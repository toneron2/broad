# Git Branching Guide - BROAD Project

## Current Setup ✅

You now have **two branches**:

```
master (main branch)
  └─ Healthcare Workflow Library Complete
       ↓
governance-layer (experimental branch) ← YOU ARE HERE
  └─ Start governance layer experiments here
```

All your healthcare workflow library work is **safely preserved** on the `master` branch.

---

## Branch Overview

### `master` Branch
**Contains**: Complete healthcare workflow library implementation
- All healthcare standards (FHIR, BPMN, CMMN, DMN, GS1)
- Complete documentation
- MCP server implementation
- n8n workflow templates
- Updated ARCHITECTURE.md and DECISIONS.md

**Status**: ✅ Complete, stable, ready for decisions and deployment

**When to use**: When you want to work on the healthcare workflow library or terraform implementation

### `governance-layer` Branch
**Contains**: Same as master (starting point)
- Ready for governance layer experimentation

**Status**: 🧪 Experimental - safe to modify without affecting master

**When to use**: When you want to add the governance layer

---

## How to Work with Branches

### Currently Active Branch
```bash
# Check which branch you're on
git branch

# You should see:
# * governance-layer  ← asterisk shows current branch
#   master
```

### Switch to Master (Healthcare Workflow Library)
```bash
git checkout master

# Now all files are exactly as you left them
# Healthcare workflow library complete
# No governance layer modifications
```

### Switch to Governance Layer (Experimental)
```bash
git checkout governance-layer

# Now you can add governance layer
# Completely safe to experiment
# Master branch untouched
```

### See What Changed
```bash
# See what files you've modified
git status

# See what changed in files
git diff

# See commit history
git log --oneline
```

---

## Working on Governance Layer

### Current State
You're on `governance-layer` branch right now. Everything you do here **will not affect master**.

### Add Governance Layer Files
```bash
# You're already on governance-layer branch
# Create your governance layer files
mkdir governance-layer/
# Add your governance components
# Modify files as needed
```

### Save Your Work (Commit)
```bash
# After making changes
git add -A
git commit -m "Add governance layer: [description of what you added]"

# Example:
git commit -m "Add governance layer: policy engine and compliance framework"
```

### Save Progress But Continue Later
```bash
# Commit your changes (even if incomplete)
git add -A
git commit -m "Work in progress: governance layer initial structure"

# Switch back to master safely
git checkout master

# Your governance work is saved, you can return anytime
```

---

## Merging or Discarding Changes

### Option 1: Keep Governance Layer (Merge into Master)
```bash
# When governance layer is ready and you want to keep it
git checkout master
git merge governance-layer

# Now master has both healthcare workflow library AND governance layer
```

### Option 2: Discard Governance Layer (Keep Master Unchanged)
```bash
# If experiment didn't work out
git checkout master
git branch -D governance-layer

# Governance layer deleted, master unchanged
# Healthcare workflow library preserved exactly as before
```

### Option 3: Keep Both Branches Separate
```bash
# Continue working on both independently
# Switch between them as needed
# No merge required

# For healthcare work:
git checkout master

# For governance work:
git checkout governance-layer
```

---

## Quick Reference Commands

### Check Status
```bash
git branch              # See all branches, * shows current
git status              # See modified files
git log --oneline       # See commit history
```

### Switch Branches
```bash
git checkout master              # Switch to master
git checkout governance-layer    # Switch to governance layer
```

### Save Work
```bash
git add -A                          # Stage all changes
git commit -m "Description"         # Commit with message
```

### Compare Branches
```bash
# See what's different between branches
git diff master governance-layer

# See list of changed files
git diff --name-only master governance-layer
```

---

## Next Session - Which Branch to Use?

### For Healthcare Workflow Library Work
**Use `master` branch**

Next session prompt:
```
Working on BROAD project - Healthcare Workflow Library implementation.

I want to work on the master branch (healthcare workflow library).

Context:
- Read CURRENT_SESSION_STATUS.md
- I've made decisions on the 14 critical questions
- Ready for terraform implementation

First, switch to master branch:
git checkout master
```

### For Governance Layer Experiment
**Use `governance-layer` branch**

Next session prompt:
```
Working on BROAD project - Adding governance layer.

I want to work on the governance-layer branch.

Context:
- Base: Healthcare workflow library (complete)
- Goal: Add governance layer on top
- Branch: governance-layer (experimental)

First, ensure I'm on governance-layer branch:
git checkout governance-layer
```

---

## Safety Features ✅

### Your Healthcare Work is Protected
- ✅ All healthcare workflow library work committed to master
- ✅ Master branch will not change unless you explicitly merge or modify
- ✅ You can always return to this exact state: `git checkout master`

### Experimentation is Safe
- ✅ governance-layer branch is completely separate
- ✅ Modify anything without fear
- ✅ Can discard entire branch if needed
- ✅ Can merge back if successful

### You Can Always Recover
```bash
# If you get confused, see all branches
git branch -a

# See exactly what changed
git log --all --graph --oneline

# Return to master (safe state)
git checkout master

# See current branch
git branch
```

---

## Current State After This Session

```
Repository: /home/szt0j2/Desktop/broad/
Current Branch: governance-layer ← 🧪 Experimental (safe to modify)
Master Branch: Complete and untouched ← ✅ Healthcare work preserved

Branches:
├─ master (stable)
│  └─ Healthcare Workflow Library Complete
│     - 18 files committed
│     - All documentation
│     - Ready for decisions
│
└─ governance-layer (experimental) ← YOU ARE HERE
   └─ Same as master (starting point)
      - Ready for governance layer additions
      - Completely safe to experiment
```

---

## When You Return

### Governance Layer Work
1. Check current branch: `git branch`
2. If not on governance-layer: `git checkout governance-layer`
3. Start adding governance components
4. Commit frequently: `git commit -m "Description"`

### Healthcare Workflow Library Work
1. Switch to master: `git checkout master`
2. Read CURRENT_SESSION_STATUS.md
3. Provide your decisions
4. Begin terraform implementation

### Both Are Independent!
- You can work on one, then the other
- You can keep them separate forever
- You can merge them when governance layer is ready
- You can discard governance layer and keep master

---

## Help Commands

### Lost? Check This:
```bash
# Where am I?
pwd
# Should show: /home/szt0j2/Desktop/broad

# Which branch?
git branch
# * shows current branch

# What did I change?
git status

# What's in my last commit?
git log -1

# Show all branches with last commit
git branch -v
```

### Need to Reset?
```bash
# Discard all uncommitted changes (careful!)
git reset --hard

# Return to master (safe state)
git checkout master
```

---

**Status**: ✅ Git repository initialized and branched
**Current Branch**: governance-layer (experimental)
**Safe State**: master (healthcare workflow library complete)
**Next Action**: Add governance layer or switch to master for healthcare work

You're all set! Your healthcare work is completely protected. Experiment freely! 🚀
