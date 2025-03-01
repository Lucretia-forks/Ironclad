with
     Interfaces.C,
     Devices.e1000e.Hardware.e1000_hw,
     Devices.e1000e.Core.Pointers;
use
     Interfaces.C;


package Devices.e1000e.Media_Access_Control
is

   subtype e1000_hw is Devices.e1000e.Hardware.e1000_hw.item;


   ---------------
   --- Subprograms
   --

   function e1000e_blink_led_generic
     (hw : access e1000_hw) return Devices.e1000e.Core.s32;

   function e1000e_check_for_copper_link
     (hw : access e1000_hw) return Devices.e1000e.Core.s32;

   function e1000e_check_for_fiber_link
     (Hw : access E1000_Hw) return Devices.e1000e.Core.s32;

   function e1000e_check_for_serdes_link
     (hw : access e1000_hw) return Devices.e1000e.Core.s32;

   function e1000e_cleanup_led_generic
     (hw : access e1000_hw) return Devices.e1000e.Core.s32;

   function e1000e_config_fc_after_link_up
     (hw : access e1000_hw) return Devices.e1000e.Core.s32;

   function e1000e_disable_pcie_master
     (hw : access e1000_hw) return Devices.e1000e.Core.s32;

   function e1000e_force_mac_fc
     (hw : access e1000_hw) return Devices.e1000e.Core.s32;

   function e1000e_get_auto_rd_done
     (hw : access e1000_hw) return Devices.e1000e.Core.s32;

   function e1000e_get_bus_info_pcie
     (hw : access e1000_hw) return Devices.e1000e.Core.s32;

   procedure e1000_set_lan_id_single_port
     (hw : access e1000_hw);

   function e1000e_get_hw_semaphore
     (hw : access e1000_hw) return Devices.e1000e.Core.s32;

   function e1000e_get_speed_and_duplex_copper
     (hw     : access e1000_hw;
      speed  : in     Devices.e1000e.Core.Pointers.u16_Pointer;
      duplex : in     Devices.e1000e.Core.Pointers.u16_Pointer) return Devices.e1000e.Core.s32;

   function e1000e_get_speed_and_duplex_fiber_serdes
     (hw     : access e1000_hw;
      speed  : in     Devices.e1000e.Core.Pointers.u16_Pointer;
      duplex : in     Devices.e1000e.Core.Pointers.u16_Pointer) return Devices.e1000e.Core.s32;

   function e1000e_id_led_init_generic
     (hw : access e1000_hw) return Devices.e1000e.Core.s32;

   function e1000e_led_on_generic
     (hw : access e1000_hw) return Devices.e1000e.Core.s32;

   function e1000e_led_off_generic
     (hw : access e1000_hw) return Devices.e1000e.Core.s32;

   procedure e1000e_update_mc_addr_list_generic
     (hw            : access e1000_hw;
      mc_addr_list  : in     Devices.e1000e.Core.Pointers.u8_Pointer;
      mc_addr_count : in     Devices.e1000e.Core.u32);

   function e1000e_set_fc_watermarks
     (hw : access e1000_hw) return Devices.e1000e.Core.s32;

   function e1000e_setup_fiber_serdes_link
     (hw : access e1000_hw) return Devices.e1000e.Core.s32;

   function e1000e_setup_led_generic
     (hw : access e1000_hw) return Devices.e1000e.Core.s32;

   function e1000e_setup_link_generic
     (hw : access e1000_hw) return Devices.e1000e.Core.s32;

   procedure e1000e_clear_hw_cntrs_base
     (hw : access e1000_hw);

   procedure e1000_clear_vfta_generic
     (hw : access e1000_hw);

   procedure e1000e_init_rx_addrs
     (hw        : access e1000_hw;
      rar_count : in     Devices.e1000e.Core.u16);

   procedure e1000e_put_hw_semaphore
     (hw : access e1000_hw);

   function e1000_check_alt_mac_addr_generic
     (hw : access e1000_hw) return Devices.e1000e.Core.s32;

   procedure e1000e_reset_adaptive
     (hw : access e1000_hw);

   procedure e1000e_set_pcie_no_snoop
     (hw       : access e1000_hw;
      no_snoop : in     Devices.e1000e.Core.u32);

   procedure e1000e_update_adaptive
     (hw : access e1000_hw);

   procedure e1000_write_vfta_generic
     (hw     : access e1000_hw;
      offset : in     Devices.e1000e.Core.u32;
      value  : in     Devices.e1000e.Core.u32);

   procedure e1000_set_lan_id_multi_port_pcie
     (hw : access e1000_hw);

   function e1000e_rar_get_count_generic
     (hw : access e1000_hw) return Devices.e1000e.Core.u32;

   function e1000e_rar_set_generic
     (hw    : access e1000_hw;
      addr  : in     Devices.e1000e.Core.Pointers.u8_Pointer;
      index : in     Devices.e1000e.Core.u32) return Interfaces.C.int;

   procedure e1000e_config_collision_dist_generic
     (hw : access e1000_hw);


end Devices.e1000e.Media_Access_Control;
