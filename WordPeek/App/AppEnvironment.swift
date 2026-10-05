import AppKit
import ApplicationServices
import Combine
import Foundation
import WordPeekCore

/// 应用运行环境：组装全部组件，暴露 UI 状态与动作。
///
/// 数据流：
///   FocusMonitor（AX 轮询）┐
///                         ├→ LookupPipeline → OnLookup → OverlayController
///   设置窗口测试框（App 内）┘
final class AppEnvironment: ObservableObject {

    let settings: AppSettings
    let store = DictionaryStore()
    let pipeline: LookupPipeline
    let overlay = OverlayController()
    let downloader = DictionaryDownloader()

    /// AX 辅助功能权限状态
    @Published private(set) var permissionGranted = false
    /// 词典状态文案
    @Published private(set) var dictionaryInfo = "加载中…"
    /// 下载 / 导入进行中
    @Published private(set) var isBusy = false
    /// 下载 / 导入状态文案
    @Published private(set) var busyMessage: String?

    /// 设置窗口提供者（AppDelegate 注入）
    var settingsWindowProvider: (() -> SettingsWindowController?)?
    /// 监听状态变化通知（菜单栏刷新图标）
    var onMonitoringStateChanged: (() -> Void)?

    /// 最近一次查词是否来自设置窗口测试框（决定浮窗锚点）
    private var lastLookupSourceIsTest = false
    private let monitor = FocusMonitor()
    private var permissionTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init() {
        settings = AppSettings()
        pipeline = LookupPipeline(store: store)
        wire()
    }

    /// 启动：加载词典、开始权限轮询与监听
    func start() {
        store.load(entries: BuiltinDictionary.entries(), isFullDictionary: false)
        updateDictionaryInfo()

        // 后台加载已安装的完整词典
        downloader.loadInstalledDictionary { [weak self] entries in
            guard let self, let entries else { return }
            self.store.load(entries: entries, isFullDictionary: true)
            self.updateDictionaryInfo()
        }

        refreshPermission()
        applyMonitoringState()
        let timer = Timer(timeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.refreshPermission()
        }
        RunLoop.main.add(timer, forMode: .common)
        permissionTimer = timer
    }

    // MARK: - 动作（UI / 菜单栏调用）

    func toggleMonitoring() {
        settings.isMonitoringEnabled.toggle()
    }

    func openSettings() {
        settingsWindowProvider?()?.show()
    }

    /// 设置窗口测试框驱动（App 内演示链路，不依赖 AX 权限）
    func ingestTestText(_ text: String) {
        lastLookupSourceIsTest = true
        pipeline.ingest(text: text)
    }

    /// 测试框聚焦 / 窗口展示时，将其当前文本设为差分基线，
    /// 避免“首次输入被当作首帧记录而不展示”。
    func primeTestField(_ text: String) {
        lastLookupSourceIsTest = true
        pipeline.prime(text: text)
    }

    func refreshPermission() {
        let granted = AXIsProcessTrusted()
        guard granted != permissionGranted else { return }
        permissionGranted = granted
        applyMonitoringState()
    }

    /// 触发系统授权引导并跳转到辅助功能设置页
    func openAccessibilityPreferences() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func downloadDictionary() {
        guard !isBusy else { return }
        isBusy = true
        busyMessage = "准备下载…"
        downloader.downloadAndInstall(
            onStatus: { [weak self] status in
                self?.busyMessage = status
            },
            completion: { [weak self] result in
                guard let self else { return }
                self.isBusy = false
                switch result {
                case .success(let entries):
                    self.store.load(entries: entries, isFullDictionary: true)
                    self.updateDictionaryInfo()
                    self.busyMessage = "词典安装完成（\(entries.count) 条）"
                case .failure(let error):
                    self.busyMessage = "下载失败：\(error.localizedDescription)"
                }
            }
        )
    }

    func importDictionary() {
        guard !isBusy else { return }
        let panel = NSOpenPanel()
        panel.title = "选择 CC-CEDICT 词典文件（.txt 或 .gz）"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }

        isBusy = true
        busyMessage = "准备导入…"
        downloader.install(
            fromFile: url,
            onStatus: { [weak self] status in
                self?.busyMessage = status
            },
            completion: { [weak self] result in
                guard let self else { return }
                self.isBusy = false
                switch result {
                case .success(let entries):
                    self.store.load(entries: entries, isFullDictionary: true)
                    self.updateDictionaryInfo()
                    self.busyMessage = "导入完成（\(entries.count) 条）"
                case .failure(let error):
                    self.busyMessage = "导入失败：\(error.localizedDescription)"
                }
            }
        )
    }

    // MARK: - 内部

    private func wire() {
        // 设置 → 运行时组件
        overlay.displayDuration = settings.overlayDuration
        pipeline.config.showSingleCharWords = settings.showSingleCharWords
        settings.$overlayDuration
            .sink { [weak self] in self?.overlay.displayDuration = $0 }
            .store(in: &cancellables)
        settings.$showSingleCharWords
            .sink { [weak self] in self?.pipeline.config.showSingleCharWords = $0 }
            .store(in: &cancellables)
        settings.$isMonitoringEnabled
            .sink { [weak self] _ in self?.applyMonitoringState() }
            .store(in: &cancellables)

        // 管线输出 → 浮窗
        pipeline.onLookup = { [weak self] result in
            self?.present(result: result)
        }

        // AX 监听 → 管线
        monitor.onSnapshot = { [weak self] text in
            guard let self else { return }
            self.lastLookupSourceIsTest = false
            self.pipeline.ingest(text: text)
        }
        monitor.onFocusContextChanged = { [weak self] in
            self?.pipeline.resetSnapshot()
        }
    }

    private func applyMonitoringState() {
        let shouldRun = settings.isMonitoringEnabled && permissionGranted
        if shouldRun {
            if !monitor.isRunning { monitor.start() }
        } else {
            if monitor.isRunning { monitor.stop() }
            pipeline.resetSnapshot()
        }
        onMonitoringStateChanged?()
    }

    private func present(result: LookupResult) {
        overlay.displayDuration = settings.overlayDuration
        let anchor: OverlayController.Anchor
        if lastLookupSourceIsTest {
            // App 内测试：锚定在设置窗口底边中点（浮窗出现在窗口下方）
            let frame = settingsWindowProvider?()?.window?.frame
            anchor = .cocoaRect(CGRect(
                x: frame?.midX ?? 200,
                y: frame?.minY ?? 200,
                width: 2,
                height: 2
            ))
        } else if let element = monitor.currentElement {
            anchor = .axRange(
                element: element,
                range: result.rangeUTF16 ?? NSRange(location: 0, length: 1)
            )
        } else {
            anchor = .mouse
        }
        overlay.show(result: result, anchor: anchor)
    }

    private func updateDictionaryInfo() {
        if store.isUsingFullDictionary {
            dictionaryInfo = "完整词典已安装：\(store.count) 条词条"
        } else {
            dictionaryInfo = "内置演示词表：\(store.count) 条（建议下载完整词典）"
        }
    }
}
