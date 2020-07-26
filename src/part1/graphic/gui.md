# 制作一个简单的GUI

这一章的最后，我们来制作一个非常简单的GUI，并且往Shell中加入一个`gui`命令来调用它。本节示例代码的目录为`guimode` (日文版为`sample3_2_add_gui_mode`)。

首先，我们为"GUI"创建一个源文件`gui.c`。这个简单的GUI只有一个矩形图标，其实现如代码4.10所示。

```c
#include "efi.h"
#include "common.h"
#include "graphics.h"
#include "gui.h"

void gui(void)
{
    struct RECT r = {10, 10, 20, 20};

    ST->ConOut->ClearScreen(ST->ConOut);

    /* 绘制一个矩形图标 */
    draw_rect(r, white);

    while (TRUE);
}
```

代码4.10: `guimode/gui.c`

接着，我们往Shell中加入一个`gui`命令。当我们输入这个命令时，它会调用上面`gui.c`中的`gui`函数。添加了这条命令后的`shell.c`如代码4.11所示。

```c
#include "common.h"
#include "graphics.h"
#include "shell.h"
#include "gui.h"  /* 新增 */

#define MAX_COMMAND_LEN  100

void shell(void)
{
    unsigned short com[MAX_COMMAND_LEN];
    struct RECT r = {10, 10, 100, 200};

    while (TRUE) {
        puts(L"poiOS> ");
        if (gets(com, MAX_COMMAND_LEN) <= 0)
            continue;

        if (!strcmp(L"hello", com))
            puts(L"Hello UEFI!\r\n");
        else if (!strcmp(L"rect", com))
            draw_rect(r, white);
        else if (!strcmp(L"gui", com))  /* 新增 */
            gui();                      /* 新增 */
        else
            puts(L"Command not found.\r\n");
    }
}
```

代码4.11: `guimode/shell.c`

如图4.3所示，当执行`gui`命令时，会进入一个全新的界面，其中只有一个矩形图标。

![显示一个矩形图标的简易GUI](../../images/part1/guimode.png)

图4.3: 显示一个矩形图标的简易GUI
