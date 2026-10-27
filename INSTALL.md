# Fully customizable Claude Code status line

Instructions for Claude: walk the user through designing their own status line, then build and install it. Do not just install a default. Run the interview, build from the answers, and iterate until they love it.

This file is self-contained: the full menu of options is in Phase 2. Be conversational and brief. Use AskUserQuestion for the menus if available (max 4 questions and 4 options per call, so use several rounds). Whenever the user says "you pick" or "surprise me", choose good defaults and move on. The user can jump to any phase or restart at any time.

---

## Phase 0: Preflight

- `command -v jq`. If missing, install it (`brew install jq` on macOS, `sudo apt install jq` on Debian/Ubuntu) or ask the user to.
- If `~/.claude/settings.json` has a `statusLine` entry, or `~/.claude/statusline.sh` exists, tell the user, and back up both (`*.bak`) before changing anything. Also back up whatever script the existing `command` points to.
- Windows needs WSL or Git Bash (scripts are bash).
- Ask which terminal and font they use. It decides whether Powerline arrows, Nerd Font icons, emoji, and clickable links are safe. If unsure, default to plain Unicode (`▰▱ █░ · |`) and offer to test glyphs by printing them for the user to eyeball.

## Phase 1: Discover what data exists

Field names change between Claude Code versions, so look at real data. The official reference is https://code.claude.com/docs/en/statusline.

1. Write a temporary `~/.claude/statusline.sh` that saves its input:
   ```bash
   #!/bin/bash
   cat > ~/.claude/statusline-sample.json
   echo "capturing..."
   ```
   `chmod +x` it and set `statusLine` (Phase 5 format). The status line runs after the next assistant message.
2. After the next message, read `~/.claude/statusline-sample.json` and list fields: `jq -r 'paths(scalars) | join(".")'`.
3. Compare to the catalog below. Fields missing from the sample are simply unavailable for this user (for example `rate_limits` only exists on subscription logins, `effort` only on models that support it). Tell the user which menu items are unavailable and why.
4. If no sample appears, use the catalog and say the fields are unverified.

## Phase 2: Interview

Keep it to a few rounds. Each round: show the options, take multi-select answers, offer "you pick", and remember everything for the spec.

### Round 0: Start point

Ask: **Start from a preset, build from scratch, or mock up the exact line you want?**

**Presets** (each is a starting point they can edit):
| Preset | Looks like |
|---|---|
| Minimal | `app · Sonnet 5.5 · 34%` |
| Git-aware | `app (main*↑2) · PR #42 ✓ · Sonnet 5.5 · 34%` |
| Cost guardian | `Sonnet 5.5 · $0.42 · $3.10/hr · 34% · +166/-25` |
| Rate-limit watcher | `5h ▰▰▱▱ 31% resets 2h10m · 7d ▰▱▱▱ 27% · Sonnet 5.5` |
| Two-line dashboard | line 1: dir, branch, PR, model. line 2: context bar, limits, cost, duration |
| Powerline | colored background segments with arrow separators (needs a Powerline/Nerd font) |
| Theme palettes | Tokyo Night, Catppuccin, Dracula, Gruvbox, Nord, Solarized variants of any preset |
| Retro ASCII | `[##########] 34% | main | $0.42`, no special glyphs, works anywhere |
| Kitchen sink | everything they have data for, spread over 2 to 3 lines |
| Focus | just the context percentage and nothing else |

**Mockup shortcut.** If they type or paste a mockup, skip the rest of the menus:
1. Map every piece to a data source (field, shell command, or literal text). Show the mapping as a table and ask them to confirm or correct it.
2. Copy their spacing, separators, brackets, bar characters, and capitalization exactly.
3. If something has no data source, say so and offer the closest alternative.

### Round 1: What to show (menu of items)

Offer these by category. Mark each as `data` (from the JSON), `computed` (math on JSON), or `shell` (runs a command, so it needs caching). Only show items the sample from Phase 1 supports, plus the shell items.

