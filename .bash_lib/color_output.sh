#!/bin/bash
# color_output.sh - 终端彩色输出基础库（标准化版本）
# 版本：1.0
# 调用方式：source /绝对路径/color_output.sh

# ==================== 1. 防重复导入（核心） ====================
if [[ -n "${COLOR_OUTPUT_LOADED}" ]]; then
    return 0  # 已导入过，直接退出，避免重复定义
fi
export COLOR_OUTPUT_LOADED="1"  # 标记已导入

# ==================== 2. 强制全局作用域（确保函数/变量可被外部调用） ====================
# 关闭局部作用域限制，所有变量/函数默认全局
set -a

# ==================== 3. 核心定义（保留你之前的逻辑） ====================
ESC=$(printf '\033')
declare -A _base_codes=(
    [BOLD]="${ESC}[1m"
    [RESET]="${ESC}[0m"
    [BLINK]="${ESC}[5m"
)
declare -A _color_control=(
    [BLACK]="${ESC}[30m"
    [RED]="${ESC}[31m"
    [GREEN]="${ESC}[32m"
    [YELLOW]="${ESC}[33m"
    [BLUE]="${ESC}[34m"
    [PURPLE]="${ESC}[35m"
    [CYAN]="${ESC}[36m"
    [WHITE]="${ESC}[37m"
    [ORANGE]="${ESC}[38;5;208m"
    [GRAY]="${ESC}[90m"
)
RAINBOW_COLORS=(
    "${_color_control[RED]}"
    "${_color_control[ORANGE]}"
    "${_color_control[YELLOW]}"
    "${_color_control[GREEN]}"
    "${_color_control[CYAN]}"
    "${_color_control[BLUE]}"
    "${_color_control[PURPLE]}"
)
declare -A _color_raw=(
    [BLACK]="\\033[30m"
    [RED]="\\033[31m"
    [GREEN]="\\033[32m"
    [YELLOW]="\\033[33m"
    [BLUE]="\\033[34m"
    [PURPLE]="\\033[35m"
    [CYAN]="\\033[36m"
    [WHITE]="\\033[37m"
    [ORANGE]="\\033[38;5;208m"
    [GRAY]="\\033[90m"
)

# ==================== 4. 初始化函数 ====================
function _init_color_vars() {
    for name in "${!_base_codes[@]}"; do
        eval "export ${name}=\"${_base_codes[$name]}\""
    done
    for name in "${!_color_control[@]}"; do
        eval "export ${name}=\"${_color_control[$name]}\""
    done
}

# ==================== 5. 对外暴露的核心函数（全部全局） ====================
function color_echo() {
    local color_name="$1"
    local content="$2"
    if [[ -z "${_color_control[$color_name]}" ]]; then
        echo "【color_output.sh 错误】颜色 ${color_name} 未定义！" >&2
        return 1
    fi
    echo -e -n "${BOLD}${_color_control[$color_name]}"
    echo -n "${content}"
    echo -e "${RESET}"
}

function blink_color_echo() {
    local color_name="$1"
    local content="$2"
    if [[ -z "${_color_control[$color_name]}" ]]; then
        echo "【color_output.sh 错误】颜色 ${color_name} 未定义！" >&2
        return 1
    fi
    echo -e -n "${BLINK}${BOLD}${_color_control[$color_name]}"
    echo -n "${content}"
    echo -e "${RESET}"
}

function rainbow_blink_forever() {
    local content="$1"
    local delay=${2:-0.2}
    local blink_pid_file="/tmp/rainbow_blink.pid"

    if [[ -f "${blink_pid_file}" ]]; then
        kill $(cat "${blink_pid_file}") 2>/dev/null
        rm -f "${blink_pid_file}"
    fi

    (
        while true; do
            for color in "${RAINBOW_COLORS[@]}"; do
                echo -ne "\r${BLINK}${BOLD}${color}${content}${RESET}"
                sleep $delay
            done
        done
    ) &
    echo $! > "${blink_pid_file}"
    echo -e "\n✅ 彩虹闪烁已启动（进程ID：$(cat ${blink_pid_file})）"
    echo "🔴 停止闪烁请执行：stop_rainbow_blink"
}

function stop_rainbow_blink() {
    local blink_pid_file="/tmp/rainbow_blink.pid"
    if [[ -f "${blink_pid_file}" ]]; then
        kill $(cat "${blink_pid_file}") 2>/dev/null
        rm -f "${blink_pid_file}"
        echo "✅ 彩虹闪烁已停止"
    else
        echo "❌ 没有正在运行的彩虹闪烁进程"
    fi
}

