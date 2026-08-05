# Vault SSH CA

User workstations never keep long-lived SSH keys on servers. Instead, Vault signs a short-lived certificate for each user's existing key, so credentials rotate automatically when the certificate expires.

## How it works

1. `vault/ssh-ca/setup.sh` enables the `ssh` secrets engine and creates the `ubuntu-ca` signing role (24h TTL).
2. The user runs `renew-ssh-cert.sh` on their workstation.
3. The script uploads the public key, asks Vault to sign it, installs the result as `~/.ssh/id_ed25519-cert.pub`, and prints the certificate details.
4. Every server trusts the CA public key, so it accepts the signed certificate without storing the user's key at all.

## Server-side trust

On every server that accepts these certificates:

```bash
# Fetch the CA public key once (after running vault/ssh-ca/setup.sh)
vault read -field=public_key ssh/config/ca > /etc/ssh/trusted-user-ca-keys.pem
chmod 644 /etc/ssh/trusted-user-ca-keys.pem
```

Then add to `/etc/ssh/sshd_config` and restart sshd:

```
TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem
```

## Renewal

Certificates expire after 24h. Users re-run the script (or a cron job does) to regenerate:

```bash
~/.ssh/renew-ssh-cert.sh
ssh-keygen -L -f ~/.ssh/id_ed25519-cert.pub   # verify expiry
```

See `docs/ssh-certificate-workflow.md` for the full end-to-end walkthrough.
