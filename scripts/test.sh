#!/usr/bin/env bash
# 构建并运行 WordPeekCore 单元测试（本地 xctest 路径）
#
# 说明：xcodebuild test 在部分 Xcode 版本下无法加载无宿主（headless）的
# macOS 测试 bundle，这里先用 build-for-testing 完成构建，再直接用
# xctest 运行，得到等价的测试结果。
set -euo pipefail
cd "$(dirname "$0")/.."

echo "▶ xcodegen generate"
xcodegen generate

echo "▶ xcodebuild build-for-testing (Debug)"
xcodebuild -project WordPeek.xcodeproj \
  -scheme WordPeekCore \
  -configuration Debug \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY="-" \
  build-for-testing 2>&1 | grep -E "error:|warning:.*deprecated|BUILD" | tail -10

BUNDLE="build/Build/Products/Debug/WordPeekTests.xctest"
if [ ! -d "$BUNDLE" ]; then
  echo "✗ 未找到测试 bundle: $BUNDLE"
  exit 1
fi

echo "▶ xctest"
XCTEST_BIN="$(xcrun --find xctest)"
"$XCTEST_BIN" "$BUNDLE"
