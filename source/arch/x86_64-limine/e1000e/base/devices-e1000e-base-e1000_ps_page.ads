with
     Devices.e1000e.Core,
     Linux,
     Interfaces.C.Pointers;


package Devices.e1000e.Base.e1000_ps_page
is
   -- Item
   --

   type Item is
      record
         page : access  linux.page;
         dma  : aliased Devices.e1000e.Core.u64;      -- Must be u64 - written to hw.
      end record;

   -- Item_Array
   --
   type Item_Array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Base.e1000_ps_page.Item;


   -- Pointer
   --

   Default_Terminator : Item;

   package C_Pointers is new Interfaces.C.Pointers (Index              => Interfaces.C.size_t,
                                                    Element            => Item,
                                                    Element_Array      => Item_Array,
                                                    Default_Terminator => Default_Terminator);
   subtype Pointer is C_Pointers.Pointer;

end Devices.e1000e.Base.e1000_ps_page;
