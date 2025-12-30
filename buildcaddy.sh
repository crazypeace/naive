# 感谢
# https://github.com/shell-script/naivecaddy/blob/master/naivecaddy.sh
# https://lhy.life/20211218-naiveproxy/
# https://github.com/233boy/v2ray/blob/master/install.sh

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

echo
echo -e "${yellow}根据操作系统架构, 取最新版本Go编译环境, 编译NaïveProxy的Caddy${none}"
echo "--------------------------------"

save_dir=$(pwd)

GO_LATEST_VER=$(curl https://go.dev/VERSION?m=text | head -1)

case "$(uname -m)" in
*aarch64* | *armv8*)
  SYSTEM_ARCH="arm64"
  ;;
'amd64' | 'x86_64')
  SYSTEM_ARCH="amd64"
  ;;
*)
  SYSTEM_ARCH="$(uname -m)"
  echo -e "${red}${SYSTEM_ARCH}${none}"
  ;;
esac

# 安装 Go 编译环境
mkdir -p /tmp/go_naive_caddy && cd $_
rm -r *
wget "https://go.dev/dl/${GO_LATEST_VER}.linux-${SYSTEM_ARCH}.tar.gz"
rm -rf /usr/local/go && tar -C /usr/local -xzf go*.tar.gz
export PATH=$PATH:/usr/local/go/bin
go version

# 编译 Caddy
go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
~/go/bin/xcaddy build --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive
./caddy version

cd ${save_dir}
cp /tmp/go_naive_caddy/caddy ./
