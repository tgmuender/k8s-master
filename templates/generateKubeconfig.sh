#!/bin/bash
# Utility to generate a kubeconfig file for a specified user.

set -euCo pipefail

readonly BASELINE=$1
readonly USERNAME=$2
readonly NEW_CONFIG="config-${USERNAME}"
readonly CTX_NAME='sandbox'
readonly OIDC_ISSUER_URL='{{ oidc_issuer_url }}'
readonly OIDC_CLIENT='{{ oidc_client }}'
readonly OIDC_CLIENT_SECRET='{{ oidc_client_secret }}'

if [[ -f ${NEW_CONFIG} ]]; then
    echo "--> Removing old config.."
    rm ${NEW_CONFIG}
fi
cp ${BASELINE} ${NEW_CONFIG}

readonly CLUSTER_NAME=$(kubectl --kubeconfig=${NEW_CONFIG} config view --flatten --output=jsonpath='{.clusters[0].name}')

kubectl --kubeconfig=${NEW_CONFIG} config unset users
kubectl --kubeconfig=${NEW_CONFIG} config unset contexts
kubectl --kubeconfig=${NEW_CONFIG} config unset current-context

kubectl --kubeconfig=${NEW_CONFIG} config set-credentials ${USERNAME} \
   --auth-provider=oidc \
   --auth-provider-arg=idp-issuer-url=${OIDC_ISSUER_URL} \
   --auth-provider-arg=client-id=${OIDC_CLIENT} \
   --auth-provider-arg=client-secret=${OIDC_CLIENT_SECRET}

kubectl --kubeconfig=${NEW_CONFIG} config set-context \
    ${CTX_NAME} \
    --user=${USERNAME} \
    --cluster=${CLUSTER_NAME}

kubectl --kubeconfig=${NEW_CONFIG} config use-context ${CTX_NAME}
