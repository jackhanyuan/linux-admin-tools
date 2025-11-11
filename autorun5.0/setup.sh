#!/bin/bash

#用户名
name=$(whoami)
#cuda版本号
cver=cuda-12.4
#NVIDIA显卡驱动安装包
qd=NVIDIA-Linux-x86_64-550.90.07.run
#cuda安装包
cuda=cuda_12.4.1_550.54.15_linux.run
#cudnn安装包
cudnn=cudnn-linux-x86_64-8.9.7.29_cuda12-archive.tar.xz
#anaconda版本号
an=Anaconda3-2024.02-1-Linux-x86_64.sh
#定义用户目录
PATH1=/home/$name
#定义cudnn安装包解压后的cudnn文件目录
PATH2=/home/$name/cudnn-linux-x86_64-8.9.7.29_cuda12-archive
#定义cuda用户环境变量
env1='export PATH=/usr/local/cuda-12.4/bin${PATH:+:${PATH}}\nexport LD_LIBRARY_PATH=/usr/local/cuda-12.4/lib64:${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}'


HEIGHT=25
WIDTH=50
CHOICE_HEIGHT=8
BACKTITLE="自动安装脚本V3.0-2024-06-21"
TITLE="自动安装脚本V3.0"
MENU="请选择安装项目:"

OPTIONS=(1 "安装显卡驱动550.90.07"
         2 "安装驱动+CUDA12.4"
         3 "安装驱动+CUDA12.4+CUDNN8.9.7"
		 4 "安装anaconda"
		 5 "安装anaconda+pytorch"
		 6 "安装anaconda+tf"
		 7 "安装anaconda+pytorch+tf")

CHOICE=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear
case $CHOICE in
        1)
            echo '-----------开始安装NVIDIA显卡驱动---------------'
			cd $PATH1 
			echo '1.检查是否安装NVIDIA显卡驱动：'
			nvidia-smi 
			if [ $? -eq 0 ]
			then
				echo 'NVIDIA显卡驱动已安装,无需安装'
				exit
			else
				echo '未安装显卡驱动，现在开始安装'
				if [ -e $PATH1/$qd ]
				then 
					cd $PATH1
					sudo chmod +x $qd
					sudo ./$qd -s  -no-x-check --dkms
					nvidia-smi
					if [ $? -eq 0 ] 
					then
						echo '显卡驱动安装成功'
						sudo sed -i 's/ nomodeset//g' /etc/default/grub
						sudo update-grub
					else
						echo '显卡驱动安装失败'
						echo '请查找原因后重新安装'
						exit
					fi
				else
					echo '未发现显卡驱动安装包，请上传安装包至用户家目录后重试'
					exit
				fi
			fi
            ;;
        2)
            echo '-----------开始安装NVIDIA显卡驱动+CUDA---------------'
cd $PATH1 
echo '1.检查是否安装NVIDIA显卡驱动：'
nvidia-smi 
if [ $? -eq 0 ]
then
	echo 'NVIDIA显卡驱动已安装,无需安装'
	echo '检查是否安装CUDA'
	sudo /usr/local/$cver/bin/__nvcc_device_query
		if [ $? -eq 0 ] 
		then
			echo 'CUDA已安装，无需安装'
			exit

		else
			echo '未安装CUDA，现在开始安装CUDA'
				if [ -e $PATH1/$cuda ]
				then 
					cd $PATH1
					sudo chmod +x $cuda
					sudo ./$cuda --silent --toolkit --samples
					sudo echo -e ${env1} >> $PATH1/.bashrc
					source $PATH1/.bashrc
					nvcc -V
					sudo /usr/local/$cver/bin/__nvcc_device_query
						if [ $? -eq 0 ] ;then
							echo 'CUDA安装成功'
							sudo sed -i 's/ nomodeset//g' /etc/default/grub
							sudo update-grub
							exit
						else
							echo 'CUDA安装失败'
							exit
						fi
				else
					echo '未发现CUDA安装包，请上传安装包后重试'
					exit
				fi
		fi
else
	echo '未安装显卡驱动，现在开始安装'
		if [ -e $PATH1/$qd ]
		then 
			cd $PATH1
			sudo chmod +x $qd
			sudo ./$qd -s -no-x-check --dkms
			nvidia-smi
				if [ $? -eq 0 ] ;then
					echo '显卡驱动安装成功'
					sudo sed -i 's/ nomodeset//g' /etc/default/grub
					sudo update-grub
					echo '开始安装CUDA'
						if [ -e $PATH1/$cuda ]
				then
					cd $PATH1
					sudo chmod +x $cuda
					sudo ./$cuda --silent --toolkit --samples
					sudo echo -e ${env1} >> $PATH1/.bashrc
					source $PATH1/.bashrc
					nvcc -V
					sudo /usr/local/$cver/bin/__nvcc_device_query
						if [ $? -eq 0 ] ;then
							echo 'CUDA安装成功'
						else
							echo 'CUDA安装失败'
							exit
						fi
				else
					echo '未发现CUDA安装包，请上传安装包后重试'
					exit
				fi
				else
					echo '显卡驱动安装失败'
					echo '请查找原因后重新安装'
					exit
				fi
		else
			echo '未发现显卡驱动安装包，请上传安装包至用户家目录后重试'
		fi
