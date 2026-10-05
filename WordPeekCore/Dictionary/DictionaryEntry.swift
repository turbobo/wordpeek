import Foundation

/// 词典词条（来源于 CC-CEDICT）。
public struct DictionaryEntry: Equatable, Codable {
    /// 简体词形
    public let simplified: String
    /// 拼音（带声调数字，如 "da3 gong1 ren2"）
    public let pinyin: String
    /// 英文义项（已按 "/" 拆分）
    public let glosses: [String]

    public init(simplified: String, pinyin: String, glosses: [String]) {
        self.simplified = simplified
        self.pinyin = pinyin
        self.glosses = glosses
    }

    /// 浮窗展示用的精简英文：最多取前 3 个义项，用 " · " 连接
    public var displayEnglish: String {
        glosses.prefix(3).joined(separator: " · ")
    }
}
