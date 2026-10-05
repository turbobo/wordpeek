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
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        lastElement = nil
        lastValue = nil
        currentElement = nil
    }

    // MARK: - 轮询

    private func poll() {
        guard AXIsProcessTrusted() else { return }

        guard let element = AXHelpers.focusedElement(),
              let pid = AXHelpers.pid(of: element),
              pid != ownPID else {
            // 无焦点 / 焦点在本进程（设置窗口测试框自行驱动管线）
            handleContextChange(to: nil)
            return
        }

        let role = AXHelpers.stringAttribute(element, kAXRoleAttribute as String)
        let isAcceptedRole = role.map { Self.acceptedRoles.contains($0) } ?? false
        let isEditable = AXHelpers.boolAttribute(element, "AXEditable") ?? false
        guard isAcceptedRole || isEditable else {
            handleContextChange(to: nil)
            return
        }

        handleContextChange(to: element)

        guard let value = AXHelpers.stringAttribute(element, kAXValueAttribute as String) else { return }
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
        lastElement = element
        lastValue = nil
        currentElement = element
        onFocusContextChanged?()
    }
}
