# create_users

批量管理本地用户账号并统一分发 SSH 密钥的小工具集合。

## 脚本简介

- `batch_create_users.sh`：根据列表文件批量建用户。每行格式 `user:group:password:/home/user:/bin/bash`，脚本会自动创建缺失的组并输出日志到 `/var/log/user_batch_create.log`。
- `gen_user_keys.sh`：为单个用户或列表中的所有用户生成 ed25519 密钥对，公钥写入 `~/.ssh/authorized_keys` 并把私钥备份到当前目录的 `keys/<username>`。
- `user_del.sh`：删除指定用户，可加 `--remove-home` 同时删除家目录。
- `keys/`：脚本导出的私钥放在这里，目录默认权限 700，便于统一打包交付。

## 使用示例

```bash
cd create_users
sudo bash batch_create_users.sh user_list.txt
sudo bash gen_user_keys.sh user_list.txt # 批量生成密钥，默认不覆盖已存在的密钥
sudo bash gen_user_keys.sh username --force # -force强制重新生成密钥
sudo bash user_del.sh username --remove-home
```

执行前请确认脚本在具备 `sudo` 权限的环境运行。
