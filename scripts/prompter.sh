#!/usr/bin/env bash

prompter() {
  PS1='\[\033[1;36m\]\u\[\033[1;31m\]@\[\033[1;32m\]\h:\[\033[1;35m\]\w\[\033[1;31m\]\$\[\033[0m\] '
  if [ -f "${KUBECONFIG}" ]; then
    CURRENT_NAMESPACE="$(grep "namespace:" <"${KUBECONFIG}" | awk '{print $2}')"
    if [ -n "${CURRENT_NAMESPACE}" ]; then
      #shellcheck disable=SC2025
      PS1="${PS1}(\e[1m${CURRENT_NAMESPACE}\e[0m) "
    fi
  fi
  export PS1
}
