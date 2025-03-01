with
     Devices.e1000e.Core;


package Devices.e1000e.Hardware.e1000_rx_desc_packet_split
--
-- Receive Descriptor - Packet Split
--
is
   use Interfaces.C;


   MAX_PS_BUFFERS  : constant := 4;
   PS_PAGE_BUFFERS : constant := MAX_PS_BUFFERS - 1;     -- Number of packet split data buffers (not including the header buffer).


   --------
   --- Read
   --
   type read_struct is
      record
         buffer_addr : aliased Devices.e1000e.Core.le64_array (0 .. MAX_PS_BUFFERS - 1);     -- One buffer for protocol header(s), three data buffers.
      end record;



   ---------
   --- Lower
   --

   type csum_ip_struct is
      record
         ip_id : aliased Devices.e1000e.Core.le16;     -- IP id.
         csum  : aliased Devices.e1000e.Core.le16;     -- Packet Checksum.
      end record;



   type hi_dword_union_variant is (rss_variant, csum_ip_variant);

   type hi_dword_union (union_Variant : hi_dword_union_variant := hi_dword_union_variant'First) is
      record
         case union_Variant
         is
            when rss_variant     =>   rss     : aliased Devices.e1000e.Core.le32;          -- RSS Hash
            when csum_ip_variant =>   csum_ip : aliased csum_ip_struct;
         end case;
      end record;

   pragma Unchecked_Union (hi_dword_union);



   type lower_struct is
      record
         mrq      : aliased Devices.e1000e.Core.le32;           -- Multiple Rx Queues
         hi_dword : aliased hi_dword_union;
      end record;



   ----------
   --- Middle
   --

   type middle_struct is
      record
         status_error : aliased Devices.e1000e.Core.le32;     -- Ext status/error.
         length0      : aliased Devices.e1000e.Core.le16;     -- length of buffer 0.
         vlan         : aliased Devices.e1000e.Core.le16;     -- VLAN tag.
      end record;



   ---------
   --- Upper
   --

   type upper_struct is
      record
         header_status : aliased Devices.e1000e.Core.le16;
         length        : aliased Devices.e1000e.Core.le16_array (0 .. PS_PAGE_BUFFERS - 1);     -- Length of buffers 1-3.
      end record;


   type wb_struct is
      record
         lower    : aliased lower_struct;
         middle   : aliased middle_struct;
         upper    : aliased upper_struct;
         reserved : aliased Devices.e1000e.Core.le64;
      end record;



   --------
   --- Item
   --

   type Item_variant is (read_variant, wb_variant);

   type Item (union_Variant : Item_variant := Item_variant'First) is
      record
         case union_Variant
         is
            when read_variant =>   read : aliased read_struct;
            when wb_variant   =>   wb   : aliased wb_struct;       -- Writeback.
         end case;
      end record;

   pragma Unchecked_Union (Item);



   -- Item_Array
   --
   type Item_Array is
     array
       (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_rx_desc_packet_split.Item;


end Devices.e1000e.Hardware.e1000_rx_desc_packet_split;
