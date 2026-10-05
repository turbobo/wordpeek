import Foundation

/// 文本基础工具：CJK 判定等。
public enum TextUtilities {
    /// 移除字符串首尾的空白与换行
    public static func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Character {
    /// 是否为 CJK 汉字（基本区 U+4E00–U+9FFF 或扩展 A 区 U+3400–U+4DBF）
    public var isCJKLetter: Bool {
        guard unicodeScalars.count == 1, let scalar = unicodeScalars.first else { return false }
        switch scalar.value {
        case 0x4E00...0x9FFF, 0x3400...0x4DBF:
            return true
        default:
            return false
        }
    }
}

extension String {
    /// 是否全部由 CJK 汉字组成（空串返回 false）
    public var isAllCJK: Bool {
        !isEmpty && allSatisfy { $0.isCJKLetter }
    }
}
