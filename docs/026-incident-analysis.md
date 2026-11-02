# 0x26 升级后失联分析与送修取证

日期：2026-11-02。对象：nRF52811、S112 7.3.0、7.5 寸 UC8179 黑白红屏。本文记录本次具体交付，不以旧会话结论替代实物证据。

## 当前结论

**已确认交付固件存在广播配置缺陷：日历／时钟模式使用 Limited Discoverable 标志，却将广播时长设为 0（无限）。该组合不合法。当前错误处理会立即复位，开机 LED 又在广播启动前闪烁，形成可解释本次现象的完整条件链。**

配置格式从旧源码的 FDS 切换为固定地址记录，未做迁移；读不到有效新记录时会回退到日历模式，能够触发上述错误。因此，不能用升级前是相册模式来排除这一分支。

这是已确认的源码／二进制缺陷，也是目前最应优先验证的实际故障原因；**设备上的模式值和具体错误码尚未读取，不能声称已经唯一确定了这台设备的运行时根因**。如果实机实际模式仍为相册 0，必须继续检查其他启动错误。

## 1. 已交付内容与观察

| 项目 | 核查结果 |
|---|---|
| OTA ZIP SHA256 | `00ab9a35777771a1a9785cc21c122e618937809e600644df5e76898bf79d5fb3` |
| 应用 BIN | 52,984 字节；SHA256 `e7f2c7c9e4d30724a0ea7f66f2485241ba36346b80f70dfda5282cbdcfa4312e` |
| init 参数 | application；fw 0x26；hw 52；sd_req 0x126；内嵌图像哈希匹配 |
| 地址范围 | `[0x19000, 0x25ef8)`；SP `0x20006000`；reset vector `0x214e9` |
| 分析用 ELF SHA256 | `ffb2bc2bc9a23e664a5d73cbc5efe02fe77e6fbfeca3b231360a9d7b193ebc65` |
| 一致性 | ZIP CRC、init 图像哈希、BIN 与仓库构建 BIN、HEX 重建内容全部核对通过 |

本机原始交付目录为 `C:/Users/lizilong/Downloads/epd-deliver-026/`。逐字节核查脚本和输出位于 `C:/Users/lizilong/Downloads/epd-incident/`。这些是下载／诊断产物，不纳入源码 Git，密钥和手机签名资料不进入送修证据包。

实机时间线（手机日志，UTC+8）：

1. 10:51:49 读到原应用版本 0x20，可以连接。
2. 旧 App 10:53:25 收到 `20 01 01` 后立即主动断开，未发现 DfuTarg。
3. App 改为等待设备断开后，11:09:36 收到成功响应；11:09:41 收到断开事件，等待约 5.2 秒。系统日志的断开原因为 Connection Timeout，不应把这当作抓到了固件发出的主动断开包。
4. 11:09:47 第一轮扫描发现 DfuTarg，连接并发现控制点／数据特征。
5. 11:09:48 开始对象传输；11:09:56 App 记录传输完成。本次无最终 EXECUTE 超时兜底提示；按现有控制流，其最终响应校验已通过，但日志未记录响应原始字节。
6. 11:12:19 两轮返回应用扫描结束，未发现 NRF_EPD，没有读回 0x26。后续手机扫描仍失败。
7. 用户报告持续快速闪灯。电脑 45 秒扫描发现 18 个周边设备而无目标；完整断电约 30 秒再上电后，电脑 75 秒扫描收到 965 个广播包、34 个设备，目标数仍为 0。

以上支持“设备进入过 bootloader 并完成传输协议，随后未完成可连接应用验收”。不能仅凭传输进度宣称激活、启动或设备健康。

## 2. 首要缺陷：广播时长与标志冲突

源码位置：`main.c:55-56`、`main.c:650`、`main.c:659-661`、`main.c:382`。

