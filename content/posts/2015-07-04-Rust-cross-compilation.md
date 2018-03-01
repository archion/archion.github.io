+++
title = "Rust交叉编译"
date = 2015-07-04T15:45:11Z
tags = ["rust-lang"]
[extra]
mdate = "2016-02-05T19:21:21Z"
+++


Rust在编译可执行文件时，`rustc`负责编译出目标文件（.o文件），接下来会调用系统的`cc`编译器进行链接，生成最终的可执行文件，所以要交叉编译之前，你需要两样东西：

- 支持交叉编译的编译器（负责最后的链接）
- 目标平台的rust标准库

下面就以64位的Archlinux平台为例，介绍如何交叉编译出windows下和32位的程序。
<!-- more -->

## 编译器

如果你需要编译到windows平台的话，需要安装`mingw-w64-gcc`，如果需要在64位的linux编译出32位的程序的话，需要安装`gcc-multilib`

## 标准库

rust官方提供主流平台的标准库，可以从[这里](http://static.rust-lang.org/dist/)下到，比如需要64位的windows的标准库，就下载`rustc-nightly-x86_64-pc-windows-gnu.tar.gz`，解压后把`rustc/bin/rustlib/x86_64-pc-windows-gnu`整个文件复制到你原来`rust`安装目录下的`rustlib`中

对于其它平台，就需要自己从源码`make`编译

## 交叉编译

在用`cargo`编译前，需要在`cargo`的配置文件中指定对应平台需要的链接器，如需要编译64位的windows程序，则在`~/.cargo/config`中添加（对于同平台的64位到32位的交叉编译不需要指定编译器的版本）
```
[target.x86_64-pc-windows-gnu]
linker = "/usr/bin/x86_64-w64-mingw32-gcc"
ar = "/usr/x86_64-w64-mingw32/bin/ar"
```
接下来执行如下命令
```
cargo --target=$triple
```
对应的`$triple`列表大概可以从[这里](https://github.com/rust-lang/rust/tree/master/mk/cfg)得到，如下
```
aarch64-apple-ios
aarch64-linux-android
aarch64-unknown-linux-gnu
arm-linux-androideabi
arm-unknown-linux-gnueabi
arm-unknown-linux-gnueabihf
armv7-apple-ios
armv7s-apple-ios
i386-apple-ios
i686-apple-darwin
i686-pc-windows-gnu
i686-pc-windows-msvc
i686-unknown-linux-gnu
mips-unknown-linux-gnu
mipsel-unknown-linux-gnu
powerpc-unknown-linux-gnu
x86_64-apple-darwin
x86_64-apple-ios
x86_64-pc-windows-gnu
x86_64-pc-windows-msvc
x86_64-unknown-bitrig
x86_64-unknown-dragonfly
x86_64-unknown-freebsd
x86_64-unknown-linux-gnu
x86_64-unknown-linux-musl
x86_64-unknown-netbsd
x86_64-unknown-openbsd
```

到此就可以了。 ~~不过实际操作过程中不知为什么，`cargo`并没有读取`config`文件中的配置并传给`rustc`，只好手动传`-C`选项，希望只是我个人情况~~ 在项目的目录下建立`.cargo/config`可以读取，但`~/.cargo/config`无法读取，不知是不是用的`multirust`的问题

未解决的问题：编译到`i686-pc-windows-gnu`会出现`undefined reference to '_Unwind_Resume'`错误

**UPDATE**: 根据[trans: Use LLVM's writeArchive to modify archives](https://github.com/rust-lang/rust/pull/26926)，rust现在貌似不用`ar`了，故上面的`ar`部分可以不用了



---
- [Rust - ArchWiki](https://wiki.archlinux.org/index.php/Rust)
- [A tour of the Rust compiler](http://www.slideshare.net/thomaslee/rust-march2014-32891901)
- [how to cross compile](https://github.com/japaric/ruststrap/blob/master/1-how-to-cross-compile.md)
- [使用Rust交叉编译arm程序](http://rust.cc/t/shi-yong-rustjiao-cha-bian-yi-armcheng-xu/384)
