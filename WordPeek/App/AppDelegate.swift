import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var environment: AppEnvironment!
    private var menuBar: MenuBarController!
    private var settingsWindow: SettingsWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let environment = AppEnvironment()
        self.environment = environment

        let settingsWindow = SettingsWindowController(environment: environment)
        self.settingsWindow = settingsWindow

        let menuBar = MenuBarController(environment: environment)
        self.menuBar = menuBar

        environment.settingsWindowProvider = { [weak settingsWindow] in settingsWindow }
        environment.onMonitoringStateChanged = { [weak menuBar] in menuBar?.refresh() }

        environment.start()
        menuBar.refresh()

        // 首次启动展示引导（权限 + 词典 + 试打区）；
        // 带 --show-settings 参数启动时也直接唤出设置窗口
        if !environment.settings.hasLaunchedBefore {
            environment.settings.hasLaunchedBefore = true
            settingsWindow.show()
        } else if CommandLine.arguments.contains("--show-settings") {
            settingsWindow.show()
        }
    }

    /// 重复打开应用（Finder 双击 / open）时唤出设置窗口
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        settingsWindow.show()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
