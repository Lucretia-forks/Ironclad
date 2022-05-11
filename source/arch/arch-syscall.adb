--  arch-syscall.adb: Syscall table and implementation.
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

with Ada.Characters.Latin_1;
with Config;
with System; use System;
with System.Storage_Elements; use System.Storage_Elements;
with Arch.Wrappers;
with Lib.Messages;
with Lib;
with Networking;
with Userland.Process; use Userland.Process;
with Userland.Loader;
with VFS.File; use VFS.File;
with VFS; use VFS;
with Scheduler;
with Memory.Virtual; use Memory.Virtual;
with Memory.Physical;
with Memory; use Memory;
with Ada.Unchecked_Deallocation;

package body Arch.Syscall is
   --  Errno values, they are ABI and arbitrary.
   Error_No_Error        : constant := 0;
   Error_Not_Big_Enough  : constant := 3;    -- ERANGE.
   Error_Bad_Access      : constant := 1002; -- EACCES.
   Error_Would_Block     : constant := 1006; -- EAGAIN.
   Error_Child           : constant := 1012; -- ECHILD.
   Error_Would_Fault     : constant := 1020; -- EFAULT.
   Error_Invalid_Value   : constant := 1026; -- EINVAL.
   Error_String_Too_Long : constant := 1036; -- ENAMETOOLONG
   Error_No_Entity       : constant := 1043; -- ENOENT.
   Error_Not_Implemented : constant := 1051; -- ENOSYS.
   Error_Not_A_Directory : constant := 1053; -- ENOTDIR.
   Error_Not_Supported   : constant := 1057; -- ENOSUP.
   Error_Invalid_Seek    : constant := 1069; -- ESPIPE.
   Error_Bad_File        : constant := 1081; -- EBADFD.

   --  Whether we are to print syscall information.
   Is_Tracing : Boolean := False;

   type String_Acc is access all String;
   procedure Free_Str is new Ada.Unchecked_Deallocation (String, String_Acc);
   procedure Free_File is new Ada.Unchecked_Deallocation
      (VFS.File.File, VFS.File.File_Acc);

   procedure Set_Tracing (Value : Boolean) is
   begin
      Is_Tracing := Value;
   end Set_Tracing;

   procedure Syscall_Handler (Number : Integer; State : access ISR_GPRs) is
      Returned : Unsigned_64 := Unsigned_64'Last;
      Errno    : Unsigned_64 := Error_No_Error;
      pragma Unreferenced (Number);
   begin
      --  Swap to kernel GS and enable interrupts.
      Interrupts.Set_Interrupt_Flag (True);
      Wrappers.Swap_GS;

      --  Call the inner syscall.
      --  RAX is the return value, as well as the syscall number.
      --  RDX is the returned errno.
      --  Arguments can be RDI, RSI, RDX, RCX, R8, and R9, in that order.
      case State.RAX is
         when 0 =>
            Syscall_Exit (State.RDI);
         when 1 =>
            Returned := Syscall_Set_TCB (State.RDI, Errno);
         when 2 =>
            Returned := Syscall_Open (State.RDI, State.RSI, Errno);
         when 3 =>
            Returned := Syscall_Close (State.RDI, Errno);
         when 4 =>
            Returned := Syscall_Read (State.RDI, State.RSI, State.RDX, Errno);
         when 5 =>
            Returned := Syscall_Write (State.RDI, State.RSI, State.RDX, Errno);
         when 6 =>
            Returned := Syscall_Seek (State.RDI, State.RSI, State.RDX, Errno);
         when 7 =>
            Returned := Syscall_Mmap (State.RDI, State.RSI, State.RDX,
                                      State.RCX, State.R8, State.R9, Errno);
         when 8 =>
            Returned := Syscall_Munmap (State.RDI, State.RSI, Errno);
         when 9 =>
            Returned := Syscall_Get_PID;
         when 10 =>
            Returned := Syscall_Get_Parent_PID;
         when 11 =>
            Returned := Syscall_Thread_Preference (State.RDI, Errno);
         when 12 =>
            Returned := Syscall_Exec (State.RDI, State.RSI, State.RDX, Errno);
         when 13 =>
            Returned := Syscall_Fork (State, Errno);
         when 14 =>
            Returned := Syscall_Wait (State.RDI, State.RSI, State.RDX, Errno);
         when 15 =>
            Returned := Syscall_Uname (State.RDI, Errno);
         when 16 =>
            Returned := Syscall_Set_Hostname (State.RDI, State.RSI, Errno);
         when 17 =>
            Returned := Syscall_FStat (State.RDI, State.RSI, Errno);
         when 18 =>
            Returned := Syscall_LStat (State.RDI, State.RSI, Errno);
         when 19 =>
            Returned := Syscall_Get_CWD (State.RDI, State.RSI, Errno);
         when 20 =>
            Returned := Syscall_Chdir (State.RDI, Errno);
         when others =>
            Errno := Error_Not_Implemented;
      end case;

      --  Assign the return values and swap back to user GS.
      State.RAX := Returned;
      State.RDX := Errno;
      Wrappers.Swap_GS;
   end Syscall_Handler;

   procedure Syscall_Exit (Error_Code : Unsigned_64) is
      Current_Thread  : constant Scheduler.TID := Scheduler.Get_Current_Thread;
      Current_Process : constant Userland.Process.Process_Data_Acc :=
            Userland.Process.Get_By_Thread (Current_Thread);
   begin
      if Is_Tracing then
         Lib.Messages.Put ("syscall exit(");
         Lib.Messages.Put (Error_Code);
         Lib.Messages.Put_Line (")");
      end if;

      --  Remove all state but the return value and keep the zombie around
      --  until we are waited.
      Userland.Process.Flush_Threads  (Current_Process);
      Userland.Process.Flush_Files    (Current_Process);
      Current_Process.Exit_Code := Unsigned_8 (Error_Code);
      Current_Process.Did_Exit  := True;
      Scheduler.Bail;
   end Syscall_Exit;

   function Syscall_Set_TCB
      (Address : Unsigned_64;
       Errno   : out Unsigned_64) return Unsigned_64 is
   begin
      if Is_Tracing then
         Lib.Messages.Put ("syscall set_tcb(");
         Lib.Messages.Put (Address);
         Lib.Messages.Put_Line (")");
      end if;
      if Address = 0 then
         Errno := Error_Invalid_Value;
         return Unsigned_64'Last;
      else
         Wrappers.Write_FS (Address);
         Errno := Error_No_Error;
         return 0;
      end if;
   end Syscall_Set_TCB;

   function Syscall_Open
      (Address : Unsigned_64;
       Flags   : Unsigned_64;
       Errno   : out Unsigned_64) return Unsigned_64
   is
      Addr : constant System.Address := To_Address (Integer_Address (Address));
   begin
      if Address = 0 then
         if Is_Tracing then
            Lib.Messages.Put ("syscall open(null, ");
            Lib.Messages.Put (Flags);
            Lib.Messages.Put_Line (")");
         end if;
         goto Error_Return;
      end if;
      declare
         Path_Length  : constant Natural := Lib.C_String_Length (Addr);
         Path_String  : String (1 .. Path_Length) with Address => Addr;
         Current_Thre : constant Scheduler.TID := Scheduler.Get_Current_Thread;
         Current_Proc : constant Userland.Process.Process_Data_Acc :=
            Userland.Process.Get_By_Thread (Current_Thre);
         Open_Mode    : VFS.File.Access_Mode;
         Opened_File  : VFS.File.File_Acc;
         Returned_FD  : Natural;
         Opened_Stat  : VFS.File_Stat;
         Symlink_Len  : Natural;
         Symlink_Buf  : String (1 .. 100);
      begin
         if Is_Tracing then
            Lib.Messages.Put ("syscall open(");
            Lib.Messages.Put (Path_String);
            Lib.Messages.Put (", ");
            Lib.Messages.Put (Flags);
            Lib.Messages.Put_Line (")");
         end if;

         --  Parse the mode.
         if (Flags and O_RDWR) /= 0 then
            Open_Mode := VFS.File.Access_RW;
         elsif (Flags and O_RDONLY) /= 0 then
            Open_Mode := VFS.File.Access_R;
         elsif (Flags and O_WRONLY) /= 0 then
            Open_Mode := VFS.File.Access_W;
         else
            --  XXX: This should go to Error_Return, yet mlibc's dynamic linker
            --  passes flags = 0 for no reason, so we will put a default.
            --  This should not be the case, and it is to be fixed.
            --  goto Error_Return;
            Open_Mode := VFS.File.Access_R;
         end if;

         --  Actually open the file.
         Opened_File := VFS.File.Open (Path_String, Open_Mode);

         --  Check if we gotta follow symlinks or not.
         if (Flags and O_NOFOLLOW) /= 0 then
            goto Add_File;
         end if;

         --  Check and follow the symlink.
         if not VFS.File.Stat (Opened_File, Opened_Stat) then
            goto Error_Return;
         end if;
         if Opened_Stat.Type_Of_File = VFS.File_Symbolic_Link then
            Symlink_Len := VFS.File.Read
               (Opened_File, Symlink_Buf'Length, Symlink_Buf'Address);
            VFS.File.Close (Opened_File);
            Free_File (Opened_File);
            Opened_File := VFS.File.Open (Symlink_Buf (1 .. Symlink_Len), Open_Mode);
         end if;

   <<Add_File>>
         if Opened_File = null then
            goto Error_Return;
         end if;
         if not Userland.Process.Add_File
               (Current_Proc, Opened_File, Returned_FD)
         then
            goto Error_Return;
         else
            Errno := Error_No_Error;
            return Unsigned_64 (Returned_FD);
         end if;
      end;
   <<Error_Return>>
      Errno := Error_Invalid_Value;
      return Unsigned_64'Last;
   end Syscall_Open;

   function Syscall_Close
      (File_D : Unsigned_64;
       Errno  : out Unsigned_64) return Unsigned_64
   is
      Current_Thread  : constant Scheduler.TID := Scheduler.Get_Current_Thread;
      Current_Process : constant Userland.Process.Process_Data_Acc :=
         Userland.Process.Get_By_Thread (Current_Thread);
      File            : constant Natural := Natural (File_D);
   begin
      if Is_Tracing then
         Lib.Messages.Put ("syscall close(");
         Lib.Messages.Put (File_D);
         Lib.Messages.Put_Line (")");
      end if;
      Userland.Process.Remove_File (Current_Process, File);
      Errno := Error_No_Error;
      return 0;
   end Syscall_Close;

   function Syscall_Read
      (File_D : Unsigned_64;
       Buffer : Unsigned_64;
       Count  : Unsigned_64;
       Errno  : out Unsigned_64) return Unsigned_64
   is
      Buffer_Addr     : constant System.Address :=
         To_Address (Integer_Address (Buffer));
      Current_Thread  : constant Scheduler.TID := Scheduler.Get_Current_Thread;
      Current_Process : constant Userland.Process.Process_Data_Acc :=
         Userland.Process.Get_By_Thread (Current_Thread);
      File : constant VFS.File.File_Acc :=
         Current_Process.File_Table (Natural (File_D));
   begin
      if Is_Tracing then
         Lib.Messages.Put ("syscall read(");
         Lib.Messages.Put (File_D);
         Lib.Messages.Put (", ");
         Lib.Messages.Put (Buffer, False, True);
         Lib.Messages.Put (", ");
         Lib.Messages.Put (Count);
         Lib.Messages.Put_Line (")");
      end if;
      if File = null then
         Errno := Error_Bad_File;
         return Unsigned_64'Last;
      end if;
      if Buffer = 0 then
         Errno := Error_Invalid_Value;
         return Unsigned_64'Last;
      end if;
      Errno := Error_No_Error;
      return Unsigned_64 (VFS.File.Read (File, Integer (Count), Buffer_Addr));
   end Syscall_Read;

   function Syscall_Write
      (File_D : Unsigned_64;
       Buffer : Unsigned_64;
       Count  : Unsigned_64;
       Errno  : out Unsigned_64) return Unsigned_64
   is
      Buffer_Addr     : constant System.Address :=
         To_Address (Integer_Address (Buffer));
      Current_Thread  : constant Scheduler.TID := Scheduler.Get_Current_Thread;
      Current_Process : constant Userland.Process.Process_Data_Acc :=
         Userland.Process.Get_By_Thread (Current_Thread);
      File : constant File_Acc :=
         Current_Process.File_Table (Natural (File_D));
   begin
      if Is_Tracing then
         Lib.Messages.Put ("syscall write(");
         Lib.Messages.Put (File_D);
         Lib.Messages.Put (", ");
         Lib.Messages.Put (Buffer, False, True);
         Lib.Messages.Put (", ");
         Lib.Messages.Put (Count);
         Lib.Messages.Put_Line (")");
      end if;
      if File = null then
         Errno := Error_Bad_File;
         return Unsigned_64'Last;
      end if;
      if Buffer = 0 then
         Errno := Error_Invalid_Value;
         return Unsigned_64'Last;
      end if;
      Errno := Error_No_Error;
      return Unsigned_64 (VFS.File.Write (File, Integer (Count), Buffer_Addr));
   end Syscall_Write;

   function Syscall_Seek
      (File_D : Unsigned_64;
       Offset : Unsigned_64;
       Whence : Unsigned_64;
       Errno  : out Unsigned_64) return Unsigned_64
   is
      Current_Thread  : constant Scheduler.TID := Scheduler.Get_Current_Thread;
      Current_Process : constant Userland.Process.Process_Data_Acc :=
         Userland.Process.Get_By_Thread (Current_Thread);
      File : constant VFS.File.File_Acc :=
         Current_Process.File_Table (Natural (File_D));
      Stat_Val : VFS.File_Stat;
   begin
      if Is_Tracing then
         Lib.Messages.Put ("syscall seek(");
         Lib.Messages.Put (File_D);
         Lib.Messages.Put (", ");
         Lib.Messages.Put (Offset);
         Lib.Messages.Put (", ");
         Lib.Messages.Put (Whence);
         Lib.Messages.Put_Line (")");
      end if;

      if File = null then
         Errno := Error_Bad_File;
         return Unsigned_64'Last;
      end if;
      if not VFS.File.Stat (File, Stat_Val) then
         Errno := Error_Invalid_Seek;
         return Unsigned_64'Last;
      end if;
      case Whence is
         when SEEK_SET =>
            File.Index := Natural (Offset);
         when SEEK_CURRENT =>
            File.Index := Natural (Unsigned_64 (File.Index) + Offset);
         when SEEK_END =>
            File.Index := Natural (Stat_Val.Byte_Size + Offset);
         when others =>
            Errno := Error_Invalid_Value;
            return Unsigned_64'Last;
      end case;

      Errno := Error_No_Error;
      return Unsigned_64 (File.Index);
   end Syscall_Seek;

   function Syscall_Mmap
      (Hint       : Unsigned_64;
       Length     : Unsigned_64;
       Protection : Unsigned_64;
       Flags      : Unsigned_64;
       File_D     : Unsigned_64;
       Offset     : Unsigned_64;
       Errno      : out Unsigned_64) return Unsigned_64
   is
      Current_Thread  : constant Scheduler.TID := Scheduler.Get_Current_Thread;
      Current_Process : constant Userland.Process.Process_Data_Acc :=
         Userland.Process.Get_By_Thread (Current_Thread);
      Map : constant Memory.Virtual.Page_Map_Acc := Current_Process.Common_Map;

      Map_Not_Execute : Boolean := True;
      Map_Flags : Memory.Virtual.Page_Flags := (
         Present         => True,
         Read_Write      => False,
         User_Supervisor => True,
         Write_Through   => False,
         Cache_Disable   => False,
         Accessed        => False,
         Dirty           => False,
         PAT             => False,
         Global          => False
      );

      Aligned_Hint : Unsigned_64 := Lib.Align_Up (Hint, Page_Size);
   begin
      if Is_Tracing then
         Lib.Messages.Put ("syscall mmap(");
         Lib.Messages.Put (Hint, False, True);
         Lib.Messages.Put (", ");
         Lib.Messages.Put (Length, False, True);
         Lib.Messages.Put (", ");
         Lib.Messages.Put (Protection, False, True);
         Lib.Messages.Put (", ");
         Lib.Messages.Put (Flags, False, True);
         Lib.Messages.Put (", ");
         Lib.Messages.Put (File_D);
         Lib.Messages.Put (", ");
         Lib.Messages.Put (Offset, False, True);
         Lib.Messages.Put_Line (")");
      end if;

      --  Check protection flags.
      Map_Flags.Read_Write := (Protection and Protection_Write)  /= 0;
      Map_Not_Execute      := (Protection and Protection_Execute) = 0;

      --  Check that we got a length.
      if Length = 0 then
         Errno := Error_Invalid_Value;
         return Unsigned_64'Last;
      end if;

      --  Set our own hint if none was provided.
      if Hint = 0 then
         Aligned_Hint := Current_Process.Alloc_Base;
         Current_Process.Alloc_Base := Current_Process.Alloc_Base + Length;
      end if;

      --  Check for fixed.
      if (Flags and Map_Fixed) /= 0 and Aligned_Hint /= Hint then
         Errno := Error_Invalid_Value;
         return Unsigned_64'Last;
      end if;

      --  We only support anonymous right now, so if its not anon, we cry.
      if (Flags and Map_Anon) = 0 then
         Errno := Error_Not_Implemented;
         return Unsigned_64'Last;
      end if;

      --  Allocate the requested block and map it.
      declare
         A : constant Virtual_Address := Memory.Physical.Alloc (Size (Length));
      begin
         Memory.Virtual.Map_Range (
            Map,
            Virtual_Address (Aligned_Hint),
            A - Memory_Offset,
            Length,
            Map_Flags,
            Map_Not_Execute,
            True
         );
         Errno := Error_No_Error;
         return Aligned_Hint;
      end;
   end Syscall_Mmap;

   function Syscall_Munmap
      (Address    : Unsigned_64;
       Length     : Unsigned_64;
       Errno      : out Unsigned_64) return Unsigned_64
   is
      Current_Thread  : constant Scheduler.TID := Scheduler.Get_Current_Thread;
      Current_Process : constant Userland.Process.Process_Data_Acc :=
         Userland.Process.Get_By_Thread (Current_Thread);
      Map : constant Memory.Virtual.Page_Map_Acc := Current_Process.Common_Map;
      Addr : constant Physical_Address :=
         Memory.Virtual.Virtual_To_Physical (Map, Virtual_Address (Address));
   begin
      if Is_Tracing then
         Lib.Messages.Put ("syscall munmap(");
         Lib.Messages.Put (Address, False, True);
         Lib.Messages.Put (", ");
         Lib.Messages.Put (Length, False, True);
         Lib.Messages.Put_Line (")");
      end if;
      --  We only support MAP_ANON and MAP_FIXED, so we can just assume we want
      --  to free.
      --  TODO: Actually unmap, not only free.
      Memory.Physical.Free (Addr);
      Errno := Error_No_Error;
      return 0;
   end Syscall_Munmap;

   function Syscall_Get_PID return Unsigned_64 is
      Current_Thread  : constant Scheduler.TID := Scheduler.Get_Current_Thread;
      Current_Process : constant Userland.Process.Process_Data_Acc :=
         Userland.Process.Get_By_Thread (Current_Thread);
   begin
      if Is_Tracing then
         Lib.Messages.Put_Line ("syscall getpid()");
      end if;
      return Unsigned_64 (Current_Process.Process_PID);
   end Syscall_Get_PID;

   function Syscall_Get_Parent_PID return Unsigned_64 is
      Current_Thread  : constant Scheduler.TID := Scheduler.Get_Current_Thread;
      Current_Process : constant Userland.Process.Process_Data_Acc :=
         Userland.Process.Get_By_Thread (Current_Thread);
      Parent_Process : constant Natural := Current_Process.Parent_PID;
   begin
      if Is_Tracing then
         Lib.Messages.Put_Line ("syscall getppid()");
      end if;
      return Unsigned_64 (Parent_Process);
   end Syscall_Get_Parent_PID;

   function Syscall_Thread_Preference
      (Preference : Unsigned_64;
       Errno      : out Unsigned_64) return Unsigned_64
   is
      Thread : constant Scheduler.TID := Scheduler.Get_Current_Thread;
   begin
      if Is_Tracing then
         Lib.Messages.Put ("syscall thread_preference(");
         Lib.Messages.Put (Preference);
         Lib.Messages.Put_Line (")");
      end if;

      --  Check if we have a valid preference before doing anything with it.
      if Preference > Unsigned_64 (Positive'Last) then
         Errno := Error_Invalid_Value;
         return Unsigned_64'Last;
      end if;

      --  If 0, we have to return the current preference, else, we gotta set
      --  it to the passed value.
      if Preference = 0 then
         declare
            Pr : constant Natural := Scheduler.Get_Thread_Preference (Thread);
         begin
            --  If we got error preference, return that, even tho that should
            --  be impossible.
            if Pr = 0 then
               Errno := Error_Not_Supported;
               return Unsigned_64'Last;
            else
               Errno := Error_No_Error;
               return Unsigned_64 (Pr);
            end if;
         end;
      else
         Scheduler.Set_Thread_Preference (Thread, Natural (Preference));
         Errno := Error_No_Error;
         return Unsigned_64 (Scheduler.Get_Thread_Preference (Thread));
      end if;
   end Syscall_Thread_Preference;

   function Syscall_Exec
      (Address : Unsigned_64;
       Argv    : Unsigned_64;
       Envp    : Unsigned_64;
       Errno   : out Unsigned_64) return Unsigned_64
   is
      --  FIXME: This type should be dynamic ideally and not have a maximum.
      type Arg_Arr is array (1 .. 40) of Unsigned_64;

      Current_Thread  : constant Scheduler.TID := Scheduler.Get_Current_Thread;
      Current_Process : constant Userland.Process.Process_Data_Acc :=
         Userland.Process.Get_By_Thread (Current_Thread);

      Addr : constant System.Address := To_Address (Integer_Address (Address));
      Path_Length : constant Natural := Lib.C_String_Length (Addr);
      Path_String : String (1 .. Path_Length) with Address => Addr;
      Opened_File : constant File_Acc := Open (Path_String, Access_R);

      Args_Raw : Arg_Arr with Address => To_Address (Integer_Address (Argv));
      Env_Raw  : Arg_Arr with Address => To_Address (Integer_Address (Envp));
      Args_Count : Natural := 0;
      Env_Count  : Natural := 0;
   begin
      if Is_Tracing then
         Lib.Messages.Put ("syscall exec(" & Path_String & ")");
      end if;

      if Opened_File = null then
         Errno := Error_No_Entity;
         return Unsigned_64'Last;
      end if;

      --  Count the args and envp we have, and copy them to Ada arrays.
      for I in Args_Raw'Range loop
         exit when Args_Raw (I) = 0;
         Args_Count := Args_Count + 1;
      end loop;
      for I in Env_Raw'Range loop
         exit when Env_Raw (I) = 0;
         Env_Count := Env_Count + 1;
      end loop;

      declare
         Args : Userland.Argument_Arr    (1 .. Args_Count);
         Env  : Userland.Environment_Arr (1 .. Env_Count);
      begin
         for I in 1 .. Args_Count loop
            declare
               Addr : constant System.Address :=
                  To_Address (Integer_Address (Args_Raw (I)));
               Arg_Length : constant Natural := Lib.C_String_Length (Addr);
               Arg_String : String (1 .. Arg_Length) with Address => Addr;
            begin
               Args (I) := new String'(Arg_String);
            end;
         end loop;
         for I in 1 .. Env_Count loop
            declare
               Addr : constant System.Address :=
                  To_Address (Integer_Address (Env_Raw (I)));
               Arg_Length : constant Natural := Lib.C_String_Length (Addr);
               Arg_String : String (1 .. Arg_Length) with Address => Addr;
            begin
               Env (I) := new String'(Arg_String);
            end;
         end loop;

         Userland.Process.Flush_Threads (Current_Process);
         if not Userland.Loader.Start_Program
            (Opened_File, Args, Env, Current_Process)
         then
            Errno := Error_Bad_Access;
            return Unsigned_64'Last;
         end if;

         for Arg of Args loop
            Free_Str (Arg);
         end loop;
         for En of Env loop
            Free_Str (En);
         end loop;

         Userland.Process.Remove_Thread (Current_Process, Current_Thread);
         Scheduler.Bail;
         Errno := Error_No_Error;
         return 0;
      end;
   end Syscall_Exec;

   function Syscall_Fork
      (State_To_Fork : access ISR_GPRs;
       Errno         : out Unsigned_64) return Unsigned_64
   is
      Current_Thread  : constant Scheduler.TID := Scheduler.Get_Current_Thread;
      Current_Process : constant Userland.Process.Process_Data_Acc :=
         Userland.Process.Get_By_Thread (Current_Thread);
      Forked_Process : constant Userland.Process.Process_Data_Acc :=
         Userland.Process.Fork (Current_Process);
   begin
      if Is_Tracing then
         Lib.Messages.Put_Line ("syscall fork()");
      end if;

      --  Fork the process.
      if Forked_Process = null then
         Errno := Error_Would_Block;
         return Unsigned_64'Last;
      end if;

      --  Set a good memory map.
      Forked_Process.Common_Map := Clone_Space (Current_Process.Common_Map);

      --  Create a running thread cloning the caller.
      if not Add_Thread (Forked_Process,
         Scheduler.Create_User_Thread
            (State_To_Fork, Forked_Process.Common_Map))
      then
         Errno := Error_Would_Block;
         return Unsigned_64'Last;
      end if;

      Errno := Error_No_Error;
      return Unsigned_64 (Forked_Process.Process_PID);
   end Syscall_Fork;

   function Syscall_Wait
      (Waited_PID : Unsigned_64;
       Exit_Addr  : Unsigned_64;
       Options    : Unsigned_64;
       Errno      : out Unsigned_64) return Unsigned_64
   is
      Current_Thread  : constant Scheduler.TID := Scheduler.Get_Current_Thread;
      Current_Process : constant Userland.Process.Process_Data_Acc :=
         Userland.Process.Get_By_Thread (Current_Thread);
      Exit_Value : Unsigned_32
         with Address => To_Address (Integer_Address (Exit_Addr));
   begin
      if Is_Tracing then
         Lib.Messages.Put      ("syscall wait(");
         Lib.Messages.Put      (Waited_PID);
         Lib.Messages.Put      (", ");
         Lib.Messages.Put      (Exit_Addr, False, True);
         Lib.Messages.Put      (", ");
         Lib.Messages.Put      (Options, False, True);
         Lib.Messages.Put_Line (")");
      end if;

      --  Fail on having to wait on the process group, we dont support that.
      if Waited_PID = 0 then
         Errno := Error_Invalid_Value;
         return Unsigned_64'Last;
      end if;

      --  If -1, we have to wait for any of the children.
      --  TODO: Do not hardcode this to the first child.
      if Waited_PID = Unsigned_64 (Unsigned_32'Last) then
         return Syscall_Wait
            (Unsigned_64 (Current_Process.Children (1)),
             Exit_Addr, Options, Errno);
      end if;

      --  Check the callee is actually the parent, else we are doing something
      --  weird.
      for PID_Item of Current_Process.Children loop
         if Natural (Waited_PID) = PID_Item then
            goto Is_Parent;
         end if;
      end loop;

      Errno := Error_Child;
      return Unsigned_64'Last;

   <<Is_Parent>>
      declare
         Waited_Process : constant Userland.Process.Process_Data_Acc :=
            Userland.Process.Get_By_PID (Natural (Waited_PID));
      begin
         --  Actually wait.
         while not Waited_Process.Did_Exit loop
            Scheduler.Yield;
         end loop;

         --  Set the return value.
         Exit_Value := Unsigned_32 (Waited_Process.Exit_Code);

         --  Now that we got the exit code, finally allow the process to die.
         Userland.Process.Delete_Process (Waited_Process);
         Errno := Error_No_Error;
         return Waited_PID;
      end;
   end Syscall_Wait;


   function Syscall_Uname
      (Address : Unsigned_64;
       Errno   : out Unsigned_64) return Unsigned_64
   is
      Addr : constant System.Address := To_Address (Integer_Address (Address));
      UTS  : UTS_Name with Address => Addr;
   begin
      if Addr = System.Null_Address then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      end if;

      UTS.System_Name (1 .. Config.Package_Name'Length + 1) :=
         Config.Package_Name & Ada.Characters.Latin_1.NUL;
      UTS.Node_Name (1 .. Networking.Hostname_Length) :=
         Networking.Hostname_Buffer (1 .. Networking.Hostname_Length);
      UTS.Node_Name (Networking.Hostname_Length + 1) :=
         Ada.Characters.Latin_1.NUL;
      UTS.Release (1 .. Config.Package_Version'Length + 1) :=
         Config.Package_Version & Ada.Characters.Latin_1.NUL;
      UTS.Version (1) := Ada.Characters.Latin_1.NUL;
      UTS.Machine (1 .. 7) := "x86_64" & Ada.Characters.Latin_1.NUL;
      Errno := Error_No_Error;
      return 0;
   end Syscall_Uname;

   function Syscall_Set_Hostname
      (Address : Unsigned_64;
       Length  : Unsigned_64;
       Errno   : out Unsigned_64) return Unsigned_64
   is
      Len  : constant Natural := Natural (Length);
      Addr : constant System.Address := To_Address (Integer_Address (Address));
      Name : String (1 .. Len) with Address => Addr;
   begin
      if Addr = System.Null_Address then
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      elsif Len = 0 or Len > Networking.Hostname_Buffer'Length then
         Errno := Error_Invalid_Value;
         return Unsigned_64'Last;
      else
         Networking.Hostname_Length := Len;
         Networking.Hostname_Buffer (1 .. Len) := Name;
         Errno := Error_No_Error;
         return 0;
      end if;
   end Syscall_Set_Hostname;

   function Inner_Stat
      (F       : VFS.File.File_Acc;
       Address : Unsigned_64) return Boolean
   is
      Stat_Val : VFS.File_Stat;
      Stat_Buf : Stat with Address => To_Address (Integer_Address (Address));
   begin
      if VFS.File.Stat (F, Stat_Val) then
         Stat_Buf := (
            Device_Number => 1,
            Inode_Number  => Stat_Val.Unique_Identifier,
            Mode          => Stat_Val.Mode,
            Number_Links  => Unsigned_32 (Stat_Val.Hard_Link_Count),
            UID           => 0,
            GID           => 0,
            Inner_Device  => 0,
            File_Size     => Stat_Val.Byte_Size,
            Access_Time   => (Seconds => 0, Nanoseconds => 0),
            Modify_Time   => (Seconds => 0, Nanoseconds => 0),
            Create_Time   => (Seconds => 0, Nanoseconds => 0),
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

         return True;
      else
         --  TODO: Once our VFS can handle better '.', '..', and '/', remove
         --  this fallback.
         Stat_Buf.Device_Number := 0;
         Stat_Buf.Inode_Number  := 0;
         Stat_Buf.Number_Links  := 1;
         Stat_Buf.File_Size     := 512;
         Stat_Buf.Block_Size    := 512;
         Stat_Buf.Block_Count   := 1;

         return True;
      end if;
   end Inner_Stat;

   function Syscall_FStat
      (File_D  : Unsigned_64;
       Address : Unsigned_64;
       Errno   : out Unsigned_64) return Unsigned_64
   is
      Current_Thread  : constant Scheduler.TID := Scheduler.Get_Current_Thread;
      Current_Process : constant Userland.Process.Process_Data_Acc :=
         Userland.Process.Get_By_Thread (Current_Thread);
      File : constant VFS.File.File_Acc :=
         Current_Process.File_Table (Natural (File_D));
   begin
      if Is_Tracing then
         Lib.Messages.Put ("syscall fstat(");
         Lib.Messages.Put (File_D);
         Lib.Messages.Put (", ");
         Lib.Messages.Put (Address, False, True);
         Lib.Messages.Put_Line (")");
      end if;

      if Address = 0 then
         Errno := Error_Would_Fault;
         return 0;
      end if;

      if Inner_Stat (File, Address) then
         Errno := Error_No_Error;
         return 0;
      else
         Errno := Error_Bad_File;
         return Unsigned_64'Last;
      end if;
   end Syscall_FStat;

   function Syscall_LStat
      (Path    : Unsigned_64;
       Address : Unsigned_64;
       Errno   : out Unsigned_64) return Unsigned_64
   is
      Addr : constant System.Address := To_Address (Integer_Address (Path));
      Path_Length  : constant Natural := Lib.C_String_Length (Addr);
      Path_String  : String (1 .. Path_Length) with Address => Addr;
      File : constant VFS.File.File_Acc :=
         VFS.File.Open (Path_String, VFS.File.Access_R);
   begin
      if Is_Tracing then
         Lib.Messages.Put ("syscall lstat(");
         Lib.Messages.Put (Path_String);
         Lib.Messages.Put (", ");
         Lib.Messages.Put (Address, False, True);
         Lib.Messages.Put_Line (")");
      end if;

      if Address = 0 then
         Errno := Error_Would_Fault;
         return 0;
      end if;

      if Inner_Stat (File, Address) then
         Errno := Error_No_Error;
         return 0;
      else
         Errno := Error_Bad_File;
         return Unsigned_64'Last;
      end if;
   end Syscall_LStat;

   function Syscall_Get_CWD
      (Buffer : Unsigned_64;
       Length : Unsigned_64;
       Errno  : out Unsigned_64) return Unsigned_64
   is
      Addr : constant System.Address := To_Address (Integer_Address (Buffer));
      Len  : constant Natural := Natural (Length);
      Path : String (1 .. Len) with Address => Addr;

      Thread  : constant Scheduler.TID := Scheduler.Get_Current_Thread;
      Process : constant Userland.Process.Process_Data_Acc :=
         Userland.Process.Get_By_Thread (Thread);
   begin
      if Is_Tracing then
         Lib.Messages.Put ("syscall getcwd(");
         Lib.Messages.Put (Buffer, False, True);
         Lib.Messages.Put (", ");
         Lib.Messages.Put (Length);
         Lib.Messages.Put_Line (")");
      end if;

      if Buffer = 0 then
         Errno := Error_Would_Fault;
         return 0;
      end if;
      if Len = 0 then
         Errno := Error_Invalid_Value;
         return 0;
      end if;
      if Len < Process.Current_Dir_Len then
         Errno := Error_Not_Big_Enough;
         return 0;
      end if;

      Path (1 .. Process.Current_Dir_Len) :=
         Process.Current_Dir (1 .. Process.Current_Dir_Len);
      Errno := Error_No_Error;
      return Buffer;
   end Syscall_Get_CWD;

   function Syscall_Chdir
      (Path  : Unsigned_64;
       Errno : out Unsigned_64) return Unsigned_64
   is
      Addr    : constant System.Address := To_Address (Integer_Address (Path));
      Thread  : constant Scheduler.TID := Scheduler.Get_Current_Thread;
      Process : constant Userland.Process.Process_Data_Acc :=
         Userland.Process.Get_By_Thread (Thread);
   begin
      if Path = 0 then
         if Is_Tracing then
            Lib.Messages.Put_Line ("syscall chdir(0)");
         end if;
         Errno := Error_Would_Fault;
         return Unsigned_64'Last;
      end if;

      declare
         Path_Length : constant Natural := Lib.C_String_Length (Addr);
         Path_String : String (1 .. Path_Length) with Address => Addr;
      begin
         if Is_Tracing then
            Lib.Messages.Put ("syscall chdir(");
            Lib.Messages.Put (Path_String);
            Lib.Messages.Put_Line (")");
         end if;

         if Path_Length > Process.Current_Dir'Length then
            Errno := Error_String_Too_Long;
            return Unsigned_64'Last;
         end if;

         Process.Current_Dir_Len := Path_Length;
         Process.Current_Dir (1 .. Path_Length) := Path_String;
         Errno := Error_No_Error;
         return 0;
      end;
   end Syscall_Chdir;
end Arch.Syscall;
