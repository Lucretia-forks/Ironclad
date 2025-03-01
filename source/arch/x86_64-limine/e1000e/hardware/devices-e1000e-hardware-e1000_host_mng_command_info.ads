with
     Devices.e1000e.Hardware.e1000_host_mng_command_header,
     Devices.e1000e.Core;


package Devices.e1000e.Hardware.e1000_host_mng_command_info
is
   -- Item
   --

   type Item is
      record
         command_header : aliased Devices.e1000e.Hardware.e1000_host_mng_command_header.Item;
         command_data   : aliased Devices.e1000e.Core.u8_array (0 .. 1_783);
      end record;


   -- Item_Array
   --
   type Item_Array is
     array
       (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_host_mng_command_info.Item;


end Devices.e1000e.Hardware.e1000_host_mng_command_info;
