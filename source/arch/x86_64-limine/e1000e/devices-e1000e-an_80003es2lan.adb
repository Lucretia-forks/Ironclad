with
     Devices.e1000e.Defines,
     Devices.e1000e.Registers,
     Devices.e1000e.Base.Port,
     Devices.e1000e.Hardware.e1000_phy_info,
     Devices.e1000e.Hardware.e1000_nvm_info,
     Devices.e1000e.Hardware.E1000_Mac_Info,
     Linux;


package body Devices.e1000e.an_80003es2lan
is
   use Devices.e1000e.Defines,
       Devices.e1000e.Physical_Layer,
       Devices.e1000e.Media_Access_Control,
       Devices.e1000e.Non_Volatile_Memory,
       Devices.e1000e.Manage,
       Devices.e1000e.Base.Port,
       Interfaces;


   procedure dummy is null;



   -- A table for the GG82563 cable length where the range is defined
   -- with a lower bound at "index" and the upper bound at
   -- "index + 5".
   --
   E1000_GG82563_Cable_Length_Table : constant array (0 .. 10) of Unsigned_16 := [0,   60, 115, 150, 150,
                                                                                  60, 115, 150, 180, 180,
                                                                                  16#FF#];
   GG82563_CABLE_LENGTH_TABLE_SIZE  : constant Natural                        := E1000_GG82563_Cable_Length_Table'Length;     -- TODO: Check ARRAY_SIZE gives same as 'Length.




   ----------------------
   -- Subprogram Specs --
   ----------------------

   function E1000_Setup_Copper_Link_80003es2lan      (HW : access E1000_HW) return s32;

   function E1000_Acquire_Swfw_Sync_80003es2lan      (HW   : access E1000_HW;
                                                      Mask : in     Unsigned_16) return s32;

   procedure E1000_Release_Swfw_Sync_80003es2lan     (HW   : access E1000_HW;
                                                      Mask : in     Unsigned_16);

   procedure E1000_Initialize_Hw_Bits_80003es2lan    (HW : access E1000_HW);

   --  procedure E1000_Clear_Hw_Cntrs_80003es2lan        (HW : access E1000_HW);

   function E1000_Cfg_Kmrn_1000_80003es2lan          (HW : access E1000_HW) return s32;

   function E1000_Cfg_Kmrn_10_100_80003es2lan        (HW     : access E1000_HW;
                                                      Duplex : in     Unsigned_16) return s32;

   function E1000_Read_Kmrn_Reg_80003es2lan          (HW     : access E1000_HW;
                                                      Offset : in     Unsigned_32;
                                                      Data   : in     u16_Pointer) return s32;

   function E1000_Write_Kmrn_Reg_80003es2lan         (HW     : access E1000_HW;
                                                      Offset : in     Unsigned_32;
                                                      Data   : in     Unsigned_16) return s32;

   procedure E1000_Power_Down_Phy_Copper_80003es2lan (HW : access E1000_HW);





   -----------------
   -- Subprograms --
   -----------------


   ---------------------------------------
   -- E1000_Init_Phy_Params_80003es2lan --
   ---------------------------------------

   --  Init ESB2 PHY func ptrs.
   --
   --  *  @hw: Pointer to the HW structure.


   function E1000_Init_Phy_Params_80003es2lan
     (Hw : access E1000_Hw) return s32
   is
      Phy     : E1000_Phy_Info.item renames Hw.Phy;
      Ret_Val : s32;

   begin
      if Hw.Phy.Media_Type /= E1000_Media_Type_Copper
      then
         Phy.Phy_Type := E1000_Phy_None;
         return 0;

      else
         Phy.Ops.Power_Up   := E1000_Power_Up_Phy_Copper              'Access;
         Phy.Ops.Power_Down := E1000_Power_Down_Phy_Copper_80003es2lan'Access;
      end if;


      Phy.Addr           := 1;
      Phy.Autoneg_Mask   := AUTONEG_ADVERTISE_SPEED_DEFAULT;
      Phy.Reset_Delay_Us := 100;
      Phy.Phy_Type       := E1000_Phy_Gg82563;

      -- This can only be done after all function pointers are setup.
      --
      Ret_Val := E1000e_Get_Phy_Id (Hw);

      -- Verify phy id.
      --
      if Phy.Id /= GG82563_E_PHY_ID
      then
         return -E1000_ERR_PHY;
      end if;

      return Ret_Val;
   end E1000_Init_Phy_Params_80003es2lan;






   ---------------------------------------
   -- E1000_Init_NVM_Params_80003es2lan --
   ---------------------------------------

   --  Init ESB2 NVM func ptrs.
   --
   --  *  @hw: Pointer to the HW structure.


   function E1000_Init_NVM_Params_80003es2lan
     (HW : access E1000_HW) return s32
   is
      NVM  :          E1000_NVM_Info.item renames HW.NVM;
      EECD : constant Unsigned_32 := Er32 (Hw.all, Devices.e1000e.Registers.E1000_EECD);
      Size :          Unsigned_16;

   begin
      NVM.Opcode_Bits := 8;
      NVM.Delay_Usec  := 1;

      case NVM.Override
      is
         when E1000_NVM_Override_SPI_Large =>
            NVM.Page_Size    := 32;
            NVM.Address_Bits := 16;

         when E1000_NVM_Override_SPI_Small =>
            NVM.Page_Size    := 8;
            NVM.Address_Bits := 8;

         when others =>
            if (EECD and E1000_EECD_ADDR_BITS) /= 0
            then
               NVM.Page_Size    := 32;
               NVM.Address_Bits := 16;
            else
               NVM.Page_Size    := 8;
               NVM.Address_Bits := 8;
            end if;
      end case;

      NVM.NVM_Type := E1000_NVM_EEPROM_SPI;

      Size := Unsigned_16 (shift_Right (EECD and E1000_EECD_SIZE_EX_MASK,
                                        E1000_EECD_SIZE_EX_SHIFT));

      -- Added to a constant, "Size" becomes the left-shift value
      -- for setting Word_Size.
      --
      Size := Size + NVM_WORD_SIZE_BASE_SHIFT;

      -- EEPROM access above 16k is unsupported.
      --
      if Size > 14
      then
         Size := 14;
      end if;

      NVM.Word_Size := Shift_Left (1, Natural (Size));

      return 0;
   end E1000_Init_NVM_Params_80003es2lan;




   ---------------------------------------
   -- E1000_Init_Mac_Params_80003es2lan --
   ---------------------------------------

   --  Init ESB2 MAC func ptrs.
   --
   --  *  @hw: pointer to the HW structure


   function E1000_Init_Mac_Params_80003es2lan
     (Hw : access E1000_Hw) return s32
   is
      Mac : E1000_Mac_Info.item renames Hw.Mac;
   begin
      -- Set media type and media-dependent function pointers.
      --
      case Hw.Adapter.Pdev.Device
      is
         when E1000_DEV_ID_80003ES2LAN_SERDES_DPT =>
            Hw.Phy.Media_Type                := E1000_Media_Type_Internal_Serdes;
            Mac.Ops.Check_For_Link           := E1000e_Check_For_Serdes_Link  'Access;
            Mac.Ops.Setup_Physical_Interface := E1000e_Setup_Fiber_Serdes_Link'Access;
         when others =>
            Hw.Phy.Media_Type                := E1000_Media_Type_Copper;
            Mac.Ops.Check_For_Link           := E1000e_Check_For_Copper_Link       'Access;
            Mac.Ops.Setup_Physical_Interface := E1000_Setup_Copper_Link_80003es2lan'Access;
      end case;


      Mac.Mta_Reg_Count       := 128;                                    -- Set mta register count.
      Mac.Rar_Entry_Count     := E1000_RAR_ENTRIES;                      -- Set rar entry count.
      Mac.Has_Fwsm            := True;                                   -- FWSM register.
      Mac.Arc_Subsystem_Valid := (    Er32 (Hw.all, Devices.e1000e.Registers.E1000_FWSM)
                                  and E1000_FWSM_MODE_MASK) /= 0;        -- ARC supported; valid only if manageability features are enabled.
      Mac.Adaptive_Ifs        := False;                                  -- Adaptive IFS not supported.
      Hw.Mac.Ops.Set_Lan_Id (Hw);                                        -- Set lan id for port to determine which phy lock to use.

      return 0;
   end E1000_Init_Mac_Params_80003es2lan;




   ------------------------------------
   -- E1000_Get_Variants_80003es2lan --
   ------------------------------------

   function E1000_Get_Variants_80003es2lan
     (Adapter : access E1000_Adapter.item) return s32
   is
      HW : E1000_HW renames Adapter.HW;
      RC : s32;

   begin
      RC := E1000_Init_Mac_Params_80003es2lan (HW'Access);

      if RC /= 0
      then
         return RC;
      end if;

      RC := E1000_Init_Nvm_Params_80003es2lan (HW'Access);

      if RC /= 0
      then
         return RC;
      end if;

      RC := E1000_Init_Phy_Params_80003es2lan (HW'Access);

      if RC /= 0
      then
         return RC;
      end if;

      return 0;
   end E1000_Get_Variants_80003es2lan;



   -----------------------------------
   -- E1000_Acquire_Phy_80003es2lan --
   -----------------------------------

   --  Acquire rights to access PHY.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  A wrapper to acquire access rights to the correct PHY.

   function E1000_Acquire_Phy_80003es2lan
     (HW : access E1000_HW) return s32
   is
      Mask : Unsigned_16;
   begin
      if HW.Bus.Func /= 0
      then
         Mask := E1000_SWFW_PHY1_SM;
      else
         Mask := E1000_SWFW_PHY0_SM;
      end if;

      return E1000_Acquire_Swfw_Sync_80003es2lan (HW, Mask);
   end E1000_Acquire_Phy_80003es2lan;




   -----------------------------------
   -- E1000_Release_Phy_80003es2lan --
   -----------------------------------

   --  Release rights to access PHY.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  A wrapper to release access rights to the correct PHY.


   procedure E1000_Release_Phy_80003es2lan (HW : access E1000_HW)
   is
      Mask : Unsigned_16;

   begin
      if HW.Bus.Func /= 0
      then
         Mask := E1000_SWFW_PHY1_SM;
      else
         Mask := E1000_SWFW_PHY0_SM;
      end if;

      E1000_Release_Swfw_Sync_80003es2lan (HW, Mask);
   end E1000_Release_Phy_80003es2lan;




   ---------------------------------------
   -- E1000_Acquire_Mac_Csr_80003es2lan --
   ---------------------------------------

   --  Acquire right to access Kumeran register.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Acquire the semaphore to access the Kumeran interface.


   function E1000_Acquire_Mac_Csr_80003es2lan
     (HW : access E1000_HW) return s32
   is
      Mask : Unsigned_16;
   begin
      Mask := E1000_SWFW_CSR_SM;

      return E1000_Acquire_Swfw_Sync_80003es2lan (HW, Mask);
   end E1000_Acquire_Mac_Csr_80003es2lan;




   ---------------------------------------
   -- E1000_Release_Mac_Csr_80003es2lan --
   ---------------------------------------

   --  Release right to access Kumeran Register.
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Release the semaphore used to access the Kumeran interface


   procedure E1000_Release_Mac_Csr_80003es2lan
     (Hw : access E1000_Hw)
   is
      Mask : constant Unsigned_16 := E1000_SWFW_CSR_SM;
   begin
      E1000_Release_Swfw_Sync_80003es2lan (Hw, Mask);
   end E1000_Release_Mac_Csr_80003es2lan;




   -----------------------------------
   -- E1000_Acquire_Nvm_80003es2lan --
   -----------------------------------

   --  Acquire rights to access NVM.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Acquire the semaphore to access the EEPROM.


   function E1000_Acquire_Nvm_80003es2lan
     (Hw : access E1000_Hw) return s32
   is
      Ret_Val : s32;
   begin
      Ret_Val := E1000_Acquire_Swfw_Sync_80003es2lan (Hw, E1000_SWFW_EEP_SM);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;

      Ret_Val := E1000e_Acquire_Nvm (Hw);

      if Ret_Val /= 0
      then
         E1000_Release_Swfw_Sync_80003es2lan (Hw, E1000_SWFW_EEP_SM);
      end if;

      return Ret_Val;
   end E1000_Acquire_Nvm_80003es2lan;




   -----------------------------------
   -- E1000_Release_NVM_80003ES2LAN --
   -----------------------------------

   --  Relinquish rights to access NVM.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Release the semaphore used to access the EEPROM.


   procedure E1000_Release_NVM_80003ES2LAN
     (HW : access E1000_HW)
   is
   begin
      E1000E_Release_NVM (HW);
      E1000_Release_SWFW_Sync_80003ES2LAN (HW, E1000_SWFW_EEP_SM);
   end E1000_Release_NVM_80003ES2LAN;




   -----------------------------------------
   -- E1000_Acquire_SWFW_Sync_80003ES2LAN --
   -----------------------------------------

   --  Acquire SW/FW semaphore.
   --
   --  *  @hw:   Pointer to the HW structure.
   --  *  @mask: Specifies which semaphore to acquire.
   --  *
   --  *  Acquire the SW/FW semaphore to access the PHY or NVM.  The mask
   --  *  will also specify which port we're acquiring the lock for.


   function E1000_Acquire_SWFW_Sync_80003ES2LAN
     (HW : access E1000_HW; Mask : Unsigned_16) return s32
   is
      SWFW_Sync :          Unsigned_32;
      SW_Mask   : constant Unsigned_32 := Unsigned_32 (Mask);
      FW_Mask   : constant Unsigned_32 := shift_Left (Unsigned_32 (Mask), 16);
      I         :          Integer     := 0;
      Timeout   : constant Integer     := 50;

   begin
      while I < Timeout
      loop
         if E1000E_Get_HW_Semaphore (HW) = 0
         then
            return -E1000_ERR_SWFW_SYNC;
         end if;

         SWFW_Sync := ER32 (Hw.all, Devices.e1000e.Registers.E1000_SW_FW_SYNC);

         if (SWFW_Sync and (FW_Mask or SW_Mask)) = 0
         then
            exit;
         end if;

         -- Firmware currently using resource (FW_Mask)
         -- or other software thread using resource (SW_Mask).
         --
         E1000E_Put_HW_Semaphore (HW);
         delay 5.0 * 0.00_1;                  -- 5 milliseconds.

         I := I + 1;
      end loop;


      if I = Timeout
      then
         e_dbg ("Driver can't access resource, SW_FW_SYNC timeout.");
         return -E1000_ERR_SWFW_SYNC;
      end if;

      SWFW_Sync := SWFW_Sync or SW_Mask;
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_SW_FW_SYNC, SWFW_Sync);

      E1000E_Put_HW_Semaphore (HW);

      return 0;
   end E1000_Acquire_SWFW_Sync_80003ES2LAN;




   -----------------------------------------
   -- E1000_Release_SWFW_Sync_80003ES2LAN --
   -----------------------------------------

   --  Release SW/FW semaphore.
   --
   --  *  @hw:   Pointer to the HW structure.
   --  *  @mask: Specifies which semaphore to acquire.
   --  *
   --  *  Release the SW/FW semaphore used to access the PHY or NVM.  The mask
   --  *  will also specify which port we're releasing the lock for.


   procedure E1000_Release_SWFW_Sync_80003ES2LAN
     (HW   : access E1000_HW;
      Mask : in     Unsigned_16)
   is
      SWFW_Sync : Unsigned_32;
   begin
      loop
         exit when E1000E_Get_HW_Semaphore (HW) = 0;
      end loop;

      SWFW_Sync := ER32 (Hw.all, Devices.e1000e.Registers.E1000_SW_FW_SYNC);
      SWFW_Sync := SWFW_Sync and (not Unsigned_32 (Mask));
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_SW_FW_SYNC, SWFW_Sync);

      E1000E_Put_HW_Semaphore (HW);
   end E1000_Release_SWFW_Sync_80003ES2LAN;





   --------------------------------------------
   -- E1000_Read_PHY_Reg_GG82563_80003es2lan --
   --------------------------------------------

   --  Read GG82563 PHY register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Offset of the register to read.
   --  *  @data:   Pointer to the data returned from the operation.
   --  *
   --  *  Read the GG82563 PHY register.


   function E1000_Read_PHY_Reg_GG82563_80003es2lan
     (HW     : access E1000_HW;
      Offset :        Unsigned_32;
      Data   :        u16_Pointer) return s32
   is
      Ret_Val     :         s32;
      Page_Select :         Unsigned_32;
      Temp        : aliased Unsigned_16;

   begin
      Ret_Val := E1000_Acquire_PHY_80003es2lan (HW);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- Select Configuration Page.
      --
      if (Offset and MAX_PHY_REG_ADDRESS) < GG82563_MIN_ALT_REG
      then
         Page_Select := u32 (GG82563_PHY_PAGE_SELECT);
      else
         -- Use Alternative Page Select register to access registers 30 and 31.
         --
         Page_Select := u32 (GG82563_PHY_PAGE_SELECT_ALT);
      end if;

      Temp    := Unsigned_16 (Shift_Right (Offset, GG82563_PAGE_SHIFT));
      Ret_Val := E1000e_Write_PHY_Reg_MDIC (HW, Page_Select, Temp);

      if Ret_Val /= 0
      then
         E1000_Release_PHY_80003es2lan (HW);
         return Ret_Val;
      end if;


      if HW.Dev_Spec.E80003es2lan.MDIC_WA_Enable
      then
         -- The "ready" bit in the MDIC register may be incorrectly set
         -- before the device has completed the "Page Select" MDI
         -- transaction.  So we wait 200us after each MDI command ...
         --
         delay 300.0 * Microseconds;

         -- ...and verify the command was successful.
         --
         Ret_Val := E1000e_Read_PHY_Reg_MDIC (HW, Page_Select, Temp'unchecked_Access);

         if Unsigned_16 (shift_Right (Offset, GG82563_PAGE_SHIFT)) /= Temp
         then
            E1000_Release_PHY_80003es2lan (HW);
            return -E1000_ERR_PHY;
         end if;

         delay 300.0 * Microseconds;

         Ret_Val := E1000e_Read_PHY_Reg_MDIC (HW,
                                              MAX_PHY_REG_ADDRESS and Offset,
                                              Data);

         delay 300.0 * Microseconds;

      else
         Ret_Val := E1000e_Read_PHY_Reg_MDIC (HW,
                                              MAX_PHY_REG_ADDRESS and Offset,
                                              Data);
      end if;


      E1000_Release_PHY_80003es2lan (HW);

      return Ret_Val;
   end E1000_Read_PHY_Reg_GG82563_80003es2lan;




   ---------------------------------------------
   -- E1000_Write_PHY_Reg_GG82563_80003ES2LAN --
   ---------------------------------------------

   --  Write GG82563 PHY register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Offset of the register to read.
   --  *  @data:   Value to write to the register.
   --  *
   --  *  Write to the GG82563 PHY register.


   function E1000_Write_PHY_Reg_GG82563_80003ES2LAN
     (HW     : access E1000_HW;
      Offset :        Unsigned_32;
      Data   :        Unsigned_16) return s32
   is
      Ret_Val     :         s32;
      Page_Select :         Unsigned_32;
      Temp        : aliased Unsigned_16;

   begin
      Ret_Val := E1000_Acquire_PHY_80003ES2LAN (HW);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- Select Configuration Page.
      --
      if (Offset and MAX_PHY_REG_ADDRESS) < GG82563_MIN_ALT_REG
      then
         Page_Select := u32 (GG82563_PHY_PAGE_SELECT);
      else
         -- Use Alternative Page Select register to access registers 30 and 31.
         --
         Page_Select := u32 (GG82563_PHY_PAGE_SELECT_ALT);
      end if;

      Temp    := Unsigned_16 (Shift_Right (Offset, GG82563_PAGE_SHIFT));
      Ret_Val := E1000E_Write_PHY_Reg_MDIC (HW, Page_Select, Temp);

      if Ret_Val /= 0
      then
         E1000_Release_PHY_80003ES2LAN (HW);
         return Ret_Val;
      end if;


      if HW.Dev_Spec.E80003ES2LAN.MDIC_WA_Enable
      then
         -- The "ready" bit in the MDIC register may be incorrectly set
         -- before the device has completed the "Page Select" MDI
         -- transaction.  So we wait 200us after each MDI command ...
         --
         delay 300.0 * Microseconds;

         -- ...and verify the command was successful.
         --
         Ret_Val := E1000E_Read_PHY_Reg_MDIC (HW, Page_Select, Temp'unchecked_Access);

         if Unsigned_16 (shift_Right (Offset, GG82563_PAGE_SHIFT)) /= Temp
         then
            E1000_Release_PHY_80003ES2LAN (HW);
            return -E1000_ERR_PHY;
         end if;


         delay 300.0 * Microseconds;

         Ret_Val := E1000E_Write_PHY_Reg_MDIC (HW,
                                               MAX_PHY_REG_ADDRESS and Offset,
                                               Data);
         delay 300.0 * Microseconds;

      else
         Ret_Val := E1000E_Write_PHY_Reg_MDIC (HW,
                                               MAX_PHY_REG_ADDRESS and Offset,
                                               Data);
      end if;

      E1000_Release_PHY_80003ES2LAN (HW);

      return Ret_Val;
   end E1000_Write_PHY_Reg_GG82563_80003ES2LAN;



   ---------------------------------
   -- E1000_Write_NVM_80003es2lan --
   ---------------------------------

   --  Write to ESB2 NVM.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Offset of the register to read.
   --  *  @words:  Number of words to write.
   --  *  @data:   Buffer of data to write to the NVM.
   --  *
   --  *  Write "words" of data to the ESB2 NVM.


   function E1000_Write_NVM_80003es2lan
     (HW     : access E1000_HW;
      Offset : in     Unsigned_16;
      Words  : in     Unsigned_16;
      Data   : in     u16_Pointer) return s32
   is
   begin
      return E1000e_Write_NVM_SPI (HW, Offset, Words, Data);
   end E1000_Write_NVM_80003es2lan;




   ------------------------------------
   -- E1000_Get_Cfg_Done_80003es2lan --
   ------------------------------------

   --  Wait for configuration to complete.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Wait a specific amount of time for manageability processes to complete.
   --  *  This is a function pointer entry point called by the phy module.


   function E1000_Get_Cfg_Done_80003es2lan
     (Hw : access E1000_Hw) return s32
   is
      Timeout : Integer     := PHY_CFG_TIMEOUT;
      Mask    : Unsigned_32 := E1000_NVM_CFG_DONE_PORT_0;

   begin
      if Hw.Bus.Func = 1
      then
         Mask := E1000_NVM_CFG_DONE_PORT_1;
      end if;


      while Timeout > 0
      loop
         if (Er32 (Hw.all, Devices.e1000e.Registers.E1000_EEMNGCTL) and Mask) /= 0
         then
            exit;
         end if;

         delay 1_500.0 * Microseconds;  -- Equivalent to usleep_range(1000, 2000)

         Timeout := Timeout - 1;
      end loop;


      if Timeout = 0
      then
         e_dbg ("MNG configuration cycle has not completed.");
         return -E1000_ERR_RESET;
      end if;

      return 0;
   end E1000_Get_Cfg_Done_80003es2lan;




   ----------------------------------------------
   -- E1000_PHY_Force_Speed_Duplex_80003es2lan --
   ----------------------------------------------

   --  Force PHY speed and duplex.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Force the speed and duplex settings onto the PHY.  This is a
   --  *  function pointer entry point called by the phy module.


   function E1000_PHY_Force_Speed_Duplex_80003es2lan
     (HW : access E1000_HW) return s32
   is
      use Linux;

      Ret_Val  :         s32;
      PHY_Data : aliased Unsigned_16;
      Link     :         Boolean;

   begin
      -- Clear Auto-Crossover to force MDI manually. M88E1000 requires MDI
      -- forced whenever speed and duplex are forced.
      --
      Ret_Val := E1e_RPHY (HW, M88E1000_PHY_SPEC_CTRL, PHY_Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      PHY_Data := PHY_Data and (not GG82563_PSCR_CROSSOVER_MODE_AUTO);
      Ret_Val  := E1e_WPHY (HW, u32 (GG82563_PHY_SPEC_CTRL), PHY_Data);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      e_dbg ("GG82563 PSCR:" & PHY_Data'Image);

      Ret_Val := E1e_RPHY (HW, MII_BMCR, PHY_Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      E1000e_PHY_Force_Speed_Duplex_Setup (HW, PHY_Data'unchecked_Access);

      -- Reset the phy to commit changes.
      --
      PHY_Data := PHY_Data or BMCR_RESET;
      Ret_Val  := E1e_WPHY (HW, MII_BMCR, PHY_Data);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      delay 1.0 * Microseconds;       -- udelay (1) equivalent.

      if HW.PHY.Autoneg_Wait_To_Complete
      then
         e_dbg ("Waiting for forced speed/duplex link on GG82563 phy.");

         Ret_Val := E1000e_PHY_Has_Link_Generic (HW,
                                                 PHY_FORCE_LIMIT,
                                                 100_000,
                                                 Link);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         if not Link
         then
            -- We didn't get link.
            -- Reset the DSP and cross our fingers.
            --
            Ret_Val := E1000e_PHY_Reset_DSP (HW);

            if Ret_Val /= 0 then
               return Ret_Val;
            end if;
         end if;


         -- Try once more.
         --
         Ret_Val := E1000e_PHY_Has_Link_Generic (HW,
                                                 PHY_FORCE_LIMIT,
                                                 100_000,
                                                 Link);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;
      end if;


      Ret_Val := E1e_RPHY (HW,
                           u32 (GG82563_PHY_MAC_SPEC_CTRL),
                           PHY_Data'unchecked_Access);
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;

      -- Resetting the phy means we need to verify the TX_CLK corresponds
      -- to the link speed. 10Mbps -> 2.5MHz, else 25MHz.
      --
      PHY_Data := PHY_Data and (not GG82563_MSCR_TX_CLK_MASK);

      if (HW.MAC.Forced_Speed_Duplex and E1000_ALL_10_SPEED) /= 0
      then
         PHY_Data := PHY_Data or GG82563_MSCR_TX_CLK_10MBPS_2_5;
      else
         PHY_Data := PHY_Data or GG82563_MSCR_TX_CLK_100MBPS_25;
      end if;

      -- In addition, we must re-enable CRS on Tx for both half and full
      -- duplex.
      --
      PHY_Data := PHY_Data or GG82563_MSCR_ASSERT_CRS_ON_TX;
      Ret_Val  := E1e_WPHY (HW,
                            u32 (GG82563_PHY_MAC_SPEC_CTRL),
                            PHY_Data);

      return Ret_Val;
   end E1000_PHY_Force_Speed_Duplex_80003es2lan;




   ----------------------------------------
   -- E1000_Get_Cable_Length_80003es2lan --
   ----------------------------------------

   --  Set approximate cable length.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Find the approximate cable length as measured by the GG82563 PHY.
   --  *  This is a function pointer entry point called by the phy module.


   function E1000_Get_Cable_Length_80003es2lan
     (HW : access E1000_HW) return s32
   is
      PHY      :         E1000_PHY_Info.item renames HW.PHY;
      Ret_Val  :         s32;
      PHY_Data : aliased Unsigned_16;
      Index    :         Unsigned_16;

   begin
      Ret_Val := E1e_Rphy (HW, u32 (GG82563_PHY_DSP_DISTANCE), PHY_Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Index := PHY_Data and GG82563_DSPD_CABLE_LENGTH;

      if Index >= u16 (GG82563_CABLE_LENGTH_TABLE_SIZE) - 5
      then
         return -E1000_ERR_PHY;
      end if;


      PHY.Min_Cable_Length := E1000_GG82563_Cable_Length_Table (Integer (Index));
      PHY.Max_Cable_Length := E1000_GG82563_Cable_Length_Table (Integer (Index) + 5);
      PHY.Cable_Length     := (PHY.Min_Cable_Length + PHY.Max_Cable_Length) / 2;

      return 0;
   end E1000_Get_Cable_Length_80003es2lan;




   ----------------------------------------
   -- E1000_Get_Link_Up_Info_80003es2lan --
   ----------------------------------------

   --  Report speed and duplex.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @speed:  Pointer to speed buffer.
   --  *  @duplex: Pointer to duplex buffer.
   --  *
   --  *  Retrieve the current speed and duplex configuration.


   function E1000_Get_Link_Up_Info_80003es2lan
     (HW     : access E1000_HW;
      Speed  : in     u16_Pointer;
      Duplex : in     u16_Pointer) return s32
   is
      Ret_Val : s32;
      Unused  : s32;

   begin
      if HW.PHY.Media_Type = E1000_Media_Type_Copper
      then
         Ret_Val := E1000e_Get_Speed_And_Duplex_Copper (HW, Speed, Duplex);
         Unused  := HW.PHY.Ops.Cfg_On_Link_Up (HW);
      else
         Ret_Val := E1000e_Get_Speed_And_Duplex_Fiber_Serdes (HW, Speed, Duplex);
      end if;

      return Ret_Val;
   end E1000_Get_Link_Up_Info_80003es2lan;




   --------------------------------
   -- E1000_Reset_HW_80003ES2LAN --
   --------------------------------

   --  Reset the ESB2 controller.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Perform a global reset to the ESB2 controller.


   function E1000_Reset_HW_80003ES2LAN
     (HW : access E1000_HW) return s32
   is
      Ctrl         :         Unsigned_32;
      Ret_Val      :         s32;
      Kum_Reg_Data : aliased Unsigned_16;

   begin
      -- Prevent the PCI-E bus from sticking if there is no TLP connection
      -- on the last TLP read/write transaction when MAC is reset.
      --
      Ret_Val := E1000E_Disable_PCIE_Master (HW);

      if Ret_Val /= 0
      then
         e_dbg ("PCI-E Master disable polling has failed.");
      end if;

      e_dbg ("Masking off all interrupts");

      EW32 (Hw.all, Devices.e1000e.Registers.E1000_IMC, 16#ffffffff#);
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_RCTL, 0);
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_TCTL, E1000_TCTL_PSP);
      E1E_Flush (Hw);

      delay 10_500.0 * Microseconds;     -- Ada equivalent of usleep_range(10000, 11000)

      Ctrl    := ER32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);
      Ret_Val := E1000_Acquire_PHY_80003ES2LAN (HW);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;

      e_dbg ("Issuing a global reset to MAC");

      EW32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, Ctrl or E1000_CTRL_RST);
      E1000_Release_PHY_80003ES2LAN (HW);

      -- Disable IBIST slave mode (far-end loopback).
      --
      Ret_Val := E1000_Read_KMRN_Reg_80003ES2LAN (HW,
                                                  E1000_KMRNCTRLSTA_INBAND_PARAM,
                                                  Kum_Reg_Data'Unchecked_Access);
      if Ret_Val = 0
      then
         Kum_Reg_Data := Kum_Reg_Data or E1000_KMRNCTRLSTA_IBIST_DISABLE;
         Ret_Val      := E1000_Write_KMRN_Reg_80003ES2LAN (HW, E1000_KMRNCTRLSTA_INBAND_PARAM, Kum_Reg_Data);

         if Ret_Val /= 0
         then
            e_dbg ("Error disabling far-end loopback");
         end if;

      else
         e_dbg ("Error disabling far-end loopback");
      end if;


      Ret_Val := E1000E_Get_Auto_RD_Done (HW);

      if Ret_Val /= 0
      then
         -- We don't want to continue accessing MAC registers.
         --
         return Ret_Val;
      end if;


      -- Clear any pending interrupt events.
      --
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_IMC, 16#ffffffff#);

      declare
         Dummy : Interfaces.Unsigned_32;
      begin
         Dummy := ER32 (Hw.all, Devices.e1000e.Registers.E1000_ICR);
      end;

      return E1000_Check_Alt_Mac_Addr_Generic (HW);
   end E1000_Reset_HW_80003ES2LAN;




   -------------------------------
   -- E1000_Init_HW_80003ES2LAN --
   -------------------------------

   --  Initialize the ESB2 controller.
   --
   --  *  @hw: pointer to the HW structure
   --  *
   --  *  Initialize the hw bits, LED, VFTA, MTA, link and hw counters.


   function E1000_Init_HW_80003ES2LAN
     (HW : access E1000_HW) return s32
   is
      MAC          :         E1000_MAC_Info.item renames HW.MAC;
      Reg_Data     :         Unsigned_32;
      Ret_Val      :         s32;
      Kum_Reg_Data : aliased Unsigned_16;
      I            : aliased Unsigned_16;
   begin
      E1000_Initialize_HW_Bits_80003ES2LAN (HW);

      -- Initialize identification LED.
      --
      Ret_Val := MAC.Ops.Id_Led_Init (HW);

      -- An error is not fatal and we should not stop init due to this.
      --
      if Ret_Val /= 0
      then
         e_dbg ("Error initializing identification LED");
      end if;

      -- Disabling VLAN filtering.
      --
      e_dbg ("Initializing the IEEE VLAN");
      MAC.Ops.Clear_VFTA (HW);

      -- Setup the receive address.
      --
      E1000E_Init_RX_Addrs (HW, MAC.RAR_Entry_Count);

      -- Zero out the Multicast HASH table.
      --
      e_dbg ("Zeroing the MTA");

      for I in 0 .. u32 (MAC.MTA_Reg_Count) - 1
      loop
         E1000_Write_Reg_Array (HW, Devices.e1000e.Registers.E1000_MTA, I, 0);
      end loop;

      -- Setup link and flow control.
      --
      Ret_Val := MAC.Ops.Setup_Link (HW);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;

      -- Disable IBIST slave mode (far-end loopback).
      --
      Ret_Val := E1000_Read_KMRN_Reg_80003ES2LAN (HW,
                                                  E1000_KMRNCTRLSTA_INBAND_PARAM,
                                                  Kum_Reg_Data'unchecked_Access);

      if Ret_Val = 0
      then
         Kum_Reg_Data := Kum_Reg_Data or E1000_KMRNCTRLSTA_IBIST_DISABLE;
         Ret_Val      := E1000_Write_KMRN_Reg_80003ES2LAN (HW, E1000_KMRNCTRLSTA_INBAND_PARAM, Kum_Reg_Data);

         if Ret_Val /= 0
         then
            e_dbg ("Error disabling far-end loopback");
         end if;

      else
         e_dbg ("Error disabling far-end loopback");
      end if;

      -- Set the transmit descriptor write-back policy.
      --
      Reg_Data := ER32 (Hw.all, Devices.e1000e.Registers.E1000_TXDCTL (0));
      Reg_Data :=   (Reg_Data and not E1000_TXDCTL_WTHRESH)
                  or E1000_TXDCTL_FULL_TX_DESC_WB
                  or E1000_TXDCTL_COUNT_DESC;

      EW32 (Hw.all, Devices.e1000e.Registers.E1000_TXDCTL (0), Reg_Data);

      -- ... for both queues.
      --
      Reg_Data := ER32 (Hw.all, Devices.e1000e.Registers.E1000_TXDCTL (1));
      Reg_Data :=    (Reg_Data and not E1000_TXDCTL_WTHRESH)
                  or E1000_TXDCTL_FULL_TX_DESC_WB
                  or E1000_TXDCTL_COUNT_DESC;

      EW32 (Hw.all, Devices.e1000e.Registers.E1000_TXDCTL (1), Reg_Data);

      -- Enable retransmit on late collisions.
      --
      Reg_Data := ER32 (Hw.all, Devices.e1000e.Registers.E1000_TCTL);
      Reg_Data := Reg_Data or E1000_TCTL_RTLC;
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_TCTL, Reg_Data);

      -- Configure Gigabit Carry Extend Padding.
      --
      Reg_Data := ER32 (Hw.all, Devices.e1000e.Registers.E1000_TCTL_EXT);
      Reg_Data := Reg_Data and not E1000_TCTL_EXT_GCEX_MASK;
      Reg_Data := Reg_Data or DEFAULT_TCTL_EXT_GCEX_80003ES2LAN;
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_TCTL_EXT, Reg_Data);

      -- Configure Transmit Inter-Packet Gap.
      --
      Reg_Data := ER32 (Hw.all, Devices.e1000e.Registers.E1000_TIPG);
      Reg_Data := Reg_Data and not E1000_TIPG_IPGT_MASK;
      Reg_Data := Reg_Data or DEFAULT_TIPG_IPGT_1000_80003ES2LAN;
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_TIPG, Reg_Data);

      Reg_Data := E1000_Read_Reg_Array (HW, Devices.e1000e.Registers.E1000_FFLT, 1);
      Reg_Data := Reg_Data and not 16#00100000#;
      E1000_Write_Reg_Array (HW, Devices.e1000e.Registers.E1000_FFLT, 1, Reg_Data);

      -- Default to true to enable the MDIC W/A.
      --
      HW.Dev_Spec.E80003ES2LAN.MDIC_WA_Enable := True;

      Ret_Val := E1000_Read_KMRN_Reg_80003ES2LAN (HW,
                                                  Shift_Right (E1000_KMRNCTRLSTA_OFFSET, E1000_KMRNCTRLSTA_OFFSET_SHIFT),
                                                  I'unchecked_Access);
      if Ret_Val = 0
      then
         if (I and E1000_KMRNCTRLSTA_OPMODE_MASK) = E1000_KMRNCTRLSTA_OPMODE_INBAND_MDIO
         then
            HW.Dev_Spec.E80003ES2LAN.MDIC_WA_Enable := False;
         end if;
      end if;

      -- Clear all of the statistics registers (clear on read).  It is
      -- important that we do this after we have tried to establish link
      -- because the symbol error count will increment wildly if there
      -- is no link.
      --
      E1000_Clear_HW_Cntrs_80003ES2LAN (HW);

      return Ret_Val;
   end E1000_Init_HW_80003ES2LAN;




   ------------------------------------------
   -- E1000_Initialize_HW_Bits_80003es2lan --
   ------------------------------------------

   --  Init hw bits of ESB2.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Initializes required hardware-dependent bits needed for normal operation.


   procedure E1000_Initialize_HW_Bits_80003es2lan
     (HW : access E1000_HW)
   is
      Reg : Unsigned_32;

   begin
      -- Transmit Descriptor Control 0.
      --
      Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_TXDCTL (0));
      Reg := Reg or BIT (22);
      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_TXDCTL (0), Reg);

      -- Transmit Descriptor Control 1.
      --
      Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_TXDCTL (1));
      Reg := Reg or BIT (22);
      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_TXDCTL (1), Reg);

      -- Transmit Arbitration Control 0.
      --
      Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_TARC (0));
      Reg := Reg and not shift_Left (16#F#, 27);             -- 30:27

      if HW.Phy.Media_Type /= E1000_Media_Type_Copper
      then
         Reg := Reg and not BIT (20);
      end if;

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_TARC (0), Reg);

      -- Transmit Arbitration Control 1.
      --
      Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_TARC (1));

      if      (Er32 (Hw.all, Devices.e1000e.Registers.E1000_TCTL)
          and E1000_TCTL_MULR) /= 0
      then
         Reg := Reg and not BIT (28);
      else
         Reg := Reg or      BIT (28);
      end if;

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_TARC (1), Reg);

      -- Disable IPv6 extension header parsing because some malformed
      -- IPv6 headers can hang the Rx.
      --
      Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_RFCTL);
      Reg := Reg or (   E1000_RFCTL_IPV6_EX_DIS
                     or E1000_RFCTL_NEW_IPV6_EXT_DIS);

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_RFCTL, Reg);
   end E1000_Initialize_HW_Bits_80003es2lan;




   -------------------------------------------------
   -- E1000_Copper_Link_Setup_GG82563_80003es2lan --
   -------------------------------------------------

   --  Configure GG82563 Link.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Setup some GG82563 PHY registers for obtaining link


   function E1000_Copper_Link_Setup_GG82563_80003es2lan
     (HW : access E1000_HW) return s32
   is
      PHY     :         E1000_PHY_Info.item renames HW.PHY;
      Ret_Val :         s32;
      Reg     :         Unsigned_32;
      Data    : aliased Unsigned_16;

   begin
      Ret_Val := E1e_Rphy (HW,
                           u32 (GG82563_PHY_MAC_SPEC_CTRL),
                           Data'unchecked_Access);
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Data := Data or GG82563_MSCR_ASSERT_CRS_ON_TX;
      Data := Data or GG82563_MSCR_TX_CLK_1000MBPS_25;      -- Use 25MHz for both link down and 1000Base-T for Tx clock.

      Ret_Val := E1e_Wphy (HW,
                           u32 (GG82563_PHY_MAC_SPEC_CTRL),
                           Data);
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- Options:
      --
      --   MDI/MDI-X = 0 (default)
      --   0 - Auto for all speeds
      --   1 - MDI mode
      --   2 - MDI-X mode
      --   3 - Auto for 1000Base-T only (MDI-X for 10/100Base-T modes)
      --
      Ret_Val := E1e_Rphy (HW,
                           u32 (GG82563_PHY_SPEC_CTRL),
                           Data'unchecked_Access);
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Data := Data and (not GG82563_PSCR_CROSSOVER_MODE_MASK);

      case PHY.Mdix
      is
         when 1      =>   Data := Data or GG82563_PSCR_CROSSOVER_MODE_MDI;
         when 2      =>   Data := Data or GG82563_PSCR_CROSSOVER_MODE_MDIX;
         when others =>   Data := Data or GG82563_PSCR_CROSSOVER_MODE_AUTO;
      end case;

      -- Options:
      --
      --   disable_polarity_correction = 0 (default)
      --       Automatic Correction for Reversed Cable Polarity
      --   0 - Disabled
      --   1 - Enabled
      --
      Data := Data and (not GG82563_PSCR_POLARITY_REVERSAL_DISABLE);

      if PHY.Disable_Polarity_Correction
      then
         Data := Data or GG82563_PSCR_POLARITY_REVERSAL_DISABLE;
      end if;

      Ret_Val := E1e_Wphy (HW,
                           u32 (GG82563_PHY_SPEC_CTRL),
                           Data);
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- SW Reset the PHY so all changes take effect.
      --
      Ret_Val := HW.PHY.Ops.Commit (HW);

      if Ret_Val /= 0
      then
         e_dbg ("Error Resetting the PHY");
         return Ret_Val;
      end if;


      -- Bypass Rx and Tx FIFO's.
      --
      Reg     := E1000_KMRNCTRLSTA_OFFSET_FIFO_CTRL;
      Data    :=    E1000_KMRNCTRLSTA_FIFO_CTRL_RX_BYPASS
                 or E1000_KMRNCTRLSTA_FIFO_CTRL_TX_BYPASS;
      Ret_Val := E1000_Write_Kmrn_Reg_80003es2lan (HW, Reg, Data);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Reg     := E1000_KMRNCTRLSTA_OFFSET_MAC2PHY_OPMODE;
      Ret_Val := E1000_Read_Kmrn_Reg_80003es2lan (HW, Reg, Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Data := Data or E1000_KMRNCTRLSTA_OPMODE_E_IDLE;

      Ret_Val := E1000_Write_Kmrn_Reg_80003es2lan (HW, Reg, Data);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Ret_Val := E1e_Rphy (HW,
                           u32 (GG82563_PHY_SPEC_CTRL_2),
                           Data'unchecked_Access);
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Data    := Data and (not GG82563_PSCR2_REVERSE_AUTO_NEG);
      Ret_Val := E1e_Wphy (HW,
                           u32 (GG82563_PHY_SPEC_CTRL_2),
                           Data);
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT);
      Reg := Reg and (not E1000_CTRL_EXT_LINK_MODE_MASK);
      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT, Reg);

      Ret_Val := E1e_Rphy (HW,
                           u32 (GG82563_PHY_PWR_MGMT_CTRL),
                           Data'unchecked_Access);
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- Do not init these registers when the HW is in IAMT mode, since the
      -- firmware will have already initialized them.  We only initialize
      -- them if the HW is not in IAMT mode.
      --
      if not HW.Mac.Ops.Check_Mng_Mode (HW)
      then
         -- Enable Electrical Idle on the PHY.
         --
         Data    := Data or GG82563_PMCR_ENABLE_ELECTRICAL_IDLE;
         Ret_Val := E1e_Wphy (HW,
                              u32 (GG82563_PHY_PWR_MGMT_CTRL),
                              Data);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Ret_Val := E1e_Rphy (HW,
                              u32 (GG82563_PHY_KMRN_MODE_CTRL),
                              Data'unchecked_Access);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Data    := Data and (not GG82563_KMCR_PASS_FALSE_CARRIER);
         Ret_Val := E1e_Wphy (HW,
                              u32 (GG82563_PHY_KMRN_MODE_CTRL),
                              Data);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;
      end if;


      -- Workaround: Disable padding in Kumeran interface in the MAC
      -- and in the PHY to avoid CRC errors.
      --
      Ret_Val := E1e_Rphy (HW,
                           u32 (GG82563_PHY_INBAND_CTRL),
                           Data'unchecked_Access);
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Data    := Data or GG82563_ICR_DIS_PADDING;
      Ret_Val := E1e_Wphy (HW,
                           u32 (GG82563_PHY_INBAND_CTRL),
                           Data);
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;

      return 0;
   end E1000_Copper_Link_Setup_GG82563_80003es2lan;




   -----------------------------------------
   -- E1000_Setup_Copper_Link_80003es2lan --
   -----------------------------------------

   --  Setup Copper Link for ESB2.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Essentially a wrapper for setting up all things "copper" related.
   --  *  This is a function pointer entry point called by the mac module.


   function E1000_Setup_Copper_Link_80003es2lan
     (Hw : access E1000_Hw) return s32
   is
      Ctrl     :         Unsigned_32;
      Ret_Val  :         s32;
      Reg_Data : aliased Unsigned_16;

   begin
      Ctrl := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);
      Ctrl := Ctrl or E1000_CTRL_SLU;
      Ctrl := Ctrl and (not (E1000_CTRL_FRCSPD or E1000_CTRL_FRCDPX));

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, Ctrl);

      -- Set the mac to wait the maximum time between each
      -- iteration and increase the max iterations when
      -- polling the phy; this fixes erroneous timeouts at 10Mbps.

      -- These next three accesses were always meant to use page 0x34 using
      -- GG82563_REG(0x34, N) but never did, so we've just corrected the call
      -- to not drop bits.

      Ret_Val := E1000_Write_Kmrn_Reg_80003es2lan (Hw, 4, 16#FFFF#);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Ret_Val := E1000_Read_Kmrn_Reg_80003es2lan (Hw, 9, Reg_Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Reg_Data := Reg_Data or 16#3F#;
      Ret_Val  := E1000_Write_Kmrn_Reg_80003es2lan (Hw, 9, Reg_Data);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Ret_Val := E1000_Read_Kmrn_Reg_80003es2lan (Hw,
                                                  E1000_KMRNCTRLSTA_OFFSET_INB_CTRL,
                                                  Reg_Data'unchecked_Access);
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;

      Reg_Data := Reg_Data or E1000_KMRNCTRLSTA_INB_CTRL_DIS_PADDING;
      Ret_Val  := E1000_Write_Kmrn_Reg_80003es2lan (Hw,
                                                    E1000_KMRNCTRLSTA_OFFSET_INB_CTRL,
                                                    Reg_Data);
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Ret_Val := E1000_Copper_Link_Setup_Gg82563_80003es2lan (Hw);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      return E1000e_Setup_Copper_Link (Hw);
   end E1000_Setup_Copper_Link_80003es2lan;





   --------------------------------------
   -- E1000_Cfg_On_Link_Up_80003es2lan --
   --------------------------------------

   --  es2 link configuration after link-up.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Configure the KMRN interface by applying last minute quirks for
   --  *  10/100 operation.


   function E1000_Cfg_On_Link_Up_80003es2lan
     (Hw : access E1000_Hw) return s32
   is
      Ret_Val : s32        := 0;
      Speed   : aliased Unsigned_16;
      Duplex  : aliased Unsigned_16;

   begin
      if Hw.Phy.Media_Type = E1000_Media_Type_Copper
      then
         Ret_Val := E1000e_Get_Speed_And_Duplex_Copper (Hw,
                                                        Speed 'unchecked_Access,
                                                        Duplex'unchecked_Access);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         if Speed = linux.SPEED_1000
         then
            Ret_Val := E1000_Cfg_Kmrn_1000_80003es2lan (Hw);
         else
            Ret_Val := E1000_Cfg_Kmrn_10_100_80003es2lan (Hw, Duplex);
         end if;
      end if;


      return Ret_Val;
   end E1000_Cfg_On_Link_Up_80003es2lan;




   ---------------------------------------
   -- E1000_Cfg_Kmrn_10_100_80003es2lan --
   ---------------------------------------

   --  Apply "quirks" for 10/100 operation.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @duplex: Current duplex setting.
   --  *
   --  *  Configure the KMRN interface by applying last minute quirks for
   --  *  10/100 operation.


   function E1000_Cfg_Kmrn_10_100_80003es2lan
     (Hw     : access E1000_Hw;
      Duplex : in     Unsigned_16) return s32
   is
      Ret_Val   :         s32;
      Tipg      :         Unsigned_32;
      I         :         Natural := 0;
      Reg_Data,
      Reg_Data2 : aliased Unsigned_16;

   begin
      Reg_Data := E1000_KMRNCTRLSTA_HD_CTRL_10_100_DEFAULT;
      Ret_Val  := E1000_Write_Kmrn_Reg_80003es2lan (Hw, E1000_KMRNCTRLSTA_OFFSET_HD_CTRL, Reg_Data);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;

      -- Configure Transmit Inter-Packet Gap.
      --
      Tipg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_TIPG);
      Tipg := Tipg and (not E1000_TIPG_IPGT_MASK);
      Tipg := Tipg or DEFAULT_TIPG_IPGT_10_100_80003ES2LAN;

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_TIPG, Tipg);

      loop
         Ret_Val := E1e_Rphy (Hw,
                              u32 (GG82563_PHY_KMRN_MODE_CTRL),
                              Reg_Data'unchecked_Access);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;

         Ret_Val := E1e_Rphy (Hw,
                              u32 (GG82563_PHY_KMRN_MODE_CTRL),
                              Reg_Data2'unchecked_Access);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;

         I := I + 1;
         exit when Reg_Data = Reg_Data2 or I >= GG82563_MAX_KMRN_RETRY;
      end loop;


      if Duplex = HALF_DUPLEX
      then
         Reg_Data := Reg_Data or       GG82563_KMCR_PASS_FALSE_CARRIER;
      else
         Reg_Data := Reg_Data and (not GG82563_KMCR_PASS_FALSE_CARRIER);
      end if;

      return E1e_Wphy (Hw,
                       u32 (GG82563_PHY_KMRN_MODE_CTRL),
                       Reg_Data);
   end E1000_Cfg_Kmrn_10_100_80003es2lan;




   -------------------------------------
   -- E1000_Cfg_Kmrn_1000_80003es2lan --
   -------------------------------------

   --  Apply "quirks" for gigabit operation.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Configure the KMRN interface by applying last minute quirks for
   --  *  gigabit operation.


   function E1000_Cfg_Kmrn_1000_80003es2lan
     (Hw : access E1000_Hw) return s32
   is
      Ret_Val   :         s32;
      Reg_Data,
      Reg_Data2 : aliased Unsigned_16;
      Tipg      :         Unsigned_32;
      I         :         Natural    := 0;

   begin
      Reg_Data := E1000_KMRNCTRLSTA_HD_CTRL_1000_DEFAULT;
      Ret_Val  := E1000_Write_Kmrn_Reg_80003es2lan (Hw,
                                                   E1000_KMRNCTRLSTA_OFFSET_HD_CTRL,
                                                   Reg_Data);
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- Configure Transmit Inter-Packet Gap.
      --
      Tipg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_TIPG);
      Tipg := Tipg and (not E1000_TIPG_IPGT_MASK);
      Tipg := Tipg or DEFAULT_TIPG_IPGT_1000_80003ES2LAN;

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_TIPG, Tipg);


      loop
         Ret_Val := E1e_Rphy (Hw,
                              u32 (GG82563_PHY_KMRN_MODE_CTRL),
                              Reg_Data'unchecked_Access);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;

         Ret_Val := E1e_Rphy (Hw,
                              u32 (GG82563_PHY_KMRN_MODE_CTRL),
                              Reg_Data2'unchecked_Access);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         I := I + 1;
         exit when    Reg_Data = Reg_Data2
                   or I >= GG82563_MAX_KMRN_RETRY;
      end loop;


      Reg_Data := Reg_Data and (not GG82563_KMCR_PASS_FALSE_CARRIER);

      return E1e_Wphy (Hw,
                       u32 (GG82563_PHY_KMRN_MODE_CTRL),
                       Reg_Data);
   end E1000_Cfg_Kmrn_1000_80003es2lan;





   -------------------------------------
   -- E1000_Read_Kmrn_Reg_80003es2lan --
   -------------------------------------

   --  Read kumeran register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to be read.
   --  *  @data:   Pointer to the read data.
   --  *
   --  *  Acquire semaphore, then read the PHY register at offset
   --  *  using the kumeran interface.  The information retrieved is stored in data.
   --  *  Release the semaphore before exiting.


   function E1000_Read_Kmrn_Reg_80003es2lan
     (Hw     : access E1000_Hw;
      Offset : in     Unsigned_32;
      Data   : in     u16_Pointer) return s32
   is
      use Linux;

      Kmrnctrlsta : Unsigned_32;
      Ret_Val     : s32;

   begin
      Ret_Val := E1000_Acquire_Mac_Csr_80003es2lan (Hw);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Kmrnctrlsta :=    FIELD_PREP (E1000_KMRNCTRLSTA_OFFSET, Offset)
                     or E1000_KMRNCTRLSTA_REN;

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_KMRNCTRLSTA, Kmrnctrlsta);
      E1E_Flush (Hw);

      delay 2.0 * Microseconds;      -- 2 microseconds.

      Kmrnctrlsta := Er32 (Hw.all, Devices.e1000e.Registers.E1000_KMRNCTRLSTA);
      Data.all    := u16 (Kmrnctrlsta);

      E1000_Release_Mac_Csr_80003es2lan (Hw);

      return Ret_Val;
   end E1000_Read_Kmrn_Reg_80003es2lan;




   --------------------------------------
   -- E1000_Write_Kmrn_Reg_80003es2lan --
   --------------------------------------

   --  Write kumeran register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to write to.
   --  *  @data:   Data to write at register offset.
   --  *
   --  *  Acquire semaphore, then write the data to PHY register
   --  *  at the offset using the kumeran interface.  Release semaphore
   --  *  before exiting.


   function E1000_Write_Kmrn_Reg_80003es2lan
     (Hw     : access E1000_Hw;
      Offset : in     Unsigned_32;
      Data   : in     Unsigned_16) return s32
   is
      use Linux;

      Kmrnctrlsta : Unsigned_32;
      Ret_Val     : s32;

   begin
      Ret_Val := E1000_Acquire_Mac_Csr_80003es2lan (Hw);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Kmrnctrlsta :=    FIELD_PREP (E1000_KMRNCTRLSTA_OFFSET, Offset)
                     or u32 (Data);

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_KMRNCTRLSTA, Kmrnctrlsta);
      E1E_Flush (Hw);

      delay 2.0 * Microseconds;

      E1000_Release_Mac_Csr_80003es2lan (Hw);

      return Ret_Val;
   end E1000_Write_Kmrn_Reg_80003es2lan;




   -------------------------------------
   -- E1000_Read_Mac_Addr_80003es2lan --
   -------------------------------------

   --  Read device MAC address.
   --
   --  *  @hw: Pointer to the HW structure.


   function E1000_Read_Mac_Addr_80003es2lan
     (HW : access E1000_HW) return s32
   is
      Ret_Val : s32;
   begin
      -- If there's an alternate MAC address place it in RAR0
      -- so that it will override the Si installed default perm
      -- address.
      --
      Ret_Val := E1000_Check_Alt_Mac_Addr_Generic (HW);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      return E1000_Read_Mac_Addr_Generic(HW);
   end E1000_Read_Mac_Addr_80003es2lan;




   ---------------------------------------------
   -- E1000_Power_Down_PHY_Copper_80003es2lan --
   ---------------------------------------------

   --  Remove link during PHY power down.
   --
   --  * @hw: Pointer to the HW structure.
   --  *
   --  * In the case of a PHY power down to save power, or to turn off link during a
   --  * driver unload, or wake on lan is not enabled, remove the link.


   procedure E1000_Power_Down_PHY_Copper_80003es2lan
     (HW : access E1000_HW)
   is
   begin
      -- If the management interface is not enabled, then power down.
      --
      if not (   HW.Mac.Ops.Check_Mng_Mode    (HW)
              or HW.Phy.Ops.Check_Reset_Block (HW) /= 0)
      then
         E1000_Power_Down_PHY_Copper (HW);
      end if;
   end E1000_Power_Down_PHY_Copper_80003es2lan;




   --------------------------------------
   -- E1000_Clear_Hw_Cntrs_80003es2lan --
   --------------------------------------

   --  Clear device specific hardware counters.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Clears the hardware counters by reading the counter registers.


   procedure E1000_Clear_Hw_Cntrs_80003es2lan
     (HW : access E1000_HW)
   is
      Unused : u32;
   begin
      E1000e_Clear_Hw_Cntrs_Base (HW);

      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_PRC64);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_PRC127);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_PRC255);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_PRC511);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_PRC1023);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_PRC1522);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_PTC64);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_PTC127);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_PTC255);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_PTC511);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_PTC1023);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_PTC1522);

      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_ALGNERRC);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_RXERRC);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_TNCRS);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CEXTERR);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_TSCTC);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_TSCTFC);

      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_MGTPRC);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_MGTPDC);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_MGTPTC);

      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_IAC);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_ICRXOC);

      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_ICRXPTC);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_ICRXATC);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_ICTXPTC);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_ICTXATC);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_ICTXQEC);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_ICTXQMTC);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_ICRXDMTC);
   end E1000_Clear_Hw_Cntrs_80003es2lan;



end Devices.e1000e.an_80003es2lan;
