# 引导并运行UEFI应用程序

编译得到UEFI可执行文件之后，我们需要将其放在一个UEFI固件可以找到的位置，并创建一个启动盘来运行这个程序。使用U盘是一个简单的办法，接下来将介绍如何创建这么一个启动U盘。

UEFI可以识别FAT格式的文件系统。因此，我们首先需要把U盘格式化成FAT32格式。

格式化成FAT32格式可以使用任何你喜欢的方式。这里介绍使用`fdisk`来格式化的方式（例子中，U盘的设备路径为`/dev/sdb`）。

**警告：下面的操作将删除U盘上的所有文件，请在操作前做好备份工作**

```shell
$ sudo fdisk /dev/sdb
Welcome to fdisk (util-linux 2.25.2).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Command (m for help): o             # 创建新的DOS分区表
Created a new DOS disklabel with disk identifier 0xde746309.

Command (m for help): n             # 建立新的分区
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p): p
Partition number (1-4, default 1): 1
First sector (2048-15228927, default 2048):
Last sector, +sectors or +size{K,M,G,T,P} (2048-15228927, default 15228927):
Created a new partition 1 of type 'Linux' and of size 7.3 GiB.

Command (m for help): t             # 改变分区类型
Selected partition 1
Hex code (type L to list all codes): b
If you have created or modified any DOS 6.x partitions, please see the fdisk \\
documentation for additional information.
Changed type of partition 'Linux' to 'W95 FAT32'.

Command (m for help): w             # 保存分区表
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.

$ sudo mkfs.vfat -F 32 /dev/sdb1    # 格式化分区
mkfs.fat 3.0.27 (2014-11-12)
```

格式化完成后，将先前的`main.efi`重命名为`BOOTX64.EFI`，并放在U盘中的`EFI/BOOT`目录下。你可以用下面的命令来完成这个操作：

```shell
$ sudo mount /dev/sdb1 /mnt
$ sudo mkdir -p /mnt/EFI/BOOT
$ sudo cp main.efi /mnt/EFI/BOOT/BOOTX64.EFI
$ sudo umount /mnt
```

关闭计算机，并从刚才所制作的U盘启动，屏幕上将会显示“Hello UEFI!”（图2.7）。

![屏幕上显示的“Hello UEFI!”](../../images/part1/hello.png)

图2.7: 屏幕上显示的“Hello UEFI!”

由于我们的UEFI应用程序没有关机功能，所以请轻按电源键关机来退出。（记得拔掉你的U盘）


> **使用EFI Shell运行UEFI应用程序**
> 
> *本段为译者补充*
> 
> 如果你的电脑固件中带有EFI Shell，恭喜你，你只需要将可执行文件放在U盘中，启动到EFI Shell中，就可以手动运行它。EFI Shell的操作与一般的*nix shell非常类似，并且也拥有Tab自动补全功能。
> 
> 要找到装有可执行文件U盘，使用`map -r`命令列出所有的被UEFI识别的文件系统，使用`fs#:`命令进入某个文件系统（例如`fs0:`），此时命令提示符将会变化。
> 
> 进入文件系统后，使用`ls`命令可以列出根目录下的文件，输入文件名就可以执行相应的UEFI应用程序。
> 
> 在EFI Shell中，除了切换文件系统需要用到`fs#:`命令，其他的`cd`, `ls`等命令，与一般的shell是类似的。

> **在QEMU上运行**[^1]
> 
> UEFI应用程序也可以在QEMU中运行。但是，QEMU默认不带有UEFI固件，我们需要手动安装OVMF(Open Virtual Machine Firmware)软件包。
> 
> ```shell
> $ sudo apt install qemu-system-x86 ovmf
> ```
> 
> QEMU有将目录挂载为虚拟FAT驱动器的功能。例如，创建一个名为`esp`的目录，将efi文件放到`esp/EFI/BOOT/BOOTX64.EFI`并使用`-drive file=fat:rw:esp,index=0,format=vvfat`选项运行QEMU。虚拟机将会把`esp`目录认作是一个FAT驱动器分区，并会自动启动到其中的`BOOTX64.EFI`文件。
> 
> ```shell
> $ qemu-system-x86_64 -bios /usr/share/OVMF/OVMF_CODE.fd -net none \ 
>                      -drive file=fat:rw:esp,index=0,format=vvfat
> ```
> 
> 其中`-net none`通过禁用网卡阻止QEMU尝试PXE启动。
> 
> 此外，在[示例代码](https://github.com/kagurazakakotori/ubmp-cn-code)各个例子的Makefile中，包含了QEMU的执行规则。执行`make run`命令就可以编译并在QEMU中运行相应的UEFI应用程序。
> 
> ```shell
> $ cd ubmp-cn-code/baremetal/<各个例子的目录>
> $ make run
> ```
> 
> 然而，QEMU/OVMF存在未实现或是无法运行的功能。在编写本书时，本书中用到的用于获取鼠标输入的`EFI_SIMPLE_POINTER_PROTOCOL`无法在虚拟机上运行。[^2]
>
> 关于示例代码Makefile的更多功能，参见示例代码根目录下的README文件。

> **显示非ASCII字符**（中日韩文字）
> 
> 中日韩文字可以在Unicode中表示。但是，各个UEFI固件所支持显示的文字有所不同。在作者的联想ThinkPad E450的UEFI固件（版本2.3.1中），平假名和一部分汉字无法显示。
> 
> 另外，在QEMU/OVMF中，所有的非ASCII字符均无法显示。比如示例代码`hello-cjk`中，我们在屏幕上打印下面这些文字:
> 
> > Hello world
> >
> > 你好，UEFI！
> >
> > こんにちは、UEFI！
> 
> 在OVMF (版本20191122) 下会看到图2.8这样的结果。
> 
> ![QEMU/OVMF中非ASCII字符显示](../../images/part1/hello-cjk.png)
> 
> 图2.8: QEMU/OVMF中的非ASCII字符显示


[^1]: 译者注：这里介绍的是中文版示例代码做法，与日文版并非完全相同

[^2]: 译者注：无法运行并不是因为QEMU/OVMF不支持，而是因为OVMF自身不带鼠标驱动，手动载入鼠标驱动即可解决问题。幸运的是，译者已经在中文版所有涉及鼠标的例子中加入了载入鼠标驱动的脚本 (所用驱动`UsbMouseDxe.efi`[^1]来自 [Clover EFI bootloader r5070](https://sourceforge.net/projects/cloverefiboot/))，你只需要执行`make run`并稍作等待就可以在QEMU下体验了。

[^3]: 译者注：使用`UsbMouseDxe.efi`而非`Ps2MouseDxe.efi`是由于QEMU默认的PS/2鼠标无法被识别，这里使用USB鼠标替代。具体无法识别的原因未知。
