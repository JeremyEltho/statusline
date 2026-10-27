# Install this Claude Code status line

Instructions for Claude: set up the custom status line described below on this machine. Do the steps in order and report what you changed.

## Result

The bottom of the Claude Code prompt shows:

```
<username> | <model> | ctx:6% | 5h:[███░░░░░░░] 7d:[██░░░░░░░░]
```

- `ctx` is context window usage in percent.
- `5h` and `7d` are rate-limit usage bars for the 5-hour and weekly windows. They are only populated on Claude.ai subscription logins. With an API key they show as empty bars.

## Steps

1. **Check for `jq`.** Run `command -v jq`. If it is missing, install it (`brew install jq` on macOS, `sudo apt install jq` on Debian/Ubuntu) or tell me to.

2. **Back up any existing status line script.** If `~/.claude/statusline.sh` exists, copy it to `~/.claude/statusline.sh.bak` before overwriting.

3. **Write `~/.claude/statusline.sh`** with exactly this content, then `chmod +x` it:

```bash
#!/bin/bash
input=$(cat)

user=$(whoami)
model=$(echo "$input" | jq -r '.model.display_name')
ctx=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
h5=$(echo "$input"  | jq -r '.rate_limits.five_hour.used_percentage // empty')
d7=$(echo "$input"  | jq -r '.rate_limits.seven_day.used_percentage // empty')

# bar <percent> -> [███░░░░░░░]
bar() {
  local p=${1%.*} w=10 f
  [ -z "$p" ] && { printf '[%*s]' $w '' | tr ' ' '░'; return; }
  f=$(( p * w / 100 ))
  printf '['
  printf '%*s' "$f" '' | tr ' ' '█'
  printf '%*s' "$((w - f))" '' | tr ' ' '░'
  printf ']'
}

printf '%s | %s | ctx:%s%% | 5h:%s 7d:%s\n' \
  "$user" "$model" "${ctx%.*}" "$(bar "$h5")" "$(bar "$d7")"
```

4. **Update `~/.claude/settings.json`.** Read it first and merge. Do not overwrite other settings. If the file does not exist, create it. Add or replace only the `statusLine` key:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

5. **Test the script** with sample input:

```bash
echo '{"model":{"display_name":"Sonnet 5.5"},"context_window":{"used_percentage":6},"rate_limits":{"five_hour":{"used_percentage":30},"seven_day":{"used_percentage":20}}}' | ~/.claude/statusline.sh
```

   Expected output: `<user> | Sonnet 5.5 | ctx:6% | 5h:[███░░░░░░░] 7d:[██░░░░░░░░]`

6. **Verify the field names.** The JSON field names (`context_window.used_percentage`, `rate_limits.five_hour.used_percentage`, `rate_limits.seven_day.used_percentage`) may differ between Claude Code versions. If the status line shows `ctx:%` or empty bars after a restart on a subscription login, check the current Claude Code status line docs (or have the `statusline-setup` agent do it), correct the `jq` paths, and re-test.

7. **Tell me to restart Claude Code** (or open a new session) so the status line appears.

## Notes

- Windows: run this under WSL or Git Bash, since the script is bash.
- To undo, remove the `statusLine` key from `~/.claude/settings.json` and restore `statusline.sh.bak` if one was made.
