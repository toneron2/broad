# ESN Development Workflow Quick Reference

## Your Standard Work Cycle

### 🔄 Daily Routine

```bash
# 1. Start of day - Get latest from GitHub
git pull

# 2. Do your work (edit files, add content, etc.)

# 3. End of session - Save to GitHub
git add .
git commit -m "Short description of what you did"
git push
```

That's it! Three commands to remember.

---

## Commit Message Examples

```bash
git commit -m "feat: Add Orange Pi 5 hardware specifications"
git commit -m "docs: Update README with clearer explanations"
git commit -m "fix: Correct Logic Engine diagram reference"
git commit -m "refactor: Reorganize specs directory structure"
git commit -m "chore: Update .gitignore rules"
```

---

## If You're On A Different Computer

### First Time Setup
```bash
# Clone the repository
git clone https://github.com/toneron2/esn.git
cd esn

# Configure Git with your info
git config user.name "Anthony R. Slosar"
git config user.email "anthonyslosar@gmail.com"
git config user.signingkey 3BB23D1FFB598E99
git config commit.gpgsign true
git config gpg.program "C:/Program Files (x86)/GnuPG/bin/gpg.exe"
```

### Then Follow Normal Cycle
```bash
git pull  # Get latest
# ... do work ...
git add .
git commit -m "Your message"
git push
```

---

## Common Issues

### "Push rejected" or "Updates were rejected"
Someone (or you on another computer) made changes. Merge them:
```bash
git pull --rebase
git push
```

### "I committed something wrong"
**Before pushing:**
```bash
git reset --soft HEAD~1  # Undo commit, keep changes
# Fix the files
git add .
git commit -m "Corrected message"
```

**After pushing:**
Contact Claude for help - it's more complex.

### "GPG passphrase not prompting"
Open Kleopatra → Settings → Configure Kleopatra → GnuPG System → check pinentry settings.

---

## Repository Structure

```
esn/
├── .claude/              # Claude Code configuration
├── docs/                 # User-facing documentation (simplified)
├── specs/                # Technical specifications (detailed)
├── patents/              # Patent documents
├── src/                  # Source code (Phase 1+)
├── tests/                # Test suites (Phase 1+)
├── scripts/              # Build automation
├── config/               # Configuration files
├── README.md            # Main introduction
├── CLAUDE.md            # Claude Code AI instructions
├── CONTRIBUTING.md      # Contribution guidelines
└── WORKFLOW.md          # This file
```

---

## Links

- **GitHub Repository**: https://github.com/toneron2/esn
- **Telegram**: [@toneron2](https://t.me/toneron2)

---

**Last Updated**: 2025-11-05
**Status**: Active Development
