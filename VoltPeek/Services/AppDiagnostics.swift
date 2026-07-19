import AppKit
import Foundation
import OSLog

/// Local-only diagnostics: append-only app log, last-crash marker, and macOS crash-report pickup.
/// Nothing is uploaded — users share via Copy / Email from the Diagnostics screen.
final class AppDiagnostics: @unchecked Sendable {
    static let shared = AppDiagnostics()
    static let supportEmail = "hello@voltpeek.app"

    private let logger = Logger(subsystem: "com.voltpeek.app", category: "diagnostics")
    private let queue = DispatchQueue(label: "com.voltpeek.diagnostics", qos: .utility)
    private let maxLogBytes = 200_000
    private let fileManager: FileManager
    private let rootDirectory: URL

    private var logFileURL: URL { rootDirectory.appendingPathComponent("app.log") }
    private var crashFileURL: URL { rootDirectory.appendingPathComponent("last-crash.txt") }
    private var didInstall = false

    init(
        fileManager: FileManager = .default,
        rootDirectory: URL? = nil
    ) {
        self.fileManager = fileManager
        if let rootDirectory {
            self.rootDirectory = rootDirectory
        } else {
            let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
            self.rootDirectory = base
                .appendingPathComponent("VoltPeek", isDirectory: true)
                .appendingPathComponent("Diagnostics", isDirectory: true)
        }
    }

    /// Creates directories, installs crash hooks, and writes a launch line.
    func install() {
        queue.sync {
            guard !didInstall else { return }
            didInstall = true
            ensureDirectory()
            openCrashFileDescriptor()
            installExceptionHandler()
            installSignalHandlers()
            appendLocked("Launch \(Self.appVersionLine()) | macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
        }
    }

    func log(_ message: String) {
        queue.async { [weak self] in
            self?.appendLocked(message)
        }
        logger.notice("\(message, privacy: .public)")
    }

    /// Full text for the Diagnostics screen / clipboard / email paste.
    func supportReport() -> String {
        queue.sync {
            ensureDirectory()
            var parts: [String] = []
            parts.append("VoltPeek Diagnostics")
            parts.append("Generated: \(Self.isoNow())")
            parts.append(Self.appVersionLine())
            parts.append("macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)")
            parts.append("Path: \(rootDirectory.path)")
            parts.append("")

            if let crash = readFile(crashFileURL), !crash.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                parts.append("=== Last crash (app-captured) ===")
                parts.append(crash.trimmingCharacters(in: .whitespacesAndNewlines))
                parts.append("")
            } else {
                parts.append("=== Last crash (app-captured) ===")
                parts.append("(none)")
                parts.append("")
            }

            if let system = latestSystemCrashSnippet() {
                parts.append("=== Latest macOS Diagnostic Report (VoltPeek) ===")
                parts.append(system)
                parts.append("")
            } else {
                parts.append("=== Latest macOS Diagnostic Report (VoltPeek) ===")
                parts.append("(none found in ~/Library/Logs/DiagnosticReports)")
                parts.append("")
            }

            parts.append("=== App log ===")
            if let log = readFile(logFileURL), !log.isEmpty {
                parts.append(log.trimmingCharacters(in: .whitespacesAndNewlines))
            } else {
                parts.append("(empty)")
            }
            return parts.joined(separator: "\n")
        }
    }

