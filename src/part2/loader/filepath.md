# 查看当前设备路径

为了调用`LoadImage()`来加载UEFI应用程序，我们需要通过它的路径来创建一个设备路径。

由于我们有办法来获取到当前应用程序`EFI/BOOT/BOOTX64.EFI`的设备路径，在本章中，我们将会通过修改这个现有的设备路径来为要加载的UEFI应用程序来创建设备路径。

在本节中，我们首先来编写一个程序来显示当前应用程序的设备路径，来看看设备路径是什么样子的。

本节示例代码的目录为`filepath` (日文版为`030_loaded_image_protocol_file_path`)。


## EFI_LOADED_IMAGE_PROTOCOL

要获取关于已加载的镜像(UEFI应用程序)的信息，需要用到图4.1中的`EFI_LOADED_IMAGE_PROTOCOL`（标准文档"8.1 EFI Loaded Image Protocol(P.255)"）。

```c
struct EFI_LOADED_IMAGE_PROTOCOL {
        unsigned int Revision;
        void *ParentHandle;
        struct EFI_SYSTEM_TABLE *SystemTable;

        /* 镜像源文件的位置 */
        void *DeviceHandle;
        struct EFI_DEVICE_PATH_PROTOCOL *FilePath;
        void *Reserved;

        /* 加载镜像时的选项 */
        unsigned int LoadOptionsSize;
        void *LoadOptions;

        /* 镜像被加载到的位置 */
        void *ImageBase;
        unsigned long long ImageSize;
        enum EFI_MEMORY_TYPE ImageCodeType;
        enum EFI_MEMORY_TYPE ImageDataType;
        unsigned long long (*Unload)(void *ImageHandle);
};
```

图4.1: `EFI_LOADED_IMAGE_PROTOCOL`的定义（位于`efi.h`中）

`EFI_LOADED_IMAGE_PROTOCOL`和我们目前位置介绍过的所有协议不同的是，它大部分的成员都是变量而不是函数。这些变量存放着和当前已加载的镜像相关的信息。从类型名`EFI_DEVICE_PATH_PROTOCOL`可以看出，其中的`FilePath`这项就是已加载镜像的设备路径。


## 使用OpenProtocol()获取EFI_LOADED_IMAGE_PROTOCOL

要得到已加载镜像的`EFI_LOADED_IMAGE_PROTOCOL`，需要使用`EFI_BOOT_SERVICES`中的`OpenProtocol()`函数，图4.2展示了它的定义。

```c
struct EFI_SYSTEM_TABLE {
    ...
    struct EFI_BOOT_SERVICES {
        ...
        unsigned long long (*OpenProtocol)(
            void *Handle,               /* 要打开的协议接口所在的镜像句柄 */
            struct EFI_GUID *Protocol,  /* 协议的GUID */
            void **Interface,           /* 所打开的协议接口 */
            void *AgentHandle,          /* 调用者的镜像句柄，这里是当前镜像自己 */
            void *ControllerHandle,
                /* 如果要打开的是遵循UEFI驱动模型(UEFI Driver Model)的驱动的协议, 为控制器句柄 */
                /* 否则为NULL*/
            unsigned int Attributes     /* 协议接口的打开模式 */
            );
        ...
    } *BootServices;
};
```

图4.2: `OpenProtocol()`的定义（位于`efi.h`中）

`OpenProtocol()`的第一个参数`Handle`是我们要获取信息的已加载镜像的句柄，第4个参数`AgentHandle`是调用该函数的镜像句柄，对于我们现在要打开`EFI_LOADED_IMAGE_PROTOCOL`这个操作而言，这两个参数都是当前应用程序的镜像句柄。

UEFI应用程序的镜像句柄是在它被`LoadImage()`加载时得到的(详细内容将在接下来的小节中介绍)。对于被加载的UEFI应用程序，它的入口函数的第一个参数`ImageHandle`就是它的镜像句柄。因此，这里我们把上面这两个参数设为`ImageHandle`。

此外，第6个参数`Attributes`接受的模式常量的定义如图4.3所示。这里我们使用`EFI_OPEN_PROTOCOL_GET_PROTOCOL`。

```c
#define EFI_OPEN_PROTOCOL_BY_HANDLE_PROTOCOL    0x00000001
#define EFI_OPEN_PROTOCOL_GET_PROTOCOL          0x00000002
#define EFI_OPEN_PROTOCOL_TEST_PROTOCOL         0x00000004
#define EFI_OPEN_PROTOCOL_BY_CHILD_CONTROLLER   0x00000008
#define EFI_OPEN_PROTOCOL_BY_DRIVER             0x00000010
#define EFI_OPEN_PROTOCOL_EXCLUSIVE             0x00000020
```

