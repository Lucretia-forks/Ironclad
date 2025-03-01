with
     Devices.e1000e.Defines,
     Devices.e1000e.Registers,
     Devices.e1000e.Hardware.e1000_nvm_info,
     Devices.e1000e.Base.Port,
     Interfaces.C;


package body Devices.e1000e.Non_Volatile_Memory
is
   use Devices.e1000e.Core,
       Devices.e1000e.Core.Pointers,
       Devices.e1000e.Defines,
       Devices.e1000e.Hardware,
       Devices.e1000e.Base.Port,
       Interfaces;


   -------------------------
   -- E1000_Raise_EEC_CLK --
   -------------------------

   --  Raise EEPROM clock.
   --
   --  *  @hw:   Pointer to the HW structure.
   --  *  @eecd: Pointer to the EEPROM.
   --  *
   --  *  Enable/Raise the EEPROM clock bit.


   procedure E1000_Raise_EEC_CLK
     (HW   : access E1000_HW;
      EECD : in out Unsigned_32)
   is
   begin
      EECD := EECD or E1000_EECD_SK;
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_EECD, EECD);
      E1E_Flush (Hw);

      delay Duration (HW.NVM.Delay_Usec) * 0.00_000_1;
   end E1000_Raise_EEC_CLK;



   -------------------------
   -- E1000_Lower_EEC_CLK --
   -------------------------

   --  Lower EEPROM clock.
   --
   --  *  @hw:   Pointer to the HW structure
   --  *  @eecd: Pointer to the EEPROM
   --  *
   --  *  Clear/Lower the EEPROM clock bit.


   procedure E1000_Lower_EEC_CLK
     (HW   : access E1000_HW;
      EECD : in out Unsigned_32)
   is
   begin
      EECD := EECD and (not E1000_EECD_SK);
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_EECD, EECD);
      E1E_Flush (Hw);

      delay Duration (HW.NVM.Delay_Usec) * 0.00_000_1;
   end E1000_Lower_EEC_CLK;




   ------------------------------
   -- E1000_Shift_Out_EEC_Bits --
   ------------------------------

   --  Shift data bits our to the EEPROM.
   --
   --  *  @hw:    Pointer to the HW structure.
   --  *  @data:  Data to send to the EEPROM.
   --  *  @count: Number of bits to shift out.
   --  *
   --  *  We need to shift 'count' bits out to the EEPROM.  So, the value in the
   --  *  "data" parameter will be shifted out to the EEPROM one bit at a time.
   --  *  In order to do this, "data" must be broken down into bits.


   procedure E1000_Shift_Out_EEC_Bits
     (HW    : access E1000_HW;
      Data  : in     Unsigned_16;
      Count : in     Unsigned_16)
   is
      NVM   : E1000_NVM_Info.item renames HW.NVM;
      EECD  : Unsigned_32 := ER32 (Hw.all, Devices.e1000e.Registers.E1000_EECD);
      Mask  : Unsigned_16;

   begin
      Mask := BIT (Integer (Count) - 1);

      if NVM.nvm_type = E1000_NVM_EEPROM_SPI
      then
         EECD := EECD or E1000_EECD_DO;
      end if;

      loop
         EECD := EECD and (not E1000_EECD_DI);

         if (Data and Mask) /= 0
         then
            EECD := EECD or E1000_EECD_DI;
         end if;

         EW32 (Hw.all, Devices.e1000e.Registers.E1000_EECD, EECD);
         E1E_Flush (Hw);

         delay Duration (NVM.Delay_Usec) * 0.00_000_1;

         E1000_Raise_EEC_CLK (HW, EECD);
         E1000_Lower_EEC_CLK (HW, EECD);

         Mask := shift_Right (Mask, 1);
         exit when Mask = 0;
      end loop;

      EECD := EECD and (not E1000_EECD_DI);
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_EECD, EECD);
   end E1000_Shift_Out_EEC_Bits;





   -----------------------------
   -- E1000_Shift_In_EEC_Bits --
   -----------------------------

   --  Shift data bits in from the EEPROM.
   --
   --  *  @hw:    Pointer to the HW structure
   --  *  @count: Number of bits to shift in
   --  *
   --  *  In order to read a register from the EEPROM, we need to shift 'count' bits
   --  *  in from the EEPROM.  Bits are "shifted in" by raising the clock input to
   --  *  the EEPROM (setting the SK bit), and then reading the value of the data out
   --  *  "DO" bit.  During this "shifting in" process the data in "DI" bit should
   --  *  always be clear.


   function E1000_Shift_In_EEC_Bits
     (HW    : access E1000_HW;
      Count : in     Unsigned_16) return Unsigned_16
   is
      EECD : Unsigned_32;
      Data : Unsigned_16 := 0;
   begin
      EECD := ER32 (Hw.all, Devices.e1000e.Registers.E1000_EECD);
      EECD := EECD and (not (E1000_EECD_DO or E1000_EECD_DI));

      for I in 1 .. Count
      loop
         Data := shift_Left (Data, 1);
         E1000_Raise_EEC_CLK (HW, EECD);

         EECD := ER32 (Hw.all, Devices.e1000e.Registers.E1000_EECD);
         EECD := EECD and (not E1000_EECD_DI);

         if (EECD and E1000_EECD_DO) /= 0
         then
            Data := Data or 1;
         end if;

         E1000_Lower_EEC_CLK (HW, EECD);
      end loop;

      return Data;
   end E1000_Shift_In_EEC_Bits;




   -----------------------
   -- E1000_Standby_NVM --
   -----------------------

   --  Return EEPROM to standby state.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Return the EEPROM to a standby state.


   procedure E1000_Standby_NVM
     (HW : access E1000_HW)
   is
      eecd : Unsigned_32 := Er32 (Hw.all, Devices.e1000e.Registers.E1000_EECD);  -- Assuming EECD register address is 0x10

   begin
      if HW.NVM.NVM_Type = E1000_NVM_EEPROM_SPI
      then
         -- Toggle CS to flush commands.
         --
         EECD := EECD or E1000_EECD_CS;            -- Assuming E1000_EECD_CS is 0x02.
         Ew32 (Hw.all, Devices.e1000e.Registers.E1000_EECD, eecd);
         E1E_Flush (Hw);

         delay Duration (HW.NVM.Delay_Usec) * 0.00_000_1;

         EECD := EECD and (not E1000_EECD_CS);
         Ew32 (Hw.all, Devices.e1000e.Registers.E1000_EECD, eecd);
         E1E_Flush (Hw);

         delay Duration (HW.NVM.Delay_Usec) * 0.00_000_1;
      end if;
   end E1000_Standby_NVM;




   --------------------
   -- E1000_Stop_NVM --
   --------------------

   --  Terminate EEPROM command.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Terminates the current command by inverting the EEPROM's chip select pin.


   procedure E1000_Stop_NVM (HW : access E1000_HW)
   is
      EECD : u32;

   begin
      EECD := ER32 (Hw.all, Devices.e1000e.Registers.E1000_EECD);

      if HW.NVM.NVM_Type = E1000_NVM_EEPROM_SPI
      then
         -- Pull CS high.
         --
         EECD := EECD or E1000_EECD_CS;
         E1000_Lower_EEC_CLK (HW, EECD);
      end if;
   end E1000_Stop_NVM;



   ----------------------------
   -- E1000_Ready_NVM_EEPROM --
   ----------------------------

   --  Prepares EEPROM for read/write.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Setups the EEPROM for reading and writing.


   function E1000_Ready_NVM_EEPROM
     (HW : access E1000_HW) return Integer
   is
      use Devices.e1000e.Base;

      NVM          : E1000_NVM_Info.item renames HW.NVM;
      EECD         : Interfaces.Unsigned_32 := ER32 (Hw.all, Devices.e1000e.Registers.E1000_EECD);
      SPI_Stat_Reg : Interfaces.Unsigned_8;

   begin
      if NVM.NVM_Type = E1000_NVM_EEPROM_SPI
      then
         declare
            Timeout : Integer := NVM_MAX_RETRY_SPI;
         begin
            -- Clear SK and CS.
            --
            EECD := EECD and not (E1000_EECD_CS or E1000_EECD_SK);
            EW32 (Hw.all, Devices.e1000e.Registers.E1000_EECD, EECD);
            E1E_Flush (Hw);

            delay 0.00_000_1;     -- 1 microsecond.

            -- Read "Status Register" repeatedly until the LSB is cleared.
            -- The EEPROM will signal that the command has been completed
            -- by clearing bit 0 of the internal status register. If it's
            -- not cleared within 'timeout', then error out.
            --
            while Timeout > 0
            loop
               E1000_Shift_Out_EEC_Bits (HW, NVM_RDSR_OPCODE_SPI,
                                         HW.NVM.Opcode_Bits);

               SPI_Stat_Reg := Interfaces.Unsigned_8 (E1000_Shift_In_EEC_Bits (HW, 8));

               if (SPI_Stat_Reg and NVM_STATUS_RDY_SPI) = 0
               then
                  exit;
               end if;

               delay 5 * 0.00_000_1;

               E1000_Standby_NVM (HW);
               Timeout := Timeout - 1;
            end loop;

            if Timeout = 0
            then
               e_dbg ("SPI NVM Status error");
               return -E1000_ERR_NVM;
            end if;
         end;
      end if;


      return 0;
   end E1000_Ready_NVM_EEPROM;




   -------------------------------
   -- E1000e_Reload_Nvm_Generic --
   -------------------------------

   --  Reloads EEPROM.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Reloads the EEPROM by setting the "Reinitialize from EEPROM" bit in the
   --  *  extended control register.


   procedure E1000e_Reload_Nvm_Generic
     (HW : access E1000_HW)
   is
      Ctrl_Ext : Unsigned_32;
   begin
      -- Sleep for 10 to 20 microseconds.
      --
      delay 15.0 * 0.00_000_1;

      Ctrl_Ext := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT);
      Ctrl_Ext := Ctrl_Ext or E1000_CTRL_EXT_EE_RST;

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT, Ctrl_Ext);
      E1E_Flush (Hw);
   end E1000e_Reload_Nvm_Generic;





   ------------------------
   -- Public Subprograms --
   ------------------------


   ------------------------
   -- E1000E_Acquire_NVM --
   ------------------------

   --  Generic request for access to EEPROM
   --  *  @hw: pointer to the HW structure
   --  *
   --  *  Set the EEPROM access request bit and wait for EEPROM access grant bit.
   --  *  Return successful if access grant bit set, else clear the request for
   --  *  EEPROM access and return -E1000_ERR_NVM (-1).


   function E1000E_Acquire_NVM
     (HW : access E1000_HW) return s32
   is
      use Devices.e1000e.Base;

      EECD    : u32;
      Timeout : s32 := E1000_NVM_GRANT_ATTEMPTS;
   begin
      EECD := ER32 (Hw.all, Devices.e1000e.Registers.E1000_EECD);
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_EECD, EECD or E1000_EECD_REQ);
      EECD := ER32 (Hw.all, Devices.e1000e.Registers.E1000_EECD);

      while Timeout > 0
      loop
         if (EECD and E1000_EECD_GNT) /= 0
         then
            exit;
         end if;

         delay 5 * 0.00_000_1;

         EECD    := ER32 (Hw.all, Devices.e1000e.Registers.E1000_EECD);
         Timeout := Timeout - 1;
      end loop;

      if Timeout = 0 then
         EECD := EECD and (not E1000_EECD_REQ);
         EW32 (Hw.all, Devices.e1000e.Registers.E1000_EECD, EECD);
         e_dbg ("Could not acquire NVM grant");
         return -E1000_ERR_NVM;
      end if;

      return 0;
   end E1000E_Acquire_NVM;





   --------------------------------
   -- E1000e_Poll_Eerd_Eewr_Done --
   --------------------------------

   --  Poll for EEPROM read/write completion.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @ee_reg: EEPROM flag for polling.
   --  *
   --  *  Polls the EEPROM status bit for either read or write completion based
   --  *  upon the value of 'ee_reg'.

   function E1000e_Poll_Eerd_Eewr_Done
     (Hw     : access E1000_Hw;
      Ee_Reg : in     Integer) return s32
   is
      Attempts : constant Unsigned_32 := 100_000;
      Reg      :          Unsigned_32 := 0;

   begin
      for I in 1 .. Attempts
      loop
         if Ee_Reg = E1000_NVM_Poll_Read
         then
            Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_EERD);
         else
            Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_EEWR);
         end if;

         if (Reg and E1000_NVM_RW_Reg_Done) /= 0
         then
            return 0;
         end if;

         delay Duration (0.00_000_5);      -- Equivalent to udelay(5).
      end loop;

      return -E1000_Err_NVM;
   end E1000e_Poll_Eerd_Eewr_Done;




   ---------------------------------
   -- E1000_Read_Mac_Addr_Generic --
   ---------------------------------

   --  Read device MAC address.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Reads the device MAC address from the EEPROM and stores the value.
   --  *  Since devices with two ports use the same EEPROM, we increment the
   --  *  last bit in the MAC address for the second port.


   function E1000_Read_Mac_Addr_Generic
     (Hw : access E1000_Hw) return s32
   is
      use type C.size_t;

      Rar_High : Unsigned_32;
      Rar_Low  : Unsigned_32;

   begin
      Rar_High := Er32 (Hw.all, Devices.e1000e.Registers.E1000_RAH (0));
      Rar_Low  := Er32 (Hw.all, Devices.e1000e.Registers.E1000_RAL (0));


      for I in C.size_t (0) .. E1000_RAL_MAC_ADDR_LEN - 1
      loop
         Hw.Mac.Perm_Addr (I) := Unsigned_8 (shift_Right (Rar_Low,
                                             Natural (I) * 8));
      end loop;


      for I in C.size_t (0) .. E1000_RAH_MAC_ADDR_LEN - 1
      loop
         Hw.Mac.Perm_Addr (I + 4) := Unsigned_8 (shift_Right (Rar_High,
                                                 Natural (I) * 8));
      end loop;


      for I in C.size_t (0) .. ETH_ALEN - 1
      loop
         Hw.Mac.Addr (I) := Hw.Mac.Perm_Addr (I);
      end loop;

      return 0;
   end E1000_Read_Mac_Addr_Generic;




   -----------------------------------
   -- E1000_Read_PBA_String_Generic --
   -----------------------------------

   --  Read device part number.
   --
   --  *  @hw:           Pointer to the HW structure.
   --  *  @pba_num:      Pointer to device part number.
   --  *  @pba_num_size: Size of part number buffer.
   --  *
   --  *  Reads the product board assembly (PBA) number from the EEPROM and stores
   --  *  the value in pba_num.


   function E1000_Read_PBA_String_Generic
     (HW           : access E1000_HW;
      PBA_Num      : in     u8_Pointer;
      PBA_Num_Size : in     u32) return s32
   is
      use Devices.e1000e.Base;
      use type u8_Pointer,
          C.size_t;

      NVM_Data   : aliased Unsigned_16;
      PBA_Ptr    : aliased Unsigned_16;
      Offset     :         u16;
      Length     : aliased u16;
      Ret_Val    :         s32;

      PBA_Num_Buffer : u8_array (0 .. C.size_t (PBA_NUM_SIZE) - 1)
        with
          Address => PBA_Num.all'Address;

   begin
      if PBA_Num = null                                  -- TODO: Compiler says this is always false ?!
      then
         e_dbg ("PBA string buffer was null");
         return -E1000_ERR_INVALID_ARGUMENT;
      end if;


      Ret_Val := E1000_Read_NVM (HW,
                                 NVM_PBA_OFFSET_0,
                                 1,
                                 NVM_Data'unchecked_Access);
      if Ret_Val /= 0
      then
         e_dbg ("NVM Read Error");
         return Ret_Val;
      end if;


      Ret_Val := E1000_Read_NVM (HW,
                                 NVM_PBA_OFFSET_1,
                                 1,
                                 PBA_Ptr'unchecked_Access);
      if Ret_Val /= 0
      then
         e_dbg ("NVM Read Error");
         return Ret_Val;
      end if;


      --  If nvm_data is not ptr guard the PBA must be in legacy format which
      --  means pba_ptr is actually our second data word for the PBA number
      --  and we can decode it into an ascii string.
      --
      if NVM_Data /= NVM_PBA_PTR_GUARD
      then
         e_dbg ("NVM PBA number is not stored as string");

         -- Make sure callers buffer is big enough to store the PBA.
         --
         if PBA_Num_Size < E1000_PBANUM_LENGTH
         then
            e_dbg ("PBA string buffer too small");
            return E1000_ERR_NO_SPACE;
         end if;

         -- Extract hex string from data and pba_ptr.
         --
         PBA_Num_Buffer (0) := u8 (shift_Right (NVM_Data, 12) and 16#F#);
         PBA_Num_Buffer (1) := u8 (shift_Right (NVM_Data,  8) and 16#F#);
         PBA_Num_Buffer (2) := u8 (shift_Right (NVM_Data,  4) and 16#F#);
         PBA_Num_Buffer (3) := u8 (NVM_Data                   and 16#F#);
         PBA_Num_Buffer (4) := u8 (shift_Right (PBA_Ptr, 12)  and 16#F#);
         PBA_Num_Buffer (5) := u8 (shift_Right (PBA_Ptr,  8)  and 16#F#);
         PBA_Num_Buffer (6) := Character'Pos ('-');
         PBA_Num_Buffer (7) := 0;
         PBA_Num_Buffer (8) := u8 (shift_Right (PBA_Ptr,  4)  and 16#F#);
         PBA_Num_Buffer (9) := u8 (PBA_Ptr                    and 16#F#);

         -- Put a null character on the end of our string.
         --
         PBA_Num_Buffer (10) := 0;


         -- Switch all the data but the '-' to hex char.
         --
         for Offset in C.size_t (0) .. 9
         loop
            if PBA_Num_Buffer (Offset) /= Character'Pos ('-')
            then

               if    PBA_Num_Buffer (Offset) < 16#A#
               then
                  PBA_Num_Buffer (Offset) := @ + Character'Pos ('0');

               elsif PBA_Num_Buffer (Offset) < 16#10#
               then
                  PBA_Num_Buffer (Offset) := @ + Character'Pos ('A') - 16#A#;
               end if;

            end if;
         end loop;

         return 0;
      end if;


      Ret_Val := E1000_Read_NVM (HW,
                                 PBA_Ptr,
                                 1,
                                 Length'unchecked_Access);
      if Ret_Val /= 0
      then
         e_dbg ("NVM Read Error");
         return Ret_Val;
      end if;


      if   Length = 16#FFFF#
        or Length = 0
      then
         e_dbg ("NVM PBA number section invalid length");
         return -E1000_ERR_NVM_PBA_SECTION;
      end if;


      -- Check if pba_num buffer is big enough.
      --
      if PBA_Num_Size < u32 (Length) * 2 - 1
      then
         e_dbg ("PBA string buffer too small");
         return -E1000_ERR_NO_SPACE;
      end if;


      -- Trim pba length from start of string.
      --
      PBA_Ptr := PBA_Ptr + 1;
      Length  := Length  - 1;

      for Offset in 0 .. C.size_t (Length) - 1
      loop
         Ret_Val := E1000_Read_NVM (HW,
                                    PBA_Ptr + u16 (Offset),
                                    1,
                                    NVM_Data'unchecked_Access);
         if Ret_Val /= 0
         then
            e_dbg ("NVM Read Error");
            return Ret_Val;
         end if;


         PBA_Num_Buffer (Offset * 2)     := u8 (shift_Right (NVM_Data, 8));
         PBA_Num_Buffer (Offset * 2 + 1) := u8 (NVM_Data and 16#FF#);
      end loop;


      PBA_Num_Buffer (C.size_t (Length) * 2) := 0;
      return 0;
   end E1000_Read_PBA_String_Generic;







   --------------------------
   -- E1000E_Read_NVM_EERD --
   --------------------------

   --  Reads EEPROM using EERD register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Offset of word in the EEPROM to read.
   --  *  @words:  Number of words to read.
   --  *  @data:   Word read from the EEPROM.
   --  *
   --  *  Reads a 16 bit word from the EEPROM using the EERD register.


   function E1000E_Read_NVM_EERD
     (HW     : access E1000_HW;
      Offset : in     Unsigned_16;
      Words  : in     Unsigned_16;
      Data   : in     u16_Pointer) return s32
   is
      use Devices.e1000e.Base;
      use type C.size_t;

      NVM     : E1000_NVM_Info.item renames HW.NVM;
      EERD    : Unsigned_32 := 0;
      Ret_Val : s32         := 0;

      Buffer  : u16_array (0 .. C.size_t (Words) - 1)
        with
          Address => Data.all'Address;

   begin
      -- A check for invalid values: offset too large, too many words,
      -- too many words for the offset, and not enough words.
      --
      if        Offset >= NVM.Word_Size
        or else Words  > (NVM.Word_Size - Offset)
        or else Words  = 0
      then
         e_dbg ("NVM parameter(s) out of bounds");
         return -E1000_ERR_NVM;
      end if;


      for I in Buffer'Range
      loop
         EERD :=   shift_Left (u32 (Offset) + u32 (I),
                               E1000_NVM_RW_ADDR_SHIFT)
           + E1000_NVM_RW_REG_START;

         EW32 (Hw.all, Devices.e1000e.Registers.E1000_EERD, EERD);
         Ret_Val := E1000E_Poll_EERD_EEWR_Done (HW, E1000_NVM_POLL_READ);

         if Ret_Val /= 0
         then
            e_dbg ("NVM read error:" & Ret_Val'Image);
            exit;
         end if;

         Buffer (I) := u16 (shift_Right (ER32 (Hw.all, Devices.e1000e.Registers.E1000_EERD),
                            E1000_NVM_RW_REG_DATA));
      end loop;

      return Ret_Val;
   end E1000E_Read_NVM_EERD;





   ------------------------------
   -- e1000e_valid_led_default --     TODO: This is implemented in 'mac.c' !
   ------------------------------

   function e1000e_valid_led_default
     (hw   : access e1000_hw;
      data : in     Devices.e1000e.Core.Pointers.u16_Pointer) return Devices.e1000e.Core.s32
   is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "e1000e_valid_led_default unimplemented");
      return
        raise Program_Error
          with "Unimplemented function e1000e_valid_led_default";
   end e1000e_valid_led_default;




   ------------------------------------------
   -- E1000e_Validate_NVM_Checksum_Generic --
   ------------------------------------------

   --  Validate EEPROM checksum.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Calculates the EEPROM checksum by reading/adding each word of the EEPROM
   --  *  and then verifies that the sum of the EEPROM is equal to 0xBABA.


   function E1000e_Validate_NVM_Checksum_Generic
     (HW : access E1000_HW) return s32
   is
      use Devices.e1000e.Base;

      Ret_Val  :         s32;
      Checksum :         Unsigned_16 := 0;
      NVM_Data : aliased Unsigned_16;

   begin
      for I in 0 .. NVM_CHECKSUM_REG
      loop
         Ret_Val := E1000_Read_NVM (HW,
                                    Unsigned_16 (I),
                                    1,
                                    NVM_Data'unchecked_Access);
         if Ret_Val /= 0
         then
            e_dbg ("NVM Read Error");
            return Ret_Val;
         end if;

         Checksum := Checksum + NVM_Data;
      end loop;


      if Checksum /= Unsigned_16 (NVM_SUM)
      then
         e_dbg ("NVM Checksum Invalid");
         return -E1000_ERR_NVM;
      end if;

      return 0;
   end E1000e_Validate_NVM_Checksum_Generic;




   --------------------------
   -- E1000E_Write_NVM_SPI --
   --------------------------

   --  Write to EEPROM using SPI.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Offset within the EEPROM to be written to.
   --  *  @words:  Number of words to write.
   --  *  @data:   16 bit word(s) to be written to the EEPROM.
   --  *
   --  *  Writes data to EEPROM at offset using SPI interface.
   --  *
   --  *  If e1000e_update_nvm_checksum is not called after this function , the
   --  *  EEPROM will most likely contain an invalid checksum.


   function E1000E_Write_NVM_SPI
     (HW     : access E1000_HW;
      Offset : in     Unsigned_16;
      Words  : in     Unsigned_16;
      Data   : in     u16_Pointer) return s32
   is
      use Devices.e1000e.Base;
      use type C.size_t;

      NVM      : E1000_NVM_Info.item renames HW.NVM;
      Ret_Val  : s32         := -E1000_ERR_NVM;
      Widx     : Unsigned_16 := 0;
      Word_Out : Unsigned_16;

      Buffer   : u16_array (0 .. C.size_t (Words) - 1)
        with
          Address => Data.all'Address;

   begin
      -- A check for invalid values: offset too large, too many words,
      -- and not enough words.
      --
      if   Offset >= NVM.Word_Size
        or Words  > (NVM.Word_Size - Offset)
        or Words  = 0
      then
         e_dbg ("nvm parameter(s) out of bounds");
         return -E1000_ERR_NVM;
      end if;


      while Widx < Words
      loop
         declare
            Write_Opcode : Unsigned_8 := NVM_WRITE_OPCODE_SPI;
         begin
            Ret_Val := NVM.Ops.Acquire (HW);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;


            Ret_Val := s32 (E1000_Ready_NVM_EEPROM (HW));

            if Ret_Val /= 0
            then
               NVM.Ops.Release (HW);
               return Ret_Val;
            end if;


            E1000_Standby_NVM (HW);

            -- Send the WRITE ENABLE command (8 bit opcode).
            --
            E1000_Shift_Out_EEC_Bits (HW, NVM_WREN_OPCODE_SPI, NVM.Opcode_Bits);
            E1000_Standby_NVM        (HW);

            -- Some SPI eeproms use the 8th address bit embedded in the opcode.
            --
            if    NVM.Address_Bits = 8
              and Offset          >= 128
            then
               Write_Opcode := Write_Opcode or NVM_A8_OPCODE_SPI;
            end if;

            -- Send the Write command (8-bit opcode + addr).
            --
            E1000_Shift_Out_EEC_Bits (HW, Unsigned_16 (Write_Opcode), NVM.Opcode_Bits);
            E1000_Shift_Out_EEC_Bits (HW, (Offset + Widx) * 2,        NVM.Address_Bits);

            -- Loop to allow for up to whole page write of eeprom.
            --
            while Widx < Words
            loop
               Word_Out := Buffer (C.size_t (Widx));
               Word_Out :=    shift_Right (Word_Out, 8)                -- TODO: Check this. Which shift occurs 1st ? Does it match C ?
                 or shift_Left  (Word_Out, 8);

               E1000_Shift_Out_EEC_Bits (HW, Word_Out, 16);
               Widx := Widx + 1;

               if ((Offset + Widx) * 2) mod NVM.Page_Size = 0
               then
                  E1000_Standby_NVM (HW);
                  exit;
               end if;
            end loop;


            delay 0.01_5;              -- Equivalent to usleep_range(10000, 11000)
            NVM.Ops.Release (HW);
         end;
      end loop;


      return Ret_Val;
   end E1000E_Write_NVM_SPI;





   ---------------------------------
   -- E1000_Update_NVM_Checksum_Generic --
   ---------------------------------

   --  Update EEPROM checksum.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Updates the EEPROM checksum by reading/adding each word of the EEPROM
   --  *  up to the checksum.  Then calculates the EEPROM checksum and writes the
   --  *  value to the EEPROM.


   function e1000e_Update_NVM_Checksum_Generic
     (HW : access E1000_HW) return s32
   is
      use Devices.e1000e.Base;

      Ret_Val  :         s32;
      Checksum : aliased Unsigned_16 := 0;
      NVM_Data : aliased Unsigned_16;

   begin
      for I in 0 .. NVM_CHECKSUM_REG - 1
      loop
         Ret_Val := E1000_Read_NVM (HW,
                                    Unsigned_16 (I),
                                    1,
                                    NVM_Data'unchecked_Access);
         if Ret_Val /= 0
         then
            e_dbg ("NVM Read Error while updating checksum.");
            return Ret_Val;
         end if;

         Checksum := Checksum + NVM_Data;
      end loop;


      Checksum := Unsigned_16 (NVM_SUM) - Checksum;
      Ret_Val  := E1000_Write_NVM (HW,
                                   NVM_CHECKSUM_REG,
                                   1,
                                   Checksum'unchecked_Access);
      if Ret_Val /= 0
      then
         e_dbg ("NVM Write Error while updating checksum.");
      end if;


      return Ret_Val;
   end e1000e_Update_NVM_Checksum_Generic;





   ------------------------
   -- E1000e_Release_NVM --
   ------------------------

   --  Release exclusive access to EEPROM
   --  *  @hw: pointer to the HW structure
   --  *
   --  *  Stop any current commands to the EEPROM and clear the EEPROM request bit.


   procedure E1000e_Release_NVM (HW : access E1000_HW)
   is
      EECD : Unsigned_32;

   begin
      E1000_Stop_NVM (HW);

      EECD := ER32 (Hw.all, Devices.e1000e.Registers.E1000_EECD);
      EECD := EECD and (not E1000_EECD_REQ);
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_EECD, EECD);
   end E1000e_Release_NVM;

end Devices.e1000e.Non_Volatile_Memory;
