# Focus Functional Specification

## 1. Purpose

This document defines **Focus** and serves as the primary source of truth for the product.

Implementations, refactors, and future features conform to this specification. When functionality changes, this document changes with it so contributors and AI agents can rely on it as the authoritative description of the app.

---

## 2. Product Overview

**Focus** is a native macOS menu bar app for tracking a single active focus session.

The app:
- lives in the macOS menu bar
- displays the current or last recorded elapsed focus time as plain text
- lets the user start or stop timing from the menu
- lets the user toggle timing with a global hotkey
- automatically stops timing when the screen locks
- provides no main window, settings UI, or persistence layer unless this specification changes

The product remains intentionally minimal and session-based.

---

## 3. Scope

The product scope includes:
- one focus timer
- menu bar display of elapsed time
- Start and Stop controls in the menu
- Quit action in the menu
- global hotkey toggle
- automatic stop on screen lock
- local build, install, and zip release packaging

---

## 4. Platform and Runtime Requirements

### 4.1 Platform
Focus targets:
- operating system: **macOS 26.0+**
- app type: **LSUIElement agent app** (menu bar only, no Dock icon)
- language: **Swift**
- UI framework: **SwiftUI**

The implementation uses the system frameworks needed to fulfill the behavior in this spec, including:
- AppKit
- Carbon
- SwiftUI

### 4.2 Package metadata
The package and bundle metadata is:
- package name: `Focus`
- executable product name: `Focus`
- bundle identifier: `com.erazemk.Focus`
- bundle display name: `Focus`
- bundle short version: `1.0`
- bundle version: `1`

---

## 5. User-Facing Application Model

### 5.1 App presence
Focus runs as a menu bar app.

The app:
- exposes a single menu bar extra
- uses the timer text itself as the visible menu bar label
- does not open a normal application window
- does not appear as a Dock app because `LSUIElement` is enabled

### 5.2 Menu bar title
The menu bar title always equals the formatted display string for the timer.

Examples:
- `0s`
- `9s`
- `1m`
- `1m 8s`
- `1h`
- `1h 2m`
- `1h 2m 3s`

The title updates reactively as timer state changes.

### 5.3 Initial state
On launch, Focus initializes to:
- timer state: **stopped**
- elapsed time: `0`
- menu bar display: `0s`

---

## 6. Timer Functional Specification

### 6.1 Timer model
Focus contains exactly one in-memory timer represented by two user-visible state values:
- `isRunning: Bool`
- `elapsedSeconds: Int`

Timer state exists only in memory for the lifetime of the app process unless this specification extends persistence.

### 6.2 Start behavior
When the user starts Focus, the app:
1. resets elapsed time to `0`
2. sets running state to `true`
3. starts the internal repeating timer
4. shows the first visible increment after approximately 1 second

Important rule:
- **Starting always resets the timer to zero**, even if the app is displaying a previously stopped value such as `12m 4s`

Focus does not implement resume behavior unless this specification changes.

### 6.3 Running behavior
While running, Focus:
- increases elapsed time by 1 second at 1-second intervals
- updates the menu bar display once per second
- continues counting until the user stops it, the screen locks, the app quits, or the maximum duration is reached

The implementation uses a repeating timer mechanism that begins roughly 1 second after start and repeats every 1 second.

### 6.4 Stop behavior
When the user stops Focus, the app:
1. sets running state to `false`
2. cancels the internal repeating timer
3. preserves and continues displaying the current elapsed value

Stopping does **not** clear elapsed time.

Examples:
- if stopped at `17s`, the menu bar continues to show `17s`
- if stopped at `2h 4m 9s`, the menu bar continues to show `2h 4m 9s`

### 6.5 Toggle behavior
Focus supports a toggle operation:
- if currently running, toggle performs **stop**
- if currently stopped, toggle performs **start**

Because start resets elapsed time, toggling from stopped begins a brand new session from `0s`.

### 6.6 Maximum duration
The maximum supported elapsed value is:
- `23h 59m 59s`
- numerically: `86399` seconds

Behavior at the limit:
- the timer increments up to `86399`
- on the next scheduled tick, the app stops the timer automatically
- the displayed value remains `23h 59m 59s`

The app does not roll into days or display values such as `24h` or `1d`.

### 6.7 Persistence rules
Unless this specification extends persistence, Focus follows these rules:
- no session state is saved to disk
- quitting the app discards the current elapsed value
- relaunching the app returns to stopped state at `0s`

---

## 7. Duration Formatting Specification

The display string is derived from integer seconds.

### 7.1 Units
Supported units are:
- hours (`h`)
- minutes (`m`)
- seconds (`s`)

### 7.2 Formatting rules
The formatter obeys these rules:
1. Hours appear only if hours > 0.
2. Minutes appear only if minutes > 0.
3. Seconds appear if:
   - seconds > 0, or
   - no higher unit has been shown yet.
