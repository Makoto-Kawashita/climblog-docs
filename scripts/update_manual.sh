#!/bin/bash

set -e

SIMULATOR_UDID="B71080B0-74D9-4A85-A784-4A270A5F046A"
SCHEME="ClimbDiary"
PROJECT="/Users/makotokawashita/Desktop/ClimbDiary/ClimbDiary.xcodeproj"
BUNDLE_ID="jp.makoto.ClimbDiary.dev"
DOCS_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCREENSHOTS_DIR="$DOCS_ROOT/docs/screenshots"

mkdir -p "$SCREENSHOTS_DIR"

echo "======================================"
echo "📱 Step 1: Simulator起動 & ビルド"
echo "======================================"
xcrun simctl boot "$SIMULATOR_UDID" 2>/dev/null || true
open -a Simulator
sleep 2

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
  -configuration Debug \
  build 2>&1 | grep -E "error:|BUILD"

DERIVED_DATA=$(xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
  -configuration Debug \
  -showBuildSettings 2>/dev/null | grep "BUILT_PRODUCTS_DIR" | head -1 | awk '{print $3}')

APP_PATH="$DERIVED_DATA/ClimbLog.app"
xcrun simctl install "$SIMULATOR_UDID" "$APP_PATH"
xcrun simctl launch "$SIMULATOR_UDID" "$BUNDLE_ID"

echo ""
echo "======================================"
echo "📸 Step 2: スクリーンショット取得"
echo "======================================"
echo "アプリが起動しました。各画面に移動してEnterを押してください。"

SCREEN_NUM=1
while true; do
  echo -n "📸 画面${SCREEN_NUM} 準備ができたらEnter（終了はq）: "
  read INPUT
  if [ "$INPUT" = "q" ]; then
    break
  fi
  FILENAME="screen_$(printf '%02d' $SCREEN_NUM)"
  xcrun simctl io "$SIMULATOR_UDID" screenshot "$SCREENSHOTS_DIR/${FILENAME}.png"
  echo "✅ ${FILENAME}.png 保存完了"
  SCREEN_NUM=$((SCREEN_NUM + 1))
done

echo ""
echo "======================================"
echo "🤖 Step 3: Claude Vision でマニュアル生成"
echo "======================================"
python3 "$DOCS_ROOT/scripts/generate_manual.py"

echo ""
echo "======================================"
echo "🚀 Step 4: GitHubにpush → 自動公開"
echo "======================================"
cd "$DOCS_ROOT"
git add .
git commit -m "Update manual: $(date '+%Y-%m-%d %H:%M')"
git push origin main

echo ""
echo "🎉 完了！約2分後にサイトが更新されます："
echo "   https://makoto-kawashita.github.io/climblog-docs/"
