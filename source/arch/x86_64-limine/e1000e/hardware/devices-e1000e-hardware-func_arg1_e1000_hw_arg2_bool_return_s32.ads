with
     Devices.e1000e.Core;

limited
with
     Devices.e1000e.Hardware.e1000_hw;


package Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_bool_return_s32
is
   -- Item
   --
   type Item is
     access
       function
         (arg_1 : access Devices.e1000e.Hardware.e1000_hw.Item;
          arg_2 : in     Boolean) return Devices.e1000e.Core.S32;


   -- Item_Array
   --
   type Item_Array is
     array
       (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_bool_return_s32.Item;


end Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_bool_return_s32;