**Model and session**
- Model display name, or short form (`sonnet`, `opus`), or full `model.id`; strip suffixes like "(1M context)" (`data`)
- Effort level with glyph `○ ◐ ●` or text: `effort.level` (`data`; absent on models without effort)
- Thinking on/off (`thinking.enabled`), fast mode ⚡ (`fast_mode`) (`data`)
- Session name from `/rename` (`session_name`), session id (short), Claude Code version, output style, agent name (`--agent`), vim mode (`data`; if shown, set `hideVimModeIndicator: true`)
- Session duration (`cost.total_duration_ms`), API time (`total_api_duration_ms`), wall-clock vs API time ratio (`computed`)
- Session start time (`computed`)

**Context window**
- Used % or remaining % (`context_window.used_percentage`, `remaining_percentage`)
- Tokens used / window size, e.g. `68k/200k` (`context_window_size` is 200k, or 1M for extended models)
- Tokens left (`computed`), input/output token counts
- Warning marker when high, e.g. `⚠ /compact?` above a chosen threshold (`computed`)

**Rate limits and spend** (subscription logins only)
- 5-hour and weekly used % (`rate_limits.five_hour.used_percentage`, `seven_day...`)
- Reset countdown, e.g. `resets in 2h10m`, or reset clock time (`resets_at` epoch seconds, `computed`)
- Used vs remaining %; show an item only when above a threshold (for example hide until 50%)
- Spend limit % and dollars when behind a Claude apps gateway (`rate_limits.spend_limit.*`)

**Cost and productivity**
- Session cost USD (`cost.total_cost_usd`; a list-price estimate, not the bill)
- Burn rate `$/hr` (`computed` from cost / duration; hide for the first minute)
- Lines added / removed, net lines, e.g. `+166 -25` (`cost.total_lines_*`)
- Cost per 1k lines, or lines per minute (`computed`)

**Prompt cache**
- Warm or cold indicator, TTL (`5m`/`1h`), countdown to expiry (`prompt_cache.expires_at`)
- Hit ratio %, miss count, last miss cause (`prompt_cache.*`)
- Tokens that would be re-cached if cold (`recache_tokens_if_cold`)

**Location and git** (`data` for PR and repo, `shell` for the rest)
- Working directory: basename, `~`-shortened path, last N segments, or fish-style abbreviation (`workspace.current_dir`); project dir (`workspace.project_dir`); extra dirs count
- Repo `owner/name` (`workspace.repo.*`)
- Git branch, short SHA, detached-HEAD marker (`shell`)
- Dirty marker `*`, or counts: staged `+2`, unstaged `~3`, untracked `?1`, conflicts, stash count, ahead/behind `↑2↓1` (`shell`)
- Open PR number and review state (`approved`, `pending`, `changes_requested`, `draft`) via `pr.*`; GitLab MRs supported (`data`)
- Worktree name and branch (`workspace.git_worktree`, `worktree.*`)
- Clickable links (OSC 8): branch to GitHub, PR number to PR URL, repo to remote (needs iTerm2, Kitty, WezTerm, or similar)

**Environment** (`shell`; all need caching)
- Python venv, Node version, Rust/Go version, Docker context, kube context and namespace, AWS profile/region, Terraform workspace
- Hostname, username, SSH marker, shell level
- Battery %, CPU load, memory, free disk
- Wi-Fi/VPN status

**Time**
- Clock (12 or 24 hour, seconds or not, time zone), date, day of week
- Pomodoro or "time since session started" timer
- Needs `refreshInterval` if it must tick while idle

**Extras**
- Now playing (Spotify or Apple Music via `osascript` on macOS)
- Weather or Claude service status (network calls: cache 5+ minutes, or skip)
- Custom text, emoji, or a mascot (`🤖`), a rotating tip or quote
- Output of any shell command they name (`custom command`), cached
- Subagent rows: a separate `subagentStatusLine` can customize rows for running subagents (see the official docs)

### Round 2: Layout

