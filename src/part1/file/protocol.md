# 文件相关的协议

UEFI支持FAT文件系统。用于进行文件操作的协议是简单文件系统协议（Simple File System Protocol）`EFI_SIMPLE_FILE_SYSTEM_PROTOCOL`和文件协议（File Protocol）`EFI_FILE_PROTOCOL`（标准文档"12.4 Simple File System Protocol(P.494)"和"12.5 EFI File Protocol(P.497)"）。

代码6.1展示了`EFI_SIMPLE_FILE_SYSTEM_PROTOCOL`的定义。

```c
struct EFI_SIMPLE_FILE_SYSTEM_PROTOCOL {
    unsigned long long Revision;
    unsigned long long (*OpenVolume)(
        struct EFI_SIMPLE_FILE_SYSTEM_PROTOCOL *This,
        struct EFI_FILE_PROTOCOL **Root);
};
```

代码6.1: `EFI_SIMPLE_FILE_SYSTEM_PROTOCOL`的定义

上面的代码`EFI_SIMPLE_FILE_SYSTEM_PROTOCOL`的完整定义，它只有一个函数`OpenVolume`。顾名思义，这个函数是用来打开一个卷的。“卷”这里可以理解成存储设备上的分区，相当于Windows中的X盘。其参数的定义如下：

* `struct EFI_FILE_PROTOCOL **Root`: 指向所打开的卷的根目录的指针

UEFI通过结构体`EFI_FILE_PROTOCOL`来处理文件和目录，通过`OpenVolume`得到的根目录也是这个类型的。[^1]代码6.2展示了它的定义（这里只展示书中要使用到的部分）。

```c
struct EFI_FILE_PROTOCOL {
    unsigned long long _buf;
    unsigned long long (*Open)(struct EFI_FILE_PROTOCOL *This,
                   struct EFI_FILE_PROTOCOL **NewHandle,
                   unsigned short *FileName,
                   unsigned long long OpenMode,
                   unsigned long long Attributes);
    unsigned long long (*Close)(struct EFI_FILE_PROTOCOL *This);
    unsigned long long _buf2;
    unsigned long long (*Read)(struct EFI_FILE_PROTOCOL *This,
                   unsigned long long *BufferSize,
                   void *Buffer);
    unsigned long long (*Write)(struct EFI_FILE_PROTOCOL *This,
                    unsigned long long *BufferSize,
                    void *Buffer);
    unsigned long long _buf3[4];
    unsigned long long (*Flush)(struct EFI_FILE_PROTOCOL *This);
};
```

代码6.2: `EFI_FILE_PROTOCOL`的定义

关于其中各个函数的使用方法，我们将在本章接下来的小节中介绍。


[^1]: 译者注：这个结构体的作用类似于Unix的文件描述符和Windows的文件句柄，但是更加面向对象
