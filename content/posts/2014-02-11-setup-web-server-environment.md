+++
title = "搭建网站环境"
date = 2014-02-11T12:46:12Z
tags = ["网络", "服务器", "linux"]
[extra]
mdate = "2016-02-05T19:20:24Z"
+++

[之前](./posts/2014-02-06-updating-archlinux-installation-and-configure/index.md)在家里的老台式机上安装了Archlinux，于是就想用它作个类VPS，挂个网站什么的，简单讲些理解方面的东西，因为是第一次接触的菜鸟，可能有很多不对的地方
<!-- more -->

## 需要的软件和服务
- `openssh`：用于远程登录管理
- `ngnix`：搭建网络服务器
- `php-fpm`：让网络服务器可以解释php文件
- `MariaDB/MySQL`：数据库，暂时用不上
- `DDNS`：因为家里的电脑没有固定ip，故需要选择个动态域名解析服务


## 解释
当互联网用户访问一个网站是，通常过程是：  
当用户在浏览器中访问一个网址时（+端口，对于默认情况，可以不指定端口，http默认端口为80，https为443），会发送一个http的请求，这个请求的headers包含着用户访问的主机域名，然后由域名解析服务器解析为ip地址+端口，找到该ip对应的主机，接下来由主机上的网络服务器软件接管，主机上的网络服务器提取http请求的headers里的域名并作出响应（题外话：正因为如此，如果你采用的是https，则这个headers会被加密，这样的话当请求发到主机时，网络服务器无法得到请求的主机域名，于是无法用响应密钥解密这个请求，所以一般托管https的服务器上一个ip只托管一个网站，除非获得一个可以用于多个域名的密钥），对应到指定的域名服务的规则，当用户需要访问的网站地址和端口符合其中一个时，就会映射到主机上的指定目录里，这些目录中存放着一个运行一个网站所需要的文件（一般为html文件，php文件什么的），然后主机上的网络服务器会响应用户请求并执行返回相应文件给用户

这里我用的网络服务器软件是`Ngnix`，比较有名的还有`Apache`以及新兴的`Node.js`

类外网站一般分两类：静态和动态，顾名思义，静态网站即网站文件都是静态的html文件，每次更改或添加网站页面都需要编辑这些html文件，这对于经常需要变化的网站显然太麻烦了，而动态网站即通过php等语言从数据库中自动生成html文件，如需更新网站只需要编辑数据库即可，用的最多的数据库是MySQL，如果网站数据不是很多可以用XML自己实现数据库

## 配置
### 目录结构
首先先提前想好网站目录的结构，一般来说，在自己家目录建立一个项目目录，如`www`，然后在这个目录下建一个目录（如`www/html`）存放互联网用户在浏览器地址栏中可以访问的文件，把其他文件（通常是php文件，设置文件和数据库文件什么的）根据需要放在`www`目录下的其他文件夹中

### 关于权限
`html`目录及其所有父目录的权限应该对所有用户都可执行，并且`html`下的所有文件应该对所有用户有可读权限

对于`www`目录下的其他文件夹，比如存放一些配置文件和php私有代码的文件，一般我们不希望让其他用户能够读取到，因为我们把他放在了`html`目录之外，所以可以保证网络用户无法通过url进行访问，然而对于本地的其他用户（特别是网站运行在共享主机环境下），按理说应该设置为其他用户不可读的，但如果设置为对其他用户不可读，那么网站服务器软件（通常以一些特殊用户运行，如nobody，http等）也就不能读取这些文件了，解决这个矛盾是使用`suPHP`（Apache支持），让网络服务器执行php文件时暂时切换为php文件拥有者来执行，这样你就可以将这些文件设置为其他用户都不可读写了，对于Nginx，貌似没有这个，故只好先将其目录权限设置为可执行，其中的文件设置为可读，因为用的是类VPS环境，只有我一个用户，所以问题不大

### Nginx配置
假设你的申请的域名/动态域名为`test.domain.com`，其在主机上对应的目录为`/pathtohtml/html`，则向`/etc/nginx/nginx.conf`文件中添加如下内容：
```bash /etc/nginx/nginx.conf
server {
	listen       80;
	server_name  test.domain.com;

	root   /pathtohtml/html;

	location / {
		index  index.html index.htm;
	}

	error_page   500 502 503 504  /50x.html;
	location = /50x.html {
		root   .;
	}

	location ~ \.php$ {
		fastcgi_pass   unix:/run/php-fpm/php-fpm.sock;
		fastcgi_index  index.php;
		fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
		include        fastcgi_params;
	}
}
```
这里简要解释下配置文件，前两行定义了域名和监听的端口，`root`定义了这个域名对应的本地目录，最后的`location`定义了如何处理php请求，其中`～`表示区分大小写，`$`匹配结尾，即将任意以`.php`结尾的请求传给`php-fpm`处理

## 启动服务
最后启动`Ngnix`和`php-fpm`服务，将网站文件考入到相应目录中（比如我就复制了这个托管在github的blog仓库），然后在浏览器中输入你设置的域名，应该就能看到网页了，如果你的主机在内网中，可能还需要在路由器中做`80`端口的端口映射

## 参考
- [Nginx的Arch Wiki](https://wiki.archlinux.org/index.php/Nginx)
- [nginx配置文件中的location详解](http://www.eit.name/blog/read.php?497)
- [nginx目录设置alias和root](https://www.akii.org/nginx-set-directory-alias-and-root.html)
- [哈佛大学公开课：构建动态网站](http://v.163.com/special/opencourse/buildingdynamicwebsites.html)
- [Node入门](http://www.nodebeginner.org/index-zh-cn.html)
- [21分钟 MySQL 入门教程](http://www.cnblogs.com/mr-wid/archive/2013/05/09/3068229.html)
- [Google](https://www.google.com)


