#!/bin/bash

# --- 配置项 ---

# 必需的外部命令列表 (uv 会在脚本中尝试安装，所以不放入此列表)
REQUIRED_COMMANDS=(git curl)
PYTHON_VERSION="3.11" # 明确指定Python版本
PROJECT_REPO="https://github.com/EmberCtl/EmberCtl.git"
PROJECT_DIR_NAME="emberctl"
INSTALL_BASE_DIR="/opt" # 项目将安装到此目录下
UV_BIN_PATH="" # uv 可执行文件的实际路径，会在运行时确定

# --- 辅助函数 ---

# 打印信息消息
log_info() {
    echo "$(tput setaf 2)[INFO]$(tput sgr0) $(date +'%Y-%m-%d %H:%M:%S') $@" # 绿色文本，带时间戳
}

# 打印警告消息
log_warn() {
    echo "$(tput setaf 3)[WARN]$(tput sgr0) $(date +'%Y-%m-%d %H:%M:%S') $@" # 黄色文本，带时间戳
}

# 打印错误消息并退出
log_error() {
    echo "$(tput setaf 1)[ERROR]$(tput sgr0) $(date +'%Y-%m-%d %H:%M:%S') $@" >&2 # 红色文本，输出到 stderr
    exit 1
}

# 检查命令是否可用
# 参数: $1 - 命令名称
# 返回: 0 (可用), 1 (不可用)
check_command() {
    local cmd_name="$1"
    if command -v "$cmd_name" &> /dev/null; then
        return 0 # 命令可用
    else
        return 1 # 命令不可用
    fi
}

# 检查当前用户是否具有 sudo (root) 权限
# 返回: 0 (是), 1 (否)
is_sudo() {
    if [[ "$EUID" -eq 0 ]]; then
        return 0 # 是 root 用户
    else
        return 1 # 不是 root 用户
    fi
}

# 确保 uv 命令在 PATH 中可用
# uv 默认安装到 ~/.cargo/bin 或 ~/.local/bin
ensure_uv_in_path() {
    log_info "正在检查 uv 是否已在 PATH 中..."
    if check_command "uv"; then
        UV_BIN_PATH=$(command -v uv)
        log_info "uv 已直接在 PATH 中找到: $UV_BIN_PATH"
        return 0
    fi

    local uv_possible_paths=(
        "$HOME/.local/bin" # 非root用户默认安装路径
        "$HOME/.cargo/bin" # cargo 工具链的默认路径，uv 也可能安装在此
        "/root/.local/bin" # root用户默认安装路径
        "/root/.cargo/bin" # root用户cargo工具链的默认路径
    )

    for p_path in "${uv_possible_paths[@]}"; do
        if [[ -f "$p_path/uv" ]]; then
            log_info "在 '$p_path' 找到了 uv 可执行文件。添加到 PATH。"
            export PATH="$p_path:$PATH"
            UV_BIN_PATH="$p_path/uv"
            if check_command "uv"; then
                log_info "uv 已成功添加到当前会话的 PATH。"
                return 0
            else
                log_warn "尽管找到 uv 但添加 PATH 后仍无法执行。可能存在权限或环境问题。"
            fi
        fi
    done

    log_warn "未能在常用路径中找到 'uv' 或无法添加到 PATH。"
    return 1 # 未找到或未能添加到 PATH
}

