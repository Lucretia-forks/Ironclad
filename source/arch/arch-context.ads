--  arch-context.ads: Architecture-specific context switching.
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
with Arch.Interrupts;

package Arch.Context with SPARK_Mode => Off is
   #if ArchName = """aarch64-stivale2"""
      subtype GP_Context is Arch.Interrupts.Frame;
      type    FP_Context is array (1 .. 512) of Unsigned_8;
   #elsif ArchName = """arm-raspi2b"""
      subtype GP_Context is Arch.Interrupts.Frame;
      type    FP_Context is array (1 .. 512) of Unsigned_8;
   #elsif ArchName = """sparc-leon3"""
      --  FIXME: Alignment should be 16, but GCC does not align then?
      subtype GP_Context is Arch.Interrupts.ISR_GPRs;
      type FP_Context is array (1 .. 512) of Unsigned_8 with Alignment => 32;
   #elsif ArchName = """x86_64-multiboot2"""
      --  FIXME: Alignment should be 16, but GCC does not align then?
      subtype GP_Context is Arch.Interrupts.ISR_GPRs;
      type FP_Context is array (1 .. 512) of Unsigned_8 with Alignment => 32;
   #end if;

   --  General-purpose context switching.
   procedure Init_GP_Context
      (Ctx        : out GP_Context;
       Stack      : System.Address;
       Start_Addr : System.Address);
   procedure Load_GP_Context (Ctx : GP_Context) with No_Return;

   --  Save and restore floating-point context.
   procedure Init_FP_Context (Ctx : out FP_Context);
   procedure Save_FP_Context (Ctx : out FP_Context);
   procedure Load_FP_Context (Ctx : FP_Context);
end Arch.Context;
