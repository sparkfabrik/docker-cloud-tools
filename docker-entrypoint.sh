#!/bin/bash

ADDITIONAL_ENV_FILE=${ADDITIONAL_ENV_FILE:-"/tmp/.env.additional"}
export ADDITIONAL_ENV_FILE
touch "${ADDITIONAL_ENV_FILE}"

if [ -d "/docker-entrypoint.d" ]; then
  run-parts "/docker-entrypoint.d"
fi

# Load the additional environment variables
# shellcheck disable=SC1090
. "${ADDITIONAL_ENV_FILE}"

# Print the namespaces in which the user can operate
if [ "${CLUSTER_CONFIGURED}" -eq 1 ]; then
  kubens
fi

exec "$@"
