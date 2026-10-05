import Foundation

/// 查词结果（浮窗展示模型）
public struct LookupResult: Equatable {
    /// 中文词
    public let word: String
    /// 英文（精简展示文本）
    public let english: String
    /// 拼音
    public let pinyin: String
    /// 触发词在文本中的 UTF-16 区间（用于浮窗锚定，可能为 nil）
    public let rangeUTF16: NSRange?

    public init(word: String, english: String, pinyin: String, rangeUTF16: NSRange?) {
        self.word = word
        self.english = english
        self.pinyin = pinyin
        self.rangeUTF16 = rangeUTF16
    }
}

/// 快照来源：外部应用（AX 监听）与 App 内试打区相互隔离。
/// 两套来源由不同的异步机制驱动（0.25s 轮询 vs SwiftUI 焦点事件），
/// 隔离可避免切换瞬间互相清空快照（如试打区基线被外部 reset 误清）。
public enum SnapshotSource {
    case external
    case testField
}

/// 打字 → 查词 的核心管线。
///
/// 职责：接收文本快照，差分出新插入的中文片段，切词并查询词典，
/// 产出值得展示的「词 → 英文」。完全独立于 Accessibility，可单测。
///
/// 线程约定：主线程调用 ingest；onLookup 在主线程回调。
public final class LookupPipeline {

    public struct Config {
        /// 是否展示单字词（默认关闭）
        public var showSingleCharWords = false
        /// 同词冷却时间（秒），避免连续重复弹出
        public var dedupInterval: TimeInterval = 3
        /// 大于该长度的插入片段视为粘贴 / 整段输入，不处理
        public var maxInsertedLength = 16

        public init() {}
    }

    public var config = Config()
    /// 查到值得展示的词时回调（主线程）
    public var onLookup: ((LookupResult) -> Void)?

    private let store: DictionaryStore
    private let now: () -> Date

    private struct SnapshotState {
        var text = ""
        var hasSnapshot = false
    }

    private var externalSnapshot = SnapshotState()
    private var testFieldSnapshot = SnapshotState()
    private var lastShown: [String: Date] = [:]

    /// - Parameter now: 当前时间提供者（测试可注入）
    public init(store: DictionaryStore, now: @escaping () -> Date = Date.init) {
        self.store = store
        self.now = now
    }

    /// 重置快照：切换输入焦点 / 暂停监听时调用（默认外部域）。
    /// 下一次 ingest 只记录快照，不产出结果（避免跨输入框误报）。
    public func resetSnapshot(source: SnapshotSource = .external) {
        setSnapshot(SnapshotState(), for: source)
    }

    /// 直接设置快照基线（不触发查询）。
    /// 用于设置窗口测试框：聚焦时先把当前文本设为基线，之后的输入即可正常差分。
    public func prime(text: String, source: SnapshotSource = .external) {
        setSnapshot(SnapshotState(text: text, hasSnapshot: true), for: source)
    }

    /// 送入一次文本快照（来自 AX 监听或 App 内测试框）
    public func ingest(text: String, source: SnapshotSource = .external) {
        var snapshot = snapshot(for: source)
        defer { setSnapshot(snapshot, for: source) }

        guard snapshot.hasSnapshot else {
            snapshot.hasSnapshot = true
            snapshot.text = text
            return
        }
        let previous = snapshot.text
        snapshot.text = text
        guard let insertion = TextDiffEngine.extractInsertion(oldText: previous, newText: text) else {
            return
        }
        handle(insertion: insertion)
    }

    // MARK: - 快照存取

    private func setSnapshot(_ state: SnapshotState, for source: SnapshotSource) {
        switch source {
        case .external: externalSnapshot = state
        case .testField: testFieldSnapshot = state
        }
    }

    private func snapshot(for source: SnapshotSource) -> SnapshotState {
        switch source {
        case .external: return externalSnapshot
        case .testField: return testFieldSnapshot
        }
    }

    // MARK: - 内部处理

    private func handle(insertion: TextDiffEngine.Insertion) {
        let inserted = insertion.text

        // 1. 长度阀门：防粘贴 / 防长文本误触发
        guard !inserted.isEmpty, inserted.count <= config.maxInsertedLength else { return }
        // 2. 纯中文校验：含标点 / 字母 / 数字 / 空白的片段不处理
        guard inserted.isAllCJK else { return }

        // 3. 切词（词典命中 ∪ 停用词 保证切分连续性）
        let matches = WordSegmenter.segment(
            inserted,
            isKnownWord: { [store] in store.hasWord($0) },
            isStopWord: { StopWords.contains($0) }
        )

        // 4. 选词：过滤停用词与单字（按开关），取最后一个（用户刚打完的词）
        var candidates = matches.filter { !$0.isStopWord }
        if !config.showSingleCharWords {
            candidates = candidates.filter { $0.word.count >= 2 }
        }
        guard let chosen = candidates.last else { return }

        // 5. 查询词典
        guard let entry = store.lookup(chosen.word) else { return }

        // 6. 冷却去重
        let timestamp = now()
        if let last = lastShown[chosen.word], timestamp.timeIntervalSince(last) < config.dedupInterval {
            return
        }
        lastShown[chosen.word] = timestamp
        pruneDedupTable(reference: timestamp)

        // 7. 计算词在全文中的 UTF-16 区间（用于浮窗锚定）
        let chars = Array(inserted)
        let prefixUTF16 = String(chars[..<chosen.charOffset]).utf16.count
        let range = NSRange(
            location: insertion.locationUTF16 + prefixUTF16,
            length: chosen.word.utf16.count
        )

        onLookup?(LookupResult(
            word: chosen.word,
            english: entry.displayEnglish,
            pinyin: entry.pinyin,
            rangeUTF16: range
        ))
    }

    /// 控制去重表规模，清理过期项
    private func pruneDedupTable(reference: Date) {
        guard lastShown.count > 200 else { return }
        lastShown = lastShown.filter { reference.timeIntervalSince($0.value) < 60 }
    }
}
