#!/bin/bash

# 显示可用设备及分区信息
echo "+-----------------------------------------------------+"
echo "|               设备选择 (支持双系统挂载)              |"
echo "+-----------------------------------------------------+"
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT | grep -Ev 'loop|sr0|rom'
echo "+-----------------------------------------------------+"

# 提示用户输入设备/分区标识
read -p "请选择操作类型：
1. 挂载整个新磁盘（自动分区为ext4，适用于Linux单系统）
2. 挂载现有分区（支持Windows NTFS双系统）
请输入数字选择: " operation_type

case $operation_type in
1)
    # 选项1：挂载整个新磁盘（自动创建GPT分区）
    read -p "请输入磁盘基础盘符（如sdb/nvme0n1）: " base_device

    # 校验输入格式
    if [[ ! $base_device =~ ^(sd[a-z]$|nvme[0-9]{1,2}n1$) ]]; then
        echo "错误：无效的磁盘盘符格式！"
        exit 1
    fi

    device="/dev/$base_device"

    # 检查设备是否存在
    if [[ ! -e $device ]]; then
        echo "错误：设备 $device 不存在！"
        exit 1
    fi

    # 卸载已挂载设备
    if mount | grep -q $device; then
        echo "检测到设备已挂载，正在卸载..."
        sudo umount $device*
    fi

    # 强制转换为GPT分区表
    echo "正在初始化GPT分区表..."
    sudo parted $device --script mklabel gpt
    sudo parted $device --script mkpart primary ext4 0% 100%
    sync
    sleep 2

    # 获取分区路径
    if [[ $base_device =~ nvme ]]; then
        partition="${device}p1"
    else
        partition="${device}1"
    fi

    # 格式化分区
    echo "正在格式化分区 $partition ..."
    sudo mkfs.ext4 -m 0 -O 64bit,has_journal $partition

    # 创建挂载点
    mount_point="/mnt/${base_device}"
    ;;
2)
    # 选项2：挂载现有分区（支持NTFS）
    read -p "请输入分区标识（如sda1/nvme0n1p3）: " partition

    # 校验输入格式
    if [[ ! $partition =~ ^(sd[a-z][0-9]+|nvme[0-9]{1,2}n1p[0-9]+)$ ]]; then
        echo "错误：无效的分区标识格式！"
        exit 1
    fi

    partition="/dev/$partition"
    
    # 检查分区是否存在
    if [[ ! -e $partition ]]; then
        echo "错误：分区 $partition 不存在！"
        exit 1
    fi

    # 获取文件系统类型
    fstype=$(lsblk -no FSTYPE $partition)
    
    # 创建类型专属挂载点
    case $fstype in
    ntfs)
        mount_point="/mnt/$(basename $partition)" ;;
    ext4)
        mount_point="/mnt/$(basename $partition)" ;;
    *)
        mount_point="/mnt/$(basename $partition)" ;;
    esac
    ;;
*)
    echo "无效选项！"
    exit 1
    ;;
esac

# 通用挂载操作
sudo mkdir -p $mount_point

# 更新fstab（根据文件系统类型）
uuid=$(sudo blkid -s UUID -o value $partition)
fstype=$(sudo blkid -s TYPE -o value $partition)

case $fstype in
ntfs)
    echo "UUID=$uuid $mount_point ntfs defaults	0	0" | sudo tee -a /etc/fstab ;;
ext4)
    echo "UUID=$uuid $mount_point ext4 defaults,noatime 0 0" | sudo tee -a /etc/fstab ;;
*)
    echo "UUID=$uuid $mount_point auto defaults 0 0" | sudo tee -a /etc/fstab ;;
esac

# 挂载验证
sudo mount -av | grep $mount_point

# 显示结果
echo
echo "---------------------- 挂载结果验证 ----------------------"
echo "设备信息："
lsblk -o NAME,FSTYPE,LABEL,UUID,MOUNTPOINT $partition
echo
echo "挂载状态："
df -hT $mount_point
echo "---------------------------------------------------------"