limited
with
     Devices.e1000e.Base.e1000_ring;


package Devices.e1000e.Base.clean_rx_func
is

   -- Item
   --
   type Item is
     access
       function
         (arg_1 : access Devices.e1000e.Base.e1000_ring.Item;
          arg_2 : access Integer;
          --  arg_2 : in     core.int_Pointer;
          arg_3 : in     C.int) return Boolean;

   pragma Convention (C, Item);

   -- Item_Array
   --
   type Item_Array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Base.clean_rx_func.Item;


end Devices.e1000e.Base.clean_rx_func;
