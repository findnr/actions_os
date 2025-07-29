#!/bin/bash
###
# LEDE固件自动编译脚本
# 支持多种设备型号编译
# 使用方法: ./lede_build.sh [设备型号] [选项]
###

# 默认配置
DEVICE_TYPE="r68s"
KERNEL_VERSION="6.6"
DEFAULT_IP="192.168.1.180"
HOSTNAME="lede-router"
BUILD_THREADS=$(nproc)
CLEAN_BUILD=false
UPLOAD_RELEASE=false
BUILD_DIR="/mnt"  # 编译目录，使用/mnt以获得更大磁盘空间

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示帮助信息
show_help() {
    cat << EOF
LEDE固件编译脚本

使用方法:
    $0 [选项] [设备型号]

选项:
    -d, --device DEVICE     设备型号 (默认: r68s)
    -k, --kernel VERSION    内核版本 (默认: 6.6)
    -i, --ip IP_ADDRESS     默认IP地址 (默认: 192.168.1.180)
    -n, --hostname NAME     主机名 (默认: lede-router)
    -j, --jobs THREADS      编译线程数 (默认: $(nproc))
    -b, --build-dir DIR     编译目录 (默认: /mnt)
    -c, --clean             清理编译
    -u, --upload            上传到GitHub Release
    -h, --help              显示此帮助信息

示例:
    $0 -d r68s -k 6.6 -i 192.168.1.180
    $0 --device x86 --clean --upload
    $0 -d r68s -j 4 --hostname my-router
    $0 -d r68s --build-dir /home/build  # 使用自定义编译目录
EOF
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--device)
                DEVICE_TYPE="$2"
                shift 2
                ;;
            -k|--kernel)
                KERNEL_VERSION="$2"
                shift 2
                ;;
            -i|--ip)
                DEFAULT_IP="$2"
                shift 2
                ;;
            -n|--hostname)
                HOSTNAME="$2"
                shift 2
                ;;
            -j|--jobs)
                BUILD_THREADS="$2"
                shift 2
                ;;
            -b|--build-dir)
                BUILD_DIR="$2"
                shift 2
                ;;
            -c|--clean)
                CLEAN_BUILD=true
                shift
                ;;
            -u|--upload)
                UPLOAD_RELEASE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 安装编译依赖
install_dependencies() {
    log_info "安装编译依赖..."
    sudo apt update -y
    sudo apt full-upgrade -y
    sudo apt install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
    bzip2 ccache cmake cpio curl device-tree-compiler fastjar flex gawk gettext gcc-multilib g++-multilib \
    git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libfuse-dev libglib2.0-dev libgmp3-dev \
    libltdl-dev libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev libpython3-dev libreadline-dev \
    libssl-dev libtool lrzsz mkisofs msmtp ninja-build p7zip p7zip-full patch pkgconf python2.7 python3 \
    python3-pyelftools python3-setuptools qemu-utils rsync scons squashfs-tools subversion swig texinfo \
    uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev
}

# 克隆或更新源码
setup_source() {
    log_info "设置LEDE源码..."
    
    # 确保编译目录存在
    if [ ! -d "$BUILD_DIR" ]; then
        log_info "创建编译目录: $BUILD_DIR"
        sudo mkdir -p "$BUILD_DIR"
        sudo chown $(whoami):$(whoami) "$BUILD_DIR"
    fi
    
    # 切换到编译目录
    cd "$BUILD_DIR"
    
    if [ ! -d "lede" ]; then
        log_info "克隆LEDE源码到 $BUILD_DIR/lede..."
        git clone https://github.com/coolsnowwolf/lede.git
    else
        log_info "更新LEDE源码..."
        cd lede
        git pull
        cd ..
    fi
    
    cd lede
    
    if [ "$CLEAN_BUILD" = true ]; then
        log_info "清理编译环境..."
        make clean
        rm -rf .config tmp
    fi
}

# 配置feeds
setup_feeds() {
    log_info "配置feeds..."
    
    # 恢复默认配置
    git restore feeds.conf.default 2>/dev/null || true
    
    # 添加第三方feeds
    cat >> feeds.conf.default << EOF
src-git istore https://github.com/linkease/istore;main
src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;main
src-git passwall2 https://github.com/xiaorouji/openwrt-passwall2.git;main
src-git helloworld https://github.com/fw876/helloworld.git
EOF
    
    ./scripts/feeds update -a
    ./scripts/feeds install -a
}

# 设备特定配置
configure_device() {
    log_info "配置设备: $DEVICE_TYPE"
    
    case $DEVICE_TYPE in
        "r68s")
            configure_r68s
            ;;
        "x86")
            configure_x86
            ;;
        *)
            log_warn "未知设备类型: $DEVICE_TYPE，使用默认配置"
            ;;
    esac
}

