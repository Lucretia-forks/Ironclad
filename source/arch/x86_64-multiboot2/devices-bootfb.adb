--  devices-bootmfb.adb: Boot-time memory framebuffer driver.
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

with System; use System;
with Memory; use Memory;
with System.Storage_Elements; use System.Storage_Elements;
with Arch.MMU;
with Arch.CPU;
with Lib.Alignment;
with Arch.Multiboot2; use Arch.Multiboot2;
with Userland.Process;
with Memory.Virtual;

package body Devices.BootFB with SPARK_Mode => Off is
   package Align is new Lib.Alignment (Unsigned_64);

   function Init return Boolean is
      Stat     : VFS.File_Stat;
      Device   : VFS.Resource;
      Fb       : constant Framebuffer_Tag_Acc :=
         new Framebuffer_Tag'(Get_Framebuffer);
      Fb_Flags : constant Arch.MMU.Page_Permissions := (
         User_Accesible => False,
         Read_Only      => False,
         Executable     => False,
         Global         => False,
         Write_Through  => True
      );
      Length : constant Unsigned_64 := Align.Align_Up
         (Unsigned_64 (Fb.Height) * 4 * Unsigned_64 (Fb.Pitch),
          Memory.Virtual.Page_Size);
   begin
      --  Remap the framebuffer write-combining in the higher-half.
      Fb.Address := To_Address (To_Integer (Fb.Address) + Memory_Offset);
      if not Memory.Virtual.Remap_Range (
         Map     => Memory.Virtual.Kernel_Map,
         Virtual => Memory.Virtual_Address (To_Integer (Fb.Address)),
         Length  => Length,
         Flags   => Fb_Flags
      )
      then
         return False;
      end if;

      --  Register the device.
      Stat := (
         Unique_Identifier => 0,
         Type_Of_File      => VFS.File_Character_Device,
         Mode              => 8#660#,
         Hard_Link_Count   => 1,
         Byte_Size         => 0,
         IO_Block_Size     => 4096,
         IO_Block_Count    => 0
      );

      Device := (
         Data       => Fb.all'Address,
         Mutex      => <>,
         Stat       => Stat,
         Sync       => null,
         Read       => null,
         Write      => null,
         IO_Control => IO_Control'Access,
         Mmap       => Mmap'Access,
         Munmap     => null
      );

      return VFS.Register (Device, "bootfb");
   end Init;

   IO_Control_Report_Dimensions : constant := 1;
   function IO_Control
      (Data     : VFS.Resource_Acc;
       Request  : Unsigned_64;
       Argument : System.Address) return Boolean
   is
      type Dimensions is record
         Width  : Unsigned_32;
         Height : Unsigned_32;
         Pitch  : Unsigned_32;
         BPP    : Unsigned_8;
      end record;

      Dev_Data : Arch.Multiboot2.Framebuffer_Tag with Address => Data.Data;
   begin
      case Request is
         when IO_Control_Report_Dimensions =>
            declare
               Requested_Data : Dimensions with Address => Argument;
            begin
               Requested_Data := (
                  Width  => Dev_Data.Width,
                  Height => Dev_Data.Height,
                  Pitch  => Dev_Data.Pitch,
                  BPP    => Dev_Data.BPP
               );
               return True;
            end;
         when others =>
            return False;
      end case;
   end IO_Control;

   function Mmap
      (Data        : VFS.Resource_Acc;
       Address     : Memory.Virtual_Address;
       Length      : Unsigned_64;
       Map_Read    : Boolean;
       Map_Write   : Boolean;
       Map_Execute : Boolean) return Boolean
   is
      pragma Unreferenced (Map_Read); --  We cannot really map not read lol.

      Dev_Data : Arch.Multiboot2.Framebuffer_Tag with Address => Data.Data;
      Addr     : constant Integer_Address := To_Integer (Dev_Data.Address);
      Process  : constant Userland.Process.Process_Data_Acc :=
            Arch.CPU.Get_Local.Current_Process;
      Fb_Flags : constant Arch.MMU.Page_Permissions := (
         User_Accesible => True,
         Read_Only      => not Map_Write,
         Executable     => Map_Execute,
         Global         => False,
         Write_Through  => True
      );
   begin
      return Memory.Virtual.Map_Range (
         Map      => Process.Common_Map,
         Virtual  => Address,
         Physical => Memory.Virtual_Address (Addr - Memory.Memory_Offset),
         Length   => Length,
         Flags    => Fb_Flags
      );
   end Mmap;
end Devices.BootFB;
