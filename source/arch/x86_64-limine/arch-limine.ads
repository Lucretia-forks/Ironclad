--  arch-limine.ads: Limine utilities.
--  Copyright (C) 2024 streaksu
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <http://www.gnu.org/licenses/>.

with System;
with Interfaces; use Interfaces;

package Arch.Limine is
   --  Global variable holding platform information.
   Global_Info : Boot_Information;

   --  Smallest address of the memmap, filled when the proto is translated,
   --  since this garbage architecture requires sub 1MiB memory regions for
   --  SMP starting. Its fucking stupid.
   --  Its meant to be always valid.
   Max_Sub_1MiB_Size : constant := 16#1000#;
   Sub_1MiB_Region : System.Address;

   --  Get physical address where the kernel is loaded.
   function Get_Physical_Address return System.Address;

   --  Translate a multiboot2 header into architecture info.
   --  @param Proto Pointer to translate, if null, return cached or panic.
   procedure Translate_Proto;
   ----------------------------------------------------------------------------
   Limine_Common_Magic_1 : constant := 16#c7b1dd30df4c8b88#;
   Limine_Common_Magic_2 : constant := 16#0a82e883a194f07b#;

   type Request_ID is array (1 .. 4) of Unsigned_64;
   type Request is record
      ID       : Request_ID;
      Revision : Unsigned_64;
      Response : System.Address;
   end record with Pack, Volatile;

   type Response is record
      Revision : Unsigned_64;
   end record with Pack;

   type Video_Mode is record
      Pitch            : Unsigned_64;
      Width            : Unsigned_64;
      Height           : Unsigned_64;
      BPP              : Unsigned_16;
      Memory_Model     : Unsigned_8;
      Red_Mask_Size    : Unsigned_8;
      Red_Mask_Shift   : Unsigned_8;
      Green_Mask_Size  : Unsigned_8;
      Green_Mask_Shift : Unsigned_8;
      Blue_Mask_Size   : Unsigned_8;
      Blue_Mask_Shift  : Unsigned_8;
   end record with Pack;
   type Video_Mode_Arr is array (Natural range <>) of Video_Mode;

   type Framebuffer_Padding is array (1 .. 7) of Unsigned_8;
   type Framebuffer is record
      Address          : System.Address;
      Width            : Unsigned_64;
      Height           : Unsigned_64;
      Pitch            : Unsigned_64;
      BPP              : Unsigned_16;
      Memory_Model     : Unsigned_8;
      Red_Mask_Size    : Unsigned_8;
      Red_Mask_Shift   : Unsigned_8;
      Green_Mask_Size  : Unsigned_8;
      Green_Mask_Shift : Unsigned_8;
      Blue_Mask_Size   : Unsigned_8;
      Blue_Mask_Shift  : Unsigned_8;
      Unused           : Framebuffer_Padding;
      EDID_Size        : Unsigned_64;
      EDID             : System.Address;
      Mode_Count       : Unsigned_64;
      Modes            : System.Address;
   end record with Pack;
   type Framebuffer_Acc is access all Framebuffer;
   type Framebuffer_Arr is array (Unsigned_64 range <>) of Framebuffer;

   type Framebuffer_Response is record
      Base         : Response;
      Count        : Unsigned_64;
      Framebuffers : System.Address;
   end record with Pack;

   type Limine_File is record
      Base    : Response;
      Address : System.Address;
      Size    : Unsigned_64;
      Path    : System.Address;
      Cmdline : System.Address;
   end record with Pack;

   type Kernel_File_Response is record
      Base        : Response;
      Kernel_File : access Limine_File;
   end record with Pack;

   type Memmap_Response is record
      Base    : Response;
      Count   : Unsigned_64;
      Entries : System.Address;
   end record with Pack;

   LIMINE_MEMMAP_USABLE           : constant := 0;
   LIMINE_MEMMAP_RESERVED         : constant := 1;
   LIMINE_MEMMAP_ACPI_RECLAIMABLE : constant := 2;
   LIMINE_MEMMAP_ACPI_NVS         : constant := 3;
   LIMINE_MEMMAP_BAD_MEMORY       : constant := 4;
   LIMINE_MEMMAP_BOOTLOADER_RECL  : constant := 5;
   LIMINE_MEMMAP_KERNEL_AND_MODS  : constant := 6;
   LIMINE_MEMMAP_FRAMEBUFFER      : constant := 7;

   type Memmap_Entry is record
      Base      : Unsigned_64;
      Length    : Unsigned_64;
      EntryType : Unsigned_64;
   end record with Pack;

   type Memmap_Entry_Acc is access all Memmap_Entry;
   type Memmap_Entry_Arr is array (Unsigned_64 range <>) of Memmap_Entry_Acc;

   type RSDP_Response is record
      Base : Response;
      Addr : System.Address;
   end record with Pack;

   type Kernel_Address_Response is record
      Base      : Response;
      Phys_Addr : System.Address;
      Virt_Addr : System.Address;
   end record with Pack;

   type Revision_ID is array (1 .. 3) of Unsigned_64;
   Revision : Revision_ID := (16#f9562b2d5c95a6c8#, 16#6a7b384944536bdc#, 2);

   --  Response is a pointer to a Kernel_File_Response.
   Kernel_File_Request : Request :=
      (ID => (Limine_Common_Magic_1, Limine_Common_Magic_2,
              16#ad97e90e83f1ed67#, 16#31eb5d1c5ff23b69#),
       Revision => 0,
       Response => System.Null_Address);

   --  Response is a pointer to a Memmap_Response.
   Memmap_Request : Request :=
      (ID => (Limine_Common_Magic_1, Limine_Common_Magic_2,
              16#67cf3d9d378a806f#, 16#e304acdfc50c3c62#),
       Revision => 0,
       Response => System.Null_Address);

   --  Response is a pointer to an Kernel_Address_Response.
   Address_Request : Request :=
      (ID => (Limine_Common_Magic_1, Limine_Common_Magic_2,
              16#71ba76863cc55f63#, 16#b2644a48c516a487#),
       Revision => 0,
       Response => System.Null_Address);
end Arch.Limine;
