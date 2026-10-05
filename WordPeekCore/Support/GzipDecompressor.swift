import Compression
import Foundation

/// 最小 gzip 解压实现（用于 MDBG 官方 CC-CEDICT 的 .gz 源）。
///
/// 结构：10 字节固定头 + 可选字段（FEXTRA / FNAME / FCOMMENT / FHCRC）
/// + raw deflate 数据 + 8 字节尾部（CRC32 + ISIZE）。
/// deflate 部分交给 `compression_decode_buffer`（COMPRESSION_ZLIB 即 raw DEFLATE）。
public enum GzipDecompressor {

    public enum GzipError: Error, LocalizedError {
        case notGzip
        case malformedHeader
        case missingSize
        case decompressFailed

        public var errorDescription: String? {
            switch self {
            case .notGzip: return "不是有效的 gzip 数据"
            case .malformedHeader: return "gzip 头解析失败"
            case .missingSize: return "gzip 尾部缺少解压长度信息"
            case .decompressFailed: return "gzip 解压失败"
            }
        }
    }

    public static func isGzip(_ data: Data) -> Bool {
        data.count > 2 && data[data.startIndex] == 0x1F && data[data.startIndex + 1] == 0x8B
    }

    public static func decompress(_ data: Data) throws -> Data {
        guard isGzip(data) else { throw GzipError.notGzip }
        let bytes = [UInt8](data)
        guard bytes.count > 18 else { throw GzipError.malformedHeader }

        // 解析头部
        let flags = bytes[3]
        var offset = 10
        if flags & 0x04 != 0 { // FEXTRA
            guard offset + 2 <= bytes.count else { throw GzipError.malformedHeader }
            let xlen = Int(bytes[offset]) | (Int(bytes[offset + 1]) << 8)
            offset += 2 + xlen
        }
        if flags & 0x08 != 0 { // FNAME（NUL 结尾）
            while offset < bytes.count && bytes[offset] != 0 { offset += 1 }
            offset += 1
        }
        if flags & 0x10 != 0 { // FCOMMENT（NUL 结尾）
            while offset < bytes.count && bytes[offset] != 0 { offset += 1 }
            offset += 1
        }
        if flags & 0x02 != 0 { // FHCRC
            offset += 2
        }
        guard offset + 8 <= bytes.count else { throw GzipError.malformedHeader }

        // 尾部最后 4 字节为 ISIZE（解压后长度，little endian）
        let sizeStart = bytes.count - 4
        let isize = UInt32(bytes[sizeStart])
            | (UInt32(bytes[sizeStart + 1]) << 8)
            | (UInt32(bytes[sizeStart + 2]) << 16)
            | (UInt32(bytes[sizeStart + 3]) << 24)
        guard isize > 0 else { throw GzipError.missingSize }

        let compressed = Array(bytes[offset..<(bytes.count - 8)])
        var output = Data(count: Int(isize))
        let written = output.withUnsafeMutableBytes { destination -> Int in
            guard let destinationBase = destination.bindMemory(to: UInt8.self).baseAddress else { return 0 }
            return compressed.withUnsafeBufferPointer { source -> Int in
                guard let sourceBase = source.baseAddress else { return 0 }
                return compression_decode_buffer(
                    destinationBase, Int(isize),
                    sourceBase, compressed.count,
                    nil, COMPRESSION_ZLIB
                )
            }
        }
        guard written == Int(isize) else { throw GzipError.decompressFailed }
        return output
    }
}
