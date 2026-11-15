import Foundation

/// Small helper around Process. Everything runs through /bin/zsh with a Homebrew-aware PATH.
enum Shell {
    static var baseEnv: [String: String] {
        var e = ProcessInfo.processInfo.environment
        e["PATH"] = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        e["HOMEBREW_NO_AUTO_UPDATE"] = "1"
        e["HOMEBREW_NO_ENV_HINTS"] = "1"
        e["NONINTERACTIVE"] = "1"
        return e
    }

    @discardableResult
    static func run(_ command: String,
                    extraEnv: [String: String] = [:],
                    onOutput: ((String) -> Void)? = nil) -> (status: Int32, out: String) {
        execute(exe: "/bin/zsh", args: ["-c", command], extraEnv: extraEnv, onOutput: onOutput)
    }

    /// Runs an executable directly (no shell), so arguments with special characters stay safe.
    @discardableResult
    static func exec(_ path: String, _ args: [String]) -> (status: Int32, out: String) {
        execute(exe: path, args: args, extraEnv: [:], onOutput: nil)
    }

    private static func execute(exe: String, args: [String], extraEnv: [String: String],
                                onOutput: ((String) -> Void)?) -> (status: Int32, out: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: exe)
        p.arguments = args
        var env = baseEnv
        env.merge(extraEnv) { $1 }
        p.environment = env
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        p.standardInput = FileHandle.nullDevice

        let lock = NSLock()
        var collected = Data()
        pipe.fileHandleForReading.readabilityHandler = { h in
            let d = h.availableData
            if d.isEmpty { return }
            lock.lock(); collected.append(d); lock.unlock()
            if let s = String(data: d, encoding: .utf8) { onOutput?(s) }
        }
        do { try p.run() } catch { return (127, "\(error)") }
        p.waitUntilExit()
        pipe.fileHandleForReading.readabilityHandler = nil
        let rest = pipe.fileHandleForReading.readDataToEndOfFile()
        if !rest.isEmpty {
            lock.lock(); collected.append(rest); lock.unlock()
            if let s = String(data: rest, encoding: .utf8) { onOutput?(s) }
        }
        lock.lock(); defer { lock.unlock() }
        return (p.terminationStatus, String(data: collected, encoding: .utf8) ?? "")
    }
}
