#!/usr/bin/env bash

set -e

if [ ! -z ${BASH_SOURCE} ]; then
  BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
else
  BIN_DIR=$(dirname "$(readlink -f "$0")")
fi


if [ -z "${DO_TOKEN}" ]; then
  echo "Necessary the enviroment variable ${DO_TOKEN} (digital ocean token api)"
  usage
fi

get_data_create_cluster() 
{
  cat <<EOF
{
  "name": "test-cluster-${DATE}",
  "region": "nyc1",
  "version": "1.13.4-do.0",
  "tags": [
    "stg",
    "web-team"
  ],
  "node_pools": [
    {
      "size": "s-1vcpu-2gb",
      "count": 3,
      "name": "main-pool"
    }
  ]
}
EOF
}

# COLORS
SUCCESS="\e[92m"
INFO="\e[33m"
DEFAULT_COLOR="\e[39m"
ERROR="\033[0;31m"
OK="\xE2\x9C\x94"

printf "${INFO}Creating cluster\n"
DATE=`date +%Y-%m-%d-%H-%M-%S`
CLUSTER_ID=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer ${DO_TOKEN}" --data "$(get_data_create_cluster)" "https://api.digitalocean.com/v2/kubernetes/clusters" | jq -r ".kubernetes_cluster.id")
printf "${SUCCESS}[${OK}] ${INFO}Cluster id: ${CLUSTER_ID}\n"
sleep 2;

while true; do
  printf "${INFO}Checking the cluster is running\n"
  CLUSTER_STATUS=$(curl -s -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${DO_TOKEN}" "https://api.digitalocean.com/v2/kubernetes/clusters/${CLUSTER_ID}" | jq -r ".kubernetes_cluster.status.state")
  if [ "$CLUSTER_STATUS" = "running" ]; then
      printf "${SUCCESS}[${OK}] ${INFO}Cluster is \e[39m \e[104m RUNNING\n\e[49m"
      break
  fi
  printf "${INFO}Current status is: \e[39m \e[104m ${CLUSTER_STATUS}\n\e[49m"
  sleep 30
  echo "."  
done

printf "${INFO}Fething the kubeconfig\n"
KUBECONFIG_FILE="/tmp/kubeconfig-${DATE}.conf"
$(curl -s -o ${KUBECONFIG_FILE} -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${DO_TOKEN}" "https://api.digitalocean.com/v2/kubernetes/clusters/${CLUSTER_ID}/kubeconfig")
printf "${SUCCESS}[${OK}] ${INFO}Your kubeconfig file: \e[39m \e[104m ${KUBECONFIG_FILE}\n\e[49m"

KUBE_COMMAND="kubectl --kubeconfig ${KUBECONFIG_FILE}"
export KUBECONFIG=${KUBECONFIG_FILE}

printf "${INFO}Waiting nodes ready\n"
COUNTER=0
while [ $COUNTER -lt 30 ]; do
  NODE_INFO=$(${KUBE_COMMAND} get nodes -o=jsonpath='{.items[*].status.conditions[?(@.type == "Ready")].status}')
  running=true
  for val in $NODE_INFO; do
    if [ "$val" != "True" ]; then
      running=false
    fi
  done
  if $running ; then
    printf "${SUCCESS}[${OK}] ${INFO}Nodes are ready!\n"
    break;
  fi

  let COUNTER=COUNTER+1
  sleep 10;
done
ISTIO_VERSION=1.1.3
printf "${INFO}Install Istio version ${ISTIO_VERSION}\n${DEFAULT_COLOR}"
${KUBE_COMMAND} apply -f "${BIN_DIR}/../istio/kubernetes/crds.yaml"; 
${KUBE_COMMAND} apply -f "${BIN_DIR}/../istio/kubernetes/istio-demo.yaml"

COUNTER=0
while [  $COUNTER -lt 30 ]; do
  echo "."
  echo ".."
  echo "..."
  printf "${INFO}Wating for everthing is done in the installation of the istio\n"
  status_pods=$(${KUBE_COMMAND} get pods -n istio-system -o=jsonpath='{.items[*].status.phase}')
  printf "${INFO} $status_pods\n"
  running=true
  for val in $status_pods; do
      if [ "$val" != "Running" ] && [ "$val" != "Succeeded" ]; then
        running=false
      fi
  done 
  if $running ; then
    break;
  fi
  let COUNTER=COUNTER+1
  sleep 10
done

${KUBE_COMMAND} label namespace default istio-injection=enabled
${KUBE_COMMAND} delete meshpolicies.authentication.istio.io default

printf "${SUCCESS}[${OK}] ${INFO}Istio installed\n"

printf "${INFO}Install Dashboard\n${DEFAULT_COLOR}"
${KUBE_COMMAND} apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml 
${KUBE_COMMAND} apply -f "${BIN_DIR}/../dashboard/admin-user.yaml"
printf "${SUCCESS}[${OK}] ${INFO}Dashboard installed\n"

printf "${INFO}Install Mysql\n${DEFAULT_COLOR}"
${KUBE_COMMAND} apply -f "${BIN_DIR}/../mysql"
printf "${SUCCESS}[${OK}] ${INFO}Mysql installed\n"

printf "${INFO}Install RabbitMQ\n${DEFAULT_COLOR}"
${KUBE_COMMAND} apply -f "${BIN_DIR}/../rabbitmq"
printf "${SUCCESS}[${OK}] ${INFO}RabbitMQ installed\n"

printf "${INFO}Install Gateway Default\n${DEFAULT_COLOR}"
${KUBE_COMMAND} apply -f "${BIN_DIR}/../app/network"
printf "${SUCCESS}[${OK}] ${INFO}Gateway installed\n"

printf "${SUCCESS}[${OK}] ${INFO} DONE!\n Please move the file ${KUBECONFIG_FILE} for the ~./kube/config\n \e[39m \e[104m mv ${KUBECONFIG_FILE} ~/.kube/config"

exit 0
