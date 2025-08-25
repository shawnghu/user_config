#!/bin/bash
# Claude Bash Command Logger
# Logs all bash commands executed by Claude to ~/.claude_command_log.txt
# Called by Claude's PostToolUse hook

# Read the JSON input from stdin
input=$(cat)

# Debug: log the raw input
echo "DEBUG INPUT: $input" >> ~/.claude_command_log_debug.txt

# Extract fields from the JSON input using jq or python
# If jq is not available, fall back to python
if command -v jq &> /dev/null; then
    # Use jq to parse JSON
    command=$(echo "$input" | jq -r '.tool_input.command // empty')
    description=$(echo "$input" | jq -r '.tool_input.description // empty')
    cwd=$(echo "$input" | jq -r '.cwd // empty')
    sessionId=$(echo "$input" | jq -r '.session_id // empty')
    timestamp=$(echo "$input" | jq -r '.timestamp // empty')
else
    # Fall back to python
    command=$(echo "$input" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except:
    pass
")
    description=$(echo "$input" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('description', ''))
except:
    pass
")
    cwd=$(echo "$input" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('cwd', ''))
except:
    pass
")
    sessionId=$(echo "$input" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('session_id', ''))
except:
    pass
")
    timestamp=$(echo "$input" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('timestamp', ''))
except:
    pass
")
fi

# Format the timestamp to be more readable
if [[ -n "$timestamp" ]]; then
    # Convert ISO timestamp to format similar to hcmnt
    formatted_time=$(date -d "$timestamp" "+%Y%m%d %R" 2>/dev/null || echo "$timestamp")
else
    formatted_time=$(date "+%Y%m%d %R")
fi

# Build the log entry similar to hcmnt format
# Format: command ### [CLAUDE] description timestamp cwd sessionId
log_entry="$command ### [CLAUDE]"

if [[ -n "$description" ]]; then
    log_entry="$log_entry $description"
fi

log_entry="$log_entry $formatted_time"

if [[ -n "$cwd" ]]; then
    log_entry="$log_entry $cwd"
fi

if [[ -n "$sessionId" ]]; then
    log_entry="$log_entry session:${sessionId:0:8}"
fi

# Append to both log files
echo "$log_entry" >> ~/.bash_extended_log
echo "$log_entry" >> ~/.claude/bash_command_log.txt

# Exit successfully to allow the command to proceed
exit 0