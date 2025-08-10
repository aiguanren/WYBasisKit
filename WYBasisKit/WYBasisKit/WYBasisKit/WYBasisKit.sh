#!/bin/bash
# WYBasisKit.sh - 脚本管理
# 用途：集中管理所有 prepare_command 阶段需要执行的脚本
# 作者：官人
#
# 终端调试方式(在 WYBasisKit 文件夹下执行)：
#   bash WYBasisKit.sh
#   bash WYBasisKit.sh --debug  # 查看详细执行过程
#

# 开启严格模式（有错误就退出）
set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 日志函数
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

# 脚本执行函数（支持相对路径）
run_script() {
    local script_path="$1"
    if [ -f "$script_path" ]; then
        log_info "执行脚本: $script_path"
        bash "$script_path"
    else
        log_error "未找到脚本: $script_path"
        exit 1
    fi
}

# 执行 MediaPlayer 相关脚本
# run_script "$SCRIPT_DIR/WYDownload.sh"

# 如果以后有别的脚本
# run_script "$SCRIPT_DIR/OtherModule/SomeOtherScript.sh"

log_info "所有脚本执行完成"
