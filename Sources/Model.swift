import SwiftUI
import AppKit
import CoreGraphics

struct DisplayInfo: Identifiable, Hashable {
    let id: UInt32
    let name: String
    let width: Int
    let height: Int
    let isMain: Bool
    let isBuiltin: Bool
    var looksVirtual: Bool { name.lowercased().contains("virtual") }
}

@MainActor
final class AppModel: ObservableObject {
    static let formula = "lizardbyte/homebrew/sunshine"
    static let tap = "lizardbyte/homebrew"
    static let label = "sh.brew.sunshine"
    static let brewInstallCommand = "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""

    // MARK: Language
    @Published var lang: String { didSet { UserDefaults.standard.set(lang, forKey: "lang") } }
    var isTurkish: Bool {
        if lang == "tr" { return true }
        if lang == "en" { return false }
        return (Locale.preferredLanguages.first ?? "en").hasPrefix("tr")
    }
    func t(_ en: String, _ tr: String) -> String { isTurkish ? tr : en }

    // MARK: State
    @Published var brewInstalled = false
    @Published var sunshineInstalled = false
    @Published var sunshineRunning = false
    @Published var autostart = false
    @Published var plistExists = false
    @Published var crispInstalled = false
    @Published var displays: [DisplayInfo] = []
    @Published var configuredOutput: UInt32? = nil
    @Published var ip: String = "—"
    @Published var log: String = ""
    @Published var busy = false
    @Published var busyTitle = ""
    @Published var message: String? = nil

    private var timer: Timer?

    var home: String { NSHomeDirectory() }
    var plist: String { home + "/Library/LaunchAgents/\(Self.label).plist" }
    var confPath: String { home + "/.config/sunshine/sunshine.conf" }
    var sunshineLogPath: String { home + "/.config/sunshine/sunshine.log" }

