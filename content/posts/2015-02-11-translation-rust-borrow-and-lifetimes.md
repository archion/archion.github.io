+++
title = "[译文]Rust Borrow and Lifetimes"
tags = ["rust-lang", "翻译"]
date = 2015-02-11T21:08:43Z

[extra]
mdate = "2016-02-05T19:21:00Z"
toc = true
+++

译者注：文中的“我”指原作者

原文：[Rust Borrow and Lifetimes](http://arthurtw.github.io/2014/11/30/rust-borrow-lifetimes.html)


Rust是一门还在向1.0稳定版演进的新编程语言，我可能会再写一篇关于Rust语言以及为什么我认为它非常棒，这次我主要关注它租借（borrow）和生存周期（lifetime）特性，这两个特性常会吓退包括我在内的很多Rust新手。这篇文章假定你已经有了关于Rust的一些基础语法知识，如果没有，请先移步Rust的官方文档。
<!-- more -->

# 资源的所有权和租借

Rust通过精心设计的租借体系而非垃圾回收器（GC）来实现内存安全。对于任何资源（栈内存，堆内存，文件句柄等），有且仅有一个所有者来对其所有的资源释放负责。你可以通过`&`或`&mut`来创建新的指向该资源的绑定，这分别称为租借或可变租借（mutable borrow）。编译器确保所有者和租借者都正常运作。

# 复制和转移

在深入Rust的租借系统之前，我们需要知道Rust如何处理复制和转移的。这里有一个关于这方面很好的[回答](http://stackoverflow.com/questions/24253344/move-vs-copy-in-rust/24253573#24253573)。总的来说，在赋值和函数调用中：

1. 如果值是可复制的（只牵涉到无内存或文件句柄资源分配的初始类型），编译器默认选择复制，
2. 否则，编译器会转移其所有权并使原来的绑定无效。

即，无格式数据=>复制，线性类型=>转移。(原文为：In short, pod (plain old data) => copy, non-pod (linear types) => move.)

这里有一些附加的提醒：

- Rust的复制和C一样。任何对值引用的传递是通过一个字节的复制（浅复制）而非实际意义上的复制或克隆。(原文：Every by-value use of a value is a byte copy (shallow memcpy copy) instead of a semantic copy or clone.)
- 你可以用`NoCopy`标记域或实现`Drop`特性来使可复制的结构体不可复制。

# 资源的释放

当资源的所有权一旦消失Rust就会释放资源，即当：
1. 所有者离开作用域，或
2. 所有权绑定改变（即原始的绑定失效）

# 所有者和租借者的特权和约束

这部分基于Rust指南复制和转移的特权部分。

一个所有者有如下特权：
1. 控制资源的释放，
2. 以不可变方式（可多个）或可变方式（唯一）出借资源，
3. 通过转移移交所有权

和如下约束：
1. 在出租期间，所有者无法改变资源和以可变方式再次出租
2. 在可借方式出租期间，所有者无法访问资源和出租资源

租借者也有一些特权，除了访问和改变借到的资源外，还可以再次出租资源：

1. 租借者可以分享（复制）一个不可变的租借
2. 一个可变方式的租借者可以移交（转移）其可变租借权（注：可变的引用默认是转移的）

# 代码示例

说的够多了，来看看一些代码吧（你可以在[rust playpen](http://play.rust-lang.org)运行代码）。在下述例子中，我们用包含框值（堆分配的）的`sruct Foo`来代表不可复制的资源。用不可复制的资源使得操作更加受限，这对于学习很有帮助。

对于每一个示例代码，我们都提供了“作用域图表”来展示所有者和租借者等的作用域，在首行的大括号与代码中的大括号一一对应。

## 所有者在可变租借期间无法访问资源

如果取消最后一行`println!`的注释，下面代码将无法编译

```rust
struct Foo {
    f: Box<int>,
}

fn main() {
    let mut a = Foo { f: box 0 };
    // mutable borrow
    let x = &mut a;
    // error: cannot borrow `a.f` as immutable because `a` is also borrowed as mutable
    // println!("{}", a.f);
}
```

```rust
           { a x * }
   owner a   |_____|
borrower x     |___| x = &mut a
access a.f       |   error
```
因为它违反了所有者的约束2，即可变租借期间所有者无法访问资源。如果我们将`let x = &mut a;`放在区块里面，那么租借在区块外就结束了，则`println!`行可以正常工作。

```rust
fn main() {
    let mut a = Foo { f: box 0 };
    {
        // mutable borrow
        let x = &mut a;
        // mutable borrow ends here
    }
    println!("{}", a.f);
}
```

```rust
           { a { x } * }
   owner a   |_________|
borrower x       |_|     x = &mut a
access a.f           |   OK
```

## 租借者可以将可变租借移交给新的租借者

下面代码展示的是租借者的特权2，即可变租借者`x`可以将可变租借权移交（转移）给新的租借者`y`。

```rust
fn main() {
    let mut a = Foo { f: box 0 };
    // mutable borrow
    let x = &mut a;
    // move the mutable borrow to new borrower y
    let y = x;
    // error: use of moved value: `x.f`
    // println!("{}", x.f);
}
```

```rust
           { a x y * }
   owner a   |_______|
borrower x     |_|     x = &mut a
borrower y       |___| y = x
access x.f         |   error
```
在移交之后，原始的租借者`x`将无法再访问租借的资源。

# 租借范围

当我们到处传递引用（`&`和`&mut`）时，事情将变得有意思，这也是很多Rust新手感到困惑的地方

## 生存周期

在整个租借的过程中，搞清楚租借的启止位置至关重要。在Rust指南中，这被称为生存周期：

> 生存周期是指引用指针有效的一段静态近似范围：其总是对应与程序中一些语句或区块。

然而，我更愿意使用“租借范围”来称呼租借有效的范围。注意这实际上与上面“生存周期”的定义不同（我第一次看到这个词是在Rust的RFC讨论里，虽然我的定义略有区别）。我之后会指出为什么我避免使用“生存周期”，暂时我们先把“生存周期”放一边。

## & = 租借

关于租借：

第一：只需记住`&`=租借，`&mut`=可变租借。任何时候你看到`&`，就是一个租借。

第二：当`&`出现在结构体（其域）或函数/闭包（其返回类型或截获引用），结构体/函数/闭包就是租借者，所有租借规则开始起效果。

第三：对于任何租借，有且仅有一个所有者，并有一个或多个租借者。

## 扩展租借范围

关于租借范围：

第一，租借范围是：
- 租借有效的范围
- 并不一定与租借者的范围一致，因为租借范围可以被租借者扩展（见下）

第二，一个租借者可以通过复制（不可变租借）或转移（可变租借）来扩展租借范围，这通常发生在赋值或函数调用中。接受者（可以是一个新的绑定，结构体，函数或闭包）将变为新的租借者。

第三，租借范围是所有租借者范围的合集，租借的资源必须在整个租借范围都有效。

## 租借公式

对于最后一点，我们有如下租借公式：
> 资源的存在范围>=租借范围=所有租借者范围的合集

## 代码示例

让我们看些扩展租借范围的例子。`struct Foo`与前面定义一致：

```rust
fn main() {
    let mut a = Foo { f: box 0 };
    let y: &Foo;
    if false {
        // borrow
        let x = &a;
        // share the borrow with new borrower y, hence extend the borrow scope
        y = x;
    }
    // error: cannot assign to `a.f` because it is borrowed
    // a.f = box 1;
}
```

```rust
             { a { x y } * }
  resource a   |___________|
  borrower x       |___|     x = &a
  borrower y         |_____| y = x
borrow scope       |=======|
  mutate a.f             |   error
```

即使租借发生在`if`区块里面并且原始租借者`x`在`if`区块外就变为无效，然而它已经通过`y = x;`来扩展了租借范围，所以这里有两个租借者：`x`和`y`。根据租借公式，租借范围是两个租借者范围的合集，即从第一次租借`let x = &a;`开始，到`main`区块结束（注意`y`在`y = x;`之前并不是租借者）。

你可能已经注意到`if`区块永不执行，因为其条件判断总为`false`，但编译器仍然禁止资源所有者`a`访问其资源。这是因为所有租借检查都发生在编译时，与程序实际执行无关。

# 租借多个资源

到目前为止，我们只关注于租借单个资源。一个租借者可以租借多个资源吗？当然可以！比如，一个函数可以有两个引用并根据条件返回其中一个，比如返回其域中较大的那个：

```rust
fn max(x: &Foo, y: &Foo) -> &Foo
```

`max`函数返回一个`&`指针，因此是一个租借者。返回值可以是任何一个输入参数，故它租借了两个资源。

## 命名的租借范围

当有多个`&`指针作为输入时，我们需要通过“命名的生存周期”来指出它们的关系。对于现在，让我们暂时称其为“命名的租借范围”。

上面的代码会因为没有指定租借者之间的关系而无法编译，即哪个租借者是在哪个租借者的内部。下面的实现是有效的：
```rust
fn max<'a>(x: &'a Foo, y: &'a Foo) -> &'a Foo {
    if x.f > y.f { x } else { y }
}
```

```rust
(All resources and borrowers are grouped in borrow scope 'a.)
                  max( {   } ) 
    resource *x <-------------->
    resource *y <-------------->
borrow scope 'a <==============>
     borrower x        |___|
     borrower y        |___|
   return value          |___|   pass to the caller
```

在这个函数中，我们有一个租借范围`'a`和三个租借者：两个输入参数和函数的返回值。之前提到的租借公式仍然适用，并且每一个租借的资源都必须满足该公式。见如下例子。

## 代码示例

在随后的代码中，我们用`max`函数来挑出`a`和`b`中较大的`Foo`：

```rust
fn main() {
    let a = Foo { f: box 1 };
    let y: &Foo;
    if false {
        let b = Foo { f: box 0 };
        let x = max(&a, &b);
        // error: `b` does not live long enough
        // y = x;
    }
}
```

```rust
              { a { b x (  ) y } }
   resource a   |________________| pass
   resource b       |__________|   fail
 borrow scope         |==========|
temp borrower            |_|       &a
temp borrower            |_|       &b
   borrower x         |________|   x = max(&a, &b)
   borrower y                |___| y = x
```

到`let x = max(&a, &b);`为止，一切都正常，因为`&a`和`&b`是只在表达式中有效的临时引用，而第三个租借者`x`租借了两个资源（要么`a`要么`b`，但对于租借检查器而言它租借了两个），直到`if`区块结束，所以租借范围为从`let x = max(&a, &b);`到`if`区块结束。资源`a`和`b`在该租借范围内都有效。因此满足租借公式。

现在我们取消`y =x;`赋值的注释，`y`变为第四个租借者，租借范围扩展到`main`区块结束，资源`b`的范围违反了公式。

# 结构体作为租借者

除了函数和闭包外，结构体也可以通过在其域内保存多个引用来租借多个资源。我们随后将看到租借方程应用的一些例子。让我们用`Link`结构体来保存一个引用（一个不可变的租借）

```rust
struct Link<'a> {
    link: &'a Foo,
}
```

## 结构体租借多个资源

即使是只有一个域，结构体`Link`也能租借多个资源：

```rust
fn main() {
    let a = Foo { f: box 0 };
    let mut x = Link { link: &a };
    if false {
        let b = Foo { f: box 1 };
        // error: `b` does not live long enough
        // x.link = &b;
    }
}
```

```rust
             { a x { b * } }
  resource a   |___________| pass
  resource b         |___|   fail
borrow scope     |=========|
  borrower x     |_________| x.link = &a
  borrower x           |___| x.link = &b
```

在上述例子中，租借者`x`从所有者`a`中租借资源，租借范围知道`main`区块结束。目前为止一切顺利。如果我们取消最后一行赋值`x.link = &b;`，`x`试图从所有者`b`中租借资源，这会导致资源`b`违反租借公式。

## 用无返回值函数来扩展租借范围

一个无返回值的函数能通过其输入参数来扩展租借范围。例如，`store_foo`函数获得`Link`的可变引用，并在其内保存`Foo`的引用（不可变租借）：

```rust
fn store_foo<'a>(x: &mut Link<'a>, y: &'a Foo) {
    x.link = y;
}
```

在接下来的代码中，被`a`所有的资源是被租借的资源；被`x`可变引用的`Link`结构体是租借者（即`*x`是租借者）；租借范围直到`main`区块结束。

```rust
fn main() {
    let a = Foo { f: box 0 };
    let x = &mut Link { link: &a };
    if false {
        let b = Foo { f: box 1 };
        // store_foo(x, &b);
    }
}
```

```rust
             { a x { b * } }
  resource a   |___________| pass
  resource b         |___|   fail
borrow scope     |=========|
 borrower *x     |_________| x.link = &a
 borrower *x           |___| x.link = &b
```

如果我们取消最后调用函数`store_foo(x, &b);`那行的注释，函数会试图在`x.link`中储存`&b`，将使得资源`b`变为另一个被租借的资源，从而违背租借公式，因为资源`b`的作用域并不覆盖整个租借范围。

## 多个租借范围

在一个函数中存在多个命名的租借范围是许可的，比如：
```rust
fn superstore_foo<'a, 'b>(x: &mut Link<'a>, y: &'a Foo,
                          x2: &mut Link<'b>, y2: &'b Foo) {
    x.link = y;
    x2.link = y2;
}
```

在这个（可能不太有用的）函数中，涉及到两个脱耦的租借范围。每一个租借范围都有自己的租借公式需要满足。

# 为什么生存周期令人困惑

最后，我想要解释下为什么我认为Rust在租借系统中所用“生存周期”这个词令人困惑（因此我在这篇文章中避免使用这词）。

但我们提到租借，涉及到三类不同的“生存周期”：

- A：资源所有者（或被所有/租借的资源）的生存周期
- B：整个租借的生存周期，即从第一个租借靠最后一个为止
- C：每个单独租借者或被租借的指针的生存周期

当提到“生存周期”时，可以指上面任何一种，如果涉及到多个资源和租借者，事情将会变得更加令人困惑。比如，在函数或结构体声明中的“命名生存周期”指的是什么，是A，B还是C？

在我们前面提到过的`max`函数：
```rust
fn max<'a>(x: &'a Foo, y: &'a Foo) -> &'a Foo {
    if x.f > y.f { x } else { y }
}
```
这里生存周期`'a`指的是什么？不可能是A，因为涉及的两个资源可能有不同的生存周期。不可能是C，因为三个租借者`x`，`y`和函数返回值，都可能有不同的生存周期。指的是B吗？可能吧。但是整个租借范围不是一个具体的对象，怎么会有“生存周期”呢，叫其生存周期只会引起误解。

有人会说它代表的是被租借的资源最小需要的生存周期。这在某种程度上说得过去，但我们怎么能把最小需要的生存周期称为“一个生存周期”呢？

所有权和租借概念已经挺复杂了，我会说“生存周期”这词使得学习这些概念变得更加令人困惑。

P.S. 使用上述定义的A，B和C，租借方程变为

> A >= B =C1 U C2 U ... U Cn

# Rust值得你花时间学习

尽管掌握租借和所有权需要花些时间，学习过程却是有趣的。Rust期望脱离垃圾回收来实现内存安全，并且现在看来它做的非常不错。人们说学习Haskell会改变你编程的方式。我认为学习Rust也不会辜负你的时间。

期待本文会给你一点帮助。


