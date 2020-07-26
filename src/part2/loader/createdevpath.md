# 创建设备路径

上一节中我们介绍了用来把设备路径转换为字符串的函数`ConvertDevicePathToText()`。与之相对应地，UEFI标准中还有用来把字符串转换为设备路径的函数，它就是`EFI_DEVICE_PATH_FROM_TEXT_PROTOCOL`中的`ConvertTextToDevicePath()`函数，图4.10展示了它的定义。

本节示例代码的目录为`create-path` (日文版为`031_create_devpath_1`)。

```c
struct EFI_DEVICE_PATH_FROM_TEXT_PROTOCOL {
    unsigned long long _buf;
    struct EFI_DEVICE_PATH_PROTOCOL *(*ConvertTextToDevicePath) (
        const unsigned short *TextDevicePath);
};
```

图4.10: `EFI_DEVICE_PATH_TO_TEXT_PROTOCOL`的定义

同样，我们需要用到`LocateProtocol()`函数来获取`EFI_DEVICE_PATH_FROM_TEXT_PROTOCOL`的地址，如图4.11所示。

```c
struct EFI_DEVICE_PATH_FROM_TEXT_PROTOCOL *DPFTP;  /* 需要在efi.h中声明 */

void efi_init(struct EFI_SYSTEM_TABLE *SystemTable)
{
    /* ... */
    struct EFI_GUID dpftp_guid = {0x5c99a21, 0xc70f, 0x4ad2,
                      {0x8a, 0x5f, 0x35, 0xdf,
                       0x33, 0x43, 0xf5, 0x1e}};
    /* ... */
    ST->BootServices->LocateProtocol(&dpftp_guid, NULL, (void **)&DPFTP);
}
```

图4.11: 获取`EFI_DEVICE_PATH_TO_TEXT_PROTOCOL`的接口（位于`efi.c`中）

接下来，我们就可以调用`ConvertTextToDevicePath()`函数来创建设备路径了。在上一节中，启动时执行的UEFI应用程序的设备路径的字符串表示是`\EFI\BOOT\BOOTX64.EFI`。这里，我们把字符串`\test.efi`转换为设备路径，如图4.12所示。这个字符串表示“根目录下名为test.efi的UEFI应用程序”。

```c
#include "efi.h"
#include "common.h"

void efi_main(void *ImageHandle __attribute__ ((unused)), struct EFI_SYSTEM_TABLE *SystemTable)
{
    struct EFI_DEVICE_PATH_PROTOCOL *dev_path;

    efi_init(SystemTable);
    ST->ConOut->ClearScreen(ST->ConOut);

    dev_path = DPFTP->ConvertTextToDevicePath(L"\\test.efi");
    puts(L"dev_path: ");
    puts(DPTTP->ConvertDevicePathToText(dev_path, FALSE, FALSE));
    puts(L"\r\n");

    while (TRUE);
}
```

图4.12: 使用`ConvertTextToDevicePath()`的例子

为了确认是否创建成功，这里我们对刚才创建的设备路径调用`ConvertDevicePathToText()`来把它转换成字符串再输出到屏幕上，如图4.13所示。

![图4.12程序输出的设备路径](../../images/part2/create-path.png)

图4.13: 图4.12程序输出的设备路径

可以看到，我们成功地创建了我们想要的设备路径。