- Number of lines: 1, 2, or 3. Assign items to lines and order them.
- Separator: ` | `, ` · `, ` • `, ` ❯ `, `  ` (spaces), `/`, powerline arrows ``, or custom text.
- **Left and right groups:** flex spacing that pushes some items to the far right, using the `COLUMNS` environment variable (Claude Code sets it; `tput cols` does not work).
- **Narrow-terminal behavior:** switch to a compact form (drop labels, hide low-priority items, shorter bars) when `COLUMNS` is under a chosen width.
- Padding: the `statusLine.padding` setting adds horizontal spacing.
- Hide-when-empty rules per item, and "show only when" rules (for example only show cost over $1, only show the PR badge when a PR exists).

### Round 3: Look

**Bars and meters** (for context, rate limits, cache, battery, ...)
- Style: `▰▱` · `█░` · `▓░` · `●○` · `⣿⣀` braille · `[####----]` ASCII · sparkline blocks `▁▂▃▄▅▆▇█` · pie glyph `○◔◑◕●` · number only
- Width: 5, 8, 10, 20, or custom. Rounding: up, down, or nearest.
- Show used or remaining. Show the number next to the bar or not.
- Brackets or none.

**Labels**
- Full (`context`), short (`ctx`), single letter, emoji (`🧠 💸 ⏱`), Nerd Font icons, or none (minimalist, values only).
- Case and wrapping: `ctx:34%`, `ctx 34%`, `[ctx 34%]`, `ctx=34`.

**Numbers**
- Percent decimals (0 or 1), token format (`68k`, `68.2k`, `68,213`), money (`$0.42`, `42¢`), duration (`9m`, `1h05m`, `1:05:00`), 12 or 24-hour clock.

### Round 4: Color

- **Mode:** none, basic 16 colors, 256 colors, or truecolor (hex). Check `COLORTERM` for truecolor support.
- **Threshold editor** per meter: warn and critical cutoffs and their colors. Default: green under 50, yellow under 80, red at 80 and above. Let them set it per item (for example context at 60/85, rate limits at 70/90).
- **Palette themes:** Tokyo Night, Catppuccin (Mocha, Latte), Dracula, Gruvbox, Nord, Solarized, Monochrome, Rainbow, or custom hex per item.
- **Gradients:** bar that blends green to red across its length.
- **Per-item colors:** pick a color for each item, with dim labels and bright values, bold, or dim for secondary info.
- **Backgrounds:** colored "pills" or full Powerline segments (needs a Powerline font; offer to fall back to rounded or plain pills).
- **Blink or flash** on critical (warn that this can be annoying, and that some terminals ignore it).

### Round 5: Behavior

- **Refresh:** only on events (default), or `refreshInterval` every N seconds (minimum 1) for clocks and idle updates.
- **Scope:** global (`~/.claude/settings.json`) or just this project (`.claude/settings.json` in the repo).
- **Caching for slow items** (`git status` on huge repos, network calls, `kubectl`): cache in a temp file for N seconds. Never run network calls on every update.
- **Units and locale:** time zone, 12 or 24 hour, currency symbol.
- **Safety rule:** never put secrets (tokens, emails, account IDs) on the status line unless the user explicitly asks. It shows on screen shares and in screenshots.

### Last step of the interview

Summarize the choices in one table plus an ASCII mockup of the result, with sample data. Ask: **Build it, or change something?**

## Phase 3: Build