4. Units are separated by a single space.
5. Units are not zero-padded.
6. Singular and plural use the same abbreviated suffix (`1s`, `1m`, `1h`).

### 7.3 Examples
| Seconds | Display |
|---|---|
| 0 | `0s` |
| 5 | `5s` |
| 59 | `59s` |
| 60 | `1m` |
| 61 | `1m 1s` |
| 119 | `1m 59s` |
| 3600 | `1h` |
| 3601 | `1h 1s` |
| 3660 | `1h 1m` |
| 3661 | `1h 1m 1s` |
| 7199 | `1h 59m 59s` |
| 86399 | `23h 59m 59s` |

### 7.4 Omission behavior
The formatter omits zero-value units when a higher unit is present.

Examples:
- `1h 0m 0s` displays as `1h`
- `1h 0m 5s` displays as `1h 5s`
- `0h 3m 0s` displays as `3m`

---

## 8. Menu Specification

The menu bar extra opens a standard menu.

### 8.1 Menu items
The menu contains these items in this order:
1. `Start`
2. `Stop`
3. separator
4. `Quit`

### 8.2 Start command
The Start command:
- invokes timer start
- uses keyboard shortcut `⌘S`
- is enabled only when the timer is stopped
- is disabled while the timer is running

### 8.3 Stop command
The Stop command:
- invokes timer stop
- uses keyboard shortcut `⌘S`
- is enabled only when the timer is running
- is disabled while the timer is stopped

### 8.4 Shared shortcut behavior
Start and Stop share the same shortcut, `⌘S`.

Because one of the two commands is always disabled, the effective behavior is state-dependent:
- when stopped, `⌘S` starts the timer
- when running, `⌘S` stops the timer

### 8.5 Quit command
The Quit command:
- terminates the app process
- uses keyboard shortcut `⌘Q`
- remains enabled at all times

### 8.6 Menu style
The menu bar extra uses a standard menu interaction model.

The app does not use a detached custom popover or custom window UI unless this specification changes.

---

## 9. Global Hotkey Specification

### 9.1 Hotkey
The app registers a global hotkey with:
- key: `F`
- modifiers: `Control + Option`
- user-facing combination: **Ctrl + Option + F**

### 9.2 Behavior
When the hotkey is pressed while the app is running:
- if the timer is stopped, Focus starts a new session from `0s`
- if the timer is running, Focus stops the current session

This hotkey uses the same toggle semantics defined in Section 6.5.

### 9.3 Registration lifecycle
Focus registers the global hotkey during app launch.

Focus unregisters the global hotkey during app termination.

### 9.4 Failure behavior
If hotkey registration fails:
- the app logs an error
- the app continues running
- the app does not display an in-app alert, banner, or fallback UI unless this specification changes

If event handler installation fails:
- the app logs an error
- the app does not present additional user-facing recovery flow unless this specification changes

### 9.5 Configuration
The hotkey is fixed and not user-configurable.

The user cannot:
- disable it from the UI
- remap it
- choose different modifiers

---

## 10. Screen Lock Behavior

### 10.1 Observed event
Focus observes the distributed notification:
- `com.apple.screenIsLocked`

### 10.2 Behavior on lock
When the screen locks:
- if the timer is running, the app stops it
- if the timer is already stopped, nothing changes

### 10.3 Resulting state after auto-stop
When screen lock triggers an automatic stop:
- `isRunning` becomes `false`
- elapsed time remains at the last recorded value
- the menu bar continues displaying that final value

### 10.4 Unlock behavior
The app does not resume automatically on unlock.

---

## 11. Quit and Lifecycle Behavior

### 11.1 Launch
On launch, Focus:
1. creates the menu bar scene
2. initializes the shared timer object
3. installs the hotkey toggle callback
4. registers the global hotkey
5. subscribes to screen-lock notifications

### 11.2 Termination
On termination, Focus:
- removes the screen-lock observer
- unregisters the global hotkey
- exits the process

### 11.3 Data retention on quit
Quit does not persist timer state.

Any current or previous elapsed value is lost when the process exits.

---

## 12. Non-Functional UX Characteristics

### 12.1 Minimal surface area
Focus maintains a deliberately minimal UX.

Unless this specification changes, the app provides:
- no icon in the menu bar title area beyond standard menu bar rendering
- no settings window
- no onboarding
- no confirmation dialogs
- no notifications

### 12.2 Responsiveness
All user-visible timer and menu updates occur on the main actor or main queue so state and UI remain synchronized.

### 12.3 Single-session design
The app is organized around one current session only.

The product does not introduce named sessions, tags, projects, or categories unless this specification changes.

---

## 13. Error Handling and Edge Cases

