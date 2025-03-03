#!/bin/bash
# ZeroTier Minimal Backup Script - 只备份关键文件，使用固定文件名
# Usage: ./zerotier-minimal-backup.sh [backup_directory]

# 检查expect是否已安装
if ! command -v expect &> /dev/null; then
    echo "正在安装expect..."
    sudo apt-get update
    sudo apt-get install -y expect
fi

# 默认备份位置是当前目录
BACKUP_DIR=${1:-$(pwd)}
BACKUP_FILE="$BACKUP_DIR/zerotier-backup.tar.gz"

# 创建备份脚本
cat > backup_zerotier.sh << EOF
#!/bin/bash

# 设置备份文件路径
BACKUP_FILE="$BACKUP_FILE"

# 检查ZeroTier是否安装
if [ ! -d "/var/lib/zerotier-one" ]; then
  echo "未找到ZeroTier安装"
  exit 1
fi

# 创建临时目录
TMP_DIR=\$(mktemp -d)

# 仅复制重要的配置文件
echo "正在备份关键ZeroTier文件..."
cp -r /var/lib/zerotier-one/identity.public "\$TMP_DIR"
cp -r /var/lib/zerotier-one/identity.secret "\$TMP_DIR"
mkdir -p "\$TMP_DIR/networks.d"
cp -r /var/lib/zerotier-one/networks.d/* "\$TMP_DIR/networks.d/" 2>/dev/null

# 创建备份归档
echo "创建备份文件：\$BACKUP_FILE..."
tar -czf "\$BACKUP_FILE" -C "\$TMP_DIR" .

# 清理
rm -rf "\$TMP_DIR"

echo "备份完成！"
echo "备份保存于: \$BACKUP_FILE"
EOF

# 设置脚本可执行权限
chmod +x backup_zerotier.sh

# 创建expect脚本来以root权限运行backup脚本
cat > run_as_root.exp << EOF
#!/usr/bin/expect -f

set timeout 300

# 使用su切换到root用户
spawn su root -c "./backup_zerotier.sh"
expect "Password:"
send "123456\r"
expect eof
EOF

# 设置expect脚本可执行权限
chmod +x run_as_root.exp

# 运行expect脚本
./run_as_root.exp

# 清理临时脚本
rm -f backup_zerotier.sh run_as_root.exp
