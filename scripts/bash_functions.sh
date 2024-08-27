#!/usr/bin/env bash

function print-basic-auth() {
  local CURRENT_NAMESPACE INGRESS FIRST_HOST SECRET USERNAME PASSWORD

  CURRENT_NAMESPACE="${1:-"$(kubectl config view --minify -o jsonpath="{..namespace}")"}"
  echo "Discovering configured ingresses in namespace: ${CURRENT_NAMESPACE}"

  for INGRESS in $(kubectl --namespace "${CURRENT_NAMESPACE}" get ingresses -o jsonpath='{.items[*].metadata.name}'); do
    FIRST_HOST="https://$(kubectl --namespace "${CURRENT_NAMESPACE}" get ingress "${INGRESS}" -o jsonpath="{.spec.rules[0].host}")"
    # We can't use the jsonpath directly because the 'auth-secret' annotation could be prefixed with custom prefix.
    SECRET="$(kubectl --namespace "${CURRENT_NAMESPACE}" get ingress "${INGRESS}" -o yaml | grep "ingress.kubernetes.io/auth-secret:" | awk '{print $2}')"
    if [ -z "${SECRET}" ]; then
      echo "No auth secret found for ingress ${INGRESS} (${FIRST_HOST})"
      continue
    fi
    USERNAME=$(kubectl --namespace "${CURRENT_NAMESPACE}" get secret "${SECRET}" -o jsonpath="{.data.username}" | base64 -d)
    PASSWORD=$(kubectl --namespace "${CURRENT_NAMESPACE}" get secret "${SECRET}" -o jsonpath="{.data.password}" | base64 -d)
    if [ -z "${USERNAME}" ] || [ -z "${PASSWORD}" ]; then
      echo "No auth credentials found in secret ${SECRET} (${INGRESS} - ${FIRST_HOST})"
      continue
    fi
    echo "Auth credentials for ingress ${INGRESS} (${FIRST_HOST}): ${USERNAME} / ${PASSWORD}"
  done

  echo "Done"
}
