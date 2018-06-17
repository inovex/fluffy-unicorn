#!/bin/bash
set -eu
KEY=${1}
DIR="$( cd "$(dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
CLUSTER_NAME=$(grep "CLUSTER_NAME=" ./env.tmpl | awk -F= '{ print $2 }')

echo $(grep ${KEY} ${DIR}/data/cluster/${CLUSTER_NAME}.yaml| awk '{ print $2 }' | tr -d \")
