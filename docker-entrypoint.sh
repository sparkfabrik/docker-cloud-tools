#!/bin/sh

if [ -n "${AWS_ACCESS_KEY_ID}" ] && [ -n "${AWS_SECRET_ACCESS_KEY}" ] && [ -n "${AWS_DEFAULT_REGION}" ]; then
  echo -e "\e[32m\e[1mTry to configure EKS cluster ...\e[0m"
  export CLUSTER_NAME="$(aws eks list-clusters | jq --raw-output '.clusters[0]')"
  export KUBECONFIG="/aws/${CLUSTER_NAME}_kubeconfig"
  aws eks update-kubeconfig --name "${CLUSTER_NAME}" --kubeconfig "${KUBECONFIG}"
  echo -e "\e[32m\e[1mDone!\e[0m"
else
  echo -e "\e[93mIf you want to automatically configure the EKS cluster you need to set the \e[1mAWS_ACCESS_KEY_ID\e[0m\e[93m, \e[1mAWS_SECRET_ACCESS_KEY\e[0m\e[93m and \e[1mAWS_DEFAULT_REGION\e[0m\e[93m env variables.\e[0m"
fi

exec "$@"
