# CopyCat clone — setup notes

## Adding the files
1. Create a new **macOS App** target in Xcode (SwiftUI lifecycle).
2. Delete the generated `ContentView.swift` and the default `...App.swift`.
3. Drag all the `.swift` files here into the project (checked into your target).

## Info.plist / capabilities
- **Disable App Sandbox** (Signing & Capabilities tab). This app needs to:
  - read `NSPasteboard.general` continuously,
  - install a **global** keyboard event monitor (Cmd+Shift+V from anywhere),
  - post a synthetic Cmd+V into whatever app was frontmost.
  None of these are permitted for a sandboxed app — this is why third-party
  clipboard managers (Paste, Maccy, CopyCat, etc.) all ship unsandboxed,
  usually distributed outside the Mac App Store or notarized directly.
- Add `LSUIElement = YES` to Info.plist (belt-and-suspenders alongside the
  `NSApp.setActivationPolicy(.accessory)` call in `AppDelegate`) so the Dock
  icon never flashes on launch.

## Permissions the user will be asked for
- **Input Monitoring** — the first time `HotKeyManager` installs its global
  monitor, macOS prompts automatically.
- **Accessibility** — required for `CGEvent(...).post(...)` in
  `PasteHelper` to actually type Cmd+V into another app. There's no way to
  trigger this prompt programmatically for CGEvent posting; point users to
  System Settings > Privacy & Security > Accessibility the first time paste
  silently does nothing.

## What's implemented
- `ClipboardManager` — polls the pasteboard, de-dupes, keeps last 20 items.
- `ClipboardItem` — detects **links**, **hex colors**, **phone numbers**,
  **plain numbers**, falling back to **text**.
- `ClipboardPanelController` / `ClipboardPanelView` — the borderless,
  floating panel: search field, category pills (All/Text/Links/Colors),
  list with per-row keyboard shortcut (⌘1–⌘9), footer key hints.
  - ↑ / ↓ moves the selection
  - ← / → cycles category tabs
  - Return pastes the selected item
  - Delete/Backspace removes it
  - Esc closes the panel
- `StatusBarController` — draws the squircle-outline menu bar icon with a
  live badge count, and its dropdown menu (Show Copy Stack ⌘⇧V, Pause,
  Settings…, Check for Updates…, Quit).
- `OnboardingView` — the two-page welcome / "you're all set" flow with the
  login-item checkbox, shown once via a `UserDefaults` flag.
- `LaunchAtLogin` — thin `SMAppService` wrapper (macOS 13+).

## Known-fixed issues
- **Paste doing nothing**: two causes, both handled now —
  1. Showing the panel activates our own app, so without explicitly handing
     focus back, the synthesized Cmd+V landed on ourselves. `paste(_:)` now
     reactivates whichever app was frontmost before the panel opened.
  2. `CGEventPost` is silently a no-op without Accessibility permission.
     `AppDelegate` now calls `PasteHelper.ensureAccessibilityPermission()`
     at launch, which triggers the system prompt. Grant it in
     System Settings > Privacy & Security > Accessibility, then relaunch.
- **"Pause" not un-pausing**: it was actually toggling correctly, but the
  menu item's title never changed away from "Pause", so a second click
  looked like it did nothing. It now flips to "Resume" once paused.

## Things left as stubs, on purpose
- `SettingsWindowController` is a one-line placeholder — wire up whatever
  preferences you actually want (max history size, ignored apps, etc.).
- "Check for Updates…" does nothing yet — hook in Sparkle or your own
  update check.
- Pinning (footer shows ⌘P) isn't implemented — would just mean adding a
  `pinned: Bool` to `ClipboardItem` and sorting pinned items to the top.
