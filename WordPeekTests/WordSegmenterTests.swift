import XCTest
@testable import WordPeekCore

final class WordSegmenterTests: XCTestCase {

    private let dictionary: Set<String> = ["咖啡", "咖啡店", "天气", "打工人", "猫咪"]

    private func segment(_ text: String) -> [WordSegmenter.Match] {
        WordSegmenter.segment(
            text,
            isKnownWord: { [dictionary] in dictionary.contains($0) },
            isStopWord: { StopWords.contains($0) }
        )
    }

    func testSingleWordHit() {
        let matches = segment("咖啡")
        XCTAssertEqual(matches.map(\.word), ["咖啡"])
        XCTAssertFalse(matches[0].isStopWord)
    }

    func testLongestMatchWins() {
        // "咖啡店" 同时在词典中时优先整体匹配
        let matches = segment("咖啡店")
        XCTAssertEqual(matches.map(\.word), ["咖啡店"])
    }

    func testStopWordConsumedForContinuity() {
        // "因为"（停用）应被切出并标记，避免拆出错误子词
        let matches = segment("因为天气")
        XCTAssertEqual(matches.map(\.word), ["因为", "天气"])
        XCTAssertTrue(matches[0].isStopWord)
        XCTAssertFalse(matches[1].isStopWord)
    }

    func testUnknownCharactersSkipped() {
        // "我"（停用单字）切出；"喝"未知跳过；"咖啡"命中
        let matches = segment("我喝咖啡")
        XCTAssertEqual(matches.map(\.word), ["我", "咖啡"])
        XCTAssertTrue(matches[0].isStopWord)
    }

    func testCharOffset() {
        let matches = segment("因为天气")
        XCTAssertEqual(matches[0].charOffset, 0)
        XCTAssertEqual(matches[1].charOffset, 2)
    }

    func testSentenceMixed() {
        let matches = segment("我们去喝咖啡吧")
        let shown = matches.filter { !$0.isStopWord }.map(\.word)
        XCTAssertEqual(shown, ["咖啡"])
    }

    func testNoHitReturnsEmpty() {
        // 全部字符既不在词典也不在停用表
        XCTAssertTrue(segment("翰海阑干").isEmpty)
    }
}
