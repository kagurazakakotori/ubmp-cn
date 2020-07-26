# 软关机

由于UEFI应用程序运行在内存上，我们可以通过按下电源键来安全地关机，并且一直以来我们都是这么做的。除此之外，我们也可以使用`EFI_RUNTIME_SERVICES`中的`ResetSystem()`函数进行软关机或软重启，它的定义和它相关的定义如图6.4所示。

本节示例代码的目录为`shutdown` (日文版为`051_rs_resetsystem`)。

`EFI_RUNTIME_SERVICES`和`EFI_BOOT_SERVICES`一样，都是`EFI_SYSTEM_TABLE`中的成员。在第一部分我们介绍过，`EFI_BOOT_SERVICES`主要供引导加载程序(Bootloader)使用，它在操作系统启动后就不可用了，而`EFI_RUNTIME_SERVICES`可以在操作系统启动后继续使用。

更具体些的话，就是在调用`EFI_BOOT_SERVICES.ExitBootServices()`函数之后，`EFI_BOOT_SERVICES`中的函数都无法使用，而`EFI_RUNTIME_SERVICES`中的函数仍然可以使用。

```c
enum EFI_RESET_TYPE {
    EfiResetCold,
        /* 冷重启，将系统所有电路设为初始状态
         * 相当于断电再重新通电 */
    EfiResetWarm,
        /* 热重启，重新初始化系统，CPU被置为初始状态
         * 相当于不断电重启
         * 如果系统不支持，则执行EfiResetCold */
    EfiResetShutdown,
        /* 关机, 将计算机置于ACPI G2/S5(软关机)或是G3(断电)状态
         * 注: G2/S5和G3的区别在于前者仍有通电部分, 例如ATX规范中用于开机的+5VSB电路 
         * 如果系统不支持, 则在下次重启时, 它将表现出EfiResetCold的行为 */
    EfiResetPlatformSpecific
        /* 特殊的冷重启，在重启时传入一段数据
        /* 这段数据是一个以空字符结尾的Unicode字符串, 其后接一个EFI_GUID表示重启类型
        /* 固件可能会利用这段数据记录非正常的重启 */
};

struct EFI_SYSTEM_TABLE {
    ...
    struct EFI_RUNTIME_SERVICES {
        ...
        // 其他服务
        unsigned long long _buf_rs5;
        void (*ResetSystem)(
            enum EFI_RESET_TYPE ResetType,
                /* 进行重启/关机的类型
                 * 这里我们设为EfiResetShutdown */
            unsigned long long ResetStatus,
                /* 状态码, 正常的电源操作应为EFI_SUCCESS
                 * 因错误导致的为实际错误码
                 * 这里我们设为EFI_SUCCESS(0) */
            unsigned long long DataSize,
                /* ResetData的大小
                 * 这里我们由于不使用ResetData, 把它设为0 */
            void *ResetData
                /* 当ResetType为EfiResetCold、EfiResetWarm或是EfiResetShutdown时
                 * 是一个空字符结尾的Unicode字符串, 后面可接可选的二进制内容
                 * 用来表示重启的原因等信息
                 * 当ResetType为EfiResetPlatformSpecific时
                 * 是一个以空字符结尾的Unicode字符串, 其后接一个EFI_GUID表示重启类型
                 * 可使用启类型的EFI_GUID是平台定义的
                 * 这里我们不使用, 将它设为NULL */
            );
    } *RuntimeServices;
};
```

图6.4: `ResetSystem()`的定义和它的相关定义（位于`efi.h`中）

图6.5展示了一个使用`ResetSystem()`进行关机的例子。

```c
#include "efi.h"
#include "common.h"

void efi_main(void *ImageHandle __attribute__ ((unused)),
          struct EFI_SYSTEM_TABLE *SystemTable)
{
    efi_init(SystemTable);
    ST->ConOut->ClearScreen(ST->ConOut);

    /* 等待按键输入 */
    puts(L"Press any key to shutdown...\r\n");
    getc();

    /* 关机 */
    ST->RuntimeServices->ResetSystem(EfiResetShutdown, EFI_SUCCESS, 0, NULL);

    /* 下面的代码正常情况下永远不会被执行 */
    while (TRUE);
}
```

图6.5: 使用`ResetSystem()`的例子

图6.6是上面这个程序运行时的情况。

![图6.5程序运行时的情况](../../images/part2/shutdown.png)

图6.6: 图6.5程序运行时的情况