| 配置模式 | interval（0.625 ms 单位） | duration（10 ms 单位） | 标志 | 判断 |
|---|---:|---:|---|---|
| 相册 0 | 320＝200 ms | 200＝2 s | 0x05 Limited | 该组合合法 |
| 日历 1／时钟 2 | 3200＝2 s | 0＝无限 | 0x05 Limited | 不合法组合 |

Nordic 官方说明：Limited Discoverable 不能与无限超时组合，应改为 General Discoverable；对应案例报告 `sd_ble_gap_adv_set_configure()` 返回 `NRF_ERROR_INVALID_PARAM=7`，修改标志后解决。[Nordic 官方答复](https://devzone.nordicsemi.com/f/nordic-q-a/90224/sd_ble_gap_adv_set_configure-returns-nrf_error_invalid_param)

二进制交叉核验：ELF `main@0x19b88` 写入标志 5，`main@0x19c5e` 在非相册分支写入 interval 3200／duration 0。此问题确实存在于被打包的程序中。

SDK 的 `ble_advertising_init()` 首次以 data=NULL 配置 handle；首次 `ble_advertising_start()` 才携带上述广播数据配置。因此优先捕获 **start 内 configure 的返回值**，不能笼统声称已经读到了 init 的错误。

条件链为：

```text
加载配置，模式为日历／时钟
→ ble_epd_init 中 LED 亮100ms、灭100ms
→ advertising_start
→ Limited 标志 + duration 0
→ SoftDevice 拒绝配置
→ APP_ERROR_CHECK
→ app_error_fault_handler 写 SYSRESETREQ
→ 再次启动、再次闪灯
```

ELF `advertising_start@0x1973e` 检查非零返回值，并进入 `app_error_handler_bare@0x1fc30`；`app_error_fault_handler@0x1fc4c` 确认写 AIRCR 的 SYSRESETREQ。错误循环不必等 60 秒看门狗超时。

最小修复方向：在 `main.c:650` 使用 `BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE`，使无限广播模式合法；同时为启动错误保存阶段、错误码和复位原因。**本文仅给出修复方向，未生成或刷写新的试验包。**

## 3. 为什么升级前相册模式也可能触发

旧手机配置 `1413060504030207ff1207000100` 的前 13 字节按结构解析：模式在 offset 11，为 `00`（相册）；offset 12 的 `01` 是星期起始，不能当作日历模式。

但当前 `EPD/EPD_config.c:110-125` 不读取旧 FDS，只认 `0x27000` 处固定记录。magic 是数值 `0x45504443`，小端实际字节为 `43 44 50 45`。缺少 magic 或字段无效时，配置变成全 FF。

`EPD/EPD_service.c:509-524` 随后复制 11 字节 GPIO／型号默认值，并将仍为 FF 的模式补为 `MODE_CALENDAR=1`，然后开始保存。

所以，如果返修后的旧固件仍用 FDS、且没有有效新记录，就会发生：**旧相册配置未迁移 → 默认日历 → 无限 Limited 广播 → 错误复位**。旧源码确为 FDS；返修后实机 Flash 是否符合此条件，需要读取才能确认。

## 4. 替代原因与已核对项

| 项目 | 结论及证据边界 |
|---|---|
| SVCI 初始化错误处理 | 确有缺陷。`ble_dfu_unbonded.c:144-156` 在切换 bootloader 向量后，若 adv_name 初始化失败，会提前返回而不恢复应用向量；`main.c:762` 又忽略返回值。是否触发取决于实际 bootloader 和返回码，未读取。 |
| BSS／data 初始化 | 当前 ELF 的 Reset 将 `.data/.fs_data` 复制到 RAM `[0x200022d8,0x20002520)`；CRT 清零 BSS `0x20002520..0x20002c48`。没有复现旧 0x25 的 BSS 清零长度为 0 问题。 |
| 静态堆栈布局 | heap 8192 字节，`0x20002c48..0x20004c48`；stack 2048 字节，`0x20005800..0x20006000`，无静态重叠。不等于已经测过动态高水位。 |
| GUI 内存 | 800 像素宽默认页缓冲申请 7600 字节，并非一次申请整幅 96000 字节；malloc 失败未检查、_sbrk 缺少边界检查是残余风险，目前无现场证据证明触发。 |
| 屏幕 BUSY | 每100ms翻转 LED，约5Hz；单次有30秒超时并持续喂狗。快闪本身不能唯一证明重启。广播启动早于首次刷屏，单独 BUSY 等待不足以解释本次所有广播都未观测到。 |
| 最终传输后主动断开 | App 确实立即清理了 GATT；本地 SDK settings／激活完成链不依赖持续连接，尚无证据证明该断开导致激活失败。 |
| SYSOFF 观察者 | 正常 SDK buttonless 流自身请求 GOTO_DFU；不能继续把 SD-disabled 观察者当作已证实根因。本轮实际发现 DfuTarg 也已否定“当前0x20必需先SWD”的绝对结论。 |
| 实机 Flash 布局／bootloader | 未读回。固定配置页 `0x27000` 的安全性依赖实际 bootloader 保留区，不能只用本地 SDK 宏证明返修后的布局。无证据证明 bootloader 已被破坏。 |
| 硬件损坏 | 没有电气测量或 SWD 检测，不能认定。 |

## 5. 给维修方的优先取证顺序

**尽可能先读回，再擦除恢复。若读保护导致无法读回，请记录这一事实；不要为了取证直接执行会全片擦除的 recover 命令。**

1. 保存全 Flash 和 UICR，记录实际芯片 PART／RAM／Flash、SoftDevice、bootloader 地址和版本、bootloader settings／MBR 参数；特别保留 `0x27000..0x28fff` 及旧 FDS 数据。上述范围是待核对的数据区域，不代表已验证其在实机上的用途。
2. 将应用区域与本次 BIN 对照，确认实际激活的镜像。只有应用一致时才使用下面的精确断点地址。
3. 读取 Flash `0x27000` 的记录与 magic；mode 在 `0x2700f`，须同时检查记录有效性。运行后 RAM 的 `m_epd.config.display_mode` 在本 ELF 中为 `0x200027fb`。
4. 首选断点 `advertising_start@0x1973e`，读取 R0；内部 `sd_ble_gap_adv_set_configure` 返回后位置是 `0x1ea48`。若 R0=7 且 mode=1/2，即能直接确认首要故障链。若不同，按实际返回码继续定位。
5. 在 `app_error_handler_bare@0x1fc30` 捕获 R0、LR／调用栈；读取 RESETREAS 及程序保存的 `m_resetreas@0x200027cc`。如果没有走到该错误处理，应捕获实际 PC、异常栈、CFSR／HFSR／MMFAR／BFAR。
6. 核对 `ble_dfu_buttonless_async_svci_init()` 的返回值及最终中断向量是否恢复应用地址 `0x19000`，排除第4节的替代启动问题。
7. 证据保留后，用维修方确认匹配这块屏幕的原厂固件恢复；实际验证启动广播、GATT 连接、版本读取与再次断电后的连接。

## 6. 本次分析方法与限制

分析只读取交付 ZIP／HEX／ELF、对应源码和已有手机／电脑日志，未继续刷写设备，也未改生产源码。

REA MCP 未连接，CLI 的 ELF layout provider 在当前 Windows 环境返回不支持；未为此修改客户端配置或安装分析引擎。二进制核查使用现有 GNU objdump／nm 和 Python，所列汇编证据属于这些工具的静态输出，不是 REA 运行时证据。

独立分析分别复核了广播参数／错误复位链，以及配置迁移／SVCI／初始化布局。源码和静态二进制不能代替 SWD 现场：最终还需模式值、返回码和故障位置，才能把“确定存在的缺陷”确认为“本机此次触发的根因”。
