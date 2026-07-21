import AppKit
import CoreGraphics
import QuartzCore
import SwiftUI

struct PowerAlertScreenDescriptor: Equatable {
    let id: CGDirectDisplayID
    let visibleFrame: CGRect
    let isKey: Bool
    let containsPointer: Bool
    let isBuiltIn: Bool
    let isMain: Bool
}

enum PowerAlertScreenSelection {
    static func select(
        from screens: [PowerAlertScreenDescriptor]
    ) -> PowerAlertScreenDescriptor? {
        screens.first(where: \.isKey)
            ?? screens.first(where: \.containsPointer)
            ?? screens.first(where: \.isBuiltIn)
            ?? screens.first(where: \.isMain)
            ?? screens.first
    }
}

enum PowerAlertLayout {
    static func frame(
        in visibleFrame: CGRect,
        preferredSize: CGSize = CGSize(width: 290, height: 62),
        topMargin: CGFloat = 8
    ) -> CGRect {
        let horizontalMargin: CGFloat = 12
        let width = min(preferredSize.width, max(1, visibleFrame.width - (horizontalMargin * 2)))
        let height = min(preferredSize.height, max(1, visibleFrame.height - (topMargin * 2)))
        let x = min(
            max(visibleFrame.midX - (width / 2), visibleFrame.minX + horizontalMargin),
            visibleFrame.maxX - horizontalMargin - width
        )
        let y = max(visibleFrame.minY, visibleFrame.maxY - topMargin - height)
        return CGRect(x: x, y: y, width: width, height: height).integral
    }
}

struct PowerAlertPresentationGeneration {
    private(set) var value = 0

    mutating func next() -> Int {
        value &+= 1
        return value
    }

    func isCurrent(_ candidate: Int) -> Bool {
        candidate == value
    }
}

@MainActor
final class PowerAlertCoordinator {
    static let shared = PowerAlertCoordinator()

    private let panel: NSPanel
    private var dismissalTask: Task<Void, Never>?
    private var presentationGeneration = PowerAlertPresentationGeneration()
    private var activeSound: NSSound?
    private var wakeObserver: NSObjectProtocol?
    var onSystemWake: (() -> Void)?

    private init() {
        panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .transient,
            .ignoresCycle
        ]
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                PowerAlertCoordinator.shared.onSystemWake?()
            }
        }
    }

    func present(_ event: PowerAlertEvent, settings: SettingsManager) {
        guard settings.powerStatusPillEnabled else { return }
        guard let screen = targetScreen() else { return }

        let currentGeneration = presentationGeneration.next()
        dismissalTask?.cancel()

        let frame = PowerAlertLayout.frame(in: screen.visibleFrame)
        let view = PowerAlertPillView(
            event: event,
            accessibility: settings.accessibility
        )
        panel.contentView = NSHostingView(rootView: view)

        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        if panel.isVisible || reduceMotion {
            panel.setFrame(frame, display: true)
            panel.alphaValue = 1
            panel.orderFrontRegardless()
        } else {
            var initialFrame = frame
            initialFrame.origin.y -= 6
            panel.setFrame(initialFrame, display: true)
            panel.alphaValue = 0
            panel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.20
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().alphaValue = 1
                panel.animator().setFrame(frame, display: true)
            }
        }

        if settings.powerStatusPillSoundsEnabled {
            playSound(for: event)
        }

        dismissalTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            self?.dismiss(generation: currentGeneration)
        }
    }

    func dismissImmediately() {
        _ = presentationGeneration.next()
        dismissalTask?.cancel()
        dismissalTask = nil
        activeSound?.stop()
        activeSound = nil
        panel.orderOut(nil)
    }

    private func dismiss(generation expectedGeneration: Int) {
        guard presentationGeneration.isCurrent(expectedGeneration), panel.isVisible else {
            return
        }

        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            panel.orderOut(nil)
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            Task { @MainActor in
                guard
                    let self,
                    self.presentationGeneration.isCurrent(expectedGeneration)
                else {
                    return
                }
                self.panel.orderOut(nil)
            }
        }
    }

    private func playSound(for event: PowerAlertEvent) {
        activeSound?.stop()
        guard let sound = NSSound(named: NSSound.Name(soundName(for: event))) else {
            activeSound = nil
            return
        }
        sound.volume = 0.18
        activeSound = sound
        sound.play()
    }

    private func soundName(for event: PowerAlertEvent) -> String {
        switch event {
        case .charging: return "Tink"
        case .unplugged: return "Pop"
        case .lowBattery: return "Purr"
        case .fullyCharged: return "Glass"
        }
    }

    private func targetScreen() -> NSScreen? {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return NSScreen.main }

        let keyScreenID = NSApp.keyWindow
            .flatMap { $0 === panel ? nil : displayID(for: $0.screen) }
        let mainScreenID = displayID(for: NSScreen.main)
        let pointer = NSEvent.mouseLocation

        let descriptors = screens.compactMap { screen -> PowerAlertScreenDescriptor? in
            guard let id = displayID(for: screen) else { return nil }
            return PowerAlertScreenDescriptor(
                id: id,
                visibleFrame: screen.visibleFrame,
                isKey: id == keyScreenID,
                containsPointer: screen.frame.contains(pointer),
                isBuiltIn: CGDisplayIsBuiltin(id) != 0,
                isMain: id == mainScreenID
            )
        }
        guard let selected = PowerAlertScreenSelection.select(from: descriptors) else {
            return NSScreen.main ?? screens.first
        }
        return screens.first { displayID(for: $0) == selected.id }
    }

    private func displayID(for screen: NSScreen?) -> CGDirectDisplayID? {
        guard
            let number = screen?.deviceDescription[
                NSDeviceDescriptionKey("NSScreenNumber")
            ] as? NSNumber
        else {
            return nil
        }
        return CGDirectDisplayID(number.uint32Value)
    }
}
