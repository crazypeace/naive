# 说明

# 一键执行

脚本中很大部分都是在校验用户的输入。其实照着下面的内容自己配置就行了。

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
  order forward_proxy before file_server
}
:自定义端口, 你的naive域名:自定义端口 {
  tls e16d9cb045d7@gmail.com
  forward_proxy {
    basic_auth 用户名 密码
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
