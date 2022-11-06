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
echo "本脚本支持带参数执行, 在参数中输入域名, 网络栈, 端口, 用户名, 密码. 详见GitHub."
echo "----------------------------------------------------------------"

# 执行脚本带参数
if [ $# -ge 1 ]; then

    # 第1个参数是 域名
    naive_domain=${1}

    # 第2个参数是搭在ipv4还是ipv6上
    case ${2} in
    4)
        netstack=4
        ;;
    6)
        netstack=6
        ;;    
    *) # initial
        netstack="i"
        ;;    
    esac
    
    # 第3个参数是 端口
    naive_port=${3}
    if [[ -z $naive_port ]]; then
        naive_port=443
    fi
    
    #第4个参数是 用户名
    naive_user=${4}
    if [[ -z $naive_user ]]; then
        naive_user=$(openssl rand -hex 8)
    fi

    #第5个参数是 密码
    naive_pass=${5}
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

# xkcd密码生成器页面
echo
echo -e "$yellow xkcd密码生成器页面 $none"
echo "----------------------------------------------------------------"
rm -r /var/www/xkcdpw-html
git clone https://github.com/crazypeace/xkcd-password-generator -b "master" /var/www/xkcdpw-html --depth=1

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

# 网络栈
if [[ -z $netstack ]]; then
    echo -e "如果你的小鸡是${magenta}双栈(同时有IPv4和IPv6的IP)${none}，请选择你把v2ray搭在哪个'网口'上"
    echo "如果你不懂这段话是什么意思, 请直接回车"
    read -p "$(echo -e "Input ${cyan}4${none} for IPv4, ${cyan}6${none} for IPv6:") " netstack
    if [[ $netstack == "4" ]]; then
        domain_resolve=$(curl -sH 'accept: application/dns-json' "https://cloudflare-dns.com/dns-query?name=$naive_domain&type=A" | jq -r '.Answer[0].data')
    elif [[ $netstack == "6" ]]; then 
        domain_resolve=$(curl -sH 'accept: application/dns-json' "https://cloudflare-dns.com/dns-query?name=$naive_domain&type=AAAA" | jq -r '.Answer[0].data')
    else
        domain_resolve=$(curl -sH 'accept: application/dns-json' "https://cloudflare-dns.com/dns-query?name=$naive_domain&type=A" | jq -r '.Answer[0].data')
        if [[ "$domain_resolve" != "null" ]]; then
            netstack="4"
        else
            domain_resolve=$(curl -sH 'accept: application/dns-json' "https://cloudflare-dns.com/dns-query?name=$naive_domain&type=AAAA" | jq -r '.Answer[0].data')            
            if [[ "$domain_resolve" != "null" ]]; then
                netstack="6"
            fi
        fi
    fi

    # 本机 IP
    if [[ $netstack == "4" ]]; then
        ip=$(curl -4 -s https://api.myip.la)
    elif [[ $netstack == "6" ]]; then 
        ip=$(curl -6 -s https://api.myip.la)
    else
        ip=$(curl -s https://api.myip.la)
    fi

    if [[ $domain_resolve != $ip ]]; then
        echo
        echo -e "$red 域名解析错误Domain resolution error....$none"
        echo
        echo -e " 你的域名: $yellow$domain$none 未解析到: $cyan$ip$none"
        echo
        if [[ $domain_resolve != "null" ]]; then
            echo -e " 你的域名当前解析到: $cyan$domain_resolve$none"
        else
            echo -e " $red检测不到域名解析Domain not resolved $none "
        fi
        echo
        echo -e "备注...如果你的域名是使用$yellow Cloudflare $none解析的话... 在 DNS 设置页面, 请将$yellow代理状态$none设置为$yellow仅限DNS$none, 小云朵变灰."
        echo "Notice...If you use Cloudflare to resolve your domain, on 'DNS' setting page, 'Proxy status' should be 'DNS only' but not 'Proxied'."
        echo
        exit 1
    else
        echo
        echo
        echo -e "$yellow 域名解析 = ${cyan}我确定已经有解析了$none"
        echo "----------------------------------------------------------------"
        echo
    fi
fi

# 端口
if [[ -z $naive_port ]]; then
    default=443
    while :; do
        echo -e "请输入 ${yellow}端口${none} [${magenta}1-65535${none}], 不能选择 ${magenta}80${none}端口"
        read -p "$(echo -e "(默认端口port: ${cyan}${default}$none):")" naive_port
        [ -z "$naive_port" ] && naive_port=$default
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
    root /var/www/xkcdpw-html\n\
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
