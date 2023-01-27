--  devices.ads: Device management library specification.
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
with Memory;
with Lib.Synchronization;

package Devices is
   --  Data to operate with read-write.
   --  This data type imposes a hard limit on operation length of
   --  Natural. Linux shares this limitation funnily enough.
   type Operation_Data is array (Natural range <>) of Unsigned_8;
   type Operation_Data_Acc is access Operation_Data;

   --  Data that defines a device.
   type Resource;
   type Resource_Acc is access all Resource;
   type Resource is record
      Mutex       : aliased Lib.Synchronization.Binary_Semaphore; --  Driver.
      Data        : System.Address;
      Is_Block    : Boolean; --  True for block dev, false for character dev.
      Block_Size  : Natural;
      Block_Count : Unsigned_64;

      --  Safe formally-verifiable alternatives to the functions below, which
      --  will be used instead when available. This is only here because I am
      --  a bit lazy to put 10h on testing and translating every device to be
      --  better.
      Safe_Read : access procedure
         (Key       : Resource_Acc;
          Offset    : Unsigned_64;
          Data      : out Operation_Data;
          Ret_Count : out Natural;
          Success   : out Boolean);
      Safe_Write : access procedure
         (Key       : Resource_Acc;
          Offset    : Unsigned_64;
          Data      : Operation_Data;
          Ret_Count : out Natural;
          Success   : out Boolean);

      Sync : access procedure (Data : Resource_Acc);
      Read : access function
         (Data   : Resource_Acc;
          Offset : Unsigned_64;
          Count  : Unsigned_64;
          Desto  : System.Address) return Unsigned_64;
      Write : access function
         (Data     : Resource_Acc;
          Offset   : Unsigned_64;
          Count    : Unsigned_64;
          To_Write : System.Address) return Unsigned_64;
      IO_Control : access function
         (Data     : Resource_Acc;
          Request  : Unsigned_64;
          Argument : System.Address) return Boolean;
      Mmap : access function
         (Data        : Resource_Acc;
          Address     : Memory.Virtual_Address;
          Length      : Unsigned_64;
          Map_Read    : Boolean;
          Map_Write   : Boolean;
          Map_Execute : Boolean) return Boolean;
      Munmap : access function
         (Data    : Resource_Acc;
          Address : Memory.Virtual_Address;
          Length  : Unsigned_64) return Boolean;
   end record;

   --  Handle for interfacing with devices, and device conditions.
   type Device_Handle is private;
   Error_Handle    : constant Device_Handle;
   Max_Name_Length : constant Natural;

   --  Initialize the device registry and register some devices.
   --  @return True on success, False if some devices could not be registered.
   procedure Init with Post => Is_Registry_Initialized;

   --  Register a device with a resource description and matching name.
   --  @param Dev  Device description to register.
   --  @param Name Name to register the device with, must be unique.
   --  @return True on success, False on failure.
   procedure Register (Dev : Resource; Name : String; Success : out Boolean)
      with Pre => (Is_Registry_Initialized and Name'Length <= Max_Name_Length);

   --  Fetch a device by name.
   --  @param Name Name to search.
   --  @return A handle on success, or Error_Handle on failure.
   function Fetch (Name : String) return Device_Handle
      with Pre => (Is_Registry_Initialized and Name'Length <= Max_Name_Length);

   --  Fetch generic properties of a device handle.
   --  @param Handle Handle to fetch, must be valid, as checking is not done.
   --  @return The requested data.
   function Is_Block_Device (Handle : Device_Handle) return Boolean
      with Pre => (Is_Registry_Initialized and (Handle /= Error_Handle));
   function Get_Block_Count (Handle : Device_Handle) return Unsigned_64
      with Pre => (Is_Registry_Initialized and (Handle /= Error_Handle));
   function Get_Block_Size  (Handle : Device_Handle) return Natural
      with Pre => (Is_Registry_Initialized and (Handle /= Error_Handle));
   function Get_Unique_ID   (Handle : Device_Handle) return Natural
      with Pre => (Is_Registry_Initialized and (Handle /= Error_Handle));

   --  Synchronize internal device state, in order to ensure coherency.
   --  @param Handle Handle to synchronize if supported, must be valid.
   procedure Synchronize (Handle : Device_Handle)
      with Pre => (Is_Registry_Initialized and (Handle /= Error_Handle));

   --  Read from a device.
   --  @param Handle    Handle to read if supported, must be valid.
   --  @param Offset    Byte offset to start reading from, for block devices.
   --  @param Count     Count of bytes to read.
   --  @param Desto     Destination address where to write the read data.
   --  @param Ret_Count Count of bytes actually read, < count if EOF or error.
   --  @param Success   True on success, False on non-supported/failure.
   procedure Read
      (Handle    : Device_Handle;
       Offset    : Unsigned_64;
       Data      : out Operation_Data;
       Ret_Count : out Natural;
       Success   : out Boolean)
      with Pre => (Is_Registry_Initialized and (Handle /= Error_Handle));

   --  Write to a device.
   --  @param Handle    Handle to read if supported, must be valid.
   --  @param Offset    Byte offset to start writing to, for block devices.
   --  @param Count     Count of bytes to write.
   --  @param To_Write  Source address for the data to write.
   --  @param Ret_Count Count of bytes actually written, < count if EOF/error.
   --  @param Success   True on success, False on non-supported/failure.
   procedure Write
      (Handle    : Device_Handle;
       Offset    : Unsigned_64;
       Data      : Operation_Data;
       Ret_Count : out Natural;
       Success   : out Boolean)
      with Pre => (Is_Registry_Initialized and (Handle /= Error_Handle));

   --  Do a device-specific IO control request.
   --  @param Handle   Handle to operate on, must be valid.
   --  @param Request  Device-specific request.
   --  @param Argument Device-specific argument address.
   --  @result True in success, False if not supported or failed.
   function IO_Control
      (Handle   : Device_Handle;
       Request  : Unsigned_64;
       Argument : System.Address) return Boolean
      with Pre => (Is_Registry_Initialized and (Handle /= Error_Handle));

   --  Do a device-specific memory map request.
   --  @param Handle   Handle to operate on, must be valid.
   --  @param Address  Virtual address to map device memory to.
   --  @param Length   Length in bytes of the mapping.
   --  @result True in success, False if not supported or failed.
   function Mmap
      (Handle      : Device_Handle;
       Address     : Memory.Virtual_Address;
       Length      : Unsigned_64;
       Map_Read    : Boolean;
       Map_Write   : Boolean;
       Map_Execute : Boolean) return Boolean
      with Pre => (Is_Registry_Initialized and (Handle /= Error_Handle));

   --  Do a device-specific memory unmap request.
   --  @param Handle   Handle to operate on, must be valid.
   --  @param Address  Virtual address to unmap device memory from.
   --  @param Length   Length in bytes to unmap.
   --  @result True in success, False if not supported or failed.
   function Munmap
      (Handle  : Device_Handle;
       Address : Memory.Virtual_Address;
       Length  : Unsigned_64) return Boolean
      with Pre => (Is_Registry_Initialized and (Handle /= Error_Handle));

   --  Ghost function for checking whether the device handling is initialized.
   function Is_Registry_Initialized return Boolean with Ghost;

private

   type Device_Handle is new Natural range 0 .. 20;
   Error_Handle    : constant Device_Handle := 0;
   Max_Name_Length : constant Natural       := 64;
   type Device is record
      Is_Present : Boolean;
      Name       : String (1 .. Max_Name_Length);
      Name_Len   : Natural range 0 .. Max_Name_Length;
      Contents   : aliased Resource;
   end record;
   type Device_Arr     is array (Device_Handle range 1 .. 20) of Device;
   type Device_Arr_Acc is access Device_Arr;
   Devices_Data : Device_Arr_Acc;

   function Is_Registry_Initialized return Boolean is (Devices_Data /= null);
   function Non_Verified_Init return Boolean;
end Devices;
