with
     Devices.e1000e.Hardware.e1000_mac_operations,
     Devices.e1000e.Hardware.e1000_phy_operations,
     Devices.e1000e.Hardware.e1000_nvm_operations,
     Devices.e1000e.Base.get_variants_func,
     Devices.e1000e.Core;


package Devices.e1000e.Base.e1000_info
is

   -- Item
   --

   type Item is record
      mac               : aliased Devices.e1000e.Hardware.e1000_mac_type;
      flags             : aliased Interfaces.Unsigned_32;
      flags2            : aliased Interfaces.Unsigned_16;
      pba               : aliased Devices.e1000e.Core.u32;
      max_hw_frame_size : aliased Devices.e1000e.Core.u32;

      get_variants      : aliased Devices.e1000e.Base.get_variants_func.Item;

      mac_ops           : access constant Devices.e1000e.Hardware.e1000_mac_operations.item;
      phy_ops           : access constant Devices.e1000e.Hardware.e1000_phy_operations.item;
      nvm_ops           : access constant Devices.e1000e.Hardware.e1000_nvm_operations.item;
   end record;

   -- Item_Array
   --
   type Item_Array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Base.e1000_info.Item;


   type View is access constant Item;


end Devices.e1000e.Base.e1000_info;
