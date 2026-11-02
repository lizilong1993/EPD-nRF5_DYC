# 0x26 修正与验收记录

日期：2026-11-02。目标：nRF52811、S112 7.3.0、7.5 寸三色 UC8179（驱动 07）。

## 固件

异步配置保存使用独立写入快照，避免连续命令改动 SoftDevice 正在写入的源缓冲区。buttonless 的 SoftDevice-disabled 观察者改用 `NRF_PWR_MGMT_SHUTDOWN_GOTO_DFU`；正常深睡仍使用 `GOTO_SYSOFF`。当前在役 0x20 存在相同关机问题，必须先通过 SWD 烧入修正版一次，不能依靠当前 buttonless OTA 自举修复。

仓库已同步交接中的 0x26 源码与链接布局。使用 GCC 14.2.1、仓库根 Makefile 构建成功，BIN 与交接源码目录重新构建结果逐字节一致。链接器有 newlib 未实现 syscall 的警告，构建成功。

- APP_VERSION / init fw_version：0x26（38）
- FLASH：0x19000，长度 0xE000（57,344 字节）
- 应用：52,984 字节
- BIN SHA256：e7f2c7c9e4d30724a0ea7f66f2485241ba36346b80f70dfda5282cbdcfa4312e
- OTA ZIP SHA256：00ab9a35777771a1a9785cc21c122e618937809e600644df5e76898bf79d5fb3
- init 内 SHA256（小端）：2e31a4cfbd2c28a5fd0df7806b3436ba415248f2667feaa02407d3e4c9c7f2e7
- nrfutil：6.1.7；hw-version 52；sd-req / sd-id 0x126；ECDSA_P256_SHA256
- ZIP 内容：manifest.json、EPD-nRF52.bin、EPD-nRF52.dat

本机交付目录：`C:/Users/lizilong/Downloads/epd-deliver-026/`。密钥、HEX、ZIP、HAP、编译缓存不纳入本次 Git 提交。

## App

DfuTarg 使用服务 UUID 和名称过滤，空过滤显式报错。三色路径接入亮度、伽马和饱和度步进，中性参数保持原 Web 算法；现有对比度 1.2 不变，亮度 / 伽马 / 饱和度默认 0 / 1 / 1。

签名 HAP：`EPDConsole-dev.hap`；SHA256：4e7fd8d02327bf42bba1d0c998e953f785a12f127698815b7ccd7d88ea437aab。ArkTS 构建和签名校验成功，Web 对拍与 tone 参数检查通过。

## 待硬件验收

当前设备枚举未发现 SWD 调试器或鸿蒙手机，下列项目尚未验证：

- SWD 烧入（保留 SoftDevice 和 bootloader，避免全片擦除；需核对 bootloader settings 与应用校验信息）。
- 启动后读取版本 0x26。
- buttonless 后 DfuTarg 广播及 OTA 完整传输。
- 升级后连接、断电重启、屏幕红黑白预览、传图和步进操作。

编译和签名通过不代表上述硬件验收已通过。
