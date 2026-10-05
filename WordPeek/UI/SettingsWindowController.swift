import AppKit
import SwiftUI

/// 设置窗口控制器（亦承担首次启动引导）
final class SettingsWindowController: NSWindowController {

    init(environment: AppEnvironment) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 660),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "瞄词 WordPeek"
        window.isReleasedWhenClosed = false
        window.center()
        super.init(window: window)

        let hosting = NSHostingView(rootView: SettingsView(
            environment: environment,
            settings: environment.settings
        ))
        window.contentView = hosting
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