fi

            ;;
        3)
          echo '-----------开始安装NVIDIA显卡驱动+CUDA+CUDNN---------------'  
cd $PATH1 
echo '1.检查是否安装NVIDIA显卡驱动：'
nvidia-smi 
if [ $? -eq 0 ]
then
	echo 'NVIDIA显卡驱动已安装,无需安装'
	echo '检查是否安装CUDA'
	source $PATH1/.bashrc
	nvcc -V 
	sudo /usr/local/$cver/bin/__nvcc_device_query
		if [ $? -eq 0 ] 
		then
			echo 'CUDA已安装'
			echo '检查是否安装CUDNN'
				if [ -e /usr/local/$cver/include/cudnn_version.h ]
				then
					echo 'CUDNN已安装'
					echo '检测到系统已安装显卡驱动,CUDA,CUDNN，无需安装，即将退出脚本。'
					exit
				else
					echo '未发现CUDNN，现在开始安装CUDNN'
						if [ -e $PATH1/$cudnn ] 
						then
							cd $PATH1
							sudo tar -xvf $cudnn >> /dev/null
							cd $PATH2
							sudo cp include/cudnn*.h /usr/local/$cver/include
							sudo cp lib/libcudnn* /usr/local/$cver/lib64
							sudo chmod a+r /usr/local/$cver/include/cudnn*.h 
							sudo chmod a+r /usr/local/$cver/lib64/libcudnn*
							cat /usr/local/$cver/include/cudnn_version.h | grep CUDNN_MAJOR -A 2
								if [ $? -eq 0 ] 
								then
									echo 'CUDNN安装成功'
									sudo sed -i 's/ nomodeset//g' /etc/default/grub
									sudo update-grub
								else 
									echo 'CUDNN安装失败，请查找原因后重新安装'
									exit
								fi
						else 
							echo '未发现CUDNN安装包，请上传安装包至用户家目录后重试'
							exit
						fi
				fi
		else
			echo '未安装CUDA，现在开始安装CUDA'
				if [ -e $PATH1/$cuda ]
				then 
					cd $PATH1
					sudo chmod +x $cuda
					sudo ./$cuda --silent --toolkit --samples 
					sudo echo -e ${env1} >> $PATH1/.bashrc
					source $PATH1/.bashrc
					nvcc -V
					sudo /usr/local/$cver/bin/__nvcc_device_query
						if [ $? -eq 0 ] ;then
							echo 'CUDA安装成功'
							echo '现在开始安装CUDNN'
								if [ -e $PATH1/$cudnn ] 
								then
									cd $PATH1
									sudo tar -xvf $cudnn >> /dev/null
									cd $PATH2
									sudo cp include/cudnn*.h /usr/local/$cver/include
									sudo cp lib/libcudnn* /usr/local/$cver/lib64
									sudo chmod a+r /usr/local/$cver/include/cudnn*.h 
									sudo chmod a+r /usr/local/$cver/lib64/libcudnn*
									cat /usr/local/$cver/include/cudnn_version.h | grep CUDNN_MAJOR -A 2
										if [ $? -eq 0 ] 
										then
											echo 'CUDNN安装成功'
											sudo sed -i 's/ nomodeset//g' /etc/default/grub
											sudo update-grub
										else 
											echo 'CUDNN安装失败，请查找原因后重新安装'
											exit
										fi
								else 
									echo '未发现CUDNN安装包，请上传安装包至用户家目录后重试'
									exit
								fi
						else
							echo 'CUDA安装失败'
							exit
						fi
				else
					echo '未发现CUDA安装包，请上传安装包后重试'
					exit
				fi
		fi
