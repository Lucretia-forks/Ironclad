with
     Devices.e1000e.Core;

limited
with
     Devices.e1000e.Base.e1000_adapter;


package Devices.e1000e.Base.get_variants_func
is
   -- Item
   --
   type Item is
     access
       function
         (arg_1 : access Devices.e1000e.Base.e1000_adapter.Item) return Devices.e1000e.Core.s32;



   -- Item_Array
   --
   type Item_Array is
     array
       (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Base.get_variants_func.Item;


end Devices.e1000e.Base.get_variants_func;
