# 感谢
# https://github.com/shell-script/naivecaddy/blob/master/naivecaddy.sh
# https://lhy.life/20211218-naiveproxy/

GO_LATEST_VER=$(curl https://go.dev/VERSION?m=text)

case "$(uname -m)" in
"armv6l"|"i686")
  SYSTEM_ARCH="$(uname -m)"
  ;;
"aarch64")
  SYSTEM_ARCH="arm64"
  ;;
"x86_64")
  SYSTEM_ARCH="amd64"
  ;;
*)
  echo
  ;;
esac

# 安装 Go 编译环境
mkdir -p /tmp/go && cd $_
rm *
wget "https://go.dev/dl/${GO_LATEST_VER}.linux-${SYSTEM_ARCH}.tar.gz"
rm -rf /usr/local/go && tar -C /usr/local -xzf go*.tar.gz
export PATH=$PATH:/usr/local/go/bin
go version

# 编译
go get -u github.com/caddyserver/xcaddy/cmd/xcaddy
~/go/bin/xcaddy build --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive
./caddy version