else
	echo '未安装显卡驱动，现在开始安装'
		if [ -e $PATH1/$qd ]
		then 
			cd $PATH1
			sudo chmod +x $qd
			sudo ./$qd -s -no-x-check --dkms >> /dev/null
			nvidia-smi
				if [ $? -eq 0 ] ;then
					echo '显卡驱动安装成功'
					sudo sed -i 's/ nomodeset//g' /etc/default/grub
					sudo update-grub
					echo '开始安装CUDA'
						if [ -e $PATH1/$cuda ]
				then
					cd $PATH1
					sudo chmod +x $cuda
					sudo ./$cuda --silent --toolkit --samples >> /dev/null
					sudo echo -e ${env1} >> $PATH1/.bashrc
					source $PATH1/.bashrc
					nvcc -V
					sudo /usr/local/$cver/bin/__nvcc_device_query
						if [ $? -eq 0 ] ;then
							echo 'CUDA安装成功'
							echo '现在开始安装CUDNN'
								if [ -e $PATH1/$cudnn ] 
								then
									cd $PATH1
									sudo tar -xvf $cudnn >> /dev/null
									cd $PATH2
									sudo cp include/cudnn*.h /usr/local/$cver/include
									sudo cp lib/libcudnn* /usr/local/$cver/lib64
									sudo chmod a+r /usr/local/$cver/include/cudnn*.h 
									sudo chmod a+r /usr/local/$cver/lib64/libcudnn*
									cat /usr/local/$cver/include/cudnn_version.h | grep CUDNN_MAJOR -A 2
										if [ $? -eq 0 ] 
										then
											echo 'CUDNN安装成功'
										else 
											echo 'CUDNN安装失败，请查找原因后重新安装'
											exit
										fi
								else 
									echo '未发现CUDNN安装包，请上传安装包至用户家目录后重试'
									exit
								fi
						else
							echo 'CUDA安装失败'
							exit
						fi
				else
					echo '未发现CUDA安装包，请上传安装包后重试'
					exit
				fi
				else
					echo '显卡驱动安装失败'
					echo '请查找原因后重新安装'
					exit
				fi
		else
			echo '未发现显卡驱动安装包，请上传安装包至用户家目录后重试'
		fi
fi
            ;;

		4)
          echo '-----------开始安装anaconda---------------' 

echo '1.检查是否安装anaconda：'
cd $PATH1 
conda -V
if [ $? -eq 0 ]
			then
				echo 'anaconda已安装,无需安装'
				exit
			else
				echo '未安装anaconda，现在开始安装'
				if [ -e $PATH1/$an ]
				then	
					cd $PATH1
					bash $an -b
					source ~/anaconda3/bin/activate
					conda init bash
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/pkgs/main/
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/pkgs/free/
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/cloud/conda-forge/
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/cloud/msys2/
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/cloud/bioconda/
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/cloud/menpo/
					conda config --set show_channel_urls yes
					echo 'anaconda安装成功'
					exit
				else
					echo '未发现anaconda安装包，请上传安装包至用户家目录后重试'
					exit
				fi
			fi
				;;

		5)
          echo '-----------开始安装anaconda+pytorch---------------' 

echo '1.检查是否安装anaconda：'
cd $PATH1 
conda -V
if [ $? -eq 0 ]
			then
				echo 'anaconda已安装,无需安装'
					conda create -n pytorch python=3.9 -y
					conda activate pytorch
					cd $PATH1/1.12.1
					pip install torch-1.12.1+cu116-cp39-cp39-linux_x86_64.whl -i http://pypi.mirrors.ustc.edu.cn/simple/ --trusted-host pypi.mirrors.ustc.edu.cn
					pip install torchaudio-0.12.1+cu116-cp39-cp39-linux_x86_64.whl -i http://pypi.mirrors.ustc.edu.cn/simple/ --trusted-host pypi.mirrors.ustc.edu.cn
					pip install torchvision-0.13.1+cu116-cp39-cp39-linux_x86_64.whl -i http://pypi.mirrors.ustc.edu.cn/simple/ --trusted-host pypi.mirrors.ustc.edu.cn
					echo 'anaconda+pytorch安装成功'
					exit
				exit
			else
				echo '未安装anaconda，现在开始安装'
				if [ -e $PATH1/$an ]
				then	
					cd $PATH1
					bash $an -b
					source ~/anaconda3/bin/activate
					conda init bash
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/pkgs/main/
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/pkgs/free/
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/cloud/conda-forge/
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/cloud/msys2/
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/cloud/bioconda/
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/cloud/menpo/
					conda config --set show_channel_urls yes
					echo 'anaconda安装成功'
					conda create -n pytorch python=3.9 -y
					conda activate pytorch
					cd $PATH1/1.12.1
					pip install torch-1.12.1+cu116-cp39-cp39-linux_x86_64.whl -i http://pypi.mirrors.ustc.edu.cn/simple/ --trusted-host pypi.mirrors.ustc.edu.cn
					pip install torchaudio-0.12.1+cu116-cp39-cp39-linux_x86_64.whl -i http://pypi.mirrors.ustc.edu.cn/simple/ --trusted-host pypi.mirrors.ustc.edu.cn
					pip install torchvision-0.13.1+cu116-cp39-cp39-linux_x86_64.whl -i http://pypi.mirrors.ustc.edu.cn/simple/ --trusted-host pypi.mirrors.ustc.edu.cn
					echo 'anaconda+pytorch安装成功'
					exit
				else
					echo '未发现anaconda安装包，请上传安装包至用户家目录后重试'
					exit
				fi
			fi
				;;

		6)
          echo '-----------开始安装anaconda+tf---------------' 

