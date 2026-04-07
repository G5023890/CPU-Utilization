# CPU MenuBar

Minimal macOS menu bar app that shows the current CPU usage as a plain percentage.

## Build

Requires Xcode 26+ and `xcodegen`.

```bash
xcodegen generate
xcodebuild -project "CPU MenuBar.xcodeproj" -scheme "CPU MenuBar" build
```

## Behavior

- Runs as a menu bar only app
- Updates once per second
- Shows only the current CPU percent in the menu bar
- Uses a low-overhead polling interval to keep energy use reasonable
- Opens a tiny preferences popover from the status item
- Optionally highlights high CPU usage in red above a configurable threshold

## License
Apache-2.0
