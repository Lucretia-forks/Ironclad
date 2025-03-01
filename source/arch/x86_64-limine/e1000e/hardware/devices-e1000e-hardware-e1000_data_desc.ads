with
     Devices.e1000e.Core;


package Devices.e1000e.Hardware.e1000_data_desc
--
-- Offload data descriptor.
--
is

   ---------
   --- Lower
   --

   type lower_Flags is
      record
         length      : aliased Devices.e1000e.Core.le16;     -- Data buffer length.
         typ_len_ext : aliased Devices.e1000e.Core.u8;
         cmd         : aliased Devices.e1000e.Core.u8;
      end record;



   type lower_union_Variant is (data_variant, flags_variant);

   type lower_union (union_Variant : lower_union_Variant := lower_union_Variant'First) is
      record
         case union_Variant
         is
            when data_variant  =>   data  : aliased Devices.e1000e.Core.le32;
            when flags_variant =>   flags : aliased lower_Flags;
         end case;
      end record;

   pragma Unchecked_Union (lower_union);



   ---------
   --- Upper
   --

   type upper_Fields is
      record
         status  : aliased Devices.e1000e.Core.u8;       -- Descriptor status.
         popts   : aliased Devices.e1000e.Core.u8;       -- Packet Options.
         special : aliased Devices.e1000e.Core.le16;
      end record;


   type upper_union_Variant is (data_variant, fields_variant);

   type upper_Union (union_Variant : upper_union_Variant := upper_union_Variant'First) is
      record
         case union_Variant
         is
            when data_variant   =>   data   : aliased Devices.e1000e.Core.le32;
            when fields_variant =>   fields : aliased upper_Fields;
         end case;
      end record;

   pragma Unchecked_Union (upper_Union);




   --------
   --- Item
   --

   type Item is
      record
         buffer_addr : aliased Devices.e1000e.Core.le64;       -- Address of the descriptor's buffer address.
         lower       : aliased lower_union;
         upper       : aliased upper_Union;
      end record;


   -------------
   -- Item_Array
   --
   type Item_Array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_data_desc.Item;


end Devices.e1000e.Hardware.e1000_data_desc;