echo '1.检查是否安装anaconda：'
cd $PATH1 
conda -V
if [ $? -eq 0 ]
			then
				echo 'anaconda已安装,无需安装'
					conda activate
					conda create -n tensorflow python=3.9 -y
					conda activate tensorflow
					pip install tensorflow-gpu -i http://pypi.mirrors.ustc.edu.cn/simple/ --trusted-host pypi.mirrors.ustc.edu.cn
					echo 'anaconda+tf安装成功'
					exit
				exit
			else
				echo '未安装anaconda，现在开始安装'
				if [ -e $PATH1/$an ]
				then	
					cd $PATH1
					bash $an -b
					source ~/anaconda3/bin/activate
					conda init bash
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/pkgs/main/
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/pkgs/free/
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/cloud/conda-forge/
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/cloud/msys2/
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/cloud/bioconda/
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/cloud/menpo/
					conda config --set show_channel_urls yes
					echo 'anaconda安装成功'
					conda activate
					conda create -n tensorflow python=3.9 -y
					conda activate tensorflow
					pip install tensorflow-gpu -i http://pypi.mirrors.ustc.edu.cn/simple/ --trusted-host pypi.mirrors.ustc.edu.cn
					echo 'anaconda+tf安装成功'
					exit
				else
					echo '未发现anaconda安装包，请上传安装包至用户家目录后重试'
					exit
				fi
			fi
				;;

 		7)
          echo '-----------开始安装anaconda+pytorch+tf---------------' 

echo '1.检查是否安装anaconda：'
cd $PATH1 
conda -V
if [ $? -eq 0 ]
			then
				echo 'anaconda已安装,无需安装'
					conda create -n pytorch python=3.9 -y
					conda activate pytorch
					cd $PATH1/1.12.1
					pip install torch-1.12.1+cu116-cp39-cp39-linux_x86_64.whl -i http://pypi.mirrors.ustc.edu.cn/simple/ --trusted-host pypi.mirrors.ustc.edu.cn
					pip install torchaudio-0.12.1+cu116-cp39-cp39-linux_x86_64.whl -i http://pypi.mirrors.ustc.edu.cn/simple/ --trusted-host pypi.mirrors.ustc.edu.cn
					pip install torchvision-0.13.1+cu116-cp39-cp39-linux_x86_64.whl -i http://pypi.mirrors.ustc.edu.cn/simple/ --trusted-host pypi.mirrors.ustc.edu.cn
					cd
					conda activate
					conda create -n tensorflow python=3.9 -y
					conda activate tensorflow
					pip install tensorflow-gpu -i http://pypi.mirrors.ustc.edu.cn/simple/ --trusted-host pypi.mirrors.ustc.edu.cn
					echo 'anaconda+pytorch+tf安装成功'
					exit
				exit
			else
				echo '未安装anaconda，现在开始安装'
				if [ -e $PATH1/$an ]
				then	
					cd $PATH1
					bash $an -b
					source ~/anaconda3/bin/activate
					conda init bash
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/pkgs/main/
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/pkgs/free/
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/cloud/conda-forge/
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/cloud/msys2/
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/cloud/bioconda/
					conda config --add channels https://mirrors.ustc.edu.cn/anaconda/cloud/menpo/
					conda config --set show_channel_urls yes
					echo 'anaconda安装成功'
					conda create -n pytorch python=3.9 -y
					conda activate pytorch
					cd $PATH1/1.12.1
					pip install torch-1.12.1+cu116-cp39-cp39-linux_x86_64.whl -i http://pypi.mirrors.ustc.edu.cn/simple/ --trusted-host pypi.mirrors.ustc.edu.cn
					pip install torchaudio-0.12.1+cu116-cp39-cp39-linux_x86_64.whl -i http://pypi.mirrors.ustc.edu.cn/simple/ --trusted-host pypi.mirrors.ustc.edu.cn
					pip install torchvision-0.13.1+cu116-cp39-cp39-linux_x86_64.whl -i http://pypi.mirrors.ustc.edu.cn/simple/ --trusted-host pypi.mirrors.ustc.edu.cn
					cd
					conda activate
					conda create -n tensorflow python=3.9 -y
					conda activate tensorflow
					pip install tensorflow-gpu -i http://pypi.mirrors.ustc.edu.cn/simple/ --trusted-host pypi.mirrors.ustc.edu.cn
					echo 'anaconda+pytorch+tf安装成功'
					exit					
				else
					echo '未发现anaconda安装包，请上传安装包至用户家目录后重试'
					exit
				fi
			fi
				;;

esac
