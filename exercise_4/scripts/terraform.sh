#!/usr/bin/env bash

set -eu
source /etc/environment

if ! [[ -e /usr/local/bin/terraform ]]; then
   mkdir -p /etc/terraform
   DEBIAN_FRONTEND=noninteractive apt-get install -qq -y unzip
   curl -sL https://releases.hashicorp.com/terraform/${TERRAFORM_VER}/terraform_${TERRAFORM_VER}_linux_amd64.zip \
    -o /usr/local/bin/terraform.zip
  cd /usr/local/bin &&  unzip terraform.zip
   curl -sLO \
    https://github.com/coreos/terraform-provider-matchbox/releases/download/v${TERRAFORM_MB}/terraform-provider-matchbox-v${TERRAFORM_MB}-linux-amd64.tar.gz
   tar -xzf terraform-provider-matchbox-v${TERRAFORM_MB}-linux-amd64.tar.gz
   mv terraform-provider-matchbox-v${TERRAFORM_MB}-linux-amd64/terraform-provider-matchbox .
   cat<<EOF >/root/.terraformrc
providers {
  matchbox = "/usr/local/bin/terraform-provider-matchbox"
}
EOF
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
  -node http://192.168.0.254:2379 \
  -prefix /inovex/k8s \
  -interval 5
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable confd-dhcp.service
  systemctl start confd-dhcp.service
fi

if ! [[ -e /etc/systemd/system/confd-terraform.service ]]; then
  cat<<EOF >/etc/systemd/system/confd-terraform.service
[Service]
Type=oneshot
# This is used by the Terraform template
# The second ETCD_NODE url does not point to  a valid etcd, its only
# purpose is to test having more than one endpoint
Environment="ETCD_NODES=http://192.168.0.254:2379"
ExecStart=/usr/local/bin/confd \
  -confdir /etc/confd/terraform \
  -backend etcd \
  -username ${ETCD_USER} \
  -password ${ETCD_PASS} \
  -basic-auth \
  -log-level debug \
  -node http://192.168.0.254:2379 \
  -prefix /inovex/k8s \
  -onetime
ExecStartPost=/bin/bash -c \
  'cd /etc/terraform && terraform init && terraform get --update && terraform plan && terraform apply --auto-approve'
# Check if master config can be parsed
ExecStartPost=/usr/bin/curl --fail \
  "http://localhost:8080/ignition?mac=52-54-00-fb-53-a6&os=installed"
# Check if worker config can be parsed
ExecStartPost=/usr/bin/curl --fail \
  "http://localhost:8080/ignition?mac=52-54-00-fb-53-a9&os=installed"
ExecStartPost=/usr/bin/curl --fail \
  "http://localhost:8080/ignition?mac=52-54-00-fb-53-a6"
EOF
  systemctl daemon-reload
fi
