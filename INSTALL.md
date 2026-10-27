# Customizable Claude Code status line

Instructions for Claude: walk the user through designing their own status line, then build and install it. Do not just install the default. Ask first, build from their answers, and iterate until they like it.

Work through the phases in order. Be conversational and brief. Use the AskUserQuestion tool for the multiple-choice questions if it is available.

---

## Phase 0: Preflight

- Run `command -v jq`. If missing, install it (`brew install jq` on macOS, `sudo apt install jq` on Debian/Ubuntu) or ask the user to.
- Check whether `~/.claude/statusline.sh` or a `statusLine` entry in `~/.claude/settings.json` already exists. If so, tell the user and back up the script to `~/.claude/statusline.sh.bak` before changing anything.
- Windows users need WSL or Git Bash, since the script is bash.

## Phase 1: Learn what data is available

The fields Claude Code sends to a status line can change between versions, so look at real data instead of trusting the catalog below.

1. Write a temporary script `~/.claude/statusline.sh`:
   ```bash
   #!/bin/bash
   cat > ~/.claude/statusline-sample.json
   echo "capturing..."
   ```
   `chmod +x` it and point `statusLine` at it (see Phase 5 for the settings format).
2. Ask the user to send any message in Claude Code (or open a new session), then read `~/.claude/statusline-sample.json` and list the available fields with `jq 'paths(scalars) | join(".")' ...`.
3. If the file never appears, fall back to the catalog below and tell the user the fields are unverified.

### Field catalog (verify against the sample)

| Info | Likely jq path |
|---|---|
| Model name | `.model.display_name` |
| Context window used % | `.context_window.used_percentage` |
| 5-hour rate limit used % (subscription only) | `.rate_limits.five_hour.used_percentage` |
| 7-day rate limit used % (subscription only) | `.rate_limits.seven_day.used_percentage` |
| Current directory | `.workspace.current_dir` |
| Session cost (USD) | `.cost.total_cost_usd` |
| Session duration | `.cost.total_duration_ms` |
| Lines added / removed | `.cost.total_lines_added`, `.cost.total_lines_removed` |
| Claude Code version | `.version` |

Things that do not come from the JSON but are easy to add: username (`whoami`), hostname, git branch and dirty state (`git -C "$cwd" ...`), current time, battery, anything a shell command can print.

## Phase 2: Interview

Ask these, a few at a time. Offer sensible defaults so the user can answer "you pick".

1. **What do you want to see?** Offer a multi-select from the fields above plus the extras (username, git branch, time, ...).
2. **Layout:** one line or two? What order, left to right?
3. **Style:**
   - Separator between items: ` | `, ` · `, ` • `, ` ❯ `, or a custom one
   - Percentages as numbers, bars (`[███░░░░░░░]`), or both? Bar width and fill characters?
   - Icons or emoji per item, or plain text? (Nerd Font glyphs only if they confirm their terminal font supports them.)
4. **Color:** none, a fixed palette, or threshold colors (for example green below 50%, yellow to 80%, red above)? Ask which items get color.
5. **Anything else?** Labels, abbreviations, hiding items when empty, and so on.

### The mockup shortcut

At any point the user can skip the questions and **mock up the line they want**, for example:

```
~/projects/app (main*) · Sonnet 5.5 · ctx 34% ██████░░░░ · $0.42
```

When they do:
1. Map every piece of the mockup to a data source (field, shell command, or literal text). Show the mapping as a short table and ask them to confirm or correct it.
2. Copy their spacing, separators, brackets, bar characters, and capitalization exactly.
3. If something in the mockup has no data source, say so and offer the closest alternative.

## Phase 3: Build

1. Write the spec you agreed on to `~/.claude/statusline.spec.md` (items, order, separators, bar style, colors, thresholds). This makes later tweaks easy: "make the bars longer" should only need an edit to the spec and a regenerate.
2. Generate `~/.claude/statusline.sh` from the spec. Rules:
   - Read stdin once: `input=$(cat)`.
   - Every `jq` read uses `// empty`, and every item degrades gracefully when its value is missing (empty bar, or hide the item). A status line must never print errors or take noticeable time.
   - Keep it fast. Avoid slow commands (network calls, large `git status` on huge repos); say so if the user asks for one.
   - Colors use ANSI escapes via `printf '\033[...m'` and always reset at the end.
   - One `printf` or `echo` per output line.
3. `chmod +x` the script.

### Reference: default preset

If the user just wants the original look, `jeremy | Sonnet 5.5 | ctx:6% | 5h:[███░░░░░░░] 7d:[██░░░░░░░░]`, this is the script (this repo's `statusline.sh`):

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

## Phase 4: Preview and iterate

1. Run the script against the captured `~/.claude/statusline-sample.json` (if it exists) and against made-up edge cases: low, mid, and very high percentages, and missing fields.
   ```bash
   ~/.claude/statusline.sh < ~/.claude/statusline-sample.json
   ```
2. Show the user the output. Tell them if ANSI colors will not show in your preview and describe what they will look like.
3. Ask "Happy with this, or want to tweak something?" Update the spec and regenerate until they approve.

## Phase 5: Install

Read `~/.claude/settings.json` first and merge. Never overwrite the user's other settings. If the file does not exist, create it. Set only the `statusLine` key:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

Delete `~/.claude/statusline-sample.json` when done. Then tell the user to restart Claude Code or open a new session to see it, and finish with:

> To change it later, just say "customize my status line", and I'll read `~/.claude/statusline.spec.md` and update it.

## Undo

Remove the `statusLine` key from `~/.claude/settings.json`, and restore `~/.claude/statusline.sh.bak` if a backup was made.
