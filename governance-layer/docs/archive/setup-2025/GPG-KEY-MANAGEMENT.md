# GPG Key Management Guide

**IMPORTANT**: This document explains how to backup and manage your GPG keys securely.

---

## Your Current GPG Key

- **Key ID**: `3BB23D1FFB598E99`
- **Full Fingerprint**: `ADBB EED6 257C 32A0 61A3 6432 3BB2 3D1F FB59 8E99`
- **Name**: Anthony Richard Slosar
- **Email**: anthonyslosar@gmail.com
- **Created**: 2025-11-05

---

## 🔐 Security Rules

### NEVER Share or Store Your Private Key On:
- ❌ GitHub or any git repository
- ❌ Google Drive, Dropbox, or cloud storage (unless heavily encrypted)
- ❌ Email
- ❌ Public servers
- ❌ Unencrypted USB drives

### SAFE to Share Your Public Key:
- ✅ GitHub (for verified commit badges)
- ✅ Public key servers
- ✅ Email signatures
- ✅ Your website
- ✅ Business cards

---

## 📦 Backup Your Private Key (Do This Once)

### Step 1: Export Private Key

Open PowerShell/Terminal:

```bash
# Navigate to a temp location
cd ~/Desktop

# Export your private key
gpg --export-secret-keys --armor 3BB23D1FFB598E99 > esn-private-key-backup.asc

# Verify the file was created
ls esn-private-key-backup.asc
```

### Step 2: Store in Password Manager

**Recommended: 1Password, Bitwarden, or similar**

1. Open your password manager
2. Create new "Secure Note" item:
   - Title: "ESN Project GPG Private Key"
   - Type: Secure Note
3. Open `esn-private-key-backup.asc` in Notepad
4. Copy entire contents
5. Paste into password manager secure note
6. Save
7. **IMPORTANT**: Delete the file from your Desktop:
   ```bash
   rm ~/Desktop/esn-private-key-backup.asc
   ```

### Step 3: Verify Backup

1. Copy from password manager
2. Create temp file
3. Test import:
   ```bash
   gpg --import test-import.asc
   ```
4. If successful, delete temp file
5. Your backup is good!

---

## 🌐 Add Public Key to GitHub (Optional but Recommended)

This shows "Verified" badges on your commits:

### Step 1: Export Public Key
```bash
gpg --armor --export 3BB23D1FFB598E99
```

### Step 2: Add to GitHub
1. Copy the output (starts with `-----BEGIN PGP PUBLIC KEY BLOCK-----`)
2. Go to: https://github.com/settings/keys
3. Click **"New GPG key"**
4. Paste your public key
5. Click **"Add GPG key"**

### Result
All your signed commits will show green "Verified" badge! ✅

---

## 💻 Working on a Different Computer

When you need to work from another machine:

### One-Time Setup on New Machine

1. **Install GPG**:
   - Download Gpg4win from https://www.gpg4win.org/
   - Install Kleopatra

2. **Import Your Private Key**:
   ```bash
   # Create temp file from password manager
   # Then import:
   gpg --import private-key-from-password-manager.asc

   # Verify:
   gpg --list-secret-keys

   # Delete temp file:
   rm private-key-from-password-manager.asc
   ```

3. **Trust the Key**:
   ```bash
   gpg --edit-key 3BB23D1FFB598E99
   # Type: trust
   # Select: 5 (ultimate)
   # Type: quit
   ```

4. **Configure Git**:
   ```bash
   git config --global user.name "Anthony R. Slosar"
   git config --global user.email "anthonyslosar@gmail.com"
   git config --global user.signingkey 3BB23D1FFB598E99
   git config --global commit.gpgsign true
   ```

5. **Clone Repository**:
   ```bash
   git clone https://github.com/toneron2/esn.git
   cd esn
   ```

6. **Work Normally**:
   ```bash
   git pull
   # ... make changes ...
   git add .
   git commit -m "Your message"  # Will be signed automatically!
   git push
   ```

---

## 🚨 If You Lose Your Key

### If You Have Backup:
1. Import from password manager (see above)
2. Continue working normally

### If You Don't Have Backup:
1. Generate new key in Kleopatra
2. Update git config with new key ID
3. Add new public key to GitHub
4. Continue working (old commits will still show old signature)

### Prevention:
**BACKUP YOUR KEY NOW** using the steps above!

---

## 🔒 Advanced: Hardware Security Key (Optional)

For maximum security, consider:
- **YubiKey** ($50-70)
- Stores GPG key on physical device
- Must be plugged in to sign commits
- Most secure option

Setup guide: https://github.com/drduh/YubiKey-Guide

---

## 📋 Quick Reference

### Export Public Key
```bash
gpg --armor --export 3BB23D1FFB598E99
```

### Export Private Key (for backup only!)
```bash
gpg --export-secret-keys --armor 3BB23D1FFB598E99 > backup.asc
```

### Import Key
```bash
gpg --import backup.asc
```

### List Keys
```bash
gpg --list-keys          # Public keys
gpg --list-secret-keys   # Private keys
```

### Verify Signature
```bash
git log --show-signature -1
```

---

## 🆘 Need Help?

- **Kleopatra Issues**: Check Windows GPG documentation
- **Git Signing Issues**: Review WORKFLOW.md troubleshooting section
- **Lost Key**: Generate new one and update GitHub

---

**Last Updated**: 2025-11-05
**Key ID**: 3BB23D1FFB598E99
**Status**: Active

---

**COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED**