图4.3: `Attributes`接受的模式常量

在调用`OpenProtocol()`之前，我们还需要加入`EFI_LOADED_IMAGE_PROTOCOL`的GUID的定义`lip_guid`，如图4.4所示。

```c
struct EFI_GUID lip_guid = {0x5b1b31a1, 0x9562, 0x11d2,
                            {0x8e, 0x3f, 0x00, 0xa0, 0xc9, 0x69, 0x72, 0x3b}};
```

图4.4: `lip_guid`的定义（位于`efi.h`中）

最后，我们就可以像图3.5这样调用`OpenProtocol()`了。

```c
#include "efi.h"
#include "common.h"

void efi_main(void *ImageHandle, struct EFI_SYSTEM_TABLE *SystemTable)
{
    unsigned long long status;
    struct EFI_LOADED_IMAGE_PROTOCOL *lip;

    efi_init(SystemTable);
    ST->ConOut->ClearScreen(ST->ConOut);

    status = ST->BootServices->OpenProtocol(
        ImageHandle, &lip_guid, (void **)&lip, ImageHandle, NULL,
        EFI_OPEN_PROTOCOL_GET_PROTOCOL);
    assert(status, L"OpenProtocol");

    while (TRUE);
}
```

图4.5: 使用`OpenProtocol()`的例子


## EFI_DEVICE_PATH_TO_TEXT_PROTOCOL

而要把获取到的设备路径转换成字符串，则需要使用`EFI_DEVICE_PATH_TO_TEXT_PROTOCOL`，图4.6展示了它的定义。

```c
struct EFI_DEVICE_PATH_TO_TEXT_PROTOCOL {
    unsigned long long _buf;
    unsigned short *(*ConvertDevicePathToText)(
        const struct EFI_DEVICE_PATH_PROTOCOL* DeviceNode,
        unsigned char DisplayOnly,
        unsigned char AllowShortcuts);
};
```

图4.6: `EFI_DEVICE_PATH_TO_TEXT_PROTOCOL`的定义

和[1.4.1. 图形输出协议](../../part1/graphic/gop.md)还有[1.5.2 查看鼠标状态](../../part1/mouse/pstat.md)中的简单指针协议一样，这个协议也需要使用`LocateProtocol()`函数来定位。同样地，这里我们也使用一个全局变量`DPTTP`来存放它，并在我们的`efi_init()`函数中完成这个处理过程，就像图4.7这样。

```c
#include "efi.h"
#include "common.h"

/* ... */
struct EFI_DEVICE_PATH_TO_TEXT_PROTOCOL *DPTTP;  /* 需要在efi.h中声明 */

void efi_init(struct EFI_SYSTEM_TABLE *SystemTable)
{
    /* ... */
    struct EFI_GUID dpttp_guid = {0x8b843e20, 0x8132, 0x4852,
                      {0x90, 0xcc, 0x55, 0x1a,
                       0x4e, 0x4a, 0x7f, 0x1c}};
    /* ... */
    ST->BootServices->LocateProtocol(&dpttp_guid, NULL, (void **)&DPTTP);
}
```

图4.7: 获取`EFI_DEVICE_PATH_TO_TEXT_PROTOCOL`的接口（位于`efi.c`中）

调用其中的`ConvertDevicePathToText()`函数，我们就可以把`EFI_LOADED_IMAGE_PROTOCOL`中的`FilePath`转换成字符串了，如图4.8所示。

```c
#include "efi.h"
#include "common.h"

void efi_main(void *ImageHandle, struct EFI_SYSTEM_TABLE *SystemTable)
{
    unsigned long long status;
    struct EFI_LOADED_IMAGE_PROTOCOL *lip;

    efi_init(SystemTable);
    ST->ConOut->ClearScreen(ST->ConOut);

    status = ST->BootServices->OpenProtocol(
        ImageHandle, &lip_guid, (void **)&lip, ImageHandle, NULL,
        EFI_OPEN_PROTOCOL_GET_PROTOCOL);
    assert(status, L"OpenProtocol");

    /* 新增(此处开始) */
    puts(L"lip->FilePath: ");
    puts(DPTTP->ConvertDevicePathToText(lip->FilePath, FALSE, FALSE));
    puts(L"\r\n");
    /* 新增(此处结束) */

    while (TRUE);
}
```

图4.8: 使用`ConvertDevicePathToText()`的例子

这个程序在屏幕上输出它的设备路径`\EFI\BOOT\BOOTX64.EFI`，如图4.9所示。

![图4.8程序输出的设备路径](../../images/part2/filepath.png)

图4.9: 图4.8程序输出的设备路径