    var hasCapturedCrash: Bool {
        queue.sync {
            guard let text = readFile(crashFileURL) else { return false }
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var diagnosticsDirectoryURL: URL { rootDirectory }

    func clearLogs() {
        queue.sync {
            try? fileManager.removeItem(at: logFileURL)
            try? fileManager.removeItem(at: crashFileURL)
            ensureDirectory()
            openCrashFileDescriptor()
            appendLocked("Logs cleared")
        }
    }

    func copySupportReportToPasteboard() {
        let report = supportReport()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report, forType: .string)
    }

    /// Copies the report, then opens Mail with a short paste prompt (mailto bodies are size-limited).
    func emailSupportWithReport() {
        copySupportReportToPasteboard()
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Self.supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "VoltPeek diagnostics"),
            URLQueryItem(
                name: "body",
                value: """
                Please describe what happened, then paste the diagnostics report from your clipboard below.

                (VoltPeek → Settings → Diagnostics → Copy Report)

                ---
                """
            )
        ]
        if let url = components.url {
            NSWorkspace.shared.open(url)
        }
    }

    /// Records an exception/crash from a normal (non-signal) context.
    func recordCrash(_ reason: String) {
        let line = "\(Self.isoNow()) \(reason)\n"
        queue.sync {
            ensureDirectory()
            appendLocked("CRASH \(reason)")
            if let data = line.data(using: .utf8) {
                try? data.write(to: crashFileURL, options: .atomic)
            }
        }
    }

    // MARK: - Install hooks

    private func openCrashFileDescriptor() {
        if voltPeekCrashFileDescriptor >= 0 {
            close(voltPeekCrashFileDescriptor)
            voltPeekCrashFileDescriptor = -1
        }
        voltPeekCrashFileDescriptor = open(crashFileURL.path, O_WRONLY | O_CREAT | O_TRUNC, 0o644)
    }

    private func installExceptionHandler() {
        NSSetUncaughtExceptionHandler { exception in
            let reason = "NSException \(exception.name.rawValue): \(exception.reason ?? "nil")\n\(exception.callStackSymbols.prefix(40).joined(separator: "\n"))"
            AppDiagnostics.shared.recordCrash(reason)
        }
    }

    private func installSignalHandlers() {
        let signals: [Int32] = [SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS, SIGTRAP]
        for sig in signals {
            signal(sig, voltPeekSignalHandler)
        }
    }

    // MARK: - File helpers

    private func ensureDirectory() {
        try? fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
    }

    private func appendLocked(_ message: String) {
        ensureDirectory()
        let line = "\(Self.isoNow()) \(message)\n"
        guard let data = line.data(using: .utf8) else { return }

        if fileManager.fileExists(atPath: logFileURL.path) {
            if let handle = try? FileHandle(forWritingTo: logFileURL) {
                defer { try? handle.close() }
                try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
            }
        } else {
            try? data.write(to: logFileURL, options: .atomic)
        }
        trimLogIfNeeded()
    }

    private func trimLogIfNeeded() {
        guard
            let attrs = try? fileManager.attributesOfItem(atPath: logFileURL.path),
            let size = attrs[.size] as? NSNumber,
            size.intValue > maxLogBytes,
            let text = readFile(logFileURL),
            let keepFrom = text.index(text.endIndex, offsetBy: -maxLogBytes / 2, limitedBy: text.startIndex)
        else { return }

        let kept = String(text[keepFrom...])
        let trimmed = "…(earlier log trimmed)…\n" + kept
        try? trimmed.data(using: .utf8)?.write(to: logFileURL, options: .atomic)
    }

    private func readFile(_ url: URL) -> String? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    /// Snippet from the newest VoltPeek crash/ips under the user's DiagnosticReports folder.
    private func latestSystemCrashSnippet() -> String? {
        let dir = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/DiagnosticReports", isDirectory: true)
        guard
            let files = try? fileManager.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
        else { return nil }

        let matches = files.filter { url in
            let name = url.lastPathComponent
            return name.localizedCaseInsensitiveContains("VoltPeek")
                && (name.hasSuffix(".ips") || name.hasSuffix(".crash") || name.hasSuffix(".diag"))
        }
        guard let newest = matches.max(by: { lhs, rhs in
            let l = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let r = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return l < r
        }) else { return nil }

        guard let body = try? String(contentsOf: newest, encoding: .utf8) else {
            return "File: \(newest.lastPathComponent)\n(unable to read)"
        }
        let limit = 8_000
        let snippet = body.count > limit ? String(body.prefix(limit)) + "\n…(truncated)…" : body
        return "File: \(newest.lastPathComponent)\n\(snippet)"
    }

    private static func isoNow() -> String {
        ISO8601DateFormatter().string(from: Date())
    }

    private static func appVersionLine() -> String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "VoltPeek \(short) (\(build)) · \(Bundle.main.bundleIdentifier ?? "com.voltpeek.app")"
    }
}

// MARK: - Signal-safe crash FD (must not use locks / Swift heap from the handler)

/// Pre-opened FD for last-crash.txt; written only with `write(2)` from the signal handler.
private var voltPeekCrashFileDescriptor: Int32 = -1

/// Async-signal-safe handler: writes a short line, restores default, re-raises for macOS Diagnostic Reports.
private func voltPeekSignalHandler(_ signalNumber: Int32) {
    let fd = voltPeekCrashFileDescriptor
    if fd >= 0 {
        // Static bytes only — no heap allocation in the signal path.
        let message: StaticString = "VoltPeek crash (fatal signal; see macOS DiagnosticReports)\n"
        message.withUTF8Buffer { buffer in
            _ = write(fd, buffer.baseAddress, buffer.count)
        }
        fsync(fd)
    }

    Darwin.signal(signalNumber, SIG_DFL)
    Darwin.raise(signalNumber)
}
