--  Devices_Data.adb: Device management.
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

with Devices.Random;
with Devices.Streams;
with Devices.Debug;
with Lib.Panic;
with Arch.Hooks;
with Devices.PTY;
with Config;

package body Devices is
   --  Unit passes GNATprove AoRTE, GNAT does not know this.
   pragma Suppress (All_Checks);

   procedure Init is
      pragma SPARK_Mode (Off);
   begin
      Devices_Data := new Device_Arr'(others =>
         (Is_Present => False,
          Name       => <>,
          Name_Len   => <>,
          Contents   => <>));

      --  Initialize architectural Devices_Data.
      Arch.Hooks.Devices_Hook;

      --  Initialize config-driven Devices_Data.
      if Config.Support_Device_Streams then
         if not Streams.Init then
            goto Failure;
         end if;
      end if;
      if Config.Support_Device_RNG then
         if not Random.Init then
            goto Failure;
         end if;
      end if;
      if Config.Support_Device_PTY then
         if not PTY.Init then
            goto Failure;
         end if;
      end if;

      --  Initialize unconditional devices.
      if not Debug.Init then
         goto Failure;
      end if;
      return;

   <<Failure>>
      Lib.Panic.Hard_Panic ("Could not start arch-independent devices");
   end Init;

   procedure Register (Dev : Resource; Name : String; Success : out Boolean) is
   begin
      --  Search if the name is already taken.
      Success := False;
      for E of Devices_Data.all loop
         if E.Is_Present and then E.Name (1 .. E.Name_Len) = Name then
            return;
         end if;
      end loop;

      --  Allocate.
      for I in Devices_Data'Range loop
         if not Devices_Data (I).Is_Present then
            Devices_Data (I).Is_Present                 := True;
            Devices_Data (I).Name (1 .. Name'Length)    := Name;
            Devices_Data (I).Name_Len                   := Name'Length;
            Devices_Data (I).Contents                   := Dev;
            Success := True;
            exit;
         end if;
      end loop;
   end Register;

   function Fetch (Name : String) return Device_Handle is
   begin
      for I in Devices_Data'Range loop
         if Devices_Data (I).Is_Present and
            Devices_Data (I).Name (1 .. Devices_Data (I).Name_Len) = Name
         then
            return I;
         end if;
      end loop;
      return Error_Handle;
   end Fetch;

   function Is_Block_Device (Handle : Device_Handle) return Boolean is
   begin
      return Devices_Data (Handle).Contents.Is_Block;
   end Is_Block_Device;

   function Get_Block_Count (Handle : Device_Handle) return Unsigned_64 is
   begin
      return Devices_Data (Handle).Contents.Block_Count;
   end Get_Block_Count;

   function Get_Block_Size (Handle : Device_Handle) return Unsigned_64 is
   begin
      return Devices_Data (Handle).Contents.Block_Size;
   end Get_Block_Size;

   function Get_Unique_ID (Handle : Device_Handle) return Natural is
   begin
      --  Since handles are unique, reuse them as unique ID.
      return Natural (Handle);
   end Get_Unique_ID;

   procedure Synchronize (Handle : Device_Handle) is
   begin
      if Devices_Data (Handle).Contents.Sync /= null then
         Devices_Data (Handle).Contents.Sync
            (Devices_Data (Handle).Contents'Access);
      end if;
   end Synchronize;

   function Read
      (Handle : Device_Handle;
       Offset : Unsigned_64;
       Count  : Unsigned_64;
       Desto  : System.Address) return Unsigned_64
   is
   begin
      if Devices_Data (Handle).Contents.Read /= null then
         return Devices_Data (Handle).Contents.Read
            (Data   => Devices_Data (Handle).Contents'Access,
             Offset => Offset,
             Count  => Count,
             Desto  => Desto);
      else
         return 0;
      end if;
   end Read;

   function Write
      (Handle   : Device_Handle;
       Offset   : Unsigned_64;
       Count    : Unsigned_64;
       To_Write : System.Address) return Unsigned_64
   is
   begin
      if Devices_Data (Handle).Contents.Write /= null then
         return Devices_Data (Handle).Contents.Write
            (Data     => Devices_Data (Handle).Contents'Access,
             Offset   => Offset,
             Count    => Count,
             To_Write => To_Write);
      else
         return 0;
      end if;
   end Write;

   function IO_Control
      (Handle   : Device_Handle;
       Request  : Unsigned_64;
       Argument : System.Address) return Boolean
   is
   begin
      if Devices_Data (Handle).Contents.IO_Control /= null then
         return Devices_Data (Handle).Contents.IO_Control
            (Devices_Data (Handle).Contents'Access,
             Request,
             Argument);
      else
         return False;
      end if;
   end IO_Control;

   function Mmap
      (Handle      : Device_Handle;
       Address     : Memory.Virtual_Address;
       Length      : Unsigned_64;
       Map_Read    : Boolean;
       Map_Write   : Boolean;
       Map_Execute : Boolean) return Boolean
   is
   begin
      if Devices_Data (Handle).Contents.Mmap /= null then
         return Devices_Data (Handle).Contents.Mmap
            (Devices_Data (Handle).Contents'Access,
             Address,
             Length,
             Map_Read,
             Map_Write,
             Map_Execute);
      else
         return False;
      end if;
   end Mmap;

   function Munmap
      (Handle  : Device_Handle;
       Address : Memory.Virtual_Address;
       Length  : Unsigned_64) return Boolean
   is
   begin
      if Devices_Data (Handle).Contents.Munmap /= null then
         return Devices_Data (Handle).Contents.Munmap
            (Devices_Data (Handle).Contents'Access,
             Address,
             Length);
      else
         return False;
      end if;
   end Munmap;
end Devices;
