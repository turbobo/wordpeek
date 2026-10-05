import XCTest
@testable import WordPeekCore

final class LookupPipelineTests: XCTestCase {

    private func makeStore() -> DictionaryStore {
        let store = DictionaryStore()
        store.load(entries: [
            DictionaryEntry(simplified: "咖啡", pinyin: "ka1 fei1", glosses: ["coffee"]),
            DictionaryEntry(simplified: "天气", pinyin: "tian1 qi4", glosses: ["weather"]),
            DictionaryEntry(simplified: "猫", pinyin: "mao1", glosses: ["cat"]),
            DictionaryEntry(simplified: "因为", pinyin: "yin1 wei4", glosses: ["because"]),
        ], isFullDictionary: false)
        return store
    }

    private func makePipeline(
        showSingleCharWords: Bool = false,
        now: @escaping () -> Date = Date.init
    ) -> (LookupPipeline, DictionaryStore) {
        let store = makeStore()
        let pipeline = LookupPipeline(store: store, now: now)
        pipeline.config.showSingleCharWords = showSingleCharWords
        return (pipeline, store)
    }

    func testTypingProducesLookup() {
        let (pipeline, _) = makePipeline()
        var results: [LookupResult] = []
        pipeline.onLookup = { results.append($0) }

        pipeline.ingest(text: "")
        pipeline.ingest(text: "咖啡")

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].word, "咖啡")
        XCTAssertEqual(results[0].english, "coffee")
        XCTAssertEqual(results[0].rangeUTF16, NSRange(location: 0, length: 2))
    }

    func testFirstSnapshotOnlyRecords() {
        let (pipeline, _) = makePipeline()
        var results: [LookupResult] = []
        pipeline.onLookup = { results.append($0) }

        pipeline.ingest(text: "咖啡天气")
        XCTAssertTrue(results.isEmpty)
    }

    func testResetSnapshotPreventsCrossContextFalsePositive() {
        let (pipeline, _) = makePipeline()
        var results: [LookupResult] = []
        pipeline.onLookup = { results.append($0) }

        pipeline.ingest(text: "咖啡")
        pipeline.resetSnapshot()
        pipeline.ingest(text: "天气") // reset 后首帧只记录
        XCTAssertTrue(results.isEmpty)

        pipeline.ingest(text: "天气不错") // "不错" 未命中 → 无结果
        XCTAssertTrue(results.isEmpty)
    }

    func testStopWordNotShown() {
        let (pipeline, _) = makePipeline()
        var results: [LookupResult] = []
        pipeline.onLookup = { results.append($0) }

        pipeline.ingest(text: "")
        pipeline.ingest(text: "因为") // 词典命中但停用 → 不展示
        XCTAssertTrue(results.isEmpty)
    }

    func testSingleCharToggleOffByDefault() {
        let (pipeline, _) = makePipeline()
        var results: [LookupResult] = []
        pipeline.onLookup = { results.append($0) }

        pipeline.ingest(text: "")
        pipeline.ingest(text: "猫")
        XCTAssertTrue(results.isEmpty)
    }

    func testSingleCharToggleOn() {
        let (pipeline, _) = makePipeline(showSingleCharWords: true)
        var results: [LookupResult] = []
        pipeline.onLookup = { results.append($0) }

        pipeline.ingest(text: "")
        pipeline.ingest(text: "猫")
        XCTAssertEqual(results.first?.word, "猫")
    }

    func testDedupWithinInterval() {
        var fakeNow = Date(timeIntervalSince1970: 1_000)
        let (pipeline, _) = makePipeline(now: { fakeNow })
        var results: [LookupResult] = []
        pipeline.onLookup = { results.append($0) }

        pipeline.ingest(text: "")
        pipeline.ingest(text: "咖啡")
        XCTAssertEqual(results.count, 1)

        // 冷却期内重复 → 不再展示
        pipeline.ingest(text: "咖啡咖啡")
        XCTAssertEqual(results.count, 1)

        // 冷却期外 → 再次展示
        fakeNow = fakeNow.addingTimeInterval(5)
        pipeline.ingest(text: "咖啡咖啡咖啡")
        XCTAssertEqual(results.count, 2)
    }

    func testPasteLikeLongInsertRejected() {
        let (pipeline, _) = makePipeline()
        var results: [LookupResult] = []
        pipeline.onLookup = { results.append($0) }

        pipeline.ingest(text: "")
        pipeline.ingest(text: "今天天气真好我想去公园散步还想去咖啡店买咖啡") // 22 字 > 16 → 拒绝
        XCTAssertTrue(results.isEmpty)
    }

    func testMixedNonCJKRejected() {
        let (pipeline, _) = makePipeline()
        var results: [LookupResult] = []
        pipeline.onLookup = { results.append($0) }

        pipeline.ingest(text: "")
        pipeline.ingest(text: "咖啡123")
        XCTAssertTrue(results.isEmpty)
    }

    func testSentencePicksLastWord() {
        let (pipeline, _) = makePipeline()
        var results: [LookupResult] = []
        pipeline.onLookup = { results.append($0) }

        pipeline.ingest(text: "")
        pipeline.ingest(text: "我们去喝咖啡") // 整句上屏："我们"停用、其余未命中、末尾"咖啡"命中
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.word, "咖啡")
        XCTAssertEqual(results.first?.rangeUTF16, NSRange(location: 4, length: 2))
    }

    func testRangeReflectsInsertPositionInMiddle() {
        let (pipeline, _) = makePipeline()
        var results: [LookupResult] = []
        pipeline.onLookup = { results.append($0) }

        pipeline.ingest(text: "我吃饭")
        pipeline.ingest(text: "我吃咖啡饭") // 中间插入"咖啡"
        XCTAssertEqual(results.first?.rangeUTF16, NSRange(location: 2, length: 2))
    }
}
