# TabScreen

macOS SwiftUI app (menu bar + window) that sets up and controls Sunshine and a virtual display so an Android tablet (Moonlight) works as a Mac's wireless second screen. Free, open source (MIT), no ads. Repo: github.com/yetkina/TabScreen (public).

## Layout
- `Sources/Shell.swift` — Process helper (zsh with Homebrew PATH).
- `Sources/Model.swift` — `AppModel`: detection (brew, Sunshine, Crisp, displays), launchd control, installs, config writing, language (`t("en","tr")`).
- `Sources/Views.swift` — pages: Control, Setup, How-to & Help, About (`AppInfo` holds author/email/website/sponsor URL).
- `Sources/Diagrams.swift` — illustrated scenes for the guide (`DiagramScene`; do not name a type `Scene`, it clashes with SwiftUI).
- `Tools/make_icon.swift` — draws the app icon. `build.sh` builds `build/TabScreen.app` (swiftc, no Xcode project). `release.sh` signs, notarizes, staples and makes the `.dmg`.

## Conventions
- All UI text is bilingual: add both English and Turkish via `m.t(en, tr)`. README has separate `English (EN)` and `Türkçe (TR)` sections; keep them in sync.
- Commit author: `Yetkin AYDIN <info@yaydin.com>` (set per-repo, not global). Never use the personal Gmail in commits or in the app.
- Sunshine is controlled through its brew launchd agent (`sh.brew.sunshine`); auto-start = `RunAtLoad` in its plist; the streamed display is `output_name` in `~/.config/sunshine/sunshine.conf`.
- Not sandboxed on purpose (runs brew/launchctl, writes config), so it cannot go in the Mac App Store. Distribute via GitHub Releases.
- Support: GitHub Sponsors only (`.github/FUNDING.yml`, About page). Do not add IBAN/Papara.
- Secrets (passwords, tokens, app-specific passwords) must never be typed into the chat. Tell the user to run such commands in a separate Terminal without `!`.

## Releasing a new version
1. Bump `CFBundleShortVersionString` / `CFBundleVersion` in the Info.plist heredoc in `build.sh`.
2. Commit and push to `main`.
3. `./release.sh` — needs the "Developer ID Application" certificate in the login keychain and the notarytool keychain profile named `tabscreen` (create with `xcrun notarytool store-credentials "tabscreen" ...` in a separate Terminal; it needs a fresh app-specific password from appleid.apple.com). Output: `build/TabScreen-<version>.dmg`.
4. `gh release create v<version> build/TabScreen-<version>.dmg --repo yetkina/TabScreen --title "TabScreen <version>"` with bilingual notes and the SHA-256.

## State / to do
- v1.0 is released and notarized.
- The old app-specific password for the `tabscreen` profile was shown in a chat; the user should revoke it at appleid.apple.com and create a new one before the next release.
- Not verified yet: the full "install from scratch" flow on a Mac without Sunshine/Crisp, and download-and-open of the `.dmg` on another Mac.
