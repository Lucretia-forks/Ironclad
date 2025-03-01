with
     Devices.e1000e.Core;


package Devices.e1000e.Hardware.e1000_dev_spec_82571
is


   -- Item
   --

   type Item is record
      laa_is_present : aliased Boolean;
      smb_counter    : aliased Devices.e1000e.Core.u32;
   end record;

   -- Item_Array
   --
   type Item_Array is
     array
       (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_dev_spec_82571.Item;


end Devices.e1000e.Hardware.e1000_dev_spec_82571;
