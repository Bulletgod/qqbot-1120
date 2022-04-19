#!/usr/bin/env bash
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'


# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误: ${plain} 必须使用root用户运行此脚本！\n" && exit 1
clear
# globals
CWD=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
[ -e "${CWD}/scripts/globals" ] && . ${CWD}/scripts/globals

checkos(){
  ifTermux=$(echo $PWD | grep termux)
  ifMacOS=$(uname -a | grep Darwin)
  if [ -n "$ifTermux" ];then
    os_version=Termux
  elif [ -n "$ifMacOS" ];then
    os_version=MacOS  
  else  
    os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
  fi
  
  if [[ "$os_version" == "2004" ]] || [[ "$os_version" == "10" ]] || [[ "$os_version" == "11" ]];then
    ssll="-k --ciphers DEFAULT@SECLEVEL=1"
  fi
}
checkos 

checkCPU(){
  CPUArch=$(uname -m)
  if [[ "$CPUArch" == "aarch64" ]];then
    arch=linux_arm64
  elif [[ "$CPUArch" == "i686" ]];then
    arch=linux_386
  elif [[ "$CPUArch" == "arm" ]];then
    arch=linux_arm
  elif [[ "$CPUArch" == "x86_64" ]] && [ -n "$ifMacOS" ];then
    arch=darwin_amd64
  elif [[ "$CPUArch" == "x86_64" ]];then
    arch=linux_amd64    
  fi
}
checkCPU
check_dependencies(){

  os_detail=$(cat /etc/os-release 2> /dev/null)
  if_debian=$(echo $os_detail | grep 'ebian')
  if_redhat=$(echo $os_detail | grep 'rhel')
  if [ -n "$if_debian" ];then
    InstallMethod="apt"
  elif [ -n "$if_redhat" ] && [[ "$os_version" -lt 8 ]];then
    InstallMethod="yum"
  elif [[ "$os_version" == "MacOS" ]];then
    InstallMethod="brew"  
  fi
}
check_dependencies
#安装wget、curl、unzip
echo -e "${green}开始安装wget、curl、unzip、git，安装时间根据网络情况长短不一，请耐心等待...${plain}"
${InstallMethod} install unzip wget git curl -y > /dev/null 2>&1 
get_opsy() {
  [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
  [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
  [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}
virt_check() {
  # if hash ifconfig 2>/dev/null; then
  # eth=$(ifconfig)
  # fi

  virtualx=$(dmesg) 2>/dev/null

  if [[ $(which dmidecode) ]]; then
    sys_manu=$(dmidecode -s system-manufacturer) 2>/dev/null
    sys_product=$(dmidecode -s system-product-name) 2>/dev/null
    sys_ver=$(dmidecode -s system-version) 2>/dev/null
  else
    sys_manu=""
    sys_product=""
    sys_ver=""
  fi

  if grep docker /proc/1/cgroup -qa; then
    virtual="Docker"
  elif grep lxc /proc/1/cgroup -qa; then
    virtual="Lxc"
  elif grep -qa container=lxc /proc/1/environ; then
    virtual="Lxc"
  elif [[ -f /proc/user_beancounters ]]; then
    virtual="OpenVZ"
  elif [[ "$virtualx" == *kvm-clock* ]]; then
    virtual="KVM"
  elif [[ "$cname" == *KVM* ]]; then
    virtual="KVM"
  elif [[ "$cname" == *QEMU* ]]; then
    virtual="KVM"
  elif [[ "$virtualx" == *"VMware Virtual Platform"* ]]; then
    virtual="VMware"
  elif [[ "$virtualx" == *"Parallels Software International"* ]]; then
    virtual="Parallels"
  elif [[ "$virtualx" == *VirtualBox* ]]; then
    virtual="VirtualBox"
  elif [[ -e /proc/xen ]]; then
    virtual="Xen"
  elif [[ "$sys_manu" == *"Microsoft Corporation"* ]]; then
    if [[ "$sys_product" == *"Virtual Machine"* ]]; then
      if [[ "$sys_ver" == *"7.0"* || "$sys_ver" == *"Hyper-V" ]]; then
        virtual="Hyper-V"
      else
        virtual="Microsoft Virtual Machine"
      fi
    fi
  else
    virtual="Dedicated母鸡"
  fi
}



#系统信息
get_system_info() {
  cname=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
  opsy=$(get_opsy)
  arch=$(uname -m)
  kern=$(uname -r)
  virt_check
}


#判断机器是否安装docker
docker_install() {
    echo -e "${green}检测 Docker......${plain}"
    if [ -x "$(command -v docker)" ]; then
        echo -e "${green}检测到 Docker 已安装!${plain}"
    else
        if [ -r /etc/os-release ]; then
            lsb_dist="$(. /etc/os-release && echo "$ID")"
        fi
        if [ $lsb_dist == "openwrt" ]; then
            echo -e "${green}openwrt 环境请自行安装 docker${plain}"
            exit 1
        else
            echo -e "${green}安装 docker 环境，安装时间根据网络情况长短不一，请耐心等待...${plain}"
            curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
            echo -e "${green}安装 docker 环境...安装完成!${plain}"
            systemctl enable docker
            systemctl start docker
        fi
    fi
}
docker_install


copyright(){
    clear
echo -e "${green}
———————————————————————————————————————————————
       ___   ___  _           _   
      / _ \ / _ \| |__   ___ | |_ 
     | | | | | | | '_ \ / _ \| __|
     | |_| | |_| | |_) | (_) | |_ 
      \__\_\\__\_\_.__/ \___/ \__|     11.20b
———————————————————————————————————————————————
        qqbot助手一键安装脚本
 
                远古版本备份，请支持正版量子。             
———————————————————————————————————————————————
${plain}"
}
quit(){
exit
}

install_liangzi(){

  read -p "请输入qqbot面板希望使用的端口号（默认请输入5010）: " portinfo && printf "\n"
  read -p "请输入qqbot面板管理员用户名: " user && printf "\n"
  read -p "请输入qqbot面板管理员密码: " pwd && printf "\n"
  read -p "请输入qqbot面板管理员QQ: " adminqq && printf "\n"

  #拉取git文件
  echo -e "${green}开始进行安装依赖文件${plain}"
  git clone https://ghproxy.com/https://github.com/Bulletgod/qqbot-1120.git /root/qqbot1
  # mkdir -p /root/qqbot1/app/config && touch /root/qqbot1/app/config/SettInstallConfiging.xml
  # baseip=$(curl -s ipip.ooo)  > /dev/null
  #配置文件
  cat > /root/qqbot1/app/config/InstallConfig.xml << EOF
<?xml version="1.0" encoding="utf-16"?>
<InstallConfig xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <UserName>${user}</UserName>
  <PassWord>${pwd}</PassWord>
  <DBType>SQLite</DBType>
  <DBAddress>QQBot.db</DBAddress>
  <Port>5010</Port>
  <cqhttpWS></cqhttpWS>
  <cqhttpHttp></cqhttpHttp>
  <ManagerQQ>${adminqq}</ManagerQQ>
  <Groups></Groups>
</InstallConfig>
EOF

  #拉取镜像
  echo -e  "${green}开始拉取qqbot镜像文件，请耐心等待${plain}"
  docker pull bulletplus/qqbot


  #创建并启动容器
  echo -e "${green}开始创建qqbot容器${plain}"
  docker run -d --name qqbot1 -v /root/qqbot1/app:/app -p ${portinfo}:5010 bulletplus/qqbot -restart:always



#重要的一步重启容器
echo -e "${green}配置完成，重启qqbot容器${plain}"
docker restart qqbot1
echo -e "\n"



echo -e "${green}安装完成，qqbot开始吞噬
—————————————————————————————————————————————————————————————
企鹅群1：994205351(已满)
企鹅群2：872628933
guyhub：https://github.com/asupc
tg频道：https://t.me/asupcqqbot
—————————————————————————————————————————————————————————————
"
echo -e "${green}面板访问地址：http://本机IP地址:${portinfo}${plain}"
echo -e "${green}面板账号：${user}${plain}"
echo -e "${green}面板密码：${pwd}${plain}"
echo -e "\n"
exit 0
}

update_liangzi(){
echo -e "${green}远古版本不支持更新，脚本自动退出。${plain}"
exit 0
}







uninstall_liangzi(){
docker rm -f qqbot1
docker rmi bulletplus/qqbot:latest
rm -rf /root/qqbot1
echo -e "${green}面板已卸载，相关内容已删除，脚本自动退出。${plain}"
exit 0
}

menu() {
  echo -e "\
${green}0.${plain} 退出脚本
${green}1.${plain} 安装qqbot助手
${green}2.${plain} 更新qqbot助手
${green}3.${plain} 卸载qqbot助手
"
get_system_info
echo -e "当前系统信息: ${Font_color_suffix}$opsy ${Green_font_prefix}$virtual${Font_color_suffix} $arch ${Green_font_prefix}$kern${Font_color_suffix}
"

  read -p "请输入数字 :" num
  case "$num" in
  0)
    quit
    ;;
  1)
    install_liangzi
    ;;
  2)
      update_liangzi
      ;;
  3)
    uninstall_liangzi
    ;;    
  *)
  clear
    echo -e "${Error}:请输入正确数字 [0-3]"
    sleep 5s
    menu
    ;;
  esac
}

copyright

menu

