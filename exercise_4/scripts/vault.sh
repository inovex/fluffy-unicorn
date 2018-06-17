#!/usr/bin/env bash

set -eu
source /etc/environment

# The whole config stays in memory because of the
# dev mode, thus we make the container never restart,
# which means it will get recreated together with
# its config if its not up
# TODO update & fix warnings --> 0.10.2
POLICYDIR=/tmp/vault_policies
mkdir -p $POLICYDIR
if [[ $(docker ps -a -q --filter name=vault | wc -l) -eq 0 ]];
then
  docker run -d \
    -v $POLICYDIR:/policies:ro \
    -e SKIP_SETCAP=s \
    -e VAULT_DEV_ROOT_TOKEN_ID=123 \
    -e VAULT_ADDR=http://127.0.0.1:8200 \
    -e VAULT_TOKEN=123 \
    --net=host \
    --name=vault \
    --restart=always \
    vault:${VAULT_VERSION}
  docker exec vault vault auth-enable -path=/inovex/approle approle
  docker exec vault vault mount -path=/inovex/k8s/global generic
  docker exec vault vault write /inovex/k8s/global/fluffy-unicorn-ka/all/cmdb user=root pass=rootpw
  docker exec vault \
    sh -c 'echo '"'"'path "/inovex/k8s/global/fluffy-unicorn-ka/master/*" { capabilities=["read"] }'"'"'|vault policy-write fluffy-unicorn-ka_read_master -'

  docker exec vault \
    sh -c 'echo '"'"'path "/inovex/k8s/global/fluffy-unicorn-ka/all/*" { capabilities=["read"] }'"'"'|vault policy-write fluffy-unicorn-ka_read_all -'

  # Create PKI backends
  for ca in etcd k8s; do
    docker exec vault \
      vault mount -path /inovex/fluffy-unicorn-ka-$ca pki
    # Allow issuing an unlimited ca
    docker exec vault \
      vault mount-tune -max-lease-ttl=87600h /inovex/fluffy-unicorn-ka-$ca
    docker exec vault \
      vault write /inovex/fluffy-unicorn-ka-$ca/root/generate/internal \
                    common_name=127.0.0.1 ttl=87600h
  done

  # Create PKI backend roles
  ## The "organization" field is used by Kubernetes to determine
  ## group membership, thus we must create multiple pki roles to
  ## not have all users be member of all service groups used anywhere.
  ##
  ## Also, the username is determined based on the CN, but usually contains
  ## a ':' which obviously means it is not a valid dns name anymore. This means
  ## we must set 'allow_any_name=true', because all domains in 'allowed_domains'
  ## that are not a valid dns name get filtered out
  docker exec vault \
    vault write /inovex/fluffy-unicorn-ka-k8s/roles/master \
                allow_any_name='true' \
                enforce_hostnames='false' \
                organization='' \
                max_ttl="${VAULT_CERT_TTL}" \
                allow_ip_sans='true' \
                generate_lease='true'


  docker exec vault \
    vault write /inovex/fluffy-unicorn-ka-k8s/roles/kubelet \
                allow_any_name='true' \
                enforce_hostnames='false' \
                organization='system:nodes' \
                max_ttl="${VAULT_CERT_TTL}" \
                allow_ip_sans='true' \
                generate_lease='true'

  docker exec vault \
    vault write /inovex/fluffy-unicorn-ka-k8s/roles/kubeproxy \
                allow_any_name='true' \
                enforce_hostnames='false' \
                organization='' \
                max_ttl="${VAULT_CERT_TTL}" \
                allow_ip_sans='true' \
                generate_lease='true'

  docker exec vault \
    vault write /inovex/fluffy-unicorn-ka-etcd/roles/etcd \
                allowed_domains="${ZONE}" \
                allow_bare_domains='false' \
                allow_subdomains='true' \
                max_ttl="${VAULT_CERT_TTL}" \
                allow_ip_sans='true' \
                generate_lease='true'

  docker exec vault \
    vault write /inovex/fluffy-unicorn-ka-k8s/roles/gitlab-serviceuser \
                allow_any_name='true' \
                enforce_hostnames='false' \
                generate_lease='true' \
                organization='system:masters' \
                max_ttl="${VAULT_CERT_TTL}"


  # Create pki backend role policies
  ## The point of the nested echo is to properly get the definition + command into a script
  ## that can be executed in the container
  echo echo path \\\"/inovex/fluffy-unicorn-ka-etcd/issue/etcd\\\" {policy=\\\"write\\\"}\|vault policy-write fluffy-unicorn-ka_etcd_issue - > \
    $POLICYDIR/fluffy-unicorn-ka_etcd_issue
  echo echo path \\\"/inovex/fluffy-unicorn-ka-k8s/issue/master\\\" {policy=\\\"write\\\"}\|vault policy-write fluffy-unicorn-ka_k8s_master_issue - > \
    $POLICYDIR/fluffy-unicorn-ka_k8s_master_issue
  echo echo path \\\"/inovex/fluffy-unicorn-ka-k8s/issue/kubelet\\\" {policy=\\\"write\\\"}\|vault policy-write fluffy-unicorn-ka_k8s_kubelet_issue - > \
    $POLICYDIR/fluffy-unicorn-ka_k8s_kubelet_issue
  echo echo path \\\"/inovex/fluffy-unicorn-ka-k8s/issue/kubeproxy\\\" {policy=\\\"write\\\"}\|vault policy-write fluffy-unicorn-ka_k8s_kubeproxy_issue - > \
    $POLICYDIR/fluffy-unicorn-ka_k8s_kubeproxy_issue
  echo echo path \\\"/inovex/fluffy-unicorn-ka-k8s/issue/gitlab-serviceuser\\\" {policy=\\\"write\\\"}\|vault policy-write fluffy-unicorn-ka_k8s_gitlab_serviceuser_issue - > \
    $POLICYDIR/fluffy-unicorn-ka_k8s_gitlab_serviceuser_issue
  echo 'for file in $(ls /policies/*_issue); do sh $file; done' > $POLICYDIR/create_policies
  docker exec vault sh /policies/create_policies

  # Create approleids
  docker exec vault vault write /auth/inovex/approle/role/fluffy-unicorn-ka_master \
    bind_secret_id=false \
    policies=fluffy-unicorn-ka_read_all,fluffy-unicorn-ka_etcd_issue,fluffy-unicorn-ka_k8s_master_issue,fluffy-unicorn-ka_k8s_kubelet_issue,fluffy-unicorn-ka_k8s_kubeproxy_issue,fluffy-unicorn-ka_read_master \
    bound_cidr_list=192.168.0.0/16

  docker exec vault vault write /auth/inovex/approle/role/fluffy-unicorn-ka_worker \
    bind_secret_id=false \
    policies=fluffy-unicorn-ka_read_all,fluffy-unicorn-ka_k8s_kubelet_issue,fluffy-unicorn-ka_k8s_kubeproxy_issue \
    bound_cidr_list=192.168.0.0/16

  docker exec vault vault write /auth/inovex/approle/role/fluffy-unicorn-ka_addon_deployment \
    bind_secret_id=false \
    policies=fluffy-unicorn-ka_k8s_gitlab_serviceuser_issue \
    bound_cidr_list=192.168.0.0/16

  mkdir -p /tmp/app_roles
  docker exec vault \
    vault read -format=json /auth/inovex/approle/role/fluffy-unicorn-ka_master/role-id | jq -r .data.role_id > /tmp/app_roles/master_id
  docker exec vault \
    vault read -format=json /auth/inovex/approle/role/fluffy-unicorn-ka_worker/role-id | jq -r .data.role_id > /tmp/app_roles/worker_id
  docker exec vault \
    vault read -format=json /auth/inovex/approle/role/fluffy-unicorn-ka_addon_deployment/role-id | jq -r .data.role_id > /tmp/app_roles/deploy_id

  # Generate signing key
  openssl genrsa -out sign_key.pem 4096 2&> /dev/null
  cat sign_key.pem | docker exec -i vault vault write /inovex/k8s/global/fluffy-unicorn-ka/master/sa_sign_key service_account_key=-
  rm -f sign_key.pem
fi
