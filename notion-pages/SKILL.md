---
name: notion-pages
description: Search and view Notion pages using notion-cli. Use when the user provides a notion.so or notion.site URL, searching Notion, viewing page content, listing pages or databases, or working with Notion workspace. Do NOT use read_web_page for Notion URLs.
---

# Notion Pages

Search and view content from Notion workspaces using [notion-cli](https://github.com/lox/notion-cli).

## Prerequisites

Install notion-cli:
```bash
go install github.com/lox/notion-cli@latest
```

Authenticate (first time only - opens browser for OAuth):
```bash
notion-cli auth login
```

## Commands

### Search
```bash
notion-cli search "query"              # Search workspace
notion-cli search "query" --limit 10   # Limit results
notion-cli search "query" --json       # JSON output
```

### View Pages
```bash
notion-cli page view <url>             # View page content (markdown)
notion-cli page view <url> --json      # JSON output
```

### List Pages
```bash
notion-cli page list                   # List pages
notion-cli page list --limit 50        # Limit results
notion-cli page list --json            # JSON output
```

### Databases
```bash
notion-cli db list                     # List databases
notion-cli db query <database-id>      # Query database
notion-cli db query <id> --json        # JSON output
```

### Comments
```bash
notion-cli comment list <page-id>      # List comments on a page
```

## Workflow

1. **Search for content**: Use `notion-cli search "topic"` to find relevant pages
2. **View page content**: Use `notion-cli page view <url>` with a URL from search results
3. **Parse JSON for details**: Add `--json` flag when you need structured data

## Authentication Status

Check auth status:
```bash
notion-cli auth status
```

Tokens auto-refresh. Manual refresh if needed:
```bash
notion-cli auth refresh
```
