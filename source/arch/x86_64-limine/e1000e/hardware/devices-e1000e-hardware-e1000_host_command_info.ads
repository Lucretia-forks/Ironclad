with
     Devices.e1000e.Hardware.e1000_host_command_header,
     Devices.e1000e.Core;


package Devices.e1000e.Hardware.e1000_host_command_info
is
   use type Interfaces.C.size_t;


   E1000_HI_MAX_DATA_LENGTH : constant := 252;


   -- Item
   --

   type Item is
      record
         command_header : aliased Devices.e1000e.Hardware.e1000_host_command_header.Item;
         command_data   : aliased Devices.e1000e.Core.u8_array (0 .. E1000_HI_MAX_DATA_LENGTH - 1);
      end record;


   -- Item_Array
   --
   type Item_Array is
     array
       (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_host_command_info.Item;


end Devices.e1000e.Hardware.e1000_host_command_info;
