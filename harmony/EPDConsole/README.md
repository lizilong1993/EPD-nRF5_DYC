# 墨水屏控制台（HarmonyOS / OpenHarmony）

基于 [YCD12/EPD-nRF5_DYC](https://github.com/YCD12/EPD-nRF5_DYC) 线上版（`Tmp` 分支 `html/`）的鸿蒙重写。

## 已实现（v1）

- BLE 扫描（显示全部设备，按 RSSI 排序；网页版的 `NRF_EPD` 前缀过滤在这里改为手动选择）
- GATT 连接/断开、读取固件版本、订阅通知
- 设备控制：驱动/引脚写入（0x00 + 0x01）、星期起始（0x21）、日历/时钟/老款时钟（0x20，mode=3 固件未实现）、清屏（0x02）、原始十六进制命令
- 裁剪：默认按设备比例，支持拖拽边/角调整
- 连接后自动按设备配置选择驱动、画布尺寸与颜色（修复通知监听晚于 CCCD 导致首包配置丢失）
- 传图：选择图片 → 适配（拉伸/裁剪填充/适应留白）→ 旋转/镜像/翻转 → 亮度/伽马/饱和/对比度 → 抖动（线性光 + 蛇形扫描）→ 黑白/三色/四色打包 → CRC16 块传输（固件 ≥ 0x20）/ 传统 0x30 传输（< 0x20）→ REFRESH
- 三色增强：HSV 饱和度/色相判定红色通道，可调“红色灵敏度”；灰度在 linear RGB 中做误差扩散（参考 didder / @opendisplay/epaper-dithering 的做法）
- UC8159（驱动 08/09）2bpp 重排
- 导出 `imagedata.h`（文件保存器）
- MTU / 确认间隔可调、进度显示、日志

## HarmonyOS 7 实测要点（已修）

1. `ble.startBLEScan([])` 在 HarmonyOS 7 返回 `401 Invalid parameter`，必须带过滤器。
   本项目用 `serviceUuid = 62750001-d828-918d-fb46-b6c11c675aec`（固件在 scan response 中携带它）。
2. `getServices()` 在部分固件上会因框架描述符转换报 `memcpy_s error` 并卡 10s 超时（2900099）。
   已在 4s 超时后按 UUID 直接构造特征对象兜底，实测可继续读版本/开通知/写命令。
3. 连接后立即 `setBLEMtuSize()` 会与后续 GATT 命令冲突，导致 INIT 写超时；
   目前不在连接阶段请求 MTU，使用固件上报的 `mtu=244` 作为分包依据（待真机传图验证协商值）。

## 固件升级（Nordic Secure DFU）

- 设置 → 固件升级：选择 .zip（nrfutil 6 包）→ 解析 manifest/bin/dat → 校验 hw=52、sd_req=0x126、文件名与设备型号 → 确认电量 → BLE 进入 Bootloader → Secure DFU 传输（PRN=0、CRC32、对象分块）→ 设备重启。
- 包内不含型号/驱动信息，只能按文件名提示校验；无提示时要求用户确认。
- 传输中断可重试；设备停留在 bootloader 时 App 会自动识别，并按 SELECT 返回的 offset/CRC 续传。
- 依赖：应用固件需启用 buttonless DFU（本仓库 S112 构建已启用）。

### DFU 官方实现核对（2026-10-23）

已按厂商固件源码（SDK 17.1.0）与 Nordic 官方 DFU 库逐项核对，详见 [docs/dfu-official-research.md](docs/dfu-official-research.md)。

- App 模式 `8EC90003` 是 **write + indicate**；固件在 CCCD 未配成 indication 时拒绝写入并返回 CCCD 配置错误，HarmonyOS 表现为 2900099。现已改用 `setCharacteristicChangeIndication()` 并等待 `0x20 0x01 0x01` 指示后再断开。
- bootloader（`DfuTarg` / 0xFE59）使用 notification，且非绑定模式地址会 +1，必须按广播重新扫描，不能复用升级前 deviceId。
- CRC32 为整包累计值；对象需页对齐（4096），最后对象除外；校验必须比较累计 offset 与「前 offset 字节」的 CRC。
- 支持断点续传与对象级重试，最终 EXECUTE 响应丢失时以设备重启后重新广播 `NRF_EPD` 作为完成判据。

## 连接状态码（App ↔ 固件，v0.22）

| 方向 | 帧 | 含义 |
|---|---|---|
| App → 设备 | `70 00` | IDLE：空闲超时/退出，设备回 ACK 后结束会话 |
| App → 设备 | `70 01` | HOLD：连接保持心跳（每 15 s，连续 2 次无回复则断开） |
| App → 设备 | `70 02` | TRANSFER：图片或固件开始传输 |
| 设备 → App | `B0 <state>` | 状态确认，state 与请求一致 |

- App 在连接后发送 HOLD；ACK 失败重试一次，仍失败则进入兼容模式并保持连接；固件版本 < 0x22 时直接兼容模式。
- 空闲阈值沿用设置页的「空闲断开(秒)」，默认 120 s；退出 App 时发送 IDLE。
- 设备无回复（心跳/状态 ACK 超时）时 App 主动断开。
- 固件收到 IDLE 会清除传输上下文；收到 TRANSFER 进入传输态。

## 固件容量与升级限制

- 该 bootloader 的 DFU 区为 `0x19000..0x27000`（约 57,344 字节），镜像必须小于此值；超过会在 init 包 EXECUTE 阶段返回 `INSUFFICIENT_RESOURCES`。
- 为适配容量：配置存储改用 DFU 预留页（`0x27000`，带魔数/字段校验），移除 FDS/strftime/tzset；当前 0x26 镜像 52,952 字节；0x26 修复了重复链接脚本导致的启动/BSS 布局错误。
- 相册模式采用 60 秒周期 / 约 2 秒广播窗口（0x24 起，0x25 将窗口内间隔缩短到 200 ms）；其他模式持续广播。本设备没有可用的唤醒源，0x92 深睡已禁用。
- 恢复：设备保持广播时，用官方 V2.0.1 包（56 KB）可随时刷回；无需拆机/SWD。

## 协议一致性

- Service `62750001-d828-918d-fb46-b6c11c675aec`
- 数据特征 `62750002-…`，版本特征 `62750003-…`
- CRC16-CCITT：poly 0x8408，init 0xFFFF，仅 payload
- 与网页 JS 的抖动/打包实现做过逐字节对拍：18/18 组一致（`test/verify.js`）

## 构建

前置：OpenHarmony SDK API 12、JDK 17、Node 24。

```bat
build.bat
```

或：

```bash
export JAVA_HOME='<JDK 17 安装路径>'
export PATH="$JAVA_HOME/bin:$PATH"
export DEVECO_SDK_HOME='<OpenHarmony SDK 路径>'
node node_modules/@ohos/hvigor/bin/hvigor.js assembleHap --mode module -p product=default -p buildMode=debug --no-daemon
```

产物：`entry/build/default/outputs/default/entry-default-unsigned.hap`

## 签名与安装

仓库不包含任何私钥、证书或 profile。

- 开发调试：在 DevEco Studio 中配置自动签名后安装。
- 命令行：使用你自己的证书/profile 调用 `hap-sign-tool.jar`；或使用 OpenHarmony SDK 自带的公共测试证书（仅适用于 OpenHarmony 设备/模拟器）。
- HarmonyOS NEXT 商用设备不信任公共测试证书；可配合「小白安装助手」导入 HAP，并使用你的华为开发者证书/profile 完成签名安装。详细步骤见 [docs/INSTALL.md](docs/INSTALL.md)。

```bash
hdc install <signed>.hap
```

## 下一阶段

- 六色模式蓝牙发送（网页版同样不支持，仅导出数组）
- 老款时钟 mode=3（固件源码未实现，待确认）
- 本地自动保存画布（网页版用 localStorage；鸿蒙可迁移到 preferences + 沙箱文件）