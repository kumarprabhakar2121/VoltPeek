import XCTest
@testable import VoltPeek

final class AppDiagnosticsTests: XCTestCase {
    private var tempRoot: URL!
    private var diagnostics: AppDiagnostics!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("VoltPeekDiagnosticsTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        // Storage-only instance — do not install process-wide crash handlers in unit tests.
        diagnostics = AppDiagnostics(rootDirectory: tempRoot)
        diagnostics.log("Launch test harness")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
        tempRoot = nil
        diagnostics = nil
    }

    func testSupportReportIncludesHeaderAndLog() {
        // log() enqueues before returning; supportReport() drains the same serial queue.
        let report = diagnostics.supportReport()
        XCTAssertTrue(report.contains("VoltPeek Diagnostics"))
        XCTAssertTrue(report.contains("=== Activity log ==="))
        XCTAssertTrue(report.contains("Launch test harness"), report)
        XCTAssertFalse(report.contains(tempRoot.path), report)
    }

    func testLogAppendsToSupportReport() {
        diagnostics.log("unit-test-marker-42")
        let report = diagnostics.supportReport()
        XCTAssertTrue(report.contains("unit-test-marker-42"), report)
    }

    func testLoggingKeepsOnlyCurrentDailyActivityLog() throws {
        _ = diagnostics.supportReport()
        let legacyLog = tempRoot.appendingPathComponent("app.log")
        let previousDailyLog = tempRoot.appendingPathComponent("app-2000-01-01.log")
        try Data("legacy".utf8).write(to: legacyLog)
        try Data("old".utf8).write(to: previousDailyLog)

        diagnostics.log("current-day-marker")
        let report = diagnostics.supportReport()

        XCTAssertFalse(FileManager.default.fileExists(atPath: legacyLog.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: previousDailyLog.path))
        let activityLogs = try FileManager.default.contentsOfDirectory(
            at: tempRoot,
            includingPropertiesForKeys: nil
        ).filter {
            $0.lastPathComponent.hasPrefix("app-") && $0.pathExtension == "log"
        }
        XCTAssertEqual(activityLogs.count, 1)
        XCTAssertTrue(report.contains("current-day-marker"), report)
    }

    func testRecordCrashSurfacesInReport() {
        diagnostics.recordCrash("test-crash-reason")
        XCTAssertTrue(diagnostics.hasCapturedCrash)
        let report = diagnostics.supportReport()
        XCTAssertTrue(report.contains("test-crash-reason"))
        XCTAssertTrue(report.contains("=== Last crash (app-captured) ==="))
    }

    func testClearLogsRemovesCrashMarker() {
        diagnostics.recordCrash("temporary")
        diagnostics.clearLogs()
        XCTAssertFalse(diagnostics.hasCapturedCrash)
        let report = diagnostics.supportReport()
        XCTAssertTrue(report.contains("(none)") || report.contains("Logs cleared"))
    }

    func testInstallPromotesSignalCrashFromPreviousLaunch() throws {
        let markerURL = tempRoot.appendingPathComponent("pending-signal-crash.txt")
        try Data("fatal signal marker".utf8).write(to: markerURL)

        diagnostics.install()

        XCTAssertTrue(diagnostics.hasCapturedCrash)
        XCTAssertTrue(diagnostics.supportReport().contains("fatal signal marker"))
        XCTAssertEqual(try String(contentsOf: markerURL, encoding: .utf8), "")
    }

    func testGitHubIssueIsPrefilledWithDiagnostics() throws {
        let url = try XCTUnwrap(diagnostics.githubIssueURL(report: "stack-frame-42"))
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let values = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )

        XCTAssertEqual(url.host, "github.com")
        XCTAssertTrue(values["title"]?.contains("[Crash] VoltPeek") == true)
        XCTAssertTrue(values["body"]?.contains("What happened?") == true)
        XCTAssertTrue(values["body"]?.contains("stack-frame-42") == true)
    }

    func testEmailIsPrefilledWithDiagnostics() throws {
        let url = try XCTUnwrap(diagnostics.emailURL(report: "activity-marker-7"))
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let body = components.queryItems?.first(where: { $0.name == "body" })?.value

        XCTAssertEqual(url.scheme, "mailto")
        XCTAssertTrue(body?.contains("activity-marker-7") == true)
        XCTAssertTrue(body?.contains("Steps to reproduce") == true)
    }

    func testShareURLsBoundOversizedDiagnosticReports() throws {
        let report = String(repeating: "A", count: 6_500) + "UNBOUNDED-TAIL"
        let githubURL = try XCTUnwrap(diagnostics.githubIssueURL(report: report))
        let emailURL = try XCTUnwrap(diagnostics.emailURL(report: report))
        let githubBody = try XCTUnwrap(
            URLComponents(url: githubURL, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "body" })?
                .value
        )
        let emailBody = try XCTUnwrap(
            URLComponents(url: emailURL, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "body" })?
                .value
        )

        for body in [githubBody, emailBody] {
            XCTAssertTrue(body.contains("report truncated for URL size"))
            XCTAssertFalse(body.contains("UNBOUNDED-TAIL"))
        }
    }
}
