import AppKit

// 菜单栏应用入口（LSUIElement，无 Dock 图标）
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
