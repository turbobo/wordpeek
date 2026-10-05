# 瞄词 WordPeek

> 打字时，在你刚输入的词旁瞄一眼它的英文。

macOS 菜单栏小工具：在任何应用里打中文，词上屏的瞬间，就在光标旁边弹出一个小浮窗，
显示「打工人 → worker · office worker」这样的中英对照。为「顺便学英语」设计——不打断输入，看一眼就走。

## 特性

- **全局生效**：任何应用、任何系统输入法场景，打中文即触发，无需切换输入法
- **纯本地**：差分与查词都在本机内存完成，不联网、不上传（唯一联网行为是下载词典）
- **离线词典**：内置演示词表开箱即用；一键下载 CC-CEDICT 完整词典（约 12 万词条，CC BY-SA 4.0）
- **不打扰**：非激活浮窗，不抢焦点、不接收鼠标；同词 3 秒冷却；高频功能词与单字默认不弹
- **可控**：菜单栏一键暂停/启用；浮窗时长可调；可选展示单字词
- **隐私安全**：自动跳过密码框（AXSecureTextField）；粘贴长文本/混合内容不触发

## 快速开始

```bash
# 构建（需 Xcode 与 xcodegen）
./scripts/build.sh

# 运行
open dist/WordPeek.app
```

首次启动：

1. 弹出引导窗口 → 点「打开系统设置」授权**辅助功能**权限
   （系统设置 → 隐私与安全性 → 辅助功能 → 勾选「瞄词」）
2. 在「试一试」输入框直接打字体验完整效果（此步无需任何权限）
3. 点「下载完整词典」扩展词库（约 10MB，离线可用）

## 开发

```bash
./scripts/test.sh    # 单元测试（36 个用例，headless 直跑）
```

- `WordPeekCore/`：纯逻辑 framework（文本 diff / 词典 / 切词 / 查词管线），不依赖 AppKit，可单测
- `WordPeek/`：App 层（Accessibility 监听 / 浮窗 / 设置窗口 / 菜单栏）
- 工程由 `project.yml`（xcodegen）声明式生成，`WordPeek.xcodeproj` 为构建产物（已 gitignore）

## 权限与原理

- 监听原理：Accessibility API 以 0.25s 轮询系统焦点输入框的文本快照，在本地做字符级差分，
  提取「刚上屏的词」→ 查词典 → 浮窗展示
- 为什么需要「辅助功能」权限：这是 macOS 读取其他应用输入内容的唯一合法通道
- 词典数据：CC-CEDICT（CC BY-SA 4.0），https://cc-cedict.org

## 已知限制

- 只能拿到「上屏后」的词；想在输入法**候选框内**直接看英文，需要输入法自身可扩展（如 Rime 生态）
- ad-hoc 签名：每次重新构建后，可能需在「系统设置 → 隐私与安全性 → 辅助功能」中
  移除旧记录后重新勾选
- 极少数禁用 Accessibility 的应用（如部分密码管理器内部）不会被监听（符合预期）

## 目录结构

```
wordpeek/
├── project.yml              # xcodegen 工程描述
├── WordPeekCore/            # 纯逻辑层（可单测）
│   ├── Pipeline/            #   diff / 切词 / 停用词 / 查词管线
│   ├── Dictionary/          #   解析 / 内存索引 / 内置词表 / 下载器
│   └── Support/             #   gzip 解压 / CJK 工具
├── WordPeek/                # App 层
│   ├── App/                 #   入口 / 组装中枢 / 设置
│   ├── AX/                  #   焦点监听 / 坐标转换
│   └── UI/                  #   浮窗 / 菜单栏 / 设置窗口
├── WordPeekTests/           # 单元测试（36 例）
└── scripts/                 # build.sh / test.sh
```
