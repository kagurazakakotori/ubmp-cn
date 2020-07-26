# Hello UEFI!

本章将介绍在UEFI下进行裸机编程的流程，包括环境的搭建，和编写并执行第一个“Hello world”程序。

在UEFI固件中加载并执行的程序被称为“UEFI应用程序”（UEFI Application）。本书介绍的裸机编程，是编写UEFI应用程序，并在PC上运行。其一般流程如下：

1. 遵循UEFI标准编写程序
2. 交叉编译为UEFI可执行的二进制文件
3. 创建启动盘引导并运行UEFI应用程序

接下来，我们将一步步地编写我们的第一个“Hello UEFI!”程序。