# R68S设备配置
configure_r68s() {
    log_info "配置R68S设备..."
    
    # 恢复默认文件
    git restore target/linux/rockchip/Makefile 2>/dev/null || true
    git restore package/base-files/files/bin/config_generate 2>/dev/null || true
    
    # 修改内核版本
    sed -i "s/KERNEL_PATCHVER:=6.1/KERNEL_PATCHVER:=$KERNEL_VERSION/g" target/linux/rockchip/Makefile
    
    # 修改默认IP
    sed -i "s/192.168.1.1/$DEFAULT_IP/g" package/base-files/files/bin/config_generate
    sed -i "/set network.\$1.proto='static'/{s/$/\n\t\t\t\tset network.\$1.gateway='192.168.1.1'/}" package/base-files/files/bin/config_generate
    sed -i "/set network.\$1.proto='static'/{s/$/\n\t\t\t\tset network.\$1.dns='223.5.5.5 192.168.1.1'/}" package/base-files/files/bin/config_generate
    
    # 修改主机名
    sed -i "/uci commit system/i\uci set system.@system[0].hostname='$HOSTNAME'" package/lean/default-settings/files/zzz-default-settings
    
    # 加入编译信息
    sed -i "s/OpenWrt /$HOSTNAME build $(TZ=UTC-8 date "+%Y.%m.%d") @ OpenWrt /g" package/lean/default-settings/files/zzz-default-settings
    
    # 使用R68S配置文件
    # 获取原始脚本目录（不是当前工作目录）
    ORIGINAL_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CONFIG_FILE="$ORIGINAL_SCRIPT_DIR/configs/r68s.config"
    
    if [ -f "$CONFIG_FILE" ]; then
        log_info "使用配置文件: $CONFIG_FILE"
        cp "$CONFIG_FILE" .config
    else
        log_warn "未找到R68S配置文件: $CONFIG_FILE，请手动配置"
        make menuconfig
    fi
}

# X86设备配置
configure_x86() {
    log_info "配置X86设备..."
    
    # 修改默认IP
    sed -i "s/192.168.1.1/$DEFAULT_IP/g" package/base-files/files/bin/config_generate
    
    # 修改主机名
    sed -i "/uci commit system/i\uci set system.@system[0].hostname='$HOSTNAME'" package/lean/default-settings/files/zzz-default-settings
    
    # 使用X86配置文件
    # 获取原始脚本目录（不是当前工作目录）
    ORIGINAL_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CONFIG_FILE="$ORIGINAL_SCRIPT_DIR/configs/x86.config"
    
    if [ -f "$CONFIG_FILE" ]; then
        log_info "使用配置文件: $CONFIG_FILE"
        cp "$CONFIG_FILE" .config
    else
        log_warn "未找到X86配置文件: $CONFIG_FILE，请手动配置"
        make menuconfig
    fi
}

# 编译固件
build_firmware() {
    log_info "开始编译固件 (使用 $BUILD_THREADS 线程)..."
    
    # 生成配置
    make defconfig
    
    # 下载源码包
    log_info "下载源码包..."
    make download -j8
    
    # 编译
    log_info "编译固件..."
    make -j$BUILD_THREADS || {
        log_warn "多线程编译失败，尝试单线程编译..."
        make -j1 V=s
    }
    
    if [ $? -eq 0 ]; then
        log_info "编译成功！"
        log_info "固件位置: bin/targets/"
        ls -la bin/targets/*/*
    else
        log_error "编译失败！"
        exit 1
    fi
}

# 上传到GitHub Release
upload_release() {
    if [ "$UPLOAD_RELEASE" = true ]; then
        log_info "准备上传到GitHub Release..."
        
        # 生成发布信息
        RELEASE_TAG="$DEVICE_TYPE-$(date +"%Y.%m.%d-%H%M")"
        
        cat > release_info.txt << EOF
## LEDE $DEVICE_TYPE 固件信息

- 设备型号: $DEVICE_TYPE
- 编译时间: $(date '+%Y-%m-%d %H:%M:%S')
- 内核版本: $KERNEL_VERSION
- 默认IP: $DEFAULT_IP
- 主机名: $HOSTNAME
- 默认用户名: root
- 默认密码: password
- 包含插件: PassWall2, iStore, HelloWorld等

### 使用说明
1. 下载对应的固件文件
2. 使用刷机工具刷入设备
3. 首次启动后访问 http://$DEFAULT_IP
EOF
        
        log_info "发布标签: $RELEASE_TAG"
        log_info "发布信息已生成: release_info.txt"
        
        # 这里可以添加实际的上传逻辑
        # 例如使用 gh cli 或者在 GitHub Actions 中处理
    fi
}

# 主函数
main() {
    log_info "LEDE固件编译脚本启动"
    log_info "设备: $DEVICE_TYPE, 内核: $KERNEL_VERSION, IP: $DEFAULT_IP"
    log_info "编译目录: $BUILD_DIR"
    
    parse_args "$@"
    
    install_dependencies
    setup_source
    setup_feeds
    configure_device
    build_firmware
    upload_release
    
    log_info "编译完成！"
}

# 执行主函数
main "$@"