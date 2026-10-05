#!/usr/bin/env bash
# 构建 WordPeek.app（Release + ad-hoc 签名）并输出到 dist/
set -euo pipefail
cd "$(dirname "$0")/.."

echo "▶ xcodegen generate"
xcodegen generate

echo "▶ xcodebuild (Release)"
xcodebuild -project WordPeek.xcodeproj \
  -scheme WordPeek \
  -configuration Release \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=YES \
  build

APP_PATH="build/Build/Products/Release/WordPeek.app"
if [ ! -d "$APP_PATH" ]; then
  echo "✗ 未找到构建产物: $APP_PATH"
  exit 1
fi

mkdir -p dist
rm -rf dist/WordPeek.app
cp -R "$APP_PATH" dist/WordPeek.app
codesign --force --deep --sign - dist/WordPeek.app

echo "✅ 构建完成: dist/WordPeek.app"
echo "   运行:    open dist/WordPeek.app"
echo "   诊断:    ./scripts/doctor.sh   （实时输出打字→查词→浮窗全链路日志）"
echo
echo "⚠️  ad-hoc 重签名会使「辅助功能」授权失效（TCC 绑定签名指纹）："
echo "   本次构建后需在 系统设置 → 隐私与安全性 → 辅助功能 中移除「瞄词」再重新勾选，"
echo "   否则表现为：打字后不弹翻译。可执行以下命令清掉旧记录后重开授权："
echo "     tccutil reset Accessibility app.wordpeek.mac"
