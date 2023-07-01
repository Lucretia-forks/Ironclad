--  memory-virtual.ads: Virtual memory manager.
--  Copyright (C) 2023 streaksu
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

with Interfaces; use Interfaces;
with Lib.Synchronization;
with Arch.MMU; use Arch.MMU;

package Memory.Virtual with SPARK_Mode => Off is
   --  Minimum page size the kernel supports. Operations on memory using
   --  the rest of the package should be ideally aligned to this value.
   Page_Size : constant := Arch.MMU.Page_Size;

   --  Structures for keeping track of mapping information.
   type Page_Map     is private;
   type Page_Map_Acc is access Page_Map;

   --  Initialize the manager using the architectural interface.
   --  @return True on success, False on failure.
   function Init (Memmap : Arch.Boot_Memory_Map) return Boolean;

   --  Get the default kernel map if initialized by Init.
   --  @return Pointer to the kernel map, or null in failure.
   function Get_Kernel_Map return Page_Map_Acc;

   --  Make maps active.
   --  @return True on success, False on failure.
   function Make_Active (Map : Page_Map_Acc) return Boolean;

   --  Check whether a map is loaded.
   --  @return True if loaded, False if not loaded.
   function Is_Loaded (Map : Page_Map_Acc) return Boolean;

   --  Map a range of physical memory to virtual memory.
   --  @param Map      Map to allocate.
   --  @param Virtual  Virtual address to map.
   --  @param Physical Physical address to map.
   --  @param Length   Length of the region in bytes.
   --  @param Flags    Flags of the region.
   --  @return True on success, False on failure.
   function Map_Range
      (Map       : Page_Map_Acc;
       Virtual   : Virtual_Address;
       Physical  : Physical_Address;
       Length    : Unsigned_64;
       Flags     : Arch.MMU.Page_Permissions) return Boolean;

   --  Remap a range of virtual memory with different permissions.
   --  @param Map      Map to allocate.
   --  @param Virtual  Virtual address to remap.
   --  @param Length   Length of the region in bytes.
   --  @param Flags    Flags of the region.
   --  @return True on success, False on failure.
   function Remap_Range
      (Map     : Page_Map_Acc;
       Virtual : Virtual_Address;
       Length  : Unsigned_64;
       Flags   : Arch.MMU.Page_Permissions) return Boolean;

   --  Unmap a range of virtual memory with different permissions.
   --  @param Map     Map to allocate.
   --  @param Virtual Virtual address to unmap.
   --  @param Length  Length of the region in bytes.
   --  @return True on success, False on failure.
   function Unmap_Range
      (Map     : Page_Map_Acc;
       Virtual : Virtual_Address;
       Length  : Unsigned_64) return Boolean;

   --  Map a range of memory to an internally allocated physical region.
   --  @param Map Map to allocate.
   --  @param Virtual Virtual address to map the allocated region to.
   --  @param Length  Length of the region in bytes.
   --  @param Flags   Flags of the region.
   --  @param Writing Mapped access to the allocated memory for the kernel on
   --                 all mappings, it must be unmapped on its own, this
   --                 exists for supporting editing regions allocated for
   --                 other maps than your own.
   --  @return True on success, False on failure.
   function Map_Memory_Backed_Region
      (Map     : Page_Map_Acc;
       Virtual : Virtual_Address;
       Length  : Unsigned_64;
       Flags   : Arch.MMU.Page_Permissions;
       Writing : out Virtual_Address) return Boolean;

   --  Create a new map ready for loading. The kernel will be mapped and
   --  loading it will not cause accessing kernel addresses to fault.
   --  @return The new map, or null on failure.
   function New_Map return Page_Map_Acc;

   --  Delete the passed map, there is no reference counting, deleting this
   --  will delete it for all holders.
   procedure Delete_Map (Map : in out Page_Map_Acc);

   --  Fork the passed map into a new map, copying all the mappings and memory
   --  contents for the same virtual addresses.
   function Fork_Map (Map : Page_Map_Acc) return Page_Map_Acc;

   --  Translate a virtual address to a physical one.
   --  @return Address on success, or 0 on failure.
   function Virtual_To_Physical
      (Map     : Page_Map_Acc;
       Virtual : Virtual_Address) return Physical_Address;

   --  Check whether the loaded map can access the passed address + length
   --  from userland with the passed map.
   --  @param Addr       Address to check.
   --  @param Byte_Count Length of the window to check in bytes.
   --  @return True if accessable, False if the access would not be allowed.
   function Check_Userland_Access
      (Map        : Page_Map_Acc;
       Addr       : Virtual_Address;
       Byte_Count : Unsigned_64) return Boolean;

   --  Check whether userland can map the passed address whatsoever, used
   --  to ensure the survival of the kernel against hostile mappings. The
   --  actual map does not matter, as we do not guard against userland on
   --  userland aggressions (stop hitting yourself!).
   --  @param Addr       Address to check.
   --  @param Byte_Count Length of the window to check in bytes.
   --  @return True if mappable, False if the mapping would be illegal.
   function Check_Userland_Mappability
      (Addr       : Virtual_Address;
       Byte_Count : Unsigned_64) return Boolean;

private

   type Mapping_Range is record
      Is_Present     : Boolean;
      Is_Allocated   : Boolean;
      Virtual_Start  : Virtual_Address;
      Physical_Start : Physical_Address;
      Length         : Unsigned_64;
      Flags          : Arch.MMU.Page_Permissions;
   end record;
   type Mapping_Range_Arr is array (Natural range <>) of Mapping_Range;
   type Page_Map is record
      Mutex      : aliased Lib.Synchronization.Binary_Semaphore;
      Inner      : Arch.MMU.Page_Table_Acc;
      Map_Ranges : Mapping_Range_Arr (1 .. 100);
   end record;

   --  Inner map function shared by memory backed and standard mappings.
   function Inner_Map_Range
      (Map          : Page_Map_Acc;
       Virtual      : Virtual_Address;
       Physical     : Physical_Address;
       Length       : Unsigned_64;
       Flags        : Arch.MMU.Page_Permissions;
       Is_Allocated : Boolean) return Boolean;
end Memory.Virtual;
