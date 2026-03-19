# Focus — Agent Notes

## Specification
- `SPEC.md` is the primary source of truth for product behavior and user-facing requirements.
- Consult `SPEC.md` before making implementation changes.
- If a change affects user-facing behavior, packaging behavior, or any documented contract, update `SPEC.md` alongside the code.
- Avoid duplicating feature details here; keep behavior documentation in `SPEC.md`.

## Project Structure
- `src/` is the SwiftPM package root.
- `src/Package.swift` defines the package.
- `src/Sources/Focus/FocusApp.swift` contains the app source.
- `src/Bundle/Info.plist` contains app bundle metadata.
- `src/Bundle/Resources/AppIcon.icns` contains the app icon asset.
- `Makefile` contains the build and install workflows.

## Build and Packaging
- Build with `make build`.
- Install locally with `make install`.
- The underlying build command is: `swift build --package-path src --scratch-path .build -c release`
- App bundle assembly output is: `.build/Focus.app`
- Local install destination is: `~/Applications/Focus.app`

## Workflow Notes
- Use terminal-based workflow only; do not rely on Xcode project files or Xcode UI.
- No code signing or distribution setup is required for local builds unless the task explicitly asks for it.
