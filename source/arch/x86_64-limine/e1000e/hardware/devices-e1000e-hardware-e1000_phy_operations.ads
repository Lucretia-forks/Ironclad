with
     Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_bool_return_s32,
     Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u16_return_s32,
     Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u32_arg3_u16_array_return_s32,
     Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u32_arg3_u16_return_s32,
     Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32,
     Devices.e1000e.Hardware.proc_arg1_e1000_hw;


package Devices.e1000e.Hardware.e1000_phy_operations
--
-- When to use various PHY register access functions:
--
--                Func   Caller
--  Function      Does   Does    When to use
--  ~~~~~~~~~~~~  ~~~~~  ~~~~~~  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--  X_reg         L,P,A  n/a     for simple PHY reg accesses
--  X_reg_locked  P,A    L       for multiple accesses of different regs
--                               on different pages
--  X_reg_page    A      L,P     for multiple accesses of different regs
--                               on the same page
--
-- Where X=[read|write], L=locking, P=sets page, A=register access
--
is
   -- Item
   --
   type Item is
      record
         acquire            : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         cfg_on_link_up     : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         check_polarity     : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         check_reset_block  : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         commit             : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         force_speed_duplex : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         get_cfg_done       : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         get_cable_length   : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         get_info           : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         set_page           : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u16_return_s32.Item;
         read_reg           : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u32_arg3_u16_array_return_s32.Item;
         read_reg_locked    : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u32_arg3_u16_array_return_s32.Item;
         read_reg_page      : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u32_arg3_u16_array_return_s32.Item;
         release            : aliased Devices.e1000e.Hardware.proc_arg1_e1000_hw.Item;
         reset              : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         set_d0_lplu_state  : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_bool_return_s32.Item;
         set_d3_lplu_state  : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_bool_return_s32.Item;
         write_reg          : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u32_arg3_u16_return_s32.Item;
         write_reg_locked   : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u32_arg3_u16_return_s32.Item;
         write_reg_page     : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u32_arg3_u16_return_s32.Item;
         power_up           : aliased Devices.e1000e.Hardware.proc_arg1_e1000_hw.Item;
         power_down         : aliased Devices.e1000e.Hardware.proc_arg1_e1000_hw.Item;
      end record;


   -- Item_Array
   --
   type Item_Array is
     array
       (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_phy_operations.Item;


end Devices.e1000e.Hardware.e1000_phy_operations;
