import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var environment: AppEnvironment!
    private var menuBar: MenuBarController!
    private var settingsWindow: SettingsWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        wpDebugLogReset()
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

        // 监听「第二实例请求显示设置窗口」的分布式通知（单实例守卫配合）
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleShowSettingsRequest),
            name: InstanceGuard.showSettingsNotification,
            object: nil
        )

        // 首次启动展示引导（权限 + 词典 + 试打区）；
        // 带 --show-settings 参数启动时也直接唤出设置窗口
        if !environment.settings.hasLaunchedBefore {
            environment.settings.hasLaunchedBefore = true
            settingsWindow.show()
        } else if CommandLine.arguments.contains("--show-settings") {
            settingsWindow.show()
        } else if !environment.permissionGranted {
            // 老用户重新构建后 TCC 授权会失效（ad-hoc 签名换指纹）。
            // 此时若不提示，表现就是「打字没反应」，因此每次启动未完成授权都唤出引导。
            wpLog("ungranted at launch → show settings for guidance")
            settingsWindow.show()
        }

        // 诊断模式：自动模拟一次试打区输入，验证「管线 → 浮窗」全链路后退出
        if CommandLine.arguments.contains("--self-test") {
            runSelfTest()
        }
    }

    /// 重复打开应用（Finder 双击 / open）时唤出设置窗口
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        settingsWindow.show()
        return true
    }

    /// 第二实例请求显示设置窗口
    @objc private func handleShowSettingsRequest(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.settingsWindow.show()
        }
    }

    /// 自动诊断：输出全链路状态摘要 + 模拟试打区完整输入序列，验证后退出
    private func runSelfTest() {
        wpLog("self-test begin")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            let env = self.environment!
            env.dumpDiagnostics()
            env.smokeTestPipeline()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                wpLog("overlay after smoke test: \(env.overlay.debugState)")
                env.dumpDiagnostics()
                wpLog("self-test done")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    NSApp.terminate(nil)
                }
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
