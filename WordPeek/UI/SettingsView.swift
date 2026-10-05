import SwiftUI
import WordPeekCore

/// 设置窗口视图：权限引导 / 试打区 / 词典管理 / 偏好
struct SettingsView: View {

    @ObservedObject var environment: AppEnvironment
    @ObservedObject var settings: AppSettings
    @State private var testText = ""
    @FocusState private var testFieldFocused: Bool

    private let brandColor = Color(red: 1.0, green: 0.42, blue: 0.21)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                headerSection
                permissionSection
                testSection
                dictionarySection
                behaviorSection
                footerSection
            }
            .padding(20)
        }
        .frame(width: 480, height: 660)
        .onAppear {
            environment.primeTestField(testText)
        }
    }

    // MARK: - 区块

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(brandColor)
                Text("瞄词 WordPeek")
                    .font(.system(size: 20, weight: .bold))
                Text("v1.0")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Text("打字时，在你刚输入的词旁瞄一眼它的英文。数据完全在本机处理。")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }

    private var permissionSection: some View {
        card(title: "1 · 辅助功能权限", systemImage: "lock.shield") {
            HStack(spacing: 8) {
                Circle()
                    .fill(environment.permissionGranted ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(environment.permissionGranted
                     ? "已授权，监听已就绪"
                     : "未授权：需要辅助功能权限来读取输入内容")
                    .font(.system(size: 12))
                Spacer()
            }
            if !environment.permissionGranted {
                HStack(spacing: 8) {
                    Button("打开系统设置") {
                        environment.openAccessibilityPreferences()
                    }
                    Button("重新检测") {
                        environment.refreshPermission()
                    }
                }
                .controlSize(.small)
                Text("路径：系统设置 → 隐私与安全性 → 辅助功能 → 勾选「瞄词」。授权后无需重启，自动生效。")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            // 诊断：把轮询器的真实结论暴露出来，定位「打字不弹」卡在哪一步
            HStack(alignment: .top, spacing: 6) {
                Text("诊断")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(environment.monitorVerdict)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
                Spacer()
            }
        }
    }

    private var testSection: some View {
        card(title: "2 · 试一试（无需权限即可体验）", systemImage: "keyboard") {
            TextField("在这里打字试试，例如：咖啡、天气、打工人", text: $testText)
                .textFieldStyle(.roundedBorder)
                .focused($testFieldFocused)
                .onChange(of: testText) { _, newValue in
                    environment.ingestTestText(newValue)
                }
                .onChange(of: testFieldFocused) { _, focused in
                    // 重新聚焦时刷新基线，保证第一个词的输入即可展示
                    if focused {
                        environment.primeTestField(testText)
                    }
                }
            Text("词上屏的瞬间，屏幕对应位置会弹出英文浮窗（试打区的浮窗出现在本窗口下方）。")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }

    private var dictionarySection: some View {
        card(title: "3 · 词典", systemImage: "text.book.closed") {
            Text(environment.dictionaryInfo)
                .font(.system(size: 12))
            if let busyMessage = environment.busyMessage {
                Text(busyMessage)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 8) {
                Button("下载完整词典（约 10MB）") {
                    environment.downloadDictionary()
                }
                .disabled(environment.isBusy)
                Button("导入本地词典…") {
                    environment.importDictionary()
                }
                .disabled(environment.isBusy)
                if environment.isBusy {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .controlSize(.small)
            Text("数据源：CC-CEDICT（CC BY-SA 4.0，社区维护的汉英词典，约 12 万词条）。下载后离线可用。")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }

    private var behaviorSection: some View {
        card(title: "4 · 偏好", systemImage: "slider.horizontal.3") {
            Toggle("启用监听（在任何应用打中文时弹英文）", isOn: $settings.isMonitoringEnabled)
                .font(.system(size: 12))
            Toggle("显示单字词的英文（如「猫 → cat」）", isOn: $settings.showSingleCharWords)
                .font(.system(size: 12))
            HStack {
                Text("浮窗停留时长")
                    .font(.system(size: 12))
                Slider(value: $settings.overlayDuration, in: 1.0...5.0, step: 0.5)
                Text(String(format: "%.1f 秒", settings.overlayDuration))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(width: 52, alignment: .trailing)
            }
        }
    }

    private var footerSection: some View {
        Text("隐私说明：输入内容仅在本机内存中做差分与查词，不联网、不上传。只有首次下载词典或导入词典时需要网络。")
            .font(.system(size: 11))
            .foregroundColor(.secondary)
    }

    // MARK: - 卡片容器

    private func card<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 13, weight: .semibold))
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}
