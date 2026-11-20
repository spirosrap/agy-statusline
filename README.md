# agy-statusline

Minimalist custom status line for Google Antigravity CLI (`agy`).

Preserves the original status bar format while dynamically detecting `--dangerously-skip-permissions` to show `⚡ yolo`.

## Usage

Configure in `~/.gemini/antigravity-cli/settings.json`:

```json
{
  "statusLine": {
    "command": "~/.gemini/antigravity-cli/statusline.sh",
    "enabled": true
  }
}
```

Activate inside `agy`:
```text
/statusline on
```
