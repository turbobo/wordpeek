import Foundation

/// 文本快照差分：比较前后两次输入框内容，提取"新插入的片段"。
///
/// 输入法上屏、逐字输入、选区替换（净增长）都会表现为一次插入；
/// 删除、无变化、净缩短的替换返回 nil。
public enum TextDiffEngine {

    public struct Insertion: Equatable {
        /// 新增的文本片段
        public let text: String
        /// 插入区间在新文本中的 UTF-16 偏移（用于浮窗锚定）
        public let locationUTF16: Int
        /// 插入片段的 UTF-16 长度
        public let lengthUTF16: Int
    }

    /// 提取 oldText → newText 的插入片段
    public static func extractInsertion(oldText: String, newText: String) -> Insertion? {
        if oldText == newText { return nil }
        let old = Array(oldText)
        let new = Array(newText)
        // 净缩短（删除操作）不处理
        guard new.count > old.count else { return nil }

        // 公共前缀（Character 级，天然兼容多字节与组合字符）
        let maxPrefix = min(old.count, new.count)
        var prefix = 0
        while prefix < maxPrefix && old[prefix] == new[prefix] { prefix += 1 }

        // 公共后缀
        let maxSuffix = min(old.count, new.count) - prefix
        var suffix = 0
        while suffix < maxSuffix && old[old.count - 1 - suffix] == new[new.count - 1 - suffix] { suffix += 1 }

        let inserted = new[prefix..<(new.count - suffix)]
        guard !inserted.isEmpty else { return nil }

        let text = String(inserted)
        // Character 偏移 → UTF-16 偏移（AX 的 range 语义）
        let location = String(new[..<prefix]).utf16.count
        return Insertion(text: text, locationUTF16: location, lengthUTF16: text.utf16.count)
    }
}
