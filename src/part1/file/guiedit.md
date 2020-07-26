# GUI下编辑文本文件

本章的最后，我们还是要将上一节实现的编辑功能集成到GUI模式中。本节示例代码的目录为`gui-edit` (日文版为`sample5_6_gui_edit`)。

这里我们要实现下面这两点功能：

1. 在文件图标或是空白处右键进入编辑器
2. 按Esc键退出编辑模式

回忆一下，要新建一个文件，我们需要把`Open`函数中的`OpenMode`参数或上模式位`EFI_FILE_MODE_CREATE`。

这里要修改的文件是`gui.c`和`shell.c`。代码6.21展示了修改后的`gui.c`。

```c
/* ...省略... */

void gui(void)
{
    unsigned long long status;
    struct EFI_SIMPLE_POINTER_STATE s;
    int px = 0, py = 0;
    unsigned long long waitidx;
    int file_num;
    int idx;
    unsigned char prev_lb = FALSE;
    unsigned char prev_rb = FALSE, executed_rb;  /* 新增 */

    SPP->Reset(SPP, FALSE);
    file_num = ls_gui();

    while (TRUE) {
        ST->BootServices->WaitForEvent(1, &(SPP->WaitForInput), &waitidx);
        status = SPP->GetState(SPP, &s);
        if (!status) {
            /* ...省略... */
            /* 清除“已处理过右键事件”标志 */
            executed_rb = FALSE;  /* 新增 */

            /* 处理文件图标 */
            for (idx = 0; idx < file_num; idx++) {
                if (is_in_rect(px, py, file_list[idx].rect)) {
                    /* ...省略... */
                    if (prev_lb && !s.LeftButton) {
                        cat_gui(file_list[idx].name);
                        file_num = ls_gui();
                    }
                    /* 新增(此处开始) */
                    if (prev_rb && !s.RightButton) {
                        edit(file_list[idx].name);
                        file_num = ls_gui();
                        executed_rb = TRUE;
                    }
                    /* 新增(此处结束) */
                } else {
                    /* ...省略... */
                }
            }

            /* 新增(此处开始) */
            /* 新建文件 */
            if ((prev_rb && !s.RightButton) && !executed_rb) {
                /* 处理文件图标外的右键单击事件 */
                dialogue_get_filename(file_num);
                edit(file_list[file_num].name);
                ST->ConOut->ClearScreen(ST->ConOut);
                file_num = ls_gui();
            }
            /* 新增(此处结束) */

            /* 保存鼠标按键状态 */
            prev_lb = s.LeftButton;
            prev_rb = s.RightButton;  /* 新增 */
        }
    }
}
```

代码6.21: `gui-edit/gui.c`

代码6.21增加了对于单击右键进入编辑模式的处理。对于已经存在的文件，这个过程仍然在处理文件图标的循环中进行；对于新建文件，则在这个循环之后。变量`executed_rb`用来标记右键事件是否已经在处理文件图标这一循环中被处理。

另外，我们在`shell.c`中加入了新建文件时询问文件名的函数`dialogue_get_filename`，并且在`edit`函数调用`Open`函数时或上了模式位`EFI_FILE_MODE_CREATE`。代码6.22展示了修改后的修改后的`shell.c`。

```c
/* ...省略... */

/* 新增(此处开始) */
void dialogue_get_filename(int idx)
{
    int i;

    ST->ConOut->ClearScreen(ST->ConOut);

    puts(L"New File Name: ");
    for (i = 0; i < MAX_FILE_NAME_LEN; i++) {
        file_list[idx].name[i] = getc();
        if (file_list[idx].name[i] != L'\r')
            putc(file_list[idx].name[i]);
        else
            break;
    }
    file_list[idx].name[(i < MAX_FILE_NAME_LEN) ? i : MAX_FILE_NAME_LEN - 1] = L'\0';
}
/* 新增(此处结束) */

/* ...省略... */

void edit(unsigned short *file_name)
{
    /* ...省略... */
    status = root->Open(root, &file, file_name,
                EFI_FILE_MODE_READ | EFI_FILE_MODE_WRITE | \
                EFI_FILE_MODE_CREATE, 0);  /* 更改 */
    assert(status, L"root->Open");
    /* ...省略... */
}

/* ...省略... */
```

代码6.22: `gui-edit/shell.c`

这个例子的运行结果如图6.8、6.9所示。这里展示的是新建文件的操作。

![输入文件名的界面](../../images/part1/gui-edit-filename.png)

图6.8: 输入文件名的界面

![编辑界面](../../images/part1/gui-edit.png)

图6.9: 编辑界面
