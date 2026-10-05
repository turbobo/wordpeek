import Combine
import Foundation

/// 应用设置（UserDefaults 持久化，@Published 驱动 SwiftUI）
final class AppSettings: ObservableObject {

    /// 是否启用全局监听
    @Published var isMonitoringEnabled: Bool {
        didSet { defaults.set(isMonitoringEnabled, forKey: Keys.monitoringEnabled) }
    }

    /// 是否展示单字词（默认关闭，避免浮窗过于频繁）
    @Published var showSingleCharWords: Bool {
        didSet { defaults.set(showSingleCharWords, forKey: Keys.showSingleCharWords) }
    }

    /// 浮窗停留时长（秒）
    @Published var overlayDuration: Double {
        didSet { defaults.set(overlayDuration, forKey: Keys.overlayDuration) }
    }

    /// 是否已经启动过（首次启动展示引导窗口）
    var hasLaunchedBefore: Bool {
        get { defaults.bool(forKey: Keys.hasLaunchedBefore) }
        set { defaults.set(newValue, forKey: Keys.hasLaunchedBefore) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let monitoringEnabled = "monitoringEnabled"
        static let showSingleCharWords = "showSingleCharWords"
        static let overlayDuration = "overlayDuration"
        static let hasLaunchedBefore = "hasLaunchedBefore"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isMonitoringEnabled = defaults.object(forKey: Keys.monitoringEnabled) as? Bool ?? true
        showSingleCharWords = defaults.object(forKey: Keys.showSingleCharWords) as? Bool ?? false
        overlayDuration = defaults.object(forKey: Keys.overlayDuration) as? Double ?? 2.5
    }
}
