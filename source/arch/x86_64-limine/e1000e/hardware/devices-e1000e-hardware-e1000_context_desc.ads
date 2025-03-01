with
     Devices.e1000e.Core;


package Devices.e1000e.Hardware.e1000_context_desc
--
-- Offload Context Descriptor.
--
is

   ----------------
   --- Lower setup.
   --

   type ip_fields_Struct is
      record
         ipcss : aliased Devices.e1000e.Core.u8;       -- IP checksum start.
         ipcso : aliased Devices.e1000e.Core.u8;       -- IP checksum offset.
         ipcse : aliased Devices.e1000e.Core.le16;     -- IP checksum end.
      end record;



   type lower_setup_union_Variant is (ip_config_variant, ip_fields_variant);

   type lower_setup_union (union_Variant : lower_setup_union_Variant := lower_setup_union_Variant'First) is
      record
         case union_Variant
         is
            when ip_config_variant =>   ip_config : aliased Devices.e1000e.Core.le32;
            when ip_fields_variant =>   ip_fields : aliased ip_fields_Struct;
         end case;
      end record;

   pragma Unchecked_Union (lower_setup_union);




   ----------------
   --- Upper setup.
   --

   type tcp_fields_struct is
      record
         tucss : aliased Devices.e1000e.Core.u8;       -- TCP checksum start.
         tucso : aliased Devices.e1000e.Core.u8;       -- TCP checksum offset.
         tucse : aliased Devices.e1000e.Core.le16;     -- TCP checksum end.
      end record;


   type upper_setup_Variant is (tcp_config_variant, tcp_fields_variant);

   type upper_setup_union (union_Variant : upper_setup_Variant := upper_setup_Variant'First) is
      record
         case union_Variant
         is
            when tcp_config_variant =>   tcp_config : aliased Devices.e1000e.Core.le32;
            when tcp_fields_variant =>   tcp_fields : aliased tcp_fields_struct;
         end case;
      end record;

   pragma Unchecked_Union (upper_setup_union);



   ------------------
   --- Tcp seg setup.
   --

   type tcp_seg_setup_fields is
      record
         status  : aliased Devices.e1000e.Core.u8;       -- Descriptor status.
         hdr_len : aliased Devices.e1000e.Core.u8;       -- Header length.
         mss     : aliased Devices.e1000e.Core.le16;     -- Maximum segment size.
      end record;


   type tcp_seg_setup_Variant is (data_variant, fields_variant);

   type tcp_seg_setup_union (union_Variant : tcp_seg_setup_Variant := tcp_seg_setup_Variant'First) is
      record
         case union_Variant
         is
            when data_variant   =>   data   : aliased Devices.e1000e.Core.le32;
            when fields_variant =>   fields : aliased tcp_seg_setup_fields;
         end case;
      end record;

   pragma Unchecked_Union (tcp_seg_setup_union);


   --------
   --- Item
   --

   type Item is
      record
         lower_setup    : aliased lower_setup_union;
         upper_setup    : aliased upper_setup_union;
         cmd_and_length : aliased Devices.e1000e.Core.le32;
         tcp_seg_setup  : aliased tcp_seg_setup_union;
      end record;


   -------------
   -- Item_Array
   --
   type Item_Array is
     array
       (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_context_desc.Item;


end Devices.e1000e.Hardware.e1000_context_desc;
