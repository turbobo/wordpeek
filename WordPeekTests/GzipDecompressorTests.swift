import XCTest
@testable import WordPeekCore

final class GzipDecompressorTests: XCTestCase {

    /// 样例数据生成方式（本地）：
    /// `printf '咖啡 coffee 天气 weather 测试' | gzip | base64`
    private let sampleBase64 = "H4sIAIZDw2oAAwEjANz/5ZKW5ZWhIGNvZmZlZSDlpKnmsJQgd2VhdGhlciDmtYvor5U31KIMIwAAAA=="
    private let expected = "咖啡 coffee 天气 weather 测试"

    func testIsGzip() throws {
        let data = try XCTUnwrap(Data(base64Encoded: sampleBase64))
        XCTAssertTrue(GzipDecompressor.isGzip(data))
    }

    func testDecompressRoundTrip() throws {
        let data = try XCTUnwrap(Data(base64Encoded: sampleBase64))
        let output = try GzipDecompressor.decompress(data)
        XCTAssertEqual(String(data: output, encoding: .utf8), expected)
    }

    func testNotGzipDataThrows() {
        let data = Data("hello".utf8)
        XCTAssertFalse(GzipDecompressor.isGzip(data))
        XCTAssertThrowsError(try GzipDecompressor.decompress(data))
    }
}
