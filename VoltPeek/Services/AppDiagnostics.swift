import AppKit
import Foundation
import OSLog

/// Local-only diagnostics: activity log, crash marker, and macOS crash-report pickup.
/// Nothing is uploaded — users explicitly choose how to share from the Diagnostics screen.
final class AppDiagnostics: @unchecked Sendable {
    static let shared = AppDiagnostics()
    static let supportEmail = "hello@voltpeek.app"
    static let issuesURL = URL(string: "https://github.com/kumarprabhakar2121/VoltPeek/issues/new")!

    private let logger = Logger(subsystem: "com.voltpeek.app", category: "diagnostics")
    private let queue = DispatchQueue(label: "com.voltpeek.diagnostics", qos: .utility)
    private let maxLogBytes = 200_000
    private let fileManager: FileManager
    private let rootDirectory: URL

    private var logFileURL: URL {
        rootDirectory.appendingPathComponent("app-\(Self.localDayStamp()).log")
    }
    private var crashFileURL: URL { rootDirectory.appendingPathComponent("last-crash.txt") }
    private var pendingSignalFileURL: URL { rootDirectory.appendingPathComponent("pending-signal-crash.txt") }
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
            removePastActivityLogs(keeping: logFileURL)
            promotePendingSignalCrash()
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

    /// Full text for the Diagnostics screen and clipboard.
    func supportReport() -> String {
        queue.sync {
            ensureDirectory()
            let currentLogFileURL = logFileURL
            removePastActivityLogs(keeping: currentLogFileURL)
            var parts: [String] = []
            parts.append("VoltPeek Diagnostics")
            parts.append("Generated: \(Self.isoNow())")
            parts.append(Self.appVersionLine())
            parts.append("macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)")
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

            parts.append("=== Activity log ===")
            if let log = readFile(currentLogFileURL), !log.isEmpty {
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
            removeAllActivityLogs()
            try? fileManager.removeItem(at: crashFileURL)
            try? fileManager.removeItem(at: pendingSignalFileURL)
            ensureDirectory()
            openCrashFileDescriptor()
            appendLocked("Logs cleared")
        }
    }

    func copySupportReportToPasteboard() {
        let report = supportReport()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report, forType: .string)
        log("Diagnostics report copied")
    }

    /// Copies the full report and opens a prefilled email with a bounded diagnostic excerpt.
    func emailSupportWithReport() {
        let report = supportReport()
        copyToPasteboard(report)
        guard let url = emailURL(report: report) else {
            log("Unable to create support email URL")
            return
        }
        log("Opening prefilled support email")
        NSWorkspace.shared.open(url)
    }

    /// Copies the full report and opens a prefilled GitHub issue in the default browser.
    func reportOnGitHub() {
        let report = supportReport()
        copyToPasteboard(report)
        guard let url = githubIssueURL(report: report) else {
            log("Unable to create GitHub issue URL")
            return
        }
        log("Opening prefilled GitHub issue")
        NSWorkspace.shared.open(url)
    }

