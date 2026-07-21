import XCTest
@testable import VoltPeek

@MainActor
final class BatteryLogStoreTests: XCTestCase {
    private var tempRoot: URL!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("VoltPeekBatteryLogTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
        tempRoot = nil
    }

    func testDefaultRetentionLimitIsOneHundredEntries() {
        XCTAssertEqual(BatteryLogStore.defaultMaximumEntryCount, 100)
    }

    func testChargingSessionTracksPercentageAndClosesOnACIdle() {
        let store = makeStore()
        let start = Date(timeIntervalSince1970: 1_000)

        store.record(battery(percentage: 10, charging: true, onAC: true), at: start)
        store.record(battery(percentage: 100, charging: true, onAC: true), at: start.addingTimeInterval(3_900))
        store.record(battery(percentage: 100, charging: false, onAC: true), at: start.addingTimeInterval(3_900))

        XCTAssertNil(store.currentEntry)
        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(store.entries[0].kind, .charging)
        XCTAssertEqual(store.entries[0].startPercentage, 10)
        XCTAssertEqual(store.entries[0].endPercentage, 100)
        XCTAssertEqual(store.entries[0].duration(), 3_900, accuracy: 0.01)
        XCTAssertEqual(store.entries[0].completionReason, .stateChanged)
    }

    func testDischargingSessionStartsOnlyWhileOffAC() {
        let store = makeStore()
        let start = Date(timeIntervalSince1970: 2_000)

        store.record(battery(percentage: 80, charging: false, onAC: true), at: start)
        XCTAssertNil(store.currentEntry)

        store.record(battery(percentage: 66, charging: false, onAC: false), at: start.addingTimeInterval(10))
        store.record(battery(percentage: 2, charging: false, onAC: false), at: start.addingTimeInterval(45_130))

        XCTAssertEqual(store.currentEntry?.kind, .discharging)
        XCTAssertEqual(store.currentEntry?.startPercentage, 66)
        XCTAssertEqual(store.currentEntry?.endPercentage, 2)
    }

    func testSleepClosesEntryAndWakeStartsANewOne() {
        let store = makeStore()
        let start = Date(timeIntervalSince1970: 3_000)
        store.record(battery(percentage: 70, charging: false, onAC: false), at: start)

        store.handleSleep(at: start.addingTimeInterval(600))
        store.record(
            battery(percentage: 65, charging: false, onAC: false),
            at: start.addingTimeInterval(3_600)
        )
        XCTAssertNil(store.currentEntry)

        store.handleWake()
        store.record(
            battery(percentage: 65, charging: false, onAC: false),
            at: start.addingTimeInterval(3_610)
        )

        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(store.entries[0].completionReason, .sleep)
        XCTAssertEqual(store.entries[0].duration(), 600, accuracy: 0.01)
        XCTAssertEqual(store.currentEntry?.startDate, start.addingTimeInterval(3_610))
    }

    func testRelaunchRecoversCurrentEntryAtLastPersistedObservation() {
        let start = Date(timeIntervalSince1970: 4_000)
        var store: BatteryLogStore? = makeStore()
        store?.record(battery(percentage: 50, charging: false, onAC: false), at: start)
        store?.record(
            battery(percentage: 40, charging: false, onAC: false),
            at: start.addingTimeInterval(900)
        )
        store = nil

        let reloaded = makeStore()

        XCTAssertNil(reloaded.currentEntry)
        XCTAssertEqual(reloaded.entries.count, 1)
        XCTAssertEqual(reloaded.entries[0].completionReason, .interrupted)
        XCTAssertEqual(reloaded.entries[0].endDate, start.addingTimeInterval(900))
        XCTAssertEqual(reloaded.entries[0].endPercentage, 40)
    }

