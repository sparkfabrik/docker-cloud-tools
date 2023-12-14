#!/usr/bin/env bash

export ADDITIONAL_ENV_FILE=/tmp/.env.additional
touch "${ADDITIONAL_ENV_FILE}"

# Fix kubens bin
if [ "${ORIGINAL_KUBENS:-0}" = "1" ]; then
  echo "Using original kubens!"
  unlink /usr/local/bin/kubens
  ln -s /utility/kubens /usr/local/bin/kubens
fi

if [ -d "/docker-entrypoint.d" ]; then
  run-parts "/docker-entrypoint.d"
fi

if [ -d "/custom-docker-entrypoint.d" ]; then
  run-parts "/custom-docker-entrypoint.d"
fi

# Load the additional environment variables
# shellcheck disable=SC1090
. "${ADDITIONAL_ENV_FILE}"

# Print the namespaces in which the user can operate
if [ "${CLUSTER_CONFIGURED}" -eq 1 ]; then
  kubens
fi

exec "$@"
