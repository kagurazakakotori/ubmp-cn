# 实现退出功能

## 退出Shell功能

我们来加入一条`exit`命令用来退出Shell，这个功能实现起来非常容易，只需对`shell.c`中的`shell`函数稍作修改即可（代码7.4）。

```c
void shell(void)
{
    unsigned short com[MAX_COMMAND_LEN];
    struct RECT r = {10, 10, 100, 200};
    unsigned char is_exit = FALSE;  /* 新增 */

    while (!is_exit) {  /* 更改 */
        /* ...省略... */
        } else if (!strcmp(L"exit", com))  /* 新增 */
            is_exit = TRUE;                /* 新增 */
        else
            puts(L"Command not found.\r\n");
    }
}
```

代码7.4: 在`sample_poios/shell.c:shell`实现`exit`命令

## 退出GUI功能

接下来，我们在GUI的右上角放一个[X]按钮，并且实现点击这个按钮来退出GUI的功能。

这里要修改的只有`gui.c`这个源文件。首先，我们创建两个函数，一个名为`put_exit_button`，用来在右上角绘制[X]按钮；另一个名为`update_exit_button`，用来更新按钮状态（是否高亮）和判定点击事件(代码7.5)。

```c
/* ...省略... */
#define EXIT_BUTTON_WIDTH   20
#define EXIT_BUTTON_HEIGHT  20
/* ...省略... */
struct FILE rect_exit_button;
/* ...省略... */
void put_exit_button(void)
{
    unsigned int hr = GOP->Mode->Info->HorizontalResolution;
    unsigned int x;

    rect_exit_button.rect.x = hr - EXIT_BUTTON_WIDTH;
    rect_exit_button.rect.y = 0;
    rect_exit_button.rect.w = EXIT_BUTTON_WIDTH;
    rect_exit_button.rect.h = EXIT_BUTTON_HEIGHT;
    rect_exit_button.is_highlight = FALSE;
    draw_rect(rect_exit_button.rect, white);

    /* 绘制按钮中的X图案 */
    for (x = 3; x < rect_exit_button.rect.w - 3; x++) {
        draw_pixel(x + rect_exit_button.rect.x, x, white);
        draw_pixel(x + rect_exit_button.rect.x,
               rect_exit_button.rect.w - x, white);
    }
}

unsigned char update_exit_button(int px, int py, unsigned char is_clicked)
{
    unsigned char is_exit = FALSE;

    if (is_in_rect(px, py, rect_exit_button.rect)) {
        if (!rect_exit_button.is_highlight) {
            draw_rect(rect_exit_button.rect, yellow);
            rect_exit_button.is_highlight = TRUE;
        }
        if (is_clicked)
            is_exit = TRUE;
    } else {
        if (rect_exit_button.is_highlight) {
            draw_rect(rect_exit_button.rect, white);
            rect_exit_button.is_highlight = FALSE;
        }
    }

    return is_exit;
}
```

代码7.5: `sample_poios/gui.c:put_exit_button&update_exit_button`

代码7.5中，`put_exit_button`函数在屏幕右上角绘制[X]按钮，并将这个按钮的坐标、大小和高亮状态放置在全局变量`struct FILE rect_exit_button`中。而`update_exit_button`则根据当前的鼠标状态（指针位置、点击状态）来更新[X]按钮的的高亮状态，并返回[X]按钮是否被按下。

接着，我们在`gui`函数中调用上面两个函数来实现退出GUI的功能（代码7.6）。

```c
void gui(void)
{
    /* ...省略... */
    unsigned char is_exit = FALSE;  /* 新增 */

    SPP->Reset(SPP, FALSE);
    file_num = ls_gui();
    put_exit_button();  /* 新增 */

    while (!is_exit) {  /* 更改 */
        ST->BootServices->WaitForEvent(1, &(SPP->WaitForInput), &waitidx);
        status = SPP->GetState(SPP, &s);
        if (!status) {
            /* ...省略... */

            /* 处理文件图标 */
            for (idx = 0; idx < file_num; idx++) {
                if (is_in_rect(px, py, file_list[idx].rect)) {
                    /* ...省略... */
                    if (prev_lb && !s.LeftButton) {
                        /* ...省略... */
                        file_num = ls_gui();
                        put_exit_button();  /* 追加 */
                    }
                    if (prev_rb && !s.RightButton) {
                        edit(file_list[idx].name);
                        file_num = ls_gui();
                        put_exit_button();  /* 追加 */
                        executed_rb = TRUE;
                    }
                } else {
                    /* ...省略... */
                }
            }

            /* 新建文件 */
            if ((prev_rb && !s.RightButton) && !executed_rb) {
                /* 处理文件图标外的右键单击事件 */
                dialogue_get_filename(file_num);
                edit(file_list[file_num].name);
                ST->ConOut->ClearScreen(ST->ConOut);
                file_num = ls_gui();
                put_exit_button();  /* 新增 */
            }

            /* 新增(此处开始) */
            /* 更新退出按钮状态 */
            is_exit = update_exit_button(px, py, prev_lb && !s.LeftButton);
            /* 新增(此处结束) */

            /* ...省略... */
        }
    }
}
```

代码7.6: `sample_poios/gui.c:gui`

上面这段代码中，在第一次进入至GUI或是从其它界面回到GUI时（例如从`cat`命令返回），我们调用`put_exit_button`函数来绘制[X]按钮。并且在主循环的最后调用`update_exit_button`函数来更新[X]按钮的状态，并通过这个函数的返回值来决定是否要跳出主循环。
