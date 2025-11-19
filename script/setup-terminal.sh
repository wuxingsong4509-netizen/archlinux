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
    print_header "6. 生成.zshrc配置"
    
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
eval "$(zoxide init zsh)"
alias cd='z'

# thefuck 设置（命令纠错）
eval $(thefuck --alias)
eval $(thefuck --alias fk)

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
    print_header "7. 设置默认Shell"
    
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
    echo "  • fastfetch - 系统信息"
    
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
    echo "  1. 运行: ${GREEN}zsh${NC} 切换到zsh"
    echo "  2. 或注销并重新登录"
    echo "  3. 享受您的新终端环境！"
    
    echo -e "\n${BLUE}常用命令：${NC}"
    echo "  • ${GREEN}ll${NC} - 查看文件列表"
    echo "  • ${GREEN}cat file${NC} - 语法高亮查看文件"
    echo "  • ${GREEN}lg${NC} - 启动lazygit"
    echo "  • ${GREEN}Ctrl+R${NC} - 搜索历史命令"
    echo "  • ${GREEN}fuck${NC} - 纠正上一条错误命令"
    
    echo -e "\n${YELLOW}配置文件位置：${NC}"
    echo "  • ~/.zshrc"
    echo "  • 使用 ${GREEN}zshconfig${NC} 编辑配置"
    echo "  • 使用 ${GREEN}zshreload${NC} 重载配置"
    
    echo ""
}

# 主函数
main() {
    clear
    echo -e "${GREEN}"
    cat << 'EOF'
╔═══════════════════════════════════════════╗
║   终端环境一键配置脚本                    ║
║   Arch Linux                              ║
╚═══════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    check_root
    check_sudo
    
    fix_locale
    install_oh_my_zsh
    install_zsh_plugins
    install_terminal_tools
    configure_kitty
    backup_config
    generate_zshrc
    set_default_shell
    
    finish_installation
}

# 运行主函数
main "$@"
