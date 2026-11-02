PROJECT_NAME := epd_nrf52
TARGETS := nrf52811_xxaa
OUTPUT_DIRECTORY := _build
SDK_ROOT := SDK/17.1.0_ddde560
PROJ_DIR := .

$(OUTPUT_DIRECTORY)/nrf52811_xxaa.out: LINKER_SCRIPT := $(PROJ_DIR)/SDK/17.1.0_ddde560/gcc_nrf52.ld

GNU_INSTALL_ROOT := C:/armgcc/xpack-arm-none-eabi-gcc-14.2.1-1.1/bin/
GNU_VERSION := 14.2.1
GNU_PREFIX := arm-none-eabi

SRC_FILES += \
  $(PROJ_DIR)/main.c \
  $(PROJ_DIR)/EPD/EPD_config.c \
  $(PROJ_DIR)/EPD/EPD_driver.c \
  $(PROJ_DIR)/EPD/EPD_service.c \
  $(PROJ_DIR)/EPD/UC81xx.c \
  $(PROJ_DIR)/EPD/SSD16xx.c \
  $(PROJ_DIR)/GUI/GUI.c \
  $(PROJ_DIR)/GUI/Lunar.c \
  $(PROJ_DIR)/GUI/fonts.c \
  $(PROJ_DIR)/GUI/u8g2_font.c \
  $(PROJ_DIR)/GUI/Adafruit_GFX.c \
  $(SDK_ROOT)/components/ble/common/ble_advdata.c \
  $(SDK_ROOT)/components/ble/ble_advertising/ble_advertising.c \
  $(SDK_ROOT)/components/ble/common/ble_conn_params.c \
  $(SDK_ROOT)/components/ble/common/ble_srv_common.c \
  $(SDK_ROOT)/components/ble/nrf_ble_gatt/nrf_ble_gatt.c \
  $(SDK_ROOT)/components/ble/ble_services/ble_dfu/ble_dfu.c \
  $(SDK_ROOT)/components/ble/ble_services/ble_dfu/ble_dfu_unbonded.c \
  $(SDK_ROOT)/integration/nrfx/legacy/nrf_drv_clock.c \
  $(SDK_ROOT)/integration/nrfx/legacy/nrf_drv_spi.c \
  $(SDK_ROOT)/modules/nrfx/soc/nrfx_atomic.c \
  $(SDK_ROOT)/modules/nrfx/drivers/src/nrfx_clock.c \
  $(SDK_ROOT)/modules/nrfx/drivers/src/nrfx_gpiote.c \
  $(SDK_ROOT)/modules/nrfx/drivers/src/prs/nrfx_prs.c \
  $(SDK_ROOT)/modules/nrfx/drivers/src/nrfx_spi.c \
  $(SDK_ROOT)/modules/nrfx/drivers/src/nrfx_spim.c \
  $(SDK_ROOT)/modules/nrfx/drivers/src/nrfx_wdt.c \
  $(SDK_ROOT)/components/libraries/util/app_error.c \
  $(SDK_ROOT)/components/libraries/util/app_error_handler_gcc.c \
  $(SDK_ROOT)/components/libraries/util/app_error_weak.c \
  $(SDK_ROOT)/components/libraries/scheduler/app_scheduler.c \
  $(SDK_ROOT)/components/libraries/timer/app_timer2.c \
  $(SDK_ROOT)/components/libraries/util/app_util_platform.c \
  $(SDK_ROOT)/components/libraries/timer/drv_rtc.c \
  $(SDK_ROOT)/components/libraries/fds/fds.c \
  $(SDK_ROOT)/components/libraries/util/nrf_assert.c \
  $(SDK_ROOT)/components/libraries/atomic_fifo/nrf_atfifo.c \
  $(SDK_ROOT)/components/libraries/atomic_flags/nrf_atflags.c \
  $(SDK_ROOT)/components/libraries/atomic/nrf_atomic.c \
  $(SDK_ROOT)/components/libraries/balloc/nrf_balloc.c \
  $(SDK_ROOT)/components/libraries/bootloader/dfu/nrf_dfu_svci.c \
  $(SDK_ROOT)/external/fprintf/nrf_fprintf.c \
  $(SDK_ROOT)/external/fprintf/nrf_fprintf_format.c \
  $(SDK_ROOT)/components/libraries/fstorage/nrf_fstorage.c \
  $(SDK_ROOT)/components/libraries/fstorage/nrf_fstorage_sd.c \
  $(SDK_ROOT)/components/libraries/memobj/nrf_memobj.c \
  $(SDK_ROOT)/components/libraries/pwr_mgmt/nrf_pwr_mgmt.c \
  $(SDK_ROOT)/components/libraries/ringbuf/nrf_ringbuf.c \
  $(SDK_ROOT)/components/libraries/experimental_section_vars/nrf_section_iter.c \
  $(SDK_ROOT)/components/libraries/sortlist/nrf_sortlist.c \
  $(SDK_ROOT)/components/libraries/strerror/nrf_strerror.c \
  $(SDK_ROOT)/components/libraries/log/src/nrf_log_backend_rtt.c \
  $(SDK_ROOT)/components/libraries/log/src/nrf_log_backend_serial.c \
  $(SDK_ROOT)/components/libraries/log/src/nrf_log_default_backends.c \
  $(SDK_ROOT)/components/libraries/log/src/nrf_log_frontend.c \
  $(SDK_ROOT)/components/libraries/log/src/nrf_log_str_formatter.c \
  $(SDK_ROOT)/external/segger_rtt/SEGGER_RTT.c \
  $(SDK_ROOT)/external/segger_rtt/SEGGER_RTT_Syscalls_GCC.c \
  $(SDK_ROOT)/external/segger_rtt/SEGGER_RTT_printf.c \
  $(SDK_ROOT)/components/softdevice/common/nrf_sdh.c \
  $(SDK_ROOT)/components/softdevice/common/nrf_sdh_ble.c \
  $(SDK_ROOT)/components/softdevice/common/nrf_sdh_soc.c \
  $(PROJ_DIR)/main.c \
  $(PROJ_DIR)/EPD/EPD_config.c \
  $(PROJ_DIR)/EPD/EPD_driver.c \
  $(PROJ_DIR)/EPD/EPD_service.c \
  $(PROJ_DIR)/EPD/UC81xx.c \
  $(PROJ_DIR)/EPD/SSD16xx.c \
  $(PROJ_DIR)/GUI/GUI.c \
  $(PROJ_DIR)/GUI/Lunar.c \
  $(PROJ_DIR)/GUI/fonts.c \
  $(PROJ_DIR)/GUI/u8g2_font.c \
  $(PROJ_DIR)/GUI/Adafruit_GFX.c \
  $(SDK_ROOT)/components/ble/common/ble_advdata.c \
  $(SDK_ROOT)/components/ble/ble_advertising/ble_advertising.c \
  $(SDK_ROOT)/components/ble/common/ble_conn_params.c \
  $(SDK_ROOT)/components/ble/common/ble_srv_common.c \
  $(SDK_ROOT)/components/ble/nrf_ble_gatt/nrf_ble_gatt.c \
  $(SDK_ROOT)/components/ble/ble_services/ble_dfu/ble_dfu.c \
  $(SDK_ROOT)/components/ble/ble_services/ble_dfu/ble_dfu_unbonded.c \
  $(SDK_ROOT)/integration/nrfx/legacy/nrf_drv_clock.c \
  $(SDK_ROOT)/integration/nrfx/legacy/nrf_drv_spi.c \
  $(SDK_ROOT)/modules/nrfx/soc/nrfx_atomic.c \
  $(SDK_ROOT)/modules/nrfx/drivers/src/nrfx_clock.c \
  $(SDK_ROOT)/modules/nrfx/drivers/src/nrfx_gpiote.c \
  $(SDK_ROOT)/modules/nrfx/drivers/src/prs/nrfx_prs.c \
  $(SDK_ROOT)/modules/nrfx/drivers/src/nrfx_spi.c \
  $(SDK_ROOT)/modules/nrfx/drivers/src/nrfx_spim.c \
  $(SDK_ROOT)/modules/nrfx/drivers/src/nrfx_wdt.c \
  $(SDK_ROOT)/components/libraries/util/app_error.c \
  $(SDK_ROOT)/components/libraries/util/app_error_handler_gcc.c \
  $(SDK_ROOT)/components/libraries/util/app_error_weak.c \
  $(SDK_ROOT)/components/libraries/scheduler/app_scheduler.c \
  $(SDK_ROOT)/components/libraries/timer/app_timer2.c \
  $(SDK_ROOT)/components/libraries/util/app_util_platform.c \
  $(SDK_ROOT)/components/libraries/timer/drv_rtc.c \
  $(SDK_ROOT)/components/libraries/fds/fds.c \
  $(SDK_ROOT)/components/libraries/util/nrf_assert.c \
  $(SDK_ROOT)/components/libraries/atomic_fifo/nrf_atfifo.c \
  $(SDK_ROOT)/components/libraries/atomic_flags/nrf_atflags.c \
  $(SDK_ROOT)/components/libraries/atomic/nrf_atomic.c \
  $(SDK_ROOT)/components/libraries/balloc/nrf_balloc.c \
  $(SDK_ROOT)/components/libraries/bootloader/dfu/nrf_dfu_svci.c \
  $(SDK_ROOT)/external/fprintf/nrf_fprintf.c \
  $(SDK_ROOT)/external/fprintf/nrf_fprintf_format.c \
  $(SDK_ROOT)/components/libraries/fstorage/nrf_fstorage.c \
  $(SDK_ROOT)/components/libraries/fstorage/nrf_fstorage_sd.c \
  $(SDK_ROOT)/components/libraries/memobj/nrf_memobj.c \
  $(SDK_ROOT)/components/libraries/pwr_mgmt/nrf_pwr_mgmt.c \
  $(SDK_ROOT)/components/libraries/ringbuf/nrf_ringbuf.c \
  $(SDK_ROOT)/components/libraries/experimental_section_vars/nrf_section_iter.c \
  $(SDK_ROOT)/components/libraries/sortlist/nrf_sortlist.c \
  $(SDK_ROOT)/components/libraries/strerror/nrf_strerror.c \
  $(SDK_ROOT)/components/libraries/log/src/nrf_log_backend_rtt.c \
  $(SDK_ROOT)/components/libraries/log/src/nrf_log_backend_serial.c \
  $(SDK_ROOT)/components/libraries/log/src/nrf_log_default_backends.c \
  $(SDK_ROOT)/components/libraries/log/src/nrf_log_frontend.c \
  $(SDK_ROOT)/components/libraries/log/src/nrf_log_str_formatter.c \
  $(SDK_ROOT)/external/segger_rtt/SEGGER_RTT.c \
  $(SDK_ROOT)/external/segger_rtt/SEGGER_RTT_Syscalls_GCC.c \
  $(SDK_ROOT)/external/segger_rtt/SEGGER_RTT_printf.c \
  $(SDK_ROOT)/components/softdevice/common/nrf_sdh.c \
  $(SDK_ROOT)/components/softdevice/common/nrf_sdh_ble.c \
  $(SDK_ROOT)/components/softdevice/common/nrf_sdh_soc.c \
  $(SDK_ROOT)/modules/nrfx/mdk/gcc_startup_nrf52811.S \
  $(SDK_ROOT)/modules/nrfx/mdk/system_nrf52811.c