    func emailURL(report: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Self.supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "VoltPeek crash report"),
            URLQueryItem(name: "body", value: Self.emailReportBody(report: report))
        ]
        return components.url
    }

    func githubIssueURL(report: String) -> URL? {
        guard var components = URLComponents(url: Self.issuesURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.queryItems = [
            URLQueryItem(name: "title", value: "[Crash] VoltPeek \(Self.shortVersion())"),
            URLQueryItem(name: "body", value: Self.reportBody(report: report))
        ]
        return components.url
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

    private func promotePendingSignalCrash() {
        guard
            let pending = readFile(pendingSignalFileURL)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            !pending.isEmpty
        else { return }

        let previous = readFile(crashFileURL)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let combined = [previous, pending].compactMap { value in
            guard let value, !value.isEmpty else { return nil }
            return value
        }.joined(separator: "\n\n")
        try? combined.data(using: .utf8)?.write(to: crashFileURL, options: .atomic)
        try? fileManager.removeItem(at: pendingSignalFileURL)
    }

    private func openCrashFileDescriptor() {
        if voltPeekCrashFileDescriptor >= 0 {
            close(voltPeekCrashFileDescriptor)
            voltPeekCrashFileDescriptor = -1
        }
        voltPeekCrashFileDescriptor = open(
            pendingSignalFileURL.path,
            O_WRONLY | O_CREAT | O_TRUNC,
            0o644
        )
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
        let currentLogFileURL = logFileURL
        removePastActivityLogs(keeping: currentLogFileURL)
        let line = "\(Self.isoNow()) \(message)\n"
        guard let data = line.data(using: .utf8) else { return }

        if fileManager.fileExists(atPath: currentLogFileURL.path) {
            if let handle = try? FileHandle(forWritingTo: currentLogFileURL) {
                defer { try? handle.close() }
                try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
            }
        } else {
            try? data.write(to: currentLogFileURL, options: .atomic)
        }
        trimLogIfNeeded(currentLogFileURL)
    }

    private func trimLogIfNeeded(_ fileURL: URL) {
        guard
            let attrs = try? fileManager.attributesOfItem(atPath: fileURL.path),
            let size = attrs[.size] as? NSNumber,
            size.intValue > maxLogBytes,
            let text = readFile(fileURL),
            let keepFrom = text.index(text.endIndex, offsetBy: -maxLogBytes / 2, limitedBy: text.startIndex)
        else { return }

        let kept = String(text[keepFrom...])
        let trimmed = "…(earlier log trimmed)…\n" + kept
        try? trimmed.data(using: .utf8)?.write(to: fileURL, options: .atomic)
    }

    private func removePastActivityLogs(keeping currentLogFileURL: URL) {
        activityLogFileURLs()
            .filter { $0.standardizedFileURL != currentLogFileURL.standardizedFileURL }
            .forEach { try? fileManager.removeItem(at: $0) }
    }

    private func removeAllActivityLogs() {
        activityLogFileURLs().forEach { try? fileManager.removeItem(at: $0) }
    }

    private func activityLogFileURLs() -> [URL] {
        guard let files = try? fileManager.contentsOfDirectory(
            at: rootDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        return files.filter { url in
            let name = url.lastPathComponent
            return name == "app.log"
                || (name.hasPrefix("app-") && name.hasSuffix(".log"))
        }
    }

    private func readFile(_ url: URL) -> String? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    private func copyToPasteboard(_ report: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report, forType: .string)
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

    private static func localDayStamp() -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    private static func shortVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown version"
    }

    private static func appVersionLine() -> String {
        let short = shortVersion()
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "VoltPeek \(short) (\(build)) · \(Bundle.main.bundleIdentifier ?? "com.voltpeek.app")"
    }

    private static func reportBody(report: String) -> String {
        let excerpt = reportExcerpt(report)

        return """
        What happened?
        <!-- Please describe what you were doing immediately before the problem. -->

        Steps to reproduce:
        1.
        2.
        3.

        Expected behavior:

        Additional context:

        <details>
        <summary>VoltPeek diagnostics and stack trace</summary>

        ```
        \(excerpt)
        ```
        </details>

        The complete diagnostics report was also copied to the clipboard.
        Please review it before submitting because system crash reports may contain device metadata.
        """
    }

    private static func emailReportBody(report: String) -> String {
        """
        What happened?

        Steps to reproduce:
        1.
        2.
        3.

        Expected behavior:

        Additional context:

        --- VoltPeek diagnostics and stack trace ---
        \(reportExcerpt(report))

        ---
        The complete diagnostics report was also copied to the clipboard.
        Please review it before sending because system crash reports may contain device metadata.
        """
    }

    private static func reportExcerpt(_ report: String) -> String {
        let limit = 6_000
        if report.count > limit {
            return String(report.prefix(limit))
                + "\n…(report truncated for URL size; the complete report is on the clipboard)…"
        }
        return report
    }
}

// MARK: - Signal-safe crash FD (must not use locks / Swift heap from the handler)

/// Pre-opened FD for a pending signal marker; written only with `write(2)` from the signal handler.
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
