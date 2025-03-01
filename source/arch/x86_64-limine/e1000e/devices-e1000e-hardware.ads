with
     Interfaces.C;


package Devices.e1000e.Hardware
is

   -- e1000_mac_type
   --
   type e1000_mac_type is
     (e1000_82571,       e1000_82572,   e1000_82573,   e1000_82574,    e1000_82583,
      e1000_80003es2lan, e1000_ich8lan, e1000_ich9lan, e1000_ich10lan, e1000_pchlan,
      e1000_pch2lan,     e1000_pch_lpt, e1000_pch_spt, e1000_pch_cnp,  e1000_pch_tgp,
      e1000_pch_adp,     e1000_pch_mtp, e1000_pch_lnp, e1000_pch_ptp,  e1000_pch_nvp);

   type e1000_mac_type_array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_mac_type;

   -- e1000_media_type
   --
   type e1000_media_type is
     (e1000_media_type_unknown,
      e1000_media_type_copper,
      e1000_media_type_fiber,
      e1000_media_type_internal_serdes,
      e1000_num_media_types);

   type e1000_media_type_array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_media_type;

   -- e1000_nvm_type
   --
   type e1000_nvm_type is
     (e1000_nvm_unknown,
      e1000_nvm_none,
      e1000_nvm_eeprom_spi,
      e1000_nvm_flash_hw,
      e1000_nvm_flash_sw);

   type e1000_nvm_type_array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_nvm_type;

   -- e1000_nvm_override
   --
   type e1000_nvm_override is
     (e1000_nvm_override_none,
      e1000_nvm_override_spi_small,
      e1000_nvm_override_spi_large);

   type e1000_nvm_override_array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_nvm_override;

   -- e1000_phy_type
   --
   type e1000_phy_type is
     (e1000_phy_unknown, e1000_phy_none,    e1000_phy_m88,   e1000_phy_igp,
      e1000_phy_igp_2,   e1000_phy_gg82563, e1000_phy_igp_3, e1000_phy_ife,
      e1000_phy_bm,      e1000_phy_82578,   e1000_phy_82577, e1000_phy_82579,
      e1000_phy_i217);

   type e1000_phy_type_array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_phy_type;

   -- e1000_bus_width
   --
   type e1000_bus_width is
     (e1000_bus_width_unknown, e1000_bus_width_pcie_x1,
      e1000_bus_width_pcie_x2, e1000_bus_width_pcie_x4,
      e1000_bus_width_pcie_x8, e1000_bus_width_32,
      e1000_bus_width_64,      e1000_bus_width_reserved);

   for e1000_bus_width use
     (e1000_bus_width_unknown =>  0, e1000_bus_width_pcie_x1   => 1,
      e1000_bus_width_pcie_x2 =>  2, e1000_bus_width_pcie_x4   => 4,
      e1000_bus_width_pcie_x8 =>  8, e1000_bus_width_32        => 9,
      e1000_bus_width_64      => 10, e1000_bus_width_reserved => 11);

   type e1000_bus_width_array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_bus_width;

   -- e1000_1000t_rx_status
   --
   type e1000_1000t_rx_status is
     (e1000_1000t_rx_status_not_ok,
      e1000_1000t_rx_status_ok,
      e1000_1000t_rx_status_undefined);

   for e1000_1000t_rx_status use
     (e1000_1000t_rx_status_not_ok    =>   0,
      e1000_1000t_rx_status_ok        =>   1,
      e1000_1000t_rx_status_undefined => 255);

   type e1000_1000t_rx_status_array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_1000t_rx_status;

   -- e1000_rev_polarity
   --
   type e1000_rev_polarity is
     (e1000_rev_polarity_normal,
      e1000_rev_polarity_reversed,
      e1000_rev_polarity_undefined);

   for e1000_rev_polarity use
     (e1000_rev_polarity_normal    =>   0,
      e1000_rev_polarity_reversed  =>   1,
      e1000_rev_polarity_undefined => 255);

   type e1000_rev_polarity_array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_rev_polarity;

   -- e1000_fc_mode
   --
   type e1000_fc_mode is
     (e1000_fc_none,
      e1000_fc_rx_pause,
      e1000_fc_tx_pause,
      e1000_fc_full,
      e1000_fc_default);

   for e1000_fc_mode use
     (e1000_fc_none     =>   0,
      e1000_fc_rx_pause =>   1,
      e1000_fc_tx_pause =>   2,
      e1000_fc_full     =>   3,
      e1000_fc_default  => 255);

   type e1000_fc_mode_array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_fc_mode;

   -- e1000_ms_type
   --
   type e1000_ms_type is
     (e1000_ms_hw_default,
      e1000_ms_force_master,
      e1000_ms_force_slave,
      e1000_ms_auto);

   type e1000_ms_type_array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_ms_type;

   -- e1000_smart_speed
   --
   type e1000_smart_speed is
     (e1000_smart_speed_default,
      e1000_smart_speed_on,
      e1000_smart_speed_off);

   type e1000_smart_speed_array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_smart_speed;

   -- e1000_serdes_link_state
   --
   type e1000_serdes_link_state is
     (e1000_serdes_link_down,
      e1000_serdes_link_autoneg_progress,
      e1000_serdes_link_autoneg_complete,
      e1000_serdes_link_forced_up);

   type e1000_serdes_link_state_array is
     array
       (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_serdes_link_state;



   -- e1000_ulp_state ~ I218 PHY Ultra Low Power (ULP) states.
   --
   type e1000_ulp_state is
     (e1000_ulp_state_unknown,
      e1000_ulp_state_off,
      e1000_ulp_state_on);

   type e1000_ulp_state_array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_ulp_state;


   ETH_ALEN                            : constant := 6;
   IFNAMSIZ                            : constant := 16;
   VLAN_N_VID                          : constant := 4_096;
   sizeof_long                         : constant := 8;
   BITS_PER_BYTE                       : constant := 8;


   E1000_DEV_ID_82571EB_COPPER         : constant := 16#105e#;
   E1000_DEV_ID_82571EB_FIBER          : constant := 16#105f#;
   E1000_DEV_ID_82571EB_SERDES         : constant := 16#1060#;
   E1000_DEV_ID_82571EB_QUAD_COPPER    : constant := 16#10a4#;
   E1000_DEV_ID_82571PT_QUAD_COPPER    : constant := 16#10d5#;
   E1000_DEV_ID_82571EB_QUAD_FIBER     : constant := 16#10a5#;
   E1000_DEV_ID_82571EB_QUAD_COPPER_LP : constant := 16#10bc#;
   E1000_DEV_ID_82571EB_SERDES_DUAL    : constant := 16#10d9#;
   E1000_DEV_ID_82571EB_SERDES_QUAD    : constant := 16#10da#;
   E1000_DEV_ID_82572EI_COPPER         : constant := 16#107d#;
   E1000_DEV_ID_82572EI_FIBER          : constant := 16#107e#;
   E1000_DEV_ID_82572EI_SERDES         : constant := 16#107f#;
   E1000_DEV_ID_82572EI                : constant := 16#10b9#;
   E1000_DEV_ID_82573E                 : constant := 16#108b#;
   E1000_DEV_ID_82573E_IAMT            : constant := 16#108c#;
   E1000_DEV_ID_82573L                 : constant := 16#109a#;
   E1000_DEV_ID_82574L                 : constant := 16#10d3#;
   E1000_DEV_ID_82574LA                : constant := 16#10f6#;
   E1000_DEV_ID_82583V                 : constant := 16#150c#;
   E1000_DEV_ID_80003ES2LAN_COPPER_DPT : constant := 16#1096#;
   E1000_DEV_ID_80003ES2LAN_SERDES_DPT : constant := 16#1098#;
   E1000_DEV_ID_80003ES2LAN_COPPER_SPT : constant := 16#10ba#;
   E1000_DEV_ID_80003ES2LAN_SERDES_SPT : constant := 16#10bb#;
   E1000_DEV_ID_ICH8_82567V_3          : constant := 16#1501#;
   E1000_DEV_ID_ICH8_IGP_M_AMT         : constant := 16#1049#;
   E1000_DEV_ID_ICH8_IGP_AMT           : constant := 16#104a#;
   E1000_DEV_ID_ICH8_IGP_C             : constant := 16#104b#;
   E1000_DEV_ID_ICH8_IFE               : constant := 16#104c#;
   E1000_DEV_ID_ICH8_IFE_GT            : constant := 16#10c4#;
   E1000_DEV_ID_ICH8_IFE_G             : constant := 16#10c5#;
   E1000_DEV_ID_ICH8_IGP_M             : constant := 16#104d#;
   E1000_DEV_ID_ICH9_IGP_AMT           : constant := 16#10bd#;
   E1000_DEV_ID_ICH9_BM                : constant := 16#10e5#;
   E1000_DEV_ID_ICH9_IGP_M_AMT         : constant := 16#10f5#;
   E1000_DEV_ID_ICH9_IGP_M             : constant := 16#10bf#;
   E1000_DEV_ID_ICH9_IGP_M_V           : constant := 16#10cb#;
   E1000_DEV_ID_ICH9_IGP_C             : constant := 16#294c#;
   E1000_DEV_ID_ICH9_IFE               : constant := 16#10c0#;
   E1000_DEV_ID_ICH9_IFE_GT            : constant := 16#10c3#;
   E1000_DEV_ID_ICH9_IFE_G             : constant := 16#10c2#;
   E1000_DEV_ID_ICH10_R_BM_LM          : constant := 16#10cc#;
   E1000_DEV_ID_ICH10_R_BM_LF          : constant := 16#10cd#;
   E1000_DEV_ID_ICH10_R_BM_V           : constant := 16#10ce#;
   E1000_DEV_ID_ICH10_D_BM_LM          : constant := 16#10de#;
   E1000_DEV_ID_ICH10_D_BM_LF          : constant := 16#10df#;
   E1000_DEV_ID_ICH10_D_BM_V           : constant := 16#1525#;
   E1000_DEV_ID_PCH_M_HV_LM            : constant := 16#10ea#;
   E1000_DEV_ID_PCH_M_HV_LC            : constant := 16#10eb#;
   E1000_DEV_ID_PCH_D_HV_DM            : constant := 16#10ef#;
   E1000_DEV_ID_PCH_D_HV_DC            : constant := 16#10f0#;
   E1000_DEV_ID_PCH2_LV_LM             : constant := 16#1502#;
   E1000_DEV_ID_PCH2_LV_V              : constant := 16#1503#;
   E1000_DEV_ID_PCH_LPT_I217_LM        : constant := 16#153a#;
   E1000_DEV_ID_PCH_LPT_I217_V         : constant := 16#153b#;
   E1000_DEV_ID_PCH_LPTLP_I218_LM      : constant := 16#155a#;
   E1000_DEV_ID_PCH_LPTLP_I218_V       : constant := 16#1559#;
   E1000_DEV_ID_PCH_I218_LM2           : constant := 16#15a0#;
   E1000_DEV_ID_PCH_I218_V2            : constant := 16#15a1#;
   E1000_DEV_ID_PCH_I218_LM3           : constant := 16#15a2#;     -- Wildcat Point PCH.
   E1000_DEV_ID_PCH_I218_V3            : constant := 16#15a3#;     -- Wildcat Point PCH.
   E1000_DEV_ID_PCH_SPT_I219_LM        : constant := 16#156f#;     -- SPT PCH.
   E1000_DEV_ID_PCH_SPT_I219_V         : constant := 16#1570#;     -- SPT PCH.
   E1000_DEV_ID_PCH_SPT_I219_LM2       : constant := 16#15b7#;     -- SPT-H PCH.
   E1000_DEV_ID_PCH_SPT_I219_V2        : constant := 16#15b8#;     -- SPT-H PCH.
   E1000_DEV_ID_PCH_LBG_I219_LM3       : constant := 16#15b9#;     -- LBG PCH.
   E1000_DEV_ID_PCH_SPT_I219_LM4       : constant := 16#15d7#;
   E1000_DEV_ID_PCH_SPT_I219_V4        : constant := 16#15d8#;
   E1000_DEV_ID_PCH_SPT_I219_LM5       : constant := 16#15e3#;
   E1000_DEV_ID_PCH_SPT_I219_V5        : constant := 16#15d6#;
   E1000_DEV_ID_PCH_CNP_I219_LM6       : constant := 16#15bd#;
   E1000_DEV_ID_PCH_CNP_I219_V6        : constant := 16#15be#;
   E1000_DEV_ID_PCH_CNP_I219_LM7       : constant := 16#15bb#;
   E1000_DEV_ID_PCH_CNP_I219_V7        : constant := 16#15bc#;
   E1000_DEV_ID_PCH_ICP_I219_LM8       : constant := 16#15df#;
   E1000_DEV_ID_PCH_ICP_I219_V8        : constant := 16#15e0#;
   E1000_DEV_ID_PCH_ICP_I219_LM9       : constant := 16#15e1#;
   E1000_DEV_ID_PCH_ICP_I219_V9        : constant := 16#15e2#;
   E1000_DEV_ID_PCH_CMP_I219_LM10      : constant := 16#d4e#;
   E1000_DEV_ID_PCH_CMP_I219_V10       : constant := 16#d4f#;
   E1000_DEV_ID_PCH_CMP_I219_LM11      : constant := 16#d4c#;
   E1000_DEV_ID_PCH_CMP_I219_V11       : constant := 16#d4d#;
   E1000_DEV_ID_PCH_CMP_I219_LM12      : constant := 16#d53#;
   E1000_DEV_ID_PCH_CMP_I219_V12       : constant := 16#d55#;
   E1000_DEV_ID_PCH_TGP_I219_LM13      : constant := 16#15fb#;
   E1000_DEV_ID_PCH_TGP_I219_V13       : constant := 16#15fc#;
   E1000_DEV_ID_PCH_TGP_I219_LM14      : constant := 16#15f9#;
   E1000_DEV_ID_PCH_TGP_I219_V14       : constant := 16#15fa#;
   E1000_DEV_ID_PCH_TGP_I219_LM15      : constant := 16#15f4#;
   E1000_DEV_ID_PCH_TGP_I219_V15       : constant := 16#15f5#;
   E1000_DEV_ID_PCH_RPL_I219_LM23      : constant := 16#dc5#;
   E1000_DEV_ID_PCH_RPL_I219_V23       : constant := 16#dc6#;
   E1000_DEV_ID_PCH_ADP_I219_LM16      : constant := 16#1a1e#;
   E1000_DEV_ID_PCH_ADP_I219_V16       : constant := 16#1a1f#;
   E1000_DEV_ID_PCH_ADP_I219_LM17      : constant := 16#1a1c#;
   E1000_DEV_ID_PCH_ADP_I219_V17       : constant := 16#1a1d#;
   E1000_DEV_ID_PCH_RPL_I219_LM22      : constant := 16#dc7#;
   E1000_DEV_ID_PCH_RPL_I219_V22       : constant := 16#dc8#;
   E1000_DEV_ID_PCH_MTP_I219_LM18      : constant := 16#550a#;
   E1000_DEV_ID_PCH_MTP_I219_V18       : constant := 16#550b#;
   E1000_DEV_ID_PCH_MTP_I219_LM19      : constant := 16#550c#;
   E1000_DEV_ID_PCH_MTP_I219_V19       : constant := 16#550d#;
   E1000_DEV_ID_PCH_LNP_I219_LM20      : constant := 16#550e#;
   E1000_DEV_ID_PCH_LNP_I219_V20       : constant := 16#550f#;
   E1000_DEV_ID_PCH_LNP_I219_LM21      : constant := 16#5510#;
   E1000_DEV_ID_PCH_LNP_I219_V21       : constant := 16#5511#;
   E1000_DEV_ID_PCH_ARL_I219_LM24      : constant := 16#57a0#;
   E1000_DEV_ID_PCH_ARL_I219_V24       : constant := 16#57a1#;
   E1000_DEV_ID_PCH_PTP_I219_LM25      : constant := 16#57b3#;
   E1000_DEV_ID_PCH_PTP_I219_V25       : constant := 16#57b4#;
   E1000_DEV_ID_PCH_PTP_I219_LM26      : constant := 16#57b5#;
   E1000_DEV_ID_PCH_PTP_I219_V26       : constant := 16#57b6#;
   E1000_DEV_ID_PCH_PTP_I219_LM27      : constant := 16#57b7#;
   E1000_DEV_ID_PCH_PTP_I219_V27       : constant := 16#57b8#;
   E1000_DEV_ID_PCH_NVL_I219_LM29      : constant := 16#57b9#;
   E1000_DEV_ID_PCH_NVL_I219_V29       : constant := 16#57ba#;

   E1000_REVISION_4                    : constant := 4;

   E1000_FUNC_1                        : constant := 1;

   E1000_ALT_MAC_ADDRESS_OFFSET_LAN0   : constant := 0;
   E1000_ALT_MAC_ADDRESS_OFFSET_LAN1   : constant := 3;

   E1000_HI_MAX_MNG_DATA_LENGTH        : constant := 16#6f8#;

   E1000_ICH8_SHADOW_RAM_WORDS         : constant := 2_048;


end Devices.e1000e.Hardware;
