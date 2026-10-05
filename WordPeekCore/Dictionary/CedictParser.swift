import Foundation

/// CC-CEDICT 文本行解析器。
///
/// 行格式：`简体 繁体 [pin1 yin1] /义项1/义项2/`
/// 注释行以 `#` 开头，空行与非标准行返回 nil。
public enum CedictParser {

    /// 解析单行
    public static func parse(line: String) -> DictionaryEntry? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { return nil }
        guard let openBracket = trimmed.firstIndex(of: "["),
              let closeBracket = trimmed.firstIndex(of: "]"),
              openBracket < closeBracket else { return nil }

        let head = trimmed[..<openBracket].trimmingCharacters(in: .whitespaces)
        let pinyin = trimmed[trimmed.index(after: openBracket)..<closeBracket]
            .trimmingCharacters(in: .whitespaces)

        let tail = trimmed[trimmed.index(after: closeBracket)...]
        let glosses = tail
            .split(separator: "/")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard !glosses.isEmpty else { return nil }

        let headParts = head.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        guard let simplified = headParts.first, !simplified.isEmpty else { return nil }

        return DictionaryEntry(simplified: String(simplified), pinyin: pinyin, glosses: glosses)
    }

    /// 解析全文，返回全部词条（忽略注释行）
    public static func parseAll(text: String) -> [DictionaryEntry] {
        var entries: [DictionaryEntry] = []
        entries.reserveCapacity(131_000)
        text.enumerateLines { line, _ in
            if let entry = parse(line: line) {
                entries.append(entry)
            }
        }
        return entries
    }
}
