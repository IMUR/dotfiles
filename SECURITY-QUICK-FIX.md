# Security Quick Fix - CRITICAL TOKEN ROTATION

**Time Required**: 15 minutes
**Status**: 🔴 REQUIRED BEFORE MIGRATION

---

## Execute These Commands in Order

### 1. Generate New Token (Manual)
```
Visit: https://www.duckdns.org/domains
Login and click "recreate token"
Copy the new token
```

### 2. Create Secrets Directory
```bash
sudo mkdir -p /etc/crtr-config/secrets
sudo chmod 700 /etc/crtr-config/secrets
```

### 3. Store New Token
```bash
# Replace <NEW_TOKEN> with the token from DuckDNS
echo "<NEW_TOKEN>" | sudo tee /etc/crtr-config/secrets/duckdns.token
sudo chmod 600 /etc/crtr-config/secrets/duckdns.token
sudo chown root:root /etc/crtr-config/secrets/duckdns.token
```

### 4. Update State File
```bash
cd ~/Projects/crtr-config

# Edit state/network.yml line 50
vim state/network.yml
# Change line 50 from:
#   token: dd3810d4-6ea3-497b-832f-ec0beaf679b3
# To:
#   token_file: /etc/crtr-config/secrets/duckdns.token
# Save and exit
```

### 5. Remove Backup File with Token
```bash
git rm backups/dns/duckdns/duckdns.md
```

### 6. Commit Changes
```bash
git add state/network.yml
git commit -m "Security: Remove DuckDNS token, implement file-based secrets"
git push
```

### 7. Update DuckDNS Script Generator
```bash
# Create or update the generator script
cat > scripts/generate/duckdns.sh <<'SCRIPT'
#!/bin/bash
# Generate duck.sh with token from secure file

DUCKDNS_TOKEN=$(sudo cat /etc/crtr-config/secrets/duckdns.token)

cat > ~/duckdns/duck.sh <<EOF
echo url="https://www.duckdns.org/update?domains=crtrcooperator&token=${DUCKDNS_TOKEN}&ip=" | curl -k -o ~/duckdns/duck.log -K -
EOF

chmod 700 ~/duckdns/duck.sh
echo "duck.sh generated successfully"
SCRIPT

chmod +x scripts/generate/duckdns.sh
```

### 8. Regenerate duck.sh
```bash
./scripts/generate/duckdns.sh
```

### 9. Test New Token
```bash
# Run the update
~/duckdns/duck.sh

# Check result (should show "OK")
cat ~/duckdns/duck.log

# Verify DNS resolution
dig @1.1.1.1 crtrcooperator.duckdns.org +short
# Should show your current public IP (47.155.237.161)
```

---

## Verification Checklist

After completing all steps:

- [ ] New token generated at duckdns.org
- [ ] Token stored in /etc/crtr-config/secrets/duckdns.token
- [ ] File permissions are 600 (not world-readable)
- [ ] state/network.yml uses token_file (not literal token)
- [ ] backups/dns/duckdns/duckdns.md removed from git
- [ ] Changes committed and pushed
- [ ] duck.sh regenerated with new token
- [ ] DuckDNS update test shows "OK"
- [ ] DNS resolves to correct IP

---

## What This Fixes

**Before**: Token hardcoded in git (public repository)
- Anyone can clone repo and steal token
- Attacker can hijack DNS for all services
- Token exposed since initial commit

**After**: Token in secure filesystem location
- Token not in git history (new token)
- Only root can read token file
- State files reference location, not value
- Old token revoked (replaced by new token)

---

## If Something Goes Wrong

### Token Test Shows "KO"
```bash
# Verify token is correct
sudo cat /etc/crtr-config/secrets/duckdns.token
# Should match token from duckdns.org

# Check duck.sh was generated correctly
cat ~/duckdns/duck.sh
# Should contain the new token

# Run manually with verbose output
curl -v "https://www.duckdns.org/update?domains=crtrcooperator&token=$(sudo cat /etc/crtr-config/secrets/duckdns.token)&ip="
```

### DNS Not Resolving
```bash
# Wait 5 minutes (DNS propagation)
# Then test again
dig @1.1.1.1 crtrcooperator.duckdns.org +short
```

### Forgot New Token
```bash
# Visit duckdns.org and generate another new token
# Repeat steps 3-9
```

---

## After This Fix

**You can proceed with migration safely**

The old token in git history is now worthless (revoked by new token generation).

**Next**: Follow docs/MIGRATION-PROCEDURE.md

---

## Need More Details?

- Quick Summary: `SECURITY-ASSESSMENT-SUMMARY.md`
- Full Report: `SECURITY-ASSESSMENT-2025-10-13.md` (52 pages)
- Updated Handoff: `HANDOFF-2025-10-13-CLEANUP.md`

---

**Status**: Ready to execute
**Time**: 15 minutes
**Risk After Fix**: LOW (acceptable for migration)
