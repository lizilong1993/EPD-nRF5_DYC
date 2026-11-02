# 0x26 修正与验收记录

日期：2026-11-02。目标：nRF52811、S112 7.3.0、7.5 寸三色 UC8179（驱动 07）。
> 实机连接验收未通过（2026-11-02）：固件传输后两轮扫描共约 142 秒未发现应用广播，随后手机多次扫描为 0；电脑 45 秒扫描收到 384 个广播、18 个设备，但没有 NRF_EPD 或 DfuTarg。用户报告持续快速闪灯。不能把此包标为可用升级包，启动/复位故障原因尚未确定。


## 固件

异步配置保存使用独立写入快照，避免连续命令改动 SoftDevice 正在写入的源缓冲区。buttonless 的 SoftDevice-disabled 观察者改用 `NRF_PWR_MGMT_SHUTDOWN_GOTO_DFU`；正常深睡仍使用 `GOTO_SYSOFF`。这是一处源码修改，不能据此认定实机失败根因。此前“在役 0x20 必须先 SWD 烧入”的结论证据不足，现予撤回。

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

App buttonless 策略：收到 `20 01 01` 仅记录请求已接受；最多等待设备断开 15 秒，再清理 GATT 并扫描。等待超时显式报错，不主动调用 disconnect；只有发现 DFU 广播后才标记 bootloader 状态。每次连接重置断开状态，并忽略旧连接的迟到状态回调。

对应提交 `fe4ee30` 已推送。签名 HAP：`EPDConsole-dev.hap`；SHA256：8b4f8c9390ccbedcc13b8631425372c9b8c2a493e3e2c8219d549cde8df270ba。ArkTS 构建和签名校验成功并已安装，Web 对拍与 tone 参数检查通过；生产类 GATT mock 测试 5/5 通过，独立审查完成。

## DFU 诊断与实机证据

本地 SDK 的 `ble_dfu.c` 正常路径为 HVC（indication 确认）→ prepare → GPREGRET → `GOTO_DFU`；`nrf_pwr_mgmt` 锁存首次 shutdown 请求。目前未发现正常流程触发 `main.c` 的 SoftDevice-disabled 观察者，因此不能把观察者中的 `GOTO_SYSOFF` 认定为实机确定根因。

手机日志 `phone-dfu-snapshot-20261102.log` 与 `phone-bluetooth-service-20261102.log` 记录：

- 10:53:25.651：收到 buttonless 响应 `20 01 01`。
- 10:53:25.655：手机发送 HCI disconnect。
- 10:53:59.790：App 报未发现 DfuTarg。

修改前的证据仅确认请求被接受，随后 bootloader 未被 App 发现。修改 App 断连时序后，`C:/Users/lizilong/Downloads/epd-deliver-026/logs/phone-dfu-wait-snapshot.log` 记录：

- 11:09:36.011：收到 `20 01 01`，仅记录请求已接受。
- 11:09:36.012：开始等待设备断开。
- 11:09:41.166：收到 GATT 断开事件；11:09:41.204 结束等待，日志计时 5,192 毫秒。
- 11:09:47.056：第一轮扫描发现 1 个候选；11:09:47.058 连接 DfuTarg。
- 11:09:48.420：DFU 就绪，开始传输。
- 11:09:56.743：传输完成，开始等待应用固件重新广播。
- 11:12:19.259：两轮扫描结束，未发现 NRF_EPD；没有读回 0x26。
- 此后手机扫描及电脑独立扫描均未发现目标；用户报告持续快速闪灯，重复启动仅为待验证假设。

本次未使用 SWD，实机已走通 buttonless → 发现并连接 DfuTarg → 固件传输。这与修改前的失败构成 A/B 证据，支持收到响应后过早主动断开是故障因素；但未捕获设备端 HVC，不能断言其确切内部丢失原因，也不能把 SoftDevice-disabled 观察者中的 `GOTO_SYSOFF` 认定为实机根因。固件传输完成尚不等于升级后应用启动和版本读回通过。

## 待硬件验收

当前 USB 手机已连接，未发现 SWD 调试器。下列项目尚未完成：

- 如需进一步定位内部原因，补充设备端 HVC、复位证据。当前手机日志已验证 DfuTarg 扫描、连接和传输。
- 如需备用恢复，再使用 SWD（保留 SoftDevice 和 bootloader，避免全片擦除；需核对 bootloader settings 与应用校验信息）；尚不能判定 SWD 为必需或唯一方案。
- 启动后读取版本 0x26。
- 升级后连接、断电重启、屏幕红黑白预览、传图和步进操作。

编译、签名、DfuTarg 连接与传输已通过；尚未确认的项目不能据此视为通过。

## 完整断电后的复测

用户完全断电约 30 秒后重新上电，仍报告快速连续闪灯。Windows 独立主动扫描 75 秒（覆盖 60 秒广播周期）收到 965 个广播包、34 个设备，目标数 0。原始输出：epd-deliver-026/logs/pc-coldboot-026-scan.log。当前没有找到应用或 DFU 的无线恢复入口，不能宣称冷启动可恢复；也没有硬件测量证明主板损坏。有线恢复可能需要 SWD，实际 bootloader/UICR/settings 与错误状态尚未读取。

原厂应用镜像恢复候选包已在本机 epd-recovery 准备，尚未刷入：应用 BIN 与 7.5 寸 V2.0.1 厂商包逐字节一致，56,228 字节。init fw_version 使用 0x26，与本次版本计数相同；应用内读回版本仍为厂商 0x19。此包不是完整烧录 HEX，也不能解决缺少 bootloader 通信入口的问题。ZIP SHA256：6873b1de5aff948dbc85a82ccf7e62be36c70e707d3c6c8401c114f60f28835f。

## 源码与二进制定位结果

已确认日历/时钟模式的 Limited 标志与无限广播时长为不合法组合；当前配置默认回退路径可进入该模式。实际启动错误码和运行模式尚未读取，不能将静态条件链直接当作本机运行时根因。详细取证、替代假设与排除项见 [026-incident-analysis.md](026-incident-analysis.md)，给维修方的短说明见 [026-repair-handoff.md](026-repair-handoff.md)。本轮未修改生产源码，未生成新的试验固件。
