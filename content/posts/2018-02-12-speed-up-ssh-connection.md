+++
title = "提高ssh连接速度"
tags = ["配置"]
draft = true
date = 2018-02-12T22:27:07+08:00
[extra]
mdate = "2018-02-12T22:27:07+08:00"
+++
在服务端的`/etc/ssh/sshd_config`中设置`UseDSN no`

如果还慢的话可以再设置`UsePAM no`
