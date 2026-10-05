import AppKit

/// 菜单栏控制器（图标 + 下拉菜单）
final class MenuBarController: NSObject {

    private let statusItem: NSStatusItem
    private weak var environment: AppEnvironment?
    private var enableItem: NSMenuItem?

    init(environment: AppEnvironment) {
        self.environment = environment
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        configureButton()
        buildMenu()
    }

    /// 刷新图标与菜单勾选状态
    func refresh() {
        guard let environment else { return }
        let active = environment.settings.isMonitoringEnabled && environment.permissionGranted
        statusItem.button?.image = NSImage(
            systemSymbolName: active ? "book.closed.fill" : "book.closed",
            accessibilityDescription: active ? "瞄词（监听中）" : "瞄词（已暂停）"
        )
        enableItem?.state = environment.settings.isMonitoringEnabled ? .on : .off
    }

    // MARK: - 内部

    private func configureButton() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "book.closed", accessibilityDescription: "瞄词")
        button.image?.isTemplate = true
    }

    private func buildMenu() {
        let menu = NSMenu()

        let enableItem = NSMenuItem(title: "启用监听", action: #selector(toggleEnabled), keyEquivalent: "")
        enableItem.target = self
        menu.addItem(enableItem)
        self.enableItem = enableItem

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "设置…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "退出瞄词", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func toggleEnabled() {
        environment?.toggleMonitoring()
    }

    @objc private func openSettings() {
        environment?.openSettings()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
