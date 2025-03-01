with
     Devices.e1000e.Core;


package Devices.e1000e.Hardware.e1000_phy_stats
is
   -- Item
   --
   type Item is
      record
         idle_errors    : aliased Devices.e1000e.Core.u32;
         receive_errors : aliased Devices.e1000e.Core.u32;
      end record;


   -- Item_Array
   --
   type Item_Array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_phy_stats.Item;


end Devices.e1000e.Hardware.e1000_phy_stats;
