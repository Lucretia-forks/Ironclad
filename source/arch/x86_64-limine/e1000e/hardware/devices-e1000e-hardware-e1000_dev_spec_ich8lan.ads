with
     Devices.e1000e.Hardware.e1000_shadow_ram,
     Devices.e1000e.Core;


package Devices.e1000e.Hardware.e1000_dev_spec_ich8lan
is
   -- Item
   --

   type Item is
      record
         kmrn_lock_loss_workaround_enabled : aliased Boolean;
         shadow_ram                        : aliased Devices.e1000e.Hardware.e1000_shadow_ram.Item_Array (0 .. 2_047);
         nvm_k1_enabled                    : aliased Boolean;
         eee_disable                       : aliased Boolean;
         eee_lp_ability                    : aliased Devices.e1000e.Core.u16;
         ulp_state                         : aliased Devices.e1000e.Hardware.e1000_ulp_state;
      end record;


   -- Item_Array
   --
   type Item_Array is
     array
       (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_dev_spec_ich8lan.Item;


end Devices.e1000e.Hardware.e1000_dev_spec_ich8lan;
