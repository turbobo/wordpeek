import AppKit

// 单实例守卫：已有实例运行时，仅请求其显示设置窗口，本进程退出。
// （避免多实例并存导致重复轮询与重复浮窗）
if !InstanceGuard.acquire() {
    InstanceGuard.notifyExistingInstance()
    Thread.sleep(forTimeInterval: 0.25) // 等待分布式通知投递
    exit(0)
}

// 菜单栏应用入口（LSUIElement，无 Dock 图标）
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
