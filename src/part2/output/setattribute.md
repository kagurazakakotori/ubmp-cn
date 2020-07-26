# 设置文字颜色和背景色

通过调用`SetAttribute()`函数我们可以设置文字的颜色和背景色（图2.1）。

本节示例代码的目录为`text-color` (日文版为`010_simple_text_output_set_attribute`)。[^1]

```c
//*******************************************************
// Attributes
//*******************************************************
#define EFI_BLACK         0x00
#define EFI_BLUE          0x01
#define EFI_GREEN         0x02
#define EFI_CYAN          0x03
#define EFI_RED           0x04
#define EFI_MAGENTA       0x05
#define EFI_BROWN         0x06
#define EFI_LIGHTGRAY     0x07
#define EFI_BRIGHT        0x08
#define EFI_DARKGRAY      0x08
#define EFI_LIGHTBLUE     0x09
#define EFI_LIGHTGREEN    0x0A
#define EFI_LIGHTCYAN     0x0B
#define EFI_LIGHTRED      0x0C
#define EFI_LIGHTMAGENTA  0x0D
#define EFI_YELLOW        0x0E
#define EFI_WHITE         0x0F

#define EFI_BACKGROUND_BLACK      0x00
#define EFI_BACKGROUND_BLUE       0x10
#define EFI_BACKGROUND_GREEN      0x20
#define EFI_BACKGROUND_CYAN       0x30
#define EFI_BACKGROUND_RED        0x40
#define EFI_BACKGROUND_MAGENTA    0x50
#define EFI_BACKGROUND_BROWN      0x60
#define EFI_BACKGROUND_LIGHTGRAY  0x70

struct EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL {
    ...
    unsigned long long (*SetAttribute)(
        struct EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *This,
        unsigned long long Attribute
            /* 要设置的文字颜色和背景色，可设置的颜色如上面的宏定义所示 */
        );
    ...
};
```

图2.1: `SetAttribute()`相关的定义（位于`efi.h`中）

第二个参数`Attribute`是1个字节的文字颜色和背景色的值，其中高4位为背景色，低4位为文字颜色。

使用`SetAttribute()`函数来输出本书封面的代码如图2.2所示.

```c
#include "efi.h"
#include "common.h"

void efi_main(void *ImageHandle __attribute__ ((unused)),
          struct EFI_SYSTEM_TABLE *SystemTable)
{
    efi_init(SystemTable);

    puts(L" ");

    ST->ConOut->SetAttribute(ST->ConOut, EFI_LIGHTGREEN | EFI_BACKGROUND_LIGHTGRAY);
    ST->ConOut->ClearScreen(ST->ConOut);
    puts(L"Light Green Text\r\n");

    ST->ConOut->SetAttribute(ST->ConOut, EFI_LIGHTRED | EFI_BACKGROUND_LIGHTGRAY);
    puts(L"Light Red Text\r\n");

    ST->ConOut->SetAttribute(ST->ConOut, EFI_LIGHTBLUE | EFI_BACKGROUND_LIGHTGRAY);
    puts(L"Light Blue Text\r\n");

    ST->ConOut->SetAttribute(ST->ConOut, EFI_LIGHTMAGENTA | EFI_BACKGROUND_LIGHTGRAY);
    puts(L"Light Magenta Text\r\n");

    ST->ConOut->SetAttribute(ST->ConOut, EFI_WHITE | EFI_BACKGROUND_LIGHTGRAY);
    puts(L"White Text\r\n");

    ST->ConOut->SetAttribute(ST->ConOut, EFI_LIGHTCYAN | EFI_BACKGROUND_LIGHTGRAY);
    puts(L"Light Cyan Text\r\n");

    ST->ConOut->SetAttribute(ST->ConOut, EFI_MAGENTA | EFI_BACKGROUND_LIGHTGRAY);
    puts(L"Magenta Text\r\n");

    while (TRUE);
}
```

图2.2: 使用`SetAttribute()`的例子

上面的代码在调用`efi_init()`后先输出了一个空格，这是为了适配部分计算机的UEFI固件。某些UEFI固件，例如作者的联想笔记本的固件，在启动后不输出任何内容的情况下直接调用`ClearScreen()`进行清屏似乎会被忽略。即使这里我们先调用`SetAttribute()`设置背景色，再调用`ClearScreen()`清屏，屏幕的背景色也不会被设为我们指定的颜色。[^2]。

![图2.2程序显示的彩色字符](../../images/part2/text-color.png)

图2.3: 图2.2程序显示的彩色字符


[^1]: 译者注：日文版中这一节的例子是输出本书的封面，考虑到大部分计算机的UEFI固件和OVMF都不支持显示日语字符，这里将其修改成了其它内容。

[^2]: 不能理解为什么固件实现上要在没有任何内容被输出到屏幕时忽略对`ClearScreen()`的调用。这里要实现的效果是在调用`SetAttribute()`之后改变整个画面的背景色。
