#!/bin/bash

set -e  # 一旦出错立即退出
set -x  # 显示每条执行的命令

# 当前目录
echo "📁 当前路径: $(pwd)"

# 下载地址和目标路径
ZIP_URL="https://github.com/aiguanren/WYBasisKit-swift/releases/download/1.0.0/WYMediaPlayerFramework.zip"
ZIP_PATH="./MediaPlayer/WYMediaPlayerFramework.zip"
UNZIP_DIR="./MediaPlayer/WYMediaPlayerFramework"

# 清理旧内容
echo "🧹 清理旧内容..."
rm -rf "$UNZIP_DIR"
mkdir -p "$UNZIP_DIR"

# 下载 ZIP 包
echo "⬇️ 正在下载框架..."
curl -L -o "$ZIP_PATH" "$ZIP_URL"

# 解压到临时目录
echo "📦 正在解压..."
unzip -o "$ZIP_PATH" -d "$UNZIP_DIR/__temp__"

# 移动实际框架文件
echo "🚚 移动内容到目标目录..."
mv "$UNZIP_DIR/__temp__/WYMediaPlayerFramework/"* "$UNZIP_DIR/"

# 删除临时目录和 zip 包
echo "🧹 清理临时文件..."
rm -rf "$UNZIP_DIR/__temp__"
rm -rf "$UNZIP_DIR/__MACOSX"
rm -f "$ZIP_PATH"

echo "✅ 下载和解压完成"
