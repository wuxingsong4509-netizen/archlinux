#!/bin/bash

# ============================================
# 终端环境一键配置脚本
# 适用于 Arch Linux
# ============================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_header() {
    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  $1${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "请不要使用root用户运行此脚本"
        exit 1
    fi
}

# 检查sudo权限
check_sudo() {
    print_info "检查sudo权限..."
    if ! sudo -v; then
        print_error "需要sudo权限才能继续"
        exit 1
    fi
    print_success "sudo权限验证成功"
}

# 修复中文locale
fix_locale() {
    print_header "1. 修复中文Locale"
    
    if locale | grep -q "zh_CN.UTF-8"; then
        print_success "中文locale已配置"
    else
        print_info "配置中文locale..."
        
        # 添加zh_CN.UTF-8到locale.gen
        if ! grep -q "^zh_CN.UTF-8 UTF-8" /etc/locale.gen; then
            sudo bash -c 'echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen'
        fi
        
        # 生成locale
        sudo locale-gen
        
        print_success "中文locale配置完成"
    fi
}

# 安装oh-my-zsh
install_oh_my_zsh() {
    print_header "2. 安装Oh My Zsh"
    
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        print_success "Oh My Zsh已安装"
    else
        print_info "安装Oh My Zsh..."
        sudo pacman -S --noconfirm zsh
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        print_success "Oh My Zsh安装完成"
    fi
}

