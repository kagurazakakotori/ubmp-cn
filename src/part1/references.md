# 参考资料

## 本书所参考的资料

* UEFI标准
  * [https://www.uefi.org/specifications](https://www.uefi.org/specifications)
  * 这是第一手资料，请尽可能多的参考它

* ツールキットを使わずに UEFI アプリケーションの Hello World! を作る - 品川高廣（東京大学）のブログ
  * 不使用开发工具包的情况下编写 UEFI 的 Hello World! 程序 - 东京大学品川高广教授的博客
  * [https://d.hatena.ne.jp/shina_ecc/20140819/1408434995](https://d.hatena.ne.jp/shina_ecc/20140819/1408434995)
  * 这篇文章是我进行UEFI裸机编程的起点

* EDK2的源代码
  * [https://github.com/tianocore/edk2](https://github.com/tianocore/edk2)
  * 我参考了它对于UEFI标准的的实现

* gnu-efi的源代码
  * [https://sourceforge.net/p/gnu-efi/code/ci/master/tree/](https://sourceforge.net/p/gnu-efi/code/ci/master/tree/)
  * 同上


## 除本书外的关于UEFI裸机编程的资料

* 我的博客 (へにゃぺんて＠日々勉強のまとめ)
  * UEFIベアメタルプログラミング - Hello UEFI! (ベアメタルプログラミングの流れについて)
    * UEFI裸机编程 - Hello UEFI! (裸机编程的流程)
    * [https://d.hatena.ne.jp/cupnes/20170408/1491654807](https://d.hatena.ne.jp/cupnes/20170408/1491654807)
  * UEFIベアメタルプログラミング - マルチコアを制御する
    * UEFI裸机编程 - 多核编程
    * [https://d.hatena.ne.jp/cupnes/20170503/1493787477](https://d.hatena.ne.jp/cupnes/20170503/1493787477)

* 示例代码
  * [https://github.com/cupnes/bare_metal_uefi](https://github.com/cupnes/bare_metal_uefi)
  * 这些代码和本书的示例代码非常类似，但其中涉及到一些本书没有介绍的功能
  * 处理计时器事件的例子
    * [https://github.com/cupnes/bare_metal_uefi/tree/master/080_timer_wait_for_event](https://github.com/cupnes/bare_metal_uefi/tree/master/080_timer_wait_for_event)
