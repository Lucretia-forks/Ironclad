with
     Devices.e1000e.Hardware.e1000_dev_spec_80003es2lan,
     Devices.e1000e.Hardware.e1000_dev_spec_82571,
     Devices.e1000e.Hardware.e1000_dev_spec_ich8lan;


package Devices.e1000e.Hardware.e1000_hw_dev_spec
is
   -- Item
   --

   type Item_variant is
     (e82571_variant, e80003es2lan_variant, ich8lan_variant);

   type Item (union_Variant : Item_variant := Item_variant'First) is
      record
         case union_Variant
         is
            when e82571_variant       =>   e82571       : aliased Devices.e1000e.Hardware.e1000_dev_spec_82571.Item;
            when e80003es2lan_variant =>   e80003es2lan : aliased Devices.e1000e.Hardware.e1000_dev_spec_80003es2lan.Item;
            when ich8lan_variant      =>   ich8lan      : aliased Devices.e1000e.Hardware.e1000_dev_spec_ich8lan.Item;
         end case;
      end record;

   pragma Unchecked_Union (Item);


   -- Item_Array
   --
   type Item_Array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_hw_dev_spec.Item;


end Devices.e1000e.Hardware.e1000_hw_dev_spec;
