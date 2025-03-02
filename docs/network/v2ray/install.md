<!--
 * @Author: findnr
 * @Date: 2025-01-23 10:24:39
 * @LastEditors: findnr
 * @LastEditTime: 2025-01-23 10:24:39
 * @Description: v2ray配置指南
-->

# V2Ray通过FRP内网穿透实现代理服务

## 环境准备
- 公网服务器（frp服务端）：已安装frp，需要有固定公网IP
- 美国Ubuntu服务器（无公网）：需要安装frp客户端和v2ray服务端
- 中国Windows 11（客户端）：需要安装v2ray客户端

## 方案优势
- 无需美国服务器拥有公网IP
- 通过frp内网穿透技术实现安全连接
- 支持多客户端同时连接
- 配置灵活，易于维护

#### 配置步骤

##### 1. 公网服务器配置（frp服务端）
- 编辑frps.toml配置文件：
```toml
[common]
bindPort = 7000
# 用于验证客户端的token
token = "your_secure_token"
```

##### 2. 美国Ubuntu服务器配置

###### 2.1 安装v2ray
```bash
# 下载v2ray安装脚本
curl -O https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh

# 安装v2ray
bash install-release.sh
```

###### 2.2 配置v2ray
- 编辑 /usr/local/etc/v2ray/config.json：
```json
{
  "inbounds": [{
    "port": 10086,
    "protocol": "vmess",
    "settings": {
      "clients": [{
        "id": "your-uuid-here",
        "alterId": 0
      }]
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  }]
}
```

###### 2.3 配置frp客户端
- 编辑frpc.toml：
```toml
[common]
server_addr = "公网服务器IP"
server_port = 7000
token = "your_secure_token"

[v2ray_tcp]
type = "tcp"
local_ip = "127.0.0.1"
local_port = 10086
remote_port = 10087
```

##### 3. 中国Windows客户端配置

###### 3.1 下载安装v2ray
- 从 https://github.com/v2fly/v2ray-core/releases 下载最新版本
- 解压到本地目录

###### 3.2 配置v2ray客户端
- 编辑config.json：
```json
{
  "inbounds": [{
    "port": 1080,
    "protocol": "socks",
    "settings": {
      "udp": true
    }
  }],
  "outbounds": [{
    "protocol": "vmess",
    "settings": {
      "vnext": [{
        "address": "公网服务器IP",
        "port": 10087,
        "users": [{
          "id": "your-uuid-here",
          "alterId": 0
        }]
      }]
    }
  }]
}
```

#### 启动服务

##### 公网服务器
```bash
systemctl start frps
systemctl enable frps
```

##### 美国Ubuntu服务器
```bash
systemctl start v2ray
systemctl enable v2ray
systemctl start frpc
systemctl enable frpc
```

##### Windows客户端
- 运行v2ray.exe启动服务
- 配置浏览器或系统代理使用socks5://127.0.0.1:1080

#### 验证配置
1. 确保所有服务都正常运行
2. 在Windows客户端访问 https://www.google.com 测试代理是否正常工作
3. 使用在线IP查询工具验证是否显示美国IP地址

#### UUID生成和端口说明
1. UUID生成方法：
   ```bash
   # Linux系统使用命令生成UUID
   cat /proc/sys/kernel/random/uuid
   
   # 或者访问在线UUID生成网站
   # https://www.uuidgenerator.net/
   ```

2. 端口使用说明：
   - frps服务端口：7000（可自定义）
   - v2ray服务端口：10086（本地监听）
   - frp转发端口：10087（远程访问）
   - v2ray客户端socks端口：1080（本地代理）

#### 故障排查指南
1. 连接失败检查：
   - 确认所有服务状态：`systemctl status frps/frpc/v2ray`
   - 检查端口监听：`netstat -tlnp | grep -E "7000|10086|10087"`
   - 查看服务日志：`journalctl -u v2ray -f`

2. 性能优化：
   - 建议使用TCP BBR拥塞控制算法
   - 适当调整MTU值优化传输性能
   - 配置合理的路由规则避免国内流量走代理

#### 安全建议
1. 请确保修改所有示例中的占位符（如token、uuid等）为您自己的安全值
2. 防火墙配置：
   - 仅开放必要端口
   - 建议使用UFW或iptables限制IP访问
   - 定期检查服务器安全日志
3. 建议使用强密码和安全的UUID
4. 定期更新：
   - 及时更新v2ray到最新版本
   - 保持frp服务端和客户端版本一致
   - 定期更新系统安全补丁

#### 维护建议
1. 定期备份配置文件
2. 监控服务器资源使用情况
3. 建立日志轮转机制避免占用过多磁盘空间
4. 配置服务器监控告警及时发现异常