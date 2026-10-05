import AppKit
import Darwin

/// 单实例守卫（flock 文件锁，兼容 LaunchServices 启动与终端 nohup 启动的实例）。
///
/// - 首个实例：获取锁并保持（进程退出自动释放）
/// - 后续实例：检测到锁被占 → 发送分布式通知请求已有实例显示设置窗口 → 自行退出
enum InstanceGuard {

    /// 「请求显示设置窗口」的分布式通知名
    static let showSettingsNotification = Notification.Name("app.wordpeek.mac.showSettings")

    /// 锁文件描述符（持有到进程结束）
    private static var lockFileDescriptor: Int32 = -1

    /// 尝试成为唯一实例；返回 false 表示已有实例在运行
    static func acquire() -> Bool {
        let path = (NSTemporaryDirectory() as NSString)
            .appendingPathComponent("app.wordpeek.mac.instance.lock")
        let fd = open(path, O_CREAT | O_RDWR, 0o644)
        guard fd >= 0 else {
            // 锁文件不可用时放行，不阻塞启动
            return true
        }
        if flock(fd, LOCK_EX | LOCK_NB) == 0 {
            lockFileDescriptor = fd
            return true
        }
        close(fd)
        return false
    }

    /// 请求已在运行的实例显示设置窗口
    static func notifyExistingInstance() {
        DistributedNotificationCenter.default().postNotificationName(
            showSettingsNotification,
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }
}
