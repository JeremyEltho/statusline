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
