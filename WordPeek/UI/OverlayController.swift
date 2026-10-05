import AppKit
import ApplicationServices
import SwiftUI
import WordPeekCore

/// 「词 → 英文」浮窗控制器（无边框非激活面板，不抢焦点、不接收鼠标事件）
final class OverlayController {

    /// 浮窗锚点
    enum Anchor {
        /// 真实输入场景：锚定到 AX 元素的文本区间
        case axRange(element: AXUIElement, range: NSRange)
        /// App 内测试场景：锚定到 Cocoa 矩形（如设置窗口底边）
        case cocoaRect(CGRect)
        /// 兜底：鼠标位置
        case mouse
    }

    /// 浮窗停留时长（秒），由设置驱动
    var displayDuration: TimeInterval = 2.5

    /// 调试状态（仅用于诊断日志 / self-test）
    var debugState: String {
        guard let panel else { return "panel=nil" }
        return "visible=\(panel.isVisible) frame=\(panel.frame) alpha=\(panel.alphaValue)"
    }

    private var panel: OverlayPanel?
    private var hostingView: NSHostingView<OverlayView>?
    private var hideWorkItem: DispatchWorkItem?

    private let fadeInDuration: TimeInterval = 0.18
    private let fadeOutDuration: TimeInterval = 0.25

    /// 显示浮窗（主线程调用）
    func show(result: LookupResult, anchor: Anchor) {
        let panel = ensurePanel()
        let hostingView = ensureHostingView()

        hostingView.rootView = OverlayView(result: result)
        hostingView.layoutSubtreeIfNeeded()
        let size = hostingView.fittingSize
        panel.setContentSize(size)
        let origin = targetOrigin(for: size, anchor: anchor)
        panel.setFrameOrigin(origin)
        wpLog("overlay show size=\(size) origin=\(origin)")

        // 重置自动隐藏计时
        hideWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.hide()
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration, execute: workItem)

        if panel.isVisible {
            // 已显示：直接更新内容并保持可见
            panel.alphaValue = 1
        } else {
            panel.alphaValue = 0
            panel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = fadeInDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().alphaValue = 1
            }
        }
    }

    /// 隐藏浮窗（淡出）
    func hide() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
        guard let panel, panel.isVisible else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = fadeOutDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.orderOut(nil)
        })
    }

    // MARK: - 面板

    private func ensurePanel() -> OverlayPanel {
        if let panel { return panel }
        let panel = OverlayPanel(
            contentRect: NSRect(x: 0, y: 0, width: 120, height: 40),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.isMovable = false
        panel.animationBehavior = .none
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .transient]
        self.panel = panel
        return panel
    }

    private func ensureHostingView() -> NSHostingView<OverlayView> {
        if let hostingView { return hostingView }
        let view = NSHostingView(rootView: OverlayView(
            result: LookupResult(word: "", english: "", pinyin: "", rangeUTF16: nil)
        ))
        hostingView = view
        panel?.contentView = view
        return view
    }

    // MARK: - 定位

    private func targetOrigin(for size: CGSize, anchor: Anchor) -> CGPoint {
        guard let rect = resolveCocoaAnchorRect(anchor) else {
            // 兜底：鼠标右下方
            let mouse = NSEvent.mouseLocation
            return clamp(origin: CGPoint(x: mouse.x + 12, y: mouse.y - size.height - 12), size: size)
        }

        // 默认出现在锚点下方
        var origin = CGPoint(x: rect.midX - size.width / 2, y: rect.minY - size.height - 10)
        let screen = CoordinateConverter.screen(containing: CGPoint(x: rect.midX, y: rect.midY))
        if let visible = screen?.visibleFrame, origin.y < visible.minY + 6 {
            // 下方空间不足 → 改到锚点上方
            origin = CGPoint(x: rect.midX - size.width / 2, y: rect.maxY + 10)
        }
        return clamp(origin: origin, size: size)
    }

    private func resolveCocoaAnchorRect(_ anchor: Anchor) -> CGRect? {
        switch anchor {
        case .axRange(let element, let range):
            if let axRect = AXHelpers.bounds(for: range, in: element) {
                return CoordinateConverter.cocoaRect(fromAXRect: axRect)
            }
            if let elementFrame = AXHelpers.frame(of: element) {
                return CoordinateConverter.cocoaRect(fromAXRect: elementFrame)
            }
            return nil
        case .cocoaRect(let rect):
            return rect
        case .mouse:
            return nil
        }
    }

    private func clamp(origin: CGPoint, size: CGSize) -> CGPoint {
        let center = CGPoint(x: origin.x + size.width / 2, y: origin.y + size.height / 2)
        guard let screen = CoordinateConverter.screen(containing: center) else { return origin }
        let frame = screen.visibleFrame
        var result = origin
        result.x = min(max(result.x, frame.minX + 6), frame.maxX - size.width - 6)
        result.y = min(max(result.y, frame.minY + 6), frame.maxY - size.height - 6)
        return result
    }
}

/// 不抢焦点的浮窗面板
private final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
