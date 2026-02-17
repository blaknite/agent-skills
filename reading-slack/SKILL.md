---
name: reading-slack
description: "Read Slack channels, threads, and messages using slack-cli. Use when the user provides a Slack URL, asks to read a channel, search Slack messages, or check Slack conversations. Do NOT use read_web_page for Slack URLs."
---

# Reading Slack

Read channels, threads, and messages from Slack using [slack-cli](https://github.com/lox/slack-cli).

## Prerequisites

Install slack-cli:
```bash
brew install slack-cli
```

Authenticate (first time only, opens browser for OAuth):
```bash
slack-cli auth login
```

## Commands

### View any Slack URL
```bash
slack-cli view <url>                    # View a message, thread, or channel by URL
slack-cli view <url> --markdown         # Output as markdown
slack-cli view <url> --limit 50         # Control how many messages to show
```

This is the most versatile command. When a user pastes a Slack link, use this first.

### Read a channel
```bash
slack-cli channel read <channel>              # Read recent messages (default 20)
slack-cli channel read <channel> --limit 50   # Read more messages
```

The `<channel>` argument accepts a channel name or ID.

### Read a thread
```bash
slack-cli thread read <url>                           # Read thread by Slack URL
slack-cli thread read -c <channel-id> -t <timestamp>  # Read thread by channel + timestamp
slack-cli thread read <url> --limit 200               # Read more replies (default 100)
```

### Search messages
```bash
slack-cli search "query"                    # Search messages
slack-cli search "query" --limit 50         # More results
slack-cli search "from:@user query"         # Filter by sender
slack-cli search "in:#channel query"        # Filter by channel
```

Supports Slack search syntax for `from:`, `in:`, and other operators.

### List channels
```bash
slack-cli channel list                  # List channels you're a member of
slack-cli channel list --limit 200      # List more channels
```

### Channel info
```bash
slack-cli channel info <channel>        # Show channel details (topic, purpose, members)
```

### Users
```bash
slack-cli user list                     # List workspace users
slack-cli user info <user>              # Show user info (accepts user ID or email)
```

## Workflow

1. **Slack URL provided**: Use `slack-cli view <url>` to display it directly
2. **Channel name mentioned**: Use `slack-cli channel read <name>` to read recent messages
3. **Looking for something specific**: Use `slack-cli search "query"` with Slack search operators
4. **Need thread context**: Use `slack-cli thread read <url>` to read the full thread

## Authentication Status

Check auth status:
```bash
slack-cli auth status
```
