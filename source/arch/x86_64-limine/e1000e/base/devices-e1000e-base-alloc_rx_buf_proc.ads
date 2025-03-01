with
     Linux;

limited
with
     Devices.e1000e.Base.e1000_ring;


package Devices.e1000e.Base.alloc_rx_buf_proc
is
   -- Item
   --
   type Item is
     access
       procedure
         (Rx_Ring    : access Devices.e1000e.Base.e1000_ring.Item;
          Desc_Count : in     C.int;
          Flags      : in     linux.gfp_t);


   -- Item_Array
   --
   type Item_Array is
     array
       (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Base.alloc_rx_buf_proc.Item;


end Devices.e1000e.Base.alloc_rx_buf_proc;
