#!/bin/bash

# ============================================
# 修复 Chrome/Google 浏览器中文输入问题
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}   修复 Chrome 中文输入${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# 1. 更新系统环境变量
echo -e "${BLUE}[1/5]${NC} 更新系统环境变量..."
sudo mkdir -p /etc/environment.d
sudo tee /etc/environment.d/fcitx5.conf > /dev/null << 'ENVEOF'
GTK_IM_MODULE=fcitx5
QT_IM_MODULE=fcitx5
XMODIFIERS=@im=fcitx5
SDL_IM_MODULE=fcitx5
GLFW_IM_MODULE=ibus
ENVEOF
echo -e "${GREEN}✓${NC} 已更新 /etc/environment.d/fcitx5.conf"

# 2. 更新 ~/.profile
echo -e "${BLUE}[2/5]${NC} 更新用户配置..."
if ! grep -q "export GTK_IM_MODULE=fcitx5" ~/.profile 2>/dev/null; then
    cat >> ~/.profile << 'PROFEOF'

# Fcitx5 输入法
export GTK_IM_MODULE=fcitx5
export QT_IM_MODULE=fcitx5
export XMODIFIERS=@im=fcitx5
export SDL_IM_MODULE=fcitx5
PROFEOF
    echo -e "${GREEN}✓${NC} 已添加到 ~/.profile"
else
    echo -e "${GREEN}✓${NC} ~/.profile 已配置"
fi

# 3. 更新 ~/.zshrc 中的配置
echo -e "${BLUE}[3/5]${NC} 更新 zsh 配置..."
if [ -f ~/.zshrc ]; then
    # 删除旧的 fcitx 配置
    sed -i '/export GTK_IM_MODULE=fcitx$/d' ~/.zshrc
    sed -i '/export QT_IM_MODULE=fcitx$/d' ~/.zshrc
    sed -i '/export XMODIFIERS=@im=fcitx$/d' ~/.zshrc
    
    # 添加新的 fcitx5 配置
    if ! grep -q "export GTK_IM_MODULE=fcitx5" ~/.zshrc; then
        cat >> ~/.zshrc << 'ZSHEOF'

# ============================================
# Fcitx5 输入法
# ============================================
export GTK_IM_MODULE=fcitx5
export QT_IM_MODULE=fcitx5
export XMODIFIERS=@im=fcitx5
export SDL_IM_MODULE=fcitx5
ZSHEOF
        echo -e "${GREEN}✓${NC} 已更新 ~/.zshrc"
    else
        echo -e "${GREEN}✓${NC} ~/.zshrc 已配置"
    fi
fi

# 4. 配置 Chrome 启动参数
echo -e "${BLUE}[4/5]${NC} 配置 Chrome 启动参数..."
CHROME_DESKTOP=""
if [ -f /usr/share/applications/google-chrome.desktop ]; then
    CHROME_DESKTOP="google-chrome.desktop"
elif [ -f /usr/share/applications/chromium.desktop ]; then
    CHROME_DESKTOP="chromium.desktop"
fi

if [ -n "$CHROME_DESKTOP" ]; then
    mkdir -p ~/.local/share/applications
    cp /usr/share/applications/$CHROME_DESKTOP ~/.local/share/applications/
    
    # 修改 Exec 行，添加环境变量
    sed -i 's|^Exec=/usr/bin/|Exec=env GTK_IM_MODULE=fcitx5 QT_IM_MODULE=fcitx5 XMODIFIERS=@im=fcitx5 /usr/bin/|' ~/.local/share/applications/$CHROME_DESKTOP
    
    echo -e "${GREEN}✓${NC} 已配置 $CHROME_DESKTOP"
else
    echo -e "${YELLOW}⚠${NC} 未找到 Chrome/Chromium"
fi

# 5. 重启 fcitx5
echo -e "${BLUE}[5/5]${NC} 重启 fcitx5..."
pkill fcitx5 2>/dev/null
sleep 1
fcitx5 -d 2>/dev/null
sleep 2

if pgrep -x fcitx5 > /dev/null; then
    echo -e "${GREEN}✓${NC} fcitx5 运行正常"
else
    echo -e "${RED}✗${NC} fcitx5 未运行"
fi

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}   ✓ 修复完成${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${YELLOW}重要：请按以下步骤操作${NC}\n"
echo -e "  方法1（推荐）："
echo -e "  1. ${RED}关闭所有 Chrome 窗口${NC}"
echo -e "  2. ${BLUE}注销并重新登录${NC}"
echo -e "  3. 重新打开 Chrome"
echo -e "  4. 按 ${GREEN}Ctrl+Space${NC} 切换中文输入\n"

echo -e "  方法2（快速测试）："
echo -e "  1. ${RED}关闭所有 Chrome 窗口${NC}"
echo -e "  2. 在终端运行："
echo -e "     ${GREEN}google-chrome-stable${NC}"
echo -e "  3. 按 ${GREEN}Ctrl+Space${NC} 测试输入\n"

echo -e "${BLUE}调试信息：${NC}"
echo -e "  当前环境变量："
env | grep -E "GTK_IM|QT_IM|XMODIFIERS" | sed 's/^/    /'
echo ""