INC_FOLDERS += \
  $(PROJ_DIR)/ \
  $(PROJ_DIR)/EPD \
  $(PROJ_DIR)/GUI \
  $(PROJ_DIR)/SDK/17.1.0_ddde560 \
  $(SDK_ROOT)/components/ble/common \
  $(SDK_ROOT)/components/ble/ble_advertising \
  $(SDK_ROOT)/components/ble/nrf_ble_gatt \
  $(SDK_ROOT)/components/ble/ble_services/ble_dfu \
  $(SDK_ROOT)/components/libraries/atomic \
  $(SDK_ROOT)/components/libraries/atomic_fifo \
  $(SDK_ROOT)/components/libraries/atomic_flags \
  $(SDK_ROOT)/components/libraries/balloc \
  $(SDK_ROOT)/components/libraries/bootloader \
  $(SDK_ROOT)/components/libraries/bootloader/ble_dfu \
  $(SDK_ROOT)/components/libraries/bootloader/dfu \
  $(SDK_ROOT)/components/libraries/delay \
  $(SDK_ROOT)/components/libraries/fstorage \
  $(SDK_ROOT)/components/libraries/fds \
  $(SDK_ROOT)/components/libraries/experimental_section_vars \
  $(SDK_ROOT)/components/libraries/log \
  $(SDK_ROOT)/components/libraries/log/src \
  $(SDK_ROOT)/components/libraries/memobj \
  $(SDK_ROOT)/components/libraries/mutex \
  $(SDK_ROOT)/components/libraries/pwr_mgmt \
  $(SDK_ROOT)/components/libraries/ringbuf \
  $(SDK_ROOT)/components/libraries/sortlist \
  $(SDK_ROOT)/components/libraries/scheduler \
  $(SDK_ROOT)/components/libraries/strerror \
  $(SDK_ROOT)/components/libraries/svc \
  $(SDK_ROOT)/components/libraries/timer \
  $(SDK_ROOT)/components/libraries/util \
  $(SDK_ROOT)/components/softdevice/common \
  $(SDK_ROOT)/components/softdevice/s112/headers \
  $(SDK_ROOT)/components/softdevice/s112/headers/nrf52 \
  $(SDK_ROOT)/components/toolchain/cmsis/include \
  $(SDK_ROOT)/external/fprintf \
  $(SDK_ROOT)/external/segger_rtt \
  $(SDK_ROOT)/integration/nrfx \
  $(SDK_ROOT)/integration/nrfx/legacy \
  $(SDK_ROOT)/modules/nrfx \
  $(SDK_ROOT)/modules/nrfx/mdk \
  $(SDK_ROOT)/modules/nrfx/drivers/include \
  $(SDK_ROOT)/modules/nrfx/hal

