/**
 * ATCA V2 PCI ADC  device driver
 * Definitions for the Linux Device Driver
 *
 * Copyright 2016 - 2019 IPFN-Instituto Superior Tecnico, Portugal
 * Creation Date  2016-02-10
 *
 * Licensed under the EUPL, Version 1.2 only (the "Licence");
 * You may not use this work except in compliance with the Licence.
 * You may obtain a copy of the Licence, available in 23 official languages of
 * the European Union, at:
 * https://joinup.ec.europa.eu/community/eupl/og_page/eupl-text-11-12
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the Licence is distributed on an "AS IS" basis,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the Licence for the specific language governing permissions and
 * limitations under the Licence.
 *
 */
#ifndef _ATCA_V2_PCI_H_
#define _ATCA_V2_PCI_H_

#ifndef __KERNEL__
//#define u32 unsigned int
#include "atca-v2-pcie-ioctl.h"
#include <pthread.h>
#include <stdint.h>
#include <sys/time.h>
#include <time.h>
#endif

#define DMA_BUFFS 8 // Number of DMA ch0 buffs
#define PCK_N_SAMPLES 1024
#define ADC_CHANNELS 32

typedef struct _DATA_FLDS {
  int adc_data : 20; //, buf_num : 3, status : 3, data_byte : 8; // msb
  unsigned int chop_phase : 1, rsv0 : 3, data_byte : 8; // msb,
} DATA_FLDS;

typedef struct _HEAD_FOOT_FLDS {
  unsigned int buf_num : 3, dmaC : 1, rsv0 : 12, type : 16; // msb, chopp : 1
  unsigned int magic : 32;                                  // msb, chopp : 1
} HEAD_FOOT_FLDS;

typedef struct _SAMPLE {
  volatile DATA_FLDS channel[ADC_CHANNELS];
} SAMPLE;

typedef struct _HEAD_SAMPLE {
  volatile HEAD_FOOT_FLDS header;
  volatile uint64_t time_cnt;
  DATA_FLDS channel[ADC_CHANNELS - 4];
} HEAD_SAMPLE;

typedef struct _FOOT_SAMPLE {
  DATA_FLDS channel[ADC_CHANNELS - 4];
  volatile HEAD_FOOT_FLDS footer;
  volatile uint64_t time_cnt;
} FOOT_SAMPLE;

typedef struct _DMA_PCKT {
  // volatile HEAD_SAMPLE hsamp;
  SAMPLE samp[PCK_N_SAMPLES];
  // volatile FOOT_SAMPLE fsamp;
} DMA_PCKT;

/*512 data packet*/
typedef struct _DMACH1_PCKT {
  volatile HEAD_FOOT_FLDS header;
  volatile uint64_t head_time_cnt;
  volatile int32_t headdata[12];
  volatile SAMPLE adc_decim_data;
  volatile int32_t channel[64];
  volatile int32_t footdata[12];
  volatile HEAD_FOOT_FLDS footer;
  volatile uint64_t foot_time_cnt;
} DMACH1_PCKT;

struct atca_eo_config {
  int32_t offset[ADC_CHANNELS];
};

//#define DMA_MAX_BYTES 2048 // Difeine in FPGA

// TODO : to be used.
#ifdef __BIG_ENDIAN_BTFLD
#define BTFLD(a, b) b, a
#else
#define BTFLD(a, b) a, b
#endif

#ifndef VM_RESERVED
#define VMEM_FLAGS (VM_IO | VM_DONTEXPAND | VM_DONTDUMP)
#else
#define VMEM_FLAGS (VM_IO | VM_RESERVED)
#endif

#undef PDEBUG /* undef it, just in case */
#ifdef ATCA_DEBUG
#ifdef __KERNEL__
/* This one if debugging is on, and kernel space */
#define PDEBUG(fmt, args...) printk(KERN_DEBUG "atcav2: " fmt, ##args)
#else
/* This one for user space */
#define PDEBUG(fmt, args...) fprintf(stderr, fmt, ##args)
#endif
#else
#define PDEBUG(fmt, args...) /* not debugging: nothing */
#endif

#undef PDEBUGG
#define PDEBUGG(fmt, args...) /* nothing: it's a placeholder */

#endif /* _ATCA_V2_PCI_H_ */