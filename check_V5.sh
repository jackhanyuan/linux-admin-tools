#!/bin/bash

#Check hardware and system configuration.

echo '--------------------------------Check OS and kernel version.-----------------------------------'
echo
cat /etc/os-release |grep '\<NAME' -A2
echo
cat /etc/redhat-release >> /dev/null 2>&1
if [ $? -eq 0 ] 
			then 
cat /etc/redhat-release																	
			else
echo '非redhat系列系统' >> /dev/null
fi
echo
uname -sr
echo
echo '--------------------------------Check motherboard model.---------------------------------------'
echo
sudo dmidecode |grep -A16 "System Information$" |grep '\<Product Name'
echo
sudo dmidecode |grep -A16 "System Information$" |grep -A4 "Base Board Information"
echo

echo '--------------------------------Check BIOS version.--------------------------------------------'
echo
sudo dmidecode -t bios |grep '\<Version' -A 1 
echo

echo '--------------------------------Check CPU model and quantity.----------------------------------'
echo
lscpu |grep '\<Model name' 
lscpu |grep '\<Socket(s)'
echo
echo more information
echo
lscpu |grep Arch -A24
lscpu |grep 架构 -A24
echo
echo '--------------------------------Check memory.--------------------------------------------------'
echo
sudo dmidecode|grep -P -A18 "Memory\s+Device"|grep 'Size\|Locator\|Configured Memory Speed\|Manufacturer'|grep -v Range
echo
free -h
echo
echo '--------------------------------Check hard drive and partitions.-------------------------------'
echo
lsblk|grep -v loop
echo
lspci -nnk |grep -A3 'Non-Volatile memory controller'
echo
sudo lspci | grep "Non-Volatile memory controller" | awk '{print $1}' | xargs -I {} sh -c "echo {}; sudo lspci -vvv -s {} | grep Width"
echo
echo '--------------------------------Check network card.--------------------------------------------'
echo
lspci -nnk | grep -A2 Eth
echo
sudo lspci | grep Ethernet | awk '{print $1}' | xargs -I {} sh -c "echo {}; sudo lspci -vvv -s {} | grep Width"
echo '-----------------------------------------------------------------------------------------------'
echo
lspci -nnk | grep -A3 Infiniband
echo
sudo lspci | grep "Infiniband" | awk '{print $1}' | xargs -I {} sh -c "echo {}; sudo lspci -vvv -s {} | grep Width"
echo '-----------------------------------------------------------------------------------------------'
lspci -nnk | grep -A2 'Network controller'
echo
ip a
echo
lspci|grep -i nvidia 
if [ $? -eq 0 ] 
			then 
echo '--------------------------------Check GPU and driver.------------------------------------------'
echo
nvidia-smi
echo
echo 'check nvlink status' >> /dev/null
echo
nvidia-smi nvlink --status
echo
nvidia-smi -L
echo
nvidia-smi -q |grep -A2 "Link Width"
echo
			else 
				echo '无nvidia显卡' >> /dev/null
fi

output=$(sudo lspci | grep -i lsi | awk '{print $1}' | xargs -I {} sh -c "echo {}; sudo lspci -vvv -s {} | grep Width" )
if [[ -n $output ]]; then
    echo '有安装lsi阵列卡' >> /dev/null
    echo '-------------------------------Check RAID card and RAID 信息-------------------------------------------------'
echo
sudo chmod 777 /usr/bin/storcli64 
sudo storcli64 /c0 show
sudo storcli64 /c1 show
echo
sudo lspci | grep -i lsi | awk '{print $1}' | xargs -I {} sh -c "echo {}; sudo lspci -vvv -s {} | grep Width"
echo
else
    echo '无lsi阵列卡 无需检查此项目' >> /dev/null
fi

sudo dmidecode |grep -A16 "System Information$" |grep '\<Product Name' >> /dev/null
Product_Name=$(sudo dmidecode |grep -A16 "System Information$" |grep '\<Product Name'|head -n 1 | awk -F': ' '{print $2}')
#检查机型是否为SYS-420GP-TNR
if [[ "$Product_Name" == "SYS-420GP-TNR" ]]; then
echo
echo '----------------------------Check ACS信息----------------------------------------------'
echo
	echo '该超微420GP-TNR机型需要在bios里面禁用ACS功能 否则可能出现掉卡情况'
	echo '禁用ACS后下面输出应该全部为 - 号'
	echo
	lspci -vvv |grep -i acsctl
	echo
else
	echo '非超微420GP-TNR机型 无需检查此项目' >> /dev/null
fi

sudo ipmitool sensor list >> /dev/null 2>&1
if [ $? -eq 0 ] 
			then 
echo '----------------------------Check sensors信息----------------------------------------------'
echo
sudo ipmitool sensor list 
echo
echo '----------------------------Check BMC信息----------------------------------------------'
echo
sudo ipmitool user list 1 |grep ID -A5
echo
sudo ipmitool lan print |grep 'IP Address Source' -A3
echo	
			else 
				echo '无bmc' >> /dev/null
fi
echo
echo '--------------------------------Check System Hardware Error.------------------------------------------'
echo
sudo dmesg |grep -i error
echo '--------------------------------END.-----------------------------------------------------------'
echo
echo '*****************************************Summary*****************************************' 
echo																						  
echo '---------------------------------------OS version----------------------------------------'
echo																						  
cat /etc/os-release |grep '\<NAME' -A2|grep 'VERSION' 									
cat /etc/redhat-release >> /dev/null 2>&1
if [ $? -eq 0 ] 
			then 
cat /etc/redhat-release																	
			else
echo '非redhat系列系统' >> /dev/null
fi
uname -r															
echo
echo '------------------------------------motherboard model------------------------------------'
echo																						
sudo dmidecode |grep -A16 "System Information$" |grep '\<Product Name'					
echo																						
echo '-------------------------------------------CPU-------------------------------------------'
echo																						
lscpu |grep '\<Model name' 																
lscpu |grep '\<Socket(s)'																
echo																						
echo '------------------------------------------memory-----------------------------------------'
echo																						
free -h																					
echo																					
echo '----------------------------------------hard drive---------------------------------------'
echo																						 
lsblk|grep -v loop																		
echo																						
echo '---------------------------------------network card--------------------------------------'
echo																						
lspci -nnk | grep -A2 Eth
lspci -nnk | grep -A2 'Network controller'
lspci -nnk | grep -A3 Infiniband
echo
ip a
echo																						
lspci|grep -i nvidia >> /dev/null
if [ $? -eq 0 ] 
			then 
echo																						 
echo '-------------------------------------------GPU-------------------------------------------'
nvidia-smi -L																		   
			else
				echo '无nvidia显卡' >> /dev/null
fi
echo '-----------------------------------------ALL end-----------------------------------------'



