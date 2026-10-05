import Foundation

/// CC-CEDICT 词典下载、解压与安装。
///
/// 数据源（均为公网）：
/// 1. GitHub 镜像（未压缩 txt，9.8MB）
/// 2. MDBG 官方（gzip 压缩，约 4MB）
///
/// 安装位置：`~/Library/Application Support/WordPeek/cedict.txt`
public final class DictionaryDownloader {

    /// 词典数据源（按顺序尝试）
    public enum Source: CaseIterable {
        case githubMirror
        case mdbgOfficial

        var url: URL {
            switch self {
            case .githubMirror:
                return URL(string: "https://raw.githubusercontent.com/qundao/backup-cc-cedict/main/cedict.txt")!
            case .mdbgOfficial:
                return URL(string: "https://www.mdbg.net/chinese/export/cedict/cedict_1_0_ts_utf-8_mdbg.txt.gz")!
            }
        }

        var displayName: String {
            switch self {
            case .githubMirror: return "GitHub 镜像"
            case .mdbgOfficial: return "MDBG 官方源"
            }
        }
    }

    public enum DownloadError: Error, LocalizedError {
        case allSourcesFailed([String])
        case dataCorrupted(String)
        case emptyDictionary

        public var errorDescription: String? {
            switch self {
            case .allSourcesFailed(let reasons):
                return "所有下载源均失败：" + reasons.joined(separator: "；")
            case .dataCorrupted(let detail):
                return "词典数据无效：\(detail)"
            case .emptyDictionary:
                return "词典解析结果为空"
            }
        }
    }

    public init() {}

    // MARK: - 路径

    /// 应用支持目录
    public static func supportDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("WordPeek", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// 已安装词典文件路径
    public static func installedDictionaryURL() -> URL {
        supportDirectory().appendingPathComponent("cedict.txt")
    }

    // MARK: - 下载安装

    /// 依次尝试各数据源，下载 → 解压（如需）→ 解析 → 写入本地。
    /// - 回调均在主线程触发。
    public func downloadAndInstall(
        onStatus: @escaping (String) -> Void,
        completion: @escaping (Result<[DictionaryEntry], Error>) -> Void
    ) {
        let sources = Source.allCases
        attempt(sources: sources, index: 0, failures: [], onStatus: onStatus, completion: completion)
    }

    private func attempt(
        sources: [Source],
        index: Int,
        failures: [String],
        onStatus: @escaping (String) -> Void,
        completion: @escaping (Result<[DictionaryEntry], Error>) -> Void
    ) {
        guard index < sources.count else {
            DispatchQueue.main.async { completion(.failure(DownloadError.allSourcesFailed(failures))) }
            return
        }
        let source = sources[index]
        DispatchQueue.main.async { onStatus("正在下载词典（\(source.displayName)，\(index + 1)/\(sources.count)）…") }

        var request = URLRequest(url: source.url)
        request.timeoutInterval = 60
        request.setValue("WordPeek/1.0 (macOS)", forHTTPHeaderField: "User-Agent")

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }
            let failureReason: String?
            if let error {
                failureReason = "\(source.displayName)：\(error.localizedDescription)"
            } else if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                failureReason = "\(source.displayName)：HTTP \(http.statusCode)"
            } else if let data, !data.isEmpty {
                failureReason = nil
                self.processAndInstall(data: data, onStatus: onStatus, completion: completion)
            } else {
                failureReason = "\(source.displayName)：数据为空"
            }
            if let failureReason {
                self.attempt(sources: sources, index: index + 1, failures: failures + [failureReason], onStatus: onStatus, completion: completion)
            }
        }
        task.resume()
    }

    private func processAndInstall(
        data: Data,
        onStatus: @escaping (String) -> Void,
        completion: @escaping (Result<[DictionaryEntry], Error>) -> Void
    ) {
        DispatchQueue.main.async { onStatus("正在解析词典…") }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let raw = GzipDecompressor.isGzip(data) ? try GzipDecompressor.decompress(data) : data
                guard let text = String(data: raw, encoding: .utf8) else {
                    throw DownloadError.dataCorrupted("非 UTF-8 编码")
                }
                let entries = CedictParser.parseAll(text: text)
                guard !entries.isEmpty else { throw DownloadError.emptyDictionary }
                try text.write(to: Self.installedDictionaryURL(), atomically: true, encoding: .utf8)
                DispatchQueue.main.async { completion(.success(entries)) }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(DownloadError.dataCorrupted(error.localizedDescription)))
                }
            }
        }
    }

    // MARK: - 本地导入

    /// 从本地文件导入词典（CC-CEDICT 文本格式，支持 .gz）
    /// - 回调均在主线程触发。
    public func install(
        fromFile url: URL,
        onStatus: @escaping (String) -> Void,
        completion: @escaping (Result<[DictionaryEntry], Error>) -> Void
    ) {
        DispatchQueue.main.async { onStatus("正在读取文件…") }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let raw = try Data(contentsOf: url)
                let decompressed = GzipDecompressor.isGzip(raw) ? try GzipDecompressor.decompress(raw) : raw
                guard let text = String(data: decompressed, encoding: .utf8) else {
                    throw DownloadError.dataCorrupted("非 UTF-8 编码")
                }
                DispatchQueue.main.async { onStatus("正在解析词典…") }
                let entries = CedictParser.parseAll(text: text)
                guard !entries.isEmpty else { throw DownloadError.emptyDictionary }
                try text.write(to: Self.installedDictionaryURL(), atomically: true, encoding: .utf8)
                DispatchQueue.main.async { completion(.success(entries)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    // MARK: - 启动加载

    /// 加载已安装的词典（若无则返回 nil），在后台队列执行解析
    public func loadInstalledDictionary(
        completion: @escaping ([DictionaryEntry]?) -> Void
    ) {
        let url = Self.installedDictionaryURL()
        DispatchQueue.global(qos: .userInitiated).async {
            guard let text = try? String(contentsOf: url, encoding: .utf8) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let entries = CedictParser.parseAll(text: text)
            DispatchQueue.main.async { completion(entries.isEmpty ? nil : entries) }
        }
    }
}
