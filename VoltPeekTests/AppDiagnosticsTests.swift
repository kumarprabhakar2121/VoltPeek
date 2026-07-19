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
        // Flush async log() via a sync supportReport on the same queue after a brief wait.
        let deadline = Date().addingTimeInterval(1)
        var report = ""
        repeat {
            report = diagnostics.supportReport()
            if report.contains("Launch test harness") { break }
            Thread.sleep(forTimeInterval: 0.01)
        } while Date() < deadline

        XCTAssertTrue(report.contains("VoltPeek Diagnostics"))
        XCTAssertTrue(report.contains("=== App log ==="))
        XCTAssertTrue(report.contains("Launch test harness"), report)
    }

    func testLogAppendsToSupportReport() {
        diagnostics.log("unit-test-marker-42")
        let deadline = Date().addingTimeInterval(1)
        var report = ""
        repeat {
            report = diagnostics.supportReport()
            if report.contains("unit-test-marker-42") { break }
            Thread.sleep(forTimeInterval: 0.01)
        } while Date() < deadline
        XCTAssertTrue(report.contains("unit-test-marker-42"), report)
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
}
