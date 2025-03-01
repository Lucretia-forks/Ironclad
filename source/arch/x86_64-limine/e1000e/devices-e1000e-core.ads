with
     Interfaces.C.Pointers,
     System.Storage_Elements;


package Devices.e1000e.Core
is
   use Interfaces;


   Milliseconds : constant Duration := 0.00_1;
   Microseconds : constant Duration := 0.00_000_1;



   -- s32
   --
   subtype s32 is Interfaces.Integer_32;

   type s32_array is array (C.size_t range <>) of aliased s32;


   -- u8
   --
   subtype u8 is Interfaces.Unsigned_8;

   type u8_array is array (C.size_t range <>) of aliased u8;


   -- u16
   --
   subtype u16 is Interfaces.Unsigned_16;

   type u16_array is array (C.size_t range <>) of aliased u16;


   -- u32
   --
   subtype u32 is Interfaces.Unsigned_32;

   type u32_array is array (C.size_t range <>) of aliased u32;


   -- u64
   --
   subtype u64 is Interfaces.Unsigned_64;

   type u64_array is array (C.size_t range <>) of aliased u64;



   --  function to_u32 (From : in system.Address) return u32
   --  is
   --     (u32 (System.Storage_Elements.to_Integer (From)));

   function to_ulong (From : in system.Address) return C.unsigned_long
   is
     (C.unsigned_long (System.Storage_Elements.to_Integer (From)));



   --------------
   --- Big Endian
   --


   -- be16
   --

   type be16 is
      record
         Value : interfaces.Unsigned_16;
      end record
     with
       Bit_Order            => System.High_Order_First,
       Scalar_Storage_Order => System.High_Order_First;

   for be16 use
      record
         Value at 0 range 0 .. 15;     -- TODO: Check this.
      end record;


   type be16_array is array (C.size_t range <>) of aliased be16
     with
       Scalar_Storage_Order => System.High_Order_First;



   -- be32
   --

   type be32 is
      record
         Value : interfaces.Unsigned_32;
      end record
     with
       Bit_Order            => System.High_Order_First,
       Scalar_Storage_Order => System.High_Order_First;

   for be32 use
      record
         Value at 0 range 0 .. 31;     -- TODO: Check this.
      end record;


   type be32_array is array (C.size_t range <>) of aliased be32
     with
       Scalar_Storage_Order => System.High_Order_First;




   -----------------
   --- Little Endian
   --

   -- le16
   --

   type le16 is
      record
         Value : interfaces.Unsigned_16;
      end record
     with
       Scalar_Storage_Order => System.Low_Order_First;

   for le16 use
      record
         Value at 0 range 0 .. 15;
      end record;


   type le16_array is array (C.size_t range <>) of aliased le16
     with
       Scalar_Storage_Order => System.Low_Order_First;


   -- le32
   --

   type le32 is
      record
         Value : interfaces.Unsigned_32;
      end record
     with
       Scalar_Storage_Order => System.Low_Order_First;

   for le32 use
      record
         Value at 0 range 0 .. 31;
      end record;


   type le32_array is array (C.size_t range <>) of aliased le32
     with
       Scalar_Storage_Order => System.Low_Order_First;


   -- le64
   --
   type le64 is
      record
         Value : interfaces.Unsigned_64;
      end record
     with
       Scalar_Storage_Order => System.Low_Order_First;

   for le64 use
      record
         Value at 0 range 0 .. 63;
      end record;


   type le64_array is array (C.size_t range <>) of aliased le64
     with
       Scalar_Storage_Order => System.Low_Order_First;



   -----------
   --- C Types
   --

   subtype void_ptr            is System.Address;
   type    int_Array           is array (C.size_t range <>) of aliased C.Int;
   type    unsigned_long_Array is array (C.size_t range <>) of aliased C.unsigned_Long;

   package c_int_Pointers      is new C.Pointers (Index              => C.size_t,
                                                  Element            => C.Int,
                                                  element_Array      => int_Array,
                                                  default_Terminator => 0);
   subtype int_Pointer         is c_int_Pointers.Pointer;



   ----------
   --- Macros
   --

   function BIT (nr : in Natural) return Unsigned_16
   is
     (shift_Left (1, nr));


   function BIT (nr : in Natural) return Unsigned_32
   is
     (shift_Left (1, nr));


   function BIT (nr : in Natural) return Unsigned_64
   is
     (shift_Left (1, nr));




   -------------
   --- Utilities
   --

   protected type Mutex
   is
      entry     acquire;
      procedure release;
   private
      Available : Boolean := True;
   end Mutex;



end Devices.e1000e.Core;
