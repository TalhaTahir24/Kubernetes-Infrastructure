#!/bin/bash
set -euo pipefail

export VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"

vault secrets enable -path=pki pki

vault secrets tune -max-lease-ttl=87600h pki

vault write -field=certificate pki/root/generate/internal \
  common_name=dc1.local \
  ttl=87600h > pki/ca.crt

vault write pki/roles/internal-tls \
  allowed_domains=dc1.local \
  allow_subdomains=true \
  max_ttl=8760h

vault write pki/config/urls \
  issuing_certificates="http://vault.dc1.local/v1/pki/ca" \
  crl_distribution_points="http://vault.dc1.local/v1/pki/crl"
