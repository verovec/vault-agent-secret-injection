#!/bin/bash

# Get Vault credentials
VAULT_UNSEAL_KEY=$(cat vault-keys.json | jq -r ".unseal_keys_b64[]")
VAULT_ROOT_KEY=$(cat vault-keys.json | jq -r ".root_token")

# Unseal Vault
kubectl exec vault-0 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY

# Enable Key Value engine
kubectl exec vault-0 -n vault -- /bin/sh -c "VAULT_TOKEN=$VAULT_ROOT_KEY vault secrets enable -version=2 kv"

# Create Key Value secret
kubectl exec vault-0 -n vault -- /bin/sh -c "VAULT_TOKEN=$VAULT_ROOT_KEY vault kv put kv/api APP_SECRET=my_secure_secret"

kubectl exec vault-0 -n vault -- /bin/sh -c "VAULT_TOKEN=$VAULT_ROOT_KEY vault policy write app -<<EOF
path \"kv/data/api*\" {
  capabilities = [\"read\"]
}
EOF"

kubectl exec vault-0 -n vault -- /bin/sh -c "VAULT_TOKEN=$VAULT_ROOT_KEY vault auth enable kubernetes"

TOKEN_REVIEWER_JWT_COMMAND=$(kubectl exec vault-0 -n vault -- /bin/sh -c "cat /var/run/secrets/kubernetes.io/serviceaccount/token")

KUBERNETES_PORT_443_TCP_ADDR=$(kubectl exec vault-0 -n vault -- /bin/sh -c "echo \$KUBERNETES_PORT_443_TCP_ADDR")

kubectl exec vault-0 -n vault -- /bin/sh -c "VAULT_TOKEN=$VAULT_ROOT_KEY vault write auth/kubernetes/config \
   token_reviewer_jwt=$TOKEN_REVIEWER_JWT_COMMAND \
   kubernetes_host=https://$KUBERNETES_PORT_443_TCP_ADDR:443 \
   kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"

kubectl exec vault-0 -n vault -- /bin/sh -c "VAULT_TOKEN=$VAULT_ROOT_KEY vault write auth/kubernetes/role/api \
   bound_service_account_names=api-serviceaccount \
   bound_service_account_namespaces=api \
   policies=app \
   ttl=1h"
