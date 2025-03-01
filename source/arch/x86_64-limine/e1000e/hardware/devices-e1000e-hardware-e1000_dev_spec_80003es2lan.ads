package Devices.e1000e.Hardware.e1000_dev_spec_80003es2lan
is

   -- Item
   --

   type Item is
      record
         mdic_wa_enable : aliased Boolean;
      end record;


   -- Item_Array
   --
   type Item_Array is
     array
       (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_dev_spec_80003es2lan.Item;


end Devices.e1000e.Hardware.e1000_dev_spec_80003es2lan;
