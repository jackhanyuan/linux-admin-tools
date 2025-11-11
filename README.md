# linux-admin-tools

个人常用的 Linux 管理脚本集合，涵盖服务器装机、批量建号、GPU 压力测试、系统巡检和挖矿排查等场景。大部分脚本需要 `sudo` 权限。

## 如何获取

```bash
git clone --recursive https://github.com/jackhanyuan/linux-admin-tools.git

# 如果忘记带子模块：
git submodule update --init --recursive
```

## 主要脚本/目录

| 脚本/目录 | 功能简介 |
| --- | --- |
| `autorun5.0/` | 自动化安装 NVIDIA 驱动、CUDA、cuDNN 以及 Anaconda 组件。 |
| `create_users/` | 批量创建/删除用户，批量生成 SSH Key，便于密钥登录。 |
| `gpu-burn/` | GPU 烧机压测工具。 |
| `motd/` | MOTD 信息展示脚本集合。 |
| `check_V5.sh` | 输出系统硬件/驱动/网络/RAID/BMC 等状态，便于巡检。 |
| `mount_V6.sh` | 向导式磁盘挂载脚本，可初始化新盘或挂载现有分区并写入 `/etc/fstab`。 |
| `scan_miner.sh` | 扫描常见挖矿木马文件、cron、服务、环境变量等。 |

## 示例命令

```bash
# 烧机 600 秒
sudo bash gpu-burn/gpu_burn 600

# 自动配置 apt 源并安装依赖
sudo bash autorun5.0/pre.sh

# 运行安装菜单
sudo bash autorun5.0/setup.sh

# 批量创建用户
sudo bash create_users/batch_create_users.sh create_users/user_list.txt

# 批量生成用户密钥并保存私钥到keys目录
sudo bash create_users/gen_user_keys.sh create_users/user_list.txt 

# 删除指定用户
sudo bash create_users/user_del.sh username --remove-home

# 输出系统信息
bash check_V5.sh

# 格式化或挂载新磁盘
sudo bash mount_V6.sh

# 深度 2 的挖矿排查
sudo bash scan_miner.sh 2
```

更多说明见各子目录 README 或脚本开头注释。

## 致谢

- [gpu-burn](https://github.com/wilicc/gpu-burn)
- [motd](https://github.com/yboetz/motd)
