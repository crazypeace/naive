# 说明
这个一键脚本超级简单。有效语句10行(其中安装Caddy 5行, 下载NaïveProxy作者编译的Caddy 1行, 解压 1行, 停止Caddy 1行, 替换Caddy程序 1行, 启动Caddy 1行)+Caddy配置文件15行(其中你需要修改5处), 其它都是用来检验小白输入错误参数或者搭建条件不满足的。

你如果不放心开源的脚本，你可以自己执行那10行有效语句，再修改配置文件中的5处，也能达到一样的效果。

# 一键安装
```
apt update
apt install -y curl
```
```
bash <(curl -L https://github.com/crazypeace/naive/raw/main/install.sh || wget -O- $_)
```

脚本中很大部分都是在校验用户的输入。其实照着下面的步骤自己配置就行了。

# 具体手搓步骤 (点击展开)

<details>
    <summary>(点击展开)</summary>

# 安装CaddyV2最新版本
source: https://caddyserver.com/docs/install#debian-ubuntu-raspbian

```
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
```

如果已经装过了Caddy, 重装的时候脚本会问你
```
File '/usr/share/keyrings/caddy-stable-archive-keyring.gpg' exists. Overwrite? (y/N)
```
输入`y`回车。

# 下载NaïveProxy作者编译的caddy
```
cd /tmp
wget https://github.com/klzgrad/forwardproxy/releases/download/caddy2-naive-20221007/caddy-forwardproxy-naive.tar.xz
tar -xf caddy-forwardproxy-naive.tar.xz
cd caddy-forwardproxy-naive
```

# 替换caddy程序
```
service caddy stop
cp caddy /usr/bin/
```

# 写个简单的html页面
```
mkdir -p /var/www/html
echo "hello world" > /var/www/html/index.html
```

# 在Caddyfile的顶部添加下面这一段
```
{
  order forward_proxy first
}
:自定义端口, 你的naive域名:自定义端口 {    // ***
  tls e16d9cb045d7@gmail.com
  forward_proxy {
    basic_auth 用户名 密码   // *** 多写几行就有多个用户, 详见官方文档 https://github.com/klzgrad/forwardproxy/?tab=readme-ov-file#caddyfile-syntax-server-configuration
    hide_ip
    hide_via
    probe_resistance
  }
  file_server {
    root /var/www/html
  }
}
```

# 启动NaiveProxy
```
service caddy start
```
  
</details>
  
  
# Uninstall
```
rm /etc/apt/sources.list.d/caddy-stable.list
apt remove -y caddy
```

# 如果希望和Caddy V2前置的VLESS/Vmess V2Ray共存
需要先搭好V2Ray，教程:
https://zelikk.blogspot.com/2022/11/naiveproxy-caddy-v2-vless-vmess-cdn.html

然后把Caddy替换为带naive的。

# 带参数执行
如果你已经很熟悉了, 安装过程中的参数都确认没问题. 可以带参数使用本脚本, 跳过脚本中的各种校验.
```
bash <(curl -L https://github.com/crazypeace/naive/raw/main/install.sh) <domain> [netstack] [port] [username] [password]
```
其中

`domain`      你的域名

`netstask`    6 表示 IPv6入站, 最后会安装WARP获得IPv4出站

`port` 你的端口

`username` 你的用户名

`password` 你的密码，如果不输入，会和用户名相同

例如
```
bash <(curl -L https://github.com/crazypeace/naive/raw/main/install.sh) abc.mydomain.com
bash <(curl -L https://github.com/crazypeace/naive/raw/main/install.sh) abc.mydomain.com 6
bash <(curl -L https://github.com/crazypeace/naive/raw/main/install.sh) abc.mydomain.com 6 14443
bash <(curl -L https://github.com/crazypeace/naive/raw/main/install.sh) abc.mydomain.com 6 14443 username
bash <(curl -L https://github.com/crazypeace/naive/raw/main/install.sh) abc.mydomain.com 6 14443 username password
```

## 用你的STAR告诉我这个Repo对你有用 Welcome STARs! :)

[![Stargazers over time](https://starchart.cc/crazypeace/naive.svg)](https://starchart.cc/crazypeace/naive)
