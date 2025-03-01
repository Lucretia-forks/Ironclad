with
     Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u16_array_arg3_u16_array_return_s32,
     Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u8_array_arg3_u32_return_int,
     Devices.e1000e.Hardware.func_arg1_e1000_hw_return_bool,
     Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32,
     Devices.e1000e.Hardware.func_arg1_e1000_hw_return_u32,
     Devices.e1000e.Hardware.proc_arg1_e1000_hw,
     Devices.e1000e.Hardware.proc_arg1_e1000_hw_arg2_u32_arg3_u32,
     Devices.e1000e.Hardware.proc_arg1_e1000_hw_arg2_u8_array_arg3_u32;


package Devices.e1000e.Hardware.e1000_mac_operations
--
-- Function pointers for the MAC.
--
is
   -- Item
   --
   type Item is
      record
         id_led_init              : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         blink_led                : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         check_mng_mode           : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_bool.Item;
         check_for_link           : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         cleanup_led              : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         clear_hw_cntrs           : aliased Devices.e1000e.Hardware.proc_arg1_e1000_hw.Item;
         clear_vfta               : aliased Devices.e1000e.Hardware.proc_arg1_e1000_hw.Item;
         get_bus_info             : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         set_lan_id               : aliased Devices.e1000e.Hardware.proc_arg1_e1000_hw.Item;
         get_link_up_info         : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u16_array_arg3_u16_array_return_s32.Item;
         led_on                   : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         led_off                  : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         update_mc_addr_list      : aliased Devices.e1000e.Hardware.proc_arg1_e1000_hw_arg2_u8_array_arg3_u32.Item;
         reset_hw                 : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         init_hw                  : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         setup_link               : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         setup_physical_interface : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         setup_led                : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         write_vfta               : aliased Devices.e1000e.Hardware.proc_arg1_e1000_hw_arg2_u32_arg3_u32.Item;
         config_collision_dist    : aliased Devices.e1000e.Hardware.proc_arg1_e1000_hw.Item;
         rar_set                  : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u8_array_arg3_u32_return_int.Item;
         read_mac_addr            : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         rar_get_count            : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_u32.Item;
      end record;


   -- Item_Array
   --
   type Item_Array is
     array
       (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_mac_operations.Item;


end Devices.e1000e.Hardware.e1000_mac_operations;
