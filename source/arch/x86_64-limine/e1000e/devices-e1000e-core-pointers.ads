with
     Interfaces.C.Pointers;


package Devices.e1000e.Core.Pointers
is

   -- s32_Pointer
   --
   package C_s32_Pointers is new Interfaces.C.Pointers (Index              => Interfaces.C.size_t,
                                                        Element            => Devices.e1000e.Core.s32,
                                                        Element_Array      => Devices.e1000e.Core.s32_array,
                                                        Default_Terminator => 0);

   subtype s32_Pointer is C_s32_Pointers.Pointer;

   -- s32_Pointer_Array
   --
   type s32_Pointer_Array is array (Interfaces.C.size_t range <>) of aliased s32_Pointer;

   -- u8_Pointer
   --
   package C_u8_Pointers is new Interfaces.C.Pointers (Index              => Interfaces.C.size_t,
                                                       Element            => Devices.e1000e.Core.u8,
                                                       Element_Array      => Devices.e1000e.Core.u8_array,
                                                       Default_Terminator => 0);

   subtype u8_Pointer is C_u8_Pointers.Pointer;

   -- u8_Pointer_Array
   --
   type u8_Pointer_Array is
     array (Interfaces.C.size_t range <>) of aliased u8_Pointer;

   -- u16_Pointer
   --
   package C_u16_Pointers is new Interfaces.C.Pointers (Index              => Interfaces.C.size_t,
                                                        Element            => Devices.e1000e.Core.u16,
                                                        Element_Array      => Devices.e1000e.Core.u16_array,
                                                        Default_Terminator => 0);

   subtype u16_Pointer is C_u16_Pointers.Pointer;

   -- u16_Pointer_Array
   --
   type u16_Pointer_Array is
     array
       (Interfaces.C.size_t range <>) of aliased u16_Pointer;

   -- u32_Pointer
   --
   package C_u32_Pointers is new Interfaces.C.Pointers (Index              => Interfaces.C.size_t,
                                                        Element            => Devices.e1000e.Core.u32,
                                                        Element_Array      => Devices.e1000e.Core.u32_array,
                                                        Default_Terminator => 0);

   subtype u32_Pointer is C_u32_Pointers.Pointer;

   -- u32_Pointer_Array
   --
   type u32_Pointer_Array is
     array
       (Interfaces.C.size_t range <>) of aliased u32_Pointer;

   -- u64_Pointer
   --
   package C_u64_Pointers is new Interfaces.C.Pointers (Index              => Interfaces.C.size_t,
                                                        Element            => Devices.e1000e.Core.u64,
                                                        Element_Array      => Devices.e1000e.Core.u64_array,
                                                        Default_Terminator => 0);

   subtype u64_Pointer is C_u64_Pointers.Pointer;

   -- u64_Pointer_Array
   --
   type u64_Pointer_Array is
     array
       (Interfaces.C.size_t range <>) of aliased u64_Pointer;

   -- le16_Pointer
   --
   package C_le16_Pointers is new Interfaces.C.Pointers (Index              => Interfaces.C.size_t,
                                                         Element            => Devices.e1000e.Core.le16,
                                                         Element_Array      => Devices.e1000e.Core.le16_array,
                                                         Default_Terminator => (Value => 0));

   subtype le16_Pointer is C_le16_Pointers.Pointer;

   -- le16_Pointer_Array
   --
   type le16_Pointer_Array is
     array
       (Interfaces.C.size_t range <>) of aliased le16_Pointer;

   -- le32_Pointer
   --
   package C_le32_Pointers is new Interfaces.C.Pointers (Index              => Interfaces.C.size_t,
                                                         Element            => Devices.e1000e.Core.le32,
                                                         Element_Array      => Devices.e1000e.Core.le32_array,
                                                         Default_Terminator => (Value => 0));

   subtype le32_Pointer is C_le32_Pointers.Pointer;

   -- le32_Pointer_Array
   --
   type le32_Pointer_Array is
     array
       (Interfaces.C.size_t range <>) of aliased le32_Pointer;

   -- le64_Pointer
   --
   package C_le64_Pointers is new Interfaces.C.Pointers (Index              => Interfaces.C.size_t,
                                                         Element            => Devices.e1000e.Core.le64,
                                                         Element_Array      => Devices.e1000e.Core.le64_array,
                                                         Default_Terminator => (Value => 0));

   subtype le64_Pointer is C_le64_Pointers.Pointer;

   -- le64_Pointer_Array
   --
   type le64_Pointer_Array is
     array
       (Interfaces.C.size_t range <>) of aliased le64_Pointer;


end Devices.e1000e.Core.Pointers;
