#!/bin/bash
# ZeroTier Minimal Restore Script - 仅还原关键文件，使用固定文件名
# Usage: ./zerotier-minimal-restore.sh [backup_file.tar.gz]

# 使用指定的备份文件或默认名称
BACKUP_FILE=${1:-"zerotier-backup.tar.gz"}

# 检查备份文件是否存在
if [ ! -f "$BACKUP_FILE" ]; then
  echo "错误: 未找到备份文件: $BACKUP_FILE"
  exit 1
fi

# 检查root权限
if [ "$EUID" -ne 0 ]; then
  echo "请使用root权限运行此脚本"
  exit 1
fi

# 创建临时解压目录
TMP_DIR=$(mktemp -d)

# 解压备份文件
echo "解压备份文件..."
tar -xzf "$BACKUP_FILE" -C "$TMP_DIR"

# 检查必要文件是否存在
if [ ! -f "$TMP_DIR/identity.secret" ] || [ ! -f "$TMP_DIR/identity.public" ]; then
  echo "错误: 备份文件中缺少身份文件"
  rm -rf "$TMP_DIR"
  exit 1
fi

# 安装ZeroTier（如果需要）
if ! command -v zerotier-cli &> /dev/null; then
  echo "未找到ZeroTier，正在安装..."
  curl -s https://install.zerotier.com | bash
fi

# 停止ZeroTier服务
echo "停止ZeroTier服务..."
systemctl stop zerotier-one

# 还原配置
echo "还原ZeroTier配置..."
mkdir -p /var/lib/zerotier-one/networks.d

# 删除当前身份文件
rm -f /var/lib/zerotier-one/identity.*
rm -rf /var/lib/zerotier-one/networks.d/*

# 从备份复制文件
cp -f "$TMP_DIR"/identity.* /var/lib/zerotier-one/
if [ -d "$TMP_DIR/networks.d" ]; then
  cp -rf "$TMP_DIR"/networks.d/* /var/lib/zerotier-one/networks.d/ 2>/dev/null
fi

# 设置正确权限
chown -R root:root /var/lib/zerotier-one
chmod 600 /var/lib/zerotier-one/identity.secret

# 重启ZeroTier服务
echo "启动ZeroTier服务..."
systemctl start zerotier-one
sleep 2

# 显示网络信息
echo "还原后的网络信息:"
zerotier-cli status
zerotier-cli listnetworks

# 清理
rm -rf "$TMP_DIR"

echo "ZeroTier配置还原成功！"
