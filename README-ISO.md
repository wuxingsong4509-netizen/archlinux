# 自定义 Arch Linux ISO 构建指南

## 概述

此项目可以将您的 Arch Linux 配置打包成标准安装 ISO，包含：
- fcitx5 中文输入法预配置
- Chrome 浏览器输入法支持（X11 模式）
- 常用开发工具和中文字体
- 自动配置脚本

## 快速开始

### 构建 ISO

```bash
cd archlinux-main
sudo ./build-iso.sh
```

构建时间：10-30 分钟  
输出位置：`~/iso-output/customarch-YYYYMMDD.iso`

### 前置要求

- 运行 Arch Linux 系统
- 至少 5GB 可用磁盘空间
- Root 权限

## ISO 包含内容

### 预装软件包

**输入法系统：**
- fcitx5（主程序）
- fcitx5-chinese-addons（中文输入法）
- fcitx5-configtool（配置工具）
- fcitx5-gtk & fcitx5-qt（应用支持）
- fcitx5-rime（Rime 输入法引擎）

**浏览器：**
- Firefox（预装）
- Google Chrome（需手动安装）

**开发工具：**
- git, base-devel
- vim, neovim

**系统工具：**
- wget, curl, htop, tmux

**字体：**
- Noto 字体（包括中日韩字体和 Emoji）

### 配置脚本

ISO 中包含以下脚本（位于 `/root/`）：

1. **setup-terminal.sh** - fcitx5 自动配置
   - 设置环境变量
   - 配置 bash/zsh
   - 配置 Chrome X11 模式

2. **post-install.sh** - 安装后运行
   - 调用 setup-terminal.sh
   - 启用桌面服务（如果已安装）

3. **README.txt** - 使用说明
4. **INSTALL-GUIDE.txt** - 详细安装指南

## 使用 ISO

### 1. 制作启动盘

**Linux:**
```bash
sudo dd if=~/iso-output/customarch-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

**Windows:**
- 使用 Rufus 或 balenaEtcher

**通用方案（推荐）:**
- 使用 Ventoy（支持多 ISO 启动）

### 2. 安装系统

1. 从 USB 启动
2. 联网（WiFi 使用 `iwctl`）
3. 分区（`cfdisk /dev/sdX`）
4. 格式化并挂载
5. 运行 `pacstrap /mnt base linux linux-firmware`
6. 配置系统（详见 ISO 中的 INSTALL-GUIDE.txt）
7. 安装引导程序（GRUB 或 systemd-boot）
8. 重启

### 3. 安装后配置

首次启动后：

```bash
# 运行自动配置脚本
sudo bash /root/post-install.sh

# 重新登录
logout
```

### 4. 验证中文输入法

1. 打开任意文本编辑器或浏览器
2. 按 `Ctrl+Space` 切换输入法
3. 应该能看到 fcitx5 输入法面板
4. 可以输入中文

## 自定义 ISO

### 添加软件包

编辑 `build-iso.sh`，在 `packages.x86_64` 部分添加：

```bash
cat >> "$PROFILE_DIR/packages.x86_64" << 'EOF'
package-name-1
package-name-2
EOF
```

### 添加桌面环境

取消注释 `build-iso.sh` 中的相应行：

```bash
# Desktop Environment
xorg
plasma-meta    # KDE Plasma
sddm           # 显示管理器
```

或选择其他桌面：
```bash
gnome          # GNOME
gdm            # GNOME 显示管理器
```

### 包含自定义配置文件

在脚本中添加：

```bash
# 复制配置到用户骨架目录
cp your-config-file "$AIROOTFS/etc/skel/.config/"
```

### 添加自定义脚本

```bash
# 复制脚本到 root
cp your-script.sh "$AIROOTFS/root/"
chmod +x "$AIROOTFS/root/your-script.sh"
```

## 故障排除

### 构建失败

**问题：空间不足**
```
error: could not extract ... (Write failed)
```

**解决：**
- 检查磁盘空间：`df -h ~`
- 清理旧构建：`rm -rf ~/archiso-build`
- 确保至少有 5GB 可用空间

**问题：包下载失败**
```
error: failed retrieving file
```

**解决：**
- 更新镜像列表：`sudo reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist`
- 检查网络连接
- 重试构建

### 输入法问题

**问题：安装后无法切换输入法**

**解决：**
```bash
# 检查 fcitx5 是否运行
ps aux | grep fcitx5

