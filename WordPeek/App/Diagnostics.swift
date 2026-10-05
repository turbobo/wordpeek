import Foundation

/// 诊断日志开关：满足任一条件即开启
/// - 启动参数 `--self-test` / `--debug-log`
/// - 环境变量 `WP_DEBUG=1`
/// - 哨兵文件 `/tmp/wordpeek-debug.on` 存在
let wpDebugEnabled: Bool = {
    let args = CommandLine.arguments
    if args.contains("--self-test") || args.contains("--debug-log") { return true }
    if ProcessInfo.processInfo.environment["WP_DEBUG"] == "1" { return true }
    return FileManager.default.fileExists(atPath: "/tmp/wordpeek-debug.on")
}()

/// 诊断日志落盘路径：仅在 `--debug-log` 下写文件。
/// 用于经 LaunchServices（`open`）启动、拿不到 stderr 时抓全链路日志。
private let wpDebugFilePath: String? =
    CommandLine.arguments.contains("--debug-log") ? "/tmp/wordpeek-debug.log" : nil

private let wpDebugTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter
}()

/// 进程启动时清空上一次诊断文件，避免读到旧内容
func wpDebugLogReset() {
    guard let path = wpDebugFilePath else { return }
    try? "".write(toFile: path, atomically: true, encoding: .utf8)
}

/// 诊断日志：输出到 NSLog，并在 `--debug-log` 下追加到 /tmp/wordpeek-debug.log
func wpLog(_ message: String) {
    guard wpDebugEnabled else { return }
    NSLog("[WP] %@", message)
    guard let path = wpDebugFilePath else { return }
    let line = "\(wpDebugTimeFormatter.string(from: Date())) \(message)\n"
    guard let data = line.data(using: .utf8) else { return }
    if let handle = FileHandle(forWritingAtPath: path) {
        handle.seekToEndOfFile()
        handle.write(data)
        handle.closeFile()
    } else {
        try? data.write(to: URL(fileURLWithPath: path))
    }
}
