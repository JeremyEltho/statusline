# statusline

A custom [Claude Code](https://claude.com/claude-code) status line:

```
user | Sonnet 5.5 | ctx:6% | 5h:[███░░░░░░░] 7d:[██░░░░░░░░]
```

- `ctx` is context window usage.
- `5h` / `7d` are rate-limit bars (Claude.ai subscription logins only).

## Install (customizable)

Tell Claude Code:

> Follow the instructions in https://github.com/JeremyEltho/statusline/blob/main/INSTALL.md

Claude walks you through a setup: pick what to show (model, context %, rate limits, git branch, cost, time, ...), the layout, separators, bar style, and colors. Or just **mock up the line you want** and Claude builds it to match. It saves your choices to `~/.claude/statusline.spec.md`, so you can say "customize my status line" later to tweak it.

## Install (default look, manual)


1. `brew install jq`
2. `cp statusline.sh ~/.claude/statusline.sh && chmod +x ~/.claude/statusline.sh`
3. Add the entry from [settings.example.json](settings.example.json) to `~/.claude/settings.json`
4. Restart Claude Code

Run `./test.sh` to check the output with sample input.
