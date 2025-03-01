limited
with
     Devices.e1000e.Hardware.e1000_hw;


package Devices.e1000e.Hardware.proc_arg1_e1000_hw
is
   -- Item
   --
   type Item is access
     procedure (arg_1 : access Devices.e1000e.Hardware.e1000_hw.Item);


   -- Item_Array
   --
   type Item_Array is
     array
       (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.proc_arg1_e1000_hw.Item;


end Devices.e1000e.Hardware.proc_arg1_e1000_hw;
