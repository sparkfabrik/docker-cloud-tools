#!/usr/bin/env bash

function print-basic-auth() {
  local CURRENT_NAMESPACE INGRESS FIRST_HOST SECRET USERNAME PASSWORD
  local SERVICE SERVICE_JSON SELECTOR POD ENV_USER ENV_PASS

  CURRENT_NAMESPACE="${1:-}"
  # If no namespace is provided, try to get the current one
  if [ -z "${CURRENT_NAMESPACE}" ]; then
    CURRENT_NAMESPACE="$(kubectl config view --minify -o jsonpath="{..namespace}")"
    # If there is no current namespace, use 'default'
    if [ -z "${CURRENT_NAMESPACE}" ]; then
      CURRENT_NAMESPACE="default"
    fi
  fi

  echo "Discovering configured ingresses in namespace: ${CURRENT_NAMESPACE}"

  for INGRESS in $(kubectl --namespace "${CURRENT_NAMESPACE}" get ingresses -o jsonpath='{.items[*].metadata.name}'); do
    FIRST_HOST="https://$(kubectl --namespace "${CURRENT_NAMESPACE}" get ingress "${INGRESS}" -o jsonpath="{.spec.rules[0].host}")"
    # We can't use the jsonpath directly because the 'auth-secret' annotation could be prefixed with custom prefix.
    SECRET="$(kubectl --namespace "${CURRENT_NAMESPACE}" get ingress "${INGRESS}" -o yaml | grep "ingress.kubernetes.io/auth-secret:" | awk '{print $2}')"
    if [ -z "${SECRET}" ]; then
      # No auth-secret annotation: the ingress is not configured for basic auth at the
      # ingress level. Fall back to inspecting the served service's pods, which may
      # implement basic auth themselves via the NGINX_BASIC_AUTH_* env vars.
      SERVICE="$(kubectl --namespace "${CURRENT_NAMESPACE}" get ingress "${INGRESS}" -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}')"
      if [ -z "${SERVICE}" ]; then
        echo "No auth secret and no backend service found for ingress ${INGRESS} (${FIRST_HOST})"
        continue
      fi

      # Fetch the service once so we can distinguish "not found" from "no selector".
      SERVICE_JSON="$(kubectl --namespace "${CURRENT_NAMESPACE}" get service "${SERVICE}" -o json 2>/dev/null)"
      if [ -z "${SERVICE_JSON}" ]; then
        echo "No auth secret and backend service ${SERVICE} not found (${INGRESS} - ${FIRST_HOST})"
        continue
      fi
      # Build a label selector from the service's selector map. '// {}' keeps jq quiet for
      # services without a selector (e.g. ExternalName), so SELECTOR ends up empty cleanly.
      SELECTOR="$(echo "${SERVICE_JSON}" | jq -r '.spec.selector // {} | to_entries | map("\(.key)=\(.value)") | join(",")')"
      if [ -z "${SELECTOR}" ]; then
        echo "No auth secret and service ${SERVICE} has no selector, cannot inspect pods (${INGRESS} - ${FIRST_HOST})"
        continue
      fi
      POD="$(kubectl --namespace "${CURRENT_NAMESPACE}" get pods -l "${SELECTOR}" --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')"
      if [ -z "${POD}" ]; then
        echo "No auth secret and no running pod for service ${SERVICE} (${INGRESS} - ${FIRST_HOST})"
        continue
      fi

      # Read the env vars from inside the pod so that values sourced via valueFrom
      # (secretKeyRef/configMapKeyRef) are resolved too. printenv exits non-zero when unset.
      ENV_PASS="$(kubectl --namespace "${CURRENT_NAMESPACE}" exec "${POD}" -- printenv NGINX_BASIC_AUTH_PASS 2>/dev/null)"
      if [ -z "${ENV_PASS}" ]; then
        echo "No basic auth configured for ingress ${INGRESS} (${FIRST_HOST})"
        continue
      fi
      ENV_USER="$(kubectl --namespace "${CURRENT_NAMESPACE}" exec "${POD}" -- printenv NGINX_BASIC_AUTH_USER 2>/dev/null)"
      echo "Auth credentials for ingress ${INGRESS} (${FIRST_HOST}): ${ENV_USER:-admin} / ${ENV_PASS} (from service ${SERVICE} pod ${POD})"
      continue
    fi
    # Remove the prefix from the secret name, if it is present
    SECRET="$(echo "${SECRET}" | cut -d"/" -f1)"
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
