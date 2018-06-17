#!/bin/bash

set -eu
source /etc/environment

if ! [[ -e "/usr/bin/dockerd" ]];
then
  mkdir -p /etc/docker/
  tee /etc/docker/daemon.json << EOF
{
  "bip": "192.168.122.1/25"
}
EOF
  DEBIAN_FRONTEND=noninteractive apt-get install -qq -y \
       apt-transport-https \
       ca-certificates \
       curl \
       gnupg2 \
       software-properties-common
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
  add-apt-repository \
     "deb [arch=amd64] https://download.docker.com/linux/debian \
     $(lsb_release -cs) \
     stable"
  DEBIAN_FRONTEND=noninteractive apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -qq -y docker-ce
fi

if [[ $(docker ps -a -q --filter name=etcd | wc -l) -eq 0 ]];
then
	docker run -d --name=etcd \
    --restart=always \
    -e ETCDCTL_API=2 \
	  -p 0.0.0.0:2379:2379 \
    quay.io/coreos/etcd:${ETCD_VERSION} \
      etcd \
      --listen-client-urls http://0.0.0.0:2379 \
      --advertise-client-urls http://192.168.0.254:2379 \
      --enable-v2
  sleep 2
  echo "{
  \"user\": \"${ETCD_USER}\",
  \"password\": \"${ETCD_PASS}\",
  \"roles\": [],
  \"grant\": [],
  \"revoke\": []
}" > user.json

  curl -XPUT http://192.168.0.254:2379/v2/auth/users/${ETCD_USER} \
       -d @user.json \
       -H 'Content-Type: application/json'
  rm -f user.json

  curl -XPUT http://192.168.0.254:2379/v2/auth/enable
  curl -u ${ETCD_USER}:${ETCD_PASS} -XDELETE http://192.168.0.254:2379/v2/auth/roles/guest
fi

if ! [[ -x /usr/local/bin/confd ]]; then
  echo "Downloading confd ${CONFD_VERSION}"
	curl -sL https://github.com/kelseyhightower/confd/releases/download/v${CONFD_VERSION}/confd-${CONFD_VERSION}-linux-amd64 \
		-o /usr/local/bin/confd
  chmod +x /usr/local/bin/confd
  mkdir -p /etc/confd/
fi

if ! [[ -e /etc/systemd/system/confd-dhcp.service ]]; then
  cat<<EOF >/etc/systemd/system/confd-dhcp.service
[Service]
ExecStart=/usr/local/bin/confd \
  -confdir /etc/confd/dhcpd \
  -backend etcd \
  -username ${ETCD_USER} \
  -password ${ETCD_PASS} \
  -basic-auth \
  -log-level debug \
  -node http://127.0.0.1:2379 \
  -prefix / \
  -interval 5
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable confd-dhcp.service
  systemctl start confd-dhcp.service
fi
