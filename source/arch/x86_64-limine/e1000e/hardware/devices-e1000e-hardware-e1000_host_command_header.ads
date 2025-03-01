with
     Devices.e1000e.Core;


package Devices.e1000e.Hardware.e1000_host_command_header
--
-- Host Interface "Rev 1".
--
is
   -- Item
   --

   type Item is
      record
         command_id      : aliased Devices.e1000e.Core.u8;
         command_length  : aliased Devices.e1000e.Core.u8;
         command_options : aliased Devices.e1000e.Core.u8;
         checksum        : aliased Devices.e1000e.Core.u8;
      end record;


   -- Item_Array
   --
   type Item_Array is
     array
       (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_host_command_header.Item;


end Devices.e1000e.Hardware.e1000_host_command_header;