1. Write the agreed spec to `~/.claude/statusline.spec.md` (items, order, lines, separators, bars, colors, thresholds, behavior). Later requests like "make the bars longer" should only need a spec edit and a regenerate.
2. Generate `~/.claude/statusline.sh` from the spec. Rules:
   - Read stdin once: `input=$(cat)`. Parse with as few `jq` calls as practical (one `jq` call emitting tab-separated values is faster than many).
   - Every read uses `// empty`. Every item degrades gracefully when its value is missing: hide it, or show an empty bar.
   - Build each line by appending only non-empty parts so a hidden item never leaves a stray or doubled separator: `add() { [ -n "$1" ] && out="${out:+$out · }$1"; }`.
   - Speed budget: the script runs very often, so keep it under about 50 ms. Cache slow commands (see Round 5). Use `GIT_OPTIONAL_LOCKS=0` for git. Say so if the user asks for something slow.
   - Colors are ANSI via `printf '\033[...m'`, always reset at the end of each colored span. Use `printf '%b'` or `$'...'` so escapes render.
   - One `printf` or `echo` per output line.
   - Right-aligned groups: use `${COLUMNS:-80}` and visible length (strip ANSI first) to compute padding.
   - Clickable links use OSC 8: `printf '\033]8;;%s\033\\%s\033]8;;\033\\' "$url" "$text"`.
   - Validate numbers before arithmetic (`[[ $p =~ ^[0-9]+$ ]]`), and clamp percentages to 0 to 100.
3. `chmod +x` the script.

### Reference: tiny default preset

`jeremy | Sonnet 5.5 | ctx:6% | 5h:[███░░░░░░░] 7d:[██░░░░░░░░]` (this repo's `statusline.sh`):

```bash
#!/bin/bash
input=$(cat)

user=$(whoami)
model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
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

[ -n "$ctx" ] && ctx="${ctx%.*}%" || ctx="--"

printf '%s | %s | ctx:%s | 5h:%s 7d:%s\n' \
  "$user" "$model" "$ctx" "$(bar "$h5")" "$(bar "$d7")"
```

## Phase 4: Preview and iterate

1. Run the script against the captured sample and made-up edge cases: 0%, mid, 100%, missing fields (`echo '{}'`), no git repo, very long directory names, `COLUMNS=40`.
   ```bash
   ~/.claude/statusline.sh < ~/.claude/statusline-sample.json
   COLUMNS=40 ~/.claude/statusline.sh < ~/.claude/statusline-sample.json
   ```
2. Show the output. If ANSI colors do not render in your preview, describe the colors and show a `cat -v` view, or print a plain version.
3. Time it (`time`): if over about 100 ms, find the slow part and cache it.
4. Ask "Happy with this, or want to tweak something?" Update the spec, regenerate, and repeat until they approve.

## Phase 5: Install

Read `~/.claude/settings.json` first and merge. Never overwrite the user's other settings. If the file does not exist, create it. Set only the `statusLine` key (use the project's `.claude/settings.json` if they chose project scope):

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 0,
    "refreshInterval": 30,
    "hideVimModeIndicator": false
  }
}
```

Include `refreshInterval` only for time-based items, `hideVimModeIndicator` only if vim mode is shown, and `padding` only if they asked for it.

Delete `~/.claude/statusline-sample.json` when done (it can contain session data). Tell the user to restart Claude Code or send a message to see it, then finish with:

> To change it later, say "customize my status line", and I'll read `~/.claude/statusline.spec.md` and update it.

## Troubleshooting

- **Nothing appears:** check `statusLine` is valid JSON in settings, the script is executable, and it prints to stdout with exit code 0. Run it by hand with the sample.
- **Shows `--` or empty values:** the field is absent for this account or model. Check the sample.
- **Garbled characters or `\033` text:** use `printf '%b'` or `$'...'`; check the terminal font supports the glyphs.
- **Lag:** an item is slow. Cache it.
- **Links not clickable:** the terminal does not support OSC 8.
- **Truncated or wrapped:** shorten items, use compact mode on small `COLUMNS`.

## Undo

Remove the `statusLine` key from `~/.claude/settings.json`, and restore `~/.claude/statusline.sh.bak` if a backup was made.

## Credits and ideas

This menu borrows ideas from [ccstatusline](https://github.com/sirmalloc/ccstatusline), [cship](https://docs.rs/crate/cship/1.1.2), [cc-statusline](https://github.com/chongdashu/cc-statusline), [starship-claude](https://github.com/martinemde/starship-claude), and the official [status line docs](https://code.claude.com/docs/en/statusline).
