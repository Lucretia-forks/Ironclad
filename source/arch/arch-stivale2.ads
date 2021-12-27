--  arch-stivale2.ads: Specification of stivale2 utilities and tags.
--  Copyright (C) 2021 streaksu
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

package Arch.Stivale2 is
   --  IDs of several tags.
   CmdlineID  : constant := 16#E5E76A1B4597A781#;
   TerminalID : constant := 16#C2B3F4C3233B0974#;
   MemmapID   : constant := 16#2187F79E8612DE07#;

   --  Stivale2 header passed by the bootloader to kernel.
   type Header is record
      BootloaderBrand   : String (1 .. 64);
      BootloaderVersion : String (1 .. 64);
      Tags              : System.Address;
   end record;
   for Header use record
      BootloaderBrand   at 0 range    0 ..  511;
      BootloaderVersion at 0 range  512 .. 1023;
      Tags              at 0 range 1024 .. 1087;
   end record;
   for Header'Size use 1088;

   --  Stivale2 tag passed in front of all specialized tags.
   type Tag is record
      Identifier : Unsigned_64;
      Next       : System.Address;
   end record;
   for Tag use record
      Identifier at 0 range  0 ..  63;
      Next       at 0 range 64 .. 127;
   end record;
   for Tag'Size use 128;

   type Cmdline_Tag is record
      TagInfo : Tag;
      Cmdline : System.Address;
   end record;
   for Cmdline_Tag use record
      TagInfo at 0 range   0 .. 127;
      Cmdline at 0 range 128 .. 191;
   end record;
   for Cmdline_Tag'Size use 192;

   type Terminal_Tag is record
      TagInfo   : Tag;
      Flags     : Unsigned_32;
      Cols      : Unsigned_16;
      Rows      : Unsigned_16;
      TermWrite : System.Address;
      MaxLength : Unsigned_64;
   end record;
   for Terminal_Tag use record
      TagInfo   at 0 range   0 .. 127;
      Flags     at 0 range 128 .. 159;
      Cols      at 0 range 160 .. 175;
      Rows      at 0 range 176 .. 191;
      TermWrite at 0 range 192 .. 255;
      MaxLength at 0 range 256 .. 319;
   end record;
   for Terminal_Tag'Size use 320;

   Memmap_Entry_Usable                 : constant := 1;
   Memmap_Entry_Reserved               : constant := 2;
   Memmap_Entry_ACPI_Reclaimable       : constant := 3;
   Memmap_Entry_ACPI_NVS               : constant := 4;
   Memmap_Entry_Bad                    : constant := 5;
   Memmap_Entry_Bootloader_Reclaimable : constant := 16#1000#;
   Memmap_Entry_Kernel_And_Modules     : constant := 16#1001#;
   Memmap_Entry_Framebuffer            : constant := 16#1002#;

   type Memmap_Entry is record
      Base      : System.Address;
      Length    : Unsigned_64;
      EntryType : Unsigned_32;
      Unused    : Unsigned_32;
   end record;
   for Memmap_Entry use record
      Base      at 0 range   0 ..  63;
      Length    at 0 range  64 .. 127;
      EntryType at 0 range 128 .. 159;
      Unused    at 0 range 160 .. 191;
   end record;
   for Memmap_Entry'Size use 192;

   --  TODO: There must be a better way in Ada to represent this VLA.
   --  Discriminants with a record field would be nice, but it doesnt work.
   type Memmap_Tag is record
      TagInfo    : Tag;
      EntryCount : Unsigned_64;
      Entries    : Unsigned_64; --  Is actually a VLA with length = EntryCount
   end record;
   for Memmap_Tag use record
      TagInfo    at 0 range   0 .. 127;
      EntryCount at 0 range 128 .. 191;
      Entries    at 0 range 192 .. 255;
   end record;
   for Memmap_Tag'Size use 256;

   --  Find a header.
   function Get_Tag
      (Proto     : access Header;
      Identifier : Unsigned_64) return System.Address;

   --  Initialize the terminal with a header.
   procedure Init_Terminal (Terminal : access Terminal_Tag);

   --  Print a message using the stivale2 terminal.
   procedure Print_Terminal (Message : String);
   procedure Print_Terminal (Message : Character);
end Arch.Stivale2;
