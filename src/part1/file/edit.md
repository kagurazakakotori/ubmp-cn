# 编辑文本文件(edit命令)

现在我们已经知道了如何读取文件，接下来我们来尝试写入文件。和之前一样，这里我们在Shell中加入一个简单的`edit`命令，这个命令覆盖写入一个文本文件。本节示例代码的目录为`edit` (日文版为`sample5_5_edit`)。

用于写入文件的是`EFI_FILE_PROTOCOL`中的`Write`函数，代码6.18展示了它的定义。

```c
unsigned long long (*Write)(struct EFI_FILE_PROTOCOL *This,
                            unsigned long long *BufferSize,
                            void *Buffer);
```

代码6.18: `Write`函数的定义

其参数含义如下：

* `unsigned long long *BufferSize`: 指向表示`Buffer`的大小的变量的指针。操作完成后，该值将会被设为已写入的内容的大小。
* `void *Buffer`: 指向存放要写入的内容的缓冲区的指针。

注意，在执行`Write`操作后，内容不一定会立刻写入到磁盘上。因此我们需要要调用`Flush`函数来手动将缓冲区的内容写入到磁盘上，代码6.19展示了这个函数的定义。

```c
unsigned long long (*Flush)(struct EFI_FILE_PROTOCOL *This);
```

代码6.19: `Flush`函数的定义

了解了上面这两个函数之后，我们就可以在Shell中实现这个简单的`edit`命令了。代码6.20展示了修改后的`shell.c`。

```c
/* ...省略... */

/* 新增(此处开始) */
void edit(unsigned short *file_name)
{
    unsigned long long status;
    struct EFI_FILE_PROTOCOL *root;
    struct EFI_FILE_PROTOCOL *file;
    unsigned long long buf_size = MAX_FILE_BUF;
    unsigned short file_buf[MAX_FILE_BUF / 2];
    int i = 0;
    unsigned short ch;

    ST->ConOut->ClearScreen(ST->ConOut);

    while (TRUE) {
        ch = getc();

        if (ch == SC_ESC)
            break;

        putc(ch);
        file_buf[i++] = ch;

        if (ch == L'\r') {
            putc(L'\n');
            file_buf[i++] = L'\n';
        }
    }
    file_buf[i] = L'\0';

    status = SFSP->OpenVolume(SFSP, &root);
    assert(status, L"SFSP->OpenVolume");

    status = root->Open(root, &file, file_name,
                EFI_FILE_MODE_READ | EFI_FILE_MODE_WRITE, 0);
    assert(status, L"root->Open");

    status = file->Write(file, &buf_size, (void *)file_buf);
    assert(status, L"file->Write");

    file->Flush(file);

    file->Close(file);
    root->Close(root);
}
/* 新增(此处结束) */

void shell(void)
{
    /* ...省略... */
    while (TRUE) {
        /* ...省略... */
        if (!strcmp(L"hello", com))
            puts(L"Hello UEFI!\r\n");
        /* ...省略... */
        else if (!strcmp(L"edit", com))  /* 新增 */
            edit(L"abc");                /* 新增 */
        else
            puts(L"Command not found.\r\n");
    }
}
```

代码6.20: `edit/shell.c`

在代码6.20的`edit`函数中，`while(TRUE)`代码块接受输入，将输入的内容存放在输入缓冲区中，直至按下Esc键结束编辑。之后，这个函数把缓冲区的内容写入至文件中。这里实现的`edit`命令和之前的`cat`命令一样，所操作的文件是固定的"abc"。

本例子的运行结果如图6.5、6.6、6.7所示。

![`edit`命令运行前的"abc"](../../images/part1/edit-before.png)

图6.5: `edit`命令运行前的文件"abc"

![`edit`命令运行时的样子](../../images/part1/edit.png)

图6.6: `edit`命令运行时的样子

![`edit`命令运行后的"abc"](../../images/part1/edit-after.png)

图6.7: `edit`命令运行后的文件"abc"
