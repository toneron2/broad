# GPG Commit Signing Setup Guide

**Purpose**: Sign all git commits with GPG to prove authenticity and prevent impersonation

**Status**: GPG installed, no keys configured yet

---

## Why Sign Commits?

Signing commits with GPG provides:
- **Authenticity**: Proves commits actually came from you
- **Non-repudiation**: Can't deny you made a commit
- **Integrity**: Commits haven't been tampered with
- **Trust**: GitHub shows "Verified" badge on signed commits

**Important for ESN**: As this project may seek patents and academic publication, signed commits provide legal proof of authorship and development timeline.

---

## Current Status

✅ **GPG Installed**: Version 2.4.8
❌ **No GPG Keys**: Need to generate key pair
❌ **Git Not Configured**: Need to enable commit signing

---

## Step-by-Step Setup

### Step 1: Generate GPG Key

Run this command:
```bash
gpg --full-generate-key
```

When prompted:
1. **Key type**: Choose `(1) RSA and RSA`
2. **Key size**: Enter `4096` (maximum security)
3. **Expiration**: Choose `0` (key does not expire) or set expiration date
4. **Real name**: `Anthony R. Slosar`
5. **Email**: Use your primary email (same as GitHub/git)
6. **Comment**: `TODOMODO.IO AGENCY LLC` (optional)
7. **Passphrase**: Create a strong passphrase (you'll need this for every commit)

**Example output:**
```
Real name: Anthony R. Slosar
Email address: your-email@example.com
Comment: TODOMODO.IO AGENCY LLC
You selected this USER-ID:
    "Anthony R. Slosar (TODOMODO.IO AGENCY LLC) <your-email@example.com>"
```

### Step 2: List Your GPG Key

```bash
gpg --list-secret-keys --keyid-format=long
```

You'll see output like:
```
/c/Users/Tony/.gnupg/pubring.kbx
--------------------------------
sec   rsa4096/ABCD1234EFGH5678 2025-11-03 [SC]
      FULL_KEY_ID_HERE
uid   [ultimate] Anthony R. Slosar (TODOMODO.IO AGENCY LLC) <your-email@example.com>
ssb   rsa4096/WXYZ9876STUV5432 2025-11-03 [E]
```

**Copy the key ID**: `ABCD1234EFGH5678` (after `rsa4096/`)

### Step 3: Configure Git to Use GPG Key

Replace `YOUR_KEY_ID` with the key ID from Step 2:

```bash
# Tell git which key to use
git config --global user.signingkey YOUR_KEY_ID

# Enable commit signing by default
git config --global commit.gpgsign true

# Tell git where to find GPG (Windows)
git config --global gpg.program "C:/Program Files/Git/usr/bin/gpg.exe"
```

### Step 4: Add GPG Key to GitHub

Export your public key:
```bash
gpg --armor --export YOUR_KEY_ID
```

This outputs your public key. Copy everything including:
```
-----BEGIN PGP PUBLIC KEY BLOCK-----
...
-----END PGP PUBLIC KEY BLOCK-----
```

**Add to GitHub:**
1. Go to: https://github.com/settings/keys
2. Click **"New GPG key"**
3. Paste your public key
4. Click **"Add GPG key"**

### Step 5: Test Signed Commit

Create a test commit:
```bash
echo "test" > test.txt
git add test.txt
git commit -S -m "Test signed commit"
```

If prompted for passphrase, enter the one you created in Step 1.

**Remove test file:**
```bash
git rm test.txt
git commit -S -m "Remove test file"
```

### Step 6: Push and Verify on GitHub

```bash
git push
```

Go to: https://github.com/toneron2/esn/commits/main

You should see **"Verified"** badges next to your commits! ✅

---

## Troubleshooting

### "gpg: signing failed: Inappropriate ioctl for device"

Run:
```bash
export GPG_TTY=$(tty)
```

Add to `~/.bashrc` or `~/.bash_profile`:
```bash
export GPG_TTY=$(tty)
```

### "error: gpg failed to sign the data"

1. Check GPG works:
   ```bash
   echo "test" | gpg --clearsign
   ```

2. Verify key exists:
   ```bash
   gpg --list-secret-keys
   ```

3. Check git config:
   ```bash
   git config --global user.signingkey
   ```

### Passphrase Prompt Every Commit

**Option 1: Use GPG Agent** (recommended)
```bash
# Start agent
gpg-agent --daemon

# Cache passphrase for 8 hours
gpg-connect-agent "RELOADAGENT" /bye
```

**Option 2: Cache Passphrase**
Edit `~/.gnupg/gpg-agent.conf`:
```
default-cache-ttl 28800
max-cache-ttl 28800
```

Restart agent:
```bash
gpg-connect-agent reloadagent /bye
```

### Can't Find gpg.exe on Windows

Find GPG location:
```bash
where gpg
```

Use that path in git config:
```bash
git config --global gpg.program "PATH_FROM_WHERE_COMMAND"
```

---

## Backup Your GPG Key (CRITICAL!)

If you lose your private key, you can't sign commits anymore and old signatures can't be verified.

### Export Private Key (Keep Secure!)

```bash
# Export private key
gpg --export-secret-keys --armor YOUR_KEY_ID > gpg-private-key.asc

# Export public key
gpg --export --armor YOUR_KEY_ID > gpg-public-key.asc
```

**Store these files:**
- ✅ Password manager (1Password, Bitwarden)
- ✅ Encrypted USB drive
- ✅ Secure cloud storage (encrypted)
- ❌ **Never commit to git!**
- ❌ **Never store unencrypted!**

### Restore Keys on New Machine

```bash
# Import private key
gpg --import gpg-private-key.asc

# Trust key
gpg --edit-key YOUR_KEY_ID
gpg> trust
gpg> 5 (Ultimate trust)
gpg> quit
```

---

## Git Configuration Summary

After setup, your git config should have:

```bash
git config --global --list | grep -E "(user|gpg|commit)"
```

Expected output:
```
user.name=Anthony R. Slosar
user.email=your-email@example.com
user.signingkey=YOUR_KEY_ID
commit.gpgsign=true
gpg.program=/path/to/gpg
```

---

## Quick Reference

### Sign Single Commit
```bash
git commit -S -m "Commit message"
```

### Sign All Commits Automatically
```bash
git config --global commit.gpgsign true
```

### Verify Commit Signature
```bash
git log --show-signature -1
```

### List GPG Keys
```bash
gpg --list-keys
```

### Delete GPG Key (if needed)
```bash
gpg --delete-secret-keys YOUR_KEY_ID
gpg --delete-keys YOUR_KEY_ID
```

---

## Next Steps

Once GPG is set up:
1. ✅ All future commits will be signed automatically
2. ✅ GitHub will show "Verified" badge
3. ✅ Legal proof of authorship established
4. ✅ Ready for patent filings and academic publication

---

## For TODOMODO.IO AGENCY LLC

Consider:
- Using same GPG key across all company projects
- Documenting key ID in company records
- Establishing key management policy for team members
- Regular key backups to secure storage
- Key expiration policy (e.g., rotate every 2 years)

---

**Generated**: 2025-11-03
**Status**: Setup guide created, awaiting user execution
**Next**: User runs commands to generate and configure GPG key

---

**COPYRIGHT 2025 TODOMODO.IO AGENCY LLC Anthony R. Slosar ALL RIGHTS RESERVED**