function rainbow_blink_then_hold() {
    local content="$1"
    local blink_times=${2:-10}
    local delay=${3:-0.2}
    local hold_color=${4:-RED}

    for ((i=0; i<blink_times; i++)); do
        local color=${RAINBOW_COLORS[$((i % ${#RAINBOW_COLORS[@]}))]}
        echo -ne "\r${BLINK}${BOLD}${color}${content}${RESET}"
        sleep $delay
    done

    echo -ne "\r${BLINK}${BOLD}${_color_control[$hold_color]}${content}${RESET}"
    echo -e "\n✅ 彩虹闪烁结束，已切换为 ${hold_color} 持续闪烁"
}

function print_color_samples() {
    echo -e "\n${BOLD}【所有颜色定义样例】${RESET}"
    for name in $(echo "${!_color_control[@]}" | tr ' ' '\n' | sort); do
        local display="    ${name}=\"${_color_raw[$name]}\""
        color_echo "${name}" "${display}"
    done

    echo -e "\n${BOLD}【单一颜色闪烁样例】${RESET}"
    blink_color_echo "ORANGE" "    ORANGE=\"${_color_raw[ORANGE]}\""
    blink_color_echo "RED" "    RED=\"${_color_raw[RED]}\""

    echo -e "\n${BOLD}【彩虹色闪烁样例】${RESET}"
    rainbow_blink_then_hold "    🌈 彩虹色闪烁效果 🌈" 14 0.1
}

function print_bg_color_code() { # 打印背景颜色编码	
    echo -n "    黑色背景      40 | \033[0;40m白字黑底\033[0m" && echo -e " | \033[0;40m白字黑底\033[0m"
    echo -n "    红色背景      41 | \033[0;41m白字红底\033[0m" && echo -e " | \033[0;41m白字红底\033[0m"
    echo -n "    绿色背景      42 | \033[0;42m白字绿底\033[0m" && echo -e " | \033[0;42m白字绿底\033[0m"
    echo -n "    黄色背景      43 | \033[0;43m白字黄底\033[0m" && echo -e " | \033[0;43m白字黄底\033[0m"
    echo -n "    蓝色背景      44 | \033[0;44m白字蓝底\033[0m" && echo -e " | \033[0;44m白字蓝底\033[0m"
    echo -n "    洋红背景      45 | \033[0;45m白字紫底\033[0m" && echo -e " | \033[0;45m白字洋红底\033[0m"
    echo -n "    青色背景      46 | \033[0;46m白字青底\033[0m" && echo -e " | \033[0;46m白字青底\033[0m"
    echo -n "    白色背景      47 | \033[30;47m黑字白底\033[0m" && echo -e " | \033[30;47m黑字白底\033[0m"
    echo -n "    重置背景色    49 | \033[49m默认背景\033[0m"    && echo -e " | \033[49m默认背景\033[0m"
}

# ==================== 新增：列出所有自定义函数 ====================
function list_color_functions() {
    echo -e "${BOLD}【color_output.sh 所有自定义函数】${RESET}"
    # 定义函数说明（键：函数名，值：说明）
    declare -A func_desc=(
        [_init_color_vars]="内部函数：初始化颜色变量（无需外部调用）"
        [color_echo]="基础彩色打印（参数：颜色名 内容）"
        [blink_color_echo]="单一颜色闪烁打印（参数：颜色名 内容）"
        [rainbow_blink_forever]="彩虹色永久闪烁（参数：内容 [切换间隔]）"
        [stop_rainbow_blink]="停止彩虹色永久闪烁（无参数）"
        [rainbow_blink_then_hold]="限时彩虹闪烁+最后保持颜色（参数：内容 [次数] [间隔] [保持颜色]）"
        [print_color_samples]="打印所有颜色样例（无参数）"
	[print_bg_color_code]="自定义显示背景颜色编码 (无参数)"
        [list_color_functions]="列出所有函数及说明（本函数）"
    )

    # 遍历所有自定义函数，按字母排序输出
    local funcs=(
        "_init_color_vars"
        "color_echo"
        "blink_color_echo"
        "rainbow_blink_forever"
        "stop_rainbow_blink"
        "rainbow_blink_then_hold"
        "print_color_samples"
	"print_bg_color_code"
        "list_color_functions"
    )

    for func in "${funcs[@]}"; do
        # 彩色输出函数名 + 说明
        color_echo "CYAN" "• ${func}"
        echo "  说明：${func_desc[$func]}"
    done
}

# ==================== 6. 初始化执行（自动加载变量） ====================
_init_color_vars

# ==================== 7. 恢复默认配置（不影响调用方脚本） ====================
set +a  # 关闭强制全局作用域

# ==================== 8. 版本信息（可选，便于调试） ====================
export COLOR_OUTPUT_VERSION="1.0"
