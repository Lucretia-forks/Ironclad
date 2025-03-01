with
     Devices.e1000e.Core;


package Devices.e1000e.Hardware.e1000_rx_desc_extended
--
-- Receive Descriptor - Extended.
--
is
   use Devices.e1000e.Core;


   ---------------
   --- read_struct
   --

   type read_struct is
      record
         buffer_addr : aliased Devices.e1000e.Core.le64;
         reserved    : aliased Devices.e1000e.Core.le64;
      end record;


   -------------
   --- wb_struct
   --

   type csum_ip_struct is
      record
         ip_id : le16;     -- IP Id.
         csum  : le16;     -- Packet Checksum.
      end record;


   type hi_dword_variant is (rss_variant, csum_ip_variant);

   type hi_dword_union (union_Variant : hi_dword_variant := hi_dword_variant'First)
   is
      record
         case union_Variant
         is
            when rss_variant     =>   rss     : aliased Devices.e1000e.Core.le32;          -- RSS Hash.
            when csum_ip_variant =>   csum_ip : aliased csum_ip_struct;
         end case;
      end record;

   pragma Unchecked_Union (hi_dword_union);



   type lower_struct is
      record
         mrq      : aliased Devices.e1000e.Core.le32;         -- Receive Descriptor - Extended.
         hi_dword : aliased hi_dword_union;
      end record;


   type upper_struct is
      record
         status_error : aliased Devices.e1000e.Core.le32;     -- Ext status/error.
         length       : aliased Devices.e1000e.Core.le16;
         vlan         : aliased Devices.e1000e.Core.le16;     -- VLAN tag.
      end record;


   type wb_struct is
      record
         lower : aliased lower_struct;
         upper : aliased upper_struct;
      end record;


   -------
   -- Item
   --

   type Item_variant is (read_variant, wb_variant);

   type Item (union_Variant : Item_variant := Item_variant'First) is
      record
         case union_Variant
         is
            when read_variant =>   read : aliased read_struct;
            when wb_variant   =>   wb   : aliased wb_struct;        -- Writeback.
         end case;
      end record;

   pragma Unchecked_Union (Item);



   -- Item_Array
   --
   type Item_Array is
     array
       (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_rx_desc_extended.Item;


end Devices.e1000e.Hardware.e1000_rx_desc_extended;
