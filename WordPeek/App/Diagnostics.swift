import Foundation

/// 诊断日志：仅当以 `--self-test` 启动或设置了 `WP_DEBUG=1` 时输出到 stderr。
///
/// 启动方式示例：
/// `WP_DEBUG=1 nohup ./WordPeek > /tmp/wordpeek-run.log 2>&1 &`
func wpLog(_ message: String) {
    let enabled = CommandLine.arguments.contains("--self-test")
        || ProcessInfo.processInfo.environment["WP_DEBUG"] == "1"
    guard enabled else { return }
    NSLog("[WP] %@", message)
}
