with
     Devices.e1000e.Core.Pointers,
     Devices.e1000e.Defines,
     Devices.e1000e.Hardware.e1000_mac_operations,
     Devices.e1000e.Hardware.e1000_phy_operations,
     Devices.e1000e.Hardware.e1000_nvm_operations,
     Devices.e1000e.Physical_Layer,
     Devices.e1000e.Media_Access_Control,
     Devices.e1000e.Non_Volatile_Memory,
     Devices.e1000e.Base.e1000_Adapter,
     Devices.e1000e.Base.e1000_info,
     Linux,
     Interfaces.C,
     System.storage_Elements;


package Devices.e1000e.Ich8Lan
is
   use Devices.e1000e.Core,
       Devices.e1000e.Core.Pointers,
       Devices.e1000e.Defines,
       Devices.e1000e.Base,
       Devices.e1000e.Physical_Layer,
       Interfaces,
       System.storage_Elements;


   ICH_FLASH_GFPREG                : constant := 16#0#;
   ICH_FLASH_HSFSTS                : constant := 16#4#;
   ICH_FLASH_HSFCTL                : constant := 16#6#;
   ICH_FLASH_FADDR                 : constant := 16#8#;
   ICH_FLASH_FDATA0                : constant := 16#10#;
   ICH_FLASH_PR0                   : constant := 16#74#;

   -- Requires up to 10 seconds when MNG might be accessing part.
   --
   ICH_FLASH_READ_COMMAND_TIMEOUT  : constant := 10_000_000;
   ICH_FLASH_WRITE_COMMAND_TIMEOUT : constant := 10_000_000;
   ICH_FLASH_ERASE_COMMAND_TIMEOUT : constant := 10_000_000;
   ICH_FLASH_LINEAR_ADDR_MASK      : constant := 16#ff_ffff#;
   ICH_FLASH_CYCLE_REPEAT_COUNT    : constant := 10;


   ICH_CYCLE_READ                  : constant := 0;
   ICH_CYCLE_WRITE                 : constant := 2;
   ICH_CYCLE_ERASE                 : constant := 3;


   FLASH_GFPREG_BASE_MASK          : constant := 16#1fff#;
   FLASH_SECTOR_ADDR_SHIFT         : constant := 12;


   ICH_FLASH_SEG_SIZE_256          : constant := 256;
   ICH_FLASH_SEG_SIZE_4K           : constant := 4_096;
   ICH_FLASH_SEG_SIZE_8K           : constant := 8_192;
   ICH_FLASH_SEG_SIZE_64K          : constant := 65_536;


   E1000_ICH_FWSM_RSPCIPHY         : constant := 16#40#;           -- Reset PHY on PCI Reset.
   E1000_ICH_FWSM_FW_VALID         : constant := 16#8000#;         -- FW established a valid mode.
   E1000_ICH_FWSM_PCIM2PCI         : constant := 16#100_0000#;     -- ME PCIm-to-PCI active.
   E1000_ICH_FWSM_PCIM2PCI_COUNT   : constant := 2_000;


   E1000_ICH_MNG_IAMT_MODE         : constant := 16#2#;


   E1000_FWSM_WLOCK_MAC_MASK       : constant := 16#380#;
   E1000_FWSM_WLOCK_MAC_SHIFT      : constant := 7;
   E1000_FWSM_ULP_CFG_DONE         : constant := 16#400#;          -- Low power cfg done.
   E1000_EXFWSM_DPG_EXIT_DONE      : constant := 16#1#;


   -- Shared Receive Address Registers
   --

   function E1000_SHRAL_PCH_LPT (i : in integer_Address) return system.Address
   is
      (to_Address (16#05408# + i * 8));

   function E1000_SHRAH_PCH_LPT (i : in integer_Address) return system.Address
   is
     (to_Address (16#0540C# + i * 8));


   E1000_H2ME                      : constant := 16#5b50#;          -- Host to ME.
   E1000_H2ME_START_DPG            : constant := 16#1#;             -- Indicate the ME of DPG.
   E1000_H2ME_EXIT_DPG             : constant := 16#2#;             -- Indicate the ME exit DPG.
   E1000_H2ME_ULP                  : constant := 16#800#;           -- ULP Indication Bit.
   E1000_H2ME_ENFORCE_SETTINGS     : constant := 16#1000#;          -- Enforce Settings.

   ID_LED_DEFAULT_ICH8LAN          : constant Unsigned_32 :=    shift_Left (Devices.e1000e.Defines.ID_LED_DEF1_DEF2, 12)
                                                             or shift_Left (Devices.e1000e.Defines.ID_LED_OFF1_OFF2,  8)
                                                             or shift_Left (Devices.e1000e.Defines.ID_LED_OFF1_ON2,   4)
                                                             or             Devices.e1000e.Defines.ID_LED_DEF1_DEF2;

   E1000_ICH_NVM_SIG_WORD       : aliased constant Interfaces.C.unsigned := 16#13#;
   E1000_ICH_NVM_SIG_MASK       : aliased constant Interfaces.C.unsigned := 16#c000#;
   E1000_ICH_NVM_VALID_SIG_MASK : aliased constant Interfaces.C.unsigned := 16#c0#;
   E1000_ICH_NVM_SIG_VALUE      : aliased constant Interfaces.C.unsigned := 16#80#;


   E1000_ICH8_LAN_INIT_TIMEOUT                 : constant := 1_500;

   -- FEXT register bit definition.
   --
   E1000_FEXT_PHY_CABLE_DISCONNECTED           : constant := 16#4#;


   E1000_FEXTNVM_SW_CONFIG                     : constant             := 1;
   E1000_FEXTNVM_SW_CONFIG_ICH8M               : constant Unsigned_32 := shift_Left (1, 27);     -- Different on ICH8M.


   E1000_FEXTNVM3_PHY_CFG_COUNTER_MASK         : constant := 16#c00_0000#;
   E1000_FEXTNVM3_PHY_CFG_COUNTER_50MSEC       : constant := 16#800_0000#;


   E1000_FEXTNVM4_BEACON_DURATION_MASK         : constant := 16#7#;
   E1000_FEXTNVM4_BEACON_DURATION_8USEC        : constant := 16#7#;
   E1000_FEXTNVM4_BEACON_DURATION_16USEC       : constant := 16#3#;


   E1000_FEXTNVM6_REQ_PLL_CLK                  : constant := 16#100#;
   E1000_FEXTNVM6_ENABLE_K1_ENTRY_CONDITION    : constant := 16#200#;
   E1000_FEXTNVM6_K1_OFF_ENABLE                : constant := 16#8000_0000#;
   E1000_FEXTNVM7_DISABLE_PB_READ              : constant := 16#4_0000#;        -- Bit for disabling packet buffer read.
   E1000_FEXTNVM7_SIDE_CLK_UNGATE              : constant := 16#4#;
   E1000_FEXTNVM7_DISABLE_SMB_PERST            : constant := 16#20#;
   E1000_FEXTNVM9_IOSFSB_CLKGATE_DIS           : constant := 16#800#;
   E1000_FEXTNVM9_IOSFSB_CLKREQ_DIS            : constant := 16#1000#;
   E1000_FEXTNVM11_DISABLE_PB_READ             : constant := 16#200#;
   E1000_FEXTNVM11_DISABLE_MULR_FIX            : constant := 16#2000#;


   E1000_RXDCTL_THRESH_UNIT_DESC               : constant := 16#100_0000#;      -- bit24: RXDCTL thresholds granularity: 0 - cache lines, 1 - descriptors.


   K1_ENTRY_LATENCY                            : constant := 0;
   K1_MIN_TIME                                 : constant := 1;
   NVM_SIZE_MULTIPLIER                         : constant := 4_096;              -- Multiplier for NVMS field.
   E1000_FLASH_BASE_ADDR                       : constant := 16#e000#;           -- Offset of NVM access regs.
   E1000_CTRL_EXT_NVMVS                        : constant := 16#3#;              -- NVM valid sector.
   E1000_TARC0_CB_MULTIQ_3_REQ                 : constant := 16#3000_0000#;
   E1000_TARC0_CB_MULTIQ_2_REQ                 : constant := 16#2000_0000#;
   PCIE_ICH8_SNOOP_ALL                         : constant := PCIE_NO_SNOOP_ALL;

   E1000_ICH_RAR_ENTRIES                       : constant := 7;
   E1000_PCH2_RAR_ENTRIES                      : constant := 5;                  -- RAR[0], SHRA[0-3].
   E1000_PCH_LPT_RAR_ENTRIES                   : constant := 12;                 -- RAR[0], SHRA[0-10].


   function PHY_REG (page : in Unsigned_64;
                     reg  : in Unsigned_64) return u32
   is
     (u32 (   shift_Left (page, PHY_PAGE_SHIFT)
           or (reg and Devices.e1000e.Defines.MAX_PHY_REG_ADDRESS)));

   IGP3_KMRN_DIAG    : constant u32 := PHY_REG (770, 19);               -- KMRN Diagnostic.
   IGP3_VR_CTRL      : constant u32 := PHY_REG (776, 18);               -- Voltage Regulator Control.


   IGP3_KMRN_DIAG_PCS_LOCK_LOSS                : constant := 16#2#;
   IGP3_VR_CTRL_DEV_POWERDOWN_MODE_MASK        : constant := 16#300#;
   IGP3_VR_CTRL_MODE_SHUTDOWN                  : constant := 16#200#;

   -- PHY Wakeup Registers and defines.
   --
   BM_PORT_GEN_CFG   : constant u32 := PHY_REG (BM_PORT_CTRL_PAGE, 17);
   BM_RCTL           : constant u32 := PHY_REG (BM_WUC_PAGE,        0);
   BM_WUC            : constant u32 := PHY_REG (BM_WUC_PAGE,        1);
   BM_WUFC           : constant u32 := PHY_REG (BM_WUC_PAGE,        2);
   BM_WUS            : constant u32 := PHY_REG (BM_WUC_PAGE,        3);


   function BM_RAR_L (i : in u32) return u32
   is
     (BM_PHY_REG (BM_WUC_PAGE,
                  16 + shift_Left (i, 2)));


   function BM_RAR_M (i : in u32) return u32
   is
     (BM_PHY_REG (BM_WUC_PAGE,
                  17 + shift_Left (i, 2)));


   function BM_RAR_H (i : in u32) return u32
   is
     (BM_PHY_REG (BM_WUC_PAGE,
                  18 + shift_Left (i, 2)));


   function BM_RAR_CTRL (i : in u32) return u32
   is
     (BM_PHY_REG (BM_WUC_PAGE,
                  19 + shift_Left (i, 2)));


   function BM_MTA (i : in u32) return u32
   is
     (BM_PHY_REG (BM_WUC_PAGE,
                  128 + shift_Left (i, 1)));


   BM_RCTL_UPE                  : constant             := 16#1#;                 -- Unicast Promiscuous Mode.
   BM_RCTL_MPE                  : constant             := 16#2#;                 -- Multicast Promiscuous Mode.
   BM_RCTL_MO_SHIFT             : constant             := 3;                     -- Multicast Offset Shift.
   BM_RCTL_MO_MASK              : constant Unsigned_32 := shift_Left (3, 3);     -- Multicast Offset Mask.
   BM_RCTL_BAM                  : constant             := 16#20#;                -- Broadcast Accept Mode.
   BM_RCTL_PMCF                 : constant             := 16#40#;                -- Pass MAC Control Frames.
   BM_RCTL_RFCE                 : constant             := 16#80#;                -- Rx Flow Control Enable.

   HV_LED_CONFIG                : constant u32         := PHY_REG (768, 30);     -- LED Configuration.
   HV_MUX_DATA_CTRL             : constant u32         := PHY_REG (776, 16);

   HV_MUX_DATA_CTRL_GEN_TO_MAC  : constant := 16#400#;
   HV_MUX_DATA_CTRL_FORCE_SPEED : constant := 16#4#;
   HV_STATS_PAGE                : constant := 778;


   -- Half-duplex collision counts.
   --
   HV_SCC_UPPER     : constant u32 := PHY_REG (HV_STATS_PAGE, 16);     -- Single Collision.
   HV_SCC_LOWER     : constant u32 := PHY_REG (HV_STATS_PAGE, 17);
   HV_ECOL_UPPER    : constant u32 := PHY_REG (HV_STATS_PAGE, 18);     -- Excessive Coll.
   HV_ECOL_LOWER    : constant u32 := PHY_REG (HV_STATS_PAGE, 19);
   HV_MCC_UPPER     : constant u32 := PHY_REG (HV_STATS_PAGE, 20);     -- Multiple Collision.
   HV_MCC_LOWER     : constant u32 := PHY_REG (HV_STATS_PAGE, 21);
   HV_LATECOL_UPPER : constant u32 := PHY_REG (HV_STATS_PAGE, 23);     -- Late Collision.
   HV_LATECOL_LOWER : constant u32 := PHY_REG (HV_STATS_PAGE, 24);
   HV_COLC_UPPER    : constant u32 := PHY_REG (HV_STATS_PAGE, 25);     -- Collision.
   HV_COLC_LOWER    : constant u32 := PHY_REG (HV_STATS_PAGE, 26);
   HV_DC_UPPER      : constant u32 := PHY_REG (HV_STATS_PAGE, 27);     -- Defer Count.
   HV_DC_LOWER      : constant u32 := PHY_REG (HV_STATS_PAGE, 28);
   HV_TNCRS_UPPER   : constant u32 := PHY_REG (HV_STATS_PAGE, 29);     -- Tx with no CRS.
   HV_TNCRS_LOWER   : constant u32 := PHY_REG (HV_STATS_PAGE, 30);


   E1000_FCRTV_PCH                             : constant := 16#5f40#;            -- PCH Flow Control Refresh Timer Value.


   E1000_NVM_K1_CONFIG                         : constant := 16#1b#;              -- NVM K1 Config Word.
   E1000_NVM_K1_ENABLE                         : constant := 16#1#;               -- NVM Enable K1 bit.


   -- SMBus Control Phy Register.
   --
   CV_SMB_CTRL                                 : constant u32 := PHY_REG (769, 23);
   CV_SMB_CTRL_FORCE_SMBUS                     : constant     := 16#1#;


   -- I218 Ultra Low Power Configuration 1 Register.
   --
   I218_ULP_CONFIG1                            : constant u32 := PHY_REG (779, 16);
   I218_ULP_CONFIG1_START                      : constant     := 16#1#;        -- Start auto ULP config.
   I218_ULP_CONFIG1_IND                        : constant     := 16#4#;        -- Pwr up from ULP indication.
   I218_ULP_CONFIG1_STICKY_ULP                 : constant     := 16#10#;       -- Set sticky ULP mode.
   I218_ULP_CONFIG1_INBAND_EXIT                : constant     := 16#20#;       -- Inband on ULP exit.
   I218_ULP_CONFIG1_WOL_HOST                   : constant     := 16#40#;       -- WoL Host on ULP exit.
   I218_ULP_CONFIG1_RESET_TO_SMBUS             : constant     := 16#100#;      -- Reset to SMBus mode.
   I218_ULP_CONFIG1_EN_ULP_LANPHYPC            : constant     := 16#400#;      -- Enable ULP even if when phy powered down via lanphypc.
   I218_ULP_CONFIG1_DIS_CLR_STICKY_ON_PERST    : constant     := 16#800#;      -- Disable clear of sticky ULP on PERST.
   I218_ULP_CONFIG1_DISABLE_SMB_PERST          : constant     := 16#1000#;     -- Disable on PERST#.


   -- SMBus Address Phy Register.
   --
   HV_SMB_ADDR                                 : constant u32 := PHY_REG (768, 26);
   HV_SMB_ADDR_MASK                            : constant     := 16#7f#;
   HV_SMB_ADDR_PEC_EN                          : constant     := 16#200#;
   HV_SMB_ADDR_VALID                           : constant     := 16#80#;
   HV_SMB_ADDR_FREQ_MASK                       : constant     := 16#1100#;
   HV_SMB_ADDR_FREQ_LOW_SHIFT                  : constant     := 8;
   HV_SMB_ADDR_FREQ_HIGH_SHIFT                 : constant     := 12;

   -- Strapping Option Register - RO.
   --
   E1000_STRAP                                 : constant := 16#c#;
   E1000_STRAP_SMBUS_ADDRESS_MASK              : constant := 16#fe_0000#;
   E1000_STRAP_SMBUS_ADDRESS_SHIFT             : constant := 17;
   E1000_STRAP_SMT_FREQ_MASK                   : constant := 16#3000#;
   E1000_STRAP_SMT_FREQ_SHIFT                  : constant := 12;


   -- OEM Bits Phy Register.
   --
   HV_OEM_BITS                                 : constant u32 := PHY_REG (768, 25);
   HV_OEM_BITS_LPLU                            : constant     := 16#4#;       -- Low Power Link Up.
   HV_OEM_BITS_GBE_DIS                         : constant     := 16#40#;      -- Gigabit Disable.
   HV_OEM_BITS_RESTART_AN                      : constant     := 16#400#;     -- Restart Auto-negotiation.


   -- KMRN Mode Control.
   --
   HV_KMRN_MODE_CTRL                           : constant u32 := PHY_REG (769, 16);
   HV_KMRN_MDIO_SLOW                           : constant     := 16#400#;

   -- KMRN FIFO Control and Status.
   --
   HV_KMRN_FIFO_CTRLSTA                        : constant u32 := PHY_REG (770, 16);
   HV_KMRN_FIFO_CTRLSTA_PREAMBLE_MASK          : constant     := 16#7000#;
   HV_KMRN_FIFO_CTRLSTA_PREAMBLE_SHIFT         : constant     := 12;

   -- PHY Power Management Control.
   --
   HV_PM_CTRL                                  : constant u32 := PHY_REG (770, 17);
   HV_PM_CTRL_K1_CLK_REQ                       : constant     := 16#200#;
   HV_PM_CTRL_K1_ENABLE                        : constant     := 16#4000#;

   I217_PLL_CLOCK_GATE_REG                     : constant u32 := PHY_REG (772, 28);
   I217_PLL_CLOCK_GATE_MASK                    : constant     := 16#7ff#;


   SW_FLAG_TIMEOUT                             : constant     := 1_000;       -- SW Semaphore flag timeout in ms.


   -- Inband Control.
   --
   I217_INBAND_CTRL                            : constant u32 := PHY_REG (770, 18);
   I217_INBAND_CTRL_LINK_STAT_TX_TIMEOUT_MASK  : constant     := 16#3f00#;
   I217_INBAND_CTRL_LINK_STAT_TX_TIMEOUT_SHIFT : constant     := 8;


   -- Low Power Idle GPIO Control.
   --
   I217_LPI_GPIO_CTRL                          : constant u32 := PHY_REG (772, 18);
   I217_LPI_GPIO_CTRL_AUTO_EN_LPI              : constant     := 16#800#;


   -- PHY Low Power Idle Control.
   --
   I82579_LPI_CTRL                             : constant u32 := PHY_REG (772, 20);
   I82579_LPI_CTRL_100_ENABLE                  : constant     := 16#2000#;
   I82579_LPI_CTRL_1000_ENABLE                 : constant     := 16#4000#;
   I82579_LPI_CTRL_ENABLE_MASK                 : constant     := 16#6000#;
   I82579_LPI_CTRL_FORCE_PLL_LOCK_COUNT        : constant     := 16#80#;


   -- Extended Management Interface (EMI) Registers.
   --
   I82579_EMI_ADDR                             : constant := 16#10#;
   I82579_EMI_DATA                             : constant := 16#11#;
   I82579_LPI_UPDATE_TIMER                     : constant := 16#4805#;     -- In 40ns units + 40 ns base value.
   I82579_MSE_THRESHOLD                        : constant := 16#84f#;      -- 82579 Mean Square Error Threshold.
   I82577_MSE_THRESHOLD                        : constant := 16#887#;      -- 82577 Mean Square Error Threshold.
   I82579_MSE_LINK_DOWN                        : constant := 16#2411#;     -- MSE count before dropping link.
   I82579_RX_CONFIG                            : constant := 16#3412#;     -- Receive configuration.
   I82579_LPI_PLL_SHUT                         : constant := 16#4412#;     -- LPI PLL Shut Enable.
   I82579_EEE_PCS_STATUS                       : constant := 16#182e#;     -- IEEE MMD Register 3.1 >> 8.
   I82579_EEE_CAPABILITY                       : constant := 16#410#;      -- IEEE MMD Register 3.20.
   I82579_EEE_ADVERTISEMENT                    : constant := 16#40e#;      -- IEEE MMD Register 7.60.
   I82579_EEE_LP_ABILITY                       : constant := 16#40f#;      -- IEEE MMD Register 7.61.
   I82579_EEE_100_SUPPORTED                    : constant := 2;            -- 100BaseTx EEE.
   I82579_EEE_1000_SUPPORTED                   : constant := 4;            -- 1000BaseTx EEE.
   I82579_LPI_100_PLL_SHUT                     : constant := 4;            -- 100M LPI PLL Shut Enabled.
   I217_EEE_PCS_STATUS                         : constant := 16#9401#;     -- IEEE MMD Register 3.1.
   I217_EEE_CAPABILITY                         : constant := 16#8000#;     -- IEEE MMD Register 3.20.
   I217_EEE_ADVERTISEMENT                      : constant := 16#8001#;     -- IEEE MMD Register 7.60.
   I217_EEE_LP_ABILITY                         : constant := 16#8002#;     -- IEEE MMD Register 7.61.
   I217_RX_CONFIG                              : constant := 16#b20c#;     -- Receive configuration.


   E1000_EEE_RX_LPI_RCVD                       : constant := 16#400#;      -- Tx LP idle received.
   E1000_EEE_TX_LPI_RCVD                       : constant := 16#800#;      -- Rx LP idle received.


   -- Intel Rapid Start Technology Support.
   --
   I217_PROXY_CTRL                             : constant u32 := BM_PHY_REG (BM_WUC_PAGE, 70);
   I217_PROXY_CTRL_AUTO_DISABLE                : constant     := 16#80#;

   I217_SxCTRL                                 : constant u32 := PHY_REG (BM_PORT_CTRL_PAGE, 28);
   I217_SxCTRL_ENABLE_LPI_RESET                : constant     := 16#1000#;

   I217_CGFREG                                 : constant u32 := PHY_REG (772, 29);
   I217_CGFREG_ENABLE_MTA_RESET                : constant     := 16#2#;

   I217_MEMPWR                                 : constant u32 := PHY_REG (772, 26);
   I217_MEMPWR_DISABLE_SMB_RELEASE             : constant     := 16#10#;


   -- Receive Address Initial CRC Calculation.
   --
   function E1000_PCH_RAICC (n : in Integer_Address) return C.unsigned_long
   is
     (C.unsigned_long (16#05F50# + (n * 4)));


   -- Latency Tolerance Reporting.
   --
   E1000_LTRV                                  : constant := 16#f8#;
   E1000_LTRV_VALUE_MASK                       : constant := 16#3ff#;
   E1000_LTRV_SCALE_MAX                        : constant := 5;
   E1000_LTRV_SCALE_FACTOR                     : constant := 5;
   E1000_LTRV_SCALE_SHIFT                      : constant := 10;
   E1000_LTRV_SCALE_MASK                       : constant := 16#1c00#;
   E1000_LTRV_REQ_SHIFT                        : constant := 15;
   E1000_LTRV_NOSNOOP_SHIFT                    : constant := 16;
   E1000_LTRV_SEND                             : constant := 1_073_741_824;


   -- Proprietary Latency Tolerance Reporting PCI Capability.
   --
   E1000_PCI_LTR_CAP_LPT                       : constant := 16#a8#;

   -- Don't gate wake DMA clock.
   --
   E1000_FFLT_DBG_DONT_GATE_WAKE_DMA_CLK       : constant := 16#1000#;



   ---------------
   --- Subprograms
   --

   procedure e1000e_write_protect_nvm_ich8lan
     (hw    : access e1000_hw);

   procedure e1000e_set_kmrn_lock_loss_workaround_ich8lan
     (hw    : access e1000_hw;
      state : in     Boolean);

   procedure e1000e_igp3_phy_powerdown_workaround_ich8lan
     (hw    : access e1000_hw);

   procedure e1000e_gig_downshift_workaround_ich8lan
     (hw    : access e1000_hw);

   procedure e1000_suspend_workarounds_ich8lan
     (hw    : access e1000_hw);

   procedure e1000_resume_workarounds_pchlan
     (hw    : access e1000_hw);

   function  e1000_configure_k1_ich8lan
     (hw        : access e1000_hw;
      k1_enable : in     Boolean) return Devices.e1000e.Core.s32;

   procedure e1000_copy_rx_addrs_to_phy_ich8lan
     (hw     : access e1000_hw);

   function  e1000_lv_jumbo_workaround_ich8lan
     (hw     : access e1000_hw;
      enable : in     Boolean) return Devices.e1000e.Core.s32;

   function  e1000_read_emi_reg_locked
     (hw     : access e1000_hw;
      addr   : in     Devices.e1000e.Core.u16;
      data   : in     u16_Pointer) return Devices.e1000e.Core.s32;

   function  e1000_write_emi_reg_locked
     (hw     : access e1000_hw;
      addr   : in     Devices.e1000e.Core.u16;
      data   : in     Devices.e1000e.Core.u16) return Devices.e1000e.Core.s32;

   function  e1000_set_eee_pchlan
     (hw     : access e1000_hw) return Devices.e1000e.Core.s32;

   function  e1000_enable_ulp_lpt_lp
     (hw     : access e1000_hw;
      to_sx  : in     Boolean) return Devices.e1000e.Core.s32;




   --------
   --- Info
   --

   e1000_ich8_info    : aliased constant Devices.e1000e.Base.e1000_info.item;
   e1000_ich9_info    : aliased constant Devices.e1000e.Base.e1000_info.item;
   e1000_ich10_info   : aliased constant Devices.e1000e.Base.e1000_info.item;
   e1000_pch_info     : aliased constant Devices.e1000e.Base.e1000_info.item;
   e1000_pch2_info    : aliased constant Devices.e1000e.Base.e1000_info.item;
   e1000_pch_lpt_info : aliased constant Devices.e1000e.Base.e1000_info.item;
   e1000_pch_spt_info : aliased constant Devices.e1000e.Base.e1000_info.item;
   e1000_pch_cnp_info : aliased constant Devices.e1000e.Base.e1000_info.item;
   e1000_pch_tgp_info : aliased constant Devices.e1000e.Base.e1000_info.item;
   e1000_pch_adp_info : aliased constant Devices.e1000e.Base.e1000_info.item;
   e1000_pch_mtp_info : aliased constant Devices.e1000e.Base.e1000_info.item;





private

   -------------------
   --- e1000_ich8_info
   --

   function e1000_get_variants_ich8lan (adapter : access e1000_adapter.item) return s32;

   function e1000_check_for_copper_link_ich8lan (hw : access e1000_hw) return s32;
   function e1000_get_bus_info_ich8lan          (hw : access e1000_hw) return s32;
   function e1000_reset_hw_ich8lan              (hw : access e1000_hw) return s32;
   function e1000_init_hw_ich8lan               (hw : access e1000_hw) return s32;
   function e1000_setup_link_ich8lan            (hw : access e1000_hw) return s32;
   function e1000_setup_copper_link_ich8lan     (hw : access e1000_hw) return s32;

   procedure e1000_clear_hw_cntrs_ich8lan (hw : access e1000_hw);

   function e1000_get_link_up_info_ich8lan(hw     : access e1000_hw;
                                           speed  : in     u16_Pointer;
                                           duplex : in     u16_Pointer) return s32;



   ich8_mac_ops : aliased constant Devices.e1000e.Hardware.e1000_mac_operations.item := (check_mng_mode           => <>,     -- Dependent on mac type.
                                                                          check_for_link           => e1000_check_for_copper_link_ich8lan'Access,
                                                                          cleanup_led              => <>,     -- Dependent on mac type.
                                                                          clear_hw_cntrs           => e1000_clear_hw_cntrs_ich8lan'Access,
                                                                          get_bus_info             => e1000_get_bus_info_ich8lan'Access,
                                                                          set_lan_id               => Devices.e1000e.Media_Access_Control.e1000_set_lan_id_single_port'Access,
                                                                          get_link_up_info         => e1000_get_link_up_info_ich8lan'Access,
                                                                          led_on                   => <>,     -- Dependent on mac type.
                                                                          led_off                  => <>,     -- Dependent on mac type.
                                                                          update_mc_addr_list      => Devices.e1000e.Media_Access_Control.e1000e_update_mc_addr_list_generic'Access,
                                                                          reset_hw                 => e1000_reset_hw_ich8lan'Access,
                                                                          init_hw                  => e1000_init_hw_ich8lan'Access,
                                                                          setup_link               => e1000_setup_link_ich8lan'Access,
                                                                          setup_physical_interface => e1000_setup_copper_link_ich8lan'Access,
                                                                          id_led_init              => <>,     -- Dependent on mac type.
                                                                          config_collision_dist    => Devices.e1000e.Media_Access_Control.e1000e_config_collision_dist_generic'Access,
                                                                          rar_set                  => Devices.e1000e.Media_Access_Control.e1000e_rar_set_generic'Access,
                                                                          rar_get_count            => Devices.e1000e.Media_Access_Control.e1000e_rar_get_count_generic'Access,
                                                                          blink_led                => <>,
                                                                          clear_vfta               => <>,
                                                                          setup_led                => <>,
                                                                          write_vfta               => <>,
                                                                          read_mac_addr            => <>);


   function  e1000_acquire_swflag_ich8lan    (hw : access e1000_hw) return s32;
   function  e1000_check_reset_block_ich8lan (hw : access e1000_hw) return s32;
   function  e1000_get_cfg_done_ich8lan      (hw : access e1000_hw) return s32;
   function  e1000_phy_hw_reset_ich8lan      (hw : access e1000_hw) return s32;
   procedure e1000_release_swflag_ich8lan    (hw : access e1000_hw);

   function  e1000_set_d0_lplu_state_ich8lan (hw     : access e1000_hw;
                                              active : in     Boolean) return s32;

   function  e1000_set_d3_lplu_state_ich8lan (hw     : access e1000_hw;
                                              active : in     Boolean) return s32;



   ich8_phy_ops : aliased constant Devices.e1000e.Hardware.e1000_phy_operations.item := (acquire            => e1000_acquire_swflag_ich8lan     'Access,
                                                                          check_reset_block  => e1000_check_reset_block_ich8lan  'Access,
                                                                          commit             => null,
                                                                          get_cfg_done       => e1000_get_cfg_done_ich8lan       'Access,
                                                                          get_cable_length   => Devices.e1000e.Physical_Layer.e1000e_get_cable_length_igp_2'Access,
                                                                          read_reg           => Devices.e1000e.Physical_Layer.e1000e_read_phy_reg_igp      'Access,
                                                                          release            => e1000_release_swflag_ich8lan     'Access,
                                                                          reset              => e1000_phy_hw_reset_ich8lan       'Access,
                                                                          set_d0_lplu_state  => e1000_set_d0_lplu_state_ich8lan  'Access,
                                                                          set_d3_lplu_state  => e1000_set_d3_lplu_state_ich8lan  'Access,
                                                                          write_reg          => Devices.e1000e.Physical_Layer.e1000e_write_phy_reg_igp     'Access,
                                                                          cfg_on_link_up     => null,
                                                                          check_polarity     => null,
                                                                          force_speed_duplex => null,
                                                                          get_info           => null,
                                                                          set_page           => null,
                                                                          read_reg_locked    => null,
                                                                          read_reg_page      => null,
                                                                          write_reg_locked   => null,
                                                                          write_reg_page     => null,
                                                                          power_up           => null,
                                                                          power_down         => null);



   function  e1000_acquire_nvm_ich8lan (hw : access e1000_hw with Unreferenced) return s32;
   procedure e1000_release_nvm_ich8lan (hw : access e1000_hw with Unreferenced);


   function  e1000_update_nvm_checksum_ich8lan (hw : access e1000_hw) return s32;


   function  e1000_read_nvm_ich8lan (hw     : access e1000_hw;
                                     offset : in     u16;
                                     words  : in     u16;
                                     data   : in     u16_Pointer) return s32;

   function  e1000_valid_led_default_ich8lan (hw   : access e1000_hw;
                                              data : in     u16_Pointer) return s32;

   function  e1000_validate_nvm_checksum_ich8lan (hw : access e1000_hw) return s32;


   function  e1000_write_nvm_ich8lan (hw     : access e1000_hw;
                                      offset : in     u16;
                                      words  : in     u16;
                                      data   : in     u16_Pointer) return s32;



   ich8_nvm_ops : aliased constant Devices.e1000e.Hardware.e1000_nvm_operations.item := (acquire            => e1000_acquire_nvm_ich8lan          'Access,
                                                                          read               => e1000_read_nvm_ich8lan             'Access,
                                                                          release            => e1000_release_nvm_ich8lan          'Access,
                                                                          reload             => Devices.e1000e.Non_Volatile_Memory.e1000e_reload_nvm_generic      'Access,
                                                                          update             => e1000_update_nvm_checksum_ich8lan  'Access,
                                                                          valid_led_default  => e1000_valid_led_default_ich8lan    'Access,
                                                                          validate           => e1000_validate_nvm_checksum_ich8lan'Access,
                                                                          write              => e1000_write_nvm_ich8lan            'Access);



   e1000_ich8_info : aliased constant Devices.e1000e.Base.e1000_info.item := (mac               => Devices.e1000e.Hardware.e1000_ich8lan,
                                                                flags             =>    FLAG_HAS_WOL
                                                                                     or FLAG_IS_ICH
                                                                                     or FLAG_HAS_CTRLEXT_ON_LOAD
                                                                                     or FLAG_HAS_AMT
                                                                                     or FLAG_HAS_FLASH
                                                                                     or FLAG_APME_IN_WUC,
                                                                flags2            => 0,
                                                                pba               => 8,
                                                                max_hw_frame_size =>   linux.VLAN_ETH_FRAME_LEN
                                                                                     + linux.ETH_FCS_LEN,
                                                                get_variants      => e1000_get_variants_ich8lan'Access,
                                                                mac_ops           => ich8_mac_ops              'Access,
                                                                phy_ops           => ich8_phy_ops              'Access,
                                                                nvm_ops           => ich8_nvm_ops              'Access);
   -------------------
   --- e1000_ich9_info
   --

   e1000_ich9_info : aliased constant Devices.e1000e.Base.e1000_info.item := (mac               => Devices.e1000e.Hardware.e1000_ich9lan,
                                                                flags             =>    FLAG_HAS_JUMBO_FRAMES
                                                                                     or FLAG_IS_ICH
                                                                                     or FLAG_HAS_WOL
                                                                                     or FLAG_HAS_CTRLEXT_ON_LOAD
                                                                                     or FLAG_HAS_AMT
                                                                                     or FLAG_HAS_FLASH
                                                                                     or FLAG_APME_IN_WUC,
                                                                flags2            => 0,
                                                                pba               => 18,
                                                                max_hw_frame_size => DEFAULT_JUMBO,
                                                                get_variants      => e1000_get_variants_ich8lan'Access,
                                                                mac_ops           => ich8_mac_ops              'Access,
                                                                phy_ops           => ich8_phy_ops              'Access,
                                                                nvm_ops           => ich8_nvm_ops              'Access);
   --------------------
   --- e1000_ich10_info
   --

   e1000_ich10_info : aliased constant Devices.e1000e.Base.e1000_info.item := (mac               => Devices.e1000e.Hardware.e1000_ich10lan,
                                                                 flags             =>    FLAG_HAS_JUMBO_FRAMES
                                                                                      or FLAG_IS_ICH
                                                                                      or FLAG_HAS_WOL
                                                                                      or FLAG_HAS_CTRLEXT_ON_LOAD
                                                                                      or FLAG_HAS_AMT
                                                                                      or FLAG_HAS_FLASH
                                                                                      or FLAG_APME_IN_WUC,
                                                                 flags2            =>  0,
                                                                 pba               => 18,
                                                                 max_hw_frame_size => DEFAULT_JUMBO,
                                                                 get_variants      => e1000_get_variants_ich8lan'Access,
                                                                 mac_ops           => ich8_mac_ops              'Access,
                                                                 phy_ops           => ich8_phy_ops              'Access,
                                                                 nvm_ops           => ich8_nvm_ops              'Access);
   ------------------
   --- e1000_pch_info
   --

   e1000_pch_info   : aliased constant Devices.e1000e.Base.e1000_info.item := (mac               => Devices.e1000e.Hardware.e1000_pchlan,
                                                                 flags             =>    FLAG_IS_ICH
                                                                                      or FLAG_HAS_WOL
                                                                                      or FLAG_HAS_CTRLEXT_ON_LOAD
                                                                                      or FLAG_HAS_AMT
                                                                                      or FLAG_HAS_FLASH
                                                                                      or FLAG_HAS_JUMBO_FRAMES
                                                                                      or FLAG_DISABLE_FC_PAUSE_TIME     -- Errata
                                                                                      or FLAG_APME_IN_WUC,
                                                                 flags2            =>    FLAG2_HAS_PHY_STATS,
                                                                 pba               => 26,
                                                                 max_hw_frame_size => 4096,
                                                                 get_variants      => e1000_get_variants_ich8lan'Access,
                                                                 mac_ops           => ich8_mac_ops              'Access,
                                                                 phy_ops           => ich8_phy_ops              'Access,
                                                                 nvm_ops           => ich8_nvm_ops              'Access);
   -------------------
   --- e1000_pch2_info
   --

   e1000_pch2_info : aliased constant Devices.e1000e.Base.e1000_info.item := (mac               => Devices.e1000e.Hardware.e1000_pch2lan,
                                                                flags             =>    FLAG_IS_ICH
                                                                                     or FLAG_HAS_WOL
                                                                                     or FLAG_HAS_HW_TIMESTAMP
                                                                                     or FLAG_HAS_CTRLEXT_ON_LOAD
                                                                                     or FLAG_HAS_AMT
                                                                                     or FLAG_HAS_FLASH
                                                                                     or FLAG_HAS_JUMBO_FRAMES
                                                                                     or FLAG_APME_IN_WUC,
                                                                flags2            =>    FLAG2_HAS_PHY_STATS
                                                                                     or FLAG2_HAS_EEE
                                                                                     or FLAG2_CHECK_SYSTIM_OVERFLOW,
                                                                pba               => 26,
                                                                max_hw_frame_size => 9022,
                                                                get_variants      => e1000_get_variants_ich8lan'Access,
                                                                mac_ops           => ich8_mac_ops              'Access,
                                                                phy_ops           => ich8_phy_ops              'Access,
                                                                nvm_ops           => ich8_nvm_ops              'Access);

   ----------------------
   --- e1000_pch_lpt_info
   --

   e1000_pch_lpt_info : aliased constant Devices.e1000e.Base.e1000_info.item := (mac               => Devices.e1000e.Hardware.e1000_pch_lpt,
                                                                   flags             =>    FLAG_IS_ICH
                                                                                        or FLAG_HAS_WOL
                                                                                        or FLAG_HAS_HW_TIMESTAMP
                                                                                        or FLAG_HAS_CTRLEXT_ON_LOAD
                                                                                        or FLAG_HAS_AMT
                                                                                        or FLAG_HAS_FLASH
                                                                                        or FLAG_HAS_JUMBO_FRAMES
                                                                                        or FLAG_APME_IN_WUC,
                                                                   flags2            =>    FLAG2_HAS_PHY_STATS
                                                                                        or FLAG2_HAS_EEE
                                                                                        or FLAG2_CHECK_SYSTIM_OVERFLOW,
                                                                   pba               => 26,
                                                                   max_hw_frame_size => 9022,
                                                                   get_variants      => e1000_get_variants_ich8lan'Access,
                                                                   mac_ops           => ich8_mac_ops              'Access,
                                                                   phy_ops           => ich8_phy_ops              'Access,
                                                                   nvm_ops           => ich8_nvm_ops              'Access);
   ----------------------
   --- e1000_pch_spt_info
   --

   function e1000_read_nvm_spt (hw     : access e1000_hw;
                                offset : in     u16;
                                words  : in     u16;
                                data   : in     u16_Pointer) return s32;


   function e1000_update_nvm_checksum_spt (hw : access e1000_hw) return s32;



   spt_nvm_ops : aliased constant Devices.e1000e.Hardware.e1000_nvm_operations.item := (acquire           => e1000_acquire_nvm_ich8lan          'Access,
                                                                         release           => e1000_release_nvm_ich8lan          'Access,
                                                                         read              => e1000_read_nvm_spt                 'Access,
                                                                         update            => e1000_update_nvm_checksum_spt      'Access,
                                                                         reload            => Devices.e1000e.Non_Volatile_Memory.e1000e_reload_nvm_generic      'Access,
                                                                         valid_led_default => e1000_valid_led_default_ich8lan    'Access,
                                                                         validate          => e1000_validate_nvm_checksum_ich8lan'Access,
                                                                         write             => e1000_write_nvm_ich8lan            'Access);


   e1000_pch_spt_info : aliased constant Devices.e1000e.Base.e1000_info.item := (mac               => Devices.e1000e.Hardware.e1000_pch_spt,
                                                                   flags             =>    FLAG_IS_ICH
                                                                                        or FLAG_HAS_WOL
                                                                                        or FLAG_HAS_HW_TIMESTAMP
                                                                                        or FLAG_HAS_CTRLEXT_ON_LOAD
                                                                                        or FLAG_HAS_AMT
                                                                                        or FLAG_HAS_FLASH
                                                                                        or FLAG_HAS_JUMBO_FRAMES
                                                                                        or FLAG_APME_IN_WUC,
                                                                   flags2            =>    FLAG2_HAS_PHY_STATS
                                                                                        or FLAG2_HAS_EEE,
                                                                   pba               => 26,
                                                                   max_hw_frame_size => 9022,
                                                                   get_variants      => e1000_get_variants_ich8lan'Access,
                                                                   mac_ops           => ich8_mac_ops              'Access,
                                                                   phy_ops           => ich8_phy_ops              'Access,
                                                                   nvm_ops           => spt_nvm_ops               'Access);
   ----------------------
   --- e1000_pch_cnp_info
   --

   e1000_pch_cnp_info : aliased constant Devices.e1000e.Base.e1000_info.item := (mac               => Devices.e1000e.Hardware.e1000_pch_cnp,
                                                                   flags             =>    FLAG_IS_ICH
                                                                                        or FLAG_HAS_WOL
                                                                                        or FLAG_HAS_HW_TIMESTAMP
                                                                                        or FLAG_HAS_CTRLEXT_ON_LOAD
                                                                                        or FLAG_HAS_AMT
                                                                                        or FLAG_HAS_FLASH
                                                                                        or FLAG_HAS_JUMBO_FRAMES
                                                                                        or FLAG_APME_IN_WUC,
                                                                   flags2            =>    FLAG2_HAS_PHY_STATS
                                                                                        or FLAG2_HAS_EEE,
                                                                   pba               => 26,
                                                                   max_hw_frame_size => 9022,
                                                                   get_variants      => e1000_get_variants_ich8lan'Access,
                                                                   mac_ops           => ich8_mac_ops              'Access,
                                                                   phy_ops           => ich8_phy_ops              'Access,
                                                                   nvm_ops           => spt_nvm_ops               'Access);
   ----------------------
   --- e1000_pch_tgp_info
   --

   e1000_pch_tgp_info : aliased constant Devices.e1000e.Base.e1000_info.item := (mac               => Devices.e1000e.Hardware.e1000_pch_tgp,
                                                                   flags             =>    FLAG_IS_ICH
                                                                                        or FLAG_HAS_WOL
                                                                                        or FLAG_HAS_HW_TIMESTAMP
                                                                                        or FLAG_HAS_CTRLEXT_ON_LOAD
                                                                                        or FLAG_HAS_AMT
                                                                                        or FLAG_HAS_FLASH
                                                                                        or FLAG_HAS_JUMBO_FRAMES
                                                                                        or FLAG_APME_IN_WUC,
                                                                   flags2            =>    FLAG2_HAS_PHY_STATS
                                                                                        or FLAG2_HAS_EEE,
                                                                   pba               => 26,
                                                                   max_hw_frame_size => 9022,
                                                                   get_variants      => e1000_get_variants_ich8lan'Access,
                                                                   mac_ops           => ich8_mac_ops              'Access,
                                                                   phy_ops           => ich8_phy_ops              'Access,
                                                                   nvm_ops           => spt_nvm_ops               'Access);
   ----------------------
   --- e1000_pch_adp_info
   --

   e1000_pch_adp_info : aliased constant Devices.e1000e.Base.e1000_info.item := (mac               => Devices.e1000e.Hardware.e1000_pch_adp,
                                                                   flags             =>    FLAG_IS_ICH
                                                                                        or FLAG_HAS_WOL
                                                                                        or FLAG_HAS_HW_TIMESTAMP
                                                                                        or FLAG_HAS_CTRLEXT_ON_LOAD
                                                                                        or FLAG_HAS_AMT
                                                                                        or FLAG_HAS_FLASH
                                                                                        or FLAG_HAS_JUMBO_FRAMES
                                                                                        or FLAG_APME_IN_WUC,
                                                                   flags2            =>    FLAG2_HAS_PHY_STATS
                                                                                        or FLAG2_HAS_EEE,
                                                                   pba               => 26,
                                                                   max_hw_frame_size => 9022,
                                                                   get_variants      => e1000_get_variants_ich8lan'Access,
                                                                   mac_ops           => ich8_mac_ops              'Access,
                                                                   phy_ops           => ich8_phy_ops              'Access,
                                                                   nvm_ops           => spt_nvm_ops               'Access);
   ----------------------
   --- e1000_pch_mtp_info
   --

   e1000_pch_mtp_info : aliased constant Devices.e1000e.Base.e1000_info.item := (mac               => Devices.e1000e.Hardware.e1000_pch_mtp,
                                                                   flags             =>    FLAG_IS_ICH
                                                                                        or FLAG_HAS_WOL
                                                                                        or FLAG_HAS_HW_TIMESTAMP
                                                                                        or FLAG_HAS_CTRLEXT_ON_LOAD
                                                                                        or FLAG_HAS_AMT
                                                                                        or FLAG_HAS_FLASH
                                                                                        or FLAG_HAS_JUMBO_FRAMES
                                                                                        or FLAG_APME_IN_WUC,
                                                                   flags2            =>    FLAG2_HAS_PHY_STATS
                                                                                        or FLAG2_HAS_EEE,
                                                                   pba               => 26,
                                                                   max_hw_frame_size => 9022,
                                                                   get_variants      => e1000_get_variants_ich8lan'Access,
                                                                   mac_ops           => ich8_mac_ops              'Access,
                                                                   phy_ops           => ich8_phy_ops              'Access,
                                                                   nvm_ops           => spt_nvm_ops               'Access);
end Devices.e1000e.Ich8Lan;
