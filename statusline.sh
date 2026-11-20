#!/usr/bin/env python3
import sys
import json
import os
import subprocess
import re

def visible_length(s):
    # Strip ANSI escape sequences to compute true visible character length
    ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
    return len(ansi_escape.sub('', s))

def main():
    raw_input = sys.stdin.read()
    
    # Save payload for debugging if needed
    try:
        with open('/tmp/agy_statusline_payload.json', 'w') as f:
            f.write(raw_input)
    except Exception:
        pass

    try:
        data = json.loads(raw_input) if raw_input.strip() else {}
    except Exception:
        data = {}

    # Check if --dangerously-skip-permissions is enabled
    is_yolo = False
    if data.get("dangerously_skip_permissions") or data.get("tool_permission") == "always-proceed":
        is_yolo = True
    else:
        try:
            ppid = os.getppid()
            res = subprocess.run(["ps", "-p", str(ppid), "-o", "args="], capture_output=True, text=True, timeout=1)
            if "dangerously-skip-permissions" in res.stdout:
                is_yolo = True
            else:
                res2 = subprocess.run(["pgrep", "-a", "-f", "agy.*--dangerously-skip-permissions"], capture_output=True, text=True, timeout=1)
                if res2.stdout.strip():
                    is_yolo = True
        except Exception:
            pass

    # ANSI Colors matching the original minimal style
    RESET = "\033[0m"
    GRAY = "\033[90m"
    YELLOW = "\033[1;33m"
    MAGENTA = "\033[35m"

    # Terminal width
    term_width = data.get("terminal_width")
    if not term_width or term_width <= 0:
        try:
            term_width = os.get_terminal_size().columns
        except Exception:
            term_width = 80

    # Left side: original subtle hint
    left_str = f"{GRAY}? for shortcuts{RESET}"

    # Model Name (with reasoning effort if specified)
    model_obj = data.get("model", {})
    model_name = model_obj.get("display_name") or model_obj.get("id") or "Gemini 3.8 Flash (High)"
    effort = data.get("effort") or data.get("reasoning_effort")
    if effort and effort.lower() not in model_name.lower():
        model_name = f"{model_name} ({effort.capitalize()})"

    # Context window % (if active)
    ctx = data.get("context_window", {})
    used_pct = ctx.get("used_percentage")
    ctx_str = f"{used_pct:.0f}%" if used_pct is not None and used_pct > 0 else ""

    # Mode / YOLO indicator
    mode = data.get("mode", "auto")
    if is_yolo:
        mode_str = f"{YELLOW}⚡ yolo{RESET}"
    else:
        mode_str = f"{GRAY}{mode}{RESET}"

    # State indicator (only shown when actively running/thinking)
    agent_state = data.get("agent_state", "idle")
    state_str = ""
    if agent_state not in ("idle", "done", "ready", ""):
        state_str = f"{MAGENTA}{agent_state}...{RESET}"

    # Build right-hand elements (matching original spacing)
    right_items = []
    if state_str:
        right_items.append(state_str)
    if model_name:
        right_items.append(f"{GRAY}{model_name}{RESET}")
    if ctx_str:
        right_items.append(f"{GRAY}{ctx_str}{RESET}")
    right_items.append(mode_str)

    right_str = "   ".join(right_items)

    # Calculate padding to push to right margin
    left_len = visible_length(left_str)
    right_len = visible_length(right_str)
    spaces_count = max(1, term_width - left_len - right_len - 2)
    padding = " " * spaces_count

    print(f" {left_str}{padding}{right_str} ")

if __name__ == "__main__":
    main()
