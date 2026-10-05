import AppKit

/// 菜单栏控制器（图标 + 下拉菜单）
final class MenuBarController: NSObject {

    private let statusItem: NSStatusItem
    private weak var environment: AppEnvironment?
    private var enableItem: NSMenuItem?
    private var permissionItem: NSMenuItem?

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
        let granted = environment.permissionGranted
        let active = environment.settings.isMonitoringEnabled && granted
        // 未授权时用感叹号图标显式告警：否则「打字不弹」看起来像功能坏了
        statusItem.button?.image = NSImage(
            systemSymbolName: granted ? (active ? "book.closed.fill" : "book.closed") : "exclamationmark.circle.fill",
            accessibilityDescription: granted ? (active ? "瞄词（监听中）" : "瞄词（已暂停）") : "瞄词（未授权辅助功能）"
        )
        statusItem.button?.contentTintColor = granted ? nil : .systemOrange
        statusItem.button?.toolTip = Self.statusText(granted: granted, enabled: environment.settings.isMonitoringEnabled)
        enableItem?.state = environment.settings.isMonitoringEnabled ? .on : .off
        refreshPermissionItem(granted: granted)
    }

    private static func statusText(granted: Bool, enabled: Bool) -> String {
        if !granted { return "瞄词：未授权辅助功能，打字不会弹翻译（点击菜单栏 → 去授权）" }
        return enabled ? "瞄词：监听中" : "瞄词：已暂停"
    }

    /// 权限状态行：未授权时可直接点击跳转授权页（ad-hoc 重签名后权限会失效，必须可自助修复）
    private func refreshPermissionItem(granted: Bool) {
        guard let permissionItem else { return }
        permissionItem.title = granted ? "辅助功能权限：已授权" : "辅助功能权限：未授权 → 点此开启"
        permissionItem.action = granted ? nil : #selector(openPermissionSettings)
        permissionItem.target = granted ? nil : self
    }

    // MARK: - 内部

    private func configureButton() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "book.closed", accessibilityDescription: "瞄词")
        button.image?.isTemplate = true
    }

    private func buildMenu() {
        let menu = NSMenu()

        let permissionItem = NSMenuItem(title: "辅助功能权限：检测中…",
                                       action: nil, keyEquivalent: "")
        permissionItem.target = self
        menu.addItem(permissionItem)
        self.permissionItem = permissionItem

        menu.addItem(.separator())

        let doctorItem = NSMenuItem(title: "自检（诊断日志）", action: #selector(runDoctorLog), keyEquivalent: "")
        doctorItem.target = self
        menu.addItem(doctorItem)

        menu.addItem(.separator())

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

    @objc private func openPermissionSettings() {
        environment?.openAccessibilityPreferences()
    }

    /// 在诊断日志里补一条当前状态摘要（不重启、不弹窗）
    @objc private func runDoctorLog() {
        environment?.dumpDiagnostics()
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
