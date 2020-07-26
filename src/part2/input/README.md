# 键盘输入

UEFI标准中有一个比简单文本输入协议(Simple Text Input Protocol)拥有更多功能的Simple Text Input Ex Protocol `EFI_SIMPLE_TEXT_INPUT_EX_PROTOCOL`。本章将介绍一些利用该协议的编程技巧。

图3.1展示了`EFI_SIMPLE_TEXT_INPUT_EX_PROTOCOL`的GUID和定义。

```c
struct EFI_GUID stiep_guid = {0xdd9e7534, 0x7762, 0x4698, \
                              {0x8c, 0x14, 0xf5, 0x85, 0x17, 0xa6, 0x25, 0xaa}};

struct EFI_SIMPLE_TEXT_INPUT_EX_PROTOCOL {
    /* 重置输入设备 */
    unsigned long long (*Reset)(
        struct EFI_SIMPLE_TEXT_INPUT_EX_PROTOCOL *This,
        unsigned char ExtendedVerification);

    /* 获取按键输入数据 */
    unsigned long long (*ReadKeyStrokeEx)(
        struct EFI_SIMPLE_TEXT_INPUT_EX_PROTOCOL *This,
        struct EFI_KEY_DATA *KeyData);

    /* 等待按键输入的事件，EFI_EVENT类型 */
    void *WaitForKeyEx;

    /* 设置输入设备状态(NumLock、CapsLock等) */
    unsigned long long (*SetState)(
        struct EFI_SIMPLE_TEXT_INPUT_EX_PROTOCOL *This,
        unsigned char *KeyToggleState);

    /* 绑定按键事件处理函数 */
    unsigned long long (*RegisterKeyNotify)(
        struct EFI_SIMPLE_TEXT_INPUT_EX_PROTOCOL *This,
        struct EFI_KEY_DATA *KeyData,
        unsigned long long (*KeyNotificationFunction)(
            struct EFI_KEY_DATA *KeyData),
        void **NotifyHandle);

    /* 解绑按键事件 */
    unsigned long long (*UnregisterKeyNotify)(
        struct EFI_SIMPLE_TEXT_INPUT_EX_PROTOCOL *This,
        void *NotificationHandle);
};
```

图3.1: `EFI_SIMPLE_TEXT_INPUT_EX_PROTOCOL`的GUID和定义

本章将介绍其中的`RegisterKeyNotify()`函数。
