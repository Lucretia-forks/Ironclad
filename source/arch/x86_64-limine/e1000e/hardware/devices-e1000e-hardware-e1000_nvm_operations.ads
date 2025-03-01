with
     Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u16_arg3_u16_arg4_u16_array_return_s32,
     Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u16_array_return_s32,
     Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32,
     Devices.e1000e.Hardware.proc_arg1_e1000_hw;


package Devices.e1000e.Hardware.e1000_nvm_operations
--
-- Subprogram pointers for the NVM.
--
is
   -- Item
   --
   type Item is
      record
         acquire           : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         read              : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u16_arg3_u16_arg4_u16_array_return_s32.Item;
         release           : aliased Devices.e1000e.Hardware.proc_arg1_e1000_hw.Item;
         reload            : aliased Devices.e1000e.Hardware.proc_arg1_e1000_hw.Item;
         update            : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         valid_led_default : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u16_array_return_s32.Item;
         validate          : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;
         write             : aliased Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u16_arg3_u16_arg4_u16_array_return_s32.Item;
      end record;


   -- Item_Array
   --
   type Item_Array is
     array
       (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_nvm_operations.Item;


end Devices.e1000e.Hardware.e1000_nvm_operations;
