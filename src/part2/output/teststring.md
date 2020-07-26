# 检测字符串是否能被显示

UEFI的字符编码虽然是Unicode，包括了中文和日语字符，但是在各个UEFI固件的实现中，可以显示的Unicode字符却是存在差异的。

我们可以使用`TestString()`函数可以来检测一个字符串或者某个字符是否能被显示，图2.4展示了它的定义。

本节示例代码的目录为`test-string` (日文版为`011_simple_text_output_test_string`)。

```c
struct EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL {
    ...
    unsigned long long (*TestString)(
        struct EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *This,
        unsigned short *String
            /* 所要检测的字符串的起始地址 */
        );
    ...
};
```

图2.4: `TestString()`的定义（位于`efi.h`中）

`TestString()`检测参数中指定的字符串能否被显示并返回结果。如果可以被显示，返回`EFI_SUCCESS(0)`，如果字符串中存在无法显示的字符，则返回`EFI_UNSUPPORTED(0x80000000 00000003)`。

使用`TestString()`的一个例子如图2.5所示。[^1]

```c
#include "efi.h"
#include "common.h"

void efi_main(void *ImageHandle __attribute__ ((unused)),
          struct EFI_SYSTEM_TABLE *SystemTable)
{
    efi_init(SystemTable);
    ST->ConOut->ClearScreen(ST->ConOut);

    /* test1 */
    if (!ST->ConOut->TestString(ST->ConOut, L"Hello"))
        puts(L"test1: success\r\n");
    else
        puts(L"test1: fail\r\n");

    /* test2 */
    if (!ST->ConOut->TestString(ST->ConOut, L"你好"))
        puts(L"test2: success\r\n");
    else
        puts(L"test2: fail\r\n");

    /* test3 */
    if (!ST->ConOut->TestString(ST->ConOut, L"Hello, 你好"))
        puts(L"test3: success\r\n");
    else
        puts(L"test3: fail\r\n");

    while (TRUE);
}
```

图2.5: 使用`TestString()`的例子

当在QEMU上运行时，由于OVMF并不支持显示日语字符，因此就像图2.5那样，含有日语的字符串将会返回失败的结果。另外这里我们可能需要对Makefile进行一些修改来在QEMU上运行，具体将在后文说明。

![在QEMU上运行TestString()](../../images/part2/test-string.png)

图2.5: 在QEMU上运行`TestString()`

而在支持显示中文字符的实机上，这三个检测都会返回成功的结果。[^2]


> **QEMU/OVMF上可执行文件大小限制**
> 
> QEMU所使用的UEFI固件实现OVMF对于可执行文件的大小似乎有一定的限制。随着代码量的增长，生成的可执行文件也会变大。在实机上可以运行的UEFI程序，可能在QEMU/OVMF下无法运行（UEFI固件找不到可执行文件）。
> 
> 本书两册主要针对实机环境下的裸机编程，并且所有代码都在作者的联想笔记本上测试通过。为了在QEMU/OVMF上运行本书的示例代码，需要对Makefile进行一定的修改，在编译和链接的对象中去掉未使用的源文件来减小生成程序的大小。
> 
> 例如，为了在QEMU/OVMF上运行图2.4中的程序，需要像图2.7这样修改Makefile，再运行`make`命令进行编译。
> 
> ```diff
> - fs/EFI/BOOT/BOOTX64.EFI: efi.c common.c file.c graphics.c shell.c gui.c
> + fs/EFI/BOOT/BOOTX64.EFI: efi.c common.c main.c
>     mkdir -p fs/EFI/BOOT
>     x86_64-w64-mingw32-gcc -Wall -Wextra -e efi_main -nostdinc \
>     -nostdlib -fno-builtin -Wl,--subsystem,10 -o $@ $+
> ```
> 
> 图2.7: 为在QEMU/OVMF上运行所做的修改
>
> *复制Makefile时请留意将空格转换为Tab


[^1]: 译者注：日文版中这个例子测试的是带日语字符的字符串，这里改成了中文。

[^1]: 译者注：由于译者没有支持中文显示的设备，略去了三个test均成功的结果图片。
