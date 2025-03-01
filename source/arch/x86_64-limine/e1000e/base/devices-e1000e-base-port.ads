with
     Devices.e1000e.Base.e1000_info,
     Devices.e1000e.Hardware.e1000_hw,
     Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32,

     Devices.e1000e.an_82571,
     Devices.e1000e.Ich8Lan,
     Devices.e1000e.an_80003es2lan,
     Devices.e1000e.Non_Volatile_Memory,

     Devices.e1000e.Core.Pointers,
     Linux,

     interfaces.C,
     system.storage_Elements;


package Devices.e1000e.Base.Port
is
   use Interfaces.C,
       system.storage_Elements;

   subtype an_e1000_hw is Devices.e1000e.Hardware.e1000_hw.item;


   ----------
   --- Info's
   --

   e1000_82571_info   : Devices.e1000e.Base.e1000_info.item renames Devices.e1000e.an_82571.e1000_82571_info;
   e1000_82572_info   : Devices.e1000e.Base.e1000_info.item renames Devices.e1000e.an_82571.e1000_82572_info;
   e1000_82573_info   : Devices.e1000e.Base.e1000_info.item renames Devices.e1000e.an_82571.e1000_82573_info;
   e1000_82574_info   : Devices.e1000e.Base.e1000_info.item renames Devices.e1000e.an_82571.e1000_82574_info;
   e1000_82583_info   : Devices.e1000e.Base.e1000_info.item renames Devices.e1000e.an_82571.e1000_82583_info;
   e1000_ich8_info    : Devices.e1000e.Base.e1000_info.item renames Devices.e1000e.Ich8Lan.e1000_ich8_info;
   e1000_ich9_info    : Devices.e1000e.Base.e1000_info.item renames Devices.e1000e.Ich8Lan.e1000_ich9_info;
   e1000_ich10_info   : Devices.e1000e.Base.e1000_info.item renames Devices.e1000e.Ich8Lan.e1000_ich10_info;
   e1000_pch_info     : Devices.e1000e.Base.e1000_info.item renames Devices.e1000e.Ich8Lan.e1000_pch_info;
   e1000_pch2_info    : Devices.e1000e.Base.e1000_info.item renames Devices.e1000e.Ich8Lan.e1000_pch2_info;
   e1000_pch_lpt_info : Devices.e1000e.Base.e1000_info.item renames Devices.e1000e.Ich8Lan.e1000_pch_lpt_info;
   e1000_pch_spt_info : Devices.e1000e.Base.e1000_info.item renames Devices.e1000e.Ich8Lan.e1000_pch_spt_info;
   e1000_pch_cnp_info : Devices.e1000e.Base.e1000_info.item renames Devices.e1000e.Ich8Lan.e1000_pch_cnp_info;
   e1000_pch_tgp_info : Devices.e1000e.Base.e1000_info.item renames Devices.e1000e.Ich8Lan.e1000_pch_tgp_info;
   e1000_pch_adp_info : Devices.e1000e.Base.e1000_info.item renames Devices.e1000e.Ich8Lan.e1000_pch_adp_info;
   e1000_pch_mtp_info : Devices.e1000e.Base.e1000_info.item renames Devices.e1000e.Ich8Lan.e1000_pch_mtp_info;
   e1000_es2_info     : Devices.e1000e.Base.e1000_info.item renames Devices.e1000e.an_80003es2lan.e1000_es2_info;



   ---------------
   --- Subprograms
   --


   function e1000_phy_hw_reset
     (hw : access an_e1000_hw) return Devices.e1000e.Core.s32
   is
      (hw.phy.ops.reset (hw));



   function e1e_rphy
     (hw     : access an_e1000_hw;
      offset : in     Devices.e1000e.Core.u32;
      data   : in     Devices.e1000e.Core.Pointers.u16_Pointer) return Devices.e1000e.Core.s32
     with
       Inline;



   function e1e_rphy_locked
     (hw     : access an_e1000_hw;
      offset : in     Devices.e1000e.Core.u32;
      data   : in     Devices.e1000e.Core.Pointers.u16_Pointer) return Devices.e1000e.Core.s32
   is
      (hw.phy.ops.read_reg_locked (hw, offset, data));



   function e1e_wphy
     (hw     : access an_e1000_hw;
      offset : in     Devices.e1000e.Core.u32;
      data   : in     Devices.e1000e.Core.u16) return Devices.e1000e.Core.s32
   is
      (hw.phy.ops.write_reg (hw, offset, data));



   procedure e1e_wphy
     (hw     : access an_e1000_hw;
      offset : in     Devices.e1000e.Core.u32;
      data   : in     Devices.e1000e.Core.u16);



   function e1e_wphy_locked
     (hw     : access an_e1000_hw;
      offset : in     Devices.e1000e.Core.u32;
      data   : in     Devices.e1000e.Core.u16) return Devices.e1000e.Core.s32
   is
      (hw.phy.ops.write_reg_locked (hw, offset, data));



   use type Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.item;

   function e1000e_read_mac_addr
     (hw : access an_e1000_hw) return Devices.e1000e.Core.s32
   is
      (if hw.mac.ops.read_mac_addr /= null
      then
         hw.mac.ops.read_mac_addr (hw)
      else
         Devices.e1000e.Non_Volatile_Memory.e1000_read_mac_addr_generic (hw));



   function e1000_validate_nvm_checksum
     (hw : access an_e1000_hw) return Devices.e1000e.Core.s32
   is
     (hw.nvm.ops.validate (hw));



   function e1000e_update_nvm_checksum
     (hw : access an_e1000_hw) return Devices.e1000e.Core.s32
   is
      (hw.nvm.ops.update (hw));



   function e1000_read_nvm
     (hw     : access an_e1000_hw;
      offset : in     Devices.e1000e.Core.u16;
      words  : in     Devices.e1000e.Core.u16;
      data   : in     Devices.e1000e.Core.Pointers.u16_Pointer) return Devices.e1000e.Core.s32
   is
      (hw.nvm.ops.read (hw, offset, words, data));



   function e1000_write_nvm
     (Hw     : access an_e1000_hw;
      offset : in     Devices.e1000e.Core.u16;
      words  : in     Devices.e1000e.Core.u16;
      data   : in     Devices.e1000e.Core.Pointers.u16_Pointer) return Devices.e1000e.Core.s32
   is
      (Hw.nvm.ops.write (Hw, offset, words, data));



   function e1000_get_phy_info
     (hw : access an_e1000_hw) return Devices.e1000e.Core.s32
   is
      (hw.phy.ops.get_info (hw));



   function er32
     (hw  : in an_e1000_hw;
      reg : in Interfaces.C.unsigned_long) return Devices.e1000e.Core.u32
   is
      (linux.readl (hw.hw_addr + storage_Offset (reg)));



   procedure er32
     (hw  : in an_e1000_hw;
      reg : in Interfaces.C.unsigned_long);



   procedure ew32
     (hw  : in an_e1000_hw;
      reg : in C.unsigned_long;
      val : in u32);



   procedure ew32_prepare
     (HW : in an_E1000_HW);



   procedure e1e_flush (Hw : access an_e1000_hw);



   procedure E1000_WRITE_REG_ARRAY
     (a      : access an_e1000_hw;
      reg    : in     u32;
      offset : in     u32;
      value  : in     u32);



   function E1000_READ_REG_ARRAY
     (a      : access an_e1000_hw;
      reg    : in     u32;
      offset : in     u32) return u32
   is
     (linux.readl (a.hw_addr + storage_Offset (reg + shift_Left (offset, 2))));



end Devices.e1000e.Base.Port;
