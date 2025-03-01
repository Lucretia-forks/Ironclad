with
     Devices.e1000e.Base.Port,
     Devices.e1000e.Defines,
     Devices.e1000e.Registers,
     Devices.e1000e.Physical_Layer,
     Devices.e1000e.Hardware.E1000_Mac_Info,
     Devices.e1000e.Hardware.E1000_Bus_Info,
     Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32,
     Linux;


package body Devices.e1000e.Media_Access_Control
is
   use Devices.e1000e.Core,
       Devices.e1000e.Core.Pointers,
       Devices.e1000e.Defines,
       Devices.e1000e.Hardware,
       Devices.e1000e.Base,
       Devices.e1000e.Base.Port,
       Devices.e1000e.Physical_Layer,
       Linux,
       Interfaces;



   ------------------------
   -- E1000_Hash_MC_Addr --
   ------------------------

   --  Generate a multicast hash value.
   --
   --  *  @hw:      Pointer to the HW structure.
   --  *  @mc_addr: Pointer to a multicast address.
   --  *
   --  *  Generates a multicast address hash value which is used to determine
   --  *  the multicast filter table array address and new table value.


   function E1000_Hash_MC_Addr
     (HW      : access E1000_HW;
      MC_Addr : in     u8_Pointer) return u32
   is
      Hash_Value,
      Hash_Mask  : Unsigned_32;
      Bit_Shift  : Natural    := 0;

      MC_Address : u8_array (0 .. 5)
        with
          Address => MC_Addr.all'Address;

   begin
      -- Register count multiplied by bits per register.
      --
      Hash_Mask := u32 (HW.Mac.MTA_Reg_Count * 32) - 1;

      -- For a mc_filter_type of 0, bit_shift is the number of left-shifts
      -- where 0xFF would still fall within the hash mask.
      --
      while shift_Right (Hash_Mask, Bit_Shift) /= 16#FF#
      loop
         Bit_Shift := Bit_Shift + 1;
      end loop;

      --  The portion of the address that is used for the hash table
      --  is determined by the mc_filter_type setting.
      --  The algorithm is such that there is a total of 8 bits of shifting.
      --  The bit_shift for a mc_filter_type of 0 represents the number of
      --  left-shifts where the MSB of mc_addr[5] would still fall within
      --  the hash_mask.  Case 0 does this exactly.  Since there are a total
      --  of 8 bits of shifting, then mc_addr[4] will shift right the
      --  remaining number of bits. Thus 8 - bit_shift.  The rest of the
      --  cases are a variation of this algorithm...essentially raising the
      --  number of bits to shift mc_addr[5] left, while still keeping the
      --  8-bit shifting total.
      --
      --  For example, given the following Destination MAC Address and an
      --  mta register count of 128 (thus a 4096-bit vector and 0xFFF mask),
      --  we can see that the bit_shift for case 0 is 4.  These are the hash
      --  values resulting from each mc_filter_type...
      --  [0] [1] [2] [3] [4] [5]
      --  01  AA  00  12  34  56
      --  LSB           MSB
      --
      --  case 0: hash_value = ((0x34 >> 4) | (0x56 << 4)) & 0xFFF = 0x563
      --  case 1: hash_value = ((0x34 >> 3) | (0x56 << 5)) & 0xFFF = 0xAC6
      --  case 2: hash_value = ((0x34 >> 2) | (0x56 << 6)) & 0xFFF = 0x163
      --  case 3: hash_value = ((0x34 >> 0) | (0x56 << 8)) & 0xFFF = 0x634
      --
      case HW.Mac.MC_Filter_Type
      is
         when 0      => null;
         when 1      => Bit_Shift := Bit_Shift + 1;
         when 2      => Bit_Shift := Bit_Shift + 2;
         when 3      => Bit_Shift := Bit_Shift + 4;
         when others => null;
      end case;

      Hash_Value := Hash_Mask
        and (   shift_Right (Unsigned_32 (MC_Address (4)), 8 - Bit_Shift)
             or shift_Left  (Unsigned_32 (MC_Address (5)),     Bit_Shift));

      return Hash_Value;
   end E1000_Hash_MC_Addr;





   ----------------------------------
   -- E1000_Set_Default_FC_Generic --
   ----------------------------------

   --  Set flow control default values.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Read the EEPROM for the default values for flow control and store the
   --  *  values.


   function E1000_Set_Default_FC_Generic
     (HW : access E1000_HW) return s32
   is
      Ret_Val  :         s32;
      NVM_Data : aliased Unsigned_16;
   begin
      -- Read and store word 0x0F of the EEPROM. This word contains bits
      -- that determine the hardware's default PAUSE (flow control) mode,
      -- a bit that determines whether the HW defaults to enabling or
      -- disabling auto-negotiation, and the direction of the
      -- SW defined pins. If there is no SW over-ride of the flow
      -- control setting, then the variable hw.fc will
      -- be initialized based on a value in the EEPROM.
      --
      Ret_Val := E1000_Read_NVM (HW,
                                 NVM_INIT_CONTROL2_REG,
                                 1,
                                 NVM_Data'unchecked_Access);
      if Ret_Val /= 0
      then
         e_dbg ("NVM Read Error");
         return Ret_Val;
      end if;


      if (NVM_Data and NVM_WORD0F_PAUSE_MASK) = 0
      then
         HW.FC.Requested_Mode := E1000_FC_None;

      elsif (NVM_Data and NVM_WORD0F_PAUSE_MASK) = NVM_WORD0F_ASM_DIR
      then
         HW.FC.Requested_Mode := E1000_FC_TX_Pause;

      else
         HW.FC.Requested_Mode := E1000_FC_Full;
      end if;


      return 0;
   end E1000_Set_Default_FC_Generic;




   --------------------------------------
   -- E1000_Commit_FC_Settings_Generic --
   --------------------------------------

   --  Configure flow control.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Write the flow control settings to the Transmit Config Word Register (TXCW)
   --  *  base on the flow control settings in e1000_mac_info.


   function E1000_Commit_FC_Settings_Generic
     (HW : access E1000_HW) return s32
   is
      Mac  : E1000_Mac_Info.item renames HW.Mac;
      TXCW : Unsigned_32;

   begin
      -- Check for a software override of the flow control settings, and
      -- setup the device accordingly. If auto-negotiation is enabled, then
      -- software will have to set the "PAUSE" bits to the correct value in
      -- the Transmit Config Word Register (TXCW) and re-start auto-
      -- negotiation. However, if auto-negotiation is disabled, then
      -- software will have to manually configure the two flow control enable
      -- bits in the CTRL register.
      --
      -- The possible values of the "fc" parameter are:
      --      0:  Flow control is completely disabled
      --      1:  Rx flow control is enabled (we can receive pause frames,
      --          but not send pause frames).
      --      2:  Tx flow control is enabled (we can send pause frames but we
      --          do not support receiving pause frames).
      --      3:  Both Rx and Tx flow control (symmetric) are enabled.

      case HW.FC.Current_Mode
      is
         when E1000_FC_None =>
            -- Flow control completely disabled by a software over-ride.
            --
            TXCW := E1000_TXCW_ANE or E1000_TXCW_FD;

         when E1000_FC_RX_Pause =>
            -- Rx Flow control is enabled and Tx Flow control is disabled
            -- by a software over-ride. Since there really isn't a way to
            -- advertise that we are capable of Rx Pause ONLY, we will
            -- advertise that we support both symmetric and asymmetric Rx
            -- PAUSE. Later, we will disable the adapter's ability to send
            -- PAUSE frames.
            --
            TXCW := E1000_TXCW_ANE or E1000_TXCW_FD or E1000_TXCW_PAUSE_MASK;

         when E1000_FC_TX_Pause =>
            -- Tx Flow control is enabled, and Rx Flow control is disabled,
            -- by a software over-ride.
            --
            TXCW := E1000_TXCW_ANE or E1000_TXCW_FD or E1000_TXCW_ASM_DIR;

         when E1000_FC_Full =>
            -- Flow control (both Rx and Tx) is enabled by a software
            -- over-ride.
            --
            TXCW := E1000_TXCW_ANE or E1000_TXCW_FD or E1000_TXCW_PAUSE_MASK;

         when others =>
            e_dbg ("Flow control param set incorrectly");
            return -E1000_ERR_CONFIG;
      end case;


      EW32 (Hw.all, Devices.e1000e.Registers.E1000_TXCW, TXCW);
      Mac.TXCW := TXCW;

      return 0;
   end E1000_Commit_FC_Settings_Generic;




   ------------------------------------
   -- Poll_Fiber_Serdes_Link_Generic --
   ------------------------------------

   --  Poll for link up.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Polls for link up by reading the status register, if link fails to come
   --  *  up with auto-negotiation, then the link is forced if a signal is detected.


   function E1000_Poll_Fiber_Serdes_Link_Generic
     (HW : access e1000_hw) return s32
   is
      Mac     : e1000_mac_info.item renames HW.Mac;
      Status  : Unsigned_32;
      i       : u32        := 0;
      Ret_Val : s32;

   begin
      -- If we have a signal (the cable is plugged in, or assumed true for
      -- serdes media) then poll for a "Link-Up" indication in the Device
      -- Status Register. Time-out if a link isn't seen in 500 milliseconds
      -- seconds (Auto-negotiation should complete in less than 500
      -- milliseconds even if the other end is doing it in SW).
      --
      while i < FIBER_LINK_UP_LIMIT
      loop
         delay 10_500.0 * Microseconds;     -- Equivalent to usleep_range(10000, 11000)
         Status := Er32 (Hw.all, Devices.e1000e.Registers.E1000_STATUS);

         if (Status and E1000_STATUS_LU) /= 0
         then
            exit;
         end if;

         i := i + 1;
      end loop;


      if I = FIBER_LINK_UP_LIMIT
      then
         e_dbg ("Never got a valid link from auto-neg!!!");
         Mac.Autoneg_Failed := True;

         -- AutoNeg failed to achieve a link, so we'll call
         -- mac.check_for_link. This routine will force the
         -- link up if we detect a signal. This will allow us to
         -- communicate with non-autonegotiating link partners.
         --
         Ret_Val := Mac.Ops.Check_For_Link (HW);

         if Ret_Val /= 0
         then
            e_dbg ("Error while checking for link");
            return Ret_Val;
         end if;

         Mac.Autoneg_Failed := False;

      else
         Mac.Autoneg_Failed := False;
         e_dbg ("Valid Link Found");
      end if;


      return 0;
   end E1000_Poll_Fiber_Serdes_Link_Generic;




   ------------------------------
   -- E1000e_Valid_Led_Default --
   ------------------------------

   --  Verify a valid default LED config.
   --
   --  *  @hw:   Pointer to the HW structure.
   --  *  @data: Pointer to the NVM (EEPROM).
   --  *
   --  *  Read the EEPROM for the current default LED configuration.  If the
   --  *  LED configuration is not valid, set to a valid LED configuration.

   function E1000e_Valid_Led_Default
     (Hw   : access E1000_Hw;
      Data : in     u16_Pointer) return s32
   is
      Ret_Val : s32;

   begin
      Ret_Val := E1000_Read_Nvm (Hw, NVM_ID_LED_SETTINGS, 1, Data);

      if Ret_Val /= 0
      then
         e_dbg ("NVM Read Error");
         return Ret_Val;
      end if;

      if   Data.all = ID_LED_RESERVED_0000
        or Data.all = ID_LED_RESERVED_FFFF
      then
         Data.all := u16 (ID_LED_DEFAULT);
      end if;

      return 0;
   end E1000e_Valid_Led_Default;





   -----------------------------------------------------------------------------------
   --                               Public Subprograms                              --
   -----------------------------------------------------------------------------------


   ------------------------------
   -- E1000e_Blink_Led_Generic --
   ------------------------------

   --    Blink LED.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Blink the LEDs which are set to be on.


   function E1000e_Blink_Led_Generic
     (HW : access E1000_HW) return s32
   is
      Ledctl_Blink : Unsigned_32 := 0;
      i            : Natural     := 0;

   begin
      if HW.Phy.Media_Type = E1000_Media_Type_Fiber
      then
         -- Always blink LED0 for PCI-E fiber.
         --
         Ledctl_Blink :=    E1000_LEDCTL_LED0_BLINK
           or shift_Left (E1000_LEDCTL_MODE_LED_ON,
                          E1000_LEDCTL_LED0_MODE_SHIFT);
      else
         -- Set the blink bit for each LED that's "on" (0x0E)
         -- (or "off" if inverted) in ledctl_mode2.  The blink
         -- logic in hardware only works when mode is set to "on"
         -- so it must be changed accordingly when the mode is
         -- "off" and inverted.
         --
         Ledctl_Blink := HW.Mac.Ledctl_Mode2;

         while i < 32
         loop
            declare
               Mode        : constant Unsigned_32 :=     shift_Right (HW.Mac.Ledctl_Mode2, i)
                 and E1000_LEDCTL_LED0_MODE_MASK;
               Led_Default : constant Unsigned_32 :=     shift_Right (HW.Mac.Ledctl_Default, i);
            begin
               if   (    (Led_Default and E1000_LEDCTL_LED0_IVRT) = 0
                     and Mode = E1000_LEDCTL_MODE_LED_ON)
                 or (    (Led_Default and E1000_LEDCTL_LED0_IVRT) /= 0
                     and (Mode = E1000_LEDCTL_MODE_LED_OFF))
               then
                  Ledctl_Blink :=     Ledctl_Blink
                                  and not shift_Left (E1000_LEDCTL_LED0_MODE_MASK, i);
                  Ledctl_Blink :=     Ledctl_Blink
                                  or      shift_Left (E1000_LEDCTL_LED0_BLINK or E1000_LEDCTL_MODE_LED_ON, i);
               end if;
            end;

            I := I + 8;
         end loop;
      end if;

      EW32 (Hw.all, Devices.e1000e.Registers.E1000_LEDCTL, Ledctl_Blink);

      return 0;
   end E1000e_Blink_Led_Generic;




   ----------------------------------
   -- E1000e_Check_For_Copper_Link --
   ----------------------------------

   --  Check for link (Copper).
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Checks to see of the link status of the hardware has changed.  If a
   --  *  change in link status has been detected, then we read the PHY registers
   --  *  to get the current speed/duplex if link exists.


   function E1000e_Check_For_Copper_Link
     (Hw : access E1000_Hw) return s32
   is
      Mac     : E1000_Mac_Info.item renames Hw.Mac;
      Ret_Val : s32;
      Link    : Boolean;
      Unused  : s32;

   begin
      -- We only want to go out to the PHY registers to see if Auto-Neg
      -- has completed and/or if our link status has changed.  The
      -- get_link_status flag is set upon receiving a Link Status
      -- Change or Rx Sequence Error interrupt.
      --
      if not Mac.Get_Link_Status
      then
         return 0;
      end if;


      Mac.Get_Link_Status := False;

      -- First we want to see if the MII Status Register reports
      -- link.  If so, then we want to get the current speed/duplex
      -- of the PHY.
      --
      Ret_Val := E1000e_Phy_Has_Link_Generic (Hw, 1, 0, Link);

      if   Ret_Val /= 0
        or not Link
      then
         goto Out_Label;
      end if;

      -- Check if there was DownShift, must be checked
      -- immediately after link-up.
      --
      Unused := E1000e_Check_Downshift (Hw);

      -- If we are forcing speed/duplex, then we simply return since
      -- we have already determined whether we have link or not.
      --
      if not Mac.Autoneg
      then
         return -E1000_ERR_CONFIG;
      end if;


      -- Auto-Neg is enabled.  Auto Speed Detection takes care
      -- of MAC speed/duplex configuration.  So we only need to
      -- configure Collision Distance in the MAC.
      --
      Mac.Ops.Config_Collision_Dist (Hw);

      -- Configure Flow Control now that Auto-Neg has completed.
      -- First, we need to restore the desired flow control
      -- settings because we may have had to re-autoneg with a
      -- different link partner.
      --
      Ret_Val := E1000e_Config_Fc_After_Link_Up (Hw);

      if Ret_Val /= 0
      then
         e_dbg ("Error configuring flow control");
      end if;

      return Ret_Val;


      <<Out_Label>>

      Mac.Get_Link_Status := True;

      return Ret_Val;
   end E1000e_Check_For_Copper_Link;




   ---------------------------------
   -- E1000e_Check_For_Fiber_Link --
   ---------------------------------

   --  Check for link (Fiber).
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Checks for link up on the hardware.  If link is not up and we have
   --  *  a signal, then we need to force link up.


   function E1000e_Check_For_Fiber_Link
     (Hw : access E1000_Hw) return Devices.e1000e.Core.s32
   is
      Mac     : E1000_Mac_Info.item renames Hw.Mac;
      Rxcw    : Unsigned_32;
      Ctrl    : Unsigned_32;
      Status  : Unsigned_32;
      Ret_Val : s32;

   begin
      Ctrl   := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);
      Status := Er32 (Hw.all, Devices.e1000e.Registers.E1000_STATUS);
      Rxcw   := Er32 (Hw.all, Devices.e1000e.Registers.E1000_RXCW);

      -- If we don't have link (auto-negotiation failed or link partner
      -- cannot auto-negotiate), the cable is plugged in (we have signal),
      -- and our link partner is not trying to auto-negotiate with us (we
      -- are receiving idles or data), we need to force link up. We also
      -- need to give auto-negotiation time to complete, in case the cable
      -- was just plugged in. The autoneg_failed flag does this.

      -- (ctrl & E1000_CTRL_SWDPIN1) == 1 == have signal.
      --
      if         (Ctrl   and E1000_CTRL_SWDPIN1) /= 0
        and then (Status and E1000_STATUS_LU)     = 0
        and then (Rxcw   and E1000_RXCW_C)        = 0
      then
         if not Mac.Autoneg_Failed
         then
            Mac.Autoneg_Failed := True;
            return 0;
         end if;

         e_dbg ("NOT Rx'ing /C/, disable AutoNeg and force link.");

         -- Disable auto-negotiation in the TXCW register.
         --
         Ew32 (Hw.all,
               Devices.e1000e.Registers.E1000_TXCW,
               Mac.Txcw and (not E1000_TXCW_ANE));

         -- Force link-up and also force full-duplex.
         --
         Ctrl := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);
         Ctrl := Ctrl or (E1000_CTRL_SLU or E1000_CTRL_FD);

         Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, Ctrl);

         -- Configure Flow Control after forcing link up.
         --
         Ret_Val := E1000e_Config_Fc_After_Link_Up (Hw);

         if Ret_Val /= 0
         then
            e_dbg ("Error configuring flow control");
            return Ret_Val;
         end if;

      elsif      (Ctrl and E1000_CTRL_SLU) /= 0
        and then (Rxcw and E1000_RXCW_C)   /= 0
      then
         -- If we are forcing link and we are receiving /C/ ordered
         -- sets, re-enable auto-negotiation in the TXCW register
         -- and disable forced link in the Device Control register
         -- in an attempt to auto-negotiate with our link partner.
         --
         e_dbg ("Rx'ing /C/, enable AutoNeg and stop forcing link.");
         Ew32 (Hw.all, Devices.e1000e.Registers.E1000_TXCW, Mac.Txcw);
         Ew32 (Hw.all,
               Devices.e1000e.Registers.E1000_CTRL,
               Ctrl and (not E1000_CTRL_SLU));

         Mac.Serdes_Has_Link := True;
      end if;


      return 0;
   end E1000e_Check_For_Fiber_Link;





   ----------------------------------
   -- E1000e_Check_For_Serdes_Link --
   ----------------------------------

   --  Check for link (Serdes).
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Checks for link up on the hardware.  If link is not up and we have
   --  *  a signal, then we need to force link up.


   function E1000e_Check_For_Serdes_Link
     (Hw : access E1000_Hw) return s32
   is
      Mac     : E1000_Mac_Info.item renames Hw.Mac;
      Rxcw    : Unsigned_32;
      Ctrl    : Unsigned_32;
      Status  : Unsigned_32;
      Ret_Val : s32;

   begin
      Ctrl   := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);
      Status := Er32 (Hw.all, Devices.e1000e.Registers.E1000_STATUS);
      Rxcw   := Er32 (Hw.all, Devices.e1000e.Registers.E1000_RXCW);

      -- If we don't have link (auto-negotiation failed or link partner
      -- cannot auto-negotiate), and our link partner is not trying to
      -- auto-negotiate with us (we are receiving idles or data),
      -- we need to force link up. We also need to give auto-negotiation
      -- time to complete.

      -- (ctrl & E1000_CTRL_SWDPIN1) == 1 == have signal.
      --
      if         (Status and E1000_STATUS_LU) = 0
        and then (Rxcw   and E1000_RXCW_C)    = 0
      then
         if not Mac.Autoneg_Failed
         then
            Mac.Autoneg_Failed := True;
            return 0;
         end if;

         e_dbg ("NOT Rx'ing /C/, disable AutoNeg and force link.");

         -- Disable auto-negotiation in the TXCW register.
         --
         Ew32 (Hw.all,
               Devices.e1000e.Registers.E1000_TXCW,
               Mac.Txcw and (not E1000_TXCW_ANE));

         -- Force link-up and also force full-duplex.
         --
         Ctrl := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);
         Ctrl := Ctrl or (E1000_CTRL_SLU or E1000_CTRL_FD);
         Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, Ctrl);

         -- Configure Flow Control after forcing link up.
         --
         Ret_Val := E1000e_Config_Fc_After_Link_Up (Hw);

         if Ret_Val /= 0
         then
            e_dbg ("Error configuring flow control");
            return Ret_Val;
         end if;


      elsif      (Ctrl and E1000_CTRL_SLU) /= 0
        and then (Rxcw and E1000_RXCW_C)   /= 0
      then
         -- If we are forcing link and we are receiving /C/ ordered
         -- sets, re-enable auto-negotiation in the TXCW register
         -- and disable forced link in the Device Control register
         -- in an attempt to auto-negotiate with our link partner.
         --
         e_dbg ("Rx'ing /C/, enable AutoNeg and stop forcing link.");

         Ew32 (Hw.all, Devices.e1000e.Registers.E1000_TXCW, Mac.Txcw);
         Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, Ctrl and (not E1000_CTRL_SLU));

         Mac.Serdes_Has_Link := True;


      elsif (E1000_TXCW_ANE and Er32 (Hw.all, Devices.e1000e.Registers.E1000_TXCW)) = 0
      then
         -- If we force link for non-auto-negotiation switch, check
         -- link status based on MAC synchronization for internal
         -- serdes media type.
         -- SYNCH bit and IV bit are sticky.
         --
         delay 15.0 * Microseconds;     -- Equivalent to usleep_range (10, 20).

         Rxcw := Er32 (Hw.all, Devices.e1000e.Registers.E1000_RXCW);

         if (Rxcw and E1000_RXCW_SYNCH) /= 0
         then
            if (Rxcw and E1000_RXCW_IV) = 0
            then
               Mac.Serdes_Has_Link := True;
               e_dbg ("SERDES: Link up - forced.");
            end if;

         else
            Mac.Serdes_Has_Link := False;
            e_dbg ("SERDES: Link down - force failed.");
         end if;
      end if;


      if (E1000_TXCW_ANE and Er32 (Hw.all, Devices.e1000e.Registers.E1000_TXCW)) /= 0
      then
         Status := Er32 (Hw.all, Devices.e1000e.Registers.E1000_STATUS);

         if (Status and E1000_STATUS_LU) /= 0
         then
            -- SYNCH bit and IV bit are sticky, so reread rxcw.
            --
            delay 15.0 * Microseconds;     -- Equivalent to usleep_range (10, 20).

            Rxcw := Er32 (Hw.all, Devices.e1000e.Registers.E1000_RXCW);

            if (Rxcw and E1000_RXCW_SYNCH) /= 0
            then
               if (Rxcw and E1000_RXCW_IV) = 0
               then
                  Mac.Serdes_Has_Link := True;
                  e_dbg ("SERDES: Link up - autoneg completed successfully.");
               else
                  Mac.Serdes_Has_Link := False;
                  e_dbg ("SERDES: Link down - invalid codewords detected in autoneg.");
               end if;

            else
               Mac.Serdes_Has_Link := False;
               e_dbg ("SERDES: Link down - no sync.");
            end if;

         else
            Mac.Serdes_Has_Link := False;
            e_dbg ("SERDES: Link down - autoneg failed");
         end if;
      end if;


      return 0;
   end E1000e_Check_For_Serdes_Link;




   --------------------------------
   -- E1000e_Cleanup_LED_Generic --
   --------------------------------

   --  Set LED config to default operation.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Remove the current LED configuration and set the LED configuration
   --  *  to the default value, saved from the EEPROM.


   function E1000e_Cleanup_LED_Generic
     (HW : access E1000_HW) return s32
   is
   begin
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_LEDCTL, HW.Mac.LEDCTL_Default);
      return 0;
   end E1000e_Cleanup_LED_Generic;




   ------------------------------------
   -- E1000E_Config_FC_After_Link_Up --
   ------------------------------------

   --  Configures flow control after link.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Checks the status of auto-negotiation after link up to ensure that the
   --  *  speed and duplex were not forced.  If the link needed to be forced, then
   --  *  flow control needs to be forced also.  If auto-negotiation is enabled
   --  *  and did not fail, then we configure flow control based on our link
   --  *  partner.


   function E1000E_Config_FC_After_Link_Up
     (Hw : access E1000_Hw) return s32
   is
      mac                     : E1000_MAC_Info.item renames Hw.Mac;
      ret_val                 : s32 := 0;

      pcs_status_reg,
      pcs_adv_reg,
      pcs_lp_ability_reg,
      pcs_ctrl_reg            :         u32;

      mii_status_reg,
      mii_nway_adv_reg,
      mii_nway_lp_ability_reg : aliased u16;

      speed,
      duplex                  : aliased u16;

   begin
      --  Check for the case where we have fiber media and auto-neg failed
      --  so we had to force link.  In this case, we need to force the
      --  configuration of the MAC to match the "fc" parameter.
      --
      if mac.autoneg_failed
      then
         if        hw.phy.media_type = e1000_media_type_fiber
           or else hw.phy.media_type = e1000_media_type_internal_serdes
         then
            ret_val := E1000E_Force_MAC_FC (hw);
         end if;

      else
         if hw.phy.media_type = e1000_media_type_copper
         then
            ret_val := E1000E_Force_MAC_FC(hw);
         end if;
      end if;


      if ret_val /= 0
      then
         E_Dbg ("Error forcing flow control settings");
         return ret_val;
      end if;


      --  Check for the case where we have copper media and auto-neg is
      --  enabled.  In this case, we need to check and see if Auto-Neg
      --  has completed, and if so, how the PHY and link partner has
      --  flow control configured.
      --
      if    hw.phy.media_type = e1000_media_type_copper
        and mac.autoneg
      then
         -- Read the MII Status Register and check to see if AutoNeg
         -- has completed.  We read this twice because this reg has
         -- some "sticky" (latched) bits.
         --
         ret_val := E1E_RPHY (hw, MII_BMSR, mii_status_reg'unchecked_Access);

         if ret_val /= 0
         then
            return ret_val;
         end if;


         ret_val := E1E_RPHY (hw, MII_BMSR, mii_status_reg'unchecked_Access);

         if ret_val /= 0
         then
            return ret_val;
         end if;


         if (mii_status_reg and BMSR_ANEGCOMPLETE) = 0
         then
            E_Dbg ("Copper PHY and Auto Neg has not completed.");
            return ret_val;
         end if;


         -- The AutoNeg process has completed, so we now need to
         -- read both the Auto Negotiation Advertisement
         -- Register (Address 4) and the Auto_Negotiation Base
         -- Page Ability Register (Address 5) to determine how
         -- flow control was negotiated.
         --
         ret_val := E1E_RPHY (hw, MII_ADVERTISE, mii_nway_adv_reg'unchecked_Access);

         if ret_val /= 0
         then
            return ret_val;
         end if;


         ret_val := E1E_RPHY (hw, MII_LPA, mii_nway_lp_ability_reg'unchecked_Access);

         if ret_val /= 0
         then
            return ret_val;
         end if;


         -- Two bits in the Auto Negotiation Advertisement Register
         -- (Address 4) and two bits in the Auto Negotiation Base
         -- Page Ability Register (Address 5) determine flow control
         -- for both the PHY and the link partner.  The following
         -- table, taken out of the IEEE 802.3ab/D6.0 dated March 25,
         -- 1999, describes these PAUSE resolution bits and how flow
         -- control is determined based upon these settings.
         -- NOTE:  DC = Don't Care
         --
         --   LOCAL DEVICE  |   LINK PARTNER
         -- PAUSE | ASM_DIR | PAUSE | ASM_DIR | NIC Resolution
         -- ------|---------|-------|---------|--------------------
         --   0   |    0    |  DC   |   DC    | e1000_fc_none
         --   0   |    1    |   0   |   DC    | e1000_fc_none
         --   0   |    1    |   1   |    0    | e1000_fc_none
         --   0   |    1    |   1   |    1    | e1000_fc_tx_pause
         --   1   |    0    |   0   |   DC    | e1000_fc_none
         --   1   |   DC    |   1   |   DC    | e1000_fc_full
         --   1   |    1    |   0   |    0    | e1000_fc_none
         --   1   |    1    |   0   |    1    | e1000_fc_rx_pause
         --
         -- Are both PAUSE bits set to 1?  If so, this implies
         -- Symmetric Flow Control is enabled at both ends.  The
         -- ASM_DIR bits are irrelevant per the spec.
         --
         -- For Symmetric Flow Control:
         --
         --   LOCAL DEVICE  |   LINK PARTNER
         --  PAUSE | ASM_DIR | PAUSE | ASM_DIR | Result
         -- -------|---------|-------|---------|--------------------
         --    1   |   DC    |   1   |   DC    | E1000_fc_full
         --
         if    (mii_nway_adv_reg        and ADVERTISE_PAUSE_CAP) /= 0
           and (mii_nway_lp_ability_reg and LPA_PAUSE_CAP)       /= 0
         then
            -- Now we need to check if the user selected Rx ONLY
            -- of pause frames.  In this case, we had to advertise
            -- FULL flow control because we could not advertise Rx
            -- ONLY. Hence, we must now check to see if we need to
            -- turn OFF the TRANSMISSION of PAUSE frames.
            --
            if hw.fc.requested_mode = e1000_fc_full
            then
               hw.fc.current_mode := e1000_fc_full;
               E_Dbg ("Flow Control = FULL.");
            else
               hw.fc.current_mode := e1000_fc_rx_pause;
               E_Dbg ("Flow Control = Rx PAUSE frames only.");
            end if;

            -- For receiving PAUSE frames ONLY.
            --
            --    LOCAL DEVICE  |   LINK PARTNER
            --  PAUSE | ASM_DIR | PAUSE | ASM_DIR | Result
            -- -------|---------|-------|---------|--------------------
            --    0   |    1    |   1   |    1    | e1000_fc_tx_pause
            --
         elsif (mii_nway_adv_reg        and ADVERTISE_PAUSE_CAP)   = 0
           and (mii_nway_adv_reg        and ADVERTISE_PAUSE_ASYM) /= 0
           and (mii_nway_lp_ability_reg and LPA_PAUSE_CAP)        /= 0
           and (mii_nway_lp_ability_reg and LPA_PAUSE_ASYM)       /= 0
         then
            hw.fc.current_mode := e1000_fc_tx_pause;
            E_Dbg ("Flow Control = Tx PAUSE frames only.");

            -- For transmitting PAUSE frames ONLY.
            --
            --    LOCAL DEVICE  |   LINK PARTNER
            --  PAUSE | ASM_DIR | PAUSE | ASM_DIR | Result
            -- -------|---------|-------|---------|--------------------
            --    1   |    1    |   0   |    1    | e1000_fc_rx_pause
            --
         elsif (mii_nway_adv_reg        and ADVERTISE_PAUSE_CAP)  /= 0
           and (mii_nway_adv_reg        and ADVERTISE_PAUSE_ASYM) /= 0
           and (mii_nway_lp_ability_reg and LPA_PAUSE_CAP)         = 0
           and (mii_nway_lp_ability_reg and LPA_PAUSE_ASYM)       /= 0
         then
            hw.fc.current_mode := e1000_fc_rx_pause;
            E_Dbg ("Flow Control = Rx PAUSE frames only.");

         else
            --  Per the IEEE spec, at this point flow control
            --  should be disabled.
            --
            hw.fc.current_mode := e1000_fc_none;
            E_Dbg ("Flow Control = NONE.");
         end if;


         -- Now we need to do one last check ...  If we auto-
         -- negotiated to HALF DUPLEX, flow control should not be
         -- enabled per IEEE 802.3 spec.
         --
         ret_val := mac.ops.get_link_up_info (hw,
                                              speed 'unchecked_Access,
                                              duplex'unchecked_Access);
         if ret_val /= 0
         then
            E_Dbg ("Error getting link speed and duplex");
            return ret_val;
         end if;


         if duplex = HALF_DUPLEX
         then
            hw.fc.current_mode := e1000_fc_none;
         end if;

         -- Now we call a subroutine to actually force the MAC
         -- controller to use the correct flow control settings.
         --
         ret_val := E1000E_Force_MAC_FC (hw);

         if ret_val /= 0
         then
            E_Dbg ("Error forcing flow control settings");
            return ret_val;
         end if;
      end if;


      -- Check for the case where we have SerDes media and auto-neg is
      -- enabled.  In this case, we need to check and see if Auto-Neg
      -- has completed, and if so, how the PHY and link partner has
      -- flow control configured.
      --
      if    hw.phy.media_type = e1000_media_type_internal_serdes
        and mac.autoneg
      then
         -- Read the PCS_LSTS and check to see if AutoNeg has completed.
         --
         pcs_status_reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_PCS_LSTAT);

         if (pcs_status_reg and E1000_PCS_LSTS_AN_COMPLETE) = 0
         then
            E_Dbg ("PCS Auto Neg has not completed.");
            return ret_val;
         end if;

         -- The AutoNeg process has completed, so we now need to
         -- read both the Auto Negotiation Advertisement
         -- Register (PCS_ANADV) and the Auto_Negotiation Base
         -- Page Ability Register (PCS_LPAB) to determine how
         -- flow control was negotiated.
         --
         pcs_adv_reg        := Er32 (Hw.all, Devices.e1000e.Registers.E1000_PCS_ANADV);
         pcs_lp_ability_reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_PCS_LPAB);

         -- Two bits in the Auto Negotiation Advertisement Register
         -- (PCS_ANADV) and two bits in the Auto Negotiation Base
         -- Page Ability Register (PCS_LPAB) determine flow control
         -- for both the PHY and the link partner.  The following
         -- table, taken out of the IEEE 802.3ab/D6.0 dated March 25,
         -- 1999, describes these PAUSE resolution bits and how flow
         -- control is determined based upon these settings.
         -- NOTE:  DC = Don't Care
         --
         --   LOCAL DEVICE  |   LINK PARTNER
         --  PAUSE | ASM_DIR | PAUSE | ASM_DIR | NIC Resolution
         -- -------|---------|-------|---------|--------------------
         --    0   |    0    |  DC   |   DC    | e1000_fc_none
         --    0   |    1    |   0   |   DC    | e1000_fc_none
         --    0   |    1    |   1   |    0    | e1000_fc_none
         --    0   |    1    |   1   |    1    | e1000_fc_tx_pause
         --    1   |    0    |   0   |   DC    | e1000_fc_none
         --    1   |   DC    |   1   |   DC    | e1000_fc_full
         --    1   |    1    |   0   |    0    | e1000_fc_none
         --    1   |    1    |   0   |    1    | e1000_fc_rx_pause
         --
         -- Are both PAUSE bits set to 1?  If so, this implies
         -- Symmetric Flow Control is enabled at both ends.  The
         -- ASM_DIR bits are irrelevant per the spec.
         --
         -- For Symmetric Flow Control:
         --
         --   LOCAL DEVICE  |   LINK PARTNER
         --  PAUSE | ASM_DIR | PAUSE | ASM_DIR | Result
         -- -------|---------|-------|---------|--------------------
         --    1   |   DC    |   1   |   DC    | e1000_fc_full
         --
         if    (pcs_adv_reg        and E1000_TXCW_PAUSE) /= 0
           and (pcs_lp_ability_reg and E1000_TXCW_PAUSE) /= 0
         then
            -- Now we need to check if the user selected Rx ONLY
            -- of pause frames.  In this case, we had to advertise
            -- FULL flow control because we could not advertise Rx
            -- ONLY. Hence, we must now check to see if we need to
            -- turn OFF the TRANSMISSION of PAUSE frames.
            --
            if hw.fc.requested_mode = e1000_fc_full
            then
               hw.fc.current_mode := e1000_fc_full;
               E_Dbg ("Flow Control = FULL.");
            else
               hw.fc.current_mode := e1000_fc_rx_pause;
               E_Dbg ("Flow Control = Rx PAUSE frames only.");
            end if;

            -- For receiving PAUSE frames ONLY.
            --
            --    LOCAL DEVICE  |   LINK PARTNER
            --  PAUSE | ASM_DIR | PAUSE | ASM_DIR | Result
            -- -------|---------|-------|---------|--------------------
            --    0   |    1    |   1   |    1    | e1000_fc_tx_pause
            --
         elsif (pcs_adv_reg        and E1000_TXCW_PAUSE)    = 0
           and (pcs_adv_reg        and E1000_TXCW_ASM_DIR) /= 0
           and (pcs_lp_ability_reg and E1000_TXCW_PAUSE)   /= 0
           and (pcs_lp_ability_reg and E1000_TXCW_ASM_DIR) /= 0
         then
            hw.fc.current_mode := e1000_fc_tx_pause;
            E_Dbg ("Flow Control = Tx PAUSE frames only.");

            -- For transmitting PAUSE frames ONLY.
            --
            --       LOCAL DEVICE  |   LINK PARTNER
            --     PAUSE | ASM_DIR | PAUSE | ASM_DIR | Result
            --    -------|---------|-------|---------|--------------------
            --       1   |    1    |   0   |    1    | e1000_fc_rx_pause
            --
         elsif (pcs_adv_reg        and E1000_TXCW_PAUSE)   /= 0
           and (pcs_adv_reg        and E1000_TXCW_ASM_DIR) /= 0
           and (pcs_lp_ability_reg and E1000_TXCW_PAUSE)    = 0
           and (pcs_lp_ability_reg and E1000_TXCW_ASM_DIR) /= 0
         then
            hw.fc.current_mode := e1000_fc_rx_pause;
            E_Dbg ("Flow Control = Rx PAUSE frames only.");

         else
            -- Per the IEEE spec, at this point flow control should be disabled.
            --
            hw.fc.current_mode := e1000_fc_none;
            E_Dbg ("Flow Control = NONE.");
         end if;


         -- Now we call a subroutine to actually force the MAC
         -- controller to use the correct flow control settings.
         --
         pcs_ctrl_reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_PCS_LCTL);
         pcs_ctrl_reg := pcs_ctrl_reg or E1000_PCS_LCTL_FORCE_FCTRL;

         Ew32 (Hw.all, Devices.e1000e.Registers.E1000_PCS_LCTL, pcs_ctrl_reg);

         ret_val := E1000E_Force_MAC_FC (hw);

         if ret_val /= 0
         then
            E_Dbg ("Error forcing flow control settings");
            return ret_val;
         end if;
      end if;


      return 0;
   end E1000E_Config_FC_After_Link_Up;




   -------------------------------
   -- E1000_Disable_PCIe_Master --
   -------------------------------

   --  Disables PCI-express master access.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Returns 0 if successful, else returns -10
   --  *  (-E1000_ERR_MASTER_REQUESTS_PENDING) if master disable bit has not caused
   --  *  the master requests to be disabled.
   --  *
   --  *  Disables PCI-Express master access and verifies there are no pending
   --  *  requests.


   function E1000e_Disable_PCIe_Master
     (HW : access E1000_HW) return s32
   is
      Ctrl    : Unsigned_32;
      Timeout : Integer    := MASTER_DISABLE_TIMEOUT;

   begin
      Ctrl := er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);
      Ctrl := Ctrl or E1000_CTRL_GIO_MASTER_DISABLE;

      ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, Ctrl);

      while Timeout > 0
      loop
         exit when (    er32 (Hw.all, Devices.e1000e.Registers.E1000_STATUS)
                    and E1000_STATUS_GIO_MASTER_ENABLE) = 0;

         delay 150.0 * Microseconds;
         Timeout := Timeout - 1;
      end loop;

      if Timeout = 0
      then
         e_dbg ("Master requests are pending.");
         return -E1000_ERR_MASTER_REQUESTS_PENDING;
      end if;

      return 0;
   end E1000e_Disable_PCIe_Master;




   -------------------------
   -- E1000e_Force_Mac_Fc --
   -------------------------

   --  Force the MAC's flow control settings
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Force the MAC's flow control settings.  Sets the TFCE and RFCE bits in the
   --  *  device control register to reflect the adapter settings.  TFCE and RFCE
   --  *  need to be explicitly set by software when a copper PHY is used because
   --  *  autonegotiation is managed by the PHY rather than the MAC.  Software must
   --  *  also configure these bits when link is forced on a fiber connection.


   function E1000e_Force_Mac_Fc
     (Hw : access E1000_Hw) return s32
   is
      Ctrl : Unsigned_32;
   begin
      Ctrl := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);

      -- Because we didn't get link via the internal auto-negotiation
      -- mechanism (we either forced link or we got link via PHY
      -- auto-neg), we have to manually enable/disable transmit and
      -- receive flow control.
      --
      -- The "Case" statement below enables/disable flow control
      -- according to the "Hw.Fc.Current_Mode" parameter.
      --
      -- The possible values of the "fc" parameter are:
      --      0:  Flow control is completely disabled
      --      1:  Rx flow control is enabled (we can receive pause
      --          frames but not send pause frames).
      --      2:  Tx flow control is enabled (we can send pause frames
      --          but we do not receive pause frames).
      --      3:  Both Rx and Tx flow control (symmetric) is enabled.
      --  other:  No other values should be possible at this point.

      e_dbg ("Hw.Fc.Current_Mode =" & Hw.Fc.Current_Mode'Image);

      case Hw.Fc.Current_Mode
      is
         when E1000_Fc_None =>
            Ctrl := Ctrl and (not (E1000_CTRL_TFCE or E1000_CTRL_RFCE));

         when E1000_Fc_Rx_Pause =>
            Ctrl := Ctrl and (not E1000_CTRL_TFCE);
            Ctrl := Ctrl or       E1000_CTRL_RFCE;

         when E1000_Fc_Tx_Pause =>
            Ctrl := Ctrl and (not E1000_CTRL_RFCE);
            Ctrl := Ctrl or       E1000_CTRL_TFCE;

         when E1000_Fc_Full =>
            Ctrl := Ctrl or      (E1000_CTRL_TFCE or E1000_CTRL_RFCE);

         when others =>
            e_dbg ("Flow control param set incorrectly");
            return -E1000_ERR_CONFIG;
      end case;

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, Ctrl);

      return 0;
   end E1000e_Force_Mac_Fc;




   -----------------------------
   -- E1000e_Get_Auto_Rd_Done --
   -----------------------------

   --  Check for auto read completion.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Check EEPROM for Auto Read done bit.


   function E1000e_Get_Auto_Rd_Done
     (Hw : access E1000_Hw) return s32
   is
      I : Natural := 0;

   begin
      while I < AUTO_READ_DONE_TIMEOUT
      loop
         exit when (    Er32 (Hw.all, Devices.e1000e.Registers.E1000_EECD)
                    and E1000_EECD_AUTO_RD)            /= 0;

         delay 1_500.0 * Microseconds;
         I := I + 1;
      end loop;

      if I = AUTO_READ_DONE_TIMEOUT
      then
         e_dbg ("Auto read by HW from NVM has not completed.");
         return -E1000_ERR_RESET;
      end if;

      return 0;
   end E1000e_Get_Auto_Rd_Done;




   ------------------------------
   -- E1000e_Get_Bus_Info_PCIe --
   ------------------------------

   --  Get PCIe bus information.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Determines and stores the system bus information for a particular
   --  *  network interface.  The following bus information is determined and stored:
   --  *  bus speed, bus width, type (PCIe), and PCIe function.


   function E1000e_Get_Bus_Info_PCIe
     (HW : access E1000_HW) return s32
   is
      Pdev             : constant access  PCI_Dev             := HW.Adapter.Pdev;
      Mac              : constant access  E1000_Mac_Info.item := HW.Mac'Access;
      Bus              : constant access  E1000_Bus_Info.item := HW.Bus'Access;
      PCIe_Link_Status : aliased          u16;
      Unused           :                  C.int;

   begin
      if PCI_PCIe_Cap (Pdev) = 0
      then
         Bus.Width := E1000_Bus_Width_Unknown;
      else
         Unused    := PCIe_Capability_Read_Word (Pdev,
                                                 PCI_EXP_LNKSTA,
                                                 PCIe_Link_Status'unchecked_Access);

         Bus.Width := E1000_Bus_Width'Enum_Val (FIELD_GET (PCI_EXP_LNKSTA_NLW,
                                                pcie_link_status));
      end if;

      Mac.Ops.Set_Lan_Id (HW);

      return 0;
   end E1000e_Get_Bus_Info_PCIe;




   ----------------------------------
   -- e1000_Set_Lan_Id_Single_Port --
   ----------------------------------

   --  Set LAN id for a single port device.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Sets the LAN function id to zero for a single port device.


   procedure e1000_Set_Lan_Id_Single_Port
     (HW : access E1000_HW)
   is
   begin
      HW.Bus.Func := 0;
   end e1000_Set_Lan_Id_Single_Port;




   -----------------------------
   -- E1000E_Get_HW_Semaphore --
   -----------------------------

   --  Acquire hardware semaphore.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Acquire the HW semaphore to access the PHY or NVM


   function E1000E_Get_HW_Semaphore
     (HW : access E1000_HW) return s32
   is
      SWSM    :          Unsigned_32;
      Timeout : constant s32        := s32 (HW.NVM.Word_Size) + 1;
      I       :          s32        := 0;

   begin
      -- Get the SW semaphore.
      --
      while I < Timeout
      loop
         SWSM := ER32 (Hw.all, Devices.e1000e.Registers.E1000_SWSM);

         exit when (SWSM and E1000_SWSM_SMBI) = 0;

         delay 100.0 * Microseconds;
         I := I + 1;
      end loop;


      if I = Timeout
      then
         e_dbg ("Driver can't access device - SMBI bit is set.");
         return -E1000_ERR_NVM;
      end if;


      -- Get the FW semaphore.
      --
      I := 0;

      while I < Timeout
      loop
         SWSM := ER32 (Hw.all, Devices.e1000e.Registers.E1000_SWSM);
         EW32 (Hw.all, Devices.e1000e.Registers.E1000_SWSM, SWSM or E1000_SWSM_SWESMBI);

         -- Semaphore acquired if bit latched.
         --
         exit when (ER32 (Hw.all, Devices.e1000e.Registers.E1000_SWSM) and E1000_SWSM_SWESMBI) /= 0;

         delay 100.0 * Microseconds;
         I := I + 1;
      end loop;


      if I = Timeout
      then
         -- Release semaphores.
         --
         E1000E_Put_HW_Semaphore (HW);
         e_dbg ("Driver can't access the NVM");
         return -E1000_ERR_NVM;
      end if;


      return 0;
   end E1000E_Get_HW_Semaphore;




   ----------------------------------------
   -- e1000e_Get_Speed_And_Duplex_Copper --
   ----------------------------------------

   --  Retrieve current speed/duplex.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @speed:  Stores the current speed.
   --  *  @duplex: Stores the current duplex.
   --  *
   --  *  Read the status register for the current speed/duplex and store the current
   --  *  speed and duplex for copper connections.


   function e1000e_Get_Speed_And_Duplex_Copper
     (hw     : access e1000_hw;
      speed  : in     Devices.e1000e.Core.Pointers.u16_Pointer;
      duplex : in     Devices.e1000e.Core.Pointers.u16_Pointer) return Devices.e1000e.Core.s32
   is
      Status : u32;

   begin
      Status := Er32 (Hw.all, Devices.e1000e.Registers.E1000_STATUS);

      if (Status and E1000_STATUS_SPEED_1000) /= 0
      then
         Speed.all := SPEED_1000;

      elsif (Status and E1000_STATUS_SPEED_100) /= 0
      then
         Speed.all := SPEED_100;

      else
         Speed.all := SPEED_10;
      end if;


      if (Status and E1000_STATUS_FD) /= 0
      then
         Duplex.all := FULL_DUPLEX;
      else
         Duplex.all := HALF_DUPLEX;
      end if;


      e_dbg (  Speed'Image & " Mbps, "
               & (if Duplex.all = FULL_DUPLEX then "Full"
                                              else "Half") & " Duplex");
      return 0;
   end e1000e_Get_Speed_And_Duplex_Copper;




   ----------------------------------------------
   -- E1000e_Get_Speed_And_Duplex_Fiber_Serdes --
   ----------------------------------------------

   --  Retrieve current speed/duplex.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @speed:  Stores the current speed.
   --  *  @duplex: Stores the current duplex.
   --  *
   --  *  Sets the speed and duplex to gigabit full duplex (the only possible option)
   --  *  for fiber/serdes links.


   function E1000e_Get_Speed_And_Duplex_Fiber_Serdes
     (hw     : access e1000_hw with Unreferenced;
      speed  : in     Devices.e1000e.Core.Pointers.u16_Pointer;
      duplex : in     Devices.e1000e.Core.Pointers.u16_Pointer) return Devices.e1000e.Core.s32
   is
   begin
      Speed.all  := SPEED_1000;
      Duplex.all := FULL_DUPLEX;

      return 0;
   end E1000e_Get_Speed_And_Duplex_Fiber_Serdes;





   --------------------------------
   -- E1000e_Id_Led_Init_Generic --
   --------------------------------

   function E1000e_Id_Led_Init_Generic
     (Hw : access E1000_Hw) return s32
   is
      Mac         :          E1000_Mac_Info.item renames Hw.Mac;
      Ret_Val     :          s32;
      Ledctl_Mask : constant Unsigned_32 := 16#000000FF#;
      Ledctl_On   : constant Unsigned_32 := E1000_LEDCTL_MODE_LED_ON;
      Ledctl_Off  : constant Unsigned_32 := E1000_LEDCTL_MODE_LED_OFF;
      Data        : aliased  Unsigned_16;
      I           :          Unsigned_16;
      Temp        :          Unsigned_16;
      Led_Mask    : constant Unsigned_16 := 16#0F#;

   begin
      Ret_Val := Hw.Nvm.Ops.Valid_Led_Default (Hw, Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Mac.Ledctl_Default := Er32 (Hw.all, Devices.e1000e.Registers.E1000_LEDCTL);
      Mac.Ledctl_Mode1   := Mac.Ledctl_Default;
      Mac.Ledctl_Mode2   := Mac.Ledctl_Default;

      for I in 0 .. 3
      loop
         Temp := shift_Right (Data, I * 4) and Led_Mask;

         case Temp
         is
            when ID_LED_ON1_DEF2
               | ID_LED_ON1_ON2
               | ID_LED_ON1_OFF2 =>

               Mac.Ledctl_Mode1 := Mac.Ledctl_Mode1 and not shift_Left (Ledctl_Mask, I * 8);
               Mac.Ledctl_Mode1 := Mac.Ledctl_Mode1 or      shift_Left (Ledctl_On,   I * 8);

            when ID_LED_OFF1_DEF2
               | ID_LED_OFF1_ON2
               | ID_LED_OFF1_OFF2 =>

               Mac.Ledctl_Mode1 := Mac.Ledctl_Mode1 and not shift_Left (Ledctl_Mask, I * 8);
               Mac.Ledctl_Mode1 := Mac.Ledctl_Mode1 or      shift_Left (Ledctl_Off,  I * 8);

            when others =>
               null;
         end case;

         case Temp
         is
            when ID_LED_DEF1_ON2
               | ID_LED_ON1_ON2
               | ID_LED_OFF1_ON2 =>

               Mac.Ledctl_Mode2 := Mac.Ledctl_Mode2 and not shift_Left (Ledctl_Mask, I * 8);
               Mac.Ledctl_Mode2 := Mac.Ledctl_Mode2 or      shift_Left (Ledctl_On,   I * 8);

            when ID_LED_DEF1_OFF2
               | ID_LED_ON1_OFF2
               | ID_LED_OFF1_OFF2 =>

               Mac.Ledctl_Mode2 := Mac.Ledctl_Mode2 and not shift_Left (Ledctl_Mask, I * 8);
               Mac.Ledctl_Mode2 := Mac.Ledctl_Mode2 or      shift_Left (Ledctl_Off,  I * 8);

            when others =>
               null;
         end case;

      end loop;

      return 0;
   end E1000e_Id_Led_Init_Generic;





   ---------------------------
   -- E1000e_LED_On_Generic --
   ---------------------------

   --  Turn LED on.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Turn LED on.


   function E1000e_LED_On_Generic
     (HW : access E1000_HW) return s32
   is
      Ctrl : Unsigned_32;

   begin
      case HW.Phy.Media_Type
      is
         when E1000_Media_Type_Fiber =>

            Ctrl := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);
            Ctrl := Ctrl and (not E1000_CTRL_SWDPIN0);
            Ctrl := Ctrl or E1000_CTRL_SWDPIO0;

            Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, Ctrl);

         when E1000_Media_Type_Copper =>

            Ew32 (Hw.all, Devices.e1000e.Registers.E1000_LEDCTL, HW.Mac.Ledctl_Mode2);

         when others =>
            null;
      end case;

      return 0;
   end E1000e_LED_On_Generic;





   ----------------------------
   -- E1000e_Led_Off_Generic --
   ----------------------------

   --  Turn LED off.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Turn LED off.


   function E1000e_Led_Off_Generic
     (Hw : access E1000_Hw) return s32
   is
      Ctrl : Unsigned_32;

   begin
      case Hw.Phy.Media_Type
      is
         when E1000_Media_Type_Fiber =>

            Ctrl := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);
            Ctrl := Ctrl or E1000_CTRL_SWDPIN0;
            Ctrl := Ctrl or E1000_CTRL_SWDPIO0;

            Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, Ctrl);

         when E1000_Media_Type_Copper =>

            Ew32 (Hw.all, Devices.e1000e.Registers.E1000_LEDCTL, Hw.Mac.Ledctl_Mode1);

         when others =>
            null;
      end case;

      return 0;
   end E1000e_Led_Off_Generic;




   ----------------------------------------
   -- e1000e_Update_MC_Addr_List_Generic --
   ----------------------------------------

   --  Update Multicast addresses.
   --
   --  *  @hw:            Pointer to the HW structure.
   --  *  @mc_addr_list:  Array of multicast addresses to program.
   --  *  @mc_addr_count: Number of multicast addresses to program.
   --  *
   --  *  Updates entire Multicast Table Array.
   --  *  The caller must have a packed mc_addr_list of multicast addresses.


   procedure e1000e_Update_MC_Addr_List_Generic
     (HW            : access E1000_HW;
      MC_Addr_List  : in     u8_Pointer;
      MC_Addr_Count : in     u32)
   is
      use C_u8_Pointers;

      Hash_Value : Interfaces.Unsigned_32;
      Hash_Reg   : Interfaces.Unsigned_32;
      Hash_Bit   : Interfaces.Unsigned_32;

      MC_Address_List : u8_Pointer := MC_Addr_List;

   begin
      -- Clear mta_shadow.
      --
      HW.Mac.MTA_Shadow := [others => 0];


      -- Update mta_shadow from mc_addr_list.
      --
      for I in 0 .. MC_Addr_Count - 1
      loop
         Hash_Value := E1000_Hash_MC_Addr (HW, MC_Address_List);

         Hash_Reg   :=     shift_Right (Hash_Value, 5)
           and u32 (HW.Mac.MTA_Reg_Count - 1);

         Hash_Bit   := Hash_Value and 16#1F#;

         HW.Mac.MTA_Shadow (C.size_t (Hash_Reg)) := @ or BIT (Integer (Hash_Bit));

         MC_Address_List := MC_Address_List + ETH_ALEN;
      end loop;


      -- Replace the entire MTA table.
      --
      for I in reverse 0 .. C.size_t (HW.Mac.MTA_Reg_Count) - 1
      loop
         E1000_Write_Reg_Array (HW,
                                Devices.e1000e.Registers.E1000_MTA,
                                u32 (I),
                                HW.Mac.MTA_Shadow (I));
      end loop;

      E1E_Flush (Hw);
   end e1000e_Update_MC_Addr_List_Generic;




   ------------------------------
   -- E1000e_Set_Fc_Watermarks --
   ------------------------------

   --  Set flow control high/low watermarks.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Sets the flow control high/low threshold (watermark) registers.  If
   --  *  flow control XON frame transmission is enabled, then set XON frame
   --  *  transmission as well.


   function E1000e_Set_Fc_Watermarks
     (Hw : access E1000_Hw) return s32
   is
      Fcrtl : Unsigned_32 := 0;
      Fcrth : Unsigned_32 := 0;
   begin
      -- Set the flow control receive threshold registers.  Normally,
      -- these registers will be set to a default threshold that may be
      -- adjusted later by the driver's runtime code.  However, if the
      -- ability to transmit pause frames is not enabled, then these
      -- registers will be set to 0.
      --
      if (    u32 (Hw.Fc.Current_Mode'enum_Rep)
          and      E1000_Fc_Tx_Pause 'enum_Rep) /= 0
      then
         -- We need to set up the Receive Threshold high and low water
         -- marks as well as (optionally) enabling the transmission of
         -- XON frames.
         --
         Fcrtl := Hw.Fc.Low_Water;

         if Hw.Fc.Send_Xon
         then
            Fcrtl := Fcrtl or E1000_FCRTL_XONE;
         end if;

         Fcrth := Hw.Fc.High_Water;
      end if;

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_FCRTL, Fcrtl);
      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_FCRTH, Fcrth);

      return 0;
   end E1000e_Set_Fc_Watermarks;




   ------------------------------------
   -- E1000e_Setup_Fiber_Serdes_Link --
   ------------------------------------

   --  Setup link for fiber/serdes.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Configures collision distance and flow control for fiber and serdes
   --  *  links.  Upon successful setup, poll for link.


   function E1000e_Setup_Fiber_Serdes_Link
     (Hw : access E1000_Hw) return s32
   is
      Ctrl    : Unsigned_32;
      Ret_Val : s32;

   begin
      Ctrl := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);

      -- Take the link out of reset.
      --
      Ctrl := Ctrl and (not E1000_CTRL_LRST);

      Hw.Mac.Ops.Config_Collision_Dist (Hw);

      Ret_Val := E1000_Commit_Fc_Settings_Generic (Hw);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- Since auto-negotiation is enabled, take the link out of reset (the
      -- link will be in reset, because we previously reset the chip). This
      -- will restart auto-negotiation.  If auto-negotiation is successful
      -- then the link-up status bit will be set and the flow control enable
      -- bits (RFCE and TFCE) will be set according to their negotiated value.
      --
      e_dbg ("Auto-negotiation enabled");

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, Ctrl);
      E1E_Flush (Hw);

      delay 1_500.0 * Microseconds;

      -- For these adapters, the SW definable pin 1 is set when the optics
      -- detect a signal.  If we have a signal, then poll for a "Link-Up"
      -- indication.
      --
      if   Hw.Phy.Media_Type = E1000_Media_Type_Internal_Serdes
        or (Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL) and E1000_CTRL_SWDPIN1) /= 0
      then
         Ret_Val := E1000_Poll_Fiber_Serdes_Link_Generic (Hw);
      else
         e_dbg ("No signal detected");
      end if;


      return Ret_Val;
   end E1000e_Setup_Fiber_Serdes_Link;





   ------------------------------
   -- E1000e_Setup_Led_Generic --
   ------------------------------

   --  Configures SW controllable LED.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  This prepares the SW controllable LED for use and saves the current state
   --  *  of the LED so it can be later restored.


   function E1000e_Setup_Led_Generic
     (Hw : access E1000_Hw) return s32
   is
      use type Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.item;

      Ledctl : Unsigned_32;

   begin
      if Hw.Mac.Ops.Setup_Led /= E1000e_Setup_Led_Generic'Access
      then
         return -E1000_ERR_CONFIG;
      end if;


      if Hw.Phy.Media_Type = E1000_Media_Type_Fiber
      then
         Ledctl                := Er32 (Hw.all, Devices.e1000e.Registers.E1000_LEDCTL);
         Hw.Mac.Ledctl_Default := Ledctl;

         -- Turn off LED0.
         --
         Ledctl := Ledctl and not (   E1000_LEDCTL_LED0_IVRT
                                   or E1000_LEDCTL_LED0_BLINK
                                   or E1000_LEDCTL_LED0_MODE_MASK);

         Ledctl := Ledctl or shift_Left (E1000_LEDCTL_MODE_LED_OFF,
                                         E1000_LEDCTL_LED0_MODE_SHIFT);
         Ew32 (Hw.all, Devices.e1000e.Registers.E1000_LEDCTL, Ledctl);

      elsif Hw.Phy.Media_Type = E1000_Media_Type_Copper
      then
         Ew32 (Hw.all, Devices.e1000e.Registers.E1000_LEDCTL, Hw.Mac.Ledctl_Mode1);
      end if;


      return 0;
   end E1000e_Setup_Led_Generic;









   -------------------------------
   -- E1000e_Setup_Link_Generic --
   -------------------------------

   --  Setup flow control and link settings.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Determines which flow control settings to use, then configures flow
   --  *  control.  Calls the appropriate media-specific link configuration
   --  *  function.  Assuming the adapter has a valid link partner, a valid link
   --  *  should be established.  Assumes the hardware has previously been reset
   --  *  and the transmitter and receiver are not enabled.


   function E1000e_Setup_Link_Generic
     (HW : access E1000_HW) return S32
   is
      use type Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.item;

      Ret_Val : S32;
   begin
      -- In the case of the phy reset being blocked, we already have a link.
      -- We do not need to set it up again.
      --
      if         HW.Phy.Ops.Check_Reset_Block      /= null
        and then HW.Phy.Ops.Check_Reset_Block (HW) /= 0
      then
         return 0;
      end if;


      -- If requested flow control is set to default, set flow control
      -- based on the EEPROM flow control settings.
      --
      if HW.Fc.Requested_Mode = E1000_Fc_Default
      then
         Ret_Val := E1000_Set_Default_Fc_Generic (HW);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;
      end if;


      -- Save off the requested flow control mode for use later. Depending
      -- on the link partner's capabilities, we may or may not use this mode.
      --
      HW.Fc.Current_Mode := HW.Fc.Requested_Mode;

      e_dbg ("After fix-ups FlowControl is now = " & HW.Fc.Current_Mode'Image);

      -- Call the necessary media_type subroutine to configure the link.
      --
      Ret_Val := HW.Mac.Ops.Setup_Physical_Interface (HW);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- Initialize the flow control address, type, and PAUSE timer
      -- registers to their default values. This is done even if flow
      -- control is disabled, because it does not hurt anything to
      -- initialize these registers.
      --
      e_dbg ("Initializing the Flow Control address, type and timer regs");

      EW32 (Hw.all, Devices.e1000e.Registers.E1000_FCT,   FLOW_CONTROL_TYPE);
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_FCAH , FLOW_CONTROL_ADDRESS_HIGH);
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_FCAL,  FLOW_CONTROL_ADDRESS_LOW);
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_FCTTV, u32 (HW.Fc.Pause_Time));

      return E1000e_Set_Fc_Watermarks (HW);
   end E1000e_Setup_Link_Generic;




   --------------------------------
   -- E1000e_Clear_Hw_Cntrs_Base --
   --------------------------------

   --  Clear base hardware counters.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Clears the base hardware counters by reading the counter registers.


   procedure E1000e_Clear_Hw_Cntrs_Base
     (HW : access E1000_HW)
   is
      Unused : u32;
   begin
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_CRCERRS);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_SYMERRS);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_MPC);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_SCC);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_ECOL);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_MCC);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_LATECOL);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_COLC);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_DC);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_SEC);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_RLEC);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_XONRXC);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_XONTXC);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_XOFFRXC);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_XOFFTXC);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_FCRUC);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_GPRC);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_BPRC);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_MPRC);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_GPTC);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_GORCL);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_GORCH);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_GOTCL);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_GOTCH);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_RNBC);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_RUC);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_RFC);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_ROC);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_RJC);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_TORL);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_TORH);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_TOTL);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_TOTH);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_TPR);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_TPT);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_MPTC);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_BPTC);
   end E1000e_Clear_Hw_Cntrs_Base;




   ------------------------------
   -- E1000_Clear_VFTA_Generic --
   ------------------------------

   --  Clear VLAN filter table.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Clears the register array which contains the VLAN filter table by
   --  *  setting all the values to 0.


   procedure E1000_Clear_VFTA_Generic
     (HW : access E1000_HW)
   is
   begin
      for Offset in 0 .. u32 (E1000_VLAN_FILTER_TBL_SIZE) - 1
      loop
         E1000_WRITE_REG_ARRAY (HW,
                                Devices.e1000e.Registers.E1000_VFTA,
                                Offset,
                                0);
         E1E_Flush (Hw);
      end loop;
   end E1000_Clear_VFTA_Generic;




   --------------------------
   -- e1000e_Init_Rx_Addrs --
   --------------------------

   --  Initialize receive address's.
   --
   --  *  @hw:        Pointer to the HW structure.
   --  *  @rar_count: Receive address registers.
   --  *
   --  *  Setup the receive address registers by setting the base receive address
   --  *  register to the devices MAC address and clearing all the other receive
   --  *  address registers to 0.


   procedure e1000e_Init_Rx_Addrs
     (HW        : access E1000_HW;
      RAR_Count : in     u16)
   is
      MAC_Addr : u8_array (0 .. ETH_ALEN - 1) := [others => 0];
      Unused   : C.int;
   begin
      -- Setup the receive address.
      --
      e_dbg ("Programming MAC Address into RAR[0]");

      Unused := HW.Mac.Ops.RAR_Set (HW,
                                    HW.Mac.Addr (0)'Access,
                                    0);

      -- Zero out the other (RAR_Count - 1) receive addresses.
      --
      e_dbg ("Clearing RAR[1-" & u16'Image (RAR_Count - 1) & "]");

      for I in 1 .. u32 (RAR_Count) - 1
      loop
         Unused := HW.Mac.Ops.RAR_Set (HW,
                                       MAC_Addr (0)'unchecked_Access,
                                       I);
      end loop;
   end e1000e_Init_Rx_Addrs;





   -----------------------------
   -- E1000e_Put_Hw_Semaphore --
   -----------------------------

   --  Release hardware semaphore.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Release hardware semaphore used to access the PHY or NVM


   procedure E1000e_Put_Hw_Semaphore
     (Hw : access E1000_Hw)
   is
      Swsm : u32;
   begin
      Swsm := Er32 (Hw.all, Devices.e1000e.Registers.E1000_SWSM);
      Swsm := Swsm and not (E1000_SWSM_SMBI or E1000_SWSM_SWESMBI);

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_SWSM, Swsm);
   end E1000e_Put_Hw_Semaphore;





   --------------------------------------
   -- E1000_Check_Alt_Mac_Addr_Generic --
   --------------------------------------

   --  Check for alternate MAC addr.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Checks the nvm for an alternate MAC address.  An alternate MAC address
   --  *  can be setup by pre-boot software and must be treated like a permanent
   --  *  address and must override the actual permanent MAC address. If an
   --  *  alternate MAC address is found it is programmed into RAR0, replacing
   --  *  the permanent address that was installed into RAR0 by the Si on reset.
   --  *  This function will return SUCCESS unless it encounters an error while
   --  *  reading the EEPROM.


   function E1000_Check_Alt_Mac_Addr_Generic
     (HW : access E1000_HW) return s32
   is
      I                       :         C.size_t := 0;
      Ret_Val                 :         s32;
      Offset                  :         Unsigned_16;
      NVM_Alt_Mac_Addr_Offset : aliased Unsigned_16;
      NVM_Data                : aliased Unsigned_16;
      Alt_Mac_Addr            :         u8_array (0 .. ETH_ALEN - 1);
      Unused                  :         C.int;

   begin
      Ret_Val := E1000_Read_NVM (HW,
                                 NVM_COMPAT,
                                 1,
                                 NVM_Data'unchecked_Access);
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;

      -- Not supported on 82573.
      --
      if HW.Mac.Mac_Type = E1000_82573
      then
         return 0;
      end if;


      Ret_Val := E1000_Read_NVM (HW,
                                 NVM_ALT_MAC_ADDR_PTR,
                                 1,
                                 NVM_Alt_Mac_Addr_Offset'unchecked_Access);
      if Ret_Val /= 0
      then
         e_dbg ("NVM Read Error");
         return Ret_Val;
      end if;


      if   NVM_Alt_Mac_Addr_Offset = 16#FFFF#
        or NVM_Alt_Mac_Addr_Offset = 16#0000#
      then
         -- There is no Alternate MAC Address.
         --
         return 0;
      end if;


      if HW.Bus.Func = E1000_FUNC_1
      then
         NVM_Alt_Mac_Addr_Offset := NVM_Alt_Mac_Addr_Offset + E1000_ALT_MAC_ADDRESS_OFFSET_LAN1;
      end if;


      while I < ETH_ALEN
      loop
         Offset  := NVM_Alt_Mac_Addr_Offset + shift_Right (u16 (I), 1);
         Ret_Val := E1000_Read_NVM (HW,
                                    Offset,
                                    1,
                                    NVM_Data'unchecked_Access);
         if Ret_Val /= 0
         then
            e_dbg ("NVM Read Error");
            return Ret_Val;
         end if;


         Alt_Mac_Addr (I)     := Unsigned_8 (NVM_Data and 16#FF#);
         Alt_Mac_Addr (I + 1) := Unsigned_8 (shift_Right (NVM_Data, 8));

         I := I + 2;
      end loop;


      -- If multicast bit is set, the alternate address will not be used.
      --
      if Is_Multicast_Ether_Addr (Alt_Mac_Addr (0)'unchecked_Access)
      then
         e_dbg ("Ignoring Alternate Mac Address with MC bit set");
         return 0;
      end if;


      -- We have a valid alternate MAC address, and we want to treat it the
      -- same as the normal permanent MAC address stored by the HW into the
      -- RAR. Do this by mapping this address into RAR0.
      --
      Unused := HW.Mac.Ops.Rar_Set (HW,
                                    Alt_Mac_Addr (0)'unchecked_Access,
                                    0);

      return 0;
   end E1000_Check_Alt_Mac_Addr_Generic;




   ---------------------------
   -- E1000e_Reset_Adaptive --
   ---------------------------

   --    Reset Adaptive Interframe Spacing
   --  *  @hw: pointer to the HW structure
   --  *
   --  *  Reset the Adaptive Interframe Spacing throttle to default values.


   procedure E1000e_Reset_Adaptive
     (HW : access E1000_HW)
   is
      MAC : E1000_MAC_Info.item renames HW.MAC;
   begin
      if not MAC.Adaptive_IFS
      then
         e_dbg ("Not in Adaptive IFS mode!");
         return;
      end if;

      MAC.Current_IFS_Val := 0;
      MAC.IFS_Min_Val     := IFS_MIN;
      MAC.IFS_Max_Val     := IFS_MAX;
      MAC.IFS_Step_Size   := IFS_STEP;
      MAC.IFS_Ratio       := IFS_RATIO;
      MAC.In_IFS_Mode     := False;

      ew32 (Hw.all, Devices.e1000e.Registers.E1000_AIT, 0);
   end E1000e_Reset_Adaptive;




   ------------------------------
   -- E1000e_Set_Pcie_No_Snoop --
   ------------------------------

   --    Set PCI-express capabilities.
   --
   --  *  @hw:       Pointer to the HW structure.
   --  *  @no_snoop: Bitmap of snoop events.
   --  *
   --  *  Set the PCI-express register to snoop for events enabled in 'no_snoop'.


   procedure E1000e_Set_Pcie_No_Snoop
     (Hw       : access E1000_Hw;
      No_Snoop : in     u32)
   is
      Gcr : u32;

   begin
      if No_Snoop /= 0
      then
         Gcr := Er32 (Hw.all, Devices.e1000e.Registers.E1000_GCR);
         Gcr := Gcr and not PCIE_NO_SNOOP_ALL;
         Gcr := Gcr or No_Snoop;

         Ew32 (Hw.all, Devices.e1000e.Registers.E1000_GCR, Gcr);
      end if;
   end E1000e_Set_Pcie_No_Snoop;




   ----------------------------
   -- e1000e_update_adaptive --
   ----------------------------

   --  Update Adaptive Interframe Spacing.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Update the Adaptive Interframe Spacing Throttle value based on the
   --  *  time between transmitted packets and time between collisions.


   procedure e1000e_update_adaptive
     (HW : access E1000_HW)
   is
      Mac : E1000_MAC_Info.item renames HW.Mac;

   begin
      if not Mac.Adaptive_IFS
      then
         e_dbg ("Not in Adaptive IFS mode!");
         return;
      end if;


      if Mac.Collision_Delta * u32 (Mac.IFS_Ratio) > Mac.TX_Packet_Delta
      then
         if Mac.TX_Packet_Delta > MIN_NUM_XMITS
         then
            Mac.In_IFS_Mode := True;

            if Mac.Current_IFS_Val < Mac.IFS_Max_Val
            then
               if Mac.Current_IFS_Val = 0
               then   Mac.Current_IFS_Val := Mac.IFS_Min_Val;
               else   Mac.Current_IFS_Val := Mac.Current_IFS_Val + Mac.IFS_Step_Size;
               end if;

               EW32 (Hw.all, Devices.e1000e.Registers.E1000_AIT, u32 (Mac.Current_IFS_Val));
            end if;
         end if;

      else
         if         Mac.In_IFS_Mode
           and then Mac.TX_Packet_Delta <= MIN_NUM_XMITS
         then
            Mac.Current_IFS_Val := 0;
            Mac.In_IFS_Mode     := False;

            EW32 (Hw.all, Devices.e1000e.Registers.E1000_AIT, 0);
         end if;
      end if;
   end e1000e_update_adaptive;




   ------------------------------
   -- E1000_Write_VFTA_Generic --
   ------------------------------

   --  Write value to VLAN filter table.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset in VLAN filter table.
   --  *  @value:  Register value written to VLAN filter table.
   --  *
   --  *  Writes value at the given offset in the register array which stores
   --  *  the VLAN filter table.


   procedure E1000_Write_VFTA_Generic
     (HW     : access E1000_HW;
      Offset : in     Interfaces.Unsigned_32;
      Value  : in     Interfaces.Unsigned_32)
   is
   begin
      E1000_Write_Reg_Array (Hw, Devices.e1000e.Registers.E1000_VFTA, Offset, Value);
      E1E_Flush (Hw);
   end E1000_Write_VFTA_Generic;




   --------------------------------------
   -- e1000_Set_Lan_Id_Multi_Port_Pcie --
   --------------------------------------

   --  Set LAN id for PCIe multiple port devices
   --  *
   --  *  @hw: pointer to the HW structure
   --  *
   --  *  Determines the LAN function id by reading memory-mapped registers
   --  *  and swaps the port value if requested.


   procedure e1000_Set_Lan_Id_Multi_Port_Pcie
     (HW : access E1000_HW)
   is
      Reg : u32;
   begin
      -- The status register reports the correct function number
      -- for the device regardless of function swap state.
      --
      Reg         := Er32 (Hw.all, Devices.e1000e.Registers.E1000_STATUS);
      HW.Bus.Func := FIELD_GET (E1000_STATUS_FUNC_MASK, u16 (reg));
   end e1000_Set_Lan_Id_Multi_Port_Pcie;




   ----------------------------------
   -- E1000e_Rar_Get_Count_Generic --
   ----------------------------------

   function E1000e_Rar_Get_Count_Generic
     (HW : access E1000_HW) return u32
   is
   begin
      return u32 (HW.Mac.Rar_Entry_Count);
   end E1000e_Rar_Get_Count_Generic;




   ----------------------------
   -- E1000e_Rar_Set_Generic --
   ----------------------------

   --  Set receive address register.
   --
   --  *  @hw:    Pointer to the HW structure.
   --  *  @addr:  Pointer to the receive address.
   --  *  @index: Receive address array register.
   --  *
   --  *  Sets the receive address array register at index to the address passed
   --  *  in by addr.


   function E1000e_Rar_Set_Generic
     (Hw    : access E1000_Hw;
      Addr  : in     u8_Pointer;
      Index : in     Unsigned_32) return C.int
   is
      Rar_Low,
      Rar_High : Unsigned_32;
      Address  : u8_array (0 .. 5)
        with
          Address => Addr.all'Address;

   begin
      -- HW expects these in little endian so we reverse the byte order
      -- from network order (big endian) to little endian.
      --
      Rar_Low  :=                Unsigned_32 (Address (0))
                  or shift_Left (Unsigned_32 (Address (1)),  8)
                  or shift_Left (Unsigned_32 (Address (2)), 16)
                  or shift_Left (Unsigned_32 (Address (3)), 24);

      Rar_High :=                Unsigned_32 (Address (4))
                  or shift_Left (Unsigned_32 (Address (5)),  8);

      -- If MAC address zero, no need to set the AV bit.
      --
      if   Rar_Low  /= 0
        or Rar_High /= 0
      then
         Rar_High := Rar_High or E1000_RAH_AV;
      end if;

      -- Some bridges will combine consecutive 32-bit writes into
      -- a single burst write, which will malfunction on some parts.
      -- The flushes avoid this.
      --
      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_RAL (Index), Rar_Low);
      E1E_Flush (Hw);

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_RAH (Index), Rar_High);
      E1E_Flush (Hw);

      return 0;
   end E1000e_Rar_Set_Generic;




   ------------------------------------------
   -- E1000e_Config_Collision_Dist_Generic --
   ------------------------------------------

   --  Configure collision distance.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Configures the collision distance to the default value and is used
   --  *  during link setup.


   procedure E1000e_Config_Collision_Dist_Generic
     (HW : access E1000_HW)
   is
      TCTL : Unsigned_32;

   begin
      TCTL := ER32 (Hw.all, Devices.e1000e.Registers.E1000_TCTL);

      TCTL := TCTL and (not E1000_TCTL_COLD);
      TCTL := TCTL or shift_Left (E1000_COLLISION_DISTANCE, E1000_COLD_SHIFT);

      EW32 (Hw.all, Devices.e1000e.Registers.E1000_TCTL, TCTL);
      E1E_Flush (Hw);
   end E1000e_Config_Collision_Dist_Generic;


end Devices.e1000e.Media_Access_Control;
