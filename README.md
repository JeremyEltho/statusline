# statusline

A custom [Claude Code](https://claude.com/claude-code) status line:

```
jeremy | Sonnet 5.5 | ctx:6% | 5h:[███░░░░░░░] 7d:[██░░░░░░░░]
```

- `ctx` is context window usage.
- `5h` / `7d` are rate-limit bars (Claude.ai subscription logins only).

## Install

Easiest: tell Claude Code to follow [INSTALL.md](INSTALL.md).

Manual:

1. `brew install jq`
2. `cp statusline.sh ~/.claude/statusline.sh && chmod +x ~/.claude/statusline.sh`
3. Add the entry from [settings.example.json](settings.example.json) to `~/.claude/settings.json`
4. Restart Claude Code

Run `./test.sh` to check the output with sample input.
