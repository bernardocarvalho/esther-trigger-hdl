// ***************************************************************************
// ***************************************************************************
// Copyright 2014 - 2017 (c) Analog Devices, Inc. All rights reserved.
//
// In this HDL repository, there are many different and unique modules, consisting
// of various HDL (Verilog or VHDL) components. The individual modules are
// developed independently, and may be accompanied by separate and unique license
// terms.
//
// The user should read each of these license terms, and understand the
// freedoms and responsibilities that he or she has by using this source/core.
//
// This core is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE.
//
// Redistribution and use of source or resulting binaries, with or without modification
// of this file, are permitted under one of the following two license terms:
//
//   1. The GNU General Public License version 2 as published by the
//      Free Software Foundation, which can be found in the top level directory
//      of this repository (LICENSE_GPL2), and also online at:
//      <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
//
// OR
//
//   2. An ADI specific BSD license, which can be found in the top level directory
//      of this repository (LICENSE_ADIBSD), and also on-line at:
//      https://github.com/analogdevicesinc/hdl/blob/master/LICENSE_ADIBSD
//      This will allow to generate bit files and not release the source code,
//      as long as it attaches to an ADI device.
//
// ***************************************************************************
// ***************************************************************************

`timescale 1ns/100ps

module system_top (

  input                   sys_rst,
  input                   sys_clk_p,
  input                   sys_clk_n,

  input                   uart_sin,
  output                  uart_sout,

  output      [ 2:0]      ddr3_1_n,
  output      [ 1:0]      ddr3_1_p,
  output                  ddr3_reset_n,
  output      [13:0]      ddr3_addr,
  output      [ 2:0]      ddr3_ba,
  output                  ddr3_cas_n,
  output                  ddr3_ras_n,
  output                  ddr3_we_n,
  output      [ 0:0]      ddr3_ck_n,
  output      [ 0:0]      ddr3_ck_p,
  output      [ 0:0]      ddr3_cke,
  output      [ 0:0]      ddr3_cs_n,
  output      [ 7:0]      ddr3_dm,
  inout       [63:0]      ddr3_dq,
  inout       [ 7:0]      ddr3_dqs_n,
  inout       [ 7:0]      ddr3_dqs_p,
  output      [ 0:0]      ddr3_odt,

  output                  mdio_mdc,
  inout                   mdio_mdio,
  output                  mii_rst_n,
  input                   mii_col,
  input                   mii_crs,
  input                   mii_rx_clk,
  input                   mii_rx_er,
  input                   mii_rx_dv,
  input       [ 3:0]      mii_rxd,
  input                   mii_tx_clk,
  output                  mii_tx_en,
  output      [ 3:0]      mii_txd,

  output      [26:1]      linear_flash_addr,
  output                  linear_flash_adv_ldn,
  output                  linear_flash_ce_n,
  inout       [15:0]      linear_flash_dq_io,
  output                  linear_flash_oen,
  output                  linear_flash_wen,

  output                  fan_pwm,

  inout       [ 6:0]      gpio_lcd,
  inout       [16:0]      gpio_bd,

  output                  iic_rstn,
  inout                   iic_scl,
  inout                   iic_sda,

  input                   rx_ref_clk_p,
  input                   rx_ref_clk_n,
  output                  rx_sysref,
  output                  rx_sync,
  input       [ 3:0]      rx_data_p,
  input       [ 3:0]      rx_data_n,

  output                  spi_csn_0,
  output                  spi_clk,
  inout                   spi_sdio,
  
  //User SMA Clock
  output          user_sma_clk_p, // SMA J11
  output          user_sma_clk_n, // SMA J12
  //User SMA Gpio
  output          user_sma_gpio_p, //Y23 USER_SMA_GPIO_P LVCMOS25 J13.1
  output          user_sma_gpio_n,  //Y24 USER_SMA_GPIO_N LVCMOS25 J14.1 bellow J11
// PCIE
  output  [3:0]    pci_exp_txp,
  output  [3:0]    pci_exp_txn,
  input   [3:0]    pci_exp_rxp,
  input   [3:0]    pci_exp_rxn,

  input         pci_sys_clk_p,
  input         pci_sys_clk_n,
  input         pci_sys_rst_n
  
  );
 
 localparam N_ADC_CHANNELS  = 4;

  // internal signals

  wire    [63:0]  gpio_i;
  wire    [63:0]  gpio_o;
  wire    [63:0]  gpio_t;
  wire    [ 7:0]  spi_csn;
  wire            spi_mosi;
  wire            spi_miso;
  wire            rx_ref_clk;
  wire            rx_clk;

  wire    [N_ADC_CHANNELS-1:0] adc_enable;
  wire    [N_ADC_CHANNELS-1:0] adc_valid;
  wire    [31:0] adc_data[0:N_ADC_CHANNELS-1]; // array of  32-bit registers;

  //wire    [13:0]      gpio_trigg_lvl = gpio_o[31:18]; // 14 bit GPIO lines 18 -31

//assign gpio_o
    //assign           user_sma_gpio_n = rx_clk; // J14
    //assign           user_sma_clk_n = adc_valid[0]; //  adc_enable[0] &  user_sma_clk_n, // SMA J12
// SMA J11
    assign user_sma_clk_p = gpio_o[36]; // J11 
     
  assign ddr3_1_p = 2'b11;
  assign ddr3_1_n = 3'b000;
  assign fan_pwm = 1'b1;
  assign iic_rstn = 1'b1;
  assign spi_csn_0 = spi_csn[0];

  wire [15:0] pulse_delay_i;
  // instantiations
  trigger_gen i_trigger_gen (
    .clk (rx_clk), // 125MHz

    .adc_data_a (adc_data[0]),
    .adc_enable_a (adc_enable[0]),
    .adc_valid_a (adc_valid[0]),

    .adc_data_b (adc_data[1]),
    .adc_enable_b (adc_enable[1]),
    .adc_valid_b (adc_valid[1]),
    
    .adc_data_c (adc_data[2]),
    .adc_enable_c (adc_enable[2]),
    .adc_valid_c (adc_valid[2]),
    
    .adc_data_d (adc_data[3]),
    .adc_enable_d (adc_enable[3]),
    .adc_valid_d (adc_valid[3]),

    // Latency 480 ns ?
    //Trigger levels are positive

    .trig_enable(gpio_o[36]), // bit 4 second gpio
    .trig_level_addr(gpio_o[12:11]),
    .trig_level_data(gpio_o[55:40]),
    .trig_level_wrt(gpio_o[13]),
    .pulse_delay(pulse_delay_i), // O 

    .trigger0 (user_sma_clk_n), // user_sma_clk_p
    .trigger1 (user_sma_gpio_n) //J14
    );

  IBUFDS_GTE2 i_ibufds_rx_ref_clk (
    .CEB (1'd0),
    .I (rx_ref_clk_p),
    .IB (rx_ref_clk_n),
    .O (rx_ref_clk),
    .ODIV2 ());

  ad_iobuf #(.DATA_WIDTH(17)) i_iobuf (
    .dio_t (gpio_t[16:0]),
    .dio_i (gpio_o[16:0]),
    .dio_o (gpio_i[16:0]),
    .dio_p (gpio_bd));

//  assign gpio_i[63:32] = gpio_o[63:32];

  assign gpio_i[63:56] = gpio_o[63:56];
  assign gpio_i[55:40] = pulse_delay_i; // Lines 55:40 are reading pulses 1->2 delay
  assign gpio_i[39:32] = gpio_o[39:32]; 
  assign gpio_i[31:17] = gpio_o[31:17];

  fmcjesdadc1_spi i_fmcjesdadc1_spi (
    .spi_csn (spi_csn[0]),
    .spi_clk (spi_clk),
    .spi_mosi (spi_mosi),
    .spi_miso (spi_miso),
    .spi_sdio (spi_sdio));

  ad_sysref_gen #(.SYSREF_PERIOD(64)) i_sysref (
    .core_clk (rx_clk),
    .sysref_en (gpio_o[32]),
    .sysref_out (rx_sysref));

  // instantiations

  system_wrapper i_system_wrapper (
      .adc_data_a (adc_data[0]),
      .adc_enable_a (adc_enable[0]),
      .adc_valid_a (adc_valid[0]),
      .adc_data_b (adc_data[1]),
      .adc_enable_b (adc_enable[1]),
      .adc_valid_b (adc_valid[1]),
      .adc_data_c (adc_data[2]),
      .adc_enable_c (adc_enable[2]),
      .adc_valid_c (adc_valid[2]),
      .adc_data_d (adc_data[3]),
      .adc_enable_d (adc_enable[3]),
      .adc_valid_d (adc_valid[3]),
    .ddr3_addr (ddr3_addr),
    .ddr3_ba (ddr3_ba),
    .ddr3_cas_n (ddr3_cas_n),
    .ddr3_ck_n (ddr3_ck_n),
    .ddr3_ck_p (ddr3_ck_p),
    .ddr3_cke (ddr3_cke),
    .ddr3_cs_n (ddr3_cs_n),
    .ddr3_dm (ddr3_dm),
    .ddr3_dq (ddr3_dq),
    .ddr3_dqs_n (ddr3_dqs_n),
    .ddr3_dqs_p (ddr3_dqs_p),
    .ddr3_odt (ddr3_odt),
    .ddr3_ras_n (ddr3_ras_n),
    .ddr3_reset_n (ddr3_reset_n),
    .ddr3_we_n (ddr3_we_n),
    .gpio0_i (gpio_i[31:0]),
    .gpio0_o (gpio_o[31:0]),
    .gpio0_t (gpio_t[31:0]),
    .gpio1_i (gpio_i[63:32]),
    .gpio1_o (gpio_o[63:32]),
    .gpio1_t (gpio_t[63:32]),
    .gpio_lcd_tri_io (gpio_lcd),
    .iic_main_scl_io (iic_scl),
    .iic_main_sda_io (iic_sda),
    .mdio_mdc (mdio_mdc),
    .mdio_mdio_io (mdio_mdio),
    .mii_col (mii_col),
    .mii_crs (mii_crs),
    .mii_rst_n (mii_rst_n),
    .mii_rx_clk (mii_rx_clk),
    .mii_rx_dv (mii_rx_dv),
    .mii_rx_er (mii_rx_er),
    .mii_rxd (mii_rxd),
    .mii_tx_clk (mii_tx_clk),
    .mii_tx_en (mii_tx_en),
    .mii_txd (mii_txd),
    .linear_flash_addr (linear_flash_addr),
    .linear_flash_adv_ldn (linear_flash_adv_ldn),
    .linear_flash_ce_n (linear_flash_ce_n),
    .linear_flash_dq_io (linear_flash_dq_io),
    .linear_flash_oen (linear_flash_oen),
    .linear_flash_wen (linear_flash_wen),
    .sys_clk_n (sys_clk_n),
    .sys_clk_p (sys_clk_p),
    .sys_rst (sys_rst),
    .uart_sin (uart_sin),
    .uart_sout (uart_sout),
    .rx_data_0_n (rx_data_n[0]),
    .rx_data_0_p (rx_data_p[0]),
    .rx_data_1_n (rx_data_n[1]),
    .rx_data_1_p (rx_data_p[1]),
    .rx_data_2_n (rx_data_n[2]),
    .rx_data_2_p (rx_data_p[2]),
    .rx_data_3_n (rx_data_n[3]),
    .rx_data_3_p (rx_data_p[3]),
    .rx_ref_clk_0 (rx_ref_clk),
    .rx_sync_0 (rx_sync),
    .rx_sysref_0 (rx_sysref),
    .rx_core_clk (rx_clk),
    .spi_clk_i (spi_clk),
    .spi_clk_o (spi_clk),
    .spi_csn_i (spi_csn),
    .spi_csn_o (spi_csn),
    .spi_sdi_i (spi_miso),
    .spi_sdo_i (spi_mosi),
    .spi_sdo_o (spi_mosi));

    wire [63:0] adc_all_data_i;

    assign adc_all_data_i[31:0]     = adc_data[0];
    assign adc_all_data_i[63:32]    = adc_data[1];

    wire  adc_all_data_en = adc_enable[0];

//PCIE

xilinx_pcie_2_1_ep_7x xilinx_pcie_i(
 .pci_exp_txp(pci_exp_txp),
 .pci_exp_txn(pci_exp_txn),
 .pci_exp_rxp(pci_exp_rxp),
 .pci_exp_rxn(pci_exp_rxn),

 .sys_clk_p(pci_sys_clk_p),
 .sys_clk_n(pci_sys_clk_n),
 .sys_rst_n(pci_sys_rst_n),
 
       // ADC Interface
   .adc_data(adc_all_data_i),
   .adc_data_en(adc_all_data_en),
   
   .adc_data_clk(rx_clk)  // 125MHz

);

endmodule

// ***************************************************************************
// ***************************************************************************