### 13.1 Starting while already running
The UI disables Start while the timer is running.

If internal logic invokes start while already running, the app treats it as a fresh start: elapsed time resets to `0`, and the repeating timer restarts.

### 13.2 Stopping while already stopped
The UI disables Stop while the timer is stopped.

If internal logic invokes stop while already stopped, the app remains stopped and preserves the displayed elapsed value.

### 13.3 Repeated hotkey registration attempts
The hotkey manager avoids registering the same hotkey more than once simultaneously.

### 13.4 Max-time stop
When the timer reaches maximum duration, the app stops automatically without presenting any message unless this specification changes.

### 13.5 Lock while stopped
If a screen-lock notification is received while the timer is stopped, the app shows no visible change.

---

## 14. Packaging and Distribution Specification

### 14.1 Build system
The project uses Swift Package Manager and exposes a single executable target.

The package root is:
- `src/`

The primary runtime source file is:
- `src/Sources/Focus/FocusApp.swift`

### 14.2 Build target
Package configuration defines:
- one executable target named `Focus`
- package manifest at `src/Package.swift`
- source files under `src/Sources/Focus/`
- bundle assembly inputs under `src/Bundle/`

### 14.3 App bundle assembly
`make build` performs the following:
1. runs `swift build --package-path src --scratch-path .build -c release`
2. creates `.build/Focus.app/Contents/MacOS`
3. creates `.build/Focus.app/Contents/Resources`
4. copies the built executable to `.build/Focus.app/Contents/MacOS/Focus`
5. copies `src/Bundle/Info.plist` into the app bundle
6. copies `src/Bundle/Resources/AppIcon.icns` into app bundle resources

### 14.4 Install behavior
`make install`:
1. builds the app bundle
2. stops an already-running `Focus` process if one exists
3. removes any existing `~/Applications/Focus.app`
4. copies the newly built app bundle into `~/Applications/`

Additional requirements:
- removal uses `trash`, not `rm`
- `make` with no target defaults to install behavior via `all: install`

### 14.5 Release packaging
`make release`:
1. builds the app bundle
2. finds the most recent git tag
3. creates `.build/Focus-<tag>.zip`
4. packages the `.app` bundle using `ditto -c -k --sequesterRsrc --keepParent`

If no git tag exists, release packaging fails with an error.

### 14.6 App icon
The bundle uses:
- `CFBundleIconFile = AppIcon.icns`

The icon asset is included in the built app bundle's resources.

### 14.7 Quarantine note
Documentation may instruct users that downloaded releases can be unquarantined with:

```bash
xattr -dr com.apple.quarantine Focus.app
```

This remains a distribution note, not an app runtime feature.

---

## 15. Repository File Roles

The repository assigns the following roles to key files:

- `src/Sources/Focus/FocusApp.swift` — runtime behavior, including app scene, timer, app delegate, hotkey management, and duration formatting
- `src/Package.swift` — SwiftPM package definition and macOS platform requirement
- `src/Bundle/Info.plist` — app bundle metadata, identifier, icon, version, LSUIElement mode, and minimum OS version
- `Makefile` — build, install, and release automation plus app bundle assembly
- `src/Bundle/Resources/AppIcon.icns` — packaged application icon asset
- `README.md` — concise human-facing description and quarantine note
- `AGENTS.md` — project guidance for automated contributors
- `.gitignore` — ignored local and build artifacts
- `.vscode/launch.json` — editor launch configurations for debug and release execution

---

## 16. Change Management Rules for Future Work

To keep this specification authoritative, future work follows these rules:

1. **Any new user-facing behavior appears in this spec.**
2. **If a new feature changes existing behavior, the relevant section changes instead of only appending notes.**
3. **If implementation differs from this spec, the difference is treated as a bug or an intentional spec change; it does not remain ambiguous.**
4. **New controls specify:**
   - user action
   - state transitions
   - shortcuts
   - enabled/disabled logic
   - persistence behavior
   - failure behavior
5. **New background behavior specifies:**
   - trigger/event source
   - resulting state changes
   - user-visible consequences
6. **New data specifies:**
   - storage location
   - lifetime
   - reset rules
   - migration/versioning needs if persisted

---

## 17. Functional Contract Summary

Focus satisfies all of the following:
- it is a menu bar-only macOS app
- it displays one elapsed-time value as text in the menu bar
- it starts and stops a single in-memory timer
- starting always resets the timer to `0s`
- stopping preserves the last elapsed value on screen
- `⌘S` acts as Start or Stop depending on current state
- `⌘Q` quits the app
- `Ctrl + Option + F` toggles the timer globally while the app is running
- screen lock stops an active timer
- no data persists across app launches
- timing is capped at `23h 59m 59s`

Future changes build on this contract by updating this specification first or alongside the code change.
