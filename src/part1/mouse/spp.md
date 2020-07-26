# 简单指针协议

用于获取鼠标输入的是简单指针协议（Simple Pointer Protocol）`EFI_SIMPLE_POINTER_PROTOCOL`（标准文档"11.5 Simple Pointer Protocol(P.439)"）。不要害怕，这里的指针不是内存地址，而是诸如鼠标、轨迹球、触摸板这样的指针设备。本书所要用到的定义如代码5.1所示。

```c
struct EFI_SIMPLE_POINTER_PROTOCOL {
    unsigned long long (*Reset)(
        struct EFI_SIMPLE_POINTER_PROTOCOL *This,
        unsigned char ExtendedVerification);
    unsigned long long (*GetState)(
        struct EFI_SIMPLE_POINTER_PROTOCOL *This,
        struct EFI_SIMPLE_POINTER_STATE *State);
    void *WaitForInput;
};
```

代码5.1: `EFI_SIMPLE_POINTER_PROTOCOL`的定义

其中，`Reset`函数用于重置指针设备（鼠标），`GetState`函数则用于获取设备的状态。

`Reset`函数的参数含义如下：

* `unsigned char ExtendedVerification`: 用于指示是否执行完整检查的标志，其执行的操作由固件决定。在本书中，由于我们不需要这样的检查，我们将其设置为`FALSE`。

并且，`GetState`函数的参数含义如下：

* `struct EFI_SIMPLE_POINTER_STATE *State`: 指向存放指针设备状态的结构体的指针。

代码5.2展示了存放指针设备状态的结构体`EFI_SIMPLE_POINTER_STATE`的定义。

```c
struct EFI_SIMPLE_POINTER_STATE {
    int RelativeMovementX;      /* X轴方向的相对移动量 */
    int RelativeMovementY;      /* Y轴方向的相对移动量 */
    int RelativeMovementZ;      /* Z轴方向的相对移动量 */
    unsigned char LeftButton;   /* 左键状态，按下为1，松开为0 */
    unsigned char RightButton;  /* 右键状态，同上 */
};
```

代码5.2: `EFI_SIMPLE_POINTER_STATE`的定义

这个结构体各成员的含义如代码5.2中注释所述。此外，对于一般的鼠标而言，其`RelativeMovementZ`恒为0。（由于作者并没有什么特别的鼠标，在作者的尝试中，没有出现过不为0的情况）

`EFI_SIMPLE_POINTER_PROTOCOL`中的`WaitForInput`是用于等待鼠标输入的函数。和之前[3.2 编写一个回显程序](../input/echo.md)中提到的`WaitForKey`一样，它也作为`WaitForEvent`函数的参数来使用。