CFLAGS += \
-DAPP_TIMER_V2 \
-DAPP_TIMER_V2_RTC1_ENABLED \
-DCONFIG_GPIO_AS_PINRESET \
-DFLOAT_ABI_SOFT \
-DNRF52811_XXAA \
-DNRFX_COREDEP_DELAY_US_LOOP_CYCLES=3 \
-DNRF_DFU_SVCI_ENABLED \
-DNRF_DFU_TRANSPORT_BLE=1 \
-DNRF_SD_BLE_API_VERSION=7 \
-DS112 \
-DSOFTDEVICE_PRESENT \
-D__HEAP_SIZE=8192 \
-D__STACK_SIZE=2048

CFLAGS += -Os -g3 -mcpu=cortex-m4 -mthumb -mfloat-abi=soft -ffunction-sections -fdata-sections
ASMFLAGS += -mcpu=cortex-m4 -mthumb -D__HEAP_SIZE=8192 -D__STACK_SIZE=2048
LDFLAGS += -mcpu=cortex-m4 -mthumb -L$(PROJ_DIR)/SDK/17.1.0_ddde560/modules/nrfx/mdk -T$(PROJ_DIR)/SDK/17.1.0_ddde560/gcc_nrf52.ld --specs=nano.specs -lc -lnosys -Wl,--gc-sections
CFLAGS += -Wno-unused-function -Wno-unused-variable -Wno-unused-but-set-variable -Wno-missing-field-initializers

TEMPLATE_PATH := $(SDK_ROOT)/components/toolchain/gcc
include $(SDK_ROOT)/components/toolchain/gcc/Makefile.common

TEMPLATE_PATH := $(SDK_ROOT)/components/toolchain/gcc

$(foreach target,$(TARGETS),$(eval $(call define_target,$(target))))
