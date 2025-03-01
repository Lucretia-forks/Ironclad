with
     Devices.e1000e.Core;


package Devices.e1000e.Hardware.e1000_bus_info
is
   -- Item
   --

   type Item is
      record
         width : aliased Devices.e1000e.Hardware.e1000_bus_width;
         func  : aliased Devices.e1000e.Core.u16;
      end record;


   -- Item_Array
   --
   type Item_Array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_bus_info.Item;


end Devices.e1000e.Hardware.e1000_bus_info;
