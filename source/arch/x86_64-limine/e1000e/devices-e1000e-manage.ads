with
     Devices.e1000e.Hardware.e1000_hw,
     Devices.e1000e.Core.Pointers;


package Devices.e1000e.Manage
is

   -- e1000_hw
   --
   subtype e1000_hw is Devices.e1000e.Hardware.e1000_hw.item;


   -- e1000_mng_mode
   --
   type e1000_mng_mode is (e1000_mng_mode_none,
                           e1000_mng_mode_asf,
                           e1000_mng_mode_pt,
                           e1000_mng_mode_ipmi,
                           e1000_mng_mode_host_if_only);


   E1000_FACTPS_MNGCG                   : constant := 16#2000_0000#;

   E1000_FWSM_MODE_MASK                 : constant := 16#e#;
   E1000_FWSM_MODE_SHIFT                : constant := 1;

   E1000_MNG_IAMT_MODE                  : constant := 16#3#;
   E1000_MNG_DHCP_COOKIE_LENGTH         : constant := 16#10#;
   E1000_MNG_DHCP_COOKIE_OFFSET         : constant := 16#6f0#;
   E1000_MNG_DHCP_COMMAND_TIMEOUT       : constant := 10;
   E1000_MNG_DHCP_TX_PAYLOAD_CMD        : constant := 64;
   E1000_MNG_DHCP_COOKIE_STATUS_PARSING : constant := 16#1#;
   E1000_MNG_DHCP_COOKIE_STATUS_VLAN    : constant := 16#2#;

   E1000_VFTA_ENTRY_SHIFT               : constant := 5;
   E1000_VFTA_ENTRY_MASK                : constant := 16#7f#;
   E1000_VFTA_ENTRY_BIT_SHIFT_MASK      : constant := 16#1f#;

   E1000_HICR_EN                        : constant := 16#1#;             -- Enable bit - RO.
   E1000_HICR_C                         : constant := 16#2#;             -- Driver sets this bit when done to put command in RAM.
   E1000_HICR_SV                        : constant := 16#4#;             -- Status Validity.
   E1000_HICR_FW_RESET_ENABLE           : constant := 16#40#;
   E1000_HICR_FW_RESET                  : constant := 16#80#;

   E1000_IAMT_SIGNATURE                 : constant := 16#544d_4149#;     -- Intel(R) Active Management Technology signature.



   ---------------
   --- Subprograms
   --

   function e1000e_check_mng_mode_generic
     (hw     : access e1000_hw) return Boolean;

   function e1000e_enable_tx_pkt_filtering
     (hw     : access E1000_Hw) return Boolean;

   function e1000e_mng_write_dhcp_info
     (hw     : access e1000_hw;
      buffer : in     Devices.e1000e.Core.Pointers.u8_Pointer;
      length : in     Devices.e1000e.Core.u16) return Devices.e1000e.Core.s32;

   function e1000e_enable_mng_pass_thru
     (hw     : access e1000_hw) return Boolean;


end Devices.e1000e.Manage;
