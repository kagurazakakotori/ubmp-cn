# 读取文本文件(cat命令)

在获取到文件列表之后，接下来我们实现读取文件内容的功能。这里我们在Shell中加入一个简易的`cat`命令。本节示例代码的目录为`cat` (日文版为`sample5_3_cat`)。

由于我们的主要目标是学习如何调用UEFI固件接口来读取文件，这里为了简化处理，我们要实现的`cat`命令所读取的文件是固定的。换句话说，这个`cat`命令不接受文件名作为参数。这里我们要读取的文件名为"abc"。

之前介绍了对于目录，调用`EFI_FILE_PROTOCOL`中的`Read`函数（标准文档"12.5 EFI File Protocol(P.504)"）是读取目录中的一项文件/目录名。对于文件，调用这个函数则是读取其中的内容。

要获取某个文件的`EFI_FILE_PROTOCOL`，我们需要在它所在目录的`EFI_FILE_PROTOCOL`中调用`Open`函数（标准文档"12.5 EFI File Protocol(P.499)"）来打开这个文件。代码6.12展示了`Open`函数的定义。

```c
unsigned long long (*Open)(struct EFI_FILE_PROTOCOL *This,
                           struct EFI_FILE_PROTOCOL **NewHandle,
                           unsigned short *FileName,
                           unsigned long long OpenMode,
                           unsigned long long Attributes);
```

代码6.12: `Open`函数的定义

这个函数参数的含义如下：

* `struct EFI_FILE_PROTOCOL **NewHandle`: 被打开的文件的`EFI_FILE_PROTOCOL`
* `unsigned short *FileName`: 文件名
* `unsigned long long OpenMode`: 文件打开的模式
* `unsigned long long Attributes`: 新建文件时的属性。本书不使用。

`OpenMode`中的模式位的定义如代码6.13所示。

```c
#define EFI_FILE_MODE_READ      0x0000000000000001
#define EFI_FILE_MODE_WRITE     0x0000000000000002
#define EFI_FILE_MODE_CREATE    0x8000000000000000
```

代码6.13: `OpenMode`中的模式位

此外，`OpenMode`中只容许下面这些组合：

* READ (只读)
* READ | WRITE (读写)
* READ | WRITE | CREATE (读写，如果文件不存在，那么创建它)

了解了上面的内容后，可以看出，打开并读取指定的文件"abc"这个动作可以拆分成下面三步：

1. 调用`EFI_SIMPLE_FILE_SYSTEM_PROTOCOL`的`OpenVolume`函数打开卷（获取根目录的`EFI_FILE_PROTOCOL`）
2. 在根目录的`EFI_FILE_PROTOCOL`中调用`Open`函数打开文件"abc"（获取文件"abc"的`EFI_FILE_PROTOCOL`）
3. 在文件"abc"的`EFI_FILE_PROTOCOL`中调用`Read`函数读取文件（读取文件"abc"的内容）

代码6.14展示了实现这个简易的`cat`命令的代码。在上面三步的基础上，这里最后调用了`Close`函数来释放我们打开过的文件和目录。

```c
/* ...省略... */

/* 新增(此处开始) */
void cat(unsigned short *file_name)
{
    unsigned long long status;
    struct EFI_FILE_PROTOCOL *root;
    struct EFI_FILE_PROTOCOL *file;
    unsigned long long buf_size = MAX_FILE_BUF;
    unsigned short file_buf[MAX_FILE_BUF / 2];

    status = SFSP->OpenVolume(SFSP, &root);
    assert(status, L"SFSP->OpenVolume");

    status = root->Open(root, &file, file_name, EFI_FILE_MODE_READ, 0);
    assert(status, L"root->Open");

    status = file->Read(file, &buf_size, (void *)file_buf);
    assert(status, L"file->Read");

    puts(file_buf);

    file->Close(file);
    root->Close(root);
}
/* 新增(此处结束) */

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
        /* ...省略... */
        else if (!strcmp(L"cat", com))  /* 新增 */
            cat(L"abc");                /* 新增 */
        else
            puts(L"Command not found.\r\n");
    }
}
```

代码6.14: `cat/shell.c`

此外，我们可以使用`iconv`和`unix2dos`命令来文本文件转换为UEFI可识别的Unicode编码。[^1]

```shell
$ unix2dos < input.txt | iconv -f UTF-8 -t UCS-2LE > output.txt
```

上述代码执行时的样子如图6.3所示。

![`cat`命令运行时的样子](../../images/part1/cat.png)

图6.3: `cat`命令运行时的样子


[^1]: 译者注：原文介绍的是`nkf`命令，命令为`nkf -w16L0 orig.txt > unicode.txt`。这里用更常见的`iconv`命令替代。
