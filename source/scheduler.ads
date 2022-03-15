--  userland-scheduler.ads: Specification of the scheduler.
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

with Interfaces; use Interfaces;
with Arch.Interrupts;
with Memory.Virtual;
with Memory; use Memory;
with Userland;
with Userland.ELF;

package Scheduler is
   --  True if the scheduler is initialized.
   Is_Initialized : Boolean with Volatile;

   --  Initialize the scheduler, return true on success, false on failure.
   function Init return Boolean;

   --  Use when doing nothing and we want the scheduler to put us to work.
   --  Doubles as the function to initialize core locals.
   procedure Idle_Core;

   --  Creates a kernel thread, and queues it for execution.
   --  Allows to pass an argument to the thread, that will be loaded to RDI.
   --  (C calling convention).
   --  Return thread ID or 0 on failure.
   type TID is new Natural;
   function Create_Kernel_Thread
      (Address  : Virtual_Address;
       Argument : Unsigned_64) return TID;

   --  Creates a userland thread, and queues it for execution.
   --  Return thread ID or 0 on failure.
   function Create_User_Thread
      (Address   : Virtual_Address;
       Args      : Userland.Argument_Arr;
       Env       : Userland.Environment_Arr;
       Map       : Memory.Virtual.Page_Map_Acc;
       Vector    : Userland.ELF.Auxval;
       Stack_Top : Unsigned_64) return TID;

   --  Removes a thread, kernel or user, from existance (if it exists).
   procedure Delete_Thread (Thread : TID);

   --  Sets whether a thread is allowed to execute or not (if it exists).
   procedure Ban_Thread (Thread : TID; Is_Banned : Boolean);

   --  Get the preference for the thread.
   --  Returns 0 on failure, else, the preference.
   function Get_Thread_Preference (Thread : TID) return Natural;

   --  Set the preference for the thread to run, the higher the value, the
   --  more preference.
   --  Values higher than accepted will be colapsed.
   procedure Set_Thread_Preference (Thread : TID; Preference : Positive);

   --  Give up the rest of our execution time for some other process.
   procedure Yield;

   --  Delete and yield the current thread.
   procedure Bail;

   --  Returns whether the current thread is userspace.
   function Is_Userspace return Boolean;

   --  Returns the current thread.
   function Get_Current_Thread return TID;
private
   function Find_Free_TID return TID;
   procedure Scheduler_ISR
      (Number : Unsigned_32;
       State  : access Arch.Interrupts.ISR_GPRs);
   function Is_Thread_Present (Thread : TID) return Boolean;
end Scheduler;
