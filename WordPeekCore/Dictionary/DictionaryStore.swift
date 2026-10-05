import Foundation

/// 词典内存索引。
///
/// 数据来源优先级：下载/导入的完整 CC-CEDICT > 内置演示词表。
/// 线程约定：仅在主线程读写（监听轮询与 UI 都在主线程）。
public final class DictionaryStore {

    private var map: [String: DictionaryEntry] = [:]

    /// 当前是否为完整词典（否则为内置演示词表）
    public private(set) var isUsingFullDictionary = false

    public init() {}

    public var count: Int { map.count }

    /// 整体替换词条数据
    /// - Parameter isFullDictionary: 是否为完整词典
    public func load(entries: [DictionaryEntry], isFullDictionary: Bool) {
        var newMap: [String: DictionaryEntry] = [:]
        newMap.reserveCapacity(entries.count)
        for entry in entries where newMap[entry.simplified] == nil {
            newMap[entry.simplified] = entry
        }
        map = newMap
        isUsingFullDictionary = isFullDictionary
    }

    /// 词典是否可用
    public var isEmpty: Bool { map.isEmpty }

    public func lookup(_ word: String) -> DictionaryEntry? {
        map[word]
    }

    public func hasWord(_ word: String) -> Bool {
        map[word] != nil
    }
}
