# 低功耗 + 可按需连接：固件改造方案（无唤醒按键）

## 结论

设备没有可用的唤醒源（无按键；NFC/无线充脚无法确认），因此不能用 SYSTEM OFF。
要同时满足「几乎不耗电」和「手机随时能连」，唯一可行的是：

**低频广播窗口（advertising window）+ 相册模式停 1 Hz 定时器**

- 每 5 s 打开一次广播窗口 300 ms；
- 窗口内手机可发现并连接；窗口外关闭射频；
- 连接成功后停止窗口调度；断开后恢复；
- 相册模式不再每秒唤醒 CPU。

## 预期

| 状态 | 平均电流（估算） |
|---|---|
| 现状（连接/常开广告 + 1 Hz） | 0.27–0.55 mA（约 6 个月） |
| 低频窗口（5 s/300 ms）+ 停 1 Hz | 约 2–4 µA（远超电池 shelf life） |
| 窗口周期 10 s | 约 1–2 µA |

连接时延 ≤ 5 s；App 扫描 12 s 可覆盖 2 个窗口，不会连不上。

## 固件补丁（nRF5 SDK / main.c）

```c
#define ADV_WINDOW_MS   300
#define ADV_PERIOD_MS   5000

APP_TIMER_DEF(m_adv_window_timer_id);

static void adv_window_timeout_handler(void* p_context) {
    // ble_advertising 的 timeout 单位是 10 ms
    m_advertising.adv_modes_config.ble_adv_fast_timeout = ADV_WINDOW_MS / 10;
    advertising_start();
}

static void schedule_adv_window(void) {
    app_timer_start(m_adv_window_timer_id, APP_TIMER_TICKS(ADV_PERIOD_MS), NULL);
}
```

在 `timers_init()` 中创建一次性定时器：

```c
app_timer_create(&m_adv_window_timer_id, APP_TIMER_MODE_SINGLE_SHOT,
                 adv_window_timeout_handler);
```

`on_adv_evt()` 的 `BLE_ADV_EVT_IDLE` 分支改为：

```c
case BLE_ADV_EVT_IDLE:
    if (m_epd.config.display_mode == MODE_PICTURE) {
        schedule_adv_window();          // 相册模式：进入低频窗口
    } else if (m_epd.config.wakeup_pin != 0xFF) {
        setup_wakeup_pin(m_epd.config.wakeup_pin);
    } else {
        advertising_start();
    }
    break;
```

连接/断开：

```c
case BLE_GAP_EVT_CONNECTED:
    app_timer_stop(m_adv_window_timer_id);
    break;

case BLE_GAP_EVT_DISCONNECTED:
    // S112 原来什么都不做，导致停在空闲态
    schedule_adv_window();
    break;
```

相册模式停 1 Hz 时钟定时器（在 `epd_update_display_mode` 或 SET_TIME 处理里）：

```c
if (mode == MODE_PICTURE) {
    app_timer_stop(m_clock_timer_id);
} else {
    app_timer_start(m_clock_timer_id, CLOCK_TIMER_INTERVAL, NULL);
}
```

> 注意：相册模式下时间戳不再自增；下次连接由 App 发送 0x20 重新对时即可。

## App 侧

- 扫描时长 5 s → 12 s（覆盖 2 个窗口），已改；
- 发送完成后自动断开（已实现）；
- 不要开启 0x92 深睡（无唤醒源会失联）。

## 风险 / 待确认

- 窗口期间若正好有手机连接，BLE 会占用窗口；断开后恢复，无影响。
- 需要确认 `ble_advertising` 允许运行时修改 `ble_adv_fast_timeout`（SDK 支持）。
- 首次上电仍是 120 s 连续广播（便于首次连接），之后进入窗口模式。
- 实际电流需用 PPK2 实测（估算基于 1 s 广告约 20–40 µA 线性折算）。
