with
     Devices.e1000e.Hardware.e1000_bus_info,
     Devices.e1000e.Hardware.e1000_fc_info,
     Devices.e1000e.Hardware.e1000_host_mng_dhcp_cookie,
     Devices.e1000e.Hardware.e1000_hw_dev_spec,
     Devices.e1000e.Hardware.e1000_mac_info,
     Devices.e1000e.Hardware.e1000_nvm_info,
     Devices.e1000e.Hardware.e1000_phy_info,
     Devices.e1000e.Core;

limited
with
     Devices.e1000e.Base.e1000_adapter;


package Devices.e1000e.Hardware.e1000_hw
is
   -- Item
   --

   type Item is
      record
         adapter       : access  Devices.e1000e.Base.e1000_adapter.item;
         hw_addr       : aliased Devices.e1000e.Core.void_ptr;
         flash_address : aliased Devices.e1000e.Core.void_ptr;
         mac           : aliased Devices.e1000e.Hardware.e1000_mac_info.Item;
         fc            : aliased Devices.e1000e.Hardware.e1000_fc_info.Item;
         phy           : aliased Devices.e1000e.Hardware.e1000_phy_info.Item;
         nvm           : aliased Devices.e1000e.Hardware.e1000_nvm_info.Item;
         bus           : aliased Devices.e1000e.Hardware.e1000_bus_info.Item;
         mng_cookie    : aliased Devices.e1000e.Hardware.e1000_host_mng_dhcp_cookie.Item;
         dev_spec      : aliased Devices.e1000e.Hardware.e1000_hw_dev_spec.Item;
      end record;


   -- Item_Array
   --
   type Item_Array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_hw.Item;


end Devices.e1000e.Hardware.e1000_hw;
