#!/bin/bash
# ZeroTier Minimal Backup Script - 只备份关键文件，使用固定文件名
# Usage: ./zerotier-minimal-backup.sh [backup_directory]

# 默认备份位置是当前目录
BACKUP_DIR=${1:-$(pwd)}
BACKUP_FILE="$BACKUP_DIR/zerotier-backup.tar.gz"

# 检查root权限
if [ "$EUID" -ne 0 ]; then
  echo "请使用root权限运行此脚本"
  exit 1
fi

# 检查ZeroTier是否安装
if [ ! -d "/var/lib/zerotier-one" ]; then
  echo "未找到ZeroTier安装"
  exit 1
fi

# 创建临时目录
TMP_DIR=$(mktemp -d)

# 仅复制重要的配置文件
echo "正在备份关键ZeroTier文件..."
cp -r /var/lib/zerotier-one/identity.public "$TMP_DIR"
cp -r /var/lib/zerotier-one/identity.secret "$TMP_DIR"
mkdir -p "$TMP_DIR/networks.d"
cp -r /var/lib/zerotier-one/networks.d/* "$TMP_DIR/networks.d/" 2>/dev/null

# 创建备份归档
echo "创建备份文件：$BACKUP_FILE..."
tar -czf "$BACKUP_FILE" -C "$TMP_DIR" .

# 清理
rm -rf "$TMP_DIR"

echo "备份完成！"
echo "备份保存于: $BACKUP_FILE"
