#include "EPD_config.h"

#include <string.h>

#include "nordic_common.h"
#include "nrf_soc.h"
#include "nrf_sdh_soc.h"
#include "nrf_log.h"

// The bootloader reserves 8 KB at the top of the DFU region for application
// data (NRF_DFU_APP_DATA_AREA_SIZE). Use its first page for the config so the
// app never collides with the bootloader and does not need the FDS stack.
#define CONFIG_PAGE_ADDR 0x27000UL
#define CONFIG_PAGE_SIZE 4096UL

#define CONFIG_MAGIC 0x45504443UL  // "EPDC"

typedef struct {
    uint32_t magic;
    epd_config_t cfg;
} config_record_t;

#define CONFIG_WORDS ((sizeof(config_record_t) + 3) / 4)

static config_record_t m_rec __attribute__((aligned(4)));
static config_record_t m_inflight __attribute__((aligned(4)));
static volatile uint8_t m_state = 0;  // 0 idle, 1 erasing, 2 writing
static volatile bool m_pending = false;

static void config_write_start(void) {
    if (m_state != 0) {
        m_pending = true;
        return;
    }
    // SoftDevice owns this immutable snapshot until write completion.
    m_inflight = m_rec;
    m_state = 1;
    ret_code_t err = sd_flash_page_erase(CONFIG_PAGE_ADDR / CONFIG_PAGE_SIZE);
    if (err != NRF_SUCCESS) {
        NRF_LOG_ERROR("config erase failed code=%d\n", err);
        m_state = 0;
    }
}

static void config_soc_observer(uint32_t sys_evt, void* p_context) {
    UNUSED_PARAMETER(p_context);
    if (sys_evt == NRF_EVT_FLASH_OPERATION_SUCCESS) {
        if (m_state == 1) {
            m_state = 2;
            ret_code_t err = sd_flash_write((uint32_t*)CONFIG_PAGE_ADDR, (uint32_t*)&m_inflight, CONFIG_WORDS);
            if (err != NRF_SUCCESS) {
                NRF_LOG_ERROR("config write failed code=%d\n", err);
                m_state = 0;
            }
        } else if (m_state == 2) {
            m_state = 0;
            if (m_pending) {
                m_pending = false;
                config_write_start();
            }
        }
    } else if (sys_evt == NRF_EVT_FLASH_OPERATION_ERROR) {
        NRF_LOG_ERROR("config flash op error\n");
        m_state = 0;
        if (m_pending) {
            m_pending = false;
            config_write_start();
        }
    }
}

NRF_SDH_SOC_OBSERVER(m_config_soc_obs, 1, config_soc_observer, NULL);

static bool pin_valid(uint8_t pin) {
    return pin <= 31;
}

static bool pin_optional(uint8_t pin) {
    return pin == 0xFF || pin <= 31;
}

// Reject a stored config that cannot safely drive this panel. In particular,
// a 4.2" model (1..5) on a 7.5" panel makes the SSD16xx driver wait up to
// 30 s on the wrong BUSY polarity, blocking BLE event handling.
static bool config_valid(const epd_config_t* cfg) {
    if (!pin_valid(cfg->mosi_pin) || !pin_valid(cfg->sclk_pin) ||
        !pin_valid(cfg->cs_pin) || !pin_valid(cfg->dc_pin) ||
        !pin_valid(cfg->rst_pin) || !pin_valid(cfg->busy_pin) ||
        !pin_optional(cfg->bs_pin)) {
        return false;
    }
    if (!pin_optional(cfg->wakeup_pin) || !pin_optional(cfg->led_pin) ||
        !pin_optional(cfg->en_pin)) {
        return false;
    }
    if (cfg->model_id == 0 || cfg->model_id > 12) {
        return false;
    }
    // This firmware targets 7.5" panels; never accept a 4.2" model.
    if (cfg->model_id <= 5) {
        return false;
    }
    if (cfg->display_mode > 2 || cfg->week_start > 6) {
        return false;
    }
    return true;
}


void epd_config_init(epd_config_t* cfg) {
    UNUSED_PARAMETER(cfg);
}

void epd_config_read(epd_config_t* cfg) {
    const config_record_t* rec = (const config_record_t*)CONFIG_PAGE_ADDR;
    if (rec->magic != CONFIG_MAGIC) {
        memset(cfg, 0xFF, sizeof(epd_config_t));
        return;
    }
    memcpy(cfg, &rec->cfg, sizeof(epd_config_t));
    if (!config_valid(cfg)) {
        NRF_LOG_WARNING("stored config invalid, using defaults\n");
        memset(cfg, 0xFF, sizeof(epd_config_t));
    }
}

void epd_config_write(epd_config_t* cfg) {
    m_rec.magic = CONFIG_MAGIC;
    memcpy(&m_rec.cfg, cfg, sizeof(epd_config_t));
    if (m_state == 0) {
        config_write_start();
    } else {
        m_pending = true;
    }
}

void epd_config_clear(epd_config_t* cfg) {
    memset(cfg, 0xFF, sizeof(epd_config_t));
    m_rec.magic = CONFIG_MAGIC;
    memcpy(&m_rec.cfg, cfg, sizeof(epd_config_t));
    if (m_state == 0) {
        config_write_start();
    } else {
        m_pending = true;
    }
}

bool epd_config_empty(epd_config_t* cfg) {
    for (uint8_t i = 0; i < EPD_CONFIG_SIZE; i++) {
        if (((uint8_t*)cfg)[i] != 0xFF) return false;
    }
    return true;
}
