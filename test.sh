#!/bin/bash
# Smoke test: feed sample status line JSON to the script.
echo '{"model":{"display_name":"Sonnet 5.5"},"context_window":{"used_percentage":6},"rate_limits":{"five_hour":{"used_percentage":30},"seven_day":{"used_percentage":20}}}' | "$(dirname "$0")/statusline.sh"
