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

    func testReplacementShorterReturnsNil() {
        // 净缩短的替换（选中替换为更短内容）不处理
        XCTAssertNil(TextDiffEngine.extractInsertion(oldText: "你好世界", newText: "您好"))
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
