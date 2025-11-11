#!/bin/bash

shver=autorun5.0
name=$(whoami)
PATH1=/home/$name


echo '外网使用情况如下：'
if ping -c4 www.baidu.com &>/dev/null
then
    echo '已通网'
	sudo cp  /etc/apt/sources.list /etc/apt/sources.list.bak
	sudo cp  $PATH1/$shver/sources.list /etc/apt/
	sudo sed -i "s/bionic/`lsb_release -c --short`/" /etc/apt/sources.list
	sudo apt update -y 
	sudo apt install vim ssh dkms dialog htop stress memtester lm-sensors ipmitool -y 
	sudo apt upgrade -y 
	sudo cp -f $PATH1/$shver/blacklist-nouveau.conf /etc/modprobe.d/
	sudo update-initramfs -u

	sudo sed -i 's/splash/& nomodeset/' /etc/default/grub
	sudo update-grub
	sudo sed -i 's/1/0/g' /etc/apt/apt.conf.d/10periodic 
	sudo sed -i 's/1/0/g' /etc/apt/apt.conf.d/20auto-upgrades
	sudo reboot
else
    echo '断网状态，请检查网络及设备连接情况'
	exit

fi


