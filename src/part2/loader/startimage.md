# 运行加载的镜像

成功加载UEFI应用程序镜像之后，下一步就是运行它了。

本节示例代码的目录为`start-image` (日文版为`036_start_devpath`)。

用来运行加载好的镜像的函数是`EFI_BOOT_SERVICES`中的`StartImage()`，图4.29展示了它的定义。

```c
struct EFI_SYSTEM_TABLE {
    ...
    struct EFI_BOOT_SERVICES {
        ...
        // Image Services
        unsigned long long (*LoadImage)(
            unsigned char BootPolicy,
            void *ParentImageHandle,
            struct EFI_DEVICE_PATH_PROTOCOL *DevicePath,
            void *SourceBuffer,
            unsigned long long SourceSize,
            void **ImageHandle);
        unsigned long long (*StartImage)(
            void *ImageHandle,
                /* 要运行的镜像句柄 */
            unsigned long long *ExitDataSize,
                /* 指向存放ExitData大小的变量的指针
                 * 当ExitData被设为NULL时，这个值也应设为NULL */
            unsigned short **ExitData
                /* 指向存放运行的镜像调用EFI_BOOT_SERVICES.Exit()函数退出时返回的内容的缓冲区的指针
                 * 这里我们不使用，所以设为NULL */
            );
        ...
    } *BootServices;
};
```

图4.29: `StartImage()`的定义（位于`efi.h`中）

在载入UEFI应用程序镜像后，就可以调用`StartImage()`来运行它了。图4.30是在上一节图4.27代码的基础上运行镜像的例子。

```c
#include "efi.h"
#include "common.h"

void efi_main(void *ImageHandle, struct EFI_SYSTEM_TABLE *SystemTable)
{
    struct EFI_LOADED_IMAGE_PROTOCOL *lip;
    struct EFI_DEVICE_PATH_PROTOCOL *dev_path;
    struct EFI_DEVICE_PATH_PROTOCOL *dev_node;
    struct EFI_DEVICE_PATH_PROTOCOL *dev_path_merged;
    unsigned long long status;
    void *image;

    efi_init(SystemTable);
    ST->ConOut->ClearScreen(ST->ConOut);

    /* 获取ImageHandle的EFI_LOADED_IMAGE_PROTOCOL(lip) */
    status = ST->BootServices->OpenProtocol(
        ImageHandle, &lip_guid, (void **)&lip, ImageHandle, NULL,
        EFI_OPEN_PROTOCOL_GET_PROTOCOL);
    assert(status, L"OpenProtocol(lip)");

    /* 获取lip->DeviceHandle的EFI_DEVICE_PATH_PROTOCOL(dev_path) */
    status = ST->BootServices->OpenProtocol(
        lip->DeviceHandle, &dpp_guid, (void **)&dev_path, ImageHandle,
        NULL, EFI_OPEN_PROTOCOL_GET_PROTOCOL);
    assert(status, L"OpenProtocol(dpp)");

    /* 创建test.efi的设备节点 */
    dev_node = DPFTP->ConvertTextToDeviceNode(L"test.efi");

    /* 把dev_node附加到dev_path后 */
    dev_path_merged = DPUP->AppendDeviceNode(dev_path, dev_node);

    /* 把dev_path_merged转换成字符串并显示 */
    puts(L"dev_path_merged: ");
    puts(DPTTP->ConvertDevicePathToText(dev_path_merged, FALSE, FALSE));
    puts(L"\r\n");

    /* 从dev_path_merged加载镜像 */
    status = ST->BootServices->LoadImage(FALSE, ImageHandle,
                         dev_path_merged, NULL, 0, &image);
    assert(status, L"LoadImage");
    puts(L"LoadImage: Success!\r\n");

    /* 新增(此处开始) */
    /* 运行image */
    status = ST->BootServices->StartImage(image, NULL, NULL);
    assert(status, L"StartImage");
    puts(L"StartImage: Success!\r\n");
    /* 新增(此处结束) */

    while (TRUE);
}
```

图4.30: 使用`StartImage()`的例子

运行这个程序，我们可以看到图4.31这样的情况，这表明我们成功地运行了“Hello UEFI!”这个程序。

![成功加载并运行“Hello UEFI!”](../../images/part2/start-image.png)

图4.31: 成功加载并运行“Hello UEFI!”

今后，我们可以用同样的方法来运行其他的UEFI应用程序。

顺带一提，运行“Hello UEFI!”这个应用程序你会看到光标跳到了下一行，但没有返回行头。这是因为UEFI和Windows一样，是用CRLF来换行的，而第一部分的“Hello UEFI!”这个程序在换行时缺少了CR(Carriage Return/`\r`)来把光标放回行头。
