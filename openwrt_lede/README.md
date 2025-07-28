# LEDE固件编译工具

这个目录包含了用于编译LEDE固件的自动化脚本和配置文件。

## 文件结构

```
openwrt_lede/
├── lede_build.sh          # 主编译脚本
├── r68s_auto.sh           # 原有的R68S编译脚本
├── x86_auto.sh            # 原有的X86编译脚本
├── configs/               # 配置文件目录
│   ├── r68s.config        # R68S设备配置
│   └── x86.config         # X86设备配置
└── README.md              # 本说明文件
```

## 使用方法

### 1. 本地编译

#### 基本使用
```bash
# 进入脚本目录
cd openwrt_lede

# 给脚本执行权限
chmod +x lede_build.sh

# 编译R68S固件（默认配置）
./lede_build.sh

# 编译X86固件
./lede_build.sh -d x86
```

#### 高级使用
```bash
# 自定义所有参数
./lede_build.sh -d r68s -k 6.6 -i 192.168.1.180 -n my-router -j 4

# 使用自定义编译目录（解决磁盘空间不足问题）
./lede_build.sh -d r68s --build-dir /home/build

# 清理编译环境
./lede_build.sh -d r68s --clean

# 编译并准备上传信息
./lede_build.sh -d r68s --upload

# 查看帮助信息
./lede_build.sh --help
```

#### 参数说明
- `-d, --device`: 设备型号 (r68s, x86)
- `-k, --kernel`: 内核版本 (默认: 6.6)
- `-i, --ip`: 默认IP地址 (默认: 192.168.1.180)
- `-n, --hostname`: 主机名 (默认: lede-router)
- `-j, --jobs`: 编译线程数 (默认: CPU核心数)
- `-b, --build-dir`: 编译目录 (默认: /mnt)
- `-c, --clean`: 清理编译环境
- `-u, --upload`: 生成上传信息
- `-h, --help`: 显示帮助

### 2. GitHub Actions自动编译

#### 触发编译
1. 进入GitHub仓库的Actions页面
2. 选择"LEDE Firmware Build"工作流
3. 点击"Run workflow"
4. 选择编译参数：
   - 设备型号: r68s 或 x86
   - 内核版本: 默认6.6
   - 默认IP: 默认192.168.1.180
   - 主机名: 默认lede-router
   - 编译目录: 默认/mnt（推荐使用大容量磁盘）
   - 是否清理编译: 可选
5. 点击"Run workflow"开始编译

#### 获取固件
编译完成后，固件会自动上传到GitHub Releases，包含：
- 固件文件 (.img, .bin等)
- 编译信息和使用说明
- 文件大小和列表

## 配置文件

### 自定义配置
1. 在本地运行 `make menuconfig` 生成配置
2. 将生成的 `.config` 文件复制到 `configs/` 目录
3. 重命名为对应的设备名称 (如 `r68s.config`)

### 配置文件说明
- `configs/r68s.config`: R68S设备的编译配置
- `configs/x86.config`: X86设备的编译配置

这些配置文件包含了设备特定的内核配置、驱动选择、软件包等设置。

## 支持的设备

### R68S
- 架构: ARM64 (aarch64)
- 平台: Rockchip RK3568
- 默认IP: 192.168.1.180
- 内核版本: 6.6

### X86
- 架构: x86_64
- 平台: 通用PC
- 默认IP: 192.168.1.181
- 支持UEFI和Legacy启动

## 包含的插件

编译的固件默认包含以下插件和功能：

- **基础功能**: LuCI管理界面、防火墙、DHCP服务
- **网络工具**: PassWall2、HelloWorld、iStore
- **系统工具**: htop、vim、wget、curl等
- **文件系统**: 支持ext4、NTFS、exFAT等
- **USB支持**: USB 2.0/3.0存储设备

## 编译环境要求

### 系统要求
- Ubuntu 18.04+ 或 Debian 10+
- 至少20GB可用磁盘空间（推荐使用/mnt等大容量目录）
- 4GB以上内存
- 稳定的网络连接

### 磁盘空间说明
- 默认编译目录设置为 `/mnt`，通常具有更大的磁盘空间
- 如果 `/mnt` 不可用，可以使用 `-b` 参数指定其他大容量目录
- 编译过程需要大量临时文件，确保编译目录有足够空间

### 依赖包
脚本会自动安装所需的依赖包，包括：
- 编译工具链 (gcc, make, cmake等)
- 开发库 (libssl-dev, zlib1g-dev等)
- 辅助工具 (git, wget, curl等)

## 故障排除

### 常见问题

1. **编译失败**
   - 检查磁盘空间是否充足
   - 确保网络连接稳定
   - 尝试使用 `-c` 参数清理后重新编译

2. **配置文件错误**
   - 检查 `configs/` 目录下是否有对应的配置文件
   - 确保配置文件格式正确

3. **权限问题**
   - 确保脚本有执行权限: `chmod +x lede_build.sh`
   - 某些操作需要sudo权限

### 调试模式
如果编译失败，可以查看详细日志：
```bash
# 单线程编译并显示详细信息
./lede_build.sh -d r68s -j 1
```

## 更新和维护

### 更新源码
脚本会自动更新LEDE源码，也可以手动更新：
```bash
cd lede
git pull
```

### 更新feeds
```bash
cd lede
./scripts/feeds update -a
./scripts/feeds install -a
```

## 贡献

欢迎提交Issue和Pull Request来改进这个编译工具。

## 许可证

本项目遵循与LEDE项目相同的开源许可证。