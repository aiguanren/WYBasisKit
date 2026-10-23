#!/bin/bash

# 双击运行的 CocoaPods 验证/发布入口，功能都在同目录的 Cocoapods.py 里实现
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# pod 的转发脚本在 ~/.local/bin（先解除 RVM 导出的 GEM_PATH 再调 brew 版 pod），双击运行不经过登录 shell 配置，PATH 里要手动补上
export PATH="${HOME}/.local/bin:/opt/homebrew/bin:${PATH}"

# CocoaPods 要求终端 UTF-8 编码（podspec 含中文注释），Terminal 未设置 LANG 时兜底
export LANG="${LANG:-en_US.UTF-8}"

if ! command -v python3 >/dev/null 2>&1; then
    echo "未找到 python3，请先安装 Xcode Command Line Tools（终端执行 xcode-select --install）"
    read -p "按回车键关闭窗口..."
    exit 1
fi

if ! command -v pod >/dev/null 2>&1; then
    echo "未找到 pod 命令，请检查 CocoaPods 安装"
    read -p "按回车键关闭窗口..."
    exit 1
fi

python3 "${SCRIPT_DIR}/Cocoapods.py"
read -p "按回车键关闭窗口..."
