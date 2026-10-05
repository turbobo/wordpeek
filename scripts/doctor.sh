#!/usr/bin/env bash
# 以诊断模式启动 WordPeek，实时输出「AX 轮询 → 差分 → 切词 → 查词 → 浮窗」全链路日志。
# 用途：定位「打字后不弹翻译」到底断在哪一层。
set -euo pipefail
cd "$(dirname "$0")/.."

APP="$PWD/dist/WordPeek.app"
LOG="/tmp/wordpeek-debug.log"

[[ -d "$APP" ]] || { echo "✗ 未找到 $APP，请先执行 ./scripts/build.sh"; exit 1; }

echo "▶ 重启 WordPeek（--debug-log；日志文件由 app 启动时自行清空）"
pkill -f 'WordPeek.app/Contents/MacOS/WordPeek' 2>/dev/null || true
sleep 1
open "$APP" --args --debug-log
sleep 2

echo "▶ 日志：$LOG"
echo "▶ 现在到任意应用（备忘录 / 微信 / 浏览器输入框）打几个中文，例如：咖啡、天气、打工人"
echo "▶ 正常链路应依次出现："
echo "     poll 监听中 pid=… role=AXTextArea len=… → ingest external → present word=… → overlay show"
echo "▶ 若出现「AX 未授权」：系统设置 → 隐私与安全性 → 辅助功能 → 移除「瞄词」后重新勾选"
echo "     （可执行 tccutil reset Accessibility app.wordpeek.mac 清掉旧记录）"
echo "----------------------------------------（Ctrl+C 停止跟踪）"
tail -f "$LOG"
