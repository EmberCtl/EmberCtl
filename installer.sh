#!/bin/bash
set -Eeo pipefail

# --- 全局配置项 ---
REQUIRED_COMMANDS=(git curl docker systemctl sed tee chmod)
PYTHON_VERSION="3.11" # <--- 固定 Python 版本
PROJECT_REPO="https://github.com/EmberCtl/EmberCtl.git"
PROJECT_DIR_NAME="emberctl"
INSTALL_BASE_DIR="/opt"
UV_BIN_PATH=""
PROJECT_TAG="main"
SCRIPT_NAME="EmberCtl 安装器"
AUTO_YES=1 # 自动确认，无需用户输入

# --- 支持函数 ---

# 彩色日志
log_info() { echo -e "\e[32m[INFO]\e[0m $(date '+%Y-%m-%d %H:%M:%S') $@"; }
log_warn() { echo -e "\e[33m[WARN]\e[0m $(date '+%Y-%m-%d %H:%M:%S') $@" >&2; }
log_error() { echo -e "\e[31m[ERROR]\e[0m $(date '+%Y-%m-%d %H:%M:%S') $@" >&2; exit 1; }

# 命令检查
check_command() { command -v "$1" &> /dev/null; }

# root 权限判断
is_sudo_user() { [[ "$EUID" -eq 0 ]]; }

# 确认
ask_yes_no() {
    if [[ $AUTO_YES -eq 1 ]]; then
        return 0
    fi
    read -r -p "$1 [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# --- 环境准备 ---

check_system_dependencies() {
    log_info "检查依赖命令是否安装..."
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! check_command "$cmd"; then
            log_error "缺少必要依赖命令: $cmd"
        fi
    done
    log_info "依赖检查完成。"
}

ensure_uv_installed() {
    log_info "正在查找 uv..."

    if check_command uv; then
        UV_BIN_PATH=$(command -v uv)
        log_info "uv 已安装在: $UV_BIN_PATH"
        return 0
    fi

    local paths=("$HOME/.local/bin" "$HOME/.cargo/bin" "/root/.local/bin" "/root/.cargo/bin")
    for p in "${paths[@]}"; do
        if [[ -x "$p/uv" ]]; then
            export PATH="$p:$PATH"
            UV_BIN_PATH="$p/uv"
            log_info "uv 已添加到 PATH: $UV_BIN_PATH"
            return 0
        fi
    done

    log_info "uv 未找到，尝试安装..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

    if check_command uv; then
        UV_BIN_PATH=$(command -v uv)
        log_info "uv 安装完成，路径为: $UV_BIN_PATH"
    else
        log_error "uv 安装失败，请手动安装"
    fi
}

setup_python_with_uv() {
    log_info "正在初始化 Python 环境..."
    ensure_uv_installed

    if ! uv python install "${PYTHON_VERSION}"; then
        log_error "Python ${PYTHON_VERSION} 安装失败，请手动运行: uv python install ${PYTHON_VERSION}"
    fi
    log_info "Python ${PYTHON_VERSION} 已安装"
}

# --- 项目管理 ---

prepare_install_dir() {
    local path="$INSTALL_BASE_DIR/$PROJECT_DIR_NAME"
    if [[ ! -d "$INSTALL_BASE_DIR" ]]; then
        log_info "正在创建安装目录..."
        mkdir -p "$INSTALL_BASE_DIR" || log_error "目录创建失败"
    fi

    if [[ -d "$path" ]]; then
        if ask_yes_no "项目目录已存在，是否清空旧文件？"; then
            rm -rf "$path"
        else
            log_info "项目目录已存在，将会直接更新"
        fi
    fi
}

clone_project_to_target() {
    local path="$INSTALL_BASE_DIR/$PROJECT_DIR_NAME"
    if [[ -d "$path" ]]; then
        log_info "正在拉取项目最新代码..."
        if cd "$path" && git pull && git checkout "$PROJECT_TAG"; then
            log_info "项目代码已更新"
        else
            log_error "项目代码更新失败"
        fi
    else
        log_info "正在克隆项目到 $path..."
        if git clone --branch "$PROJECT_TAG" --depth 1 "$PROJECT_REPO" "$path"; then
            log_info "项目克隆完成，当前 tag: $PROJECT_TAG"
        else
            log_error "项目克隆失败"
        fi
    fi
}

install_project_deps() {
    local path="$INSTALL_BASE_DIR/$PROJECT_DIR_NAME"
    cd "$path" || log_error "切换目录失败"
    log_info "正在安装项目依赖..."
    if ! uv sync --python "$PYTHON_VERSION"; then
        log_error "依赖安装失败"
    fi
    log_info "依赖安装完成"
}

create_systemd_service() {
    local service_path="/etc/systemd/system/emberctl.service"
    local current_path="$PATH"

    tee "$service_path" > /dev/null <<EOF
[Unit]
Description=EmberCtl Daemon Service
After=network.target

[Service]
User=root
WorkingDirectory=/opt/emberctl
Environment="PATH=$current_path"
ExecStart=/bin/bash -c "uv run -p ${PYTHON_VERSION} main.py serve"
Restart=always
RestartSec=5s
StandardOutput=journal
StandardError=inherit

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable emberctl
    systemctl restart emberctl
}


create_global_entrypoint() {
    local bin_path="/bin/emctl"
    local project_dir="${INSTALL_BASE_DIR}/${PROJECT_DIR_NAME}"

    log_info "正在配置全局命令入口"

    tee "$bin_path" > /dev/null <<'EOF'
#!/bin/bash
set -e
# 使用 uv 执行固定版本的 Python 运行 main.py，并传递所有参数
!UV_PATH! run -p !PYTHON_VERSION! --directory !PROJECT_PATH! !PROJECT_PATH!/main.py "$@"
EOF
    # 替换 ${PYTHON_VERSION} 为实际的 Python 版本
    sed -i "s|!PYTHON_VERSION!|$PYTHON_VERSION|g" "$bin_path"
    # 替换 ${UV_PATH}
    sed -i "s|!UV_PATH!|$UV_BIN_PATH|g" "$bin_path"
    # 替换 ${PROJECT_PATH}
    sed -i "s|!PROJECT_PATH!|$project_dir|g" "$bin_path"

    chmod +x "$bin_path"

    log_info "全局命令已创建完成，你现在可以使用：emctl [command]"
}



# --- 主逻辑 ---

MAIN() {
    log_info "$SCRIPT_NAME 启动"

    # 1. root 检查
    if ! is_sudo_user; then
        log_error "请以 root 用户运行此安装脚本"
    fi

    # 2. 依赖检查
    check_system_dependencies

    # 3. Python 环境初始化
    setup_python_with_uv

    # 4. 准备目录
    prepare_install_dir

    # 5. 安装项目
    clone_project_to_target

    # 6. 安装依赖
    install_project_deps

    # 7. 创建全局入口
    create_global_entrypoint

    # 8. 安装系统服务
    create_systemd_service

    /bin/emctl init

    log_info "✅ $SCRIPT_NAME 成功完成"
    echo
    echo "安装路径: $INSTALL_BASE_DIR/$PROJECT_DIR_NAME"
    echo "可执行项目入口示例: uv run -p python main.py"
}

trap 'log_error "脚本非正常退出，状态码 $?。请检查上文日志。"' ERR

MAIN "$@"
