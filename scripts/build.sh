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
