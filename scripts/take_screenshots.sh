#!/bin/bash

set -e

SIMULATOR_UDID="B71080B0-74D9-4A85-A784-4A270A5F046A"
SCHEME="ClimbDiary"
PROJECT="/Users/makotokawashita/Desktop/ClimbDiary/ClimbDiary.xcodeproj"
BUNDLE_ID="jp.makoto.ClimbDiary.dev"
SCREENSHOTS_DIR="$(cd "$(dirname "$0")/.." && pwd)/docs/screenshots"

mkdir -p "$SCREENSHOTS_DIR"

echo "📱 Simulatorを起動中..."
xcrun simctl boot "$SIMULATOR_UDID" 2>/dev/null || true
open -a Simulator
sleep 2

echo "🔨 ビルド中..."
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
  -configuration Debug \
  build 2>&1 | grep -E "error:|BUILD"

echo "🚀 アプリを起動中..."
DERIVED_DATA=$(xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
  -configuration Debug \
  -showBuildSettings 2>/dev/null | grep "BUILT_PRODUCTS_DIR" | head -1 | awk '{print $3}')

APP_PATH="$DERIVED_DATA/ClimbLog.app"

if [ ! -d "$APP_PATH" ]; then
  echo "❌ アプリが見つかりません: $APP_PATH"
  exit 1
fi

echo "📦 アプリパス: $APP_PATH"
xcrun simctl install "$SIMULATOR_UDID" "$APP_PATH"
xcrun simctl launch "$SIMULATOR_UDID" "$BUNDLE_ID"

echo "⏳ 起動待ち (3秒)..."
sleep 3

echo "📸 スクリーンショット取得中..."
xcrun simctl io "$SIMULATOR_UDID" screenshot "$SCREENSHOTS_DIR/screen_01.png"
echo "✅ screen_01.png 保存完了: $SCREENSHOTS_DIR/screen_01.png"

echo ""
echo "🎉 完了！追加画面は以下で取得できます："
echo "  xcrun simctl io $SIMULATOR_UDID screenshot $SCREENSHOTS_DIR/screen_02.png"
