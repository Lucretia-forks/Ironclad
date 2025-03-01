with
     Devices.e1000e.Core;


package Devices.e1000e.Hardware.e1000_shadow_ram
is
   -- Item
   --
   type Item is
      record
         value    : aliased Devices.e1000e.Core.u16;
         modified : aliased Boolean;
      end record;


   -- Item_Array
   --
   type Item_Array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_shadow_ram.Item;


end Devices.e1000e.Hardware.e1000_shadow_ram;
