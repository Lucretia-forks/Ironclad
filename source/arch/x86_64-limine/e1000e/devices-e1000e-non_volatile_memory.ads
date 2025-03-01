with
     Devices.e1000e.Hardware.e1000_hw,
     Devices.e1000e.Core.Pointers;


package Devices.e1000e.Non_Volatile_Memory
is

   subtype e1000_hw is Devices.e1000e.Hardware.e1000_hw.item;


   E1000_STM_OPCODE : constant := 16#db00#;


   ---------------
   --- Subprograms
   --

   function e1000e_acquire_nvm
     (hw     : access e1000_hw)      return Devices.e1000e.Core.s32;

   function e1000e_poll_eerd_eewr_done
     (hw     : access e1000_hw;
      ee_reg : in     Integer)       return Devices.e1000e.Core.s32;

   function e1000_read_mac_addr_generic
     (hw     : access e1000_hw)      return Devices.e1000e.Core.s32;

   function e1000_read_pba_string_generic
     (hw           : access e1000_hw;
      pba_num      : in     Devices.e1000e.Core.Pointers.u8_Pointer;
      pba_num_size : in     Devices.e1000e.Core.u32) return Devices.e1000e.Core.s32;

   function e1000e_read_nvm_eerd
     (hw     : access e1000_hw;
      offset : in     Devices.e1000e.Core.u16;
      words  : in     Devices.e1000e.Core.u16;
      data   : in     Devices.e1000e.Core.Pointers.u16_Pointer) return Devices.e1000e.Core.s32;


   -- TODO: This is implemented in 'mac.c' !
   --
   function e1000e_valid_led_default
     (hw   : access e1000_hw;
      data : in     Devices.e1000e.Core.Pointers.u16_Pointer)   return Devices.e1000e.Core.s32;


   function e1000e_validate_nvm_checksum_generic
     (hw     : access e1000_hw)       return Devices.e1000e.Core.s32;

   function e1000e_write_nvm_spi
     (hw     : access e1000_hw;
      offset : in     Devices.e1000e.Core.u16;
      words  : in     Devices.e1000e.Core.u16;
      data   : in     Devices.e1000e.Core.Pointers.u16_Pointer) return Devices.e1000e.Core.s32;

   function e1000e_update_nvm_checksum_generic
     (hw : access e1000_hw)           return Devices.e1000e.Core.s32;

   procedure e1000e_release_nvm
     (hw : access e1000_hw);


   procedure E1000e_Reload_Nvm_Generic
     (HW : access E1000_HW);


end Devices.e1000e.Non_Volatile_Memory;