# 初始化 Python 环境 (使用 uv)
init_python() {
    log_info "正在检查并安装 uv (Python包管理器)..."

    # 尝试确保 uv 在 PATH 中可用
    if ! ensure_uv_in_path; then
        log_warn "未找到 uv 命令或无法将其添加到 PATH。尝试进行安装..."
        # 尝试通过 curl 安装 uv
        # 注意：这里直接执行 curl -sSf | sh，uv 会安装到 $HOME/.cargo/bin 或 $HOME/.local/bin
        # 对于 sudo 执行的脚本，$HOME 是 /root
        local uv_install_script_output
        uv_install_script_output=$(curl -LsSf https://astral.sh/uv/install.sh | sh 2>&1)
        if echo "$uv_install_script_output" | grep -q "installation completed!"; then
            log_info "uv 安装脚本执行成功。"
        else
            log_error "uv 安装脚本执行失败。\n输出: $uv_install_script_output"
        fi

        # 再次尝试确保 uv 在 PATH 中可用
        if ! ensure_uv_in_path; then
             log_error "uv 安装后仍不可用，请检查uv的安装位置及PATH环境变量。"
        fi
    fi
    log_info "uv 命令已安装并可用，路径为: $UV_BIN_PATH"


    log_info "正在使用 uv 安装 Python ${PYTHON_VERSION}..."
    if ! uv python install "${PYTHON_VERSION}"; then
        log_error "Python ${PYTHON_VERSION} 安装失败，请检查 uv 配置或手动安装。尝试手动运行 'uv python install ${PYTHON_VERSION} --python-prefix ${PYTHON_INSTALL_DIR}'。"
    fi
    log_info "Python ${PYTHON_VERSION} 安装完成"
}

# --- 主逻辑 ---

main() {
    log_info "脚本开始执行：环境预检查和项目安装"

    # 1. 检查 sudo 权限
    if ! is_sudo; then
        log_error "非 root 用户。本脚本需要 root (sudo) 权限来执行安装操作。\n  请尝试使用 'sudo $0 $@' 运行。"
    fi
    log_info "root 权限检查通过。"

    # 2. 检查所有必需的命令
    log_info "正在检查所有必需的外部命令..."
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! check_command "$cmd"; then
            log_error "缺少必需的命令: '$cmd'。请确保其已安装并可在 PATH 中找到。"
        fi
    done
    log_info "所有必需命令基础检查通过。"

    # 3. 初始化 Python 环境 (包括 uv 的安装和 Python 版本的安装)
    init_python

    # 4. 确保安装目录和权限
    local project_full_path="${INSTALL_BASE_DIR}/${PROJECT_DIR_NAME}"

    log_info "正在处理项目目录 '${project_full_path}'..."
    if [[ ! -d "$INSTALL_BASE_DIR" ]]; then
        log_info "目录 '${INSTALL_BASE_DIR}' 不存在，正在创建..."
        if ! mkdir -p "$INSTALL_BASE_DIR"; then
            log_error "创建目录 '${INSTALL_BASE_DIR}' 失败。请检查权限。"
        fi
        log_info "成功创建目录 '${INSTALL_BASE_DIR}'。"
    fi

    # 设置安装目录的权限，确保后续操作可以进行
    log_info "正在设置 '${INSTALL_BASE_DIR}' 目录权限..."
    if ! chmod 755 "$INSTALL_BASE_DIR"; then
        log_error "设置目录 '${INSTALL_BASE_DIR}' 权限失败。"
    fi
    log_info "目录 '${INSTALL_BASE_DIR}' 权限设置完成。"

    # 5. 克隆项目或更新项目
    if [[ -d "$project_full_path" ]]; then
        log_info "项目 '${PROJECT_DIR_NAME}' 已存在于 '${INSTALL_BASE_DIR}'。"
        read -r -p "发现项目 '${PROJECT_DIR_NAME}' 已经存在。是否尝试更新它 (y) 或删除并重新克隆(d) 或跳过 (n)? [y/d/n]: " REPLY
        REPLY=${REPLY,,} # 转换为小写

        if [[ "$REPLY" =~ ^(y|yes)$ ]]; then
            log_info "正在尝试更新项目 '${project_full_path}'..."
            (
                cd "$project_full_path" || log_error "无法进入项目目录 '$project_full_path' 进行更新。"
                if ! git pull origin main; then # 假设主分支是 main
                    log_warn "Git Pull 更新失败，可能存在本地修改或网络问题。尝试强制重置。"
                    if ! git reset --hard origin/main && git clean -df; then
                         log_error "Git 强制重置失败。请手动检查项目目录 '$project_full_path'。"
                    else
                         log_info "项目已强制重置并清理。"
                    fi
                fi
                log_info "项目更新完成。"
            )
        elif [[ "$REPLY" =~ ^(d|delete)$ ]]; then
            log_warn "用户选择删除现有项目。正在删除 '${project_full_path}'..."
            if ! rm -rf "$project_full_path"; then
                log_error "删除项目目录 '${project_full_path}' 失败。请检查权限。"
            fi
            log_info "项目目录 '${project_full_path}' 已删除。正在重新克隆..."
            if ! git clone "$PROJECT_REPO" "$project_full_path"; then
                log_error "Git 克隆失败。请检查网络或仓库地址。"
            fi
            log_info "项目重新克隆完成。"
        else
            log_warn "跳过项目克隆/更新步骤。将使用现有项目内容。"
        fi
    else
        log_info "正在克隆项目 '${PROJECT_REPO}' 到 '${INSTALL_BASE_DIR}'..."
        if ! git clone "$PROJECT_REPO" "$project_full_path"; then
                log_error "Git 克隆失败。请检查网络或仓库地址。"
        fi
        log_info "项目克隆完成。"
    fi

    # 6. 进入项目目录并设置 Python 虚拟环境和安装依赖
    log_info "进入项目目录 '${project_full_path}'..."
    (
        cd "$project_full_path" || log_error "无法进入项目目录 '$project_full_path'。"

        log_info "正在使用 uv 同步项目依赖..."

        if ! uv sync --python "$PYTHON_VERSION"; then
            log_error "项目依赖安装失败。请检查网络或项目依赖配置。"
        fi
        log_info "项目依赖安装完成。"

        log_info "脚本执行完毕！项目安装成功并依赖已同步。"
    )

    log_info "所有预检查和安装步骤已完成。"
}

# 调用主函数
main "$@"
