+++
title = "自寻谷歌挨批"
tags = ["网络"]
date = 2014-06-18T23:02:20Z

[extra]
mdate = "2016-02-05T19:20:33Z"
+++

好久没耕了，来除个草
<!-- more -->

其实写这篇文章还是比较矛盾的，一方面感觉分享破墙技术会提高我们对墙的忍耐程度（要是以前这么长时间的封锁我早就XXXX了），另一方面又觉得自己的破墙知识都是别人分享的，不分享太不厚道了，不过我这博客流量少的可怜，要是真有人看到了，也算有缘人啦

因为我都是用Linux，所以给的方案也是基于Linux，不过原理都差不多就是了

首先你要找到谷歌ip段，可以参考[Google IP address ranges](https://support.google.com/a/answer/60764?hl=en)，下面以`dig`工具为例，具体做法如下
```bash
dig @8.8.8.8 _netblocks.google.com txt
```
如果想要ipv6的话为
```bash
dig @8.8.8.8 _netblocks2.google.com txt
```
执行命令后在返回的`ANSWER SECTION` 部分显示很多ip段，举个栗子，如果得到的ip段是`207.126.144.0/20` 那么可知ip地址范围为`207.126.144.1~207.126.159.254` ，接下了就是要在这个ip段中找到可用的ip，只是`ping` 通是不行的（你会发现ping通的放到浏览器里并不能访问），但是一个一个试不可能，所以就借用`curl`工具，模拟浏览器行为，写个简单的脚本，比如[这个](https://github.com/archion/mylinux/blob/master/bin/googleip),这个脚本只支持ipv4，具体用法查看脚本注释。

接下来就复制到浏览器里看看哪些好用，好用的就写到hosts文件里面还有goagent配置文件里面的iplist里，这样就可以了

另外提醒下hosts文件里开始没必要写很多域名，先写上几个常用的，碰到访问慢的网站再用浏览器自带的开发工具看下是哪个域名出问题，添加到hosts文件里就可以了

最后，找到的ip不要在网络公开传播喔～
