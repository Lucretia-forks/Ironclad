with
     Devices.e1000e.Core.Pointers,
     Devices.e1000e.Defines,
     Devices.e1000e.Hardware.e1000_hw,
     Interfaces;


package Devices.e1000e.Physical_Layer
is
   use Devices.e1000e.Core,
       Devices.e1000e.Defines,
       Interfaces;


   -- e1000_hw
   --
   subtype e1000_hw is Devices.e1000e.Hardware.e1000_hw.item;


   -------------
   --- Constants
   --

   PHY_PAGE_SHIFT                    : constant := 5;
   E1000_MAX_PHY_ADDR                : constant := 8;


   -- IGP01E1000 Specific Registers.
   --
   IGP01E1000_PHY_PORT_CONFIG        : constant := 16#10#;     -- Port Config.
   IGP01E1000_PHY_PORT_STATUS        : constant := 16#11#;     -- Status.
   IGP01E1000_PHY_PORT_CTRL          : constant := 16#12#;     -- Control.
   IGP01E1000_PHY_LINK_HEALTH        : constant := 16#13#;     -- PHY Link Health.
   IGP02E1000_PHY_POWER_MGMT         : constant := 16#19#;     -- Power Management.
   IGP01E1000_PHY_PAGE_SELECT        : constant := 16#1f#;     -- Page Select.
   BM_PHY_PAGE_SELECT                : constant := 22;         -- Page Select for BM.
   IGP_PAGE_SHIFT                    : constant := 5;
   PHY_REG_MASK                      : constant := 16#1f#;


   -- BM/HV Specific Registers.
   --
   BM_PORT_CTRL_PAGE                 : constant := 769;
   BM_WUC_PAGE                       : constant := 800;
   BM_WUC_ADDRESS_OPCODE             : constant := 16#11#;
   BM_WUC_DATA_OPCODE                : constant := 16#12#;
   BM_WUC_ENABLE_PAGE                : constant := BM_PORT_CTRL_PAGE;
   BM_WUC_ENABLE_REG                 : constant := 17;

   BM_WUC_ENABLE_BIT                 : constant u16 := BIT (2);
   BM_WUC_HOST_WU_BIT                : constant u16 := BIT (4);
   BM_WUC_ME_WU_BIT                  : constant u16 := BIT (5);



   PHY_UPPER_SHIFT                   : constant := 21;

   function BM_PHY_REG (page : in u32;
                        reg  : in u32) return u32
   is
     (u32 (   (reg and MAX_PHY_REG_ADDRESS)
           or shift_Left (page and 16#FFFF#,
                          PHY_PAGE_SHIFT)
           or shift_Left (reg and not MAX_PHY_REG_ADDRESS,
                          PHY_UPPER_SHIFT - PHY_PAGE_SHIFT)));

   function BM_PHY_REG_PAGE (offset : in u32) return Unsigned_16
   is
     (Unsigned_16 (    shift_Right (offset, PHY_PAGE_SHIFT)
                   and 16#FFFF#));


   function BM_PHY_REG_NUM (offset : in u32) return Unsigned_16
   is
     (Unsigned_16 (   (offset and MAX_PHY_REG_ADDRESS)
                   or (    shift_Right (offset, (PHY_UPPER_SHIFT - PHY_PAGE_SHIFT))
                       and not MAX_PHY_REG_ADDRESS)));


   HV_INTC_FC_PAGE_START             : constant := 768;
   I82578_ADDR_REG                   : constant := 29;
   I82577_ADDR_REG                   : constant := 16;
   I82577_CTRL_REG                   : constant := 23;
   I82577_CFG_REG                    : constant := 22;
   I82577_CFG_ASSERT_CRS_ON_TX       : constant         u16         := BIT (15);
   I82577_CFG_ENABLE_DOWNSHIFT       : aliased constant Unsigned_16 := shift_Left (3, 10);     -- Auto downshift.


   -- 82577 specific PHY registers.
   --
   I82577_PHY_CTRL_2                 : constant := 18;
   I82577_PHY_LBK_CTRL               : constant := 19;
   I82577_PHY_STATUS_2               : constant := 26;
   I82577_PHY_DIAG_STATUS            : constant := 31;


   -- I82577 PHY Status 2.
   --
   I82577_PHY_STATUS2_REV_POLARITY   : constant := 16#400#;
   I82577_PHY_STATUS2_MDIX           : constant := 16#800#;
   I82577_PHY_STATUS2_SPEED_MASK     : constant := 16#300#;
   I82577_PHY_STATUS2_SPEED_1000MBPS : constant := 16#200#;


   -- I82577 PHY Control 2.
   --
   I82577_PHY_CTRL2_MANUAL_MDIX      : constant := 16#200#;
   I82577_PHY_CTRL2_AUTO_MDI_MDIX    : constant := 16#400#;
   I82577_PHY_CTRL2_MDIX_CFG_MASK    : constant := 16#600#;


   -- I82577 PHY Diagnostics Status.
   --
   I82577_DSTATUS_CABLE_LENGTH       : constant := 16#3fc#;
   I82577_DSTATUS_CABLE_LENGTH_SHIFT : constant := 2;


   -- BM PHY Copper Specific Control 1.
   --
   BM_CS_CTRL1                       : constant := 16;


   -- BM PHY Copper Specific Status.
   --
   BM_CS_STATUS                      : constant := 17;
   BM_CS_STATUS_LINK_UP              : constant := 16#400#;
   BM_CS_STATUS_RESOLVED             : constant := 16#800#;
   BM_CS_STATUS_SPEED_MASK           : constant := 16#c000#;
   BM_CS_STATUS_SPEED_1000           : constant := 16#8000#;


   -- 82577 Mobile Phy Status Register.
   --
   HV_M_STATUS                       : constant := 26;
   HV_M_STATUS_AUTONEG_COMPLETE      : constant := 16#1000#;
   HV_M_STATUS_SPEED_MASK            : constant := 16#300#;
   HV_M_STATUS_SPEED_1000            : constant := 16#200#;
   HV_M_STATUS_SPEED_100             : constant := 16#100#;
   HV_M_STATUS_LINK_UP               : constant := 16#40#;


   IGP01E1000_PHY_PCS_INIT_REG       : constant := 16#b4#;
   IGP01E1000_PHY_POLARITY_MASK      : constant := 16#78#;


   IGP01E1000_PSCR_AUTO_MDIX         : constant := 16#1000#;
   IGP01E1000_PSCR_FORCE_MDI_MDIX    : constant := 16#2000#;     -- 0=MDI, 1=MDIX


   IGP01E1000_PSCFR_SMART_SPEED      : constant := 16#80#;


   IGP02E1000_PM_SPD                 : constant := 16#1#;        -- Smart Power Down.
   IGP02E1000_PM_D0_LPLU             : constant := 16#2#;        -- For D0a states.
   IGP02E1000_PM_D3_LPLU             : constant := 16#4#;        -- For all other states.


   IGP01E1000_PLHR_SS_DOWNGRADE      : constant := 16#8000#;


   IGP01E1000_PSSR_POLARITY_REVERSED : constant := 16#2#;
   IGP01E1000_PSSR_MDIX              : constant := 16#800#;
   IGP01E1000_PSSR_SPEED_MASK        : constant := 16#c000#;
   IGP01E1000_PSSR_SPEED_1000MBPS    : constant := 16#c000#;


   IGP02E1000_PHY_CHANNEL_NUM        : constant := 4;
   IGP02E1000_PHY_AGC_A              : constant := 16#11b1#;
   IGP02E1000_PHY_AGC_B              : constant := 16#12b1#;
   IGP02E1000_PHY_AGC_C              : constant := 16#14b1#;
   IGP02E1000_PHY_AGC_D              : constant := 16#18b1#;


   IGP02E1000_AGC_LENGTH_SHIFT       : constant := 9;            -- Course=15:13, Fine=12:9
   IGP02E1000_AGC_LENGTH_MASK        : constant := 16#7f#;
   IGP02E1000_AGC_RANGE              : constant := 15;


   E1000_CABLE_LENGTH_UNDEFINED      : constant := 16#ff#;


   E1000_KMRNCTRLSTA_OFFSET          : constant := 16#1f_0000#;
   E1000_KMRNCTRLSTA_OFFSET_SHIFT    : constant := 16;
   E1000_KMRNCTRLSTA_REN             : constant := 16#20_0000#;
   E1000_KMRNCTRLSTA_CTRL_OFFSET     : constant := 16#1#;        -- Kumeran Control.
   E1000_KMRNCTRLSTA_DIAG_OFFSET     : constant := 16#3#;        -- Kumeran Diagnostic.
   E1000_KMRNCTRLSTA_TIMEOUTS        : constant := 16#4#;        -- Kumeran Timeouts.
   E1000_KMRNCTRLSTA_INBAND_PARAM    : constant := 16#9#;        -- Kumeran InBand Parameters.
   E1000_KMRNCTRLSTA_IBIST_DISABLE   : constant := 16#200#;      -- Kumeran IBIST Disable.
   E1000_KMRNCTRLSTA_DIAG_NELPBK     : constant := 16#1000#;     -- Nearend Loopback mode.
   E1000_KMRNCTRLSTA_K1_CONFIG       : constant := 16#7#;
   E1000_KMRNCTRLSTA_K1_ENABLE       : constant := 16#2#;        -- Enable K1.
   E1000_KMRNCTRLSTA_HD_CTRL         : constant := 16#10#;       -- Kumeran HD Control.


   IFE_PHY_EXTENDED_STATUS_CONTROL   : constant := 16#10#;
   IFE_PHY_SPECIAL_CONTROL           : constant := 16#11#;       -- 100BaseTx PHY Special Ctrl.
   IFE_PHY_SPECIAL_CONTROL_LED       : constant := 16#1b#;       -- PHY Special and LED Ctrl.
   IFE_PHY_MDIX_CONTROL              : constant := 16#1c#;       -- MDI/MDI-X Control.


   -- IFE PHY Extended Status Control.
   --
   IFE_PESC_POLARITY_REVERSED        : constant := 16#100#;


   -- IFE PHY Special Control.
   --
   IFE_PSC_AUTO_POLARITY_DISABLE     : constant := 16#10#;
   IFE_PSC_FORCE_POLARITY            : constant := 16#20#;


   -- IFE PHY Special Control and LED Control.
   --
   IFE_PSCL_PROBE_MODE               : constant := 16#20#;
   IFE_PSCL_PROBE_LEDS_OFF           : constant := 16#6#;        -- Force LEDs 0 and 2 off.
   IFE_PSCL_PROBE_LEDS_ON            : constant := 16#7#;        -- Force LEDs 0 and 2 on.


   -- IFE PHY MDIX Control.
   --
   IFE_PMC_MDIX_STATUS               : constant := 16#20#;       -- 1=MDI-X,       0=MDI
   IFE_PMC_FORCE_MDIX                : constant := 16#40#;       -- 1=force MDI-X, 0=force MDI
   IFE_PMC_AUTO_MDIX                 : constant := 16#80#;       -- 1=enable auto, 0=disable



   ----------------
   --- Subprograms.
   --

   use Devices.e1000e.Hardware,
       Devices.e1000e.Core.Pointers;


   function e1000e_check_downshift
     (hw : access e1000_hw) return s32;

   function e1000_check_polarity_m88
     (hw : access e1000_hw) return s32;

   function e1000_check_polarity_igp
     (hw : access e1000_hw) return s32;

   function e1000_check_polarity_ife
     (hw : access e1000_hw) return s32;

   function e1000e_check_reset_block_generic
     (hw : access e1000_hw) return s32;

   function e1000e_copper_link_setup_igp
     (hw : access e1000_hw) return s32;

   function e1000e_copper_link_setup_m88
     (hw : access e1000_hw) return s32;

   function e1000e_phy_force_speed_duplex_igp
     (hw : access e1000_hw) return s32;

   function e1000e_phy_force_speed_duplex_m88
     (hw : access e1000_hw) return s32;

   function e1000_phy_force_speed_duplex_ife
     (hw : access e1000_hw) return s32;

   function e1000e_get_cable_length_m88
     (hw : access e1000_hw) return s32;

   function e1000e_get_cable_length_igp_2
     (hw : access e1000_hw) return s32;

   function e1000e_get_cfg_done_generic
     (hw : access e1000_hw) return s32;

   function e1000e_get_phy_id
     (hw : access e1000_hw) return s32;

   function e1000e_get_phy_info_igp
     (hw : access e1000_hw) return s32;

   function e1000e_get_phy_info_m88
     (hw : access e1000_hw) return s32;

   function e1000_get_phy_info_ife
     (hw : access e1000_hw) return s32;

   function e1000e_phy_sw_reset
     (hw : access e1000_hw) return s32;

   procedure e1000e_phy_force_speed_duplex_setup
     (hw       : access e1000_hw;
      phy_ctrl : in     u16_Pointer);

   function e1000e_phy_hw_reset_generic
     (hw     : access e1000_hw)  return s32;

   function e1000e_phy_reset_dsp
     (hw     : access e1000_hw)  return s32;

   function e1000e_read_kmrn_reg
     (hw     : access e1000_hw;
      offset : in     u32;
      data   : in     u16_Pointer) return s32;

   function e1000e_read_kmrn_reg_locked
     (hw     : access e1000_hw;
      offset : in     u32;
      data   : in     u16_Pointer) return s32;

   function e1000_set_page_igp
     (hw     : access e1000_hw;
      page   : in     u16)   return s32;

   function e1000e_read_phy_reg_igp
     (hw     : access e1000_hw;
      offset : in     u32;
      data   : in     u16_Pointer) return s32;

   function e1000e_read_phy_reg_igp_locked
     (hw     : access e1000_hw;
      offset : in     u32;
      data   : in     u16_Pointer) return s32;

   function e1000e_read_phy_reg_m88
     (hw     : access e1000_hw;
      offset : in     u32;
      data   : in     u16_Pointer) return s32;

   function e1000e_set_d3_lplu_state
     (hw     : access e1000_hw;
      active : in     Boolean)   return s32;

   function e1000e_setup_copper_link
     (hw : access e1000_hw)      return s32;

   function e1000e_write_kmrn_reg
     (hw     : access e1000_hw;
      offset : in     u32;
      data   : in     u16)       return s32;

   function e1000e_write_kmrn_reg_locked
     (hw     : access e1000_hw;
      offset : in     u32;
      data   : in     u16)       return s32;

   function e1000e_write_phy_reg_igp
     (hw     : access e1000_hw;
      offset : in     u32;
      data   : in     u16)   return s32;

   function e1000e_write_phy_reg_igp_locked
     (hw     : access e1000_hw;
      offset : in     u32;
      data   : in     u16)   return s32;

   function e1000e_write_phy_reg_m88
     (hw     : access e1000_hw;
      offset : in     u32;
      data   : in     u16)   return s32;

   function e1000e_phy_has_link_generic
     (hw            : access e1000_hw;
      iterations    : in     u32;
      usec_interval : in     u32;
      success       :    out Boolean) return s32;

   function e1000e_phy_init_script_igp3
     (hw : access e1000_hw)      return s32;

   function e1000e_get_phy_type_from_id
     (phy_id : in u32)       return e1000_phy_type;

   function e1000e_determine_phy_address
     (hw : access e1000_hw)      return s32;

   function e1000e_write_phy_reg_bm
     (hw     : access e1000_hw;
      offset : in     u32;
      data   : in     u16)    return s32;

   function e1000e_read_phy_reg_bm
     (hw     : access e1000_hw;
      offset : in     u32;
      data   : in     u16_Pointer) return s32;

   function e1000_enable_phy_wakeup_reg_access_bm
     (hw      : access e1000_hw;
      phy_reg : in     u16_Pointer) return s32;

   function e1000_disable_phy_wakeup_reg_access_bm
     (hw      : access e1000_hw;
      phy_reg : in     u16_Pointer) return s32;

   function e1000e_read_phy_reg_bm2
     (hw      : access e1000_hw;
      offset  : in     u32;
      data    : in     u16_Pointer) return s32;

   function e1000e_write_phy_reg_bm2
     (hw     : access e1000_hw;
      offset : in     u32;
      data   : in     u16)          return s32;

   procedure e1000_power_up_phy_copper
     (hw : access e1000_hw);

   procedure e1000_power_down_phy_copper
     (hw : access e1000_hw);

   procedure e1000e_disable_phy_retry
     (hw : access e1000_hw);

   procedure e1000e_enable_phy_retry
     (hw : access e1000_hw);

   function e1000e_read_phy_reg_mdic
     (hw     : access e1000_hw;
      offset : in     u32;
      data   : in     u16_Pointer) return s32;

   function e1000e_write_phy_reg_mdic
     (hw     : access e1000_hw;
      offset : in     u32;
      data   : in     u16)       return s32;

   function e1000_read_phy_reg_hv
     (hw     : access e1000_hw;
      offset : in     u32;
      data   : in     u16_Pointer) return s32;

   function e1000_read_phy_reg_hv_locked
     (hw     : access e1000_hw;
      offset : in     u32;
      data   : in     u16_Pointer) return s32;

   function e1000_read_phy_reg_page_hv
     (hw     : access e1000_hw;
      offset : in     u32;
      data   : in     u16_Pointer) return s32;

   function e1000_write_phy_reg_hv
     (hw     : access e1000_hw;
      offset : in     u32;
      data   : in     u16)   return s32;

   function e1000_write_phy_reg_hv_locked
     (hw     : access e1000_hw;
      offset : in     u32;
      data   : in     u16)   return s32;

   function e1000_write_phy_reg_page_hv
     (hw     : access e1000_hw;
      offset : in     u32;
      data   : in     u16)   return s32;

   function e1000_link_stall_workaround_hv
     (hw     : access e1000_hw)  return s32;

   function e1000_copper_link_setup_82577
     (hw     : access e1000_hw)  return s32;

   function e1000_check_polarity_82577
     (hw     : access e1000_hw)  return s32;

   function e1000_get_phy_info_82577
     (hw     : access e1000_hw)  return s32;

   function e1000_phy_force_speed_duplex_82577
     (hw     : access e1000_hw)  return s32;

   function e1000_get_cable_length_82577
     (hw     : access e1000_hw)  return s32;


end Devices.e1000e.Physical_Layer;
