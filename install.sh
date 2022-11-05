# 等待1秒, 避免curl下载脚本的打印与脚本本身的显示冲突, 吃掉了提示用户按回车继续的信息
sleep 1

echo -e "                     _ ___                   \n ___ ___ __ __ ___ _| |  _|___ __ __   _ ___ \n|-_ |_  |  |  |-_ | _ |   |- _|  |  |_| |_  |\n|___|___|  _  |___|___|_|_|___|  _  |___|___|\n        |_____|               |_____|        "
red='\e[91m'
green='\e[92m'
yellow='\e[93m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'
_red() { echo -e ${red}$*${none}; }
_green() { echo -e ${green}$*${none}; }
_yellow() { echo -e ${yellow}$*${none}; }
_magenta() { echo -e ${magenta}$*${none}; }
_cyan() { echo -e ${cyan}$*${none}; }

error() {
    echo -e "\n$red 输入错误! $none\n"
}

pause() {
    read -rsp "$(echo -e "按 $green Enter 回车键 $none 继续....或按 $red Ctrl + C $none 取消.")" -d $'\n'
    echo
}

# 说明
echo
echo -e "$yellow此脚本仅兼容于Debian 10+系统. 如果你的系统不符合,请Ctrl+C退出脚本$none"
echo -e "可以去 ${cyan}https://github.com/crazypeace/naive${none} 查看脚本整体思路和关键命令, 以便针对你自己的系统做出调整."
echo -e "有问题加群 ${cyan}https://t.me/+D8aqonnCR3s1NTRl${none}"
echo "本脚本支持带参数执行, 在参数中输入域名, 端口, 用户名, 密码. 详见GitHub."
echo "----------------------------------------------------------------"

# 执行脚本带参数
if [ $# -ge 1 ]; then

    # 第1个参数是 域名
    naive_domain=${1}

    # 第2个参数是 端口
    naive_port=${2}
    if [[ -z $naive_port ]]; then
        naive_port=$(shuf -i20001-65535 -n1)
    fi
    
    #第3个参数是 用户名
    naive_user=${3}
    if [[ -z $naive_user ]]; then
        naive_user=$(openssl rand -hex 8)
    fi

    #第4个参数是 密码
    naive_pass=${4}
    if [[ -z $naive_pass ]]; then 
        # 默认与用户名相等
        naive_pass=$naive_user
    fi

    echo -e "域名: ${naive_domain}"
    echo -e "端口: ${naive_port}"
    echo -e "用户名: ${naive_user}"
    echo -e "密码: ${naive_pass}"
fi

pause

# 准备
apt update
apt install -y sudo curl wget

# 安装Caddy最新版
echo
echo -e "$yellow安装Caddy最新版本$none"
echo "----------------------------------------------------------------"
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy

systemctl enable caddy

# 下载NaïveProxy作者编译的caddy 并替换caddy程序
echo
echo -e "$yellow下载NaïveProxy作者编译的caddy 并替换caddy程序$none"
echo "----------------------------------------------------------------"
cd /tmp
rm caddy-forwardproxy-naive.tar.xz
rm -r caddy-forwardproxy-naive
wget https://github.com/klzgrad/forwardproxy/releases/download/caddy2-naive-20221007/caddy-forwardproxy-naive.tar.xz
tar -xf caddy-forwardproxy-naive.tar.xz
cd caddy-forwardproxy-naive

# 替换caddy程序
service caddy stop
cp caddy /usr/bin/

# 写个简单的html页面
echo
echo -e "$yellow写个简单的html页面$none"
echo "----------------------------------------------------------------"
mkdir -p /var/www/html
echo "hello world" > /var/www/html/index.html

# 域名
if [[ -z $naive_domain ]]; then
    while :; do
        echo
        echo -e "请输入一个 ${magenta}正确的域名${none} Input your domain"
        read -p "(例如: mydomain.com): " naive_domain
        [ -z "$naive_domain" ] && error && continue
        echo
        echo
        echo -e "$yellow 你的域名Domain = $cyan$naive_domain$none"
        echo "----------------------------------------------------------------"
        break
    done
fi

# 端口
if [[ -z $naive_port ]]; then
    random=$(shuf -i20001-65535 -n1)
    while :; do
        echo -e "请输入 ${yellow}端口${none} [${magenta}1-65535${none}], 不能选择 ${magenta}80${none}端口"
        read -p "$(echo -e "(默认端口port: ${cyan}${random}$none):")" naive_port
        [ -z "$naive_port" ] && naive_port=$random
        case $naive_port in
        80)
            echo
            echo " ...都说了不能选择 80 端口了咯....."
            error
            ;;
        [1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
            echo
            echo
            echo -e "$yellow 端口Port = $cyan$naive_port$none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        *)
            error
            ;;
        esac
    done
fi

# 用户名
if [[ -z $naive_user ]]; then
    random=$(openssl rand -hex 8)
    while :; do
        echo
        echo -e "请输入 ${magenta}用户名${none} Input your username"
        read -p "$(echo -e "(默认: ${cyan}${random}$none):") " naive_user
        [ -z "$naive_user" ] && naive_user=$random
        echo
        echo
        echo -e "$yellow 你的用户名Username = $cyan$naive_user$none"
        echo "----------------------------------------------------------------"
        break
    done
fi

# 密码
if [[ -z $naive_pass ]]; then
    random=$(openssl rand -hex 8)
    while :; do
        echo
        echo -e "请输入 ${magenta}密码${none} Input your password"
        read -p "$(echo -e "(默认: ${cyan}${random}$none):") " naive_pass
        [ -z "$naive_pass" ] && naive_pass=$random
        echo
        echo
        echo -e "$yellow 你的密码Password = $cyan$naive_pass$none"
        echo "----------------------------------------------------------------"
        break
    done
fi

# 修改Caddyfile
echo
echo -e "$yellow修改Caddyfile$none"
echo "----------------------------------------------------------------"
begin_line=$(awk "/_naive_config_begin_/{print NR}" /etc/caddy/Caddyfile)
end_line=$(awk "/_naive_config_end_/{print NR}" /etc/caddy/Caddyfile)
if [[ -n $begin_line && -n $end_line ]]; then
  sed -i "${begin_line},${end_line}d" /etc/caddy/Caddyfile
fi

sed -i "1i # _naive_config_begin_\n\
{\n\
  order forward_proxy before file_server\n\
}\n\
:${naive_port}, ${naive_domain}:${naive_port} {\n\
  tls e16d9cb045d7@gmail.com\n\
  forward_proxy {\n\
    basic_auth ${naive_user} ${naive_pass}\n\
    hide_ip\n\
    hide_via\n\
    probe_resistance\n\
  }\n\
  file_server {\n\
    root /var/www/html\n\
  }\n\
}\n\
# _naive_config_end_" /etc/caddy/Caddyfile

# 启动NaïveProxy
echo
echo -e "$yellow启动NaïveProxy$none"
echo "----------------------------------------------------------------"
service caddy start

# 输出参数
echo
echo -e "${yellow}NaïveProxy配置参数${none}"
echo "----------------------------------------------------------------"
echo -e "域名Domain: ${naive_domain}"
echo -e "端口Port: ${naive_port}"
echo -e "用户名Username: ${naive_user}"
echo -e "密码Password: ${naive_pass}"
