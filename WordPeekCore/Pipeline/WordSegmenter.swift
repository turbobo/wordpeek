import Foundation

/// 中文贪心最长匹配切词。
///
/// 用途：整句上屏（如语音输入）时，从插入片段中提取可查询的词。
/// 切分连续性依赖"已知词"判定（词典命中 ∪ 停用词），未知片段按单字跳过。
public enum WordSegmenter {

    public struct Match: Equatable {
        /// 命中的词
        public let word: String
        /// 是否命中停用表（命中即为"切分用词"，不应展示）
        public let isStopWord: Bool
        /// 词在输入文本中的起始 Character 偏移
        public let charOffset: Int
    }

    /// - Parameters:
    ///   - text: 待切分的中文片段
    ///   - maxWordLength: 单次匹配尝试的最大词长
    ///   - isKnownWord: 词典命中判定
    ///   - isStopWord: 停用词判定
    /// - Returns: 按文本顺序排列的命中词
    public static func segment(
        _ text: String,
        maxWordLength: Int = 6,
        isKnownWord: (String) -> Bool,
        isStopWord: (String) -> Bool
    ) -> [Match] {
        let chars = Array(text)
        var matches: [Match] = []
        var index = 0

        while index < chars.count {
            var matched = false
            let maxLen = min(maxWordLength, chars.count - index)
            var len = maxLen
            while len >= 1 {
                let word = String(chars[index..<(index + len)])
                let inDictionary = isKnownWord(word)
                let inStopWords = isStopWord(word)
                if inDictionary || inStopWords {
                    matches.append(Match(word: word, isStopWord: inStopWords, charOffset: index))
                    index += len
                    matched = true
                    break
                }
                len -= 1
            }
            if !matched {
                // 未知单字：跳过（不查询）
                index += 1
            }
        }
        return matches
    }
}
