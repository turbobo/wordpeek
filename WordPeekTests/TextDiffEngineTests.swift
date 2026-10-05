import XCTest
@testable import WordPeekCore

final class TextDiffEngineTests: XCTestCase {

    func testAppendAtEnd() {
        let result = TextDiffEngine.extractInsertion(oldText: "我今天", newText: "我今天喝了咖啡")
        XCTAssertEqual(result?.text, "喝了咖啡")
        XCTAssertEqual(result?.locationUTF16, "我今天".utf16.count)
        XCTAssertEqual(result?.lengthUTF16, "喝了咖啡".utf16.count)
    }

    func testInsertInMiddle() {
        let result = TextDiffEngine.extractInsertion(oldText: "我吃饭", newText: "我想吃饭")
        XCTAssertEqual(result?.text, "想")
        XCTAssertEqual(result?.locationUTF16, 1)
    }

    func testNoChange() {
        XCTAssertNil(TextDiffEngine.extractInsertion(oldText: "你好", newText: "你好"))
    }

    func testDeletionReturnsNil() {
        XCTAssertNil(TextDiffEngine.extractInsertion(oldText: "你好世界", newText: "你好"))
    }

    func testPureDeletionOfCompositionReturnsNil() {
        // 拼音预编辑回退（纯删除）不产出
        XCTAssertNil(TextDiffEngine.extractInsertion(oldText: "kafei", newText: "kafe"))
    }

    func testShorterReplacementExtractsNewChunk() {
        // 删除+替换混合：应提取新段（由上层按单字/词典规则决定是否展示）
        // "你好" → "您好"：首字不同，尾部"好/界"也不同 → 新段为整个"您好"
        let result = TextDiffEngine.extractInsertion(oldText: "你好世界", newText: "您好")
        XCTAssertEqual(result?.text, "您好")
        XCTAssertEqual(result?.locationUTF16, 0)
    }

    func testPinyinCompositionCommit() {
        // 核心回归：系统输入法上屏 —— 拼音预编辑(5 个 ASCII) → 汉字(2 字)，总长度缩短
        let result = TextDiffEngine.extractInsertion(oldText: "kafei", newText: "咖啡")
        XCTAssertEqual(result?.text, "咖啡")
        XCTAssertEqual(result?.locationUTF16, 0)
    }

    func testPinyinCommitAppendsToExistingText() {
        // 已有文本后继续输入并上屏
        let result = TextDiffEngine.extractInsertion(oldText: "你好kafei", newText: "你好咖啡")
        XCTAssertEqual(result?.text, "咖啡")
        XCTAssertEqual(result?.locationUTF16, 2)
    }

    func testInsertFromEmpty() {
        let result = TextDiffEngine.extractInsertion(oldText: "", newText: "咖啡")
        XCTAssertEqual(result?.text, "咖啡")
        XCTAssertEqual(result?.locationUTF16, 0)
    }

    func testEmojiContent() {
        let result = TextDiffEngine.extractInsertion(oldText: "hello ", newText: "hello 咖啡☕️")
        XCTAssertEqual(result?.text, "咖啡☕️")
    }

    func testUTF16LocationWithVariationSelector() {
        // "☕️" = U+2615 + U+FE0F，UTF-16 长度为 2
        let result = TextDiffEngine.extractInsertion(oldText: "☕️", newText: "☕️咖啡")
        XCTAssertEqual(result?.text, "咖啡")
        XCTAssertEqual(result?.locationUTF16, "☕️".utf16.count)
    }

    func testRepeatedWordSuffixHandling() {
        // 重复词：前缀与后缀重叠时不应吞掉插入内容
        let result = TextDiffEngine.extractInsertion(oldText: "咖啡", newText: "咖啡咖啡")
        XCTAssertEqual(result?.text, "咖啡")
    }
}
