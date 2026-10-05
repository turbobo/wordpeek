import AppKit

/// 坐标系转换：Accessibility / CG 全局坐标（主屏左上为原点）↔ Cocoa 全局坐标（主屏左下为原点）
enum CoordinateConverter {

    /// AX 矩形 → Cocoa 矩形
    static func cocoaRect(fromAXRect ax: CGRect) -> CGRect {
        guard let primary = NSScreen.screens.first else { return ax }
        let screenHeight = primary.frame.height
        return CGRect(
            x: ax.origin.x,
            y: screenHeight - ax.maxY,
            width: ax.width,
            height: ax.height
        )
    }

    /// 包含指定 Cocoa 点的屏幕（找不到时回退主屏）
    static func screen(containing cocoaPoint: CGPoint) -> NSScreen? {
        NSScreen.screens.first { $0.frame.contains(cocoaPoint) } ?? NSScreen.main
    }
}
