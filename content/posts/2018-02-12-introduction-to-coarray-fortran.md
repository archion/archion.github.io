+++
title = "Coarray-Fortran 介绍"
tags = ["fortran", "HPC"]
date = 2018-02-12T22:16:40+08:00
draft = true
[extra]
mdate = "2018-02-12T22:16:40+08:00"
+++

对于共享内存的并行来说，有OpenMP这样很方便的库给我们使用，然而对于分布式内存来说，MPI是大家普遍采用的库，然而MPI这种并行写起来比较麻烦，可能需要对程序有较大的改动，对于分布式内存来说，有没有类似于OpenMP这样方便的库呢？
<!-- more -->

Intel在这方面有过一些尝试，即Cluster OpenMP。不过这个库现在已经不开发了，原因可能是因为Coarray Fortran (CAF) 的出现，就现在来说，CAF功能还很简单，不能完全替代MPI，不过CAF基于的是distributed shared memory，所以不同节点间的数据访问非常方便，不像MPI那样需要显式的消息传输和接收（MPI-2好像也开始支持distributed shared memory），而且CAF已经成为Fortran 2008语言的标准了，语法简单，跟语言结合紧密，相信以后会更加好用的。

接下来我简单介绍下CAF，CAF通过对原来的Fortran数据添加一个额外的维度，即codimension来实现远程数据的访问，该维度通过方括号进行访问，有定义codimension的数据被称为coarray，coarray可以是标量，数组，自定义类型等。coarray的底层实现可以有不同的方式，比如基于MPI实现，所以，可以说coarray是比MPI更为高层的并行模型。每一个进程被成为镜像（image），不同镜像之间只能通过coarray来进行数据的访问。标准输入只对第一个镜像有效。

例子:
```fortran
program main
	implicit none
	real(8) :: A(4,4)[2,*]
	A(:,:)=this_images()
	write(*,*)A(1,1) ! 等价于A(1,1)[this_images()]
end program
```

注意，codimension的大小是由运行时来确定的，所以他最后一个维度的大小一定是`*`，这里我们定义了一个codimension为2x*的一个4x4的双精度的数组,如果我们以8个进程进行编译`ifort main.f90 -coarray -coarray-num-images=8`并运行，那么codimension就是2x4，另外如果在使用的时候不指定codimension，那么默认是当前image的coarray指标，这给我们带来了很大的方便，我们可以在无需更改大量代码的情况下实现分布式内存的并行。

一些自带语句

- num_images: 有多少镜像 
- this_images: 当前镜像的指标，如果传入coarray，则给出该指标对应与该coarray的指标
- image_index: 将coarray指标转化为镜像的指标
- lcobound: coarray指标的下界
- ucobound: coarray指标的上界
- sync all: 同步所有coarray
- sync images: 同步对应的镜像
- error stop: 停止所有镜像
- critical和endcritical: 同一时间只允许单个镜像执行

更多例子

顺序执行
```
program main
	implicit none
	if(this_image()/=1) sync images(this_image()-1)
	!do somethings that must in order
	if(this_image()<num_images()) sync images(this_image()+1)
end program
```

```
program main
	implicit none
	if(this_image()==1) then
		!do somethings that need to be done before any other images
		sync images(*)
	else
		sync images(1)
	endif
end program
```

Fortran 2008暂时支持有限的功能，更多的功能，比如team，reduction等在Fortran 2015中支持。遗憾的是，不同镜像间对同个文件的读写暂时还没有实现的计划。
