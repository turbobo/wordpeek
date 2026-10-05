import Foundation

/// 文本快照差分：比较前后两次输入框内容，提取「变化段」（新文本中的新增 / 替换内容）。
///
/// 注意：不能用「长度变短 = 删除」快速排除。系统输入法的上屏过程是
/// 拼音预编辑（ASCII，较长，如 "kafei"）→ 汉字（较短，如 "咖啡"），
/// 总长度反而缩短，但仍是一次有效的内容产出。这里统一用前缀/后缀收缩
/// 算法提取变化段；纯删除时得到空段返回 nil；该段是否为「值得展示的
/// 中文」由上层管线（长度 / 纯 CJK / 词典）过滤。
public enum TextDiffEngine {

    public struct Insertion: Equatable {
        /// 新增的文本片段
        public let text: String
        /// 插入区间在新文本中的 UTF-16 偏移（用于浮窗锚定）
        public let locationUTF16: Int
        /// 插入片段的 UTF-16 长度
        public let lengthUTF16: Int
    }

    /// 提取 oldText → newText 的变化片段
    public static func extractInsertion(oldText: String, newText: String) -> Insertion? {
        if oldText == newText { return nil }
        let old = Array(oldText)
        let new = Array(newText)

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
