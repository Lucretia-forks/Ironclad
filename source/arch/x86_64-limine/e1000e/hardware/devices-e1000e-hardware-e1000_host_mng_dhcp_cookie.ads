with
     Devices.e1000e.Core;


package Devices.e1000e.Hardware.e1000_host_mng_dhcp_cookie
is
   -- Item
   --

   type Item is
      record
         signature : aliased Devices.e1000e.Core.u32;
         status    : aliased Devices.e1000e.Core.u8;
         reserved0 : aliased Devices.e1000e.Core.u8;
         vlan_id   : aliased Devices.e1000e.Core.u16;
         reserved1 : aliased Devices.e1000e.Core.u32;
         reserved2 : aliased Devices.e1000e.Core.u16;
         reserved3 : aliased Devices.e1000e.Core.u8;
         checksum  : aliased Devices.e1000e.Core.u8;
      end record;


   -- Item_Array
   --
   type Item_Array is
     array
       (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_host_mng_dhcp_cookie.Item;


end Devices.e1000e.Hardware.e1000_host_mng_dhcp_cookie;
