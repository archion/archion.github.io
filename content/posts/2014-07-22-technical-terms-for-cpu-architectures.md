+++
title = "关于处理器的一些术语"
tags = ["硬件"]
date = 2015-03-15T10:22:31Z
[extra]
mdate = "2016-02-05T19:21:10Z"
+++

在装ifort以及链接一些库的时候，会遇到处理器架构的一些术语，如ia32，intel64，ia64什么的，老了记性不好，还是记录下吧
<!-- more -->

x86是386、486等系列intel处理器的统称，包括最早的16位处理器和后来的32位处理器，而32位的x86也称为ia32（Intel Architecture 32-bit），而i386指386后的处理器，i686特指686以后的处理器，现在的32位处理器就是i686的。这些都是32位

因为32位处理器的寻址范围的限制，所以intel和amd着手开发64位处理器，然而两个公司的策略不同，intel的策略是抛弃32位，重新开发，即后来的IA64，而amd则在现有的32位的x86处理器基础上拓展，即最开始称x86_64或x64，后来改为AMD64。由于IA64不兼容原来的32位处理器，所以intel后来也借鉴amd开发基于原有32位的64位处理器，最开始称为EM64T，后来改称为intel64，总的来说，AMD64和intel64并没有多大区别，是现在64位处理器（amd的opteron、athlon，intel的xeon，i系列等）的主流，而IA64只有intel一家用在了面向企业服务器和高性能运算的安腾（itanium）上。

总结下：

- 32位：ia32（x86 ...）
- 基于32位的64位：x86_64（amd64、intel64、x64 ...）
- 64位：ia64
