# GUI下列出文件

直到现在，我们的GUI仅仅显示了一个矩形图标，并没有任何实际的功能。这一节我们来把文件名放入矩形中。本节示例代码的目录为`gui-ls` (日文版为`sample5_2_gui_ls`)。

处理的过程很简单，在列出目录下的文件名后，再绘制包裹这些文件名的矩形。这里为了简化处理，我们假定文件名都是三字符长的。

首先，我们需要在文件信息结构体中加入矩形的信息，和矩形是否高亮。代码6.10展示了`file.h`中的更改。

```c
/* ...省略... */
struct FILE {
    struct RECT rect;            /* 新增 */
    unsigned char is_highlight;  /* 新增 */
    unsigned short name[MAX_FILE_NAME_LEN];
};
/* ...省略... */
```

代码6.10: `sample5_2_gui_ls/file.h`

代码6.11展示了在之前基础上向`gui.c`中加入列出文件功能的代码。

```c
#include "efi.h"
#include "common.h"
#include "file.h"
#include "graphics.h"
#include "shell.h"
#include "gui.h"

#define WIDTH_PER_CH     8   /* 新增 */
#define HEIGHT_PER_CH    20  /* 新增 */

/* ...省略... */

/* 新增(此处开始) */
int ls_gui(void)
{
    int file_num;
    struct RECT t;
    int idx;

    ST->ConOut->ClearScreen(ST->ConOut);

    file_num = ls();

    t.x = 0;
    t.y = 0;
    t.w = (MAX_FILE_NAME_LEN - 1) * WIDTH_PER_CH;
    t.h = HEIGHT_PER_CH;
    for (idx = 0; idx < file_num; idx++) {
        file_list[idx].rect.x = t.x;
        file_list[idx].rect.y = t.y;
        file_list[idx].rect.w = t.w;
        file_list[idx].rect.h = t.h;
        draw_rect(file_list[idx].rect, white);
        t.x += file_list[idx].rect.w + WIDTH_PER_CH;

        file_list[idx].is_highlight = FALSE;
    }

    return file_num;
}
/* 新增(此处结束) */

void gui(void)
{
    unsigned long long status;
    struct EFI_SIMPLE_POINTER_STATE s;
    int px = 0, py = 0;
    unsigned long long waitidx;
    int file_num;  /* 新增 */
    int idx;       /* 新增 */

    SPP->Reset(SPP, FALSE);
    file_num = ls_gui();  /* 新增 */

    while (TRUE) {
        ST->BootServices->WaitForEvent(1, &(SPP->WaitForInput), &waitidx);
        status = SPP->GetState(SPP, &s);
        if (!status) {
            /* ...省略... */
            /* 新增(此处开始) */
            /* 鼠标悬浮于矩形图标上时，高亮矩形图标 */
            for (idx = 0; idx < file_num; idx++) {
                if (is_in_rect(px, py, file_list[idx].rect)) {
                    if (!file_list[idx].is_highlight) {
                        draw_rect(file_list[idx].rect, yellow);
                        file_list[idx].is_highlight = TRUE;
                    }
                } else {
                    if (file_list[idx].is_highlight) {
                        draw_rect(file_list[idx].rect, white);
                        file_list[idx].is_highlight = FALSE;
                    }
                }
            }
            /* 新增(此处结束) */
        }
    }
}
```

代码6.11: `sample5_2_gui_ls/gui.c`

代码6.11中的`ls_gui`函数是对`shell.c`中的`ls`函数的封装。这个函数在清屏后调用`ls`函数来列出根目录下的文件和目录，然后设置各个文件对应的矩形图标位置、大小和高亮状态，并将这些信息保存在`file_list`数组中，最后在屏幕上绘制这些矩形图标。

代码6.11`gui`函数中新增的处理文件图标的循环和上一章实现的对矩形图标的处理一样，在鼠标指针悬浮在某个文件的图标上时，矩形框将会被设为高亮色。

图6.2展示了上述代码运行时的样子。

![加入了列出文件功能的GUI](../../images/part1/gui-ls.png)

图6.2: 加入了列出文件功能的GUI
