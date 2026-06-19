#!/usr/bin/env bash
# Cloak Browser 自动签到助手 | Cloak Browser Check-in Assistant
# https://cloakbrowser.dev
#
# 用法 / Usage:
#   ./run.sh              首次自动打开配置向导，之后直接签到
#   ./run.sh --setup      打开配置向导（添加/编辑/删除站点）
#   ./run.sh --login      进入 cookies 清除向导（强制重新登录）
#   ./run.sh <站点名>      只对单个站点签到（如 ourbits / audiences）

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ── 颜色（自动检测终端支持） ──────────────────────────────────────────────────
if [[ -t 1 ]] && command -v tput &>/dev/null && tput colors &>/dev/null 2>&1; then
    GRN="$(tput setaf 2)" YLW="$(tput setaf 3)" CYN="$(tput setaf 6)"
    BLD="$(tput bold)" RST="$(tput sgr0)"
else
    GRN="" YLW="" CYN="" BLD="" RST=""
fi
ok()   { printf '%s[+]%s %s\n' "$GRN" "$RST" "$*"; }
warn() { printf '%s[!]%s %s\n' "$YLW" "$RST" "$*"; }
info() { printf '%s[*]%s %s\n' "$CYN" "$RST" "$*"; }

# ── 横幅 ─────────────────────────────────────────────────────────────────────
printf '\n%s╔══════════════════════════════════════════╗%s\n' "$BLD" "$RST"
printf '%s║  Cloak Browser 自动签到助手              ║%s\n' "$BLD" "$RST"
printf '%s║  Cloak Browser Check-in Assistant        ║%s\n' "$BLD" "$RST"
printf '%s╚══════════════════════════════════════════╝%s\n\n' "$BLD" "$RST"

# ── 解析参数 ──────────────────────────────────────────────────────────────────
MODE="checkin"
SITE_ARG=""
for arg in "$@"; do
    case "$arg" in
        --setup) MODE="setup" ;;
        --login) MODE="login" ;;
        --help|-h)
            printf 'Usage: %s [--setup|--login|<site>]\n\n' "$0"
            printf '  %-16s %s\n' "(no args)"  "首次打开配置向导，之后直接签到所有站点"
            printf '  %-16s %s\n' "--setup"    "打开配置向导（添加/编辑/删除站点）"
            printf '  %-16s %s\n' "--login"    "清除 cookies 并强制重新登录"
            printf '  %-16s %s\n' "<site>"     "只对单个站点签到，如 ourbits"
            exit 0 ;;
        --*) printf '[-] Unknown option: %s\n' "$arg"; exit 1 ;;
        *)   SITE_ARG="$arg" ;;
    esac
done

# ═══════════════════════════════════════════════════════════════════════════════
# 第 1/3 步  检测 Python
# ═══════════════════════════════════════════════════════════════════════════════
printf '%s第 1/3 步  检测 Python...%s\n' "$BLD" "$RST"
PYTHON=""

# 优先级：系统 PATH → macOS Homebrew Apple Silicon → Intel → /usr/bin
PYTHON_CANDIDATES=(python3 python /opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3)

for cmd in "${PYTHON_CANDIDATES[@]}"; do
    if command -v "$cmd" &>/dev/null 2>&1 || [[ -x "$cmd" ]]; then
        _ver=$("$cmd" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
        _maj="${_ver%%.*}"; _min="${_ver##*.}"
        if [[ -n "$_ver" && "$_maj" -ge 3 && "$_min" -ge 8 ]]; then
            PYTHON="$cmd"; ok "$("$cmd" --version 2>&1)"; break
        fi
    fi
done

if [[ -z "$PYTHON" ]]; then
    printf '[-] 未找到 Python 3.8+\n\n'
    printf '  macOS:         brew install python3\n'
    printf '  Ubuntu/Debian: sudo apt install python3\n'
    printf '  其他 / Others: https://www.python.org/downloads/\n\n'
    exit 1
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 第 2/3 步  安装依赖
# ═══════════════════════════════════════════════════════════════════════════════
printf '\n%s第 2/3 步  检查依赖...%s\n' "$BLD" "$RST"

pip_install() {
    # 尝试三种方式：普通 pip → --break-system-packages → 项目内 venv
    if "$PYTHON" -m pip install "$@" --quiet 2>/dev/null; then
        return 0
    elif "$PYTHON" -m pip install "$@" --quiet --break-system-packages 2>/dev/null; then
        return 0
    else
        warn "创建虚拟环境 .venv ..."
        "$PYTHON" -m venv "$SCRIPT_DIR/.venv"
        PYTHON="$SCRIPT_DIR/.venv/bin/python"
        "$PYTHON" -m pip install "$@" --quiet
    fi
}

if ! "$PYTHON" -c "import cloakbrowser" &>/dev/null 2>&1; then
    warn "正在安装 cloakbrowser..."
    pip_install cloakbrowser
    ok "cloakbrowser 安装完成"
else
    ok "cloakbrowser 已就绪"
fi
[[ -f "$SCRIPT_DIR/requirements.txt" ]] && pip_install -r "$SCRIPT_DIR/requirements.txt"

# ═══════════════════════════════════════════════════════════════════════════════
# 第 3/3 步  配置检查 / 功能分发
# ═══════════════════════════════════════════════════════════════════════════════
printf '\n%s第 3/3 步  配置检查...%s\n' "$BLD" "$RST"

CONFIG_FILE="$SCRIPT_DIR/config.json"

if [[ "$MODE" == "setup" ]]; then
    # 显式打开配置向导
    "$PYTHON" "$SCRIPT_DIR/setup.py"
    exit $?
fi

if [[ "$MODE" == "login" ]]; then
    # 进入 cookies 清除向导
    "$PYTHON" "$SCRIPT_DIR/setup.py" --login
    exit $?
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    warn "未找到 config.json，打开配置向导..."
    printf '\n'
    "$PYTHON" "$SCRIPT_DIR/setup.py"
    # 如果用户保存了配置才继续签到
    [[ -f "$CONFIG_FILE" ]] || exit 0
fi

ok "已找到 config.json"

# ── 执行签到 ──────────────────────────────────────────────────────────────────
printf '\n%s开始签到...%s\n\n' "$BLD" "$RST"
if [[ -n "$SITE_ARG" ]]; then
    "$PYTHON" "$SCRIPT_DIR/checkin.py" "$SITE_ARG"
else
    "$PYTHON" "$SCRIPT_DIR/checkin.py"
fi
