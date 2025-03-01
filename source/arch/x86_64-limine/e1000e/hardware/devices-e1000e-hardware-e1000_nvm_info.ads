with
     Devices.e1000e.Hardware.e1000_nvm_operations,
     Devices.e1000e.Core;


package Devices.e1000e.Hardware.e1000_nvm_info
is
   -- Item
   --

   type Item is
      record
         ops             : aliased Devices.e1000e.Hardware.e1000_nvm_operations.Item;
         nvm_type        : aliased Devices.e1000e.Hardware.e1000_nvm_type;
         override        : aliased Devices.e1000e.Hardware.e1000_nvm_override;
         flash_bank_size : aliased Devices.e1000e.Core.u32;
         flash_base_addr : aliased Devices.e1000e.Core.u32;
         word_size       : aliased Devices.e1000e.Core.u16;
         delay_usec      : aliased Devices.e1000e.Core.u16;
         address_bits    : aliased Devices.e1000e.Core.u16;
         opcode_bits     : aliased Devices.e1000e.Core.u16;
         page_size       : aliased Devices.e1000e.Core.u16;
      end record;


   -- Item_Array
   --
   type Item_Array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_nvm_info.Item;


end Devices.e1000e.Hardware.e1000_nvm_info;
