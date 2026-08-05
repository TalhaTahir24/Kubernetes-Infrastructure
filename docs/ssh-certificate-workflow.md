# Vault SSH Certificate Workflow

Short-lived SSH certificates signed by Vault replace long-lived keys on servers.

## 1. Configure the CA

Run `vault/ssh-ca/setup.sh` against the Vault server. This enables the `ssh` secrets engine and creates the `ubuntu-ca` role:

```bash
vault write ssh/roles/ubuntu-ca \
  key_type=ca \
  ttl=24h \
  allow_user_certificates=true \
  default_user=ubuntu \
  allowed_users="ubuntu,ubuntu@" \
  allowed_extensions="permit-pty"
```

The user's role maps to the `ssh-signing` policy (`vault/policies/ssh-signing-policy.hcl`).

## 2. Trust the CA on servers

Fetch the CA public key once:

```bash
vault read -field=public_key ssh/config/ca > /etc/ssh/trusted-user-ca-keys.pem
chmod 644 /etc/ssh/trusted-user-ca-keys.pem
```

Add to `/etc/ssh/sshd_config` and restart sshd:

```
TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem
```

Servers now accept any certificate signed by the CA. No user public key is ever stored on the server.

## 3. Sign a user key

On the workstation:

```bash
~/.ssh/renew-ssh-cert.sh
```

What the script does:

1. Copies `~/.ssh/id_ed25519.pub` to the Vault host.
2. Calls `vault write -field=signed_key ssh/sign/ubuntu-ca public_key=@<key>`.
3. Saves the response as `~/.ssh/id_ed25519-cert.pub` and locks down permissions.
4. Prints the certificate details with `ssh-keygen -L -f`.

## 4. Verify

```bash
ssh-keygen -L -f ~/.ssh/id_ed25519-cert.pub
ssh -i ~/.ssh/id_ed25519 <target>
```

`ssh-keygen -L` shows the principals, validity window, and CA. If a login fails, check that the target server trusts the CA key (step 2) and that the principal matches the user.

## 5. Renew

Certificates expire after the role TTL (24h). Re-run the script to regenerate; the old certificate becomes invalid automatically. For automation, run it from a cron job on the workstation.