# 安装zsh插件
install_zsh_plugins() {
    print_header "3. 安装Zsh插件"
    
    ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
    
    # zsh-autosuggestions
    if [[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
        print_success "zsh-autosuggestions已安装"
    else
        print_info "安装zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
        print_success "zsh-autosuggestions安装完成"
    fi
    
    # zsh-syntax-highlighting
    if [[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
        print_success "zsh-syntax-highlighting已安装"
    else
        print_info "安装zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
        print_success "zsh-syntax-highlighting安装完成"
    fi
}

# 安装终端美化工具
install_terminal_tools() {
    configure_kitty
    print_header "4. 安装终端工具"
    
    print_info "更新系统并安装软件包..."
    
    # 基础工具
    PACKAGES=(
        # 美化工具
        lsd bat eza htop btop fastfetch
        
        kitty                   # Kitty终端
        # 搜索工具
        fzf ripgrep fd
        
        # 解压工具
        unzip unrar p7zip zip tar gzip bzip2 xz
        
        # 网络工具
        wget curl net-tools dnsutils traceroute
        
        # 编辑器
        vim neovim
        
        # 其他工具
        tmux tree ncdu lazygit diff-so-fancy zoxide thefuck tldr
        
        # Git
        git
        
        # 开发工具
        zeal                    # API文档浏览器
        
        # 编译器和运行时
        gcc clang               # C/C++编译器
        gdb lldb                # 调试器
        make cmake              # 构建工具
        
        # .NET
        dotnet-sdk              # .NET SDK
        mono                    # Mono运行时
        
        # Node.js
        nodejs npm              # Node.js和npm
        yarn                    # Yarn包管理器
        
        # Python
        python python-pip       # Python 3
        python-pipenv           # Python虚拟环境
        python-virtualenv       
        
        # Java
        jdk-openjdk             # OpenJDK
        
        # 其他语言
        rust                    # Rust
        go                      # Go
        ruby                    # Ruby
        
        # 数据库客户端
        postgresql-libs         # PostgreSQL客户端库
        mariadb-clients         # MySQL/MariaDB客户端
        redis                   # Redis
        
        # 容器工具
        docker docker-compose   # Docker
        podman                  # Podman容器
    )
    
    sudo pacman -Sy --noconfirm "${PACKAGES[@]}"
    
    print_success "所有工具安装完成"
}

# 配置中文输入法
configure_chinese_input() {
    print_header "5. 配置中文输入法"
    
    # 检查是否已安装
    if pacman -Q fcitx5-chinese-addons &>/dev/null; then
        print_success "fcitx5-chinese-addons 已安装"
    else
        print_info "安装 fcitx5 中文输入法组件..."
        sudo pacman -S --noconfirm fcitx5-chinese-addons fcitx5-gtk fcitx5-qt fcitx5-configtool
        print_success "fcitx5 组件安装完成"
    fi
    
    # 配置系统环境变量
    print_info "配置系统环境变量..."
    sudo mkdir -p /etc/environment.d
    sudo tee /etc/environment.d/fcitx5.conf > /dev/null << 'FCITXEOF'
GTK_IM_MODULE=fcitx5
QT_IM_MODULE=fcitx5
XMODIFIERS=@im=fcitx5
SDL_IM_MODULE=fcitx5
GLFW_IM_MODULE=ibus
FCITXEOF
    print_success "已创建 /etc/environment.d/fcitx5.conf"
    
    # 配置自动启动
    print_info "配置 fcitx5 自动启动..."
    mkdir -p ~/.config/autostart
    cat > ~/.config/autostart/fcitx5.desktop << 'FCITXEOF'
[Desktop Entry]
Type=Application
Name=Fcitx5
Exec=fcitx5 -d
Terminal=false
Categories=System;
StartupNotify=false
X-GNOME-Autostart-enabled=true
FCITXEOF
    print_success "已创建自动启动项"
    
    # 配置 fcitx5 输入法
    print_info "配置 Pinyin 输入法..."
    mkdir -p ~/.config/fcitx5/conf
    
    cat > ~/.config/fcitx5/profile << 'FCITXEOF'
[Groups/0]
Name=Default
Default Layout=us
DefaultIM=pinyin

[Groups/0/Items/0]
Name=keyboard-us
Layout=

[Groups/0/Items/1]
Name=pinyin
Layout=

[GroupOrder]
0=Default
FCITXEOF
    
    # 配置快捷键
    cat > ~/.config/fcitx5/config << 'FCITXEOF'
[Hotkey]
TriggerKeys=
EnumerateWithTriggerKeys=True
EnumerateForwardKeys=
EnumerateBackwardKeys=
EnumerateSkipFirst=False
ActivateKeys=
DeactivateKeys=

[Hotkey/TriggerKeys]
0=Control+space

[Hotkey/PrevPage]
0=Up

[Hotkey/NextPage]
0=Down

[Behavior]
ActiveByDefault=True
ShareInputState=No
PreeditEnabledByDefault=True
ShowInputMethodInformation=True
ShowInputMethodInformationWhenFocusIn=False
CompactInputMethodInformation=True
ShowFirstInputMethodInformation=True
DefaultPageSize=5
OverrideXkbOption=False
CustomXkbOption=
EnabledAddons=
DisabledAddons=
FCITXEOF
    print_success "已配置 Pinyin 输入法和快捷键"
    
    # 启动 fcitx5
    print_info "启动 fcitx5..."
    pkill fcitx5 2>/dev/null || true
    sleep 1
    fcitx5 -d 2>/dev/null || true
    sleep 1
    
    print_success "中文输入法配置完成（Ctrl+Space 切换）"
}

# 配置终端启动简洁信息
configure_fastfetch() {
    print_header "6. 配置终端启动信息"
    
    if ! command -v fastfetch &> /dev/null; then
        print_warning "fastfetch 未安装，跳过配置"
        return
    fi
    
    print_info "配置 fastfetch 简洁显示..."
    mkdir -p ~/.config/fastfetch
    
    cat > ~/.config/fastfetch/config.jsonc << 'FETCHEOF'
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/master/doc/json_schema.json",
  "modules": [
    "title",
    "separator",
    "os",
    "kernel",
    "uptime",
    "shell",
    "terminal",
    "cpu",
    "memory",
    "disk"
  ]
}
FETCHEOF
    print_success "已配置 fastfetch 简洁显示"
}

# 配置 Kitty 终端
configure_kitty() {
    print_header "配置 Kitty 终端"
    
    if ! command -v kitty &> /dev/null; then
        print_warning "Kitty 未安装，跳过配置"
        return
    fi
    
    print_info "创建 Kitty 配置目录..."
    mkdir -p "$HOME/.config/kitty"
    
    # 备份现有配置
    if [[ -f "$HOME/.config/kitty/kitty.conf" ]]; then
        cp "$HOME/.config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf.backup.$(date +%Y%m%d_%H%M%S)"
        print_success "已备份现有 Kitty 配置"
    fi
    
    print_info "生成 Kitty 美化配置..."
    
    cat > "$HOME/.config/kitty/kitty.conf" << 'KITTYEOF'
# ═══════════════════════════════════════════════════════════
# 🎨 Kitty 终端美化配置
# ═══════════════════════════════════════════════════════════

# 字体配置
font_family      JetBrainsMono Nerd Font
bold_font        JetBrainsMono Nerd Font Bold
italic_font      JetBrainsMono Nerd Font Italic
bold_italic_font JetBrainsMono Nerd Font Bold Italic
font_size        13.0
disable_ligatures never

# 光标配置
cursor_shape beam
cursor_beam_thickness 2.0
cursor_blink_interval 0.5
cursor_stop_blinking_after 15.0

# 窗口配置
remember_window_size  yes
initial_window_width  1140
initial_window_height 1824
window_padding_width  15
window_padding_height 15
placement_strategy center
draw_minimal_borders yes
window_border_width 1.0
single_window_margin_width 0
hide_window_decorations yes
confirm_os_window_close 0

# 透明度和模糊
background_opacity 0.75
background_blur 30
dynamic_background_opacity yes

# 标签页配置
tab_bar_edge top
tab_bar_style powerline
tab_powerline_style round
tab_bar_min_tabs 1
tab_title_template " {index}:{title} "
active_tab_font_style   bold-italic
inactive_tab_font_style normal

# Catppuccin Mocha 主题
foreground              #CDD6F4
background              #1E1E2E
selection_foreground    #1E1E2E
selection_background    #F5E0DC
cursor                  #F5E0DC
cursor_text_color       #1E1E2E
url_color               #F5E0DC
active_border_color     #B4BEFE
inactive_border_color   #6C7086
bell_border_color       #F9E2AF
active_tab_foreground   #11111B
active_tab_background   #CBA6F7
inactive_tab_foreground #CDD6F4
inactive_tab_background #181825
tab_bar_background      #11111B

# 16色配置
color0 #45475A
color8 #585B70
color1 #F38BA8
color9 #F38BA8
color2  #A6E3A1
color10 #A6E3A1
color3  #F9E2AF
color11 #F9E2AF
color4  #89B4FA
color12 #89B4FA
color5  #F5C2E7
color13 #F5C2E7
color6  #94E2D5
color14 #94E2D5
color7  #BAC2DE
color15 #A6ADC8

# 性能优化
repaint_delay 6
input_delay 2
sync_to_monitor yes
scrollback_lines 10000
wheel_scroll_multiplier 5.0

# 鼠标
mouse_hide_wait 3.0
url_style curly
detect_urls yes
copy_on_select yes

# 铃声
enable_audio_bell no
visual_bell_duration 0.0

# 基础快捷键
map ctrl+shift+c copy_to_clipboard
map ctrl+shift+v paste_from_clipboard
map ctrl+shift+t new_tab
map ctrl+shift+q close_tab
map ctrl+shift+right next_tab
map ctrl+shift+left previous_tab
map ctrl+shift+equal change_font_size all +1.0
map ctrl+shift+minus change_font_size all -1.0
map ctrl+shift+backspace change_font_size all 0

# 透明度调整
map ctrl+shift+a>m set_background_opacity +0.1
map ctrl+shift+a>l set_background_opacity -0.1
map ctrl+shift+a>1 set_background_opacity 1
map ctrl+shift+a>d set_background_opacity default

# 窗口管理
map ctrl+shift+enter new_window_with_cwd
map f5 launch --location=hsplit --cwd=current
map f6 launch --location=vsplit --cwd=current
map ctrl+shift+w close_window

# 标签快速跳转
map ctrl+1 goto_tab 1
map ctrl+2 goto_tab 2
map ctrl+3 goto_tab 3
map ctrl+4 goto_tab 4
map ctrl+5 goto_tab 5

# 高级配置
allow_remote_control yes
term xterm-256color
KITTYEOF

    print_success "Kitty 配置已生成"
    print_info "配置文件位置: ~/.config/kitty/kitty.conf"
    print_info "特性: 透明度75%, Catppuccin主题, 无边框"
}

# 备份现有配置
backup_config() {
    print_header "5. 备份现有配置"
    
    if [[ -f "$HOME/.zshrc" ]]; then
        BACKUP_FILE="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$HOME/.zshrc" "$BACKUP_FILE"
        print_success "已备份到: $BACKUP_FILE"
    else
        print_info "未发现现有.zshrc配置"
    fi
}

# 生成.zshrc配置
generate_zshrc() {
    print_header "7. 生成.zshrc配置"
    
    print_info "生成新的.zshrc配置..."
    
    cat > "$HOME/.zshrc" << 'EOF'
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# 主题
ZSH_THEME="robbyrussell"

# 插件
plugins=(
  git
  z
  extract
  web-search
  zsh-autosuggestions
  zsh-syntax-highlighting
  sudo
  copypath
  copyfile
  jsontools
  docker
  npm
  node
  python
  tmux
  fzf
)

source $ZSH/oh-my-zsh.sh

# ============================================
# 语言和编码设置
# ============================================
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

# ============================================
# 编辑器设置
# ============================================
export EDITOR='vim'
export VISUAL='vim'

# ============================================
# 历史记录设置
# ============================================
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt SHARE_HISTORY

# ============================================
# 路径设置
# ============================================
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"

# ============================================
# 常用别名
# ============================================
# 系统命令 - 使用lsd替代ls
alias ls='lsd'
alias ll='lsd -lah'
alias la='lsd -A'
alias l='lsd -lF'
alias lt='lsd --tree'
alias ld='lsd -d */'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cl='clear'
alias h='history'
alias df='df -h'
alias du='du -h'
alias free='free -h'

# bat替代cat
alias cat='bat --style=auto'
alias catt='/usr/bin/cat'
alias less='bat'

# 系统监控
alias top='btop'
alias htop='htop'

# 其他工具
alias lg='lazygit'
alias tree='tree -C'
alias diff='diff-so-fancy'

# Git 别名
alias gs='git status'
alias ga='git add'
alias gaa='git add .'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'
alias gb='git branch'
alias gco='git checkout'
alias gcb='git checkout -b'

# 文件操作
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'

# 快速编辑配置文件
alias zshconfig='vim ~/.zshrc'
alias zshreload='source ~/.zshrc'
alias vimconfig='vim ~/.vimrc'

# 系统信息
alias myip='curl -s https://api.ipify.org && echo'
alias ports='netstat -tulanp'
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'

# Python
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv'

# Node.js
alias ni='npm install'
alias nid='npm install --save-dev'
alias nig='npm install -g'
alias nr='npm run'
alias ns='npm start'
alias nt='npm test'
alias yi='yarn install'
alias ya='yarn add'
alias yr='yarn run'

# Docker
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias drm='docker rm'
alias drmi='docker rmi'
alias dprune='docker system prune -af'

# .NET
alias dn='dotnet new'
alias db='dotnet build'
alias dr='dotnet run'
alias dt='dotnet test'
alias dp='dotnet publish'

# Rust
alias cg='cargo'
alias cgb='cargo build'
alias cgr='cargo run'
alias cgt='cargo test'
alias cgc='cargo check'

# Go
alias gor='go run'
alias gob='go build'
alias got='go test'
alias gom='go mod'

# ============================================
# 自定义函数
# ============================================
# 创建目录并进入
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# 快速查找进程
psgrep() {
  ps aux | grep -v grep | grep -i -e VSZ -e "$1"
}

# 快速杀死进程
killport() {
  lsof -ti:$1 | xargs kill -9
}

# ============================================
# 终端设置
# ============================================
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# zsh-autosuggestions 设置
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# zoxide 设置（替代cd）
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
  alias cd='z'
fi

# thefuck 设置（命令纠错）
if command -v thefuck >/dev/null 2>&1; then
  eval "$(thefuck --alias)"
  eval "$(thefuck --alias fk)"
fi

# fzf 设置（模糊搜索）
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# ============================================
# 输入法设置
# ============================================
export GTK_IM_MODULE=fcitx5
export QT_IM_MODULE=fcitx5
export XMODIFIERS=@im=fcitx5

# ============================================
# 启动信息
# ============================================
if [[ -o interactive ]] && [[ -z "$TMUX" ]] && [[ "$TERM" != "linux" ]]; then
  fastfetch
fi
EOF

    print_success ".zshrc配置生成完成"
}

# 设置zsh为默认shell
set_default_shell() {
    print_header "8. 设置默认Shell"
    
    if [[ "$SHELL" == */zsh ]]; then
        print_success "zsh已是默认shell"
    else
        print_info "设置zsh为默认shell..."
        chsh -s $(which zsh)
        print_success "默认shell已设置为zsh"
        print_warning "需要注销并重新登录才能生效"
    fi
}

# 完成安装
finish_installation() {
    print_header "安装完成"
    
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}   ✓ 终端环境配置完成！${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    echo -e "${BLUE}已安装的工具：${NC}"
    echo "  • lsd, bat, eza - 现代化命令行工具"
    echo "  • htop, btop - 系统监控"
    echo "  • fzf, ripgrep, fd - 搜索工具"
    echo "  • lazygit - Git TUI"
    echo "  • zoxide - 智能目录跳转"
    echo "  • thefuck - 命令纠错"
    echo "  • fastfetch - 系统信息（简洁显示）"
    echo "  • fcitx5 - 中文拼音输入法"
    
    echo -e "\n${BLUE}开发工具：${NC}"
    echo "  • zeal - API文档浏览器"
    echo "  • gcc, clang - C/C++编译器"
    echo "  • dotnet-sdk, mono - .NET开发"
    echo "  • nodejs, npm, yarn - Node.js开发"
    echo "  • python, pip - Python开发"
    echo "  • jdk-openjdk - Java开发"
    echo "  • rust, go, ruby - 其他语言"
    echo "  • docker, podman - 容器工具"
    
    echo -e "\n${BLUE}下一步：${NC}"
    echo -e "  1. 运行: ${GREEN}zsh${NC} 切换到zsh"
    echo -e "  2. 或注销并重新登录"
    echo -e "  3. 享受您的新终端环境！"
    
    echo -e "\n${BLUE}常用命令：${NC}"
    echo -e "  • ${GREEN}ll${NC} - 查看文件列表"
    echo -e "  • ${GREEN}cat file${NC} - 语法高亮查看文件"
    echo -e "  • ${GREEN}lg${NC} - 启动lazygit"
    echo -e "  • ${GREEN}Ctrl+R${NC} - 搜索历史命令"
    echo -e "  • ${GREEN}fuck${NC} - 纠正上一条错误命令"
    echo -e "  • ${GREEN}Ctrl+Space${NC} - 切换中文/英文输入"
    
    echo -e "\n${YELLOW}配置文件位置：${NC}"
    echo -e "  • ~/.zshrc"
    echo -e "  • 使用 ${GREEN}zshconfig${NC} 编辑配置"
    echo -e "  • 使用 ${GREEN}zshreload${NC} 重载配置"
    
    echo ""
}

# 显示主菜单
show_menu() {
    clear
    echo -e "${GREEN}"
    cat << 'EOF'
╔═══════════════════════════════════════════╗
║   终端环境配置脚本                        ║
║   Arch Linux                              ║
╚═══════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${BLUE}请选择要执行的操作：${NC}\n"
    echo -e "  ${GREEN}1${NC}  - 完整安装（推荐新系统）"
    echo -e "  ${GREEN}2${NC}  - 安装现代化命令行工具 (lsd, bat, eza, 等)"
    echo -e "  ${GREEN}3${NC}  - 安装/切换 Zsh 主题"
    echo -e "  ${GREEN}4${NC}  - 修复 Shell 配置冲突"
    echo -e "  ${GREEN}5${NC}  - 配置中文输入法"
    echo -e "  ${GREEN}6${NC}  - 配置终端启动信息"
    echo -e "  ${GREEN}7${NC}  - Shell 状态检查与切换"
    echo -e "  ${GREEN}8${NC}  - 修复 Chrome 中文输入问题"
    echo -e "  ${GREEN}9${NC}  - 生成 SSH 密钥"
    echo -e "  ${GREEN}10${NC} - 查看系统信息"
    echo -e "  ${GREEN}0${NC}  - 退出"
    echo ""
}

# 安装现代化工具（从 install-modern-tools.sh）
install_modern_cli_tools() {
    print_header "安装现代化命令行工具"
    
    # 工具列表
    TOOLS=(
        lsd bat eza btop htop ripgrep fd fzf zoxide tldr ncdu duf dust
    )
    
    # 检查已安装的工具
    print_info "检查已安装的工具..."
    INSTALLED=()
    TO_INSTALL=()
    
    for tool in "${TOOLS[@]}"; do
        if pacman -Q "$tool" &>/dev/null; then
            INSTALLED+=("$tool")
        else
            TO_INSTALL+=("$tool")
        fi
    done
    
    if [ ${#INSTALLED[@]} -gt 0 ]; then
        print_success "已安装: ${INSTALLED[*]}"
    fi
    
    # 安装缺失的工具
    if [ ${#TO_INSTALL[@]} -gt 0 ]; then
        print_info "安装工具: ${TO_INSTALL[*]}"
        sudo pacman -S --noconfirm "${TO_INSTALL[@]}"
        print_success "工具安装完成"
    else
        print_success "所有工具已安装"
    fi
    
    # 配置别名
    print_info "配置 shell 别名..."
    
    SHELL_RC=""
    if [ -f "$HOME/.zshrc" ]; then
        SHELL_RC="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        SHELL_RC="$HOME/.bashrc"
    fi
    
    if [ -n "$SHELL_RC" ] && ! grep -q "# Modern CLI Tools Aliases" "$SHELL_RC" 2>/dev/null; then
        cat >> "$SHELL_RC" << 'EOF'

# ============================================
# Modern CLI Tools Aliases
# ============================================
alias ls='lsd'
alias ll='lsd -lah'
alias la='lsd -A'
alias l='lsd -lF'
alias lt='lsd --tree'
alias cat='bat --style=auto'
alias catt='/usr/bin/cat'
alias less='bat'
alias top='btop'
alias grep='rg'
alias oldgrep='/usr/bin/grep'
alias find='fd'
alias oldfind='/usr/bin/find'
EOF
        print_success "别名已添加到 $SHELL_RC"
    fi
    
    print_success "现代化工具配置完成"
}

# 安装 Zsh 主题（简化版）
install_zsh_theme_menu() {
    print_header "安装 Zsh 主题"
    
    if ! command -v zsh &> /dev/null; then
        print_error "zsh 未安装，请先运行完整安装"
        return 1
    fi
    
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        print_error "Oh My Zsh 未安装，请先运行完整安装"
        return 1
    fi
    
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    
    echo -e "${BLUE}请选择主题：${NC}\n"
    echo -e "  ${GREEN}1${NC} - Powerlevel10k (推荐)"
    echo -e "  ${GREEN}2${NC} - Starship"
    echo -e "  ${GREEN}3${NC} - Spaceship"
    echo ""
    read -p "请选择 [1-3]: " theme_choice
    
    case $theme_choice in
        1)
            print_info "安装 Powerlevel10k..."
            if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
                git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
            fi
            sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$HOME/.zshrc"
            print_success "Powerlevel10k 已安装。重启终端后运行: p10k configure"
            ;;
        2)
            print_info "安装 Starship..."
            sudo pacman -S --noconfirm starship
            if ! grep -q 'eval "$(starship init zsh)"' "$HOME/.zshrc"; then
                echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
            fi
            print_success "Starship 已安装"
            ;;
        3)
            print_info "安装 Spaceship..."
            if [ ! -d "$ZSH_CUSTOM/themes/spaceship-prompt" ]; then
                git clone --depth=1 https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt"
                ln -sf "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
            fi
            sed -i 's|^ZSH_THEME=.*|ZSH_THEME="spaceship"|' "$HOME/.zshrc"
            print_success "Spaceship 已安装"
            ;;
    esac
}

# Shell 状态检查
check_shell_status() {
    print_header "Shell 状态检查"
    
    CURRENT_SHELL=$(ps -p $$ -o comm=)
    DEFAULT_SHELL=$(basename "$SHELL")
    
    echo -e "当前运行的 shell: ${GREEN}$CURRENT_SHELL${NC}"
    echo -e "默认 shell:      ${GREEN}$DEFAULT_SHELL${NC}"
    echo ""
    
    if [ "$CURRENT_SHELL" = "bash" ] && [ "$DEFAULT_SHELL" = "zsh" ]; then
        print_warning "检测到默认 shell 是 zsh，但当前在 bash"
        echo ""
        read -p "是否切换到 zsh？[y/N]: " switch
        if [[ $switch =~ ^[Yy]$ ]]; then
            exec zsh
        fi
    elif [ "$CURRENT_SHELL" = "bash" ]; then
        print_info "当前使用 bash"
        if [ -f "$HOME/.zshrc" ]; then
            echo ""
            read -p "检测到 zsh 配置，是否切换到 zsh？[y/N]: " switch
            if [[ $switch =~ ^[Yy]$ ]]; then
                exec zsh
            fi
        fi
    else
        print_success "当前使用 $CURRENT_SHELL"
    fi
}

# 生成 SSH 密钥
generate_ssh_key() {
    print_header "生成 SSH 密钥"
    
    if [ -f ~/.ssh/id_ed25519.pub ] || [ -f ~/.ssh/id_rsa.pub ]; then
        print_warning "检测到已存在 SSH 密钥："
        ls -lh ~/.ssh/id_*.pub 2>/dev/null || true
        echo ""
        read -p "是否生成新密钥（会备份旧密钥）？[y/N]: " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            print_info "已取消"
            return 0
        fi
        
        # 备份旧密钥
        if [ -d ~/.ssh ]; then
            BACKUP_DIR=~/.ssh/backup_$(date +%Y%m%d_%H%M%S)
            mkdir -p "$BACKUP_DIR"
            cp ~/.ssh/id_* "$BACKUP_DIR/" 2>/dev/null || true
            print_success "旧密钥已备份到: $BACKUP_DIR"
        fi
    fi
    
    echo ""
    echo -e "${BLUE}密钥类型：${NC}"
    echo -e "  ${GREEN}1${NC} - Ed25519 (推荐) - 更安全，更快"
    echo -e "  ${GREEN}2${NC} - RSA 4096 - 兼容性更好"
    echo ""
    read -p "选择密钥类型 [1-2] (默认 1): " key_type
    key_type=${key_type:-1}
    
    echo ""
    read -p "输入邮箱地址 (用于标识密钥): " email
    
    if [ -z "$email" ]; then
        print_error "邮箱地址不能为空"
        return 1
    fi
    
    echo ""
    print_info "开始生成密钥..."
    
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    if [ "$key_type" = "2" ]; then
        ssh-keygen -t rsa -b 4096 -C "$email" -f ~/.ssh/id_rsa
    else
        ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519
    fi
    
    echo ""
    print_success "SSH 密钥生成完成！"
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}公钥内容（复制以下内容）：${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    cat ~/.ssh/id_*.pub | grep -v "\.backup"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo ""
    echo -e "${YELLOW}使用说明：${NC}"
    echo -e "  1. 复制上面的公钥内容"
    echo -e "  2. GitHub: Settings → SSH and GPG keys → New SSH key"
    echo -e "  3. GitLab: Preferences → SSH Keys"
    echo -e "  4. 服务器: ${GREEN}ssh-copy-id user@server${NC}"
    echo ""
    echo -e "${BLUE}测试连接：${NC}"
    echo -e "  GitHub:  ${GREEN}ssh -T git@github.com${NC}"
    echo -e "  GitLab:  ${GREEN}ssh -T git@gitlab.com${NC}"
    echo ""
}

# 查看系统信息
show_system_info() {
    print_header "系统信息"
    
    if command -v fastfetch &> /dev/null; then
        fastfetch
    elif command -v neofetch &> /dev/null; then
        neofetch
    else
        echo -e "${BLUE}操作系统：${NC}$(uname -o)"
        echo -e "${BLUE}内核版本：${NC}$(uname -r)"
        echo -e "${BLUE}主机名：${NC}$(hostname)"
        echo -e "${BLUE}用户：${NC}$USER"
        echo -e "${BLUE}Shell：${NC}$SHELL"
        echo -e "${BLUE}终端：${NC}$TERM"
    fi
    
    echo ""
    echo -e "${BLUE}已安装的工具：${NC}"
    
    TOOLS=(zsh git vim docker python3 node rustc go java lsd bat ripgrep fd)
    for tool in "${TOOLS[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo -e "  ${GREEN}✓${NC} $tool"
        fi
    done
    
    echo ""
    echo -e "${BLUE}Shell 状态：${NC}"
    echo -e "  当前 Shell: ${GREEN}$(ps -p $$ -o comm=)${NC}"
    echo -e "  默认 Shell: ${GREEN}$(basename $SHELL)${NC}"
    
    if [ -d ~/.oh-my-zsh ]; then
        echo -e "  Oh My Zsh: ${GREEN}已安装${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}输入法状态：${NC}"
    if pgrep -x fcitx5 > /dev/null; then
        echo -e "  Fcitx5: ${GREEN}运行中${NC}"
    else
        echo -e "  Fcitx5: ${YELLOW}未运行${NC}"
    fi
    
    echo ""
}

# 主函数
main() {
    while true; do
        show_menu
        read -p "请选择 [0-7]: " choice
        
        case $choice in
            1)
                # 完整安装
                clear
                echo -e "${GREEN}"
                cat << 'EOF'
╔═══════════════════════════════════════════╗
║   开始完整安装                            ║
╚═══════════════════════════════════════════╝
EOF
                echo -e "${NC}"
                
                check_root
                check_sudo
                
                fix_locale
                install_oh_my_zsh
                install_zsh_plugins
                install_terminal_tools
                configure_chinese_input
                configure_fastfetch
                configure_kitty
                backup_config
                generate_zshrc
                set_default_shell
                
                finish_installation
                
                echo ""
                read -p "按 Enter 返回菜单..."
                ;;
            2)
                install_modern_cli_tools
                echo ""
                read -p "按 Enter 返回菜单..."
                ;;
            3)
                install_zsh_theme_menu
                echo ""
                read -p "按 Enter 返回菜单..."
                ;;
            4)
                # 修复 Shell 配置
                print_header "修复 Shell 配置"
                bash "$(dirname "$0")/fix-shell-config.sh" || print_warning "请确保 fix-shell-config.sh 存在"
                echo ""
                read -p "按 Enter 返回菜单..."
                ;;
            5)
                configure_chinese_input
                echo ""
                read -p "按 Enter 返回菜单..."
                ;;
            6)
                configure_fastfetch
                echo ""
                read -p "按 Enter 返回菜单..."
                ;;
            7)
                check_shell_status
                echo ""
                read -p "按 Enter 返回菜单..."
                ;;
            8)
                # 修复 Chrome 中文输入
                print_header "修复 Chrome 中文输入"
                bash "$(dirname "$0")/fix-chrome-input.sh" || print_warning "请确保 fix-chrome-input.sh 存在"
                echo ""
                read -p "按 Enter 返回菜单..."
                ;;
            9)
                generate_ssh_key
                echo ""
                read -p "按 Enter 返回菜单..."
                ;;
            10)
                show_system_info
                echo ""
                read -p "按 Enter 返回菜单..."
                ;;
            0)
                echo -e "${GREEN}再见！${NC}"
                exit 0
                ;;
            *)
                print_error "无效选项"
                sleep 2
                ;;
        esac
    done
}

# 运行主函数
main "$@"
