import AppKit
import SwiftUI

enum InitialWindowLayout {
    static func frame(in visibleFrame: CGRect, fraction: CGFloat = 0.75) -> CGRect {
        let width = visibleFrame.width * fraction
        let height = visibleFrame.height * fraction
        return CGRect(
            x: visibleFrame.midX - (width / 2),
            y: visibleFrame.midY - (height / 2),
            width: width,
            height: height
        ).integral
    }
}

/// Applies the launch-time main-window size after SwiftUI attaches it to a screen.
struct InitialWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        InitialWindowConfigurationView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

@MainActor
private final class InitialWindowConfigurationView: NSView {
    private static var didConfigureThisLaunch = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil, !Self.didConfigureThisLaunch else { return }

        DispatchQueue.main.async { [weak self] in
            guard
                let window = self?.window,
                let screen = window.screen ?? NSScreen.main,
                !Self.didConfigureThisLaunch
            else {
                return
            }

            Self.didConfigureThisLaunch = true
            window.setFrame(
                InitialWindowLayout.frame(in: screen.visibleFrame),
                display: true,
                animate: false
            )
        }
    }
}
