import AppKit
import ApplicationServices

/// 轮询系统焦点输入框，产出文本快照。
///
/// 采用 0.25s 定时轮询（而非 AXObserver 通知），对不完全支持 AX 通知的应用
/// （Electron / 浏览器网页等）更稳健。仅处理文本类元素；跳过本进程与密码框
/// （AXSecureTextField 不在白名单内）。
final class FocusMonitor {

    /// 文本快照回调（主线程）
    var onSnapshot: ((_ text: String) -> Void)?
    /// 焦点上下文变化（切换元素 / 焦点离开）回调：调用方应重置管线快照
    var onFocusContextChanged: (() -> Void)?

    /// 当前焦点元素（浮窗定位用；可能为 nil）
    private(set) var currentElement: AXUIElement?

    /// 最近一次轮询结论（供设置窗口诊断展示 / 诊断日志）
    private(set) var lastVerdict: String = "未启动" {
        didSet { if lastVerdict != oldValue { wpLog("poll \(lastVerdict)") } }
    }

    private var timer: Timer?
    private var lastElement: AXUIElement?
    private var lastValue: String?
    private let ownPID = ProcessInfo.processInfo.processIdentifier

    private static let acceptedRoles: Set<String> = [
        "AXTextField", "AXTextArea", "AXComboBox", "AXSearchField",
    ]

    var isRunning: Bool { timer != nil }

    func start() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        wpLog("monitor start (own pid=\(ownPID))")
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        lastElement = nil
        lastValue = nil
        currentElement = nil
        lastVerdict = "已停止（暂停监听或未授权）"
        wpLog("monitor stop")
    }

    // MARK: - 轮询

    private func poll() {
        guard AXIsProcessTrusted() else {
            lastVerdict = "AX 未授权：辅助功能权限缺失（或被 ad-hoc 重签名后失效）"
            return
        }

        guard let element = AXHelpers.focusedElement() else {
            lastVerdict = "取不到系统焦点元素（focusedElement = nil）"
            handleContextChange(to: nil)
            return
        }
        guard let pid = AXHelpers.pid(of: element) else {
            lastVerdict = "读不到焦点元素所属 pid"
            handleContextChange(to: nil)
            return
        }
        guard pid != ownPID else {
            lastVerdict = "焦点在本进程（设置窗口试打区，由 onChange 驱动）"
            handleContextChange(to: nil)
            return
        }

        let role = AXHelpers.stringAttribute(element, kAXRoleAttribute as String)
        let isAcceptedRole = role.map { Self.acceptedRoles.contains($0) } ?? false
        let isEditable = AXHelpers.boolAttribute(element, "AXEditable") ?? false
        guard isAcceptedRole || isEditable else {
            lastVerdict = "焦点元素非文本输入类，忽略 pid=\(pid) role=\(role ?? "nil") editable=\(isEditable)"
            handleContextChange(to: nil)
            return
        }

        let elementSwitched = !AXHelpers.isSame(lastElement, element)
        handleContextChange(to: element)

        guard let value = AXHelpers.stringAttribute(element, kAXValueAttribute as String) else {
            lastVerdict = "读不到 AXValue pid=\(pid) role=\(role ?? "nil")"
            return
        }

        lastVerdict = "监听中 pid=\(pid) role=\(role ?? "nil") len=\(value.count) 元素切换=\(elementSwitched ? "是" : "否")"
        guard value != lastValue else { return }
        lastValue = value
        onSnapshot?(value)
    }

    /// 焦点上下文（元素）发生变化时通知；同元素不重复通知
    private func handleContextChange(to element: AXUIElement?) {
        let changed: Bool
        if let element {
            changed = !AXHelpers.isSame(lastElement, element)
        } else {
            changed = lastElement != nil
        }
        guard changed else { return }
        if element != nil { wpLog("focus context changed → 重置外部域快照基线") }
        lastElement = element
        lastValue = nil
        currentElement = element
        onFocusContextChanged?()
    }
}
