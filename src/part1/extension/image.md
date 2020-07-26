# 显示图片

在1.4中，我们了解了帧缓冲区的起始地址和像素的格式，并绘制了一个矩形。进一步地，我们可以通过类似的方式在屏幕上显示图片。


## 新建blt函数

首先，我们新建一个从我们指定的缓冲区向帧缓冲区传送内容的函数`blt`(Block Transfer)，如代码7.1所示

```c
void blt(unsigned char img[], unsigned int img_width, unsigned int img_height)
{
    unsigned char *fb;
    unsigned int i, j, k, vr, hr, ofs = 0;

    fb = (unsigned char *)GOP->Mode->FrameBufferBase;
    vr = GOP->Mode->Info->VerticalResolution;
    hr = GOP->Mode->Info->HorizontalResolution;

    for (i = 0; i < vr; i++) {
        if (i >= img_height)
            break;
        for (j = 0; j < hr; j++) {
            if (j >= img_width) {
                fb += (hr - img_width) * 4;
                break;
            }
            for (k = 0; k < 4; k++)
                *fb++ = img[ofs++];
        }
    }
}
```

代码7.1: `sample_poios/graphics.c:blt`

上面的代码将缓冲区`img`中的图像逐字节拷贝到帧缓冲区。图像始终从点(0, 0)开始绘制。


## 在Shell中加入查看图片的命令view

接下来，我们向Shell中加入一个新的命令`view`，这个命令使用上面的`blt`函数来在屏幕上显示图片（代码7.2）。这里的图片文件是以UEFI所兼容的像素格式保存的原始(RAW)图像文件。

```c
/* ...省略... */
#define MAX_IMG_BUF  4194304      /* 4MB, 新增 */

unsigned char img_buf[MAX_IMG_BUF];    /* 新增 */
/* ...省略... */
void view(unsigned short *img_name, unsigned int width, unsigned int height)
{
    unsigned long long buf_size = MAX_IMG_BUF;
    unsigned long long status;
    struct EFI_FILE_PROTOCOL *root;
    struct EFI_FILE_PROTOCOL *file;

    status = SFSP->OpenVolume(SFSP, &root);
    assert(status, L"error: SFSP->OpenVolume");

    status = root->Open(root, &file, img_name, EFI_FILE_MODE_READ,
                EFI_FILE_READ_ONLY);
    assert(status, L"error: root->Open");

    status = file->Read(file, &buf_size, (void *)img_buf);
    if (check_warn_error(status, L"warning:file->Read"))
        blt(img_buf, width, height);

    while (getc() != SC_ESC);

    status = file->Close(file);
    status = root->Close(root);
}

void shell(void)
{
    /* ...省略... */

    while (!is_exit) {
        /* ...省略... */
        else if (!strcmp(L"view", com)) {         /* 新增 */
            view(L"img", IMG_WIDTH, IMG_HEIGHT);  /* 新增 */
            ST->ConOut->ClearScreen(ST->ConOut);  /* 新增 */
        } else
            puts(L"Command not found.\r\n");
    }
}
```

代码7.2: `sample_poios/shell.c`[^1]

`view`命令执行时将会调用`view`函数来显示文件名为"img"的图片。`view`函数打开参数中所指定的图片文件，将其原始二进制内容读取并存放至缓冲区`img_buf`中，再调用`blt`函数将其传送至帧缓冲区来显示图像，直到按下Esc键退出。与`cat`和`edit`函数一样，我们实现的所有Shell命令函数都不会在退出时清屏，包括这里的`view`函数。因此，我们需要在`shell`函数调用`view`函数之后再调用`ClearScreen`函数来进行清屏。


> **转换图像至BGRA32格式的方法**
> 
> BGRA32是一种每像素32位的像素格式，其中每个通道（Blue、Green、Red和Alpha）各占用8位。
> 
> 我们可以通过ImageMagick的`convert`命令来把图片转换为BGRA32格式的原始图像文件（没有文件头(header)等内容的二进制文件）。转换的命令如下:
> 
> ```shell
> $ convert hoge.png -depth 8 yux.bgra
> ```
> 
> 由于这里我们实现的`view`命令不支持滚动或是缩放图片。因此，我们可能需要对图片进行缩放来使它可以在屏幕时显示。这里，作者为了适配他的UEFI固件所识别的分辨率，因而把图片缩放到640像素宽 (在QEMU/OVMF下，这个宽度默认为800像素) ，转换并缩放的命令如下：
> 
> ```shell
> $ convert hoge.png -resize 640x -depth 8 yux.bgra
> ```


## 在GUI模式中加入图片查看功能

最后，我们修改`gui.c`，让它在我们点击图片文件时调用`view`函数来显示它（代码7.3）。在poiOS中，我们把所有文件名以小写字母"i"开头的文件都当作图片文件。

```c
/* 处理文件图标 */
for (idx = 0; idx < file_num; idx++) {
    if (is_in_rect(px, py, file_list[idx].rect)) {
        /* ...省略... */
        if (prev_lb && !s.LeftButton) {
            if (file_list[idx].name[0] != L'i')                    /* 新增 */
                cat_gui(file_list[idx].name);
            else                                                   /* 新增 */
                view(file_list[idx].name, IMG_WIDTH, IMG_HEIGHT);  /* 新增 */
            file_num = ls_gui();
        }
        /* ...省略... */
    }
}
```

代码7.3: `sample_poios/gui.c:gui`

这里我们对`gui.c`所作的唯一改动是在`gui`函数的“处理文件图标”的循环中。当我们点击以字母"i"开头的文件时，我们调用`view`函数来打开它，而在点击其他文件时，还是调用之前的`cat_gui`函数。


> **UEFI标准中的Blt函数**
> 
> 事实上，UEFI标准中的`EFI_GRAPHICS_OUTPUT_PROTOCOL`中存在一个名为`Blt`的函数（标准文档"11.9 Graphics Output Protocol(P.474)"）。UEFI标准中的`Blt`函数不仅可以将内容传送至帧缓冲区(EfiBltBufferToVideo)，还可以保存帧缓冲区中的内容(EfiBltVideoToBltBuffer)，或是将帧缓冲区中一个位置的内容移动至另一位置(EfiBltVideoToVideo)。
> 
> 然而，这一函数并不能在作者的Lenovo ThinkPad E450（UEFI版本2.3.1）上调用[^1]，因此这里作者自己实现了一个简单的`blt`函数。UEFI标准中的`Blt`函数仍然可以在QEMU/OVMF（UEFI版本2.3.1）上调用。


[^1]: 译者注：为了使非分辨率宽度的图片能够正常显示，中文版的`view`函数新增了宽度width和高度height两个参数。

[^2]: 调用后返回成功的状态，但屏幕上没有任何变化。
