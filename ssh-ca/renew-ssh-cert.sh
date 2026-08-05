#!/bin/bash

set -e

VAULT_SERVER="10.0.111.211"
VAULT_USER="srvadmin"

PUBKEY="$HOME/.ssh/id_ed25519.pub"
CERT="$HOME/.ssh/id_ed25519-cert.pub"

echo "[+] Uploading public key..."

scp "$PUBKEY" ${VAULT_USER}@${VAULT_SERVER}:/tmp/user-id_ed25519.pub

echo "[+] Requesting certificate from Vault..."

ssh ${VAULT_USER}@${VAULT_SERVER} \
"export VAULT_ADDR=http://127.0.0.1:8200 && \
vault write -field=signed_key ssh/sign/ubuntu-ca public_key=@/tmp/user-id_ed25519.pub" \
> "$CERT"

chmod 600 "$CERT"

echo "[+] Certificate:"
ssh-keygen -L -f "$CERT"
