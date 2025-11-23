#!/bin/bash

# ============================================
# 修复 Shell 配置冲突脚本
# ============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}   修复 Shell 配置冲突${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# 检查当前 shell
CURRENT_SHELL=$(basename "$SHELL")
print_info "当前 shell: $CURRENT_SHELL"

# 检查是否安装了 zsh
if ! command -v zsh &> /dev/null; then
    print_warning "zsh 未安装"
    read -p "是否安装 zsh？[y/N]: " install_zsh
    if [[ $install_zsh =~ ^[Yy]$ ]]; then
        print_info "安装 zsh..."
        sudo pacman -S --noconfirm zsh
        print_success "zsh 已安装"
    fi
fi

# 清理 bashrc 中的 zsh 配置
print_info "检查 .bashrc 配置..."
if [ -f "$HOME/.bashrc" ]; then
    # 备份
    cp "$HOME/.bashrc" "$HOME/.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
    
    # 移除 zsh 特有的配置
    if grep -q "oh-my-zsh\|setopt\|ZSH_THEME" "$HOME/.bashrc"; then
        print_warning "在 .bashrc 中发现 zsh 配置，正在移除..."
        sed -i '/oh-my-zsh/d' "$HOME/.bashrc"
        sed -i '/setopt/d' "$HOME/.bashrc"
        sed -i '/ZSH_THEME/d' "$HOME/.bashrc"
        sed -i '/ZSH_CUSTOM/d' "$HOME/.bashrc"
        print_success "已清理 .bashrc"
    else
        print_success ".bashrc 配置正常"
    fi
fi

# 修复 zoxide 配置
print_info "修复 zoxide 配置..."
if command -v zoxide &> /dev/null; then
    # 从 .bashrc 移除错误的 zoxide 配置
    if [ -f "$HOME/.bashrc" ]; then
        sed -i '/eval "$(zoxide init zsh)"/d' "$HOME/.bashrc"
        
        # 检查是否已有正确配置
        if ! grep -q 'eval "$(zoxide init bash)"' "$HOME/.bashrc"; then
            cat >> "$HOME/.bashrc" << 'EOF'

# zoxide - 智能 cd
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init bash)"
    alias cd='z'
fi
EOF
            print_success "已添加 bash 版本的 zoxide 配置"
        fi
    fi
    
    # 确保 .zshrc 有正确配置
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q 'eval "$(zoxide init zsh)"' "$HOME/.zshrc"; then
            cat >> "$HOME/.zshrc" << 'EOF'

# zoxide - 智能 cd
eval "$(zoxide init zsh)"
alias cd='z'
EOF
            print_success "已添加 zsh 版本的 zoxide 配置到 .zshrc"
        fi
    fi
fi

# 询问是否切换到 zsh
if [ "$CURRENT_SHELL" = "bash" ] && [ -f "$HOME/.zshrc" ]; then
    echo ""
    print_warning "检测到你有 .zshrc 配置但当前使用 bash"
    read -p "是否切换默认 shell 到 zsh？[y/N]: " switch_shell
    
    if [[ $switch_shell =~ ^[Yy]$ ]]; then
        if command -v zsh &> /dev/null; then
            print_info "切换默认 shell 到 zsh..."
            chsh -s $(which zsh)
            print_success "默认 shell 已设置为 zsh"
            print_warning "请注销并重新登录使更改生效"
        else
            print_error "zsh 未安装，无法切换"
        fi
    fi
fi

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}   ✓ 修复完成！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${BLUE}下一步：${NC}"
if [ "$CURRENT_SHELL" = "bash" ]; then
    echo -e "  1. 运行 ${GREEN}source ~/.bashrc${NC} 重载 bash 配置"
    echo -e "  2. 或运行 ${GREEN}zsh${NC} 临时切换到 zsh"
    if [[ $switch_shell =~ ^[Yy]$ ]]; then
        echo -e "  3. ${YELLOW}注销并重新登录${NC}使 zsh 成为默认 shell"
    fi
else
    echo -e "  1. 运行 ${GREEN}source ~/.zshrc${NC} 重载 zsh 配置"
fi
echo ""
