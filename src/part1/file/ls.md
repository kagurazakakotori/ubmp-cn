# 列出目录下文件(ls命令)

我们先来实现一个ls命令来列出根目录下所有文件。本节示例代码的目录为`ls` (日文版为`sample5_1_ls`)。

首先，在`efi.c`的`efi_init`函数中调用`LocateProtocol`函数来加载`EFI_SIMPLE_FILE_SYSTEM_PROTOCOL`（代码6.3）。

```c
struct EFI_SIMPLE_FILE_SYSTEM_PROTOCOL *SFSP;  /* 新增 */

void efi_init(struct EFI_SYSTEM_TABLE *SystemTable)
{
    /* ...省略... */
    /* 新增(此处开始) */
    struct EFI_GUID sfsp_guid = {0x0964e5b22, 0x6459, 0x11d2, \
                     {0x8e, 0x39, 0x00, 0xa0, \
                      0xc9, 0x69, 0x72, 0x3b}};
    /* 新增(此处结束) */
    /* ...省略... */
    /* 新增 */
    ST->BootServices->LocateProtocol(&sfsp_guid, NULL, (void **)&SFSP);
}
```

代码6.3: `ls/efi.c`

和之前一样，这里使用了全局变量`SFSP`来存放这个协议。接下来，我们通过调用`SFSP->OpenVolume`函数打开根目录。示例代码如代码6.4所示。

```c
struct EFI_FILE_PROTOCOL *root;
SFSP->OpenVolume(SFSP, &root);
```

代码6.4: 调用`OpenVolume`函数的例子

对于目录的`EFI_FILE_PROTOCOL`，调用`Read`函数将会得到一个目录中的文件/目录名。代码6.5展示了`Read`函数的定义。

```c
unsigned long long (*Read)(struct EFI_FILE_PROTOCOL *This,
               unsigned long long *BufferSize,
               void *Buffer);
```

代码6.5: `Read`函数的定义

其参数的含义如下：

* `unsigned long long *BufferSize`: 指向表示`Buffer`的大小的变量的指针。操作完成后，变量的值将会被设为读取到的内容的大小。对于目录，当所有该目录下的文件/目录名已被读取时，该值将会被设为0。
* `void *Buffer`: 指向存放读取内容的缓冲区的指针。对于目录，每次读取会在其中放入一个文件/目录名。

在完成对文件/目录的操作之后，应当调用`EFI_FILE_PROTOCOL`中的`Close`函数来释放它。该函数的定义如代码6.6所示。

```c
unsigned long long (*Close)(struct EFI_FILE_PROTOCOL *This);
```

代码6.6: `Close`函数的定义

在上面的内容的基础上，我们来实现一个列出启动盘根目录下的文件和目录的命令。

首先，我们建立一个存储文件信息的结构体数组`struct FILE file_list[]`。为了简化处理，这里我们的文件信息只有文件名一项。虽然这些代码并不长，我们仍将它们放在单独的文件`file.h`和`file.c`中，如代码6.7和6.8所示。

```c
#ifndef _FILE_H_
#define _FILE_H_

#include "graphics.h"

#define MAX_FILE_NAME_LEN  4
#define MAX_FILE_NUM       10
#define MAX_FILE_BUF       1024

struct FILE {
    unsigned short name[MAX_FILE_NAME_LEN];
};

extern struct FILE file_list[MAX_FILE_NUM];

#endif
```

代码6.7: `ls/file.h`

```c
#include "file.h"

struct FILE file_list[MAX_FILE_NUM];
```

代码6.8: `ls/file.c`

代码6.9展示了在Shell中加入`ls`命令的代码。

```c
/* ...省略... */

/* 新增(此处开始) */
int ls(void)
{
    unsigned long long status;
    struct EFI_FILE_PROTOCOL *root;
    unsigned long long buf_size;
    unsigned char file_buf[MAX_FILE_BUF];
    struct EFI_FILE_INFO *file_info;
    int idx = 0;
    int file_num;

    status = SFSP->OpenVolume(SFSP, &root);
    assert(status, L"SFSP->OpenVolume");

    while (1) {
        buf_size = MAX_FILE_BUF;
        status = root->Read(root, &buf_size, (void *)file_buf);
        assert(status, L"root->Read");
        if (!buf_size) break;

        file_info = (struct EFI_FILE_INFO *)file_buf;
        strncpy(file_list[idx].name, file_info->FileName,
            MAX_FILE_NAME_LEN - 1);
        file_list[idx].name[MAX_FILE_NAME_LEN - 1] = L'\0';
        puts(file_list[idx].name);
        puts(L" ");

        idx++;
    }
    puts(L"\r\n");
    file_num = idx;

    root->Close(root);

    return file_num;
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
        else if (!strcmp(L"ls", com))  /* 新增 */
            ls();                      /* 新增 */
        else
            puts(L"Command not found.\r\n");
    }
}
```

代码6.9: `ls/shell.c`

代码6.9中的`ls`函数每次执行时调用`OpenVolume`函数打开根目录。这是因为通过`Read`函数获取完一个目录下的所有文件/目录名之后，如果需要再次获取，则必须使用`Close`函数释放这个目录之后再调用`OpenVolume`重新打开它。虽然我们可以第一次读取时缓存该目录中的所有项，但我们出于得到最新的结果和简化代码的考虑，这里还是每次打开目录并读取它们。

此外，`ls`函数也调用了`assert`函数。这个函数检查参数中的状态值，如果这个状态值表示错误（非零），将会输出一条参数中指定的消息，并且使程序陷入一个无限循环中。`assert`函数的检查状态值和输出消息的功能是通过另一个名为`check_warn_error`的函数实现的，`assert`在它的基础上添加了在打印错误消息后陷入无限循环的功能。如果你想了解这两个函数的具体实现，可以阅读`common.c`中的代码。

图6.1展示了`ls`命令运行时的样子。

![`ls`命令运行时的样子](../../images/part1/ls.png)

图6.1: `ls`命令运行时的样子
