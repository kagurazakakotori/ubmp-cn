# 编写一个回显程序

代码3.3展示了一个回显程序的例子。这个程序使用`ReadKeyStroke`的函数，把输入的文字输出到屏幕上。本节示例代码的目录是`echo` (日文版为`sample2_1_echoback`)。

```c
struct EFI_INPUT_KEY {
    unsigned short ScanCode;
    unsigned short UnicodeChar;
};

struct EFI_SYSTEM_TABLE {
    char _buf1[44];
    struct EFI_SIMPLE_TEXT_INPUT_PROTOCOL {
        unsigned long long _buf;
        unsigned long long (*ReadKeyStroke)(
            struct EFI_SIMPLE_TEXT_INPUT_PROTOCOL *This,
            struct EFI_INPUT_KEY *Key);
    } *ConIn;
    unsigned long long _buf2;
    struct EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL {
        unsigned long long _buf;
        unsigned long long (*OutputString)(
            struct EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *This,
            unsigned short *String);
        unsigned long long _buf2[4];
        unsigned long long (*ClearScreen)(
            struct EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *This);
    } *ConOut;
};

void efi_main(void *ImageHandle __attribute__ ((unused)),
          struct EFI_SYSTEM_TABLE *SystemTable)
{
    struct EFI_INPUT_KEY key;
    unsigned short str[3];
    SystemTable->ConOut->ClearScreen(SystemTable->ConOut);
    while (1) {
        if (!SystemTable->ConIn->ReadKeyStroke(SystemTable->ConIn, &key)) {
            if (key.UnicodeChar != L'\r') {
                str[0] = key.UnicodeChar;
                str[1] = L'\0';
            } else {
                str[0] = L'\r';
                str[1] = L'\n';
                str[2] = L'\0';
            }
            SystemTable->ConOut->OutputString(SystemTable->ConOut, str);
        }
    }
}
```

代码3.3： `echo/main.c`

上面的代码中，我们把`EFI_SIMPLE_TEXT_INPUT_PROTOCOL`的定义添加到了`EFI_SYSTEM_TABLE`中。

`efi_main`函数调用`ClearScreen`清屏后，将进入一个无限循环。在这个循环中，当`ReadKeyStroke`成功获取一个按键输入后，我们把输入的字符`key.UnicodeChar`放入字符串`str`中，添加`\0`结尾，并调用`OutputString`函数来把这个字符输出到屏幕上。另外，对于Enter键，由于获取到的字符为CR(`\r`)，输出时还加上了LF(`\n`)来实现换行。请注意，在UEFI中，输入的字符不会被自动显示在屏幕上，因此输入的内容只会显示一遍。

当运行这个例子时候，你在键盘上的输入将会一模一样地显示在屏幕上（图3.2）。

![回显程序运行时的截图](../../images/part1/echo.png)

图3.2: 回显程序执行时的截图


## 补充: 等待键盘输入 (WaitForKey)

在代码2.3的`while`循环中，`ReadKeyStroke`将会被调用多次，直至其成功获取到一个按键输入。然而，在获取到输入前阻塞这个循环，是一个对CPU更为友好的方式。这一部分示例代码的目录是`echo-wait`。

为此，`EFI_SIMPLE_TEXT_INPUT_PROTOCOL`提供了一个名为`WaitForKey`的成员来实现这样的阻塞输入的功能。（代码3.4/标准文档"11.3 Simple Text Input Protocol(P.421)"）

```c
struct EFI_SIMPLE_TEXT_INPUT_PROTOCOL {
    unsigned long long _buf;
    unsigned long long (*ReadKeyStroke)(
        struct EFI_SIMPLE_TEXT_INPUT_PROTOCOL *This,
        struct EFI_INPUT_KEY *Key);
    void *WaitForKey;
};
```

代码3.4: `WaitForKey`的定义

标准文档中定义的`WaitForKey`的类型是`EFI_EVENT`，这是UEFI中代表事件的类型，它是`void *`的别名。如标准文档第421页所述，`WaitForKey`作为`WaitForEvent`函数的参数来使用。

`WaitForEvent`是阻塞进程直到所指定的事件发生的函数，其在`SystemTable->BootService`被定义。`BootServices`是一个`EFI_BOOT_SERVICES`类型的结构体，UEFI通过它提供一系列函数（服务），这些函数主要用于实现引导加载程序(Bootloader)（详细内容将在下章讨论）。`WaitForEvent`的定义如代码2.5所示：

```c
unsigned long long (*WaitForEvent)(
    unsigned long long NumberOfEvents,
    void **Event,
    unsigned long long *Index);
```

代码2.5: `WaitForEvent`的定义

其参数含义如下：

* `unsigned long long NumberOfEvents`: 第二个参数`Event`中的事件数量
* `void **Event`: 所要等待的事件数组
* `unsigned long long *Index`: 指向变量的指针。当满足条件的某一事件发生时，该变量将会被设为事件数组中该事件的索引值。

使用`WaitForKey`和`WaitForEvent`函数来等待按键输入的例子如代码3.6所示。

```c
struct EFI_INPUT_KEY key;
unsigned long long waitidx;

/* 阻塞，直到按键输入 */
SystemTable->BootServices->WaitForEvent(1,&(SystemTable->ConIn->WaitForKey), &waitidx);

/* 获取所输入的按键 */
SystemTable->ConIn->ReadKeyStroke(SystemTable->ConIn, &key);
```

代码3.6: 使用`WaitForKey`和`WaitForEvent`的例子
