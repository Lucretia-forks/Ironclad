--  userland-syscall.adb: Syscall implementation.
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

with System.Storage_Elements; use System.Storage_Elements;
with Ada.Characters.Latin_1;
with Config;
with System; use System;
with Lib.Messages;
with Lib;
with Networking;
with Userland.Loader;
with VFS.File; use VFS.File;
with VFS; use VFS;
with Scheduler; use Scheduler;
with Memory.Virtual; use Memory.Virtual;
with Memory.Physical;
with Memory; use Memory;
with Ada.Unchecked_Deallocation;
with Ada.Unchecked_Conversion;
with Interfaces.C;
with Arch.Hooks;
with Arch.Local;
with Cryptography.Random;
with Userland.MAC;
with IPC.Pipe; use IPC.Pipe;
with IPC.PTY;  use IPC.PTY;
with Devices;
with Userland.Integrity;
with Devices.TermIOs;

package body Userland.Syscall with SPARK_Mode => Off is
   procedure Sys_Exit (Code : Unsigned_64; Errno : out Errno_Value) is
      Proc : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
   begin
      Errno := Error_No_Error;
      Do_Exit (Proc, Unsigned_8 (Code and 16#FF#));
   end Sys_Exit;

   procedure Do_Exit (Proc : Process_Data_Acc; Code : Unsigned_8) is
   begin
      --  Remove all state but the return value and keep the zombie around
      --  until we are waited.
      Userland.Process.Flush_Threads (Proc);
      Userland.Process.Flush_Files   (Proc);
      Proc.Exit_Code := Code;
      Proc.Did_Exit  := True;
      Scheduler.Bail;
   end Do_Exit;

   procedure Compound_AT_Path
      (AT_Directive : Natural;
       Curr_Proc    : Process_Data_Acc;
       Extension    : String;
       Result       : out String;
       Count        : out Natural)
   is
      File : File_Description_Acc;
   begin
      if AT_Directive = AT_FDCWD then
         Compound_Path
            (Base    => Curr_Proc.Current_Dir (1 .. Curr_Proc.Current_Dir_Len),
             Extension => Extension,
             Result    => Result,
             Count     => Count);
      else
         File := Get_File (Curr_Proc, Unsigned_64 (AT_Directive));
         if File = null then
            Count := 0;
            return;
         end if;

         Compound_Path
            (Base      => Get_Path (File.Inner_File).all,
             Extension => Extension,
             Result    => Result,
             Count     => Count);
      end if;
   end Compound_AT_Path;

   function Arch_PRCtl
      (Code     : Unsigned_64;
       Argument : Unsigned_64;
       Errno    : out Errno_Value) return Unsigned_64
   is
      Proc  : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      I_Arg : constant  Integer_Address := Integer_Address (Argument);
      S_Arg : constant   System.Address := To_Address (I_Arg);
   begin
      if not Check_Userland_Access (Proc.Common_Map, I_Arg, 8) then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      elsif Code > Unsigned_64 (Natural'Last) then
         Errno := Error_Invalid_Value;
         return Unsigned_64'Last;
      end if;

      if Arch.Hooks.PRCTL_Hook (Natural (Code), S_Arg) then
         Errno := Error_No_Error;
         return 0;
      else
         Errno := Error_Invalid_Value;
         return Unsigned_64'Last;
      end if;
   end Arch_PRCtl;

   function Open
      (Dir_FD    : Unsigned_64;
       Path_Addr : Unsigned_64;
       Path_Len  : Unsigned_64;
       Flags     : Unsigned_64;
       Errno     : out Errno_Value) return Unsigned_64
   is
      Path_IAddr : constant  Integer_Address := Integer_Address (Path_Addr);
      Path_SAddr : constant   System.Address := To_Address (Path_IAddr);
      Curr_Proc  : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Do_Close_On_Exec  : constant Boolean := (Flags and O_CLOEXEC)  /= 0;
      Do_Read           : constant Boolean := (Flags and O_RDONLY)   /= 0;
      Do_Write          : constant Boolean := (Flags and O_WRONLY)   /= 0;
      Dont_Follow       : constant Boolean := (Flags and O_NOFOLLOW) /= 0;
      Do_Append         : constant Boolean := (Flags and O_APPEND)   /= 0;

      Discard      : Boolean;
      Final_Path   : String (1 .. 1024);
      Final_Path_L : Natural;
      Open_Mode    : VFS.File.Access_Mode;
      Opened_File  : VFS.File.File_Acc;
      Opened_Stat  : VFS.File_Stat;
      New_Descr    : File_Description_Acc;
      File_Perms   : MAC.Filter_Permissions;
      Returned_FD  : Natural;
   begin
      if not Check_Userland_Access (Curr_Proc.Common_Map, Path_IAddr, Path_Len)
      then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      elsif Path_Len > Unsigned_64 (Natural'Last) then
         Errno := Error_String_Too_Long;
         return Unsigned_64'Last;
      end if;

      if        Do_Read and     Do_Write then Open_Mode := VFS.File.Read_Write;
      elsif     Do_Read and not Do_Write then Open_Mode := VFS.File.Read_Only;
      elsif not Do_Read and     Do_Write then Open_Mode := VFS.File.Write_Only;
      else Errno := Error_Invalid_Value; return Unsigned_64'Last; end if;

      declare
         Path : String (1 .. Natural (Path_Len))
            with Import, Address => Path_SAddr;
      begin
         Compound_AT_Path
            (AT_Directive => Natural (Dir_FD),
             Curr_Proc    => Curr_Proc,
             Extension    => Path,
             Result       => Final_Path,
             Count        => Final_Path_L);
         if Final_Path_L = 0 then
            Errno := Error_String_Too_Long;
            return Unsigned_64'Last;
         end if;
      end;

      if Curr_Proc.Is_MAC_Locked then
         File_Perms := MAC.Check_Path_Permissions
            (Path    => Final_Path (1 .. Final_Path_L),
             Filters => Curr_Proc.Perms.Filters);

         case Open_Mode is
            when VFS.File.Read_Write =>
               if File_Perms.Can_Read and File_Perms.Can_Write then
                  goto Resume;
               end if;
            when VFS.File.Read_Only =>
               if File_Perms.Can_Read then
                  goto Resume;
               end if;
            when VFS.File.Write_Only =>
               if File_Perms.Can_Write then
                  goto Resume;
               end if;
         end case;

         Errno := Error_Bad_Access;
         Execute_MAC_Failure ("open", Curr_Proc);
         return Unsigned_64'Last;
      end if;

   <<Resume>>
      Opened_File := Open
         (Final_Path (1 .. Final_Path_L), Open_Mode, not Dont_Follow);
      if Opened_File = null then
         Errno := Error_No_Entity;
         return Unsigned_64'Last;
      end if;

      if Do_Append then
         if not VFS.File.Stat (Opened_File, Opened_Stat) then
            Errno := Error_Invalid_Seek;
            return Unsigned_64'Last;
         end if;
         Discard := Set_Position (Opened_File, Opened_Stat.Byte_Size);
      end if;

      New_Descr := new File_Description'(
         Close_On_Exec => Do_Close_On_Exec,
         Description   => Description_File,
         Inner_File    => Opened_File
      );
      if Userland.Process.Add_File (Curr_Proc, New_Descr, Returned_FD) then
         Errno := Error_No_Error;
         return Unsigned_64 (Returned_FD);
      else
         Close (New_Descr);
         Errno := Error_Too_Many_Files;
         return Unsigned_64'Last;
      end if;
   end Open;

   function Close
      (File_D : Unsigned_64;
       Errno  : out Errno_Value) return Unsigned_64
   is
      Curr : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
   begin
      if not Userland.Process.Is_Valid_File (Curr, File_D) then
         Errno := Error_Bad_File;
         return Unsigned_64'Last;
      end if;

      Userland.Process.Remove_File (Curr, Natural (File_D));
      Errno := Error_No_Error;
      return 0;
   end Close;

   function Read
      (File_D : Unsigned_64;
       Buffer : Unsigned_64;
       Count  : Unsigned_64;
       Errno  : out Errno_Value) return Unsigned_64
   is
      Buf_IAddr : constant  Integer_Address := Integer_Address (Buffer);
      Buf_SAddr : constant   System.Address := To_Address (Buf_IAddr);
      Curr_Proc : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Final_Cnt : constant          Natural := Natural (Count);
      File      : File_Description_Acc;
      File_Mode : Access_Mode;
      Data      : Operation_Data (1 .. Final_Cnt)
         with Import, Address => Buf_SAddr;
      Ret_Count : Natural;
      Success   : Boolean;
   begin
      if not Check_Userland_Access (Curr_Proc.Common_Map, Buf_IAddr, Count)
      then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      end if;

      File := Userland.Process.Get_File (Curr_Proc, File_D);
      if File = null then
         Errno := Error_Bad_File;
         return Unsigned_64'Last;
      end if;

      case File.Description is
         when Description_File =>
            File_Mode := Get_Access (File.Inner_File);
            if File_Mode /= Read_Only and File_Mode /= Read_Write then
               Errno := Error_Invalid_Value;
               return Unsigned_64'Last;
            else
               VFS.File.Read (File.Inner_File, Data, Ret_Count, Success);
               if not Success then
                  Errno := Error_IO;
                  return Unsigned_64'Last;
               else
                  Errno := Error_No_Error;
                  return Unsigned_64 (Ret_Count);
               end if;
            end if;
         when Description_Reader_Pipe =>
            Errno := Error_No_Error;
            return Read (File.Inner_Reader_Pipe, Count, Buf_SAddr);
         when Description_Primary_PTY =>
            Errno := Error_No_Error;
            return IPC.PTY.Read (File.Inner_Primary_PTY, Count, Buf_SAddr);
         when Description_Secondary_PTY =>
            Errno := Error_No_Error;
            return IPC.PTY.Read (File.Inner_Secondary_PTY, Count, Buf_SAddr);
         when Description_Writer_Pipe =>
            Errno := Error_Bad_File;
            return Unsigned_64'Last;
      end case;
   end Read;

   function Write
      (File_D : Unsigned_64;
       Buffer : Unsigned_64;
       Count  : Unsigned_64;
       Errno  : out Errno_Value) return Unsigned_64
   is
      Buf_IAddr : constant  Integer_Address := Integer_Address (Buffer);
      Buf_SAddr : constant   System.Address := To_Address (Buf_IAddr);
      Curr_Proc : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Final_Cnt : constant          Natural := Natural (Count);
      File      : File_Description_Acc;
      File_Mode : Access_Mode;
      Data      : Operation_Data (1 .. Final_Cnt)
         with Import, Address => Buf_SAddr;
      Ret_Count : Natural;
      Success   : Boolean;
   begin
      if not Check_Userland_Access (Curr_Proc.Common_Map, Buf_IAddr, Count)
      then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      end if;

      File := Userland.Process.Get_File (Curr_Proc, File_D);
      if File = null then
         Errno := Error_Bad_File;
         return Unsigned_64'Last;
      end if;

      case File.Description is
         when Description_File =>
            File_Mode := Get_Access (File.Inner_File);
            if File_Mode /= Write_Only and File_Mode /= Read_Write then
               Errno := Error_Invalid_Value;
               return Unsigned_64'Last;
            else
               VFS.File.Write (File.Inner_File, Data, Ret_Count, Success);
               if not Success then
                  Errno := Error_IO;
                  return Unsigned_64'Last;
               else
                  Errno := Error_No_Error;
                  return Unsigned_64 (Ret_Count);
               end if;
            end if;
         when Description_Writer_Pipe =>
            Errno := Error_No_Error;
            return Write (File.Inner_Writer_Pipe, Count, Buf_SAddr);
         when Description_Primary_PTY =>
            Errno := Error_No_Error;
            return Write (File.Inner_Primary_PTY, Count, Buf_SAddr);
         when Description_Secondary_PTY =>
            Errno := Error_No_Error;
            return Write (File.Inner_Secondary_PTY, Count, Buf_SAddr);
         when Description_Reader_Pipe =>
            Errno := Error_Bad_File;
            return Unsigned_64'Last;
      end case;
   end Write;

   function Seek
      (File_D : Unsigned_64;
       Offset : Unsigned_64;
       Whence : Unsigned_64;
       Errno  : out Errno_Value) return Unsigned_64
   is
      Proc     : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      File     : File_Description_Acc;
      Stat_Val : VFS.File_Stat;
      Success  : Boolean;
   begin
      File := Get_File (Proc, File_D);
      if File = null then
         Errno := Error_Bad_File;
         return Unsigned_64'Last;
      end if;

      case File.Description is
         when Description_File =>
            if VFS.File.Stat (File.Inner_File, Stat_Val) then
               case Whence is
                  when SEEK_SET =>
                     Success := Set_Position (File.Inner_File, Offset);
                  when SEEK_CURRENT =>
                     Success := Set_Position
                        (File.Inner_File,
                         Get_Position (File.Inner_File) + Offset);
                  when SEEK_END =>
                     Success := Set_Position
                        (File.Inner_File, Stat_Val.Byte_Size + Offset);
                  when others =>
                     Errno := Error_Invalid_Value;
                     return Unsigned_64'Last;
               end case;

               if Success then
                  Errno := Error_No_Error;
                  return Get_Position (File.Inner_File);
               else
                  Errno := Error_Invalid_Seek;
                  return Unsigned_64'Last;
               end if;
            end if;
         when others =>
            null;
      end case;

      Errno := Error_Invalid_Seek;
      return Unsigned_64'Last;
   end Seek;

   function Get_Mmap_Prot (P : Unsigned_64) return Arch.MMU.Page_Permissions is
   begin
      return (
         User_Accesible => True,
         Read_Only      => (P and Protection_Write)    = 0,
         Executable     => (P and Protection_Execute) /= 0,
         Global         => False,
         Write_Through  => False
      );
   end Get_Mmap_Prot;

   function Mmap
      (Hint       : Unsigned_64;
       Length     : Unsigned_64;
       Protection : Unsigned_64;
       Flags      : Unsigned_64;
       File_D     : Unsigned_64;
       Offset     : Unsigned_64;
       Errno      : out Errno_Value) return Unsigned_64
   is
      pragma Unreferenced (Offset);
      Map_Flags : constant Arch.MMU.Page_Permissions :=
         Get_Mmap_Prot (Protection);
      Proc : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Map  : constant Page_Map_Acc     := Proc.Common_Map;
      Final_Hint : Unsigned_64 := Hint;
   begin
      if Proc.Is_MAC_Locked and not Proc.Perms.Caps.Can_Modify_Memory then
         Errno := Error_Bad_Access;
         Execute_MAC_Failure ("mmap", Proc);
         return Unsigned_64'Last;
      end if;

      --  Check that we got a length.
      if Length = 0 then
         Errno := Error_Invalid_Value;
         return Unsigned_64'Last;
      end if;

      --  Check for our own hint if none was provided.
      if Hint = 0 then
         if (Flags and Map_Fixed) /= 0 then
            Errno := Error_Invalid_Value;
            return Unsigned_64'Last;
         else
            Final_Hint      := Proc.Alloc_Base;
            Proc.Alloc_Base := Proc.Alloc_Base + Length;
         end if;
      end if;

      --  Do mmap anon or pass it to the VFS.
      if (Flags and Map_Anon) /= 0 then
         declare
            Addr : constant Virtual_Address :=
               Memory.Physical.Alloc (Interfaces.C.size_t (Length));
            Allocated : array (1 .. Length) of Unsigned_8
               with Import, Address => To_Address (Addr);
         begin
            Allocated := (others => 0);
            if not Memory.Virtual.Map_Range (
               Map,
               Virtual_Address (Final_Hint),
               Addr - Memory_Offset,
               Length,
               Map_Flags
            )
            then
               --  I dont really know what to return in this case.
               Errno := Error_Invalid_Value;
               return Unsigned_64'Last;
            else
               Errno := Error_No_Error;
               return Final_Hint;
            end if;
         end;
      else
         declare
            File : constant File_Description_Acc := Get_File (Proc, File_D);
         begin
            if File.Description /= Description_File or else
               not VFS.File.Mmap (
                  F           => File.Inner_File,
                  Address     => Virtual_Address (Final_Hint),
                  Length      => Length,
                  Map_Read    => True,
                  Map_Write   => not Map_Flags.Read_Only,
                  Map_Execute => Map_Flags.Executable
               )
            then
               Errno := Error_Bad_File;
               return Unsigned_64'Last;
            else
               Errno := Error_No_Error;
               return Final_Hint;
            end if;
         end;
      end if;
   end Mmap;

   function Munmap
      (Address    : Unsigned_64;
       Length     : Unsigned_64;
       Errno      : out Errno_Value) return Unsigned_64
   is
      pragma Unreferenced (Length);
      Proc : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Map : constant Memory.Virtual.Page_Map_Acc := Proc.Common_Map;
      Addr : constant Physical_Address :=
         Memory.Virtual.Virtual_To_Physical (Map, Virtual_Address (Address));
   begin
      if Proc.Is_MAC_Locked and not Proc.Perms.Caps.Can_Modify_Memory then
         Errno := Error_Bad_Access;
         Execute_MAC_Failure ("munmap", Proc);
         return Unsigned_64'Last;
      end if;

      --  We only support MAP_ANON and MAP_FIXED, so we can just assume we want
      --  to free.
      --  TODO: Actually unmap, not only free.
      Memory.Physical.Free (Interfaces.C.size_t (Addr));
      Errno := Error_No_Error;
      return 0;
   end Munmap;

   function Get_PID (Errno : out Errno_Value) return Unsigned_64 is
   begin
      Errno := Error_No_Error;
      return Unsigned_64 (Arch.Local.Get_Current_Process.Process_PID);
   end Get_PID;

   function Get_Parent_PID (Errno : out Errno_Value) return Unsigned_64 is
   begin
      Errno := Error_No_Error;
      return Unsigned_64 (Arch.Local.Get_Current_Process.Parent_PID);
   end Get_Parent_PID;

   function Exec
      (Path_Addr : Unsigned_64;
       Path_Len  : Unsigned_64;
       Argv_Addr : Unsigned_64;
       Argv_Len  : Unsigned_64;
       Envp_Addr : Unsigned_64;
       Envp_Len  : Unsigned_64;
       Errno     : out Errno_Value) return Unsigned_64
   is
      procedure Free is new Ada.Unchecked_Deallocation (String, String_Acc);
      type Arg_Arr is array (Natural range <>) of Unsigned_64;

      Th      : constant    Scheduler.TID := Arch.Local.Get_Current_Thread;
      Proc    : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Tmp_Map : Memory.Virtual.Page_Map_Acc;

      Path_IAddr : constant Integer_Address := Integer_Address (Path_Addr);
      Path_SAddr : constant  System.Address := To_Address (Path_IAddr);
      Path       : String (1 .. Natural (Path_Len))
         with Import, Address => Path_SAddr;
      Path_File  : File_Acc;
      File_Perms : MAC.Filter_Permissions;

      Argv_IAddr : constant Integer_Address := Integer_Address (Argv_Addr);
      Argv_SAddr : constant  System.Address := To_Address (Argv_IAddr);
      Envp_IAddr : constant Integer_Address := Integer_Address (Envp_Addr);
      Envp_SAddr : constant  System.Address := To_Address (Envp_IAddr);
   begin
      if not Check_Userland_Access (Proc.Common_Map, Path_IAddr, Path_Len) or
         not Check_Userland_Access (Proc.Common_Map, Argv_IAddr, Argv_Len) or
         not Check_Userland_Access (Proc.Common_Map, Envp_IAddr, Envp_Len)
      then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      end if;

      if Proc.Is_MAC_Locked then
         File_Perms := MAC.Check_Path_Permissions
            (Path    => Path,
             Filters => Proc.Perms.Filters);

         if not File_Perms.Can_Execute then
            Errno := Error_Bad_Access;
            Execute_MAC_Failure ("exec", Proc);
            return Unsigned_64'Last;
         end if;
      end if;

      Path_File := Open (Path, Read_Only);
      if Path_File = null then
         Errno := Error_No_Entity;
         return Unsigned_64'Last;
      end if;

      declare
         Argv : Arg_Arr (1 .. Natural (Argv_Len))
            with Import, Address => Argv_SAddr;
         Envp : Arg_Arr (1 .. Natural (Envp_Len))
            with Import, Address => Envp_SAddr;
         Args : Userland.Argument_Arr    (1 .. Argv'Length);
         Env  : Userland.Environment_Arr (1 .. Envp'Length);
      begin
         for I in Argv'Range loop
            declare
               Addr : constant System.Address :=
                  To_Address (Integer_Address (Argv (I)));
               Arg_Length : constant Natural := Lib.C_String_Length (Addr);
               Arg_String : String (1 .. Arg_Length)
                  with Import, Address => Addr;
            begin
               Args (I) := new String'(Arg_String);
            end;
         end loop;
         for I in Envp'Range loop
            declare
               Addr : constant System.Address :=
                  To_Address (Integer_Address (Envp (I)));
               Arg_Length : constant Natural := Lib.C_String_Length (Addr);
               Arg_String : String (1 .. Arg_Length)
                  with Import, Address => Addr;
            begin
               Env (I) := new String'(Arg_String);
            end;
         end loop;

         --  Free state.
         Userland.Process.Flush_Threads (Proc);
         Userland.Process.Flush_Exec_Files (Proc);

         --  Create a new map for the process.
         Userland.Process.Reroll_ASLR (Proc);
         Tmp_Map         := Proc.Common_Map;
         Proc.Common_Map := Memory.Virtual.New_Map;

         --  Start the actual program.
         if not Userland.Loader.Start_Program (Path_File, Args, Env, Proc) then
            Errno := Error_Bad_Access;
            return Unsigned_64'Last;
         end if;

         for Arg of Args loop
            Free (Arg);
         end loop;
         for En of Env loop
            Free (En);
         end loop;

         --  Free critical state now that we know wont be running.
         Userland.Process.Remove_Thread (Proc, Th);
         Memory.Virtual.Delete_Map (Tmp_Map);
         Scheduler.Bail;
         Errno := Error_No_Error;
         return 0;
      end;
   end Exec;

   function Clone
      (Callback  : Unsigned_64;
       Call_Arg  : Unsigned_64;
       Stack     : Unsigned_64;
       Flags     : Unsigned_64;
       TLS_Addr  : Unsigned_64;
       GP_State  : Arch.Context.GP_Context;
       FP_State  : Arch.Context.FP_Context;
       Errno     : out Errno_Value) return Unsigned_64
   is
      pragma Unreferenced (Call_Arg);
      Parent  : Process_Data_Acc := Arch.Local.Get_Current_Process;
      Child   : Process_Data_Acc;
      New_TID : Scheduler.TID;
      Ret     : Unsigned_64;

      Use_Parent : constant Boolean := (Flags and CLONE_PARENT) /= 0;
      Do_Thread  : constant Boolean := (Flags and CLONE_THREAD) /= 0;
   begin
      if Parent.Is_MAC_Locked and not Parent.Perms.Caps.Can_Spawn_Others then
         Errno := Error_Bad_Access;
         Execute_MAC_Failure ("clone", Parent);
         return Unsigned_64'Last;
      end if;

      if Use_Parent then
         Parent := Get_By_PID (Parent.Parent_PID);
         if Parent = null then
            Errno := Error_Invalid_Value;
            return Unsigned_64'Last;
         end if;
      end if;

      if Do_Thread then
         Child   := Parent;
         New_TID := Create_User_Thread
            (Address    => Integer_Address (Callback),
             Map        => Child.Common_Map,
             Stack_Addr => Stack,
             TLS_Addr   => TLS_Addr,
             PID        => Child.Process_PID);
         Ret := Unsigned_64 (New_TID);
      else
         Child := Create_Process (Parent);
         if Child = null then
            goto Block_Error;
         end if;

         Child.Common_Map := Memory.Virtual.Fork_Map (Parent.Common_Map);
         if Child.Common_Map = null then
            goto Block_Error;
         end if;

         for I in Parent.File_Table'Range loop
            Child.File_Table (I) := Duplicate (Parent.File_Table (I));
         end loop;
         New_TID := Scheduler.Create_User_Thread
            (GP_State => GP_State,
             FP_State => FP_State,
             Map      => Child.Common_Map,
             PID      => Child.Process_PID,
             TCB      => Arch.Local.Fetch_TCB);
         Ret := Unsigned_64 (Child.Process_PID);
      end if;

      if New_TID = 0 or else not Add_Thread (Child, New_TID) then
         goto Block_Error;
      end if;

      Errno := Error_No_Error;
      return Ret;

   <<Block_Error>>
      Errno := Error_Would_Block;
      return Unsigned_64'Last;
   end Clone;

   function Wait
      (Waited_PID, Exit_Addr, Options : Unsigned_64;
       Errno                          : out Errno_Value) return Unsigned_64
   is
      --  TODO: Support things like WCONTINUE once signals work.

      Addr : constant Integer_Address  := Integer_Address (Exit_Addr);
      Proc : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Exit_Value : Unsigned_32 with Address => To_Address (Addr), Import;
      Waited : Process_Data_Acc;
      Final_Waited_PID : Unsigned_64 := Waited_PID;
      Dont_Hang : constant Boolean := (Options and WNOHANG) /= 0;
   begin
      --  Fail on having to wait on the process group, we dont support that.
      if Waited_PID = 0 then
         Errno := Error_Invalid_Value;
         return Unsigned_64'Last;
      end if;

      --  Check whether there is anything to wait.
      for PID_Item of Proc.Children loop
         if PID_Item /= 0 then
            goto Proceed_Wait;
         end if;
      end loop;

      Errno := Error_Child;
      return Unsigned_64'Last;

   <<Proceed_Wait>>
      --  If -1, we have to wait for any of the children, else, wait for the
      --  passed PID.
      if Waited_PID = Unsigned_64 (Unsigned_32'Last) then
         loop
            for PID_Item of Proc.Children loop
               if PID_Item /= 0 then
                  Waited := Userland.Process.Get_By_PID (PID_Item);
                  if Waited /= null and then Waited.Did_Exit then
                     Final_Waited_PID := Unsigned_64 (PID_Item);
                     goto Waited_Exited;
                  end if;
               end if;
            end loop;

            if Dont_Hang then
               exit;
            end if;
            Scheduler.Yield;
         end loop;
      else
         --  Check the process is actually our child.
         if not Is_Child (Proc, Positive (Waited_PID)) then
            Errno := Error_Child;
            return Unsigned_64'Last;
         end if;

         Waited := Userland.Process.Get_By_PID (Natural (Waited_PID));
         if Waited /= null then
            loop
               if Waited.Did_Exit then
                  goto Waited_Exited;
               end if;
               if Dont_Hang then
                  exit;
               end if;
               Scheduler.Yield;
            end loop;
         end if;
      end if;

      --  If we get here, it means we are not blocking, and that the
      --  process has not exited, so lets return what we have to.
      Errno := Error_No_Error;
      return 0;

   <<Waited_Exited>>
      --  Set the return value if we are to.
      if Exit_Value'Address /= System.Null_Address then
         if not Check_Userland_Access (Proc.Common_Map, Addr, 4) then
            Errno := Error_Would_Fault;
            return Unsigned_64'Last;
         end if;
         Exit_Value := Wait_EXITED or Unsigned_32 (Waited.Exit_Code);
      end if;

      --  Now that we got the exit code, finally allow the process to die.
      Memory.Virtual.Delete_Map       (Waited.Common_Map);
      Userland.Process.Delete_Process (Waited);
      for PID_Item of Proc.Children loop
         if PID_Item = Natural (Final_Waited_PID) then
            PID_Item := 0;
         end if;
      end loop;
      Errno := Error_No_Error;
      return Final_Waited_PID;
   end Wait;

   function Uname
      (Address : Unsigned_64;
       Errno   : out Errno_Value) return Unsigned_64
   is
      Proc     : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      IAddr    : constant Integer_Address  := Integer_Address (Address);
      SAddr    : constant  System.Address  := To_Address (IAddr);
      UTS      : UTS_Name with Import, Address => SAddr;
      Host_Len : Networking.Hostname_Len;
   begin
      if not Check_Userland_Access (Proc.Common_Map, IAddr, UTS'Size / 8) then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      end if;

      Networking.Get_Hostname (UTS.Node_Name, Host_Len);
      UTS.Node_Name (Host_Len + 1) := Ada.Characters.Latin_1.NUL;

      UTS.System_Name (1 .. Config.Name'Length + 1) :=
         Config.Name & Ada.Characters.Latin_1.NUL;
      UTS.Release (1 .. Config.Version'Length + 1) :=
         Config.Version & Ada.Characters.Latin_1.NUL;
      UTS.Version (1 .. Config.Version'Length + 1) :=
         Config.Version & Ada.Characters.Latin_1.NUL;
      UTS.Machine (1 .. Config.Arch_Name'Length + 1) :=
         Config.Arch_Name & Ada.Characters.Latin_1.NUL;

      Errno := Error_No_Error;
      return 0;
   end Uname;

   function Set_Hostname
      (Address : Unsigned_64;
       Length  : Unsigned_64;
       Errno   : out Errno_Value) return Unsigned_64
   is
      Proc    : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Len     : constant          Natural := Natural (Length);
      IAddr   : constant  Integer_Address := Integer_Address (Address);
      SAddr   : constant   System.Address := To_Address (IAddr);
      Name    : String (1 .. Len) with Import, Address => SAddr;
      Success : Boolean;
   begin
      if Proc.Is_MAC_Locked and not Proc.Perms.Caps.Can_Manage_Networking then
         Errno := Error_Bad_Access;
         Execute_MAC_Failure ("set_hostname", Proc);
         return Unsigned_64'Last;
      end if;

      if not Check_Userland_Access (Proc.Common_Map, IAddr, Length) then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      end if;

      Networking.Set_Hostname (Name, Success);

      if not Success then
         Errno := Error_Invalid_Value;
         return Unsigned_64'Last;
      else
         Errno := Error_No_Error;
         return 0;
      end if;
   end Set_Hostname;

   function FStat
      (FD        : Unsigned_64;
       Stat_Addr : Unsigned_64;
       Errno     : out Errno_Value) return Unsigned_64
   is
      Proc       : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Stat_IAddr : constant  Integer_Address := Integer_Address (Stat_Addr);
      Stat_SAddr : constant   System.Address := To_Address (Stat_IAddr);
      File_Desc  : constant File_Description_Acc := Get_File (Proc, FD);
      Stat_Val   : VFS.File_Stat;
      ID         : Natural;
      Stat_Buf   : Stat with Import, Address => Stat_SAddr;
   begin
      if not Check_Userland_Access (Proc.Common_Map, Stat_IAddr, Stat'Size / 8)
      then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      elsif File_Desc = null then
         Errno := Error_Bad_File;
         return Unsigned_64'Last;
      end if;

      case File_Desc.Description is
         when Description_File =>
            if not VFS.File.Stat (File_Desc.Inner_File, Stat_Val) then
               Errno := Error_Bad_File;
               return Unsigned_64'Last;
            end if;

            ID := Get_Device_ID (File_Desc.Inner_File);
            Stat_Buf := (
               Device_Number => Unsigned_64 (ID),
               Inode_Number  => Unsigned_64 (Stat_Val.Unique_Identifier),
               Mode          => Unsigned_32 (Stat_Val.Mode),
               Number_Links  => Unsigned_32 (Stat_Val.Hard_Link_Count),
               UID           => 0,
               GID           => 0,
               Inner_Device  => Unsigned_64 (ID),
               File_Size     => Stat_Val.Byte_Size,
               Access_Time   =>
                  (Stat_Val.Access_Time.Seconds_Since_Epoch,
                   Stat_Val.Access_Time.Additional_Nanoseconds),
               Modify_Time   =>
                  (Stat_Val.Modification_Time.Seconds_Since_Epoch,
                   Stat_Val.Modification_Time.Additional_Nanoseconds),
               Create_Time   =>
                  (Stat_Val.Creation_Time.Seconds_Since_Epoch,
                   Stat_Val.Creation_Time.Additional_Nanoseconds),
               Block_Size    => Unsigned_64 (Stat_Val.IO_Block_Size),
               Block_Count   => Stat_Val.IO_Block_Count
            );

            --  Set the access part of mode.
            case Stat_Val.Type_Of_File is
               when VFS.File_Regular =>
                  Stat_Buf.Mode := Stat_Buf.Mode or Stat_IFREG;
               when VFS.File_Directory =>
                  Stat_Buf.Mode := Stat_Buf.Mode or Stat_IFDIR;
               when VFS.File_Symbolic_Link =>
                  Stat_Buf.Mode := Stat_Buf.Mode or Stat_IFLNK;
               when VFS.File_Character_Device =>
                  Stat_Buf.Mode := Stat_Buf.Mode or Stat_IFCHR;
               when VFS.File_Block_Device =>
                  Stat_Buf.Mode := Stat_Buf.Mode or Stat_IFBLK;
            end case;
         when Description_Reader_Pipe | Description_Writer_Pipe |
              Description_Primary_PTY | Description_Secondary_PTY =>
            Stat_Buf := (
               Device_Number => 0,
               Inode_Number  => 1,
               Mode          => Stat_IFIFO,
               Number_Links  => 1,
               UID           => 0,
               GID           => 0,
               Inner_Device  => 1,
               File_Size     => 512,
               Access_Time   => (Seconds => 0, Nanoseconds => 0),
               Modify_Time   => (Seconds => 0, Nanoseconds => 0),
               Create_Time   => (Seconds => 0, Nanoseconds => 0),
               Block_Size    => 512,
               Block_Count   => 1
            );
      end case;

      Errno := Error_No_Error;
      return 0;
   end FStat;

   function Get_CWD
      (Buffer : Unsigned_64;
       Length : Unsigned_64;
       Errno  : out Errno_Value) return Unsigned_64
   is
      Proc  : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      IAddr : constant  Integer_Address := Integer_Address (Buffer);
      SAddr : constant   System.Address := To_Address (IAddr);
      Len   : constant          Natural := Natural (Length);
      Path  : String (1 .. Len) with Import, Address => SAddr;
   begin
      if not Check_Userland_Access (Proc.Common_Map, IAddr, Length) then
         Errno := Error_Would_Fault;
         return 0;
      end if;
      if Len = 0 then
         Errno := Error_Invalid_Value;
         return 0;
      end if;
      if Len < Proc.Current_Dir_Len then
         Errno := Error_Not_Big_Enough;
         return 0;
      end if;

      Path (1 .. Proc.Current_Dir_Len) :=
         Proc.Current_Dir (1 .. Proc.Current_Dir_Len);
      Errno := Error_No_Error;
      return Buffer;
   end Get_CWD;

   function Chdir
      (Path_Addr : Unsigned_64;
       Path_Len  : Unsigned_64;
       Errno     : out Errno_Value) return Unsigned_64
   is
      IAddr : constant  Integer_Address := Integer_Address (Path_Addr);
      SAddr : constant   System.Address := To_Address (IAddr);
      Proc  : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Path  : String (1 .. Natural (Path_Len)) with Import, Address => SAddr;
      Final_Path   : String (1 .. 1024);
      Final_Path_L : Natural;
      File         : VFS.File.File_Acc;
   begin
      if not Check_Userland_Access (Proc.Common_Map, IAddr, Path_Len) then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      end if;

      VFS.Compound_Path
         (Base      => Proc.Current_Dir (1 .. Proc.Current_Dir_Len),
          Extension => Path,
          Result    => Final_Path,
          Count     => Final_Path_L);
      if Final_Path_L = 0 then
         Errno := Error_String_Too_Long;
         return Unsigned_64'Last;
      end if;

      File := Open (Final_Path (1 .. Final_Path_L), VFS.File.Read_Only, False);
      if File = null then
         Errno := Error_No_Entity;
         return Unsigned_64'Last;
      elsif Final_Path_L > Proc.Current_Dir'Length then
         Errno := Error_String_Too_Long;
         return Unsigned_64'Last;
      end if;

      Close (File);
      Proc.Current_Dir_Len := Final_Path_L;
      Proc.Current_Dir (1 .. Final_Path_L) := Final_Path (1 .. Final_Path_L);
      Errno := Error_No_Error;
      return 0;
   end Chdir;

   function IOCTL
      (FD       : Unsigned_64;
       Request  : Unsigned_64;
       Argument : Unsigned_64;
       Errno    : out Errno_Value) return Unsigned_64
   is
      I_Arg : constant      Integer_Address := Integer_Address (Argument);
      S_Arg : constant       System.Address := To_Address (I_Arg);
      Proc  : constant     Process_Data_Acc := Arch.Local.Get_Current_Process;
      File  : constant File_Description_Acc := Get_File (Proc, FD);
      Succ  : Boolean;
   begin
      if not Check_Userland_Access (Proc.Common_Map, I_Arg, 8) then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      elsif File = null then
         Errno := Error_Not_A_TTY;
         return Unsigned_64'Last;
      end if;

      case File.Description is
         when Description_File =>
            Succ := IO_Control (File.Inner_File, Request, S_Arg);
         when Description_Primary_PTY =>
            Succ := IO_Control (File.Inner_Primary_PTY, Request, S_Arg);
         when Description_Secondary_PTY =>
            Succ := IO_Control (File.Inner_Secondary_PTY, Request, S_Arg);
         when others =>
            Succ := False;
      end case;

      if Succ then
         Errno := Error_No_Error;
         return 0;
      else
         Errno := Error_Not_A_TTY;
         return Unsigned_64'Last;
      end if;
   end IOCTL;

   function Sched_Yield (Errno : out Errno_Value) return Unsigned_64 is
   begin
      Scheduler.Yield;
      Errno := Error_No_Error;
      return 0;
   end Sched_Yield;

   function Set_Deadlines
      (Run_Time, Period : Unsigned_64;
       Errno : out Errno_Value) return Unsigned_64
   is
      Proc : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Thre : constant    Scheduler.TID := Arch.Local.Get_Current_Thread;
   begin
      if Proc.Is_MAC_Locked and not Proc.Perms.Caps.Can_Change_Scheduling then
         Errno := Error_Bad_Access;
         Execute_MAC_Failure ("setdeadlines", Proc);
         return Unsigned_64'Last;
      elsif not Scheduler.Set_Deadlines
         (Thre, Positive (Run_Time), Positive (Period))
      then
         Errno := Error_Invalid_Value;
         return Unsigned_64'Last;
      else
         Errno := Error_No_Error;
         return 0;
      end if;
   end Set_Deadlines;

   function Pipe
      (Result_Addr : Unsigned_64;
       Flags       : Unsigned_64;
       Errno       : out Errno_Value) return Unsigned_64
   is
      Ad   : constant Integer_Address  := Integer_Address (Result_Addr);
      Proc : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Res  : array (1 .. 2) of Integer with Import, Address => To_Address (Ad);
      Reader : Pipe_Reader_Acc;
      Writer : Pipe_Writer_Acc;
      Reader_Desc, Writer_Desc : File_Description_Acc;
   begin
      if not Check_Userland_Access (Proc.Common_Map, Ad, Res'Size / 8) then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      end if;

      Create_Pair (Writer, Reader, (Flags and O_NONBLOCK) = 0);
      Reader_Desc := new File_Description'(
         Close_On_Exec     => False,
         Description       => Description_Reader_Pipe,
         Inner_Reader_Pipe => Reader
      );
      Writer_Desc := new File_Description'(
         Close_On_Exec     => False,
         Description       => Description_Writer_Pipe,
         Inner_Writer_Pipe => Writer
      );
      if not Userland.Process.Add_File (Proc, Reader_Desc, Res (1)) or
         not Userland.Process.Add_File (Proc, Writer_Desc, Res (2))
      then
         Close (Reader);
         Close (Reader_Desc);
         Close (Writer);
         Close (Writer_Desc);
         Errno := Error_Too_Many_Files;
         return Unsigned_64'Last;
      else
         Errno := Error_No_Error;
         return 0;
      end if;
   end Pipe;

   function Dup
      (Old_FD : Unsigned_64;
       New_FD : Unsigned_64;
       Flags  : Unsigned_64;
       Errno  : out Errno_Value) return Unsigned_64
   is
      Process  : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Old_File : constant File_Description_Acc := Get_File (Process, Old_FD);
      Do_Ignore_New    : constant Boolean := (Flags and DUP_IGNORE_NEWFD) /= 0;
      Do_Close_On_Exec : constant Boolean := (Flags and O_CLOEXEC)        /= 0;
      New_File  : File_Description_Acc;
      Result_FD : Natural;
   begin
      if Old_File = null then
         Errno := Error_Bad_File;
         return Unsigned_64'Last;
      end if;

      if Do_Ignore_New then
         New_File := Duplicate (Old_File);
         New_File.Close_On_Exec := Do_Close_On_Exec;
         if not Userland.Process.Add_File (Process, New_File, Result_FD) then
            Errno := Error_Too_Many_Files;
            return Unsigned_64'Last;
         else
            Errno := Error_No_Error;
            return Unsigned_64 (Result_FD);
         end if;
      else
         if New_FD /= Old_FD and then not Userland.Process.Replace_File
            (Process, Duplicate (Old_File), Natural (New_FD))
         then
            Errno := Error_Bad_File;
            return Unsigned_64'Last;
         else
            Errno := Error_No_Error;
            return New_FD;
         end if;
      end if;
   end Dup;

   function Rename
      (Source_FD   : Unsigned_64;
       Source_Addr : Unsigned_64;
       Source_Len  : Unsigned_64;
       Target_FD   : Unsigned_64;
       Target_Addr : Unsigned_64;
       Target_Len  : Unsigned_64;
       Flags       : Unsigned_64;
       Errno       : out Errno_Value) return Unsigned_64
   is
      Proc      : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Src_IAddr : constant  Integer_Address := Integer_Address (Source_Addr);
      Src_SAddr : constant   System.Address := To_Address (Src_IAddr);
      Tgt_IAddr : constant  Integer_Address := Integer_Address (Target_Addr);
      Tgt_SAddr : constant   System.Address := To_Address (Tgt_IAddr);
      Do_Keep   : constant Boolean := (Flags and RENAME_NOREPLACE) /= 0;
      Source_Path   : String (1 .. 1024);
      Source_Path_L : Natural;
      Target_Path   : String (1 .. 1024);
      Target_Path_L : Natural;
   begin
      if not Check_Userland_Access (Proc.Common_Map, Src_IAddr, Source_Len) or
         not Check_Userland_Access (Proc.Common_Map, Tgt_IAddr, Target_Len)
      then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      elsif Source_Len > Unsigned_64 (Natural'Last) or
            Target_Len > Unsigned_64 (Natural'Last)
      then
         Errno := Error_String_Too_Long;
         return Unsigned_64'Last;
      end if;

      declare
         Src : String (1 .. Natural (Source_Len))
            with Import, Address => Src_SAddr;
         Tgt : String (1 .. Natural (Target_Len))
            with Import, Address => Tgt_SAddr;
      begin
         Compound_AT_Path
            (AT_Directive => Natural (Source_FD),
             Curr_Proc    => Proc,
             Extension    => Src,
             Result       => Source_Path,
             Count        => Source_Path_L);
         Compound_AT_Path
            (AT_Directive => Natural (Target_FD),
             Curr_Proc    => Proc,
             Extension    => Tgt,
             Result       => Target_Path,
             Count        => Target_Path_L);
         if Source_Path_L = 0 or Target_Path_L = 0 then
            Errno := Error_String_Too_Long;
            return Unsigned_64'Last;
         end if;

         if VFS.File.Rename
            (Source_Path (1 .. Source_Path_L),
             Target_Path (1 .. Target_Path_L),
             Do_Keep)
         then
            Errno := Error_No_Error;
            return 0;
         else
            Errno := Error_IO;
            return Unsigned_64'Last;
         end if;
      end;
   end Rename;

   function Sysconf
      (Request : Unsigned_64;
       Errno   : out Errno_Value) return Unsigned_64
   is
      function CCount return Positive renames Arch.Hooks.Get_Active_Core_Count;

      Stats  : Memory.Physical.Statistics;
      Result : Unsigned_64;
      PS     : constant := Page_Size;
      Aval   : Memory.Size renames Stats.Available;
   begin
      Memory.Physical.Get_Statistics (Stats);
      case Request is
         when SC_PAGESIZE      => Result := PS;
         when SC_OPEN_MAX      => Result := Process_File_Table'Length;
         when SC_HOST_NAME_MAX => Result := Networking.Hostname_Max_Len;
         when SC_AVPHYS_PAGES  => Result := Unsigned_64 (Stats.Free) / PS;
         when SC_PHYS_PAGES    => Result := Unsigned_64 (Aval)       / PS;
         when SC_NPROC_ONLN    => Result := Unsigned_64 (CCount);
         when SC_TOTAL_PAGES   => Result := Unsigned_64 (Stats.Total) / PS;
         when others =>
            Errno := Error_Invalid_Value;
            return Unsigned_64'Last;
      end case;

      Errno := Error_No_Error;
      return Result;
   end Sysconf;

   function Spawn
      (Path_Addr : Unsigned_64;
       Path_Len  : Unsigned_64;
       Argv_Addr : Unsigned_64;
       Argv_Len  : Unsigned_64;
       Envp_Addr : Unsigned_64;
       Envp_Len  : Unsigned_64;
       Errno     : out Errno_Value) return Unsigned_64
   is
      procedure Free is new Ada.Unchecked_Deallocation (String, String_Acc);
      type Arg_Arr is array (Natural range <>) of Unsigned_64;

      Proc       : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Path_IAddr : constant Integer_Address := Integer_Address (Path_Addr);
      Path_SAddr : constant  System.Address := To_Address (Path_IAddr);
      Path       : String (1 .. Natural (Path_Len))
         with Import, Address => Path_SAddr;
      Path_File  : File_Acc;
      File_Perms : MAC.Filter_Permissions;
      Child      : Process_Data_Acc;
      Argv_IAddr : constant Integer_Address := Integer_Address (Argv_Addr);
      Argv_SAddr : constant  System.Address := To_Address (Argv_IAddr);
      Envp_IAddr : constant Integer_Address := Integer_Address (Envp_Addr);
      Envp_SAddr : constant  System.Address := To_Address (Envp_IAddr);
   begin
      if not Check_Userland_Access (Proc.Common_Map, Path_IAddr, Path_Len) or
         not Check_Userland_Access (Proc.Common_Map, Argv_IAddr, Argv_Len) or
         not Check_Userland_Access (Proc.Common_Map, Envp_IAddr, Envp_Len)
      then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      elsif Proc.Is_MAC_Locked then
         File_Perms := MAC.Check_Path_Permissions
            (Path    => Path,
             Filters => Proc.Perms.Filters);

         if not Proc.Perms.Caps.Can_Spawn_Others or not File_Perms.Can_Execute
         then
            Errno := Error_Bad_Access;
            Execute_MAC_Failure ("spawn", Proc);
            return Unsigned_64'Last;
         end if;
      end if;

      Path_File := Open (Path, Read_Only);
      if Path_File = null then
         Errno := Error_No_Entity;
         return Unsigned_64'Last;
      end if;

      Child := Create_Process (Proc);
      if Child = null then
         Errno := Error_Would_Block;
         return Unsigned_64'Last;
      end if;

      for I in Proc.File_Table'Range loop
         Child.File_Table (I) := Duplicate (Proc.File_Table (I));
      end loop;

      declare
         Argv : Arg_Arr (1 .. Natural (Argv_Len))
            with Import, Address => Argv_SAddr;
         Envp : Arg_Arr (1 .. Natural (Envp_Len))
            with Import, Address => Envp_SAddr;
         Args : Userland.Argument_Arr    (1 .. Argv'Length);
         Env  : Userland.Environment_Arr (1 .. Envp'Length);
      begin
         for I in Argv'Range loop
            declare
               Addr : constant System.Address :=
                  To_Address (Integer_Address (Argv (I)));
               Arg_Length : constant Natural := Lib.C_String_Length (Addr);
               Arg_String : String (1 .. Arg_Length)
                  with Import, Address => Addr;
            begin
               Args (I) := new String'(Arg_String);
            end;
         end loop;
         for I in Envp'Range loop
            declare
               Addr : constant System.Address :=
                  To_Address (Integer_Address (Envp (I)));
               Arg_Length : constant Natural := Lib.C_String_Length (Addr);
               Arg_String : String (1 .. Arg_Length)
                  with Import, Address => Addr;
            begin
               Env (I) := new String'(Arg_String);
            end;
         end loop;

         --  Create a new map for the process.
         Userland.Process.Flush_Exec_Files (Child);
         Userland.Process.Reroll_ASLR (Child);
         Child.Common_Map := Memory.Virtual.New_Map;

         --  Start the actual program.
         if not Userland.Loader.Start_Program (Path_File, Args, Env, Child)
         then
            Errno := Error_Bad_Access;
            return Unsigned_64'Last;
         end if;

         for Arg of Args loop
            Free (Arg);
         end loop;
         for En of Env loop
            Free (En);
         end loop;

         Errno := Error_No_Error;
         return Unsigned_64 (Child.Process_PID);
      end;
   end Spawn;

   function Get_Thread_Sched
      (Errno : out Errno_Value) return Unsigned_64
   is
      Ret  : Unsigned_64            := 0;
      Curr : constant Scheduler.TID := Arch.Local.Get_Current_Thread;
   begin
      if Scheduler.Is_Mono_Thread (Curr) then
         Ret := Ret or Thread_MONO;
      end if;

      Errno := Error_No_Error;
      return Ret;
   end Get_Thread_Sched;

   function Set_Thread_Sched
      (Flags : Unsigned_64;
       Errno : out Errno_Value) return Unsigned_64
   is
      Proc : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Curr : constant Scheduler.TID    := Arch.Local.Get_Current_Thread;
   begin
      if Proc.Is_MAC_Locked and not Proc.Perms.Caps.Can_Change_Scheduling then
         Errno := Error_Bad_Access;
         Execute_MAC_Failure ("set_thread_sched", Proc);
         return Unsigned_64'Last;
      end if;

      Scheduler.Set_Mono_Thread (Curr, (Flags and Thread_MONO) /= 0);
      Errno := Error_No_Error;
      return 0;
   end Set_Thread_Sched;

   function Fcntl
      (FD       : Unsigned_64;
       Command  : Unsigned_64;
       Argument : Unsigned_64;
       Errno    : out Errno_Value) return Unsigned_64
   is
      Proc : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      File : File_Description_Acc := Get_File (Proc, FD);
      Temp : Boolean;
      Returned : Unsigned_64 := 0;
   begin
      if File = null then
         Errno := Error_Bad_File;
         return Unsigned_64'Last;
      end if;

      case Command is
         when F_DUPFD | F_DUPFD_CLOEXEC =>
            Returned := Dup (FD, 0, DUP_IGNORE_NEWFD, Errno);
            if Returned = Unsigned_64'Last then
               return Returned;
            end if;
            File := Get_File (Proc, Returned);
            File.Close_On_Exec := Command = F_DUPFD_CLOEXEC;
         when F_GETFD =>
            if File.Close_On_Exec then
               Returned := FD_CLOEXEC;
            end if;
         when F_SETFD =>
            File.Close_On_Exec := (Argument and FD_CLOEXEC) /= 0;
         when F_GETFL =>
            case File.Description is
               when Description_Reader_Pipe =>
                  if Is_Blocking (File.Inner_Reader_Pipe) then
                     Returned := O_NONBLOCK;
                  end if;
               when Description_Writer_Pipe =>
                  if Is_Blocking (File.Inner_Writer_Pipe) then
                     Returned := O_NONBLOCK;
                  end if;
               when others =>
                  null;
            end case;
         when F_SETFL =>
            Temp := (Argument and O_NONBLOCK) = 0;
            case File.Description is
               when Description_Reader_Pipe =>
                  Set_Blocking (File.Inner_Reader_Pipe, Temp);
               when Description_Writer_Pipe =>
                  Set_Blocking (File.Inner_Writer_Pipe, Temp);
               when others =>
                  null;
            end case;
         when others =>
            Errno := Error_Invalid_Value;
            return Unsigned_64'Last;
      end case;

      Errno := Error_No_Error;
      return Returned;
   end Fcntl;

   procedure Exit_Thread (Errno : out Errno_Value) is
   begin
      Errno := Error_No_Error;
      Scheduler.Bail;
   end Exit_Thread;

   function Get_Random
     (Address : Unsigned_64;
      Length  : Unsigned_64;
      Errno   : out Errno_Value) return Unsigned_64
   is
      Proc   : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      IAddr  : constant  Integer_Address := Integer_Address (Address);
      SAddr  : constant   System.Address := To_Address (IAddr);
      Result : Cryptography.Random.Crypto_Data (1 .. Natural (Length / 4))
         with Import, Address => SAddr;
   begin
      if Proc.Is_MAC_Locked and not Proc.Perms.Caps.Can_Access_Entropy then
         Errno := Error_Bad_Access;
         Execute_MAC_Failure ("getrandom", Proc);
         return Unsigned_64'Last;
      elsif not Check_Userland_Access (Proc.Common_Map, IAddr, Length) then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      else
         Cryptography.Random.Fill_Data (Result);
         Errno := Error_No_Error;
         return Result'Length * 4;
      end if;
   end Get_Random;

   function MProtect
     (Address    : Unsigned_64;
      Length     : Unsigned_64;
      Protection : Unsigned_64;
      Errno      : out Errno_Value) return Unsigned_64
   is
      Proc  : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Map   : constant Page_Map_Acc     := Proc.Common_Map;
      Flags : constant Arch.MMU.Page_Permissions := Get_Mmap_Prot (Protection);
      Addr  : constant Integer_Address := Integer_Address (Address);
   begin
      if Proc.Is_MAC_Locked and not Proc.Perms.Caps.Can_Modify_Memory then
         Errno := Error_Bad_Access;
         Execute_MAC_Failure ("mprotect", Proc);
         return Unsigned_64'Last;
      end if;

      if not Check_Userland_Access (Proc.Common_Map, Addr, Length) or else
         not Remap_Range (Map, Addr, Length, Flags)
      then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      else
         Errno := Error_No_Error;
         return 0;
      end if;
   end MProtect;

   function Set_MAC_Capabilities
      (Bits  : Unsigned_64;
       Errno : out Errno_Value) return Unsigned_64
   is
      P  : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      S1 : constant Boolean := (Bits and MAC_CAP_SCHED)   /= 0;
      S2 : constant Boolean := (Bits and MAC_CAP_SPAWN)   /= 0;
      S3 : constant Boolean := (Bits and MAC_CAP_ENTROPY) /= 0;
      S4 : constant Boolean := (Bits and MAC_CAP_SYS_MEM) /= 0;
      S5 : constant Boolean := (Bits and MAC_CAP_USE_NET) /= 0;
      S6 : constant Boolean := (Bits and MAC_CAP_SYS_NET) /= 0;
      S7 : constant Boolean := (Bits and MAC_CAP_SYS_MNT) /= 0;
      S8 : constant Boolean := (Bits and MAC_CAP_SYS_PWR) /= 0;
      S9 : constant Boolean := (Bits and MAC_CAP_PTRACE)  /= 0;
   begin
      if P.Is_MAC_Locked then
         P.Perms.Caps := (
            Can_Change_Scheduling => P.Perms.Caps.Can_Change_Scheduling and S1,
            Can_Spawn_Others      => P.Perms.Caps.Can_Spawn_Others      and S2,
            Can_Access_Entropy    => P.Perms.Caps.Can_Access_Entropy    and S3,
            Can_Modify_Memory     => P.Perms.Caps.Can_Modify_Memory     and S4,
            Can_Use_Networking    => P.Perms.Caps.Can_Use_Networking    and S5,
            Can_Manage_Networking => P.Perms.Caps.Can_Manage_Networking and S6,
            Can_Manage_Mounts     => P.Perms.Caps.Can_Manage_Mounts     and S7,
            Can_Manage_Power      => P.Perms.Caps.Can_Manage_Power      and S8,
            Can_Trace_Children    => P.Perms.Caps.Can_Trace_Children    and S9
         );
      else
         P.Perms.Caps := (
            Can_Change_Scheduling => S1,
            Can_Spawn_Others      => S2,
            Can_Access_Entropy    => S3,
            Can_Modify_Memory     => S4,
            Can_Use_Networking    => S5,
            Can_Manage_Networking => S6,
            Can_Manage_Mounts     => S7,
            Can_Manage_Power      => S8,
            Can_Trace_Children    => S9
         );
      end if;

      Errno := Error_No_Error;
      return 0;
   end Set_MAC_Capabilities;

   function Lock_MAC (Errno : out Errno_Value) return Unsigned_64 is
      Proc : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
   begin
      if Proc.Is_MAC_Locked then
         Errno := Error_Bad_Access;
         Execute_MAC_Failure ("lock_mac", Proc);
         return Unsigned_64'Last;
      else
         Proc.Is_MAC_Locked := True;
         Errno := Error_No_Error;
         return 0;
      end if;
   end Lock_MAC;

   function Add_MAC_Filter
      (Filter_Addr : Unsigned_64;
       Errno       : out Errno_Value) return Unsigned_64
   is
      Proc   : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Addr   : constant Integer_Address := Integer_Address (Filter_Addr);
      Filt   : MAC_Filter with Import, Address => To_Address (Addr);
      Xlated : MAC.Filter;
   begin
      if not Check_Userland_Access (Proc.Common_Map, Addr, Filt'Size / 8) then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      end if;

      Xlated :=
         (Path   => Filt.Path,
          Length => Filt.Length,
          Perms  =>
            (Includes_Contents => (Filt.Perms and MAC_FILTER_CONTENTS) /= 0,
             Deny_Instead      => (Filt.Perms and MAC_FILTER_DENY)     /= 0,
             Can_Read          => (Filt.Perms and MAC_FILTER_READ)     /= 0,
             Can_Write         => (Filt.Perms and MAC_FILTER_WRITE)    /= 0,
             Can_Execute       => (Filt.Perms and MAC_FILTER_EXEC)     /= 0,
             Can_Append_Only   => (Filt.Perms and MAC_FILTER_APPEND)   /= 0,
             Can_Lock_Files    => (Filt.Perms and MAC_FILTER_FLOCK)    /= 0));

      if MAC.Is_Conflicting (Xlated, Proc.Perms.Filters) then
         Errno := Error_Invalid_Value;
         return Unsigned_64'Last;
      else
         for Item of Proc.Perms.Filters loop
            if Item.Length = 0 then
               Item := Xlated;
               goto Func_End;
            end if;
         end loop;
         Errno := Error_Would_Block;
         return Unsigned_64'Last;
      end if;

   <<Func_End>>
      Errno := Error_No_Error;
      return 0;
   end Add_MAC_Filter;

   function Set_MAC_Enforcement
      (Action : Unsigned_64;
       Errno  : out Errno_Value) return Unsigned_64
   is
      Proc : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
   begin
      if Proc.Is_MAC_Locked then
         Errno := Error_Bad_Access;
         Execute_MAC_Failure ("set_mac_enforcement", Proc);
         return Unsigned_64'Last;
      end if;

      case Action is
         when MAC_DENY            => Proc.Perms.Action := MAC.Deny;
         when MAC_DENY_AND_SCREAM => Proc.Perms.Action := MAC.Deny_And_Scream;
         when MAC_KILL            => Proc.Perms.Action := MAC.Kill;
         when others              => null;
      end case;

      Errno := Error_No_Error;
      return 0;
   end Set_MAC_Enforcement;

   procedure Execute_MAC_Failure (Name : String; Curr_Proc : Process_Data_Acc)
   is
      Discard : Errno_Value;
   begin
      case Curr_Proc.Perms.Action is
         when MAC.Deny =>
            null;
         when MAC.Deny_And_Scream =>
            Lib.Messages.Put      ("PID: ");
            Lib.Messages.Put      (Curr_Proc.Process_PID);
            Lib.Messages.Put_Line (", MAC failure: " & Name);
         when MAC.Kill =>
            --  TODO: Kill and not exit, once we have such a thing.
            --  The semantics of SIGTERM and SIGKILL matter.
         --  https://linuxhandbook.com/content/images/2020/06/dont-sigkill.jpeg
            Do_Exit (Curr_Proc, 42);
      end case;
   end Execute_MAC_Failure;

   function Mount
      (Source_Addr : Unsigned_64;
       Source_Len  : Unsigned_64;
       Target_Addr : Unsigned_64;
       Target_Len  : Unsigned_64;
       FSType      : Unsigned_64;
       MountFlags  : Unsigned_64;
       Errno       : out Errno_Value) return Unsigned_64
   is
      pragma Unreferenced (MountFlags);
      Proc       : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Src_IAddr  : constant  Integer_Address := Integer_Address (Source_Addr);
      Tgt_IAddr  : constant  Integer_Address := Integer_Address (Target_Addr);
      Src_Addr   : constant   System.Address := To_Address (Src_IAddr);
      Tgt_Addr   : constant   System.Address := To_Address (Tgt_IAddr);
      Parsed_Typ : VFS.FS_Type;
   begin
      if not Check_Userland_Access (Proc.Common_Map, Src_IAddr, Source_Len) or
         not Check_Userland_Access (Proc.Common_Map, Tgt_IAddr, Target_Len)
      then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      elsif Source_Len > Unsigned_64 (Natural'Last) or
            Target_Len > Unsigned_64 (Natural'Last)
      then
         Errno := Error_String_Too_Long;
         return Unsigned_64'Last;
      elsif Proc.Is_MAC_Locked and not Proc.Perms.Caps.Can_Manage_Mounts then
         Errno := Error_Bad_Access;
         Execute_MAC_Failure ("mount", Proc);
         return Unsigned_64'Last;
      end if;

      case FSType is
         when MNT_EXT => Parsed_Typ := VFS.FS_EXT;
         when MNT_FAT => Parsed_Typ := VFS.FS_FAT;
         when others  =>
            Errno := Error_Invalid_Value;
            return Unsigned_64'Last;
      end case;

      declare
         Source : String (1 .. Natural (Source_Len))
            with Import, Address => Src_Addr;
         Target : String (1 .. Natural (Target_Len))
            with Import, Address => Tgt_Addr;
      begin
         if VFS.Mount (Source, Target, Parsed_Typ) then
            Errno := Error_No_Error;
            return 0;
         else
            Errno := Error_IO;
            return Unsigned_64'Last;
         end if;
      end;
   end Mount;

   function Umount
      (Path_Addr : Unsigned_64;
       Path_Len  : Unsigned_64;
       Flags     : Unsigned_64;
       Errno     : out Errno_Value) return Unsigned_64
   is
      Curr_Proc  : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Path_IAddr : constant  Integer_Address := Integer_Address (Path_Addr);
      Path_SAddr : constant  System.Address  := To_Address (Path_IAddr);
      Flag_Force : constant Boolean := (Flags and MNT_FORCE) /= 0;
   begin
      if not Check_Userland_Access (Curr_Proc.Common_Map, Path_IAddr, Path_Len)
      then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      elsif Path_Len > Unsigned_64 (Natural'Last) then
         Errno := Error_String_Too_Long;
         return Unsigned_64'Last;
      elsif Curr_Proc.Is_MAC_Locked and
            not Curr_Proc.Perms.Caps.Can_Manage_Mounts
      then
         Errno := Error_Bad_Access;
         Execute_MAC_Failure ("umount", Curr_Proc);
         return Unsigned_64'Last;
      end if;

      declare
         Path : String (1 .. Natural (Path_Len))
            with Import, Address => Path_SAddr;
      begin
         if VFS.Unmount (Path, Flag_Force) then
            Errno := Error_No_Error;
            return 0;
         else
            Errno := Error_Busy;
            return Unsigned_64'Last;
         end if;
      end;
   end Umount;

   function Readlink
      (Dir_FD      : Unsigned_64;
       Path_Addr   : Unsigned_64;
       Path_Len    : Unsigned_64;
       Buffer_Addr : Unsigned_64;
       Buffer_Len  : Unsigned_64;
       Errno       : out Errno_Value) return Unsigned_64
   is
      Proc : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Path_IAddr   : constant Integer_Address := Integer_Address (Path_Addr);
      Buffer_IAddr : constant Integer_Address := Integer_Address (Buffer_Addr);
      Path_Add     : constant System.Address  := To_Address (Path_IAddr);
      Buffer_Add   : constant System.Address  := To_Address (Buffer_IAddr);
      Final_Path   : String (1 .. 1024);
      Final_Path_L : Natural;
      Opened       : VFS.File.File_Acc;
      Ret_Count    : Natural;
   begin
      if not Check_Userland_Access (Proc.Common_Map, Path_IAddr, Path_Len) or
         not Check_Userland_Access (Proc.Common_Map, Buffer_IAddr, Buffer_Len)
      then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      elsif Path_Len   > Unsigned_64 (Natural'Last) or
            Buffer_Len > Unsigned_64 (Natural'Last)
      then
         Errno := Error_String_Too_Long;
         return Unsigned_64'Last;
      end if;

      declare
         Path : String (1 ..   Natural (Path_Len))
            with Import, Address => Path_Add;
         Data : String (1 .. Natural (Buffer_Len))
            with Import, Address => Buffer_Add;
      begin
         Compound_AT_Path
            (AT_Directive => Natural (Dir_FD),
             Curr_Proc    => Proc,
             Extension    => Path,
             Result       => Final_Path,
             Count        => Final_Path_L);
         if Final_Path_L = 0 then
            Errno := Error_String_Too_Long;
            return Unsigned_64'Last;
         end if;

         if Proc.Is_MAC_Locked then
            if not MAC.Check_Path_Permissions
               (Final_Path (1 .. Final_Path_L), Proc.Perms.Filters).Can_Read
            then
               Errno := Error_Bad_Access;
               Execute_MAC_Failure ("readlink", Proc);
               return Unsigned_64'Last;
            end if;
         end if;

         Opened := Open (Final_Path (1 .. Final_Path_L), Read_Only, False);
         if Opened = null then
            Errno := Error_No_Entity;
            return Unsigned_64'Last;
         end if;

         VFS.File.Read_Symbolic_Link (Opened, Data, Ret_Count);
         Close (Opened);
         if Ret_Count = 0 then
            Errno := Error_Invalid_Value;
            return Unsigned_64'Last;
         else
            Errno := Error_No_Error;
            return Unsigned_64 (Ret_Count);
         end if;
      end;
   end Readlink;

   function GetDEnts
      (FD          : Unsigned_64;
       Buffer_Addr : Unsigned_64;
       Buffer_Len  : Unsigned_64;
       Errno       : out Errno_Value) return Unsigned_64
   is
      Buff_IAddr : constant Integer_Address := Integer_Address (Buffer_Addr);
      Buff_Addr  : constant System.Address  := To_Address (Buff_IAddr);
      Buff_Len   : constant Unsigned_64     := Buffer_Len / (Dirent'Size / 8);
      Buffer     : Dirents (1 .. Buff_Len) with Import, Address => Buff_Addr;
      Tmp_Buffer : VFS.Directory_Entities (1 .. Natural (Buff_Len));
      Read_Len   : Natural;
      Success    : Boolean;
      Proc : constant Process_Data_Acc     := Arch.Local.Get_Current_Process;
      File : constant File_Description_Acc := Get_File (Proc, FD);
   begin
      if not Check_Userland_Access (Proc.Common_Map, Buff_IAddr, Buffer_Len)
      then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      elsif File = null or else File.Description /= Description_File then
         Errno := Error_Bad_File;
         return Unsigned_64'Last;
      end if;

      VFS.File.Read_Entries (File.Inner_File, Tmp_Buffer, Read_Len, Success);
      if not Success then
         Errno := Error_No_Entity;
         return Unsigned_64'Last;
      elsif Read_Len > Tmp_Buffer'Length then
         Errno := Error_Invalid_Value;
         return Unsigned_64'Last;
      end if;

      for I in 1 .. Read_Len loop
         Buffer (Unsigned_64 (I)) := (
            D_Ino    => Tmp_Buffer (I).Inode_Number,
            D_Off    => (Dirent'Size / 8) * Unsigned_64 (I),
            D_Reclen => Dirent'Size / 8,
            D_Type   => 0,
            D_Name   => (others => Ada.Characters.Latin_1.NUL)
         );
         Buffer (Unsigned_64 (I)).D_Name (1 .. Tmp_Buffer (I).Name_Len)
            := Tmp_Buffer (I).Name_Buffer (1 .. Tmp_Buffer (I).Name_Len);
         Buffer (Unsigned_64 (I)).D_Type :=
            (case Tmp_Buffer (I).Type_Of_File is
               when File_Regular          => DT_REG,
               when File_Directory        => DT_DIR,
               when File_Symbolic_Link    => DT_LNK,
               when File_Character_Device => DT_CHR,
               when File_Block_Device     => DT_BLK);
      end loop;

      Errno := Error_No_Error;
      return Unsigned_64 (Read_Len * (Dirent'Size / 8));
   end GetDEnts;

   function Sync (Errno : out Errno_Value) return Unsigned_64 is
   begin
      if not VFS.Synchronize then
         Errno := Error_IO;
         return Unsigned_64'Last;
      else
         Errno := Error_No_Error;
         return 0;
      end if;
   end Sync;

   function MakeNode
      (Dir_FD    : Unsigned_64;
       Path_Addr : Unsigned_64;
       Path_Len  : Unsigned_64;
       Mode      : Unsigned_64;
       Dev       : Unsigned_64;
       Errno     : out Errno_Value) return Unsigned_64
   is
      pragma Unreferenced (Dev);
      Proc       : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Path_IAddr : constant  Integer_Address := Integer_Address (Path_Addr);
      Path_SAddr : constant   System.Address := To_Address (Path_IAddr);
      Final_Path   : String (1 .. 1024);
      Final_Path_L : Natural;
      Node_Type    : File_Type;
      Tmp_Mode     : constant File_Mode := File_Mode (Mode and 8#7777#);
   begin
      if not Check_Userland_Access (Proc.Common_Map, Path_IAddr, Path_Len) then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      elsif Path_Len > Unsigned_64 (Natural'Last) then
         Errno := Error_String_Too_Long;
         return Unsigned_64'Last;
      end if;

      declare
         Path : String (1 .. Natural (Path_Len))
            with Import, Address => Path_SAddr;
      begin
         Compound_AT_Path
            (AT_Directive => Natural (Dir_FD),
             Curr_Proc    => Proc,
             Extension    => Path,
             Result       => Final_Path,
             Count        => Final_Path_L);
         if Final_Path_L = 0 then
            Errno := Error_String_Too_Long;
            return Unsigned_64'Last;
         end if;
      end;

      if (Mode and Stat_IFDIR) /= 0 then
         Node_Type := File_Directory;
      else
         Node_Type := File_Regular;
      end if;

      if Create_Node (Final_Path (1 .. Final_Path_L), Node_Type, Tmp_Mode) then
         Errno := Error_No_Error;
         return 0;
      else
         Errno := Error_IO;
         return Unsigned_64'Last;
      end if;
   end MakeNode;

   function Unlink
      (Dir_FD    : Unsigned_64;
       Path_Addr : Unsigned_64;
       Path_Len  : Unsigned_64;
       Errno     : out Errno_Value) return Unsigned_64
   is
      Curr_Proc  : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Path_IAddr : constant Integer_Address := Integer_Address (Path_Addr);
      Path_SAddr : constant System.Address  := To_Address (Path_IAddr);
      Final_Path   : String (1 .. 1024);
      Final_Path_L : Natural;
   begin
      if not Check_Userland_Access (Curr_Proc.Common_Map, Path_IAddr, Path_Len)
      then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      elsif Path_Len > Unsigned_64 (Natural'Last) then
         Errno := Error_String_Too_Long;
         return Unsigned_64'Last;
      end if;

      declare
         Path : String (1 .. Natural (Path_Len))
            with Import, Address => Path_SAddr;
      begin
         Compound_AT_Path
            (AT_Directive => Natural (Dir_FD),
             Curr_Proc    => Curr_Proc,
             Extension    => Path,
             Result       => Final_Path,
             Count        => Final_Path_L);
         if Final_Path_L = 0 then
            Errno := Error_String_Too_Long;
            return Unsigned_64'Last;
         end if;
      end;

      if VFS.File.Unlink (Final_Path (1 .. Final_Path_L)) then
         Errno := Error_No_Error;
         return 0;
      else
         Errno := Error_No_Entity;
         return Unsigned_64'Last;
      end if;
   end Unlink;

   function Truncate
      (FD       : Unsigned_64;
       New_Size : Unsigned_64;
       Errno    : out Errno_Value) return Unsigned_64
   is
      Proc : constant     Process_Data_Acc := Arch.Local.Get_Current_Process;
      File : constant File_Description_Acc := Get_File (Proc, FD);
      Succ : Boolean;
   begin
      if File = null then
         Errno := Error_Bad_File;
         return Unsigned_64'Last;
      end if;

      case File.Description is
         when Description_File =>
            Succ := VFS.File.Truncate (File.Inner_File, New_Size);
         when others =>
            Errno := Error_Bad_File;
            return Unsigned_64'Last;
      end case;

      if Succ then
         Errno := Error_No_Error;
         return 0;
      else
         Errno := Error_Invalid_Value;
         return Unsigned_64'Last;
      end if;
   end Truncate;

   function Symlink
      (Dir_FD      : Unsigned_64;
       Path_Addr   : Unsigned_64;
       Path_Len    : Unsigned_64;
       Target_Addr : Unsigned_64;
       Target_Len  : Unsigned_64;
       Mode        : Unsigned_64;
       Errno       : out Errno_Value) return Unsigned_64
   is
      Proc       : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Path_IAddr : constant  Integer_Address := Integer_Address (Path_Addr);
      Path_SAddr : constant   System.Address := To_Address (Path_IAddr);
      Targ_IAddr : constant  Integer_Address := Integer_Address (Target_Addr);
      Targ_SAddr : constant   System.Address := To_Address (Targ_IAddr);
      Final_Path   : String (1 .. 1024);
      Final_Path_L : Natural;
   begin
      if not Check_Userland_Access (Proc.Common_Map, Path_IAddr, Path_Len) or
         not Check_Userland_Access (Proc.Common_Map, Targ_IAddr, Target_Len)
      then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      elsif Path_Len   > Unsigned_64 (Natural'Last) or
            Target_Len > Unsigned_64 (Natural'Last)
      then
         Errno := Error_String_Too_Long;
         return Unsigned_64'Last;
      end if;

      declare
         Path : String (1 ..   Natural (Path_Len))
            with Import, Address => Path_SAddr;
         Targ : String (1 .. Natural (Target_Len))
            with Import, Address => Targ_SAddr;
      begin
         Compound_AT_Path
            (AT_Directive => Natural (Dir_FD),
             Curr_Proc    => Proc,
             Extension    => Path,
             Result       => Final_Path,
             Count        => Final_Path_L);
         if Final_Path_L = 0 then
            Errno := Error_String_Too_Long;
            return Unsigned_64'Last;
         end if;

         if VFS.File.Create_Symbolic_Link
            (Final_Path (1 .. Final_Path_L), Targ, Unsigned_32 (Mode))
         then
            Errno := Error_No_Error;
            return 0;
         else
            Errno := Error_IO;
            return Unsigned_64'Last;
         end if;
      end;
   end Symlink;

   function Integrity_Setup
      (Command  : Unsigned_64;
       Argument : Unsigned_64;
       Errno    : out Errno_Value) return Unsigned_64
   is
      P : Integrity.Policy;
   begin
      case Command is
         when INTEGRITY_SET_POLICY =>
            case Argument is
               when INTEGRITY_POLICY_WARN  => P := Integrity.Policy_Warn;
               when INTEGRITY_POLICY_PANIC => P := Integrity.Policy_Panic;
               when others                 => goto Error;
            end case;
            Integrity.Set_Policy (P);
         when INTEGRITY_ONESHOT =>
            Integrity.Run_Checks;
         when INTEGRITY_FREE_MEMORY =>
            Integrity.Set_Free_Memory (Memory.Size (Argument));
         when INTEGRITY_MAX_PROC =>
            if Argument > Unsigned_64 (Process.Max_Process_Count) then
               Integrity.Set_Max_Processes_Check (Process.Max_Process_Count);
            else
               Integrity.Set_Max_Processes_Check (Natural (Argument));
            end if;
         when others =>
            goto Error;
      end case;

      Errno := Error_No_Error;
      return 0;

   <<Error>>
      Errno := Error_Invalid_Value;
      return Unsigned_64'Last;
   end Integrity_Setup;

   function Open_PTY
      (Result_Addr  : Unsigned_64;
       Termios_Addr : Unsigned_64;
       Window_Addr  : Unsigned_64;
       Errno        : out Errno_Value) return Unsigned_64
   is
      Res_IAddr : constant  Integer_Address := Integer_Address (Result_Addr);
      Res_SAddr : constant   System.Address := To_Address (Res_IAddr);
      TIO_IAddr : constant  Integer_Address := Integer_Address (Termios_Addr);
      TIO_SAddr : constant   System.Address := To_Address (TIO_IAddr);
      Win_IAddr : constant  Integer_Address := Integer_Address (Window_Addr);
      Win_SAddr : constant   System.Address := To_Address (Win_IAddr);
      Proc      : constant Process_Data_Acc := Arch.Local.Get_Current_Process;

      Primary        : IPC.PTY.Primary_Acc;
      Secondary      : IPC.PTY.Secondary_Acc;
      Primary_Desc   : File_Description_Acc;
      Secondary_Desc : File_Description_Acc;

      Result  : array (1 .. 2) of Integer with Import, Address => Res_SAddr;
      Termios : Devices.TermIOs.Main_Data with Import, Address => TIO_SAddr;
      Win_Siz : Devices.TermIOs.Win_Size  with Import, Address => Win_SAddr;
      Res_Size : constant Unsigned_64 := Result'Size  / 8;
      TIO_Size : constant Unsigned_64 := Termios'Size / 8;
      Win_Size : constant Unsigned_64 := Win_Siz'Size / 8;
   begin
      if not Check_Userland_Access (Proc.Common_Map, Res_IAddr, Res_Size) or
         not Check_Userland_Access (Proc.Common_Map, TIO_IAddr, TIO_Size) or
         not Check_Userland_Access (Proc.Common_Map, Win_IAddr, Win_Size)
      then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      end if;

      Create_Pair (Primary, Secondary, Termios, Win_Siz);
      Primary_Desc := new File_Description'(
         Close_On_Exec     => False,
         Description       => Description_Primary_PTY,
         Inner_Primary_PTY => Primary
      );
      Secondary_Desc := new File_Description'(
         Close_On_Exec       => False,
         Description         => Description_Secondary_PTY,
         Inner_Secondary_PTY => Secondary
      );
      if not Userland.Process.Add_File (Proc, Primary_Desc,   Result (1)) or
         not Userland.Process.Add_File (Proc, Secondary_Desc, Result (2))
      then
         Close (Primary);
         Close (Primary_Desc);
         Close (Secondary);
         Close (Secondary_Desc);
         Errno := Error_Too_Many_Files;
         return Unsigned_64'Last;
      else
         Errno := Error_No_Error;
         return 0;
      end if;
   end Open_PTY;

   function FSync
      (FD    : Unsigned_64;
       Errno : out Errno_Value) return Unsigned_64
   is
      Proc : constant     Process_Data_Acc := Arch.Local.Get_Current_Process;
      File : constant File_Description_Acc := Get_File (Proc, FD);
   begin
      if File = null then
         Errno := Error_Bad_File;
         return Unsigned_64'Last;
      end if;

      case File.Description is
         when Description_File =>
            if not VFS.File.Synchronize (File.Inner_File) then
               Errno := Error_IO;
               return Unsigned_64'Last;
            else
               Errno := Error_No_Error;
               return 0;
            end if;
         when others =>
            Errno := Error_Invalid_Value;
            return Unsigned_64'Last;
      end case;
   end FSync;

   function Link
      (Source_Dir  : Unsigned_64;
       Source_Addr : Unsigned_64;
       Source_Len  : Unsigned_64;
       Desto_Dir   : Unsigned_64;
       Desto_Addr  : Unsigned_64;
       Desto_Len   : Unsigned_64;
       Errno       : out Errno_Value) return Unsigned_64
   is
      Proc      : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      Src_IAddr : constant  Integer_Address := Integer_Address (Source_Addr);
      Src_SAddr : constant   System.Address := To_Address (Src_IAddr);
      Dst_IAddr : constant  Integer_Address := Integer_Address (Desto_Addr);
      Dst_SAddr : constant   System.Address := To_Address (Dst_IAddr);
      Final_Path1   : String (1 .. 1024);
      Final_Path1_L : Natural;
      Final_Path2   : String (1 .. 1024);
      Final_Path2_L : Natural;
   begin
      if not Check_Userland_Access (Proc.Common_Map, Src_IAddr, Source_Len) or
         not Check_Userland_Access (Proc.Common_Map, Dst_IAddr, Desto_Len)
      then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      elsif Source_Len > Unsigned_64 (Natural'Last) or
            Desto_Len  > Unsigned_64 (Natural'Last)
      then
         Errno := Error_String_Too_Long;
         return Unsigned_64'Last;
      end if;

      declare
         Src : String (1 .. Natural (Source_Len))
            with Import, Address => Src_SAddr;
         Dst : String (1 ..  Natural (Desto_Len))
            with Import, Address => Dst_SAddr;
      begin
         Compound_AT_Path
            (AT_Directive => Natural (Source_Dir),
             Curr_Proc    => Proc,
             Extension    => Src,
             Result       => Final_Path1,
             Count        => Final_Path1_L);
         Compound_AT_Path
            (AT_Directive => Natural (Desto_Dir),
             Curr_Proc    => Proc,
             Extension    => Dst,
             Result       => Final_Path2,
             Count        => Final_Path2_L);
         if Final_Path1_L = 0 or Final_Path2_L = 0 then
            Errno := Error_String_Too_Long;
            return Unsigned_64'Last;
         end if;

         if VFS.File.Create_Hard_Link
            (Final_Path1 (1 .. Final_Path1_L),
             Final_Path2 (1 .. Final_Path2_L))
         then
            Errno := Error_No_Error;
            return 0;
         else
            Errno := Error_IO;
            return Unsigned_64'Last;
         end if;
      end;
   end Link;

   function PTrace
      (Request     : Unsigned_64;
       Traced_PID  : Unsigned_64;
       Traced_Addr : Unsigned_64;
       Result_Addr : Unsigned_64;
       Errno       : out Errno_Value) return Unsigned_64
   is
      pragma Unreferenced (Traced_Addr);
      Proc  : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      TProc : constant Process_Data_Acc := Get_By_PID (Positive (Traced_PID));
   begin
      if TProc = null or else not Is_Child (Proc, TProc.Process_PID) then
         Errno := Error_Bad_Permissions;
         return Unsigned_64'Last;
      elsif Proc.Is_MAC_Locked and not Proc.Perms.Caps.Can_Trace_Children then
         Errno := Error_Bad_Access;
         Execute_MAC_Failure ("ptrace", Proc);
         return Unsigned_64'Last;
      end if;

      case Request is
         when PTRACE_SYSCALL_PIPE =>
            TProc.Tracer_PID := Proc.Process_PID;
            TProc.Tracer_FD  := Natural (Result_Addr);
         when others =>
            Errno := Error_Invalid_Value;
            return Unsigned_64'Last;
      end case;

      Errno := Error_No_Error;
      return 0;
   end PTrace;

   function Poll
      (FDs_Addr  : Unsigned_64;
       FDs_Count : Unsigned_64;
       Timeout   : Unsigned_64;
       Errno     : out Errno_Value) return Unsigned_64
   is
      pragma Unreferenced (Timeout);

      Proc  : constant Process_Data_Acc := Arch.Local.Get_Current_Process;
      IAddr : constant  Integer_Address := Integer_Address (FDs_Addr);
      SAddr : constant   System.Address := To_Address (IAddr);
      Count :                   Natural := 0;
      File  : File_Description_Acc;
      FDs   : Poll_FDs (1 .. FDs_Count) with Import, Address => SAddr;
   begin
      if not Check_Userland_Access (Proc.Common_Map, IAddr, FDs'Size / 8) then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      elsif FDs'Length = 0 then
         Errno := Error_No_Error;
         return 0;
      end if;

      loop
         for Polled of FDs loop
            Polled.Out_Events := 0;

            --  We are to ignore the FD if its negative.
            if (Polled.FD and Shift_Left (1, 31)) /= 0 then
               goto End_Iter;
            end if;

            --  Check the FD actually points to anything valuable.
            File := Get_File (Proc, Unsigned_64 (Polled.FD));
            if File = null then
               Polled.Out_Events := POLLNVAL;
               goto End_Iter;
            end if;

            --  Fill out events depending on the file type.
            case File.Description is
               when Description_Reader_Pipe =>
                  if Is_Broken (File.Inner_Reader_Pipe) then
                     Polled.Out_Events := POLLHUP;
                  end if;
                  if (Polled.Events and POLLIN) /= 0 then
                     if not Is_Empty (File.Inner_Reader_Pipe) then
                        Polled.Out_Events := Polled.Out_Events or POLLIN;
                     end if;
                  end if;
               when Description_Writer_Pipe =>
                  if (Polled.Events and POLLOUT) /= 0 then
                     if Is_Empty (File.Inner_Writer_Pipe) then
                        Polled.Out_Events := POLLOUT;
                     end if;
                  end if;
               when others =>
                  Polled.Out_Events := POLLERR;
            end case;

         <<End_Iter>>
            if Polled.Out_Events /= 0 then
               Count := Count + 1;
            end if;
         end loop;

         if Count /= 0 then
            Errno := Error_No_Error;
            return Unsigned_64 (Count);
         end if;

         Scheduler.Yield;
      end loop;
   end Poll;
end Userland.Syscall;
