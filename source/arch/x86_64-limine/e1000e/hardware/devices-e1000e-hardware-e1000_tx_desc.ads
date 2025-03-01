with
     Devices.e1000e.Core;


package Devices.e1000e.Hardware.e1000_tx_desc
--
-- Transmit Descriptor
--
is
   ---------
   --- Lower
   --

   type flags_struct is
      record
         length : aliased Devices.e1000e.Core.le16;     -- Data buffer length.
         cso    : aliased Devices.e1000e.Core.u8;       -- Checksum offset.
         cmd    : aliased Devices.e1000e.Core.u8;       -- Descriptor control.
      end record;



   type lower_union_variant is (data_variant, flags_variant);

   type lower_union (union_Variant : lower_union_variant := lower_union_variant'First) is
      record
         case union_Variant
         is
            when data_variant  =>   data  : aliased Devices.e1000e.Core.le32;
            when flags_variant =>   flags : aliased flags_struct;
         end case;
      end record;

   pragma Unchecked_Union (lower_union);


   ---------
   --- Upper
   --

   type fields_struct is
      record
         status  : aliased Devices.e1000e.Core.u8;       -- Descriptor status.
         css     : aliased Devices.e1000e.Core.u8;       -- Checksum start.
         special : aliased Devices.e1000e.Core.le16;
      end record;



   type upper_union_variant is (data_variant, fields_variant);

   type upper_union (union_Variant : upper_union_variant := upper_union_variant'First) is
      record
         case union_Variant
         is
            when data_variant   =>   data   : aliased Devices.e1000e.Core.le32;
            when fields_variant =>   fields : aliased fields_struct;
         end case;
      end record;

   pragma Unchecked_Union (upper_union);



   -------
   -- Item
   --
   type Item is
      record
         buffer_addr : aliased Devices.e1000e.Core.le64;       -- Address of the descriptor's data buffer.
         lower       : aliased lower_union;
         upper       : aliased upper_union;
      end record;



   -- Item_Array
   --
   type Item_Array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_tx_desc.Item;


end Devices.e1000e.Hardware.e1000_tx_desc;
