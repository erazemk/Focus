# Focus — Agent Notes

## App Summary
- Native macOS menu bar app named **Focus**.
- Counts focused time in seconds and can be started/stopped via a global shortcut.
- Menu bar shows **only the elapsed time** (no icon, no app name).

## Platform & Tech
- Language: Swift
- UI: SwiftUI (menu bar only; no custom windows)
- Libraries: Standard library only
- Target: macOS 26
- Bundle ID: `com.erazemk.Focus`
- No Xcode UI; terminal-only workflow.
- No code signing or distribution required (local `.app` only).

## Menu Bar Behavior
- Standard menu with:
  - Start (Cmd+S)
  - Stop (Cmd+S)
  - Quit (Cmd+Q)
- Start/Stop share Cmd+S:
  - If stopped: Start enabled, Stop disabled, Cmd+S starts.
  - If running: Stop enabled, Start disabled, Cmd+S stops.
- Quit always enabled.

## Global Shortcut
- System-wide hotkey: `Ctrl + Option + F` toggles start/stop.
- Use standard global hotkey registration approach (may prompt for permissions).

## Timer Rules
- Display format:
  - `1s..59s`
  - `1m, 1m 1s .. 59m 59s`
  - `1h, 1h 1s, 1h 59s, 1h 1m, ...`
- Max: under 24 hours (no days).
- Stopped state keeps last elapsed time visible.
- Stopped → started resets to 0 and begins counting.
- No persistence/history beyond the current session.

## Packaging (Terminal-First)
- SwiftPM project with a single `FocusApp.swift` at repo root.
- Build with `make`:
  - `swift build -c release`
  - Assemble `.app` inside `.build/Focus.app`
  - Copy to `~/Applications/Focus.app`
- App icon:
  - `AppIcon.icns` is used via `CFBundleIconFile`.
  - Copied into `.app/Contents/Resources/`.
