with
     Devices.e1000e.Core.Pointers;

limited
with
     Devices.e1000e.Hardware.e1000_hw;


package Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u16_arg3_u16_arg4_u16_array_return_s32
is
   -- Item
   --
   type Item is
     access
       function
         (arg_1 : access Devices.e1000e.Hardware.e1000_hw.Item;
          arg_2 : in     Devices.e1000e.Core.u16;
          arg_3 : in     Devices.e1000e.Core.u16;
          arg_4 : in     Devices.e1000e.Core.Pointers.u16_Pointer) return Devices.e1000e.Core.S32;


   -- Item_Array
   --
   type Item_Array is
     array
       (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u16_arg3_u16_arg4_u16_array_return_s32.Item;


end Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u16_arg3_u16_arg4_u16_array_return_s32;
