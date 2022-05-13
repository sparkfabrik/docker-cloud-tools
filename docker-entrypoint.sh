#!/bin/bash

export ADDITIONAL_ENV_FILE=/tmp/.env.additional
touch "${ADDITIONAL_ENV_FILE}"

if [ -d "/docker-entrypoint.d" ]; then
  run-parts "/docker-entrypoint.d"
fi

# Load the additional environment variables
# shellcheck disable=SC1090
. "${ADDITIONAL_ENV_FILE}"

# Print the namespaces in which the user can operate
kubens

exec "$@"
