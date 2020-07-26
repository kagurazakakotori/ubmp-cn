# GUI下浏览文本文件

了解了如何读取文件内容之后，和之前的`ls`一样，接下来我们把这一功能扩展到GUI模式中。本节示例代码的目录为`gui-cat` (日文版为`sample5_4_gui_cat`)。这里我们将要实现这三个功能：

1. 在文件图标（矩形）上单击进入文件浏览模式
2. 在浏览模式中，首先进行清屏，再以Unicode文本显示文件内容
3. 按Esc键退出浏览模式

这里主要修改的是`gui.c`文件，如代码6.15所示。

```c
/* ...省略... */

/* 新增(此处开始) */
void cat_gui(unsigned short *file_name)
{
    ST->ConOut->ClearScreen(ST->ConOut);

    cat(file_name);

    while (getc() != SC_ESC);
}
/* 新增(此处结束) */

void gui(void)
{
    unsigned long long status;
    struct EFI_SIMPLE_POINTER_STATE s;
    int px = 0, py = 0;
    unsigned long long waitidx;
    int file_num;
    int idx;
    unsigned char prev_lb = FALSE;  /* 新增 */

    SPP->Reset(SPP, FALSE);
    file_num = ls_gui();

    while (TRUE) {
        ST->BootServices->WaitForEvent(1, &(SPP->WaitForInput), &waitidx);
        status = SPP->GetState(SPP, &s);
        if (!status) {
            /* ...省略... */
            /* 处理文件图标 */
            for (idx = 0; idx < file_num; idx++) {
                if (is_in_rect(px, py, file_list[idx].rect)) {
                    if (!file_list[idx].is_highlight) {
                        draw_rect(file_list[idx].rect, yellow);
                        file_list[idx].is_highlight = TRUE;
                    }
                    /* 新增(此处开始) */
                    if (prev_lb && !s.LeftButton) {
                        cat_gui(file_list[idx].name);
                        file_num = ls_gui();
                    }
                    /* 新增(此处结束) */
                } else {
                    if (file_list[idx].is_highlight) {
                        draw_rect(file_list[idx].rect, white);
                        file_list[idx].is_highlight = FALSE;
                    }
                }
            }

            /* 新增(此处开始) */
            /* 保存鼠标左键状态 */
            prev_lb = s.LeftButton;
            /* 新增(此处结束) */
        }
    }
}
```

代码6.15: `gui-cat/gui.c`

代码6.15的`gui`函数中加入了对于鼠标事件的处理。鼠标左键的上一次状态保存在变量`prev_lb`中，而松开鼠标左键的那一刻会被判定为发生了一次单击。在这一事件发生后，将会以点击的文件名作为参数调用`cat_gui`函数。这个过程是在处理文件图标的循环中进行的。`cat_gui`函数是对上一节`cat`函数的封装，也是实现GUI的浏览模式的函数。

这个例子中单击文件`abc`后进入的浏览模式如图6.4所示。

![文件浏览模式](../../images/part1/gui-cat.png)

图6.4: 文件浏览模式


> **修正`getc`中非Unicode字符按键的返回值**
> 
> 代码6.15中的`cat_gui`函数中，通过循环等待`getc`函数返回`SC_ESC`（Esc键的扫描码）来实现按Esc键退出浏览模式的功能。事实上，在这个例子中，我们对`common.c`中的`getc`函数进行了一些修改来使它能够返回Unicode字符范围外的按键的扫描码（代码6.16）。
> 
> ```c
> unsigned short getc(void)
> {
>     struct EFI_INPUT_KEY key;
>     unsigned long long waitidx;
>
>     ST->BootServices->WaitForEvent(1, &(ST->ConIn->WaitForKey), &waitidx);
>     while (ST->ConIn->ReadKeyStroke(ST->ConIn, &key));
> 
>     /* 修改 */
>     return (key.UnicodeChar) ? key.UnicodeChar : (key.ScanCode + SC_OFS);
> }
> ```
>
> 代码6.16: `sample_5_4_gui_cat/common_c:getc`
> 
> 代码6.16中，如果`key.UnicodeChar`为0时（该按键在Unicode范围外），将会返回`key.ScanCode`加上偏移量`SC_OFS`的值。这是因为，扫描码的范围(0x00〜0x17)与Unicode字符范围重叠(0x0000〜0xffff)，且这一范围位于常用的ASCII子集中(0x00～0x7F)中，因此我们需要将扫描码放入一个Unicode不常用的范围中来避免冲突。
>
> 这里我们使用的是0x1680〜0x1697这个区间。在Unicode标准中，这一区间是欧甘字母的区间。这是一种在爱尔兰发现的中世纪前期使用的字母系统。[^1][^2]
>
> 因此，`common.h`中的`SC_OFS`和`SC_ESC`被定义成代码6.17所示的形式。
>
> ```c
> #define SC_OFS  0x1680
> #define SC_ESC  (SC_OFS + 0x0017)
> ```
>
> 代码6.17: `SC_OFS`和`SC_ESC`的定义


[^1]: [中文维基百科上的欧甘字母](https://zh.wikipedia.org/wiki/%E6%AD%90%E7%94%98%E5%AD%97%E6%AF%8D)

[^2]: 译者注：这里对于欧甘字母的解释与原书不同
