#!/usr/bin/env bash
set -euo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
export VAULT_ADDR="${1:-http://192.168.0.254:8200}"
export CLUSTERNAME="${2:-fluffy-unicorn-ka}"
export CHECK_CLUSTER_CONNECTION="${3:-yes}"
export KUBECONFIG="${DIR}/.kube/config"
export CLUSTERS_YAML_DIR="${DIR}/data/cluster"
export APPROLEID="$(vagrant ssh pxe_server -c "cat /tmp/app_roles/deploy_id" | tr -d '[:space:]')"

mkdir -p ${DIR}/.kube/
API_SERVER_ADDRESS=$(grep api_server_vip_address ${CLUSTERS_YAML_DIR}/${CLUSTERNAME}.yaml|awk '{print $2}'|tr -d '"')

USERNAME=gitlab

# Get token
echo 'Fetching vault token via approle id..'
CURL_STATUS_CODE=$(curl \
                    -Ss \
                    -XPOST \
                    --data "{\"role_id\": \"${APPROLEID}\"}" \
                    ${VAULT_ADDR}/v1/auth/inovex/approle/login \
                    -w "%{response_code}" \
                    -o VAULT_TOKEN_RAW)
if [[ "$CURL_STATUS_CODE" != 200 ]]; then
    echo "Failed to retrieve token! Error was: \"$(cat VAULT_TOKEN_RAW)\""
    exit 1
fi

VAULT_TOKEN=$(jq -r .auth.client_token VAULT_TOKEN_RAW)
echo $VAULT_TOKEN > vault_token
echo 'Successfully fetched token via approle id'

# Get ca, cert and key and write them into distinct files
echo 'Fetching x509 certificate for cluster...'
RAW_VAULT_ANSWER_FILE=vault_answer
curl  --fail \
      -s \
      -H "X-VAULT-TOKEN: ${VAULT_TOKEN}" \
      -XPOST \
      --data '{"common_name": "gitlab-serviceuser", "ttl": "42h"}' \
      ${VAULT_ADDR}/v1/inovex/${CLUSTERNAME}-k8s/issue/gitlab-serviceuser \
      -o ${RAW_VAULT_ANSWER_FILE}
jq -r .data.issuing_ca ${RAW_VAULT_ANSWER_FILE} > ca.pem
jq -r .data.certificate ${RAW_VAULT_ANSWER_FILE} > crt.pem
jq -r .data.private_key ${RAW_VAULT_ANSWER_FILE} > key.pem
echo 'Succesfully fetched x509 certificate for cluster'

# Configure kubectl
kubectl config set-cluster $CLUSTERNAME \
    --server https://$API_SERVER_ADDRESS:443 \
    --embed-certs=true \
    --certificate-authority=ca.pem
kubectl config set-credentials $USERNAME \
    --certificate-authority=ca.pem \
    --client-certificate=crt.pem \
    --client-key=key.pem \
    --embed-certs=true
kubectl config set-context $CLUSTERNAME \
    --cluster=$CLUSTERNAME \
    --user=$USERNAME
kubectl config use-context $CLUSTERNAME

if [[ ${CHECK_CLUSTER_CONNECTION} == "yes" ]]; then
  if ! kubectl cluster-info;
  then
      echo "It seems like the kube.config is invalid or the API servers are unreachable"
      exit 1
  fi
fi

echo 'Successfully configured kubectl'

rm -f ${DIR}/vault_token
rm -f ${DIR}/VAULT_TOKEN_RAW
rm -f ${DIR}/vault_answer
rm -f ${DIR}/ca.pem
rm -f ${DIR}/crt.pem
rm -f ${DIR}/key.pem