    func testCompletedEntriesRoundTripAndRetentionIsBounded() {
        let store = makeStore(maximumEntryCount: 2)
        let start = Date(timeIntervalSince1970: 5_000)

        for offset in 0..<4 {
            let date = start.addingTimeInterval(Double(offset * 100))
            store.record(battery(percentage: 20 + offset, charging: true, onAC: true), at: date)
            store.record(battery(percentage: 21 + offset, charging: false, onAC: true), at: date.addingTimeInterval(50))
        }

        XCTAssertEqual(store.entries.count, 2)
        let reloaded = makeStore(maximumEntryCount: 2)
        XCTAssertEqual(reloaded.entries, store.entries)
    }

    func testCurrentSessionCountsTowardRetentionLimit() {
        let store = makeStore(maximumEntryCount: 2)
        let start = Date(timeIntervalSince1970: 5_500)

        for offset in 0..<2 {
            let date = start.addingTimeInterval(Double(offset * 100))
            store.record(
                battery(percentage: 30 + offset, charging: true, onAC: true),
                at: date
            )
            store.record(
                battery(percentage: 31 + offset, charging: false, onAC: true),
                at: date.addingTimeInterval(60)
            )
        }

        store.record(
            battery(percentage: 80, charging: false, onAC: false),
            at: start.addingTimeInterval(250)
        )

        XCTAssertEqual(store.entries.count, 1)
        XCTAssertNotNil(store.currentEntry)
        XCTAssertEqual(store.allEntriesNewestFirst.count, 2)
        XCTAssertEqual(store.entries[0].startPercentage, 31)
    }

    func testCorruptFileRecoversWithEmptyHistory() throws {
        let historyURL = tempRoot.appendingPathComponent("battery-history.json")
        try Data("not-json".utf8).write(to: historyURL)

        let store = makeStore()
        XCTAssertTrue(store.entries.isEmpty)
        XCTAssertNil(store.currentEntry)

        store.record(
            battery(percentage: 30, charging: true, onAC: true),
            at: Date(timeIntervalSince1970: 6_000)
        )
        XCTAssertNotNil(store.currentEntry)
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: Data(contentsOf: historyURL)))
    }

    func testLiveEntryDurationUsesReferenceDate() {
        let start = Date(timeIntervalSince1970: 7_000)
        let entry = BatteryLogEntry(
            kind: .discharging,
            startDate: start,
            startPercentage: 80,
            endPercentage: 70,
            lastObservedDate: start.addingTimeInterval(300)
        )

        XCTAssertTrue(entry.isInProgress)
        XCTAssertEqual(entry.duration(at: start.addingTimeInterval(750)), 750, accuracy: 0.01)
    }

    func testShortUnchangedSessionIsDiscarded() {
        let store = makeStore()
        let start = Date(timeIntervalSince1970: 8_000)
        store.record(battery(percentage: 97, charging: true, onAC: true), at: start)

        store.handleAppTermination(at: start.addingTimeInterval(20))

        XCTAssertTrue(store.entries.isEmpty)
        XCTAssertNil(store.currentEntry)
    }

    func testLongUnchangedSessionIsRetained() {
        let store = makeStore()
        let start = Date(timeIntervalSince1970: 9_000)
        store.record(battery(percentage: 97, charging: true, onAC: true), at: start)

        store.handleAppTermination(at: start.addingTimeInterval(120))

        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(store.entries[0].duration(), 120, accuracy: 0.01)
    }

    private func makeStore(
        maximumEntryCount: Int = BatteryLogStore.defaultMaximumEntryCount
    ) -> BatteryLogStore {
        BatteryLogStore(
            rootDirectory: tempRoot,
            maximumEntryCount: maximumEntryCount,
            persistenceInterval: 0
        )
    }

    private func battery(percentage: Int, charging: Bool, onAC: Bool) -> BatteryInfo {
        var value = BatteryInfo.unavailable
        value.percentage = percentage
        value.isCharging = charging
        value.isOnACPower = onAC
        value.manufacturer = "Test Battery"
        return value
    }
}
