with
     Devices.e1000e.Registers;


package body Devices.e1000e.Base.Port
is
   use Devices.e1000e.Ich8Lan,
       Linux;



   --------------
   -- e1e_rphy --
   --------------

   function e1e_rphy
     (hw     : access an_e1000_hw;
      offset : in     Devices.e1000e.Core.u32;
      data   : in     Devices.e1000e.Core.Pointers.u16_Pointer) return Devices.e1000e.Core.s32
   is
   begin
      return hw.phy.ops.read_reg (hw, offset, data);
   end e1e_rphy;




   procedure e1e_wphy
     (hw     : access an_e1000_hw;
      offset : in     Devices.e1000e.Core.u32;
      data   : in     Devices.e1000e.Core.u16)
   is
      Unused : s32;
   begin
      Unused := e1e_wphy (hw, offset, data);
   end e1e_wphy;




   procedure er32
     (hw  : in an_e1000_hw;
      reg : in Interfaces.C.unsigned_long)
   is
      Unused : u32;
   begin
      Unused := er32 (hw, reg);
   end er32;




   ------------------
   -- ew32_Prepare --
   ------------------

   --    Prepare to write to MAC CSR register on certain parts.
   --
   --  * @hw: Pointer to the HW structure.
   --  *
   --  * When updating the MAC CSR registers, the Manageability Engine (ME) could
   --  * be accessing the registers at the same time.  Normally, this is handled in
   --  * h/w by an arbiter but on some parts there is a bug that acknowledges Host
   --  * accesses later than it should which could result in the register to have
   --  * an incorrect value.  Workaround this by checking the FWSM register which
   --  * has bit 24 set while ME is accessing MAC CSR registers, wait if it is set
   --  * and try again a number of times.


   procedure ew32_prepare
     (HW : in an_E1000_HW)
   is
      I    : s32 := E1000_ICH_FWSM_PCIM2PCI_COUNT;
      FWSM : u32;

   begin
      loop
         FWSM := Er32 (HW, Devices.e1000e.Registers.E1000_FWSM);

         exit when    (FWSM and E1000_ICH_FWSM_PCIM2PCI) = 0
                   or I = 0;

         delay 50.0 * Microseconds;
         I := I - 1;
      end loop;
   end ew32_prepare;




   ----------
   -- ew32 --
   ----------

   procedure ew32
     (hw  : in an_e1000_hw;
      reg : in C.unsigned_long;
      val : in Devices.e1000e.Core.u32)
   is
   begin
      if (HW.Adapter.Flags2 and C.unsigned (FLAG2_PCIM2PCI_ARBITER_WA)) /= 0
      then
         ew32_prepare (HW);
      end if;

      writel (Val,
              HW.HW_Addr + storage_Offset (Reg));
   end ew32;




   ---------------
   -- e1e_flush --
   ---------------

   procedure e1e_flush (Hw : access an_e1000_hw)
   is
   begin
     er32 (Hw.all, Devices.e1000e.Registers.E1000_STATUS);
   end e1e_flush;




   ---------------------------
   -- E1000_WRITE_REG_ARRAY --
   ---------------------------

   procedure E1000_WRITE_REG_ARRAY
     (a      : access an_e1000_hw;
      reg    : in     u32;
      offset : in     u32;
      value  : in     u32)
   is
   begin
      ew32 (hw  => a.all,
            reg => C.unsigned_long (reg + shift_Left (offset, 2)),
            val => value);
   end E1000_WRITE_REG_ARRAY;



end Devices.e1000e.Base.Port;
