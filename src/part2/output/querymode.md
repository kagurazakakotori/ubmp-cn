# 获取支持的文本显示模式

到目前为止，我们的控制台输出所用的都是UEFI默认的文本显示模式(Text mode)。通过切换到其它设备支持的文本显示模式，我们可以改变屏幕显示的行数和列数。本节将讲述如何获取设备支持的文本显示模式。

本节示例代码的目录为`query-text-mode` (日文版为`012_simple_text_output_query_mode`)。

利用`QueryMode()`函数可以通过某个文本显示模式的ID来获取它对应的行数和列数，图2.8展示了它的定义。

```c
struct EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL {
    ...
    unsigned long long (*QueryMode)(
        struct EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *This,
        unsigned long long ModeNumber,  /* 要查询的文本显示模式ID */
        unsigned long long *Columns,    /* 指向存放返回的列数的变量的指针 */
        unsigned long long *Rows        /* 指向存放返回的行数的变量的指针 */
        );
    ...
};
```

图2.8: `QueryMode()`的定义（位于`efi.h`中）

当`QueryMode()`的第二个参数`ModeNumber`的值在所支持的文本显示模式的范围外时，将会返回`EFI_UNSUPPORTED(0x80000000 00000003)`。

要获取设备支持的文本显示模式的范围，需要用到`EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL->Mode->MaxMode`这个值，所有支持的文本显示模式的都在`[0, MaxMode - 1]`这个区间内。而`EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL->Mode`是一个`SIMPLE_TEXT_OUTPUT_MODE`的结构体，它的定义如图2.9所示。

```c
#define EFI_SUCCESS      0
#define EFI_ERROR        0x8000000000000000
#define EFI_UNSUPPORTED  (EFI_ERROR | 3)

struct SIMPLE_TEXT_OUTPUT_MODE {
    int MaxMode;                  /* 所支持的文本显示模式的ID上限 */
    int Mode;                     /* 当前的文本显示模式ID */
    int Attribute;                /* 当前设置的文字颜色和背景色 */
    int CursorColumn;             /* 当前光标所在列 */
    int CursorRow;                /* 当前光标所在行 */
    unsigned char CursorVisible;  /* 当前是否显示光标 */
};
```

图2.9: `SIMPLE_TEXT_OUTPUT_MODE`结构体的定义（位于`efi.h`中）

在上面的基础上，使用`QueryMode()`的一个例子如图2.10所示

```c
#include "efi.h"
#include "common.h"

void efi_main(void *ImageHandle __attribute__ ((unused)),
          struct EFI_SYSTEM_TABLE *SystemTable)
{
    int mode;
    unsigned long long status;
    unsigned long long col, row;

    efi_init(SystemTable);
    ST->ConOut->ClearScreen(ST->ConOut);

    for (mode = 0; mode < ST->ConOut->Mode->MaxMode; mode++) {
        status = ST->ConOut->QueryMode(ST->ConOut, mode, &col, &row);
        switch (status) {
        case EFI_SUCCESS:
            puth(mode, 2);
            puts(L": ");
            puth(col, 4);
            puts(L" x ");
            puth(row, 4);
            puts(L"\r\n");
            break;

        case EFI_UNSUPPORTED:
            puth(mode, 2);
            puts(L": unsupported\r\n");
            break;

        default:
            assert(status, L"QueryMode");
            break;
        }
    }

    while (TRUE);
}
```

图2.10: 使用`QueryMode()`的例子

这个例子列出所有`[0, MaxMode - 1]`区间内受支持的文本显示模式的行数和列数的16进制值，如图2.11所示。

![运行图2.10的程序的情况](../../images/part2/query-text-mode.png)

图2.11: 运行图2.10的程序的情况
