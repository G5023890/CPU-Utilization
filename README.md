# CPU MenuBar

Ultra-minimal macOS menu bar app that shows the current CPU usage as a thin open arc with a centered number.

Current version: `0.7`

## Build

Requires Xcode 26+.

xcodebuild -project "CPU MenuBar.xcodeproj" -scheme "CPU MenuBar" build
```

## Behavior

- Runs as a menu bar only app
- Updates once per second
- Shows CPU usage as a monochrome indicator with no percent sign
- Uses a low-overhead polling interval to keep energy use reasonable
- Smooths the signal to avoid jitter

## Visual Preview

![CPU MenuBar preview](CPU%20MenuBar/BrandAssets/cpu-menubar-preview.png)

## License
Apache-2.0
