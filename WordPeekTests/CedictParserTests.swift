import XCTest
@testable import WordPeekCore

final class CedictParserTests: XCTestCase {

    func testStandardLine() {
        let entry = CedictParser.parse(line: "打工人 打工人 [da3 gong1 ren2] /worker/office worker/")
        XCTAssertEqual(entry?.simplified, "打工人")
        XCTAssertEqual(entry?.pinyin, "da3 gong1 ren2")
        XCTAssertEqual(entry?.glosses, ["worker", "office worker"])
    }

    func testTraditionalDifferentFromSimplified() {
        let entry = CedictParser.parse(line: "计算机 計算機 [ji4 suan4 ji1] /computer/CL:臺|台[tai2]/")
        XCTAssertEqual(entry?.simplified, "计算机")
        XCTAssertEqual(entry?.glosses.count, 2)
    }

    func testCommentAndEmptyLinesReturnNil() {
        XCTAssertNil(CedictParser.parse(line: "# CC-CEDICT"))
        XCTAssertNil(CedictParser.parse(line: "#! 一行注释"))
        XCTAssertNil(CedictParser.parse(line: ""))
        XCTAssertNil(CedictParser.parse(line: "   "))
    }

    func testMalformedLinesReturnNil() {
        XCTAssertNil(CedictParser.parse(line: "没有括号的内容"))
        XCTAssertNil(CedictParser.parse(line: "只有前半 [pin1 yin1"))
        XCTAssertNil(CedictParser.parse(line: "[pin1 yin1] /gloss/"))
    }

    func testParseAllSkipsComments() {
        let text = """
        # CC-CEDICT 注释行
        #! 另一行注释
        咖啡 咖啡 [ka1 fei1] /coffee/

        天气 天氣 [tian1 qi4] /weather/
        """
        let entries = CedictParser.parseAll(text: text)
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].simplified, "咖啡")
        XCTAssertEqual(entries[1].simplified, "天气")
    }

    func testDisplayEnglishLimitsToThreeGlosses() {
        let entry = DictionaryEntry(simplified: "x", pinyin: "", glosses: ["a", "b", "c", "d"])
        XCTAssertEqual(entry.displayEnglish, "a · b · c")
    }
}
