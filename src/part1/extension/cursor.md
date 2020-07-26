# 更大的鼠标指针

尽管我们之前实现的1像素大的鼠标指针是能用的，但是它太小了，并不好用。现在我们来把它改成更大的4x4像素的鼠标指针。

实现这点只需要修改`gui.c`这个源文件，如代码7.7所示。

```c
#define CURSOR_WIDTH   4  /* 追加 */
#define CURSOR_HEIGHT  4  /* 追加 */
/* ...省略... */
/* 新增(此处开始) */
struct EFI_GRAPHICS_OUTPUT_BLT_PIXEL cursor_tmp[CURSOR_HEIGHT][CURSOR_WIDTH] =
{
    {{0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}},
    {{0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}},
    {{0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}},
    {{0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}}
};
int cursor_old_x;
int cursor_old_y;
/* 新增(此处结束) */
/* ...省略... */
/* 更改(此处开始) */
void draw_cursor(int x, int y)
{
    int i, j;
    for (i = 0; i < CURSOR_HEIGHT; i++) {
        for (j = 0; j < CURSOR_WIDTH; j++) {
            if ((i * j) < CURSOR_WIDTH) {
                draw_pixel(x + j, y + i, white);
            }
        }
    }
}

void save_cursor_area(int x, int y)
{
    int i, j;
    for (i = 0; i < CURSOR_HEIGHT; i++) {
        for (j = 0; j < CURSOR_WIDTH; j++) {
            if ((i * j) < CURSOR_WIDTH) {
                cursor_tmp[i][j] = get_pixel(x + j, y + i);
                cursor_tmp[i][j].Reserved = 0xff;
            }
        }
    }
}

void load_cursor_area(int x, int y)
{
    int i, j;
    for (i = 0; i < CURSOR_HEIGHT; i++) {
        for (j = 0; j < CURSOR_WIDTH; j++) {
            if ((i * j) < CURSOR_WIDTH) {
                draw_pixel(x + j, y + i, cursor_tmp[i][j]);
            }
        }
    }    
}
/* 更改(此处结束) */

void put_cursor(int x, int y)
{
    if (cursor_tmp[0][0].Reserved) {  /* 更改 */
        load_cursor_area(cursor_old_x, cursor_old_y);
    }

    save_cursor_area(x, y);

    draw_cursor(x, y);

    cursor_old_x = x;
    cursor_old_y = y;
}
/* ...省略... */
```

代码7.7: `sample_poios/gui.c`

上面的代码并没有做什么非常大的改动，只是加大了各个函数所需要处理的区域。绘制“┏”形状的光标是通过绘制相对坐标符合`(x * y) < CURSOR_WIDTH`的像素实现的，如图7.1所示。

```ignore
  0 1 2 3
0 ■ ■ ■ ■
1 ■ ■ ■ ■
2 ■ ■ □ □
3 ■ ■ □ □
```

图7.1: 所绘制的光标形状
