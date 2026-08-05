#!/bin/bash
set -euo pipefail

export VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"

vault secrets enable -path=ssh ssh

vault write ssh/roles/ubuntu-ca \
  key_type=ca \
  ttl=24h \
  allow_user_certificates=true \
  default_user=ubuntu \
  allowed_users="ubuntu,ubuntu@" \
  allowed_extensions="permit-pty"

vault policy write ssh-signing /vault/policies/ssh-signing-policy.hcl

echo "CA public key (copy to every server's /etc/ssh/trusted-user-ca-keys.pem):"
vault read -field=public_key ssh/config/ca
