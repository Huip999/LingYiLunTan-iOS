#!/bin/bash
# ============================================================
#  凌意论坛 IPA 一键打包脚本
#  用法：在 Mac 上 cd 到本目录，然后 bash build-ipa.sh
#  产出：build/LingYiLunTan.ipa
# ============================================================
set -e

PROJECT="LingYiLunTan.xcodeproj"
SCHEME="LingYiLunTan"
CONFIG="Release"
BUILD_DIR="build"
IPA_NAME="LingYiLunTan.ipa"

echo "==> 清理旧产物..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> 编译 (archive)..."
# 注意：打 IPA 需要先 archive。
#   - 如果你付了 Apple 开发者账号，把下面 TEAM_ID 改成你的 Team ID（10位字母数字），
#     并取消 CODE_SIGN 相关注释。
#   - 如果用免费 Apple ID sideload，先不签名出 archive，再用 Sideloadly/AltStore 注入签名。
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -archivePath "$BUILD_DIR/LingYiLunTan.xcarchive" \
  -destination "generic/platform=iOS" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  AD_HOC_CODE_SIGNING_ALLOWED=NO

echo "==> 从 archive 里取出 .app..."
APP_PATH=$(find "$BUILD_DIR/LingYiLunTan.xcarchive" -name "LingYiLunTan.app" -type d | head -1)
if [ -z "$APP_PATH" ]; then
  echo "❌ 没找到 .app，编译可能失败了"
  exit 1
fi
echo "   找到: $APP_PATH"

echo "==> 打包成 .ipa..."
PAYLOAD="$BUILD_DIR/Payload"
mkdir -p "$PAYLOAD"
cp -R "$APP_PATH" "$PAYLOAD/"
cd "$BUILD_DIR"
zip -qry "$IPA_NAME" Payload
cd ..

echo ""
echo "✅ 打包完成！"
echo "   IPA 路径: $BUILD_DIR/$IPA_NAME"
echo ""
echo "==> 安装方式："
echo "   方式A（推荐，免费）：用 Sideloadly (https://sideloadly.io) 把 ipa 装到 iPhone"
echo "       - 用自己的 Apple ID 登录，免费账号即可，签名有效期 7 天"
echo "   方式B：用 AltStore (https://altstore.io) 同理"
echo "   方式C（付费开发者账号 $99/年）：签名后有效期 1 年，可用 xcodebuild 直接签"
echo ""
