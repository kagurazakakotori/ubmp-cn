# 交叉编译为UEFI可执行格式

编写完源代码之后，我们需要将它编译成UEFI可以执行的PE32+[^1][^2]格式。由于Linux的可执行文件为ELF格式，这里我们需要进行交叉编译。

在交叉编译之前，我们需要安装相对应的交叉编译器`gcc-mingw-w64-x86-64`：

```shell
$ sudo apt install gcc-mingw-w64-x86-64
```

安装完成后，使用下面的命令进行编译：

```shell
$ x86_64-w64-mingw32-gcc -Wall -Wextra -e efi_main -nostdinc -nostdlib \
        -fno-builtin -Wl,--subsystem,10 -o main.efi main.c
```

参数`-e`用于指定程序入口点，这里我们指定为`efi_main`，这意味着程序将从`efi_main`函数开始运行。另外，参数`--subsystem,10`告诉编译器将生成的可执行文件类型设置为UEFI应用程序。得到的`main.efi`就是PE32+格式的UEFI可执行文件。

此外，其他能够编译成UEFI应用程序类型的PE32+格式可执行文件的方法也是可以的。例如使用Windows上的[`x86_64-w64-mingw32-gcc`](https://sourceforge.net/projects/mingw-w64/)[^3]。


> **使用Makefile自动编译**
> 
> [示例代码](https://github.com/kagurazakakotori/ubmp-cn-code)中包括了Makefile文件。我们只需要进入各个例子的目录中，执行`make`命令，就可以轻松的完成编译。
> 
> ```shell
> $ cd ubmp-cn-code/baremetal/<各个例子的目录>
> $ make
> ```
> 
> 编译得到的可执行文件位于各个例子的目录下。[^4]


[^1]: 这是Windows的可执行文件格式

[^2]: 译者注：PE32+为64位Windows的可执行文件格式，32位的为PE32

[^3]: 参考资料：[Windows(64ビット環境)でvimprocをコンパイルしてみよう](http://qiita.com/akase244/items/ce5e2e18ad5883e98a77)（在64位Windows环境下编译vimproc/日语）

[^4]: 译者注：这里介绍的是中文版示例代码的Makefile，日文版编译得到的可执行文件位于`./fs/EFI/BOOT/BOOTX64.EFI`
