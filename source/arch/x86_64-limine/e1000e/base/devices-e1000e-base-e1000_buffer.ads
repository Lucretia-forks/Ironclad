with
     Devices.e1000e.Base.e1000_ps_page,
     Interfaces.C.Pointers,
     Devices.e1000e.Core,
     Linux;


package Devices.e1000e.Base.e1000_buffer
--
-- Wrappers around a pointer to a socket buffer,
-- so a DMA handle can be stored along with the buffer.
--
is
   use Interfaces.C;


   type Tx_struct is
      record
         time_stamp     : aliased Interfaces.C.unsigned_long;
         length         : aliased Devices.e1000e.Core.u16;
         next_to_watch  : aliased Devices.e1000e.Core.u16;
         segs           : aliased Interfaces.C.unsigned;
         bytecount      : aliased Interfaces.C.unsigned;
         mapped_as_page : aliased Devices.e1000e.Core.u16;
      end record;


   type Rx_struct is     -- Arrays of page information for packet split.
      record
         ps_pages  :        e1000_ps_page.Pointer;
         page      : access linux.page;
      end record;


   type Tx_Rx_union_variant is (Tx_variant, Rx_variant);

   type Tx_Rx_union (union_Variant : Tx_Rx_union_variant := Tx_Rx_union_variant'First) is
      record
         case union_Variant
         is
            when Tx_variant =>   Tx : aliased Tx_struct;
            when Rx_variant =>   Rx : aliased Rx_struct;
         end case;
      end record;

   pragma Unchecked_Union (Tx_Rx_union);



   -- Item
   --

   type Item is
      record
         dma            : aliased linux.dma_addr_t;
         skb            : access  linux.sk_buff;
         Tx_Rx          :         Tx_Rx_union;
      end record;



   -- Item_Array
   --
   type Item_Array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Base.e1000_buffer.Item;



   -- Pointer
   --

   Default_Terminator : Item;

   package C_Pointers is new Interfaces.C.Pointers (Index              => Interfaces.C.size_t,
                                                    Element            => Item,
                                                    Element_Array      => Item_Array,
                                                    Default_Terminator => Default_Terminator);
   subtype Pointer is C_Pointers.Pointer;


end Devices.e1000e.Base.e1000_buffer;
