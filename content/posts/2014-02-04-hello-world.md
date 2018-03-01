+++
title = "Hello World"
tags =["工具"]
date = 2014-02-04T19:48:46Z

[extra]
mdate = "2016-02-05T19:27:24Z"
+++

Hello World ^o^
<!-- more -->

## hexo基础

安装

```bash
sudo npm install hexo -g
```

升级

```bash
sudo npm update hexo -g
```

建立项目目录并初始化

```bash
hexo init 目录名 && cd 目录名
```

写文章

```bash
hexo new "文章标题"
```

默认生成`source/_posts`目录下的一个markdown文件，其中摘要和内容用`<!--more-->`行隔开
生成静态网站文件

```bash
hexo generate
#or
hexo g
```

开启服务预览

```bash
hexo server
#or
hexo s
```

生成并启动服务

```bash
hexo s -g
```

## github托管

建立名为`archion.github.io`的repo

编辑项目根目录的`_config.yml`文件，更改以下值

```bash _config.yml
url: http://archion.github.io
deploy:
  type: github
  repository: git@github.com:archion/archion.github.io.git
  branch: master
```

发布到github

```bash
hexo deploy
#or
hexo d
```

生成并发布到github

```bash
hexo d -g
```

## 问题

- 有时候会出现某某文件未找到的错误，而该文件在代码中压根没用到，可以通过删除网站根目录下的`db.json`解决，出现这种情况的原因可能是你之前在代码中引用过一些文件，后来又删除了，结果`db.json`没有及时自动更新
- 更改主题后，在本地预览的效果和生成发布出来的效果不一致，可以通过删除`public/css/style.css`，并执行`hexo g`重新生成网页，原因跟上面类似



----------
更多细节参考：[hexo你的博客](http://ibruce.info/2013/11/22/hexo-your-blog/)