# 重启 fcitx5
fcitx5 -r

# 检查环境变量
env | grep -E "GTK_IM_MODULE|QT_IM_MODULE|XMODIFIERS"

# 重新运行配置
bash /root/setup-terminal.sh
```

**问题：Chrome 中无法输入中文**

**解决：**
```bash
# 检查 Chrome 配置
cat ~/.config/chrome-flags.conf

# 应该包含：
# --ozone-platform=x11
# --enable-features=UseOzonePlatform

# 完全关闭并重启 Chrome
killall chrome
google-chrome-stable
```

### ISO 启动问题

**问题：UEFI 无法启动**

- 确保 BIOS 中启用了 UEFI 模式
- 关闭 Secure Boot
- 尝试不同的启动模式

**问题：显示问题**

在启动菜单添加内核参数：
```
nomodeset
或
nouveau.modeset=0  # NVIDIA 显卡
```

## 技术细节

### 构建流程

1. 检查并安装 archiso 工具
2. 创建构建目录（`~/archiso-build/`）
3. 复制官方 releng 配置模板
4. 自定义软件包列表
5. 添加配置脚本到 airootfs
6. 配置 profiledef.sh
7. 运行 mkarchiso 构建
8. 输出 ISO 到 `~/iso-output/`

### 目录结构

```
~/archiso-build/custom-archiso/profile/
├── airootfs/              # ISO 中包含的文件
│   ├── root/
│   │   ├── setup-terminal.sh
│   │   ├── post-install.sh
│   │   ├── README.txt
│   │   └── INSTALL-GUIDE.txt
│   └── etc/
│       └── skel/          # 新用户默认配置
├── packages.x86_64        # 软件包列表
├── profiledef.sh          # ISO 配置
└── pacman.conf            # Pacman 配置
```

### 空间需求

- 构建目录：约 3-4 GB
- 最终 ISO：约 800 MB - 1.5 GB
- 推荐可用空间：5 GB+

## 进阶功能

### 创建自动安装 ISO

添加预配置的安装脚本：

```bash
cat > "$AIROOTFS/root/auto-install.sh" << 'EOF'
#!/bin/bash
# 自动分区、格式化、安装
# 警告：会清空磁盘！
EOF
```

### 集成 AUR 包

1. 预先构建 AUR 包：
```bash
git clone https://aur.archlinux.org/package-name.git
cd package-name
makepkg -s
```

2. 创建本地仓库：
```bash
repo-add custom.db.tar.gz *.pkg.tar.zst
```

3. 在 profiledef.sh 中添加仓库配置

### 多语言支持

在 packages.x86_64 中添加：
```
noto-fonts-cjk
noto-fonts-emoji
ttf-liberation
```

## 相关资源

- [Arch Wiki - archiso](https://wiki.archlinux.org/title/Archiso)
- [Arch Wiki - fcitx5](https://wiki.archlinux.org/title/Fcitx5)
- [Arch 安装指南](https://wiki.archlinux.org/title/Installation_guide)
- [Arch 通用指南](https://wiki.archlinux.org/title/General_recommendations)

## 更新日志

### 2024-11-23
- 添加 ISO 构建功能
- 集成 fcitx5 自动配置
- 添加 Chrome X11 模式支持
- 添加详细安装指南

## 许可证

本项目基于 Arch Linux 和 archiso，遵循相应的开源许可证。

## 贡献

欢迎提交 Issue 和 Pull Request！
