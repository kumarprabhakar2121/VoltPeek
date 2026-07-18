import Foundation
import IOKit
import IOKit.ps

/// Reads battery and charger data from IOPowerSources and the AppleSmartBattery IOKit service.
/// Mapping helpers are pure and unit-testable via dictionary fixtures.
struct PowerSourceReader: Sendable {

    /// Combined read of system battery + charger state.
    func read() -> (battery: BatteryInfo, charger: ChargerInfo) {
        let powerSource = readPowerSourceDescription()
        let smartBattery = readSmartBatteryProperties()
        let battery = Self.mapBattery(powerSource: powerSource, smartBattery: smartBattery)
        let charger = Self.mapCharger(
            powerSource: powerSource,
            smartBattery: smartBattery,
            batteryWatts: battery.watts
        )
        return (battery, charger)
    }

    // MARK: - System reads

    private func readPowerSourceDescription() -> [String: Any] {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
            return [:]
        }
        guard let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] else {
            return [:]
        }
        for source in list {
            if let raw = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() {
                let desc = dictionary(from: raw)
                let type = desc[kIOPSTypeKey] as? String
                if type == kIOPSInternalBatteryType || Self.boolValue(desc[kIOPSIsPresentKey]) == true {
                    return desc
                }
            }
        }
        if let first = list.first,
           let raw = IOPSGetPowerSourceDescription(blob, first)?.takeUnretainedValue() {
            return dictionary(from: raw)
        }
        return [:]
    }

    private func readSmartBatteryProperties() -> [String: Any] {
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("AppleSmartBattery")
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        guard result == KERN_SUCCESS else { return [:] }
        defer { IOObjectRelease(iterator) }

        let service = IOIteratorNext(iterator)
        guard service != 0 else { return [:] }
        defer { IOObjectRelease(service) }

        var properties: Unmanaged<CFMutableDictionary>?
        let kr = IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0)
        guard kr == KERN_SUCCESS, let cfDict = properties?.takeRetainedValue() else {
            return [:]
        }
        return dictionary(from: cfDict)
    }

    // MARK: - Mapping (testable)

    /// Maps IOPowerSources + AppleSmartBattery dictionaries into `BatteryInfo`.
    static func mapBattery(
        powerSource: [String: Any],
        smartBattery: [String: Any]
    ) -> BatteryInfo {
        let percentage: Int = {
            if let iops = intValue(powerSource[kIOPSCurrentCapacityKey]) {
                return iops
            }
            if let cur = intValue(smartBattery["CurrentCapacity"]),
               let max = intValue(smartBattery["MaxCapacity"]),
               max == 100 {
                return cur
            }
            if let cur = intValue(smartBattery["AppleRawCurrentCapacity"]),
               let max = intValue(smartBattery["AppleRawMaxCapacity"]),
               max > 0 {
                return Int((Double(cur) / Double(max) * 100.0).rounded())
            }
            return 0
        }()

        let isCharging = boolValue(powerSource[kIOPSIsChargingKey])
            ?? boolValue(smartBattery["IsCharging"])
            ?? false

        let powerSourceState = powerSource[kIOPSPowerSourceStateKey] as? String
        let isOnACPower = powerSourceState == kIOPSACPowerValue
            || boolValue(smartBattery["ExternalConnected"]) == true

        let currentCapacity = intValue(smartBattery["AppleRawCurrentCapacity"])
            ?? intValue(smartBattery["CurrentCapacity"]).flatMap { $0 > 100 ? $0 : nil }

        let maxCapacity = intValue(smartBattery["AppleRawMaxCapacity"])
            ?? intValue(smartBattery["MaxCapacity"]).flatMap { $0 > 100 ? $0 : nil }

        let designCapacity = intValue(smartBattery["DesignCapacity"])
        let cycleCount = intValue(smartBattery["CycleCount"])

        let voltageMillivolts = doubleValue(smartBattery["Voltage"])
            ?? doubleValue(powerSource[kIOPSVoltageKey])
        let voltage: Double? = voltageMillivolts.map { $0 / 1000.0 }

        let currentAmps = resolveSignedCurrentAmps(
            smartBattery: smartBattery,
            powerSource: powerSource,
            isCharging: isCharging
        )

        let watts: Double? = {
            guard let v = voltage, let a = currentAmps else { return nil }
            let w = v * a
            return abs(w) > 0.05 ? w : nil
        }()

        let health: Double? = {
            guard let max = maxCapacity, let design = designCapacity, design > 0 else { return nil }
            return (Double(max) / Double(design)) * 100.0
        }()

        let timeRemaining = formatTimeRemaining(
            powerSource: powerSource,
            isCharging: isCharging
        )

        let temperatureCelsius = resolveTemperatureCelsius(smartBattery: smartBattery)

        return BatteryInfo(
            percentage: percentage,
            isCharging: isCharging,
            isOnACPower: isOnACPower,
            currentCapacity: currentCapacity,
            maxCapacity: maxCapacity,
            designCapacity: designCapacity,
            cycleCount: cycleCount,
            voltage: voltage,
            current: currentAmps,
            watts: watts,
            health: health,
            timeRemaining: timeRemaining,
            temperatureCelsius: temperatureCelsius
        )
    }

    /// Maps adapter-related fields into `ChargerInfo`.
    static func mapCharger(
        powerSource: [String: Any],
        smartBattery: [String: Any],
        batteryWatts: Double? = nil
    ) -> ChargerInfo {
        let connected = boolValue(smartBattery["ExternalConnected"])
            ?? (powerSource[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue)

        var adapterName: String?
        var adapterWatts: Double?

        let detailSources: [[String: Any]] = [
            dictionary(from: smartBattery["AdapterDetails"]),
            dictionary(from: smartBattery["AppleRawAdapterDetails"])
        ].filter { !$0.isEmpty }

        for details in detailSources {
            if adapterName == nil {
                adapterName = stringValue(details["Name"])
                    ?? stringValue(details["Description"])
                    ?? stringValue(details["Manufacturer"])
            }
            if adapterWatts == nil {
                adapterWatts = doubleValue(details["Watts"])
                    ?? doubleValue(details["AdapterPower"])
                    ?? doubleValue(details["Wattage"])
            }
        }

        if adapterWatts == nil {
            adapterWatts = doubleValue(smartBattery["AdapterPower"])
                ?? doubleValue(smartBattery["Watts"])
        }

        // Best-effort: when plugged in and charging, estimate from battery draw magnitude.
        if adapterWatts == nil, connected, let w = batteryWatts, w > 0.5 {
            adapterWatts = w.rounded()
        }

        return ChargerInfo(
            connected: connected,
            adapterName: adapterName,
            adapterWatts: adapterWatts
        )
    }

    /// Formats time-to-empty or time-to-full from IOPowerSources minutes.
    static func formatTimeRemaining(
        powerSource: [String: Any],
        isCharging: Bool
    ) -> String? {
        let minutesKey = isCharging ? kIOPSTimeToFullChargeKey : kIOPSTimeToEmptyKey
        guard let minutes = intValue(powerSource[minutesKey]), minutes > 0, minutes < 6000 else {
            return nil
        }
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return String(format: "%d h %d min", hours, mins)
        }
        return String(format: "%d min", mins)
    }

    /// Tries multiple temperature encodings and keys; returns first sane Celsius value.
    static func resolveTemperatureCelsius(smartBattery: [String: Any]) -> Double? {
        let candidates: [Any?] = [
            smartBattery["Temperature"],
            smartBattery["VirtualTemperature"],
            smartBattery["AppleRawTemperature"]
        ]
        for candidate in candidates {
            if let c = celsiusFromSmartBatteryTemperature(candidate) {
                return c
            }
        }
        return nil
    }

    /// Converts AppleSmartBattery temperature raw values using several known scales.
    static func celsiusFromSmartBatteryTemperature(_ value: Any?) -> Double? {
        guard let raw = doubleValue(value), raw != 0 else { return nil }

        func sane(_ celsius: Double) -> Double? {
            (celsius > -20 && celsius < 100) ? celsius : nil
        }

        // Typical AppleSmartBattery Temperature is centi-Kelvin (~27315…32000).
        if raw > 20000, let c = sane((raw / 100.0) - 273.15) {
            return c
        }
        // Already Celsius.
        if abs(raw) <= 100, let c = sane(raw) {
            return c
        }
        // Centi-Celsius (e.g. 3650 → 36.5°C).
        if raw > 100, raw < 10000, let c = sane(raw / 100.0) {
            return c
        }
        // Deci-Kelvin fallback.
        if let c = sane((raw / 10.0) - 273.15) {
            return c
        }
        return nil
    }

    /// Interprets InstantAmperage / Amperage as signed milliamps.
    static func signedMilliamps(_ value: Any?) -> Double? {
        guard let raw = doubleValue(value) else { return nil }
        var milli = Int(raw.rounded())
        // Some firmware reports negative currents as unsigned 16-bit two's complement.
        if milli > 32767 && milli < 65536 {
            milli -= 65536
        }
        return Double(milli)
    }

    /// Resolves signed amps, with fallback if InstantAmperage decode looks implausible.
    static func resolveSignedCurrentAmps(
        smartBattery: [String: Any],
        powerSource: [String: Any],
        isCharging: Bool
    ) -> Double? {
        let instant = signedMilliamps(smartBattery["InstantAmperage"])
        let amperage = signedMilliamps(smartBattery["Amperage"] ?? powerSource["Amperage"])

        let primary = instant ?? amperage
        if let primary {
            let amps = primary / 1000.0
            // Implausible laptop pack current (> 30A) → try alternate / charging-signed fallback.
            if abs(amps) <= 30 {
                return amps
            }
        }

        if let amperage {
            let magnitude = abs(amperage) / 1000.0
            guard magnitude <= 30, magnitude > 0.00005 else { return nil }
            return isCharging ? magnitude : -magnitude
        }

        return primary.map { $0 / 1000.0 }
    }

    // MARK: - Dictionary bridging

    /// Converts CFDictionary / NSDictionary / [String: Any] into a Swift dictionary.
    static func dictionary(from value: Any?) -> [String: Any] {
        if let dict = value as? [String: Any] {
            return flattenDictionary(dict)
        }
        if let dict = value as? NSDictionary {
            var result: [String: Any] = [:]
            for (key, obj) in dict {
                let keyString: String
                if let s = key as? String {
                    keyString = s
                } else if let s = key as? NSString {
                    keyString = s as String
                } else {
                    continue
                }
                result[keyString] = normalizeCFValue(obj)
            }
            return result
        }
        return [:]
    }

    private static func flattenDictionary(_ dict: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in dict {
            result[key] = normalizeCFValue(value)
        }
        return result
    }

    private static func normalizeCFValue(_ value: Any) -> Any {
        if value is NSDictionary || value is [String: Any] {
            let nested = dictionary(from: value)
            if !nested.isEmpty { return nested }
        }
        if let n = value as? NSNumber {
            return n
        }
        if let s = value as? String {
            return s
        }
        if let s = value as? NSString {
            return s as String
        }
        return value
    }

    // MARK: - Value helpers

    static func stringValue(_ value: Any?) -> String? {
        switch value {
        case let v as String: return v.isEmpty ? nil : v
        case let v as NSString: return (v as String).isEmpty ? nil : (v as String)
        default: return nil
        }
    }

    static func intValue(_ value: Any?) -> Int? {
        switch value {
        case let v as Int: return v
        case let v as Int32: return Int(v)
        case let v as Int64: return Int(v)
        case let v as UInt: return Int(v)
        case let v as UInt32: return Int(v)
        case let v as UInt64: return Int(v)
        case let v as NSNumber: return v.intValue
        default: return nil
        }
    }

    static func doubleValue(_ value: Any?) -> Double? {
        switch value {
        case let v as Double: return v
        case let v as Float: return Double(v)
        case let v as Int: return Double(v)
        case let v as Int32: return Double(v)
        case let v as Int64: return Double(v)
        case let v as UInt: return Double(v)
        case let v as UInt32: return Double(v)
        case let v as UInt64: return Double(v)
        case let v as NSNumber: return v.doubleValue
        default: return nil
        }
    }

    static func boolValue(_ value: Any?) -> Bool? {
        switch value {
        case let v as Bool: return v
        case let v as NSNumber: return v.boolValue
        default: return nil
        }
    }
}

// Instance helpers for system reads
private extension PowerSourceReader {
    func dictionary(from value: Any?) -> [String: Any] {
        Self.dictionary(from: value)
    }
}
