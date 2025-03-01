with
     Devices.e1000e.Base.e1000_buffer,
     Devices.e1000e.Hardware,
     Linux,
     Interfaces.C.Pointers,
     Devices.e1000e.Core;

limited
with
     Devices.e1000e.Base.e1000_adapter;


package Devices.e1000e.Base.e1000_ring
is
   use Interfaces.C;


   -- Item
   --

   type Item is
      record
         adapter       : access  Devices.e1000e.Base.e1000_adapter.Item;     -- Back pointer to adapter.
         desc          : aliased Devices.e1000e.Core.void_ptr;                -- Pointer to ring memory.
         dma           : aliased linux.dma_addr_t;             -- Phys address of ring.
         size          : aliased Interfaces.C.unsigned;        -- Length of ring in bytes.
         count         : aliased Interfaces.C.unsigned;        -- Number of desc in ring.

         next_to_use   : aliased Devices.e1000e.Core.u16;
         next_to_clean : aliased Devices.e1000e.Core.u16;

         head          : aliased Devices.e1000e.Core.void_ptr;
         tail          : aliased Devices.e1000e.Core.void_ptr;

         buffer_info   :         Devices.e1000e.Base.e1000_buffer.Pointer;   -- Array of buffer information structs.

         name          : aliased Interfaces.C.char_array (0 .. Devices.e1000e.Hardware.IFNAMSIZ + 5 - 1);
         ims_val       : aliased Devices.e1000e.Core.u32;
         itr_val       : aliased Devices.e1000e.Core.u32;
         itr_register  : aliased Devices.e1000e.Core.void_ptr;
         set_itr       : aliased Interfaces.C.int;

         rx_skb_top    : access  linux.sk_buff;
      end record;


   -- Item_Array
   --
   type Item_Array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Base.e1000_ring.Item;

   -- Pointer
   --
   package C_Pointers is new Interfaces.C.Pointers (Index              => Interfaces.C.size_t,
                                                    Element            => Devices.e1000e.Base.e1000_ring.Item,
                                                    Element_Array      => Devices.e1000e.Base.e1000_ring.Item_Array,
                                                    Default_Terminator => (others => <>));
   subtype Pointer is C_Pointers.Pointer;


end Devices.e1000e.Base.e1000_ring;
