# autorun5.0

一套适用于 GPU 服务器的自动化安装脚本，默认放在普通用户 `$HOME/autorun5.0/` 下运行。

## 脚本说明

- `pre.sh`：检测外网连通性，替换 apt 源、安装常用工具、黑名单 nouveau、更新 grub，并为后续 GPU 驱动安装做准备。
- `setup.sh`：使用 `dialog` 呈现菜单，可按需安装 NVIDIA 驱动、CUDA、cuDNN，以及 Anaconda（可选的 PyTorch/TF 环境）。
- `sources.list` / `blacklist-nouveau.conf`：供 `pre.sh` 写入系统的参考配置。

## 使用示例

```bash
cd ~/autorun5.0
sudo bash pre.sh          # 先处理软件源和基础依赖
sudo bash setup.sh        # 打开菜单选择安装组合
```

请先把驱动、CUDA、cuDNN、Anaconda 安装包下载到当前用户家目录，脚本会在安装前进行检测。
