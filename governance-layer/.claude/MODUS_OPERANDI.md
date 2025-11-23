Please implement these at-will, as needed. For clarity always ask. You can always reach me https://t.me/toneron2.

## **🤖 Agents & Subagents**

**Subagents** are specialized AI assistants with their own:

* Independent context windows (preventing pollution of main conversation) [Claude](https://docs.claude.com/en/docs/claude-code/sub-agents)  
* Custom system prompts tailored to specific tasks  
* Specific tool permissions and model selection [Claude](https://docs.claude.com/en/docs/claude-code/sub-agents)

**Two Types:**

1. **User-level**: `~/.claude/agents/` (available across all projects)  
2. **Project-level**: `.claude/agents/` (shared with team via git)

**Structure** (Markdown with YAML frontmatter):

markdown

\---

name: code-reviewer

description: Expert code reviewer. Use proactively after code changes.

tools: \[Read, Grep, Bash, Write\]

model: sonnet

\---

You are a senior code reviewer focusing on security and best practices...

**Key tip**: Include phrases like "use PROACTIVELY" or "MUST BE USED" in descriptions to encourage autonomous activation [Claude](https://docs.claude.com/en/docs/claude-code/sub-agents). Claude automatically selects appropriate subagents based on context, or you can explicitly request them [Claude](https://docs.claude.com/en/docs/claude-code/sub-agents).

---

## **🎯 Agent Skills**

Skills are model-invoked capabilities that Claude autonomously decides to use based on task relevance [Claude](https://docs.claude.com/en/docs/claude-code/skills) (unlike slash commands which are user-invoked).

**Progressive Disclosure Architecture:**

* At startup, only skill names and descriptions load (30-50 tokens each) [Anthropic](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)  
* Full content loads only when Claude determines relevance [Anthropic](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)  
* Can include supporting files, scripts, and templates

**Three Scopes:**

1. **Personal**: `~/.claude/skills/skill-name/SKILL.md`  
2. **Project**: `.claude/skills/skill-name/SKILL.md` (git-tracked)  
3. **Plugin**: Bundled with installed plugins

**Example Structure:**

markdown

\---

name: pdf-processor

description: Extract text/tables from PDFs, fill forms. Use when working with PDF files.

\---

\# Instructions

1\. Analyze PDF structure

2\. Extract content using provided scripts

3\. Format output appropriately

Skills can include executable code for tasks where traditional programming is more reliable than token generation [Anthropic](https://www.anthropic.com/news/skills). Anthropic provides built-in skills for docx, pptx, xlsx, and PDF manipulation.

---

## **⚡ Slash Commands**

User-invoked shortcuts for frequent workflows. Simply create Markdown files:

**Locations:**

* Project: `.claude/commands/command-name.md` → `/command-name`  
* Personal: `~/.claude/commands/command-name.md`  
* Namespacing via directories: `.claude/commands/frontend/component.md` → `/frontend:component` [Claude](https://docs.claude.com/en/docs/claude-code/slash-commands)

**Advanced Features:**

* **Arguments**: Use `$1`, `$2`, or `$ARGUMENTS`  
* Execute bash inline with `!` prefix when `allowed-tools` is set in frontmatter [Claude](https://docs.claude.com/en/docs/claude-code/slash-commands)[BioErrorLog](https://en.bioerrorlog.work/entry/claude-code-custom-slash-command)  
* **Frontmatter options**: model selection, tool permissions, argument hints, descriptions

**Example with bash execution:**

markdown

\---

allowed-tools: Bash(git:\*)

argument-hint: \[commit message\]

description: Create git commit

\---

Current status: \!\`git status\`

Create commit with message: $ARGUMENTS

**MCP Integration**: Connected MCP servers can expose prompts as slash commands dynamically [Claude](https://docs.claude.com/en/docs/claude-code/slash-commands).

---

## **🔌 Key Supporting Systems**

**MCP (Model Context Protocol):** Connects Claude to external data sources like Google Drive, Figma, Slack, Jira [Claude](https://docs.claude.com/en/docs/claude-code/overview). Configured via `.mcp.json`.

**Plugins:** Distributed through marketplaces, plugins can bundle commands, agents, skills, hooks, and MCP servers together [Claude](https://docs.claude.com/en/docs/claude-code/settings)[Claude](https://docs.claude.com/en/docs/claude-code/plugins-reference). Install from marketplaces or local directories.

**Hooks:** Execute custom commands before/after tool operations (e.g., auto-format after file edits, block writes to production configs) [Claude](https://docs.claude.com/en/docs/claude-code/settings).

**Plan Mode:** A permission mode where Claude plans and shows what it will do without executing, useful for code exploration or when you want to review before changes [Claude](https://docs.claude.com/en/docs/claude-code/common-workflows). Toggle with `Shift+Tab` or start with `--permission-mode plan`.

**CLAUDE.md:** Project root file defining coding standards, review criteria, and project-specific rules that Claude follows automatically [Claude](https://docs.claude.com/en/docs/claude-code/github-actions)[Skywork](https://skywork.ai/blog/how-to-use-skills-in-claude-code-install-path-project-scoping-testing/).

---

## **📋 Common Built-in Commands**

* `/help` \- List all commands  
* `/config` \- Open settings interface  
* `/agents` \- Manage subagents  
* `/clear` \- Clear conversation (saves tokens)  
* `/exit` \- End session  
* `/install-github-app` \- Enable automatic PR reviews [Builder.io](https://www.builder.io/blog/claude-code)

---

## **💡 Architecture Highlights**

**Three-tier hierarchy:**

1. User settings: `~/.claude/` (global)  
2. Project settings: `.claude/` (git-tracked, team-shared)  
3. Project local: `.claude/*.local.json` (gitignored, personal)

**Token Efficiency:** Skills and subagents use progressive disclosure \- minimal tokens until needed [Claude](https://docs.claude.com/en/docs/claude-code/skills)[Anthropic](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)

**Extensibility:** Everything (commands, agents, skills, hooks) can be distributed as plugins or committed to git for team sharing.

