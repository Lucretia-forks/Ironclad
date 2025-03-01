with
     Devices.e1000e.Core,
     Devices.e1000e.Defines,
     Interfaces.C;


package Devices.e1000e.Base
--
--  Linux PRO/1000 Ethernet Driver main spec.
--
is
   use Interfaces;


   ------------
   --- Logging.
   --

   procedure e_dbg    (Message : in String);
   procedure e_err    (Message : in String);
   procedure e_info   (Message : in String);
   procedure e_warn   (Message : in String);
   procedure e_notice (Message : in String);



   -- e1000_boards
   --
   type e1000_boards is
     (board_82571,       board_82572,   board_82573,   board_82574,    board_82583,
      board_80003es2lan, board_ich8lan, board_ich9lan, board_ich10lan, board_pchlan,
      board_pch2lan,     board_pch_lpt, board_pch_spt, board_pch_cnp,  board_pch_tgp,
      board_pch_adp,     board_pch_mtp);

   pragma Convention (C, e1000_boards);

   type e1000_boards_array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Base.e1000_boards;


   -- e1000_state_t
   --
   type e1000_state_t is
     (E1000_TESTING, E1000_RESETTING, E1000_ACCESS_SHARED_RESOURCE, E1000_DOWN);

   pragma Convention (C, e1000_state_t);

   type e1000_state_t_array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Base.e1000_state_t;


   -- latency_range
   --
   type latency_range is
     (lowest_latency, low_latency, bulk_latency, latency_invalid);

   for latency_range use
     (lowest_latency  => 0, low_latency => 1, bulk_latency => 2, latency_invalid => 255);

   pragma Convention (C, latency_range);

   type latency_range_array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Base.latency_range;



   -- Interrupt modes, as used by the IntMode parameter.
   --
   E1000E_INT_MODE_LEGACY        : constant := 0;
   E1000E_INT_MODE_MSI           : constant := 1;
   E1000E_INT_MODE_MSIX          : constant := 2;


   -- Tx/Rx descriptor defines.
   --
   E1000_DEFAULT_TXD             : constant := 256;
   E1000_MAX_TXD                 : constant := 4_096;
   E1000_MIN_TXD                 : constant := 64;


   E1000_DEFAULT_RXD             : constant := 256;
   E1000_MAX_RXD                 : constant := 4_096;
   E1000_MIN_RXD                 : constant := 64;

   E1000_MIN_ITR_USECS           : constant := 10;             -- 100000 irq/sec.
   E1000_MAX_ITR_USECS           : constant := 10_000;         -- 100    irq/sec.

   E1000_FC_PAUSE_TIME           : constant := 16#680#;        -- 858 uSec.


   -- How many Tx Descriptors do we need to call netif_wake_queue ?
   -- How many Rx Buffers do we bundle into one write to the hardware ?
   --
   E1000_RX_BUFFER_WRITE         : constant := 16;             -- Must be power of 2.


   AUTO_ALL_MODES                : constant := 0;
   E1000_EEPROM_APME             : constant := 16#400#;

   E1000_MNG_VLAN_NONE           : constant := Devices.e1000e.Core.U16'Last;     -- Was '-1' in C.

   DEFAULT_JUMBO                 : constant := 9_234;

   LINK_TIMEOUT                  : constant := 100;            -- Time to wait before putting the device into D3 if there's no link (in ms).


   -- Count for polling __E1000_RESET condition every 10-20msec.
   -- Experimentation has shown the reset can take approximately 210msec.
   --
   E1000_CHECK_RESET_COUNT       : constant := 25;


   PCICFG_DESC_RING_STATUS       : constant := 16#e4#;
   FLUSH_DESC_REQUIRED           : constant := 16#100#;

   -- In the case of WTHRESH, it appears at least the 82571/2 hardware
   -- writes back 4 descriptors when WTHRESH=5, and 3 descriptors when
   -- WTHRESH=4, so a setting of 5 gives the most efficient bus
   -- utilization but to avoid possible Tx stalls, set it to 1.
   --
   E1000_TXDCTL_DMA_BURST_ENABLE : aliased constant Interfaces.Unsigned_32 :=    Devices.e1000e.Defines.E1000_TXDCTL_GRAN           -- Set descriptor granularity.
                                                                              or Devices.e1000e.Defines.E1000_TXDCTL_COUNT_DESC
                                                                              or shift_Left (1, 16)                  -- WThresh must be +1 more than desired.
                                                                              or shift_Left (1,  8)                  -- HThresh.
                                                                              or 16#1f#;                             -- PThresh.

   E1000_RXDCTL_DMA_BURST_ENABLE : aliased constant Interfaces.Unsigned_32 :=    16#01000000#                        -- Set descriptor granularity.
                                                                              or shift_Left (4, 16)                  -- Set writeback threshold.
                                                                              or shift_Left (4,  8)                  -- Set prefetch threshold.
                                                                              or 16#20#;                             -- Set HThresh.
   E1000_TIDV_FPD : constant Devices.e1000e.Core.u32 := Devices.e1000e.Core.BIT (31);
   E1000_RDTR_FPD : constant Devices.e1000e.Core.u32 := Devices.e1000e.Core.BIT (31);



   -- The system time is maintained by a 64-bit counter comprised of the 32-bit
   -- SYSTIMH and SYSTIML registers.  How the counter increments (and therefore
   -- its resolution) is based on the contents of the TIMINCA register - it
   -- increments every incperiod (bits 31:24) clock ticks by incvalue (bits 23:0).
   -- For the best accuracy, the incperiod should be as small as possible.  The
   -- incvalue is scaled by a factor as large as possible (while still fitting
   -- in bits 23:0) so that relatively small clock corrections can be made.
   --
   -- As a result, a shift of INCVALUE_SHIFT_n is used to fit a value of
   -- INCVALUE_n into the TIMINCA register allowing 32+8+(24-INCVALUE_SHIFT_n)
   -- bits to count nanoseconds leaving the rest for fractional nonseconds.
   --
   -- Any given INCVALUE also has an associated maximum adjustment value. This
   -- maximum adjustment value is the largest increase (or decrease) which can be
   -- safely applied without overflowing the INCVALUE. Since INCVALUE has
   -- a maximum range of 24 bits, its largest value is 0xFFFFFF.
   --
   -- To understand where the maximum value comes from, consider the following
   -- equation:
   --
   --   new_incval = base_incval + (base_incval * adjustment) / 1billion
   --
   -- To avoid overflow that means:
   --   max_incval = base_incval + (base_incval * max_adj) / billion
   --
   -- Re-arranging:
   --   max_adj = floor(((max_incval - base_incval) * 1billion) / 1billion)
   --
   INCVALUE_96MHZ                 : constant := 125;
   INCVALUE_SHIFT_96MHZ           : constant := 17;
   INCPERIOD_SHIFT_96MHZ          : constant := 2;
   INCPERIOD_96MHZ                : constant Devices.e1000e.Core.u32 := shift_Right (12, INCPERIOD_SHIFT_96MHZ);
   MAX_PPB_96MHZ                  : constant := 23_999_900;      -- 23,999,900 ppb.

   INCVALUE_25MHZ                 : constant := 40;
   INCVALUE_SHIFT_25MHZ           : constant := 18;
   INCPERIOD_25MHZ                : constant := 1;
   MAX_PPB_25MHZ                  : constant := 599_999_900;     -- 599,999,900 ppb.

   INCVALUE_24MHZ                 : constant := 125;
   INCVALUE_SHIFT_24MHZ           : constant := 14;
   INCPERIOD_24MHZ                : constant := 3;
   MAX_PPB_24MHZ                  : constant := 999_999_999;     -- 999,999,999 ppb.

   INCVALUE_38400KHZ              : constant := 26;
   INCVALUE_SHIFT_38400KHZ        : constant := 19;
   INCPERIOD_38400KHZ             : constant := 1;
   MAX_PPB_38400KHZ               : constant := 230_769_100;     -- 230,769,100 ppb.


   -- Another drawback of scaling the incvalue by a large factor is the
   -- 64-bit SYSTIM register overflows more quickly.  This is dealt with
   -- by simply reading the clock before it overflows.
   --
   -- Clock ns bits  Overflows after
   -- ~~~~~~   ~~~~~~~  ~~~~~~~~~~~~~~~
   -- 96MHz 47-bit   2^(47-INCPERIOD_SHIFT_96MHz) / 10^9 / 3600 = 9.77 hrs
   -- 25MHz 46-bit   2^46 / 10^9 / 3600 = 19.55 hours
   --


   --- TODO: Which of these (all defined in linux kernel headers) to use ?
   --
   --  HZ : constant :=  100;
   --  HZ : constant :=  300;
   HZ : constant := 1000;
   --  HZ : constant := 1024;


   E1000_SYSTIM_OVERFLOW_PERIOD   : constant := (HZ * 60 * 60 * 4);
   E1000_MAX_82574_SYSTIM_REREADS : constant := 50;
   E1000_82574_SYSTIM_EPSILON     : aliased constant interfaces.Unsigned_64 := shift_Left (1, 35);


   -- Hardware capability, feature, and workaround flags.
   --
   use Devices.e1000e.Core;

   FLAG_HAS_AMT                     : constant Unsigned_32 := BIT (0);
   FLAG_HAS_FLASH                   : constant Unsigned_32 := BIT (1);
   FLAG_HAS_HW_VLAN_FILTER          : constant Unsigned_32 := BIT (2);
   FLAG_HAS_WOL                     : constant Unsigned_32 := BIT (3);
   -- reserved BIT (4)
   FLAG_HAS_CTRLEXT_ON_LOAD         : constant Unsigned_32 := BIT (5);
   FLAG_HAS_SWSM_ON_LOAD            : constant Unsigned_32 := BIT (6);
   FLAG_HAS_JUMBO_FRAMES            : constant Unsigned_32 := BIT (7);
   FLAG_READ_ONLY_NVM               : constant Unsigned_32 := BIT (8);
   FLAG_IS_ICH                      : constant Unsigned_32 := BIT (9);
   FLAG_HAS_MSIX                    : constant Unsigned_32 := BIT (10);
   FLAG_HAS_SMART_POWER_DOWN        : constant Unsigned_32 := BIT (11);
   FLAG_IS_QUAD_PORT_A              : constant Unsigned_32 := BIT (12);
   FLAG_IS_QUAD_PORT                : constant Unsigned_32 := BIT (13);
   FLAG_HAS_HW_TIMESTAMP            : constant Unsigned_32 := BIT (14);
   FLAG_APME_IN_WUC                 : constant Unsigned_32 := BIT (15);
   FLAG_APME_IN_CTRL3               : constant Unsigned_32 := BIT (16);
   FLAG_APME_CHECK_PORT_B           : constant Unsigned_32 := BIT (17);
   FLAG_DISABLE_FC_PAUSE_TIME       : constant Unsigned_32 := BIT (18);
   FLAG_NO_WAKE_UCAST               : constant Unsigned_32 := BIT (19);
   FLAG_MNG_PT_ENABLED              : constant Unsigned_32 := BIT (20);
   FLAG_RESET_OVERWRITES_LAA        : constant Unsigned_32 := BIT (21);
   FLAG_TARC_SPEED_MODE_BIT         : constant Unsigned_32 := BIT (22);
   FLAG_TARC_SET_BIT_ZERO           : constant Unsigned_32 := BIT (23);
   FLAG_RX_NEEDS_RESTART            : constant Unsigned_32 := BIT (24);
   FLAG_LSC_GIG_SPEED_DROP          : constant Unsigned_32 := BIT (25);
   FLAG_SMART_POWER_DOWN            : constant Unsigned_32 := BIT (26);
   FLAG_MSI_ENABLED                 : constant Unsigned_32 := BIT (27);
   -- reserved BIT (28)
   FLAG_TSO_FORCE                   : constant Unsigned_32 := BIT (29);
   FLAG_RESTART_NOW                 : constant Unsigned_32 := BIT (30);
   FLAG_MSI_TEST_FAILED             : constant Unsigned_32 := BIT (31);


   FLAG2_CRC_STRIPPING              : constant Unsigned_16 := BIT (0);
   FLAG2_HAS_PHY_WAKEUP             : constant Unsigned_16 := BIT (1);
   FLAG2_IS_DISCARDING              : constant Unsigned_16 := BIT (2);
   FLAG2_DISABLE_ASPM_L1            : constant Unsigned_16 := BIT (3);
   FLAG2_HAS_PHY_STATS              : constant Unsigned_16 := BIT (4);
   FLAG2_HAS_EEE                    : constant Unsigned_16 := BIT (5);
   FLAG2_DMA_BURST                  : constant Unsigned_16 := BIT (6);
   FLAG2_DISABLE_ASPM_L0S           : constant Unsigned_16 := BIT (7);
   FLAG2_DISABLE_AIM                : constant Unsigned_16 := BIT (8);
   FLAG2_CHECK_PHY_HANG             : constant Unsigned_16 := BIT (9);
   FLAG2_NO_DISABLE_RX              : constant Unsigned_16 := BIT (10);
   FLAG2_PCIM2PCI_ARBITER_WA        : constant Unsigned_16 := BIT (11);
   FLAG2_DFLT_CRC_STRIPPING         : constant Unsigned_16 := BIT (12);
   FLAG2_CHECK_RX_HWTSTAMP          : constant Unsigned_16 := BIT (13);
   FLAG2_CHECK_SYSTIM_OVERFLOW      : constant Unsigned_16 := BIT (14);
   FLAG2_ENABLE_S0IX_FLOWS          : constant Unsigned_16 := BIT (15);



   e1000e_driver_name               : constant String      := "e1000e";

   COPYBREAK_DEFAULT                : constant                      := 256;
   copybreak                        : aliased Interfaces.C.unsigned := COPYBREAK_DEFAULT;


end Devices.e1000e.Base;
