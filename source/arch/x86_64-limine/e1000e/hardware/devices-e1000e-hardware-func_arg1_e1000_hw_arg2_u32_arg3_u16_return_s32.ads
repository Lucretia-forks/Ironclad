with
     Devices.e1000e.Core;

limited
with
     Devices.e1000e.Hardware.e1000_hw;


package Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u32_arg3_u16_return_s32
is
   -- Item
   --
   type Item is
     access
       function
         (arg_1 : access Devices.e1000e.Hardware.e1000_hw.Item;
          arg_2 : in     Devices.e1000e.Core.u32;
          arg_3 : in     Devices.e1000e.Core.u16) return Devices.e1000e.Core.s32;


   -- Item_Array
   --
   type Item_Array is
     array
       (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u32_arg3_u16_return_s32.Item;


end Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u32_arg3_u16_return_s32;