    init() {
        lang = UserDefaults.standard.string(forKey: "lang") ?? "auto"
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    // MARK: Detection
    nonisolated static func findSunshine() -> String? {
        let candidates = ["/opt/homebrew/opt/sunshine/bin/sunshine",
                          "/usr/local/opt/sunshine/bin/sunshine",
                          "/Applications/Sunshine.app/Contents/MacOS/sunshine"]
        for c in candidates where FileManager.default.isExecutableFile(atPath: c) { return c }
        let r = Shell.run("command -v sunshine")
        let p = r.out.trimmingCharacters(in: .whitespacesAndNewlines)
        return (r.status == 0 && !p.isEmpty) ? p : nil
    }

    nonisolated static func detectCrisp() -> Bool {
        let fm = FileManager.default
        if fm.fileExists(atPath: "/opt/homebrew/Caskroom/crisp") || fm.fileExists(atPath: "/usr/local/Caskroom/crisp") { return true }
        if fm.fileExists(atPath: "/Applications/Crisp.app") || fm.fileExists(atPath: NSHomeDirectory() + "/Applications/Crisp.app") { return true }
        let r = Shell.run("mdfind \"kMDItemFSName == 'Crisp.app'\" | head -1")
        return !r.out.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    nonisolated static func localIP() -> String {
        var addr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addr) == 0, let first = addr else { return "—" }
        defer { freeifaddrs(addr) }
        var best = "—"
        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let cur = ptr {
            let name = String(cString: cur.pointee.ifa_name)
            if let sa = cur.pointee.ifa_addr, sa.pointee.sa_family == UInt8(AF_INET), name.hasPrefix("en") {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(sa, socklen_t(sa.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
                let s = String(cString: host)
                if !s.hasPrefix("169.254") { if best == "—" || name == "en0" { best = s } }
            }
            ptr = cur.pointee.ifa_next
        }
        return best
    }

    static func readDisplays() -> [DisplayInfo] {
        var count: UInt32 = 0
        var ids = [CGDirectDisplayID](repeating: 0, count: 16)
        CGGetOnlineDisplayList(16, &ids, &count)
        var names: [UInt32: String] = [:]
        for s in NSScreen.screens {
            if let n = s.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
                names[n.uint32Value] = s.localizedName
            }
        }
        return ids.prefix(Int(count)).map { id in
            DisplayInfo(id: id, name: names[id] ?? "Display \(id)",
                        width: Int(CGDisplayPixelsWide(id)), height: Int(CGDisplayPixelsHigh(id)),
                        isMain: CGDisplayIsMain(id) != 0, isBuiltin: CGDisplayIsBuiltin(id) != 0)
        }
    }

    nonisolated static func readConfiguredOutput(path: String) -> UInt32? {
        guard let text = try? String(contentsOfFile: path, encoding: .utf8) else { return nil }
        for line in text.split(separator: "\n") {
            let parts = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2, parts[0] == "output_name" { return UInt32(parts[1]) }
        }
        return nil
    }

    var suggestedDisplay: DisplayInfo? {
        if let v = displays.first(where: { $0.looksVirtual && !$0.isMain }) { return v }
        let others = displays.filter { !$0.isMain && !$0.isBuiltin }
        return others.count == 1 ? others.first : nil
    }

    func refresh() { Task { await refreshNow() } }

    func refreshNow() async {
        let plistPath = plist, conf = confPath
        let snap = await Task.detached { () -> (Bool, Bool, Bool, Bool, Bool, Bool, UInt32?, String) in
            let fm = FileManager.default
            let brew = fm.isExecutableFile(atPath: "/opt/homebrew/bin/brew") || fm.isExecutableFile(atPath: "/usr/local/bin/brew")
            let installed = AppModel.findSunshine() != nil
            let running = Shell.run("pgrep -x sunshine").status == 0
            let exists = fm.fileExists(atPath: plistPath)
            var auto = false
            if exists {
                auto = Shell.exec("/usr/libexec/PlistBuddy", ["-c", "Print :RunAtLoad", plistPath])
                    .out.trimmingCharacters(in: .whitespacesAndNewlines) == "true"
            }
            return (brew, installed, running, auto, exists, AppModel.detectCrisp(),
                    AppModel.readConfiguredOutput(path: conf), AppModel.localIP())
        }.value
        brewInstalled = snap.0; sunshineInstalled = snap.1; sunshineRunning = snap.2
        autostart = snap.3; plistExists = snap.4; crispInstalled = snap.5
        configuredOutput = snap.6; ip = snap.7
        displays = Self.readDisplays()
    }

    // MARK: Command runner
    func appendLog(_ s: String) {
        log += s
        if log.count > 20000 { log = String(log.suffix(15000)) }
    }

    @discardableResult
    func exec(_ title: String, _ cmd: String, env: [String: String] = [:]) async -> Int32 {
        busy = true; busyTitle = title
        appendLog("\n▶ \(title)\n")
        let status = await Task.detached { [weak self] () -> Int32 in
            Shell.run(cmd, extraEnv: env) { s in
                Task { @MainActor in self?.appendLog(s) }
            }.status
        }.value
        appendLog(status == 0 ? "✓ OK\n" : "✗ exit \(status)\n")
        busy = false; busyTitle = ""
        await refreshNow()
        return status
    }

    // MARK: Sunshine control
    private var svcSetup: String {
        "PL=\"\(plist)\"; U=$(id -u); "
    }

    func start() async {
        if !plistExists {
            await exec(t("Starting Sunshine", "Sunshine başlatılıyor"), "brew services start \(Self.formula)")
        } else {
            await exec(t("Starting Sunshine", "Sunshine başlatılıyor"),
                       svcSetup + "launchctl bootout gui/$U \"$PL\" 2>/dev/null; launchctl bootstrap gui/$U \"$PL\"; launchctl kickstart gui/$U/\(Self.label)")
        }
    }

    func restart() async {
        if !plistExists { await start(); return }
        await exec(t("Restarting Sunshine", "Sunshine yeniden başlatılıyor"),
                   svcSetup + "launchctl bootout gui/$U \"$PL\" 2>/dev/null; sleep 1; launchctl bootstrap gui/$U \"$PL\"; launchctl kickstart -k gui/$U/\(Self.label)")
    }

    func stop() async {
        await exec(t("Stopping Sunshine", "Sunshine durduruluyor"),
                   svcSetup + "launchctl bootout gui/$U \"$PL\" 2>/dev/null; pkill -x sunshine; true")
    }

    func setAutostart(_ on: Bool) async {
        if !plistExists && on {
            await exec(t("Creating service", "Servis oluşturuluyor"), "brew services start \(Self.formula)")
        }
        guard FileManager.default.fileExists(atPath: plist) else {
            message = t("Service file not found. Install Sunshine first.", "Servis dosyası bulunamadı. Önce Sunshine'ı kurun.")
            return
        }
        let v = on ? "true" : "false"
        await exec(on ? t("Enable start at login", "Girişte otomatik başlatmayı aç") : t("Disable start at login", "Girişte otomatik başlatmayı kapat"),
                   "/usr/libexec/PlistBuddy -c 'Set :RunAtLoad \(v)' \"\(plist)\" || /usr/libexec/PlistBuddy -c 'Add :RunAtLoad bool \(v)' \"\(plist)\"")
    }

    // MARK: Install
    func installSunshine() async {
        guard brewInstalled else { message = t("Homebrew is required first.", "Önce Homebrew gerekli."); return }
        await exec(t("Installing Sunshine", "Sunshine kuruluyor"), "brew tap \(Self.tap) && brew install \(Self.formula)")
    }

    /// Some casks need an admin password. Homebrew has no terminal here, so we hand it a GUI askpass helper.
    private func askpassPath() -> String {
        let dir = home + "/Library/Caches/TabScreen"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let path = dir + "/askpass.sh"
        let prompt = t("TabScreen needs your Mac password to install the app.", "TabScreen uygulamayı kurmak için Mac şifrenizi istiyor.")
        let script = "#!/bin/sh\nosascript -e 'text returned of (display dialog \"\(prompt)\" default answer \"\" with hidden answer with title \"TabScreen\" with icon caution)'\n"
        try? script.write(toFile: path, atomically: true, encoding: .utf8)
        try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: path)
        return path
    }

    func installCask(_ cask: String, title: String) async {
        guard brewInstalled else { message = t("Homebrew is required first.", "Önce Homebrew gerekli."); return }
        await exec(title, "brew install --cask \(cask)", env: ["SUDO_ASKPASS": askpassPath()])
    }

    func installCrisp() async { await installCask("crisp", title: t("Installing Crisp", "Crisp kuruluyor")) }

    func openTerminalWithBrewInstall() {
        let script = "tell application \"Terminal\" to do script \"\(Self.brewInstallCommand.replacingOccurrences(of: "\"", with: "\\\""))\"\ntell application \"Terminal\" to activate"
        Shell.exec("/usr/bin/osascript", ["-e", script])
    }

    // MARK: Configuration
    func writeOutput(_ id: UInt32) async {
        let dir = (confPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        var lines = ((try? String(contentsOfFile: confPath, encoding: .utf8)) ?? "")
            .split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        lines.removeAll { $0.trimmingCharacters(in: .whitespaces).hasPrefix("output_name") }
        lines.append("output_name = \(id)")
        do {
            try (lines.joined(separator: "\n") + "\n").write(toFile: confPath, atomically: true, encoding: .utf8)
            appendLog("\n✓ output_name = \(id)\n")
            message = t("Display \(id) selected.", "\(id) numaralı ekran seçildi.")
        } catch {
            message = "\(error.localizedDescription)"
            return
        }
        await refreshNow()
        if sunshineRunning { await restart() }
    }

    func setCredentials(user: String, password: String) async {
        guard let bin = Self.findSunshine(), !user.isEmpty, !password.isEmpty else { return }
        busy = true; busyTitle = t("Saving credentials", "Kimlik bilgileri kaydediliyor")
        let r = await Task.detached { Shell.exec(bin, ["--creds", user, password]) }.value
        appendLog("\n▶ sunshine --creds \(user) ***\n\(r.out)")
        busy = false; busyTitle = ""
        message = r.status == 0 ? t("Credentials saved.", "Kimlik bilgileri kaydedildi.") : t("Could not save credentials.", "Kimlik bilgileri kaydedilemedi.")
        if sunshineRunning { await restart() }
    }

    func autoSetup() async {
        message = nil
        guard brewInstalled else {
            message = t("Homebrew is not installed. See the Setup page for install options.",
                        "Homebrew kurulu değil. Kurulum seçenekleri için Kurulum sayfasına bakın.")
            return
        }
        if !sunshineInstalled { await installSunshine() }
        if !crispInstalled { await installCrisp() }
        await refreshNow()
        if let d = suggestedDisplay {
            await writeOutput(d.id)
        } else {
            message = t("Create a virtual display in Crisp (1920×1200), then press Auto setup again.",
                        "Crisp'te bir sanal ekran oluşturun (1920×1200), sonra Otomatik kurulum'a tekrar basın.")
        }
        if !sunshineRunning { await start() }
        if message == nil {
            message = t("Done. Grant the two permissions below, then pair your tablet.",
                        "Tamam. Aşağıdaki iki izni verin, sonra tabletinizi eşleştirin.")
        }
    }

    // MARK: Helpers
    func openURL(_ s: String) { if let u = URL(string: s) { NSWorkspace.shared.open(u) } }
    func openWebUI() { openURL("https://localhost:47990") }
    func openScreenRecordingSettings() { openURL("x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") }
    func openAccessibilitySettings() { openURL("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") }
    func openDisplaysSettings() { openURL("x-apple.systempreferences:com.apple.Displays-Settings.extension") }
    func openLogFile() { NSWorkspace.shared.open(URL(fileURLWithPath: sunshineLogPath)) }
    func copy(_ s: String) { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(s, forType: .string) }
}
