
with
     Devices.e1000e.Registers,
     Devices.e1000e.Hardware.e1000_phy_info,
     Devices.e1000e.Hardware.e1000_mac_info,
     Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u32_arg3_u16_array_return_s32,
     Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32,
     Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_bool_return_s32,
     Devices.e1000e.Media_Access_Control,
     Devices.e1000e.Ich8Lan,
     Devices.e1000e.Base.Port,
     Linux;



package body Devices.e1000e.Physical_Layer
is
   use Devices.e1000e.Media_Access_Control,
       Devices.e1000e.Base,
       Devices.e1000e.Base.Port,
       Linux;



   function E1000_Wait_Autoneg (HW : access E1000_HW) return S32;

   function E1000_Access_PHY_Wakeup_Reg_BM (HW       : access E1000_HW;
                                            Offset   :        U32;
                                            Data     : in     u16_Pointer;
                                            Read     :        Boolean;
                                            Page_Set :        Boolean) return S32;

   function E1000_Get_PHY_Addr_For_HV_Page (Page : U32) return U32;

   function E1000_Access_PHY_Debug_Regs_HV (HW     : access E1000_HW;
                                            Offset : in     U32;
                                            Data   : in     u16_Pointer;
                                            Read   : in     Boolean) return S32;


   -------------------------
   -- Cable length tables --
   -------------------------


   --  E1000_CABLE_LENGTH_UNDEFINED : constant := 16#FFFF#;

   E1000_M88_Cable_Length_Table : constant array (0 .. 6) of Unsigned_16
     := [0, 50, 80, 110, 140, 140, E1000_CABLE_LENGTH_UNDEFINED];

   M88E1000_CABLE_LENGTH_TABLE_SIZE : constant := E1000_M88_Cable_Length_Table'Length;     -- TODO: Check ARRAY_SIZE gives same as 'Length.

   E1000_IGP_2_Cable_Length_Table : constant array (0 .. 112) of Unsigned_16
     := [0, 0, 0, 0, 0, 0, 0, 0, 3, 5, 8, 11, 13, 16, 18, 21, 0, 0, 0, 3,
         6, 10, 13, 16, 19, 23, 26, 29, 32, 35, 38, 41, 6, 10, 14, 18, 22,
         26, 30, 33, 37, 41, 44, 48, 51, 54, 58, 61, 21, 26, 31, 35, 40,
         44, 49, 53, 57, 61, 65, 68, 72, 75, 79, 82, 40, 45, 51, 56, 61,
         66, 70, 75, 79, 83, 87, 91, 94, 98, 101, 104, 60, 66, 72, 77, 82,
         87, 92, 96, 100, 104, 108, 111, 114, 117, 119, 121, 83, 89, 95,
         100, 105, 109, 113, 116, 119, 122, 124, 104, 109, 114, 118, 121, 124];

   IGP02E1000_CABLE_LENGTH_TABLE_SIZE : constant := E1000_IGP_2_Cable_Length_Table'Length;     -- TODO: Check ARRAY_SIZE gives same as 'Length.





   ------------------------------------------------------------------------------------
   --                                 Private Subprograms                            --
   ------------------------------------------------------------------------------------



   -----------------------------
   -- E1000e_Read_Phy_Reg_Igp --
   -----------------------------

   --  Read igp PHY register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to be read.
   --  *  @data:   Pointer to the read data.
   --  *  @locked: Semaphore has already been acquired or not.
   --  *
   --  *  Acquires semaphore, if necessary, then reads the PHY register at offset
   --  *  and stores the retrieved information in data.  Release any acquired
   --  *  semaphores before exiting.


   function E1000e_Read_Phy_Reg_Igp
     (Hw     : access E1000_Hw;
      Offset : in     Unsigned_32;
      Data   : in     u16_Pointer;
      Locked : in     Boolean) return s32
   is
      use type Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.item;

      Ret_Val : s32 := 0;

   begin
      if not Locked
      then
         if Hw.Phy.Ops.Acquire = null
         then
            return 0;
         end if;


         Ret_Val := Hw.Phy.Ops.Acquire (Hw);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;
      end if;


      if Offset > Max_Phy_Multi_Page_Reg
      then
         Ret_Val := E1000e_Write_Phy_Reg_Mdic (Hw,
                                               Igp01e1000_Phy_Page_Select,
                                               Unsigned_16 (Offset));
      end if;

      if Ret_Val = 0
      then
         Ret_Val := E1000e_Read_Phy_Reg_Mdic (Hw,
                                              Max_Phy_Reg_Address and Offset,
                                              Data);
      end if;

      if not Locked
      then
         Hw.Phy.Ops.Release (Hw);
      end if;

      return Ret_Val;
   end E1000e_Read_Phy_Reg_Igp;




   -----------------------
   -- Write_PHY_Reg_IGP --
   -----------------------

   --  Write igp PHY register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to write to.
   --  *  @data:   Data to write at register offset.
   --  *  @locked: Semaphore has already been acquired or not.
   --  *
   --  *  Acquires semaphore, if necessary, then writes the data to PHY register
   --  *  at the offset.  Release any acquired semaphores before exiting.


   function Write_PHY_Reg_IGP
     (HW     : access E1000_HW;
      Offset : in     U32;
      Data   : in     U16;
      Locked : in     Boolean) return S32
   is
      use type Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.item;

      Ret_Val : S32 := 0;

   begin
      if not Locked
      then
         if HW.PHY.Ops.Acquire = null
         then
            return 0;
         end if;


         Ret_Val := HW.PHY.Ops.Acquire (HW);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;
      end if;


      if Offset > MAX_PHY_MULTI_PAGE_REG
      then
         Ret_Val := e1000e_Write_PHY_Reg_MDIC (HW,
                                               IGP01E1000_PHY_PAGE_SELECT,
                                               U16 (Offset));
      end if;

      if Ret_Val = 0
      then
         Ret_Val := e1000e_Write_PHY_Reg_MDIC (HW,
                                               U32 (MAX_PHY_REG_ADDRESS and Offset),
                                               Data);
      end if;

      if not Locked
      then
         HW.PHY.Ops.Release (HW);
      end if;

      return Ret_Val;
   end Write_PHY_Reg_IGP;




   -------------------
   -- Read_KMRN_Reg --
   -------------------

   --  Read kumeran register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to be read.
   --  *  @data:   Pointer to the read data.
   --  *  @locked: Semaphore has already been acquired or not.
   --  *
   --  *  Acquires semaphore, if necessary.  Then reads the PHY register at offset
   --  *  using the kumeran interface.  The information retrieved is stored in data.
   --  *  Release any acquired semaphores before exiting.


   function Read_KMRN_Reg
     (HW     : access E1000_HW;
      Offset : in     Unsigned_32;
      Data   : in     u16_Pointer;
      Locked : in     Boolean) return s32
   is
      use type Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.item;

      KMRNCTRLSTA : Unsigned_32;
      Ret_Val     : s32        := 0;

   begin
      if not Locked
      then
         if HW.PHY.Ops.Acquire = null
         then
            return 0;
         end if;


         Ret_Val := HW.PHY.Ops.Acquire (HW);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;
      end if;


      KMRNCTRLSTA :=    shift_Left (Offset, E1000_KMRNCTRLSTA_OFFSET_SHIFT)
                     or E1000_KMRNCTRLSTA_REN;

      EW32 (Hw.all, Devices.e1000e.Registers.E1000_KMRNCTRLSTA, KMRNCTRLSTA);
      E1E_Flush (Hw);

      delay 2.0 * Microseconds;

      KMRNCTRLSTA := ER32 (Hw.all, Devices.e1000e.Registers.E1000_KMRNCTRLSTA);
      Data.all    := Unsigned_16 (KMRNCTRLSTA and 16#FFFF#);

      if not Locked
      then
         HW.PHY.Ops.Release (HW);
      end if;

      return 0;
   end Read_KMRN_Reg;




   --------------------
   -- Write_KMRN_Reg --
   --------------------

   --    Write kumeran register.
   --
   --  *  @hw:     Pointer to the HW structure
   --  *  @offset: Register offset to write to
   --  *  @data:   Data to write at register offset
   --  *  @locked: Semaphore has already been acquired or not
   --  *
   --  *  Acquires semaphore, if necessary.  Then write the data to PHY register
   --  *  at the offset using the kumeran interface.  Release any acquired semaphores
   --  *  before exiting.


   function Write_KMRN_Reg
     (HW     : access E1000_HW;
      Offset : in     Unsigned_32;
      Data   : in     Unsigned_16;
      Locked : in     Boolean) return s32
   is
      use type Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.item;

      KMRNCTRLSTA : Unsigned_32;
      Ret_Val     : s32        := 0;

   begin
      if not Locked
      then
         if HW.PHY.Ops.Acquire = null
         then
            return 0;
         end if;


         Ret_Val := HW.PHY.Ops.Acquire (HW);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;
      end if;


      KMRNCTRLSTA := Shift_Left(Offset, E1000_KMRNCTRLSTA_OFFSET_SHIFT) or Unsigned_32(Data);
      ew32 (Hw.all, Devices.e1000e.Registers.E1000_KMRNCTRLSTA, KMRNCTRLSTA);
      E1E_Flush (Hw);

      delay 2.0 * Microseconds;

      if not Locked
      then
         HW.PHY.Ops.Release (HW);
      end if;


      return 0;
   end Write_KMRN_Reg;




   ---------------------------------
   -- E1000_Set_Master_Slave_Mode --
   ---------------------------------

   --  Setup PHY for Master/slave mode.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Sets up Master/slave mode


   function E1000_Set_Master_Slave_Mode
     (HW : access E1000_HW) return s32
   is
      Ret_Val  :         s32;
      Phy_Data : aliased Unsigned_16;

   begin
      -- Resolve Master/Slave mode.
      --
      Ret_Val := E1e_Rphy (HW, MII_CTRL1000, Phy_Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- Load defaults for future use.
      --
      if (Phy_Data and CTL1000_ENABLE_MASTER) /= 0
      then
         if (Phy_Data and CTL1000_AS_MASTER) /= 0
         then
            HW.Phy.Original_MS_Type := E1000_MS_Force_Master;
         else
            HW.Phy.Original_MS_Type := E1000_MS_Force_Slave;
         end if;

      else
         HW.Phy.Original_MS_Type := E1000_MS_Auto;
      end if;


      case HW.Phy.MS_Type
      is
         when E1000_MS_Force_Master =>
            Phy_Data := Phy_Data or (CTL1000_ENABLE_MASTER or CTL1000_AS_MASTER);

         when E1000_MS_Force_Slave =>
            Phy_Data := (Phy_Data or CTL1000_ENABLE_MASTER) and (not CTL1000_AS_MASTER);

         when E1000_MS_Auto =>
            Phy_Data := Phy_Data and (not CTL1000_ENABLE_MASTER);

         when others =>
            null;
      end case;


      return E1e_Wphy (HW, MII_CTRL1000, Phy_Data);
   end E1000_Set_Master_Slave_Mode;




   -----------------------------
   -- E1000_PHY_Setup_Autoneg --
   -----------------------------

   --  Configure PHY for auto-negotiation.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Reads the MII auto-neg advertisement register and/or the 1000T control
   --  *  register and if the PHY is already setup for auto-negotiation, then
   --  *  return successful.  Otherwise, setup advertisement and flow control to
   --  *  the appropriate values for the wanted auto-negotiation.


   function E1000_PHY_Setup_Autoneg
     (HW : access E1000_HW) return s32
   is
      PHY                 :         E1000_PHY_Info.item renames HW.PHY;
      Ret_Val             :         s32;
      MII_Autoneg_Adv_Reg : aliased Unsigned_16;
      MII_1000t_Ctrl_Reg  : aliased Unsigned_16 := 0;

   begin
      PHY.Autoneg_Advertised :=     PHY.Autoneg_Advertised
                                and PHY.Autoneg_Mask;

      -- Read the MII Auto-Neg Advertisement Register (Address 4).
      --
      Ret_Val := E1E_RPHY (HW, MII_ADVERTISE, MII_Autoneg_Adv_Reg'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      if (PHY.Autoneg_Mask and ADVERTISE_1000_FULL) /= 0
      then
         -- Read the MII 1000Base-T Control Register (Address 9).
         --
         Ret_Val := E1E_RPHY (HW, MII_CTRL1000, MII_1000t_Ctrl_Reg'unchecked_Access);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;
      end if;


      -- Need to parse both autoneg_advertised and fc and set up
      -- the appropriate PHY registers.  First we will parse for
      -- autoneg_advertised software override.  Since we can advertise
      -- a plethora of combinations, we need to check each bit
      -- individually.
      --
      --
      -- First we clear all the 10/100 mb speed bits in the Auto-Neg
      -- Advertisement Register (Address 4) and the 1000 mb speed bits in
      -- the  1000Base-T Control Register (Address 9).
      --
      MII_Autoneg_Adv_Reg := MII_Autoneg_Adv_Reg and not (   ADVERTISE_100FULL
                                                          or ADVERTISE_100HALF
                                                          or ADVERTISE_10FULL
                                                          or ADVERTISE_10HALF);

      MII_1000t_Ctrl_Reg  := MII_1000t_Ctrl_Reg  and not (   ADVERTISE_1000HALF
                                                          or ADVERTISE_1000FULL);

      e_dbg ("autoneg_advertised" & PHY.Autoneg_Advertised'Image);

      -- Set advertisement bits based on autoneg_advertised.
      --
      if (PHY.Autoneg_Advertised and ADVERTISE_10_HALF) /= 0
      then
         e_dbg ("Advertise 10mb Half duplex");
         MII_Autoneg_Adv_Reg := MII_Autoneg_Adv_Reg or ADVERTISE_10HALF;
      end if;

      if (PHY.Autoneg_Advertised and ADVERTISE_10_FULL) /= 0
      then
         e_dbg ("Advertise 10mb Full duplex");
         MII_Autoneg_Adv_Reg := MII_Autoneg_Adv_Reg or ADVERTISE_10FULL;
      end if;

      if (PHY.Autoneg_Advertised and ADVERTISE_100_HALF) /= 0
      then
         e_dbg ("Advertise 100mb Half duplex");
         MII_Autoneg_Adv_Reg := MII_Autoneg_Adv_Reg or ADVERTISE_100HALF;
      end if;

      if (PHY.Autoneg_Advertised and ADVERTISE_100_FULL) /= 0
      then
         e_dbg ("Advertise 100mb Full duplex");
         MII_Autoneg_Adv_Reg := MII_Autoneg_Adv_Reg or ADVERTISE_100FULL;
      end if;

      if (PHY.Autoneg_Advertised and ADVERTISE_1000_HALF) /= 0
      then
         e_dbg ("Advertise 1000mb Half duplex request denied!");
      end if;

      if (PHY.Autoneg_Advertised and ADVERTISE_1000_FULL) /= 0
      then
         e_dbg ("Advertise 1000mb Full duplex");
         MII_1000t_Ctrl_Reg := MII_1000t_Ctrl_Reg or ADVERTISE_1000FULL;
      end if;


      -- Check for a software override of the flow control settings, and
      -- setup the PHY advertisement registers accordingly.  If
      -- auto-negotiation is enabled, then software will have to set the
      -- "PAUSE" bits to the correct value in the Auto-Negotiation
      -- Advertisement Register (MII_ADVERTISE) and re-start auto-
      -- negotiation.
      --
      -- The possible values of the "fc" parameter are:
      --
      --      0:  Flow control is completely disabled
      --      1:  Rx flow control is enabled (we can receive pause frames
      --          but not send pause frames).
      --      2:  Tx flow control is enabled (we can send pause frames
      --          but we do not support receiving pause frames).
      --      3:  Both Rx and Tx flow control (symmetric) are enabled.
      --  other:  No software override.  The flow control configuration
      --          in the EEPROM is used.
      --
      case HW.FC.Current_Mode
      is
         when E1000_FC_None =>
            -- Flow control (Rx & Tx) is completely disabled by a software over-ride.
            --
            MII_Autoneg_Adv_Reg    := MII_Autoneg_Adv_Reg    and not (ADVERTISE_PAUSE_ASYM or ADVERTISE_PAUSE_CAP);
            PHY.Autoneg_Advertised := PHY.Autoneg_Advertised and not (ADVERTISED_Pause     or ADVERTISED_Asym_Pause);

         when E1000_FC_RX_Pause =>
            -- Rx Flow control is enabled, and Tx Flow control is
            -- disabled, by a software over-ride.
            --
            -- Since there really isn't a way to advertise that we are
            -- capable of Rx Pause ONLY, we will advertise that we
            -- support both symmetric and asymmetric Rx PAUSE.  Later
            -- (in e1000e_config_fc_after_link_up) we will disable the
            -- hw's ability to send PAUSE frames.
            --
            MII_Autoneg_Adv_Reg    := MII_Autoneg_Adv_Reg    or (ADVERTISE_PAUSE_ASYM or ADVERTISE_PAUSE_CAP);
            PHY.Autoneg_Advertised := PHY.Autoneg_Advertised or (ADVERTISED_Pause     or ADVERTISED_Asym_Pause);

         when E1000_FC_TX_Pause =>
            -- Tx Flow control is enabled, and Rx Flow control is disabled, by a software over-ride.
            --
            MII_Autoneg_Adv_Reg    := (MII_Autoneg_Adv_Reg    or ADVERTISE_PAUSE_ASYM)  and not ADVERTISE_PAUSE_CAP;
            PHY.Autoneg_Advertised := (PHY.Autoneg_Advertised or ADVERTISED_Asym_Pause) and not ADVERTISED_Pause;

         when E1000_FC_Full =>
            -- Flow control (both Rx and Tx) is enabled by a software over-ride.
            --
            MII_Autoneg_Adv_Reg    := MII_Autoneg_Adv_Reg    or (ADVERTISE_PAUSE_ASYM or ADVERTISE_PAUSE_CAP);
            PHY.Autoneg_Advertised := PHY.Autoneg_Advertised or (ADVERTISED_Pause     or ADVERTISED_Asym_Pause);

         when others =>
            e_dbg ("Flow control param set incorrectly");
            return -E1000_ERR_CONFIG;
      end case;


      Ret_Val := E1E_WPHY (HW, MII_ADVERTISE, MII_Autoneg_Adv_Reg);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      e_dbg ("Auto-Neg Advertising" & MII_Autoneg_Adv_Reg'Image);

      if (PHY.Autoneg_Mask and ADVERTISE_1000_FULL) /= 0
      then
         Ret_Val := E1E_WPHY (HW, MII_CTRL1000, MII_1000t_Ctrl_Reg);
      end if;

      return Ret_Val;
   end E1000_PHY_Setup_Autoneg;




   -------------------------------
   -- E1000_Copper_Link_Autoneg --
   -------------------------------

   --  Setup/Enable autoneg for copper link.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Performs initial bounds checking on autoneg advertisement parameter, then
   --  *  configure to advertise the full capability.  Setup the PHY to autoneg
   --  *  and restart the negotiation process between the link partner.  If
   --  *  autoneg_wait_to_complete, then wait for autoneg to complete before exiting.


   function E1000_Copper_Link_Autoneg
     (HW : access E1000_HW) return s32
   is
      PHY      : E1000_PHY_Info.item renames HW.PHY;
      Ret_Val  : s32;
      PHY_Ctrl : aliased u16;

   begin
      -- Perform some bounds checking on the autoneg advertisement parameter.
      --
      PHY.Autoneg_Advertised := PHY.Autoneg_Advertised and PHY.Autoneg_Mask;

      -- If autoneg_advertised is zero, we assume it was not defaulted
      -- by the calling code so we set to advertise full capability.
      --
      if PHY.Autoneg_Advertised = 0
      then
         PHY.Autoneg_Advertised := PHY.Autoneg_Mask;
      end if;

      e_dbg ("Reconfiguring auto-neg advertisement params");

      Ret_Val := E1000_PHY_Setup_Autoneg (HW);

      if Ret_Val /= 0
      then
         e_dbg ("Error Setting up Auto-Negotiation");
         return Ret_Val;
      end if;


      e_dbg ("Restarting Auto-Neg");

      -- Restart auto-negotiation by setting the Auto Neg Enable bit and
      -- the Auto Neg Restart bit in the PHY control register.
      --
      Ret_Val := E1e_Rphy (HW, MII_BMCR, PHY_Ctrl'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;

      PHY_Ctrl := PHY_Ctrl or (BMCR_ANENABLE or BMCR_ANRESTART);
      Ret_Val  := E1e_Wphy (HW, MII_BMCR, PHY_Ctrl);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;

      -- Does the user want to wait for Auto-Neg to complete here, or
      -- check at a later time (for example, callback routine).
      --
      if PHY.Autoneg_Wait_To_Complete
      then
         Ret_Val := E1000_Wait_Autoneg (HW);

         if Ret_Val /= 0
         then
            e_dbg ("Error while waiting for autoneg to complete");
            return Ret_Val;
         end if;
      end if;


      HW.MAC.Get_Link_Status := True;

      return Ret_Val;
   end E1000_Copper_Link_Autoneg;




   ------------------------
   -- E1000_Wait_Autoneg --
   ------------------------

   --  Wait for auto-neg completion.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Waits for auto-negotiation to complete or for the auto-negotiation time
   --  *  limit to expire, which ever happens first.


   function E1000_Wait_Autoneg
     (Hw : access E1000_Hw) return s32
   is
      Ret_Val    :         s32        := 0;
      Phy_Status : aliased Unsigned_16;

   begin
      -- Break after autoneg completes or PHY_AUTO_NEG_LIMIT expires.
      --
      for I in reverse 1 .. PHY_AUTO_NEG_LIMIT
      loop
         Ret_Val := E1e_Rphy (Hw, MII_BMSR, Phy_Status'unchecked_Access);

         if Ret_Val /= 0
         then
            exit;
         end if;

         Ret_Val := E1e_Rphy (Hw, MII_BMSR, Phy_Status'unchecked_Access);

         if Ret_Val /= 0
         then
            exit;
         end if;

         if (Phy_Status and BMSR_ANEGCOMPLETE) /= 0
         then
            exit;
         end if;

         delay 100.0 * Milliseconds;  -- Equivalent to msleep(100)
      end loop;


      -- PHY_AUTO_NEG_TIME expiration doesn't guarantee auto-negotiation
      -- has completed.
      --
      return Ret_Val;
   end E1000_Wait_Autoneg;




   ------------------------------------
   -- E1000_Get_Phy_Addr_For_Bm_Page --
   ------------------------------------

   --  Retrieve PHY page address.
   --
   --  *  @page: Page to access.
   --  *  @reg:  Register to check.
   --  *
   --  *  Returns the phy address for the page requested.


   function E1000_Get_Phy_Addr_For_Bm_Page
     (Page : Unsigned_32;
      Reg  : Unsigned_32) return u32
   is
      Phy_Addr : Unsigned_32 := 2;

   begin
      if    Page >= 768
        or (Page  = 0 and Reg = 25)
        or  Reg   = 31
      then
         Phy_Addr := 1;
      end if;

      return Phy_Addr;
   end E1000_Get_Phy_Addr_For_Bm_Page;




   ------------------------------------
   -- E1000_Access_Phy_Wakeup_Reg_Bm --
   ------------------------------------

   --    Read/write BM PHY wakeup register.
   --
   --  *  @hw:       Pointer to the HW structure
   --  *  @offset:   Register offset to be read or written
   --  *  @data:     Pointer to the data to read or write
   --  *  @read:     Determines if operation is read or write
   --  *  @page_set: BM_WUC_PAGE already set and access enabled
   --  *
   --  *  Read the PHY register at offset and store the retrieved information in
   --  *  data, or write data to PHY register at offset.  Note the procedure to
   --  *  access the PHY wakeup registers is different than reading the other PHY
   --  *  registers. It works as such:
   --  *  1) Set 769.17.2 (page 769, register 17, bit 2) = 1
   --  *  2) Set page to 800 for host (801 if we were manageability)
   --  *  3) Write the address using the address opcode (0x11)
   --  *  4) Read or write the data using the data opcode (0x12)
   --  *  5) Restore 769.17.2 to its original value
   --  *
   --  *  Steps 1 and 2 are done by e1000_enable_phy_wakeup_reg_access_bm() and
   --  *  step 5 is done by e1000_disable_phy_wakeup_reg_access_bm().
   --  *
   --  *  Assumes semaphore is already acquired.  When page_set==true, assumes
   --  *  the PHY page is set to BM_WUC_PAGE (i.e. a function in the call stack
   --  *  is responsible for calls to e1000_[enable|disable]_phy_wakeup_reg_bm()).


   function E1000_Access_Phy_Wakeup_Reg_Bm
     (HW        : access E1000_HW;
      Offset    : in     u32;
      Data      : in     u16_Pointer;
      Read      : in     Boolean;
      Page_Set  : in     Boolean) return s32
   is
      Ret_Val   :         s32;
      Reg       : constant u16 := BM_PHY_REG_NUM  (Offset);
      Page      : constant u16 := BM_PHY_REG_PAGE (Offset);
      Phy_Reg   : aliased  u16 := 0;

   begin
      -- Gig must be disabled for MDIO accesses to Host Wakeup reg page.
      --
      if          HW.Mac.mac_type = E1000_Pchlan
        and then (     Er32 (Hw.all, Devices.e1000e.Registers.E1000_PHY_CTRL)
                   and E1000_PHY_CTRL_GBE_DISABLE) = 0
      then
         e_dbg ("Attempting to access page" & Page'Image & " while gig enabled.");
      end if;

      if not Page_Set
      then
         -- Enable access to PHY wakeup registers.
         --
         Ret_Val := E1000_Enable_Phy_Wakeup_Reg_Access_Bm (HW, Phy_Reg'unchecked_Access);

         if Ret_Val /= 0
         then
            e_dbg ("Could not enable PHY wakeup reg access");
            return Ret_Val;
         end if;
      end if;


      e_dbg ("Accessing PHY page" & Page'Image & " reg " & Reg'Image);

      -- Write the Wakeup register page offset value using opcode 0x11.
      --
      Ret_Val := E1000e_Write_Phy_Reg_Mdic (HW, BM_WUC_ADDRESS_OPCODE, Reg);

      if Ret_Val /= 0
      then
         e_dbg ("Could not write address opcode to page" & Page'Image);
         return Ret_Val;
      end if;


      if Read
      then
         -- Read the Wakeup register page value using opcode 0x12.
         --
         Ret_Val := E1000e_Read_Phy_Reg_Mdic (HW, BM_WUC_DATA_OPCODE, Data);
      else
         -- Write the Wakeup register page value using opcode 0x12.
         --
         Ret_Val := E1000e_Write_Phy_Reg_Mdic (HW, BM_WUC_DATA_OPCODE, Data.all);
      end if;

      if Ret_Val /= 0
      then
         e_dbg ("Could not access PHY reg" & Page'Image & "." & Reg'Image);
         return Ret_Val;
      end if;


      if not Page_Set
      then
         Ret_Val := E1000_Disable_Phy_Wakeup_Reg_Access_Bm (HW, Phy_Reg'unchecked_Access);
      end if;

      return Ret_Val;
   end E1000_Access_Phy_Wakeup_Reg_Bm;




   ---------------------------
   -- E1000_Read_Phy_Reg_Hv --
   ---------------------------

   --    Read HV PHY register.
   --
   --  *  @hw:       Pointer to the HW structure
   --  *  @offset:   Register offset to be read
   --  *  @data:     Pointer to the read data
   --  *  @locked:   Semaphore has already been acquired or not
   --  *  @page_set: BM_WUC_PAGE already set and access enabled
   --  *
   --  *  Acquires semaphore, if necessary, then reads the PHY register at offset
   --  *  and stores the retrieved information in data.  Release any acquired
   --  *  semaphore before exiting.


   function E1000_Read_Phy_Reg_Hv
     (HW        : access E1000_HW;
      Offset    : in     Unsigned_32;
      Data      : in     u16_Pointer;
      Locked    : in     Boolean;
      Page_Set  : in     Boolean) return s32
   is
      Ret_Val   :          s32;
      Page      :          Unsigned_16 := BM_PHY_REG_PAGE (Offset);
      Reg       : constant Unsigned_16 := BM_PHY_REG_NUM  (Offset);
      Phy_Addr  :          Unsigned_32;

   begin
      HW.Phy.Addr := E1000_Get_Phy_Addr_For_Hv_Page (u32 (Page));
      Phy_Addr    := HW.Phy.Addr;

      if not Locked
      then
         Ret_Val := HW.Phy.Ops.Acquire (HW);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;
      end if;


      -- Page 800 works differently than the rest so it has its own func.
      --
      if Page = BM_WUC_PAGE
      then
         Ret_Val := E1000_Access_Phy_Wakeup_Reg_Bm (HW, Offset, Data, True, Page_Set);
         goto Exit_Function;
      end if;


      if    Page > 0
        and Page < HV_INTC_FC_PAGE_START
      then
         Ret_Val := E1000_Access_Phy_Debug_Regs_Hv (HW, Offset, Data, True);
         goto Exit_Function;
      end if;


      if not Page_Set
      then
         if Page = HV_INTC_FC_PAGE_START
         then
            Page := 0;
         end if;

         if Reg > MAX_PHY_MULTI_PAGE_REG
         then
            -- Page is shifted left, PHY expects (page x 32).
            --
            Ret_Val     := E1000_Set_Page_Igp (HW, Interfaces.Shift_Left(Page, IGP_PAGE_SHIFT));
            HW.Phy.Addr := Phy_Addr;

            if Ret_Val /= 0
            then
               goto Exit_Function;
            end if;

         end if;
      end if;


      e_dbg ("reading PHY page" & Page'Image & " (or" & shift_Left (Page, IGP_PAGE_SHIFT)'Image & " shifted) reg" & Reg'Image);

      Ret_Val := E1000e_Read_Phy_Reg_Mdic (HW,
                                           MAX_PHY_REG_ADDRESS and u32 (Reg),
                                           Data);

      <<Exit_Function>>

      if not Locked
      then
         HW.Phy.Ops.Release (HW);
      end if;

      return Ret_Val;
   end E1000_Read_Phy_Reg_Hv;




   ----------------------------
   -- E1000_Write_PHY_Reg_HV --
   ----------------------------

   --    Write HV PHY register.
   --
   --  *  @hw:       Pointer to the HW structure
   --  *  @offset:   Register offset to write to
   --  *  @data:     Data to write at register offset
   --  *  @locked:   Semaphore has already been acquired or not
   --  *  @page_set: BM_WUC_PAGE already set and access enabled
   --  *
   --  *  Acquires semaphore, if necessary, then writes the data to PHY register
   --  *  at the offset.  Release any acquired semaphores before exiting.


   function E1000_Write_PHY_Reg_HV
     (HW        : access E1000_HW;
      Offset    : in     Unsigned_32;
      Data      : in     Unsigned_16;
      Locked    : in     Boolean;
      Page_Set  : in     Boolean) return s32
   is
      Ret_Val   :          s32;
      Page      :          Unsigned_16 := BM_PHY_REG_PAGE (Offset);
      Reg       : constant Unsigned_16 := BM_PHY_REG_NUM  (Offset);
      PHY_Addr  :          Unsigned_32;

   begin
      HW.PHY.Addr := E1000_Get_PHY_Addr_For_HV_Page (u32 (Page));
      PHY_Addr    := HW.PHY.Addr;

      if not Locked
      then
         Ret_Val := HW.PHY.Ops.Acquire (HW);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;
      end if;


      -- Page 800 works differently than the rest so it has its own func.
      --
      if Page = BM_WUC_PAGE
      then
         Ret_Val := E1000_Access_PHY_Wakeup_Reg_BM (HW,
                                                    Offset,
                                                    Data'unrestricted_Access,
                                                    False,
                                                    Page_Set);
         goto Exit_Function;
      end if;


      if    Page > 0
        and Page < HV_INTC_FC_PAGE_START
      then
         Ret_Val := E1000_Access_PHY_Debug_Regs_HV (HW,
                                                    Offset,
                                                    Data'unrestricted_Access,
                                                    False);
         goto Exit_Function;
      end if;


      if not Page_Set
      then
         if Page = HV_INTC_FC_PAGE_START
         then
            Page := 0;
         end if;

         -- Workaround MDIO accesses being disabled after entering IEEE
         -- Power Down (when bit 11 of the PHY Control register is set).
         --
         if    HW.PHY.phy_type  = E1000_PHY_82578
           and HW.PHY.Revision >= 1
           and HW.PHY.Addr      = 2
           and (MAX_PHY_REG_ADDRESS and Reg) = 0
           and (Data and BIT (11))          /= 0
         then
            declare
               Data2 : aliased Unsigned_16 := 16#7EFF#;
            begin
               Ret_Val := E1000_Access_PHY_Debug_Regs_HV (HW,
                                                          BIT (6) or 16#3#,
                                                          Data2'unchecked_Access,
                                                          False);
               if Ret_Val /= 0
               then
                  goto Exit_Function;
               end if;
            end;
         end if;


         if Reg > MAX_PHY_MULTI_PAGE_REG
         then
            -- Page is shifted left, PHY expects (page x 32).
            --
            Ret_Val     := E1000_Set_Page_IGP (HW,
                                               shift_Left (Page, IGP_PAGE_SHIFT));
            HW.PHY.Addr := PHY_Addr;

            if Ret_Val /= 0
            then
               goto Exit_Function;
            end if;

         end if;
      end if;


      e_dbg (  "writing PHY page" & Page'Image
             & " (or"             & shift_Left (Page, IGP_PAGE_SHIFT)'Image
             & " shifted) reg"    & Reg'Image);

      Ret_Val := E1000E_Write_PHY_Reg_MDIC (HW,
                                            u32 (MAX_PHY_REG_ADDRESS and Reg),
                                            Data);

      <<Exit_Function>>

      if not Locked
      then
         HW.PHY.Ops.Release (HW);
      end if;

      return Ret_Val;
   end E1000_Write_PHY_Reg_HV;




   ------------------------------------
   -- E1000_Get_Phy_Addr_For_Hv_Page --
   ------------------------------------

   --  Get PHY address based on page.
   --
   --  *  @page: Page to be accessed.


   function E1000_Get_Phy_Addr_For_Hv_Page
     (Page : in u32) return u32
   is
      Phy_Addr : u32 := 2;

   begin
      if Page >= HV_INTC_FC_PAGE_START
      then
         Phy_Addr := 1;
      end if;

      return Phy_Addr;
   end E1000_Get_Phy_Addr_For_Hv_Page;




   ------------------------------------
   -- E1000_Access_PHY_Debug_Regs_HV --
   ------------------------------------

   --    Read HV PHY vendor specific high registers.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to be read or written.
   --  *  @data:   Pointer to the data to be read or written.
   --  *  @read:   Determines if operation is read or write.
   --  *
   --  *  Reads the PHY register at offset and stores the retrieved information
   --  *  in data.  Assumes semaphore already acquired.  Note that the procedure
   --  *  to access these regs uses the address port and data port to read/write.
   --  *  These accesses done with PHY address 2 and without using pages.


   function E1000_Access_PHY_Debug_Regs_HV
     (HW     : access E1000_HW;
      Offset : in     Unsigned_32;
      Data   : in     u16_Pointer;
      Read   : in     Boolean) return s32
   is
      Ret_Val  : s32;
      Addr_Reg : Unsigned_32;
      Data_Reg : Unsigned_32;

   begin
      -- This takes care of the difference with desktop vs mobile phy.
      --
      if HW.PHY.PHY_Type = E1000_PHY_82578
      then
         Addr_Reg := I82578_ADDR_REG;
      else
         Addr_Reg := I82577_ADDR_REG;
      end if;

      Data_Reg := Addr_Reg + 1;

      -- All operations in this function are phy address 2.
      --
      HW.PHY.Addr := 2;

      -- Masking with 0x3F to remove the page from offset.
      --
      Ret_Val := E1000e_Write_PHY_Reg_MDIC (HW,
                                            Addr_Reg,
                                            u16 (Offset and 16#3F#));

      if Ret_Val /= 0
      then
         e_dbg ("Could not write the Address Offset port register");
         return Ret_Val;
      end if;


      -- Read or write the data value next.
      --
      if Read
      then
         Ret_Val := E1000e_Read_PHY_Reg_MDIC (HW, Data_Reg, Data);
      else
         Ret_Val := E1000e_Write_PHY_Reg_MDIC (HW, Data_Reg, Data.all);
      end if;

      if Ret_Val /= 0
      then
         e_dbg ("Could not access the Data port register");
      end if;

      return Ret_Val;
   end E1000_Access_PHY_Debug_Regs_HV;








   -----------------------------------------------------------------------------------
   --                                 Public Subprograms                            --
   -----------------------------------------------------------------------------------



   ----------------------------
   -- E1000e_Check_Downshift --
   ----------------------------

   --  Checks whether a downshift in speed occurred.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Success returns 0, Failure returns 1
   --  *
   --  *  A downshift is detected by querying the PHY link health.


   function E1000e_Check_Downshift
     (HW : access E1000_HW) return s32
   is
      Ret_Val  :         s32;
      PHY_Data : aliased Unsigned_16;
      Offset   :         Unsigned_16;
      Mask     :         Unsigned_16;

   begin
      case HW.PHY.PHY_Type
      is
         when E1000_PHY_M88
            | E1000_PHY_GG82563
            | E1000_PHY_BM
            | E1000_PHY_82578 =>

            Offset := M88E1000_PHY_SPEC_STATUS;
            Mask   := M88E1000_PSSR_DOWNSHIFT;

         when E1000_PHY_IGP_2
            | E1000_PHY_IGP_3 =>

            Offset := IGP01E1000_PHY_LINK_HEALTH;
            Mask   := IGP01E1000_PLHR_SS_DOWNGRADE;

         when others =>
            -- Speed downshift not supported.
            --
            HW.PHY.Speed_Downgraded := False;
            return 0;
      end case;

      Ret_Val := E1e_Rphy (HW,
                           u32 (Offset),
                           PHY_Data'unchecked_Access);
      if Ret_Val = 0
      then
         HW.PHY.Speed_Downgraded := (PHY_Data and Mask) /= 0;
      end if;

      return Ret_Val;
   end E1000e_Check_Downshift;





   ------------------------------
   -- E1000_Check_Polarity_M88 --
   ------------------------------

   --  Checks the polarity.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Success returns 0, Failure returns -E1000_ERR_PHY (-2)
   --  *
   --  *  Polarity is determined based on the PHY specific status register.


   function E1000_Check_Polarity_M88
     (HW : access E1000_HW) return s32
   is
      Ret_Val :         s32;
      Data    : aliased Unsigned_16;

   begin
      Ret_Val := E1E_RPHY (HW, M88E1000_PHY_SPEC_STATUS, Data'unchecked_Access);

      if Ret_Val = 0
      then
         if (Data and M88E1000_PSSR_REV_POLARITY) /= 0
         then
            HW.PHY.Cable_Polarity := E1000_Rev_Polarity_Reversed;
         else
            HW.PHY.Cable_Polarity := E1000_Rev_Polarity_Normal;
         end if;
      end if;

      return Ret_Val;
   end E1000_Check_Polarity_M88;




   ------------------------------
   -- E1000_Check_Polarity_IGP --
   ------------------------------

   --  Checks the polarity.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Success returns 0, Failure returns -E1000_ERR_PHY (-2)
   --  *
   --  *  Polarity is determined based on the PHY port status register, and the
   --  *  current speed (since there is no polarity at 100Mbps).


   function E1000_Check_Polarity_IGP
     (HW : access E1000_HW) return s32
   is
      PHY     :         E1000_PHY_Info.item renames HW.PHY;
      Ret_Val :         s32;
      Data    : aliased Unsigned_16;
      Offset  :         Unsigned_16;
      Mask    :         Unsigned_16;

   begin
      -- Polarity is determined based on the speed of our connection.
      --
      Ret_Val := E1E_RPHY (HW, IGP01E1000_PHY_PORT_STATUS, Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      if (Data and IGP01E1000_PSSR_SPEED_MASK) = IGP01E1000_PSSR_SPEED_1000MBPS
      then
         Offset := IGP01E1000_PHY_PCS_INIT_REG;
         Mask   := IGP01E1000_PHY_POLARITY_MASK;
      else
         -- This really only applies to 10Mbps since
         -- there is no polarity for 100Mbps (always 0).
         --
         Offset := IGP01E1000_PHY_PORT_STATUS;
         Mask   := IGP01E1000_PSSR_POLARITY_REVERSED;
      end if;

      Ret_Val := E1E_RPHY (HW, u32 (Offset), Data'unchecked_Access);

      if Ret_Val = 0
      then
         PHY.Cable_Polarity := (if (Data and Mask) /= 0 then E1000_Rev_Polarity_Reversed
                                                        else E1000_Rev_Polarity_Normal);
      end if;

      return Ret_Val;
   end E1000_Check_Polarity_IGP;




   ------------------------------
   -- E1000_Check_Polarity_IFE --
   ------------------------------

   function E1000_Check_Polarity_IFE
     (HW : access E1000_HW) return s32
   is
      PHY      :         E1000_PHY_Info.item renames HW.PHY;
      Ret_Val  :         s32;
      PHY_Data : aliased Unsigned_16;
      Offset   :         u32;
      Mask     :         Unsigned_16;

   begin
      -- Polarity is determined based on the reversal feature being enabled.
      --
      if PHY.Polarity_Correction
      then
         Offset := IFE_PHY_EXTENDED_STATUS_CONTROL;
         Mask   := IFE_PESC_POLARITY_REVERSED;
      else
         Offset := IFE_PHY_SPECIAL_CONTROL;
         Mask   := IFE_PSC_FORCE_POLARITY;
      end if;

      Ret_Val := E1e_Rphy (HW, Offset, PHY_Data'unchecked_Access);

      if Ret_Val = 0
      then
         if (PHY_Data and Mask) /= 0
         then
            PHY.Cable_Polarity := E1000_Rev_Polarity_Reversed;
         else
            PHY.Cable_Polarity := E1000_Rev_Polarity_Normal;
         end if;
      end if;

      return Ret_Val;
   end E1000_Check_Polarity_IFE;




   --------------------------------------
   -- E1000e_Check_Reset_Block_Generic --
   --------------------------------------

   --  Check if PHY reset is blocked.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Read the PHY management control register and check whether a PHY reset
   --  *  is blocked.  If a reset is not blocked return 0, otherwise
   --  *  return E1000_BLK_PHY_RESET (12).


   function E1000e_Check_Reset_Block_Generic
     (Hw : access E1000_Hw) return s32
   is
      Manc : Unsigned_32;
   begin
      Manc := Er32 (Hw.all, Devices.e1000e.Registers.E1000_MANC);

      if (Manc and E1000_MANC_BLK_PHY_RST_ON_IDE) /= 0
      then
         return E1000_BLK_PHY_RESET;
      else
         return 0;
      end if;
   end E1000e_Check_Reset_Block_Generic;




   ----------------------------------
   -- E1000e_Copper_Link_Setup_IGP --
   ----------------------------------

   --  Setup igp PHY's for copper link.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Sets up LPLU, MDI/MDI-X, polarity, Smartspeed and Master/Slave config for
   --  *  igp PHY's.


   function E1000e_Copper_Link_Setup_IGP
     (HW : access E1000_HW) return s32
   is
      use type Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_bool_return_s32.item;

      PHY     :         E1000_PHY_Info.item renames HW.PHY;
      Ret_Val :         s32;
      Data    : aliased Unsigned_16;

   begin
      Ret_Val := E1000_PHY_HW_Reset (HW);

      if Ret_Val /= 0
      then
         e_dbg ("Error resetting the PHY.");
         return Ret_Val;
      end if;


      -- Wait 100ms for MAC to configure PHY from NVM settings, to avoid
      -- timeout issues when LFS is enabled.
      --
      delay 100.0 * Milliseconds;

      -- Disable lplu d0 during driver init.
      --
      if HW.PHY.Ops.Set_D0_LPLU_State /= null
      then
         Ret_Val := HW.PHY.Ops.Set_D0_LPLU_State (HW, False);

         if Ret_Val /= 0
         then
            e_dbg ("Error Disabling LPLU D0");
            return Ret_Val;
         end if;
      end if;

      -- Configure mdi-mdix settings.
      --
      Ret_Val := E1e_RPHY (HW, IGP01E1000_PHY_PORT_CTRL, Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;

      Data := Data and (not IGP01E1000_PSCR_AUTO_MDIX);

      case PHY.MDIX
      is
         when 1      =>   Data := Data and (not IGP01E1000_PSCR_FORCE_MDI_MDIX);
         when 2      =>   Data := Data or       IGP01E1000_PSCR_FORCE_MDI_MDIX;
         when others =>   Data := Data or       IGP01E1000_PSCR_AUTO_MDIX;
      end case;

      Ret_Val := E1e_WPHY (HW, IGP01E1000_PHY_PORT_CTRL, Data);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;

      -- Set auto-master slave resolution settings.
      --
      if HW.MAC.Autoneg
      then
         -- when autonegotiation advertisement is only 1000Mbps then we
         -- should disable SmartSpeed and enable Auto MasterSlave
         -- resolution as hardware default.
         --
         if PHY.Autoneg_Advertised = ADVERTISE_1000_FULL
         then
            -- Disable SmartSpeed.
            --
            Ret_Val := E1e_RPHY (HW, IGP01E1000_PHY_PORT_CONFIG, Data'unchecked_Access);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;

            Data    := Data and (not IGP01E1000_PSCFR_SMART_SPEED);
            Ret_Val := E1e_WPHY (HW, IGP01E1000_PHY_PORT_CONFIG, Data);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;

            -- Set auto Master/Slave resolution process.
            --
            Ret_Val := E1e_RPHY (HW, MII_CTRL1000, Data'unchecked_Access);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;

            Data    := Data and (not CTL1000_ENABLE_MASTER);
            Ret_Val := E1e_WPHY (HW, MII_CTRL1000, Data);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;
         end if;

         Ret_Val := E1000_Set_Master_Slave_Mode (HW);
      end if;


      return Ret_Val;
   end E1000e_Copper_Link_Setup_IGP;





   ----------------------------------
   -- E1000e_Copper_Link_Setup_M88 --
   ----------------------------------

   --  Setup m88 PHY's for copper link.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Sets up MDI/MDI-X and polarity for m88 PHY's.  If necessary, transmit clock
   --  *  and downshift values are set also.


   function E1000e_Copper_Link_Setup_M88
     (HW : access E1000_HW) return s32
   is
      use type Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.item;

      PHY      :         E1000_PHY_Info.item renames HW.PHY;
      Ret_Val  :         s32;
      PHY_Data : aliased Unsigned_16;

   begin
      -- Enable CRS on Tx. This must be set for half-duplex operation.
      --
      Ret_Val := E1e_Rphy (HW, M88E1000_PHY_SPEC_CTRL, PHY_Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- For BM PHY this bit is downshift enable.
      --
      if PHY.PHY_Type /= E1000_PHY_BM
      then
         PHY_Data := PHY_Data or M88E1000_PSCR_ASSERT_CRS_ON_TX;
      end if;

      -- Options:
      --
      --   MDI/MDI-X = 0 (default)
      --   0 - Auto for all speeds
      --   1 - MDI mode
      --   2 - MDI-X mode
      --   3 - Auto for 1000Base-T only (MDI-X for 10/100Base-T modes).
      --
      PHY_Data := PHY_Data and (not M88E1000_PSCR_AUTO_X_MODE);

      case PHY.MDIX
      is
         when 1      =>   PHY_Data := PHY_Data or M88E1000_PSCR_MDI_MANUAL_MODE;
         when 2      =>   PHY_Data := PHY_Data or M88E1000_PSCR_MDIX_MANUAL_MODE;
         when 3      =>   PHY_Data := PHY_Data or M88E1000_PSCR_AUTO_X_1000T;
         when others =>   PHY_Data := PHY_Data or M88E1000_PSCR_AUTO_X_MODE;
      end case;

      -- Options:
      --
      --   disable_polarity_correction = 0 (default)
      --       Automatic Correction for Reversed Cable Polarity
      --   0 - Disabled
      --   1 - Enabled
      --
      PHY_Data := PHY_Data and (not M88E1000_PSCR_POLARITY_REVERSAL);

      if PHY.Disable_Polarity_Correction
      then
         PHY_Data := PHY_Data or M88E1000_PSCR_POLARITY_REVERSAL;
      end if;

      -- Enable downshift on BM (disabled by default).
      --
      if PHY.PHY_Type = E1000_PHY_BM
      then
         -- For 82574/82583, first disable then enable downshift.
         --
         if PHY.ID = BME1000_E_PHY_ID_R2
         then
            PHY_Data := PHY_Data and (not BME1000_PSCR_ENABLE_DOWNSHIFT);
            Ret_Val  := E1e_Wphy (HW, M88E1000_PHY_SPEC_CTRL, PHY_Data);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;

            -- Commit the changes.
            --
            Ret_Val := PHY.Ops.Commit (HW);

            if Ret_Val /= 0
            then
               e_dbg ("Error committing the PHY changes");
               return Ret_Val;
            end if;
         end if;

         PHY_Data := PHY_Data or BME1000_PSCR_ENABLE_DOWNSHIFT;
      end if;


      Ret_Val := E1e_Wphy (HW, M88E1000_PHY_SPEC_CTRL, PHY_Data);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      if    PHY.PHY_Type = E1000_PHY_M88
        and PHY.Revision < E1000_REVISION_4
        and PHY.ID      /= BME1000_E_PHY_ID_R2
      then
         -- Force TX_CLK in the Extended PHY Specific Control Register
         -- to 25MHz clock.
         --
         Ret_Val := E1e_Rphy (HW, M88E1000_EXT_PHY_SPEC_CTRL, PHY_Data'unchecked_Access);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;

         PHY_Data := PHY_Data or M88E1000_EPSCR_TX_CLK_25;

         if    PHY.Revision = 2
           and PHY.ID       = M88E1111_I_PHY_ID
         then
            -- 82573L PHY - set the downshift counter to 5x.
            --
            PHY_Data := PHY_Data and (not M88EC018_EPSCR_DOWNSHIFT_COUNTER_MASK);
            PHY_Data := PHY_Data or M88EC018_EPSCR_DOWNSHIFT_COUNTER_5X;
         else
            -- Configure Master and Slave downshift values.
            --
            PHY_Data := PHY_Data and (not (   M88E1000_EPSCR_MASTER_DOWNSHIFT_MASK
                                           or M88E1000_EPSCR_SLAVE_DOWNSHIFT_MASK));
            PHY_Data := PHY_Data or       (   M88E1000_EPSCR_MASTER_DOWNSHIFT_1X
                                           or M88E1000_EPSCR_SLAVE_DOWNSHIFT_1X);
         end if;

         Ret_Val := E1e_Wphy (HW, M88E1000_EXT_PHY_SPEC_CTRL, PHY_Data);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;

      end if;


      if    PHY.PHY_Type = E1000_PHY_BM
        and PHY.ID       = BME1000_E_PHY_ID_R2
      then
         -- Set PHY page 0, register 29 to 0x0003.
         --
         Ret_Val := E1e_Wphy (HW, 29, 16#0003#);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;

         -- Set PHY page 0, register 30 to 0x0000.
         --
         Ret_Val := E1e_Wphy (HW, 30, 16#0000#);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;
      end if;


      -- Commit the changes.
      --
      if PHY.Ops.Commit /= null
      then
         Ret_Val := PHY.Ops.Commit (HW);

         if Ret_Val /= 0
         then
            e_dbg ("Error committing the PHY changes");
            return Ret_Val;
         end if;
      end if;

      if PHY.PHY_Type = E1000_PHY_82578
      then
         Ret_Val := E1e_Rphy (HW, M88E1000_EXT_PHY_SPEC_CTRL, PHY_Data'unchecked_Access);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;

         -- 82578 PHY - set the downshift count to 1x.
         --
         PHY_Data := PHY_Data or       I82578_EPSCR_DOWNSHIFT_ENABLE;
         PHY_Data := PHY_Data and (not I82578_EPSCR_DOWNSHIFT_COUNTER_MASK);
         Ret_Val  := E1e_Wphy (HW, M88E1000_EXT_PHY_SPEC_CTRL, PHY_Data);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;
      end if;

      return 0;
   end E1000e_Copper_Link_Setup_M88;




   ---------------------------------------
   -- E1000e_Phy_Force_Speed_Duplex_Igp --
   ---------------------------------------

   --    Force speed/duplex for igp PHY.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Calls the PHY setup function to force speed and duplex.  Clears the
   --  *  auto-crossover to force MDI manually.  Waits for link and returns
   --  *  successful if link up is successful, else -E1000_ERR_PHY (-2).


   function E1000e_Phy_Force_Speed_Duplex_Igp
     (Hw : access E1000_Hw) return s32
   is
      Phy      :         E1000_Phy_Info.item renames Hw.Phy;
      Ret_Val  :         s32;
      Phy_Data : aliased u16;
      Link     :         Boolean;

   begin
      Ret_Val := E1e_Rphy (Hw, MII_BMCR, Phy_Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      E1000e_Phy_Force_Speed_Duplex_Setup (Hw, Phy_Data'unchecked_Access);

      Ret_Val := E1e_Wphy (Hw, MII_BMCR, Phy_Data);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- Clear Auto-Crossover to force MDI manually.  IGP requires MDI
      -- forced whenever speed and duplex are forced.
      --
      Ret_Val := E1e_Rphy (Hw, IGP01E1000_PHY_PORT_CTRL, Phy_Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Phy_Data := Phy_Data and (not IGP01E1000_PSCR_AUTO_MDIX);
      Phy_Data := Phy_Data and (not IGP01E1000_PSCR_FORCE_MDI_MDIX);

      Ret_Val  := E1e_Wphy (Hw, IGP01E1000_PHY_PORT_CTRL, Phy_Data);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      E_Dbg ("IGP PSCR:" & Phy_Data'Image);

      delay 1.0 * Microseconds;     -- equivalent to udelay(1)

      if Phy.Autoneg_Wait_To_Complete
      then
         E_Dbg ("Waiting for forced speed/duplex link on IGP phy.");

         Ret_Val := E1000e_Phy_Has_Link_Generic (Hw,
                                                 PHY_FORCE_LIMIT,
                                                 100_000,
                                                 Link);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         if not Link
         then
            E_Dbg ("Link taking longer than expected.");
         end if;

         -- Try once more.
         --
         Ret_Val := E1000e_Phy_Has_Link_Generic (Hw,
                                                 PHY_FORCE_LIMIT,
                                                 100_000,
                                                 Link);
      end if;

      return Ret_Val;
   end E1000e_Phy_Force_Speed_Duplex_Igp;




   ---------------------------------------
   -- E1000e_Phy_Force_Speed_Duplex_M88 --
   ---------------------------------------

   --  Force speed/duplex for m88 PHY.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Calls the PHY setup function to force speed and duplex.  Clears the
   --  *  auto-crossover to force MDI manually.  Resets the PHY to commit the
   --  *  changes.  If time expires while waiting for link up, we reset the DSP.
   --  *  After reset, TX_CLK and CRS on Tx must be set.  Return successful upon
   --  *  successful completion, else return corresponding error code.


   function E1000e_Phy_Force_Speed_Duplex_M88
     (Hw : access E1000_Hw) return s32
   is
      use type Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.item;

      Phy      :         E1000_Phy_Info.item renames Hw.Phy;
      Ret_Val  :         s32;
      Phy_Data : aliased u16;
      Link     :         Boolean;

   begin
      -- Clear Auto-Crossover to force MDI manually. M88E1000 requires MDI
      -- forced whenever speed and duplex are forced.
      --
      Ret_Val := E1e_Rphy (Hw, M88E1000_PHY_SPEC_CTRL, Phy_Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Phy_Data := Phy_Data and (not M88E1000_PSCR_AUTO_X_MODE);
      Ret_Val  := E1e_Wphy (Hw, M88E1000_PHY_SPEC_CTRL, Phy_Data);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      e_dbg ("M88E1000 PSCR: " & Phy_Data'Image);

      Ret_Val := E1e_Rphy (Hw, MII_BMCR, Phy_Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      E1000e_Phy_Force_Speed_Duplex_Setup (Hw, Phy_Data'unchecked_Access);

      Ret_Val := E1e_Wphy (Hw, MII_BMCR, Phy_Data);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- Reset the phy to commit changes.
      --
      if Hw.Phy.Ops.Commit /= null
      then
         Ret_Val := Hw.Phy.Ops.Commit (Hw);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;
      end if;


      if Phy.Autoneg_Wait_To_Complete
      then
         e_dbg ("Waiting for forced speed/duplex link on M88 phy.");

         Ret_Val := E1000e_Phy_Has_Link_Generic (Hw, PHY_FORCE_LIMIT, 100_000, Link);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         if not Link
         then
            if Hw.Phy.Phy_Type /= E1000_Phy_M88
            then
               e_dbg ("Link taking longer than expected.");
            else
               -- We didn't get link.
               -- Reset the DSP and cross our fingers.
               --
               Ret_Val := E1e_Wphy (Hw, M88E1000_PHY_PAGE_SELECT, 16#001d#);

               if Ret_Val /= 0
               then
                  return Ret_Val;
               end if;

               Ret_Val := E1000e_Phy_Reset_Dsp (Hw);

               if Ret_Val /= 0
               then
                  return Ret_Val;
               end if;
            end if;
         end if;


         -- Try once more.
         --
         Ret_Val := E1000e_Phy_Has_Link_Generic (Hw, PHY_FORCE_LIMIT, 100_000, Link);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;
      end if;


      if Hw.Phy.Phy_Type /= E1000_Phy_M88
      then
         return 0;
      end if;


      Ret_Val := E1e_Rphy (Hw, M88E1000_EXT_PHY_SPEC_CTRL, Phy_Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- Resetting the phy means we need to re-force TX_CLK in the
      -- Extended PHY Specific Control Register to 25MHz clock from
      -- the reset value of 2.5MHz.

      Phy_Data := Phy_Data or M88E1000_EPSCR_TX_CLK_25;
      Ret_Val  := E1e_Wphy (Hw, M88E1000_EXT_PHY_SPEC_CTRL, Phy_Data);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;

      -- In addition, we must re-enable CRS on Tx for both half and full duplex.
      --
      Ret_Val := E1e_Rphy (Hw, M88E1000_PHY_SPEC_CTRL, Phy_Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Phy_Data := Phy_Data or M88E1000_PSCR_ASSERT_CRS_ON_TX;
      Ret_Val  := E1e_Wphy (Hw, M88E1000_PHY_SPEC_CTRL, Phy_Data);

      return Ret_Val;
   end E1000e_Phy_Force_Speed_Duplex_M88;




   --------------------------------------
   -- E1000_Phy_Force_Speed_Duplex_Ife --
   --------------------------------------

   --  Force PHY speed & duplex.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Forces the speed and duplex settings of the PHY.
   --  *  This is a function pointer entry point only called by
   --  *  PHY setup routines.


   function E1000_Phy_Force_Speed_Duplex_Ife
     (Hw : access E1000_Hw) return s32
   is
      Phy     :         E1000_Phy_Info.item renames Hw.Phy;
      Ret_Val :         s32;
      Data    : aliased Unsigned_16;
      Link    :         Boolean;

   begin
      Ret_Val := E1e_Rphy (Hw, MII_BMCR, Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      E1000e_Phy_Force_Speed_Duplex_Setup (Hw, Data'unchecked_Access);

      Ret_Val := E1e_Wphy (Hw, MII_BMCR, Data);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- Disable MDI-X support for 10/100.
      --
      Ret_Val := E1e_Rphy (Hw, IFE_PHY_MDIX_CONTROL, Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Data := Data and (not IFE_PMC_AUTO_MDIX);
      Data := Data and (not IFE_PMC_FORCE_MDIX);

      Ret_Val := E1e_Wphy (Hw, IFE_PHY_MDIX_CONTROL, Data);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      e_dbg ("IFE PMC:" & Data'Image);

      delay 1.0 * Microseconds;     -- Equivalent to udelay(1).

      if Phy.Autoneg_Wait_To_Complete
      then
         e_dbg ("Waiting for forced speed/duplex link on IFE phy.");

         Ret_Val := E1000e_Phy_Has_Link_Generic (Hw, PHY_FORCE_LIMIT, 100_000, Link);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         if not Link
         then
            e_dbg ("Link taking longer than expected.");
         end if;

         -- Try once more.
         --
         Ret_Val := E1000e_Phy_Has_Link_Generic (Hw, PHY_FORCE_LIMIT, 100_000, Link);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;
      end if;

      return 0;
   end E1000_Phy_Force_Speed_Duplex_Ife;




   ---------------------------------
   -- E1000e_Get_Cable_Length_M88 --
   ---------------------------------

   --  Determine cable length for m88 PHY
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Reads the PHY specific status register to retrieve the cable length
   --  *  information.  The cable length is determined by averaging the minimum and
   --  *  maximum values to get the "average" cable length.  The m88 PHY has four
   --  *  possible cable length values, which are:
   --  * Register Value    Cable Length
   --  * 0        < 50 meters
   --  * 1        50 - 80 meters
   --  * 2        80 - 110 meters
   --  * 3        110 - 140 meters
   --  * 4        > 140 meters


   function E1000e_Get_Cable_Length_M88
     (HW : access E1000_HW) return s32
   is
      Ret_Val  :         s32;
      PHY_Data : aliased Unsigned_16;
      Index    :         Unsigned_16;

   begin
      Ret_Val := E1e_Rphy (HW, M88E1000_PHY_SPEC_STATUS, PHY_Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Index := Field_Get (M88E1000_PSSR_CABLE_LENGTH, PHY_Data);

      if Index >= M88E1000_CABLE_LENGTH_TABLE_SIZE - 1
      then
         return -E1000_ERR_PHY;
      end if;


      HW.PHY.Min_Cable_Length := E1000_M88_Cable_Length_Table (Integer (Index));
      HW.PHY.Max_Cable_Length := E1000_M88_Cable_Length_Table (Integer (Index) + 1);

      HW.PHY.Cable_Length := (HW.PHY.Min_Cable_Length + HW.PHY.Max_Cable_Length) / 2;

      return 0;
   end E1000e_Get_Cable_Length_M88;




   -----------------------------------
   -- E1000e_Get_Cable_Length_Igp_2 --
   -----------------------------------

   --  Determine cable length for igp2 PHY.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  The automatic gain control (agc) normalizes the amplitude of the
   --  *  received signal, adjusting for the attenuation produced by the
   --  *  cable.  By reading the AGC registers, which represent the
   --  *  combination of coarse and fine gain value, the value can be put
   --  *  into a lookup table to obtain the approximate cable length
   --  *  for each channel.


   function E1000e_Get_Cable_Length_Igp_2
     (Hw : access E1000_Hw) return S32
   is
      Phy           :         E1000_Phy_Info.item renames Hw.Phy;
      Ret_Val       :         S32;
      Phy_Data      : aliased u16;
      Agc_Value     :         Unsigned_16 := 0;
      Cur_Agc_Index,
      Max_Agc_Index :         Unsigned_16 := 0;
      Min_Agc_Index :         Unsigned_16 := IGP02E1000_CABLE_LENGTH_TABLE_SIZE - 1;

      Agc_Reg_Array : constant array (0 .. IGP02E1000_PHY_CHANNEL_NUM - 1) of U32
        := [IGP02E1000_PHY_AGC_A,
            IGP02E1000_PHY_AGC_B,
            IGP02E1000_PHY_AGC_C,
            IGP02E1000_PHY_AGC_D];

   begin
      -- Read the AGC registers for all channels.
      --
      for I in 0 .. IGP02E1000_PHY_CHANNEL_NUM - 1
      loop
         Ret_Val := E1e_Rphy (Hw,
                              Agc_Reg_Array (I),
                              Phy_Data'unchecked_Access);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         -- Getting bits 15:9, which represent the combination of
         -- coarse and fine gain values. The result is a number
         -- that can be put into the lookup table to obtain the
         -- approximate cable length.
         --
         Cur_Agc_Index :=     shift_Right (Phy_Data,
                                           IGP02E1000_AGC_LENGTH_SHIFT)
           and IGP02E1000_AGC_LENGTH_MASK;

         -- Array index bound check.
         --
         if   Cur_Agc_Index >= IGP02E1000_CABLE_LENGTH_TABLE_SIZE
           or Cur_Agc_Index  = 0
         then
            return -E1000_ERR_PHY;
         end if;


         -- Remove min & max AGC values from calculation.
         --
         if  E1000_Igp_2_Cable_Length_Table (Integer (Min_Agc_Index))
           > E1000_Igp_2_Cable_Length_Table (Integer (Cur_Agc_Index))
         then
            Min_Agc_Index := Cur_Agc_Index;
         end if;

         if  E1000_Igp_2_Cable_Length_Table (Integer (Max_Agc_Index))
           < E1000_Igp_2_Cable_Length_Table (Integer (Cur_Agc_Index))
         then
            Max_Agc_Index := Cur_Agc_Index;
         end if;

         Agc_Value := Agc_Value + E1000_Igp_2_Cable_Length_Table (Integer (Cur_Agc_Index));
      end loop;


      Agc_Value := Agc_Value - (  E1000_Igp_2_Cable_Length_Table (Integer (Min_Agc_Index))
                                  + E1000_Igp_2_Cable_Length_Table (Integer (Max_Agc_Index)));
      Agc_Value := Agc_Value / (IGP02E1000_PHY_CHANNEL_NUM - 2);

      -- Calculate cable length with the error range of +/- 10 meters.
      --
      Phy.Min_Cable_Length := (if Agc_Value > IGP02E1000_AGC_RANGE then Agc_Value - IGP02E1000_AGC_RANGE
                               else 0);
      Phy.Max_Cable_Length := Agc_Value + IGP02E1000_AGC_RANGE;

      Phy.Cable_Length     := (Phy.Min_Cable_Length + Phy.Max_Cable_Length) / 2;

      return 0;
   end E1000e_Get_Cable_Length_Igp_2;




   ---------------------------------
   -- E1000e_Get_Cfg_Done_Generic --
   ---------------------------------

   --    Generic configuration done.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Generic function to wait 10 milli-seconds for configuration to complete
   --  *  and return success.


   function E1000e_Get_Cfg_Done_Generic
     (HW : access E1000_HW with Unreferenced) return s32
   is
   begin
      delay 10.0 * Milliseconds;
      return 0;
   end E1000e_Get_Cfg_Done_Generic;




   -----------------------
   -- E1000e_Get_Phy_Id --
   -----------------------

   --    Retrieve the PHY ID and revision.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Reads the PHY registers and stores the PHY ID and possibly the PHY
   --  *  revision in the hardware structure.


   function E1000e_Get_Phy_Id
     (Hw : access E1000_Hw) return s32
   is
      use type Devices.e1000e.Hardware.func_arg1_e1000_hw_arg2_u32_arg3_u16_array_return_s32.item;

      Phy         :         E1000_Phy_Info.item renames Hw.Phy;
      Ret_Val     :         s32        := 0;
      Phy_Id      : aliased Unsigned_16;
      Retry_Count :         Natural    := 0;

   begin
      if Phy.Ops.Read_Reg = null
      then
         return 0;
      end if;


      while Retry_Count < 2
      loop
         Ret_Val := E1e_Rphy (Hw, MII_PHYSID1, Phy_Id'unchecked_Access);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Phy.Id := Shift_Left(Unsigned_32(Phy_Id), 16);

         delay 30.0 * Microseconds;     -- Equivalent to usleep_range (20, 40).

         Ret_Val := E1e_Rphy(Hw, MII_PHYSID2, Phy_Id'unchecked_Access);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Phy.Id       := Phy.Id or (u32 (Phy_Id) and     PHY_REVISION_MASK);
         Phy.Revision :=            u32 (Phy_Id) and not PHY_REVISION_MASK;

         if    Phy.Id /= 0
           and Phy.Id /= PHY_REVISION_MASK
         then
            return 0;
         end if;

         Retry_Count := Retry_Count + 1;
      end loop;


      return 0;
   end E1000e_Get_Phy_Id;




   -----------------------------
   -- E1000e_Get_Phy_Info_Igp --
   -----------------------------

   --  Retrieve igp PHY information.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Read PHY status to determine if link is up.  If link is up, then
   --  *  set/determine 10base-T extended distance and polarity correction.  Read
   --  *  PHY port status to determine MDI/MDIx and speed.  Based on the speed,
   --  *  determine on the cable length, local and remote receiver.


   function E1000e_Get_Phy_Info_Igp
     (Hw : access E1000_Hw) return s32
   is
      Phy     :         E1000_Phy_Info.item renames Hw.Phy;
      Ret_Val :         s32;
      Data    : aliased Unsigned_16;
      Link    :         Boolean;

   begin
      Ret_Val := E1000e_Phy_Has_Link_Generic (Hw, 1, 0, Link);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      if not Link
      then
         e_dbg ("Phy info is only valid if link is up");
         return -E1000_ERR_CONFIG;
      end if;


      Phy.Polarity_Correction := True;
      Ret_Val                 := E1000_Check_Polarity_Igp (Hw);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Ret_Val := E1e_Rphy (Hw, IGP01E1000_PHY_PORT_STATUS, Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Phy.Is_Mdix := (Data and IGP01E1000_PSSR_MDIX) /= 0;

      if (Data and IGP01E1000_PSSR_SPEED_MASK) = IGP01E1000_PSSR_SPEED_1000MBPS
      then
         Ret_Val := Phy.Ops.Get_Cable_Length (Hw);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Ret_Val := E1e_Rphy (Hw, MII_STAT1000, Data'unchecked_Access);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         if (Data and LPA_1000LOCALRXOK) /= 0
         then
            Phy.Local_Rx := E1000_1000t_Rx_Status_Ok;
         else
            Phy.Local_Rx := E1000_1000t_Rx_Status_Not_Ok;
         end if;

         if (Data and LPA_1000REMRXOK) /= 0
         then
            Phy.Remote_Rx := E1000_1000t_Rx_Status_Ok;
         else
            Phy.Remote_Rx := E1000_1000t_Rx_Status_Not_Ok;
         end if;

      else
         Phy.Cable_Length := E1000_CABLE_LENGTH_UNDEFINED;
         Phy.Local_Rx     := E1000_1000t_Rx_Status_Undefined;
         Phy.Remote_Rx    := E1000_1000t_Rx_Status_Undefined;
      end if;


      return Ret_Val;
   end E1000e_Get_Phy_Info_Igp;




   -----------------------------
   -- E1000e_Get_Phy_Info_M88 --
   -----------------------------

   --  Retrieve PHY information.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Valid for only copper links.  Read the PHY status register (sticky read)
   --  *  to verify that link is up.  Read the PHY special control register to
   --  *  determine the polarity and 10base-T extended distance.  Read the PHY
   --  *  special status register to determine MDI/MDIx and current speed.  If
   --  *  speed is 1000, then determine cable length, local and remote receiver.


   function E1000e_Get_Phy_Info_M88
     (Hw : access E1000_Hw) return s32
   is
      Phy      :         E1000_Phy_Info.item renames Hw.Phy;
      Ret_Val  :         s32;
      Phy_Data : aliased Unsigned_16;
      Link     : aliased Boolean;

   begin
      if Phy.Media_Type /= E1000_Media_Type_Copper
      then
         e_dbg ("Phy info is only valid for copper media");
         return -E1000_ERR_CONFIG;
      end if;


      Ret_Val := E1000e_Phy_Has_Link_Generic (Hw, 1, 0, Link);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      if not Link
      then
         e_dbg ("Phy info is only valid if link is up");
         return -E1000_ERR_CONFIG;
      end if;


      Ret_Val := E1e_Rphy (Hw, M88E1000_PHY_SPEC_CTRL, Phy_Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Phy.Polarity_Correction := (Phy_Data and M88E1000_PSCR_POLARITY_REVERSAL) /= 0;
      Ret_Val                 := E1000_Check_Polarity_M88 (Hw);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Ret_Val := E1e_Rphy (Hw, M88E1000_PHY_SPEC_STATUS, Phy_Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Phy.Is_Mdix := (Phy_Data and M88E1000_PSSR_MDIX) /= 0;

      if (Phy_Data and M88E1000_PSSR_SPEED) = M88E1000_PSSR_1000MBS
      then
         Ret_Val := Hw.Phy.Ops.Get_Cable_Length (Hw);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Ret_Val := E1e_Rphy (Hw, MII_STAT1000, Phy_Data'unchecked_Access);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Phy.Local_Rx := (if (Phy_Data and LPA_1000LOCALRXOK) /= 0 then E1000_1000t_Rx_Status_Ok
                          else E1000_1000t_Rx_Status_Not_Ok);

         Phy.Remote_Rx := (if (Phy_Data and LPA_1000REMRXOK) /= 0  then E1000_1000t_Rx_Status_Ok
                           else E1000_1000t_Rx_Status_Not_Ok);

      else
         -- Set values to "undefined".
         --
         Phy.Cable_Length := E1000_CABLE_LENGTH_UNDEFINED;
         Phy.Local_Rx     := E1000_1000t_Rx_Status_Undefined;
         Phy.Remote_Rx    := E1000_1000t_Rx_Status_Undefined;
      end if;


      return Ret_Val;
   end E1000e_Get_Phy_Info_M88;




   ----------------------------
   -- E1000_Get_Phy_Info_Ife --
   ----------------------------

   function E1000_Get_Phy_Info_Ife
     (HW : access E1000_HW) return s32
   is
      Phy     :         E1000_Phy_Info.item renames HW.Phy;
      Ret_Val :         s32;
      Data    : aliased Unsigned_16;
      Link    :         Boolean;

   begin
      Ret_Val := E1000e_Phy_Has_Link_Generic (HW, 1, 0, Link);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      if not Link
      then
         e_dbg ("Phy info is only valid if link is up");
         return -E1000_ERR_CONFIG;
      end if;


      Ret_Val := E1e_Rphy (HW, IFE_PHY_SPECIAL_CONTROL, Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Phy.Polarity_Correction := (Data and IFE_PSC_AUTO_POLARITY_DISABLE) = 0;

      if Phy.Polarity_Correction
      then
         Ret_Val := E1000_Check_Polarity_Ife (HW);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;

      else
         -- Polarity is forced.
         --
         if (Data and IFE_PSC_FORCE_POLARITY) /= 0 then
            Phy.Cable_Polarity := E1000_Rev_Polarity_Reversed;
         else
            Phy.Cable_Polarity := E1000_Rev_Polarity_Normal;
         end if;
      end if;


      Ret_Val := E1e_Rphy (HW, IFE_PHY_MDIX_CONTROL, Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Phy.Is_Mdix := (Data and IFE_PMC_MDIX_STATUS) /= 0;

      -- The following parameters are undefined for 10/100 operation.
      --
      Phy.Cable_Length := E1000_CABLE_LENGTH_UNDEFINED;
      Phy.Local_Rx     := E1000_1000t_Rx_Status_Undefined;
      Phy.Remote_Rx    := E1000_1000t_Rx_Status_Undefined;

      return 0;
   end E1000_Get_Phy_Info_Ife;




   -------------------------
   -- E1000e_Phy_Sw_Reset --
   -------------------------

   --    PHY software reset.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Does a software reset of the PHY by reading the PHY control register and
   --  *  setting/write the control register reset bit to the PHY.


   function E1000e_Phy_Sw_Reset
     (HW : access E1000_HW) return s32
   is
      Ret_Val  :         s32;
      Phy_Ctrl : aliased Unsigned_16;

   begin
      Ret_Val := E1e_Rphy (HW, MII_BMCR, Phy_Ctrl'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Phy_Ctrl := Phy_Ctrl or BMCR_RESET;
      Ret_Val  := E1e_Wphy (HW, MII_BMCR, Phy_Ctrl);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      delay 1.0 * Microseconds;
      return Ret_Val;
   end E1000e_Phy_Sw_Reset;




   -----------------------------------------
   -- E1000e_Phy_Force_Speed_Duplex_Setup --
   -----------------------------------------

   --  Configure forced PHY speed/duplex.
   --
   --  *  @hw:       Pointer to the HW structure.
   --  *  @phy_ctrl: Pointer to current value of MII_BMCR.
   --  *
   --  *  Forces speed and duplex on the PHY by doing the following: disable flow
   --  *  control, force speed/duplex on the MAC, disable auto speed detection,
   --  *  disable auto-negotiation, configure duplex, configure speed, configure
   --  *  the collision distance, write configuration to CTRL register.  The
   --  *  caller must write to the MII_BMCR register for these settings to
   --  *  take affect.


   procedure E1000e_Phy_Force_Speed_Duplex_Setup
     (HW       : access E1000_HW;
      Phy_Ctrl : in     u16_Pointer)
   is
      Mac  : E1000_MAC_Info.item renames HW.Mac;
      Ctrl : u32;

   begin
      -- Turn off flow control when forcing speed/duplex.
      --
      HW.Fc.Current_Mode := E1000_Fc_None;

      -- Force speed/duplex on the mac.
      --
      Ctrl := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);
      Ctrl := Ctrl or (E1000_CTRL_FRCSPD or E1000_CTRL_FRCDPX);
      Ctrl := Ctrl and (not E1000_CTRL_SPD_SEL);

      -- Disable Auto Speed Detection.
      --
      Ctrl := Ctrl and (not E1000_CTRL_ASDE);

      -- Disable autoneg on the phy.
      --
      Phy_Ctrl.all := Phy_Ctrl.all and (not BMCR_ANENABLE);


      -- Forcing Full or Half Duplex?
      --
      if (Mac.Forced_Speed_Duplex and E1000_ALL_HALF_DUPLEX) /= 0
      then
         Ctrl         := Ctrl and (not E1000_CTRL_FD);
         Phy_Ctrl.all := Phy_Ctrl.all and (not BMCR_FULLDPLX);

         E_Dbg ("Half Duplex");

      else
         Ctrl         := Ctrl or E1000_CTRL_FD;
         Phy_Ctrl.all := Phy_Ctrl.all or BMCR_FULLDPLX;

         E_Dbg ("Full Duplex");
      end if;


      -- Forcing 10mb or 100mb?
      --
      if (Mac.Forced_Speed_Duplex and E1000_ALL_100_SPEED) /= 0
      then
         Ctrl         := Ctrl or E1000_CTRL_SPD_100;
         Phy_Ctrl.all := Phy_Ctrl.all or BMCR_SPEED100;
         Phy_Ctrl.all := Phy_Ctrl.all and (not BMCR_SPEED1000);

         E_Dbg ("Forcing 100mb");

      else
         Ctrl         := Ctrl and (not (E1000_CTRL_SPD_1000 or E1000_CTRL_SPD_100));
         Phy_Ctrl.all := Phy_Ctrl.all and (not (BMCR_SPEED1000 or BMCR_SPEED100));

         E_Dbg ("Forcing 10mb");
      end if;

      HW.Mac.Ops.Config_Collision_Dist (HW);

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, Ctrl);
   end E1000e_Phy_Force_Speed_Duplex_Setup;




   ---------------------------------
   -- E1000e_Phy_Hw_Reset_Generic --
   ---------------------------------

   --    PHY hardware reset.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Verify the reset block is not blocking us from resetting.  Acquire
   --  *  semaphore (if necessary) and read/set/write the device control reset
   --  *  bit in the PHY.  Wait the appropriate delay time for the device to
   --  *  reset and release the semaphore (if necessary).


   function E1000e_Phy_Hw_Reset_Generic
     (HW : access E1000_HW) return s32
   is
      use type Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.item;

      Phy     : E1000_PHY_Info.item renames HW.Phy;
      Ret_Val : s32;
      Ctrl    : u32;

   begin
      if Phy.Ops.Check_Reset_Block /= null
      then
         Ret_Val := Phy.Ops.Check_Reset_Block (HW);

         if Ret_Val /= 0
         then
            return 0;
         end if;
      end if;


      Ret_Val := Phy.Ops.Acquire (HW);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Ctrl := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);
      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, Ctrl or E1000_CTRL_PHY_RST);
      E1E_Flush (Hw);

      delay Duration (Phy.Reset_Delay_Us) * Microseconds;

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, Ctrl);
      E1E_Flush (Hw);

      delay 225.0 * Microseconds;     -- Average of 150 and 300.

      Phy.Ops.Release (HW);

      return Phy.Ops.Get_Cfg_Done (HW);
   end E1000e_Phy_Hw_Reset_Generic;




   --------------------------
   -- E1000e_Phy_Reset_Dsp --
   --------------------------

   --  Reset PHY DSP.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Reset the digital signal processor.


   function E1000e_Phy_Reset_Dsp
     (Hw : access E1000_Hw) return s32
   is
      Ret_Val : s32;

   begin
      Ret_Val := E1e_Wphy (Hw, M88E1000_PHY_GEN_CONTROL, 16#C1#);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      return E1e_Wphy (Hw, M88E1000_PHY_GEN_CONTROL, 0);
   end E1000e_Phy_Reset_Dsp;




   --------------------------
   -- E1000e_Read_Kmrn_Reg --
   --------------------------

   --  Read kumeran register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to be read.
   --  *  @data:   Pointer to the read data.
   --  *
   --  *  Acquires semaphore then reads the PHY register at offset using the
   --  *  kumeran interface.  The information retrieved is stored in data.
   --  *  Release the acquired semaphore before exiting.


   function E1000e_Read_Kmrn_Reg
     (HW     : access E1000_HW;
      Offset : in     u32;
      Data   : in     u16_Pointer) return s32
   is
   begin
      return Read_Kmrn_Reg (HW, Offset, Data, False);
   end E1000e_Read_Kmrn_Reg;




   ---------------------------------
   -- E1000e_Read_Kmrn_Reg_Locked --
   ---------------------------------

   --  Read kumeran register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to be read.
   --  *  @data:   Pointer to the read data.
   --  *
   --  *  Reads the PHY register at offset using the kumeran interface.  The
   --  *  information retrieved is stored in data.
   --  *  Assumes semaphore already acquired.


   function E1000e_Read_Kmrn_Reg_Locked
     (Hw     : access E1000_Hw;
      Offset : in     Unsigned_32;
      Data   : in     u16_Pointer) return s32
   is
   begin
      return Read_Kmrn_Reg (Hw, Offset, Data, True);
   end E1000e_Read_Kmrn_Reg_Locked;




   ------------------------
   -- E1000_Set_Page_IGP --
   ------------------------

   --  Set page as on IGP-like PHY(s).
   --
   --  *  @hw:   Pointer to the HW structure.
   --  *  @page: Page to set (shifted left when necessary).
   --  *
   --  *  Sets PHY page required for PHY register access.  Assumes semaphore is
   --  *  already acquired.  Note, this function sets phy.addr to 1 so the caller
   --  *  must set it appropriately (if necessary) after this function returns.


   function E1000_Set_Page_IGP
     (HW   : access E1000_HW;
      Page : in     Unsigned_16) return s32
   is
   begin
      e_dbg ("Setting page 0x" & Unsigned_16'Image (Page));

      HW.PHY.Addr := 1;

      return E1000E_Write_PHY_Reg_MDIC (HW, IGP01E1000_PHY_PAGE_SELECT, Page);
   end E1000_Set_Page_IGP;




   -----------------------------
   -- E1000e_Read_Phy_Reg_Igp --
   -----------------------------

   --  Read igp PHY register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to be read.
   --  *  @data:   Pointer to the read data.
   --  *
   --  *  Acquires semaphore then reads the PHY register at offset and stores the
   --  *  retrieved information in data.
   --  *  Release the acquired semaphore before exiting.


   function E1000e_Read_Phy_Reg_Igp (Hw     : access E1000_Hw;
                                     Offset : in     u32;
                                     Data   : in     u16_Pointer) return s32
   is
   begin
      return E1000e_Read_Phy_Reg_Igp (Hw, Offset, Data, False);
   end E1000e_Read_Phy_Reg_Igp;




   ------------------------------------
   -- E1000e_Read_Phy_Reg_Igp_Locked --
   ------------------------------------

   function E1000e_Read_Phy_Reg_Igp_Locked
     (Hw     : access E1000_Hw;
      Offset : in     u32;
      Data   : in     u16_Pointer) return s32
   is
   begin
      return E1000e_Read_Phy_Reg_Igp (Hw, Offset, Data, True);
   end E1000e_Read_Phy_Reg_Igp_Locked;




   -----------------------------
   -- E1000e_Read_Phy_Reg_M88 --
   -----------------------------

   --  Read m88 PHY register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to be read.
   --  *  @data:   Pointer to the read data.
   --  *
   --  *  Acquires semaphore, if necessary, then reads the PHY register at offset
   --  *  and storing the retrieved information in data.  Release any acquired
   --  *  semaphores before exiting.


   function E1000e_Read_Phy_Reg_M88
     (Hw     : access E1000_Hw;
      Offset : in     Unsigned_32;
      Data   : in     u16_Pointer) return s32
   is
      Ret_Val : s32;

   begin
      Ret_Val := Hw.Phy.Ops.Acquire (Hw);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;

      Ret_Val := E1000e_Read_Phy_Reg_Mdic (Hw,
                                           Max_Phy_Reg_Address and Offset,
                                           Data);
      Hw.Phy.Ops.Release (Hw);

      return Ret_Val;
   end E1000e_Read_Phy_Reg_M88;




   ------------------------------
   -- E1000e_Set_D3_LPLU_State --
   ------------------------------

   --  Sets low power link up state for D3.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @active: Boolean used to enable/disable lplu.
   --  *
   --  *  Success returns 0, Failure returns 1
   --  *
   --  *  The low power link up (lplu) state is set to the power management level D3
   --  *  and SmartSpeed is disabled when active is true, else clear lplu for D3
   --  *  and enable Smartspeed.  LPLU and Smartspeed are mutually exclusive.  LPLU
   --  *  is used during Dx states where the power conservation is most important.
   --  *  During driver activity, SmartSpeed should be enabled so performance is
   --  *  maintained.


   function E1000e_Set_D3_LPLU_State
     (HW     : access E1000_HW;
      Active : in     Boolean) return S32
   is
      PHY     :         E1000_PHY_Info.item renames HW.PHY;
      Ret_Val :         S32;
      Data    : aliased Unsigned_16;

   begin
      Ret_Val := E1e_Rphy (HW, IGP02E1000_PHY_POWER_MGMT, Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      if not Active
      then
         Data    := Data and (not IGP02E1000_PM_D3_LPLU);
         Ret_Val := E1e_Wphy (HW, IGP02E1000_PHY_POWER_MGMT, Data);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         -- LPLU and SmartSpeed are mutually exclusive.  LPLU is used
         -- during Dx states where the power conservation is most
         -- important.  During driver activity we should enable
         -- SmartSpeed, so performance is maintained.
         --
         if PHY.Smart_Speed = E1000_Smart_Speed_On
         then
            Ret_Val := E1e_Rphy (HW, IGP01E1000_PHY_PORT_CONFIG, Data'unchecked_Access);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;


            Data    := Data or IGP01E1000_PSCFR_SMART_SPEED;
            Ret_Val := E1e_Wphy (HW, IGP01E1000_PHY_PORT_CONFIG, Data);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;


         elsif PHY.Smart_Speed = E1000_Smart_Speed_Off
         then
            Ret_Val := E1e_Rphy (HW, IGP01E1000_PHY_PORT_CONFIG, Data'unchecked_Access);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;


            Data    := Data and (not IGP01E1000_PSCFR_SMART_SPEED);
            Ret_Val := E1e_Wphy (HW, IGP01E1000_PHY_PORT_CONFIG, Data);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;
         end if;


      elsif (PHY.Autoneg_Advertised = u16 (E1000_ALL_SPEED_DUPLEX))
        or  (PHY.Autoneg_Advertised = u16 (E1000_ALL_NOT_GIG))
        or  (PHY.Autoneg_Advertised = u16 (E1000_ALL_10_SPEED))
      then
         Data    := Data or IGP02E1000_PM_D3_LPLU;
         Ret_Val := E1e_Wphy (HW, IGP02E1000_PHY_POWER_MGMT, Data);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         -- When LPLU is enabled, we should disable SmartSpeed.
         --
         Ret_Val := E1e_Rphy (HW, IGP01E1000_PHY_PORT_CONFIG, Data'unchecked_Access);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;

         Data     := Data and (not IGP01E1000_PSCFR_SMART_SPEED);
         Ret_Val := E1e_Wphy (HW, IGP01E1000_PHY_PORT_CONFIG, Data);
      end if;


      return Ret_Val;
   end E1000e_Set_D3_LPLU_State;




   ------------------------------
   -- E1000e_Setup_Copper_Link --
   ------------------------------

   --  Configure copper link settings.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Calls the appropriate function to configure the link for auto-neg or forced
   --  *  speed and duplex.  Then we check for link, once link is established calls
   --  *  to configure collision distance and flow control are called.  If link is
   --  *  not established, we return -E1000_ERR_PHY (-2).


   function E1000e_Setup_Copper_Link
     (Hw : access E1000_Hw) return S32
   is
      Ret_Val : S32;
      Link    : Boolean;

   begin
      if Hw.Mac.Autoneg
      then
         -- Setup autoneg and flow control advertisement and perform
         -- autonegotiation.
         --
         Ret_Val := E1000_Copper_Link_Autoneg (Hw);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;

      else
         -- PHY will be set to 10H, 10F, 100H or 100F
         -- depending on user settings.
         --
         e_dbg ("Forcing Speed and Duplex");

         Ret_Val := Hw.Phy.Ops.Force_Speed_Duplex (Hw);

         if Ret_Val /= 0
         then
            e_dbg ("Error Forcing Speed and Duplex");
            return Ret_Val;
         end if;
      end if;


      -- Check link status. Wait up to 100 microseconds for link to become valid.
      --
      Ret_Val := E1000e_Phy_Has_Link_Generic (Hw, COPPER_LINK_UP_LIMIT, 10, Link);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      if Link
      then
         e_dbg ("Valid link established!!!");
         Hw.Mac.Ops.Config_Collision_Dist (Hw);
         Ret_Val := E1000e_Config_Fc_After_Link_Up (Hw);
      else
         e_dbg ("Unable to establish link!!!");
      end if;


      return Ret_Val;
   end E1000e_Setup_Copper_Link;




   ---------------------------
   -- E1000e_Write_Kmrn_Reg --
   ---------------------------

   --    Write kumeran register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to write to.
   --  *  @data:   Data to write at register offset.
   --  *
   --  *  Acquires semaphore then writes the data to the PHY register at the offset
   --  *  using the kumeran interface.  Release the acquired semaphore before exiting.


   function E1000e_Write_Kmrn_Reg
     (HW     : access E1000_HW;
      Offset : in     u32;
      Data   : in     u16) return s32
   is
   begin
      return Write_Kmrn_Reg (HW, Offset, Data, False);
   end E1000e_Write_Kmrn_Reg;





   ----------------------------------
   -- E1000e_Write_Kmrn_Reg_Locked --
   ----------------------------------

   --  Write kumeran register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to write to.
   --  *  @data:   Data to write at register offset.
   --  *
   --  *  Write the data to PHY register at the offset using the kumeran interface.
   --  *  Assumes semaphore already acquired.


   function E1000e_Write_Kmrn_Reg_Locked
     (HW     : access E1000_HW;
      Offset : in     u32;
      Data   : in     u16) return s32
   is
   begin
      return Write_Kmrn_Reg (HW, Offset, Data, True);
   end E1000e_Write_Kmrn_Reg_Locked;




   ------------------------------
   -- E1000e_Write_Phy_Reg_Igp --
   ------------------------------

   --  Write igp PHY register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to write to.
   --  *  @data:   Data to write at register offset.
   --  *
   --  *  Acquires semaphore then writes the data to PHY register
   --  *  at the offset.  Release any acquired semaphores before exiting.


   function E1000e_Write_Phy_Reg_Igp
     (HW     : access E1000_HW;
      Offset : in     U32;
      Data   : in     U16) return S32
   is
   begin
      return Write_Phy_Reg_Igp (HW, Offset, Data, False);
   end E1000e_Write_Phy_Reg_Igp;




   -------------------------------------
   -- E1000e_Write_Phy_Reg_Igp_Locked --
   -------------------------------------

   --  Write igp PHY register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to write to.
   --  *  @data:   Data to write at register offset.
   --  *
   --  *  Writes the data to PHY register at the offset.
   --  *  Assumes semaphore already acquired.


   function E1000e_Write_Phy_Reg_Igp_Locked
     (HW     : access E1000_HW;
      Offset : in     Unsigned_32;
      Data   : in     Unsigned_16) return s32
   is
   begin
      return Write_Phy_Reg_Igp (HW, Offset, Data, Locked => True);
   end E1000e_Write_Phy_Reg_Igp_Locked;




   ------------------------------
   -- E1000e_Write_Phy_Reg_M88 --
   ------------------------------

   --  Write m88 PHY register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to write to.
   --  *  @data:   Data to write at register offset.
   --  *
   --  *  Acquires semaphore, if necessary, then writes the data to PHY register
   --  *  at the offset.  Release any acquired semaphores before exiting.


   function E1000e_Write_Phy_Reg_M88
     (Hw : access E1000_Hw;
      Offset : Unsigned_32;
      Data : Unsigned_16) return s32
   is
      Ret_Val : s32;

   begin
      Ret_Val := Hw.Phy.Ops.Acquire (Hw);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;

      Ret_Val := E1000e_Write_Phy_Reg_Mdic (Hw,
                                            Unsigned_32 (Max_Phy_Reg_Address) and Offset,
                                            Data);
      Hw.Phy.Ops.Release (Hw);

      return Ret_Val;
   end E1000e_Write_Phy_Reg_M88;





   ---------------------------------
   -- E1000e_PHY_Has_Link_Generic --
   ---------------------------------

   --  Polls PHY for link.
   --
   --  *  @hw:            Pointer to the HW structure.
   --  *  @iterations:    Number of times to poll for link.
   --  *  @usec_interval: Delay between polling attempts.
   --  *  @success:       Pointer to whether polling was successful or not.
   --  *
   --  *  Polls the PHY status register for link, 'iterations' number of times.


   function E1000e_PHY_Has_Link_Generic
     (HW            : access E1000_HW;
      Iterations    : in     Unsigned_32;
      Usec_Interval : in     Unsigned_32;
      Success       :    out Boolean) return s32
   is
      Ret_Val    :         s32        := 0;
      PHY_Status : aliased Unsigned_16;

   begin
      Success := False;

      for I in 0 .. Iterations - 1
      loop
         -- Some PHYs require the MII_BMSR register to be read
         -- twice due to the link bit being sticky. No harm doing
         -- it across the board.
         --
         Ret_Val := E1e_RPHY (HW, MII_BMSR, PHY_Status'unchecked_Access);

         if Ret_Val /= 0
         then
            -- If the first read fails, another entity may have
            -- ownership of the resources, wait and try again to
            -- see if they have relinquished the resources yet.
            --
            if Usec_Interval >= 1000
            then
               delay Duration (uSec_Interval / 1_000) * Milliseconds;
            else
               delay Duration (uSec_Interval) * Microseconds;
            end if;
         end if;

         Ret_Val := E1e_RPHY (HW, MII_BMSR, PHY_Status'unchecked_Access);

         if Ret_Val /= 0
         then
            exit;
         end if;

         if (PHY_Status and BMSR_LSTATUS) /= 0
         then
            Success := True;
            exit;
         end if;

         if Usec_Interval >= 1000
         then
            delay Duration (uSec_Interval / 1_000) * Milliseconds;
         else
            delay Duration (uSec_Interval) * Microseconds;
         end if;
      end loop;


      return Ret_Val;
   end E1000e_PHY_Has_Link_Generic;




   ---------------------------------
   -- E1000e_Phy_Init_Script_Igp3 --
   ---------------------------------

   --  Inits the IGP3 PHY.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Initializes a Intel Gigabit PHY3 when an EEPROM is not present.


   function E1000e_Phy_Init_Script_Igp3
     (HW : access E1000_HW) return s32
   is
   begin
      e_dbg ("Running IGP 3 PHY init script");

      -- PHY init IGP 3.
      --

      E1e_Wphy (HW, 16#2F5B#, 16#9018#);     -- Enable rise/fall, 10-mode work in class-A.
      E1e_Wphy (HW, 16#2F52#, 16#0000#);     -- Remove all caps from Replica path filter.
      E1e_Wphy (HW, 16#2FB1#, 16#8B24#);     -- Bias trimming for ADC, AFE and Driver (Default).
      E1e_Wphy (HW, 16#2FB2#, 16#F8F0#);     -- Increase Hybrid poly bias.
      E1e_Wphy (HW, 16#2010#, 16#10B0#);     -- Add 4% to Tx amplitude in Gig mode.
      E1e_Wphy (HW, 16#2011#, 16#0000#);     -- Disable trimming (TTT).
      E1e_Wphy (HW, 16#20DD#, 16#249A#);     -- Poly DC correction to 94.6% + 2% for all channels.
      E1e_Wphy (HW, 16#20DE#, 16#00D3#);     -- ABS DC correction to 95.9%.
      E1e_Wphy (HW, 16#28B4#, 16#04CE#);     -- BG temp curve trim.
      E1e_Wphy (HW, 16#2F70#, 16#29E4#);     -- Increasing ADC OPAMP stage 1 currents to max.
      E1e_Wphy (HW, 16#0000#, 16#0140#);     -- Force 1000 ( required for enabling PHY regs configuration).
      E1e_Wphy (HW, 16#1F30#, 16#1606#);     -- Set upd_freq to 6.
      E1e_Wphy (HW, 16#1F31#, 16#B814#);     -- Disable NPDFE.
      E1e_Wphy (HW, 16#1F35#, 16#002A#);     -- Disable adaptive fixed FFE (Default).
      E1e_Wphy (HW, 16#1F3E#, 16#0067#);     -- Enable FFE hysteresis.
      E1e_Wphy (HW, 16#1F54#, 16#0065#);     -- Fixed FFE for short cable lengths.
      E1e_Wphy (HW, 16#1F55#, 16#002A#);     -- Fixed FFE for medium cable lengths.
      E1e_Wphy (HW, 16#1F56#, 16#002A#);     -- Fixed FFE for long cable lengths.
      E1e_Wphy (HW, 16#1F72#, 16#3FB0#);     -- Enable Adaptive Clip Threshold.
      E1e_Wphy (HW, 16#1F76#, 16#C0FF#);     -- AHT reset limit to 1.
      E1e_Wphy (HW, 16#1F77#, 16#1DEC#);     -- Set AHT master delay to 127 msec.
      E1e_Wphy (HW, 16#1F78#, 16#F9EF#);     -- Set scan bits for AHT.
      E1e_Wphy (HW, 16#1F79#, 16#0210#);     -- Set AHT Preset bits.
      E1e_Wphy (HW, 16#1895#, 16#0003#);     -- Change integ_factor of channel A to 3.
      E1e_Wphy (HW, 16#1796#, 16#0008#);     -- Change prop_factor of channels BCD to 8.
      E1e_Wphy (HW, 16#1798#, 16#D008#);     -- Change cg_icount + enable integbp for channels BCD.
      E1e_Wphy (HW, 16#1898#, 16#D918#);     -- Change cg_icount + enable integbp + change prop_factor_master to 8 for channel A.
      E1e_Wphy (HW, 16#187A#, 16#0800#);     -- Disable AHT in Slave mode on channel A.

      -- Enable LPLU and disable AN to 1000 in non-D0a states,
      --

      E1e_Wphy (HW, 16#0019#, 16#008D#);     -- Enable SPD+B2B
      E1e_Wphy (HW, 16#001B#, 16#2080#);     -- Enable restart AN on an1000_dis change
      E1e_Wphy (HW, 16#0014#, 16#0045#);     -- Enable wh_fifo read clock in 10/100 modes
      E1e_Wphy (HW, 16#0000#, 16#1340#);     -- Restart AN, Speed selection is 1000

      return 0;
   end E1000e_Phy_Init_Script_Igp3;




   ---------------------------------
   -- E1000e_Get_Phy_Type_From_Id --
   ---------------------------------

   --  Get PHY type from id.
   --
   --  *  @phy_id: phy_id read from the phy.
   --  *
   --  *  Returns the phy type from the id.


   function E1000e_Get_Phy_Type_From_Id
     (Phy_Id : in u32) return E1000_Phy_Type
   is
      Phy_Type : E1000_Phy_Type := E1000_Phy_Unknown;

   begin
      case Phy_Id
      is
         when M88E1000_I_PHY_ID
            | M88E1000_E_PHY_ID
            | M88E1111_I_PHY_ID
            | M88E1011_I_PHY_ID   => Phy_Type := E1000_Phy_M88;
         when IGP01E1000_I_PHY_ID => Phy_Type := E1000_Phy_Igp_2;         -- IGP 1 & 2 share this.
         when GG82563_E_PHY_ID    => Phy_Type := E1000_Phy_Gg82563;
         when IGP03E1000_E_PHY_ID => Phy_Type := E1000_Phy_Igp_3;
         when IFE_E_PHY_ID
            | IFE_PLUS_E_PHY_ID
            | IFE_C_E_PHY_ID      => Phy_Type := E1000_Phy_Ife;
         when BME1000_E_PHY_ID
            | BME1000_E_PHY_ID_R2 => Phy_Type := E1000_Phy_Bm;
         when I82578_E_PHY_ID     => Phy_Type := E1000_Phy_82578;
         when I82577_E_PHY_ID     => Phy_Type := E1000_Phy_82577;
         when I82579_E_PHY_ID     => Phy_Type := E1000_Phy_82579;
         when I217_E_PHY_ID       => Phy_Type := E1000_Phy_I217;
         when others              => Phy_Type := E1000_Phy_Unknown;
      end case;

      return Phy_Type;
   end E1000e_Get_Phy_Type_From_Id;




   ----------------------------------
   -- E1000e_Determine_Phy_Address --
   ----------------------------------

   --  Determines PHY address.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  This uses a trial and error method to loop through possible PHY
   --  *  addresses. It tests each by reading the PHY ID registers and
   --  *  checking for a match.


   function E1000e_Determine_Phy_Address
     (HW : access E1000_HW) return s32
   is
      I        : u32;
      Phy_Type : E1000_Phy_Type := E1000_Phy_Unknown;
      Unused   : s32;
   begin
      HW.Phy.Id := Phy_Type'Enum_Rep;

      for Addr in 0 .. u32 (E1000_MAX_PHY_ADDR) - 1
      loop
         HW.Phy.Addr := Addr;
         I           := 0;

         for phy_addr in 0 .. E1000_MAX_PHY_ADDR - 1
         loop
            Unused   := E1000e_Get_Phy_Id (HW);
            Phy_Type := E1000e_Get_Phy_Type_From_Id (HW.Phy.Id);

            -- If phy_type is valid, break - we found our PHY address.
            --
            if Phy_Type /= E1000_Phy_Unknown
            then
               return 0;
            end if;

            delay 1_500.0 * Microseconds;  -- Equivalent to usleep_range(1000, 2000)

            I := I + 1;
            exit when I >= 10;
         end loop;

      end loop;

      return -E1000_ERR_PHY_TYPE;
   end E1000e_Determine_Phy_Address;




   -----------------------------
   -- e1000e_write_phy_reg_bm --
   -----------------------------

   --    Write BM PHY register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to write to.
   --  *  @data:   Data to write at register offset.
   --  *
   --  *  Acquires semaphore, if necessary, then writes the data to PHY register
   --  *  at the offset.  Release any acquired semaphores before exiting.


   function e1000e_write_phy_reg_bm
     (HW     : access E1000_HW;
      Offset : in     Unsigned_32;
      Data   : in     Unsigned_16) return s32
   is
      Ret_Val :          s32;
      Page    : constant Unsigned_32 := shift_Right (Offset, IGP_PAGE_SHIFT);

   begin
      Ret_Val := HW.Phy.Ops.Acquire (HW);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- Page 800 works differently than the rest so it has its own func.
      --
      if Page = BM_WUC_PAGE
      then
         Ret_Val := e1000_access_phy_wakeup_reg_bm (HW,
                                                    Offset,
                                                    Data'unrestricted_Access,
                                                    False,
                                                    False);
         goto Release;
      end if;


      HW.Phy.Addr := e1000_get_phy_addr_for_bm_page (Page, Offset);

      if Offset > MAX_PHY_MULTI_PAGE_REG
      then
         declare
            Page_Shift  : Natural;
            Page_Select : Unsigned_32;
         begin
            -- Page select is register 31 for phy address 1 and 22 for
            -- phy address 2 and 3. Page select is shifted only for
            -- phy address 1.
            --
            if HW.Phy.Addr = 1
            then
               Page_Shift  := IGP_PAGE_SHIFT;
               Page_Select := IGP01E1000_PHY_PAGE_SELECT;
            else
               Page_Shift  := 0;
               Page_Select := BM_PHY_PAGE_SELECT;
            end if;

            -- Page is shifted left, PHY expects (page x 32).
            --
            Ret_Val := e1000e_write_phy_reg_mdic (HW,
                                                  Page_Select,
                                                  u16 (shift_Left (Page, Page_Shift)));
            if Ret_Val /= 0
            then
               goto Release;
            end if;
         end;
      end if;


      Ret_Val := e1000e_write_phy_reg_mdic (HW,
                                            u32 (MAX_PHY_REG_ADDRESS) and Offset,
                                            Data);

      <<Release>>

      HW.Phy.Ops.Release (HW);

      return Ret_Val;
   end e1000e_write_phy_reg_bm;




   ----------------------------
   -- E1000e_Read_Phy_Reg_Bm --
   ----------------------------

   --    Read BM PHY register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to be read.
   --  *  @data:   Pointer to the read data.
   --  *
   --  *  Acquires semaphore, if necessary, then reads the PHY register at offset
   --  *  and storing the retrieved information in data.  Release any acquired
   --  *  semaphores before exiting.


   function E1000e_Read_Phy_Reg_Bm
     (HW     : access E1000_HW;
      Offset : in     Unsigned_32;
      Data   : in     u16_Pointer) return s32
   is
      Ret_Val     :          s32;
      Page        : constant Unsigned_32 := Shift_Right (Offset, IGP_PAGE_SHIFT);
      Page_Shift  :          Natural;
      Page_Select :          Unsigned_32;

   begin
      Ret_Val := HW.Phy.Ops.Acquire (HW);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- Page 800 works differently than the rest so it has its own func.
      --
      if Page = BM_WUC_PAGE
      then
         Ret_Val := E1000_Access_Phy_Wakeup_Reg_Bm (HW, Offset, Data, True, False);
         goto Release_Label;
      end if;


      HW.Phy.Addr := E1000_Get_Phy_Addr_For_Bm_Page (Page, Offset);

      if Offset > MAX_PHY_MULTI_PAGE_REG
      then
         -- Page select is register 31 for phy address 1 and 22 for
         -- phy address 2 and 3. Page select is shifted only for
         -- phy address 1.
         --
         if HW.Phy.Addr = 1
         then
            Page_Shift  := IGP_PAGE_SHIFT;
            Page_Select := IGP01E1000_PHY_PAGE_SELECT;
         else
            Page_Shift  := 0;
            Page_Select := BM_PHY_PAGE_SELECT;
         end if;

         -- Page is shifted left, PHY expects (page x 32).
         --
         Ret_Val := E1000e_Write_Phy_Reg_Mdic (HW,
                                               Page_Select,
                                               u16 (shift_Left (Page,
                                                                Page_Shift)));
         if Ret_Val /= 0
         then
            goto Release_Label;
         end if;
      end if;


      Ret_Val := E1000e_Read_Phy_Reg_Mdic (HW,
                                           Offset and MAX_PHY_REG_ADDRESS,
                                           Data);

      <<Release_Label>>

      HW.Phy.Ops.Release (HW);

      return Ret_Val;
   end E1000e_Read_Phy_Reg_Bm;




   -------------------------------------------
   -- E1000_Enable_Phy_Wakeup_Reg_Access_BM --
   -------------------------------------------

   --    Enable access to BM wakeup registers.
   --
   --  *  @hw:      Pointer to the HW structure.
   --  *  @phy_reg: Pointer to store original contents of BM_WUC_ENABLE_REG.
   --  *
   --  *  Assumes semaphore already acquired and phy_reg points to a valid memory
   --  *  address to store contents of the BM_WUC_ENABLE_REG register.


   function E1000_Enable_Phy_Wakeup_Reg_Access_BM
     (HW      : access E1000_HW;
      Phy_Reg : in     u16_Pointer) return s32
   is
      Ret_Val : s32;
      Temp    : Unsigned_16;

   begin
      -- All page select, port ctrl and wakeup registers use phy address 1.
      --
      HW.Phy.Addr := 1;

      -- Select Port Control Registers page.
      --
      Ret_Val := E1000_Set_Page_IGP (HW,
                                     shift_Left (BM_PORT_CTRL_PAGE,
                                       IGP_PAGE_SHIFT));
      if Ret_Val /= 0
      then
         e_dbg ("Could not set Port Control page");
         return Ret_Val;
      end if;


      Ret_Val := E1000e_Read_Phy_Reg_Mdic (HW, BM_WUC_ENABLE_REG, Phy_Reg);

      if Ret_Val /= 0
      then
         e_dbg ("Could not read PHY register" & BM_PORT_CTRL_PAGE'Image & "." & BM_WUC_ENABLE_REG'Image);
         return Ret_Val;
      end if;


      -- Enable both PHY wakeup mode and Wakeup register page writes.
      -- Prevent a power state change by disabling ME and Host PHY wakeup.
      --
      Temp := Phy_Reg.all;
      Temp := Temp or       BM_WUC_ENABLE_BIT;
      Temp := Temp and not (BM_WUC_ME_WU_BIT or BM_WUC_HOST_WU_BIT);

      Ret_Val := E1000e_Write_Phy_Reg_Mdic (HW, BM_WUC_ENABLE_REG, Temp);

      if Ret_Val /= 0
      then
         e_dbg("Could not write PHY register" & BM_PORT_CTRL_PAGE'Image & "." & BM_WUC_ENABLE_REG'Image);
         return Ret_Val;
      end if;


      -- Select Host Wakeup Registers page - caller now able to write
      -- registers on the Wakeup registers page.
      --
      return E1000_Set_Page_IGP (HW,
                                 shift_Left (BM_WUC_PAGE,
                                   IGP_PAGE_SHIFT));
   end E1000_Enable_Phy_Wakeup_Reg_Access_BM;




   --------------------------------------------
   -- E1000_Disable_PHY_Wakeup_Reg_Access_BM --
   --------------------------------------------

   --  Disable access to BM wakeup regs.

   --  *  @hw:      Pointer to the HW structure.
   --  *  @phy_reg: Pointer to original contents of BM_WUC_ENABLE_REG.
   --  *
   --  *  Restore BM_WUC_ENABLE_REG to its original value.
   --  *
   --  *  Assumes semaphore already acquired and *phy_reg is the contents of the
   --  *  BM_WUC_ENABLE_REG before register(s) on BM_WUC_PAGE were accessed by
   --  *  caller.


   function E1000_Disable_PHY_Wakeup_Reg_Access_BM
     (HW      : access E1000_HW;
      PHY_Reg : in     u16_Pointer) return s32
   is
      Ret_Val : s32;

   begin
      -- Select Port Control Registers page.
      --
      Ret_Val := E1000_Set_Page_IGP (HW, shift_Left (BM_PORT_CTRL_PAGE,
                                     IGP_PAGE_SHIFT));
      if Ret_Val /= 0
      then
         e_dbg ("Could not set Port Control page");
         return Ret_Val;
      end if;


      -- Restore 769.17 to its original value.
      --
      Ret_Val := E1000e_Write_PHY_Reg_MDIC (HW, BM_WUC_ENABLE_REG, PHY_Reg.all);

      if Ret_Val /= 0
      then
         e_dbg ("Could not restore PHY register" & BM_PORT_CTRL_PAGE'Image & "." & BM_WUC_ENABLE_REG'Image);
      end if;

      return Ret_Val;
   end E1000_Disable_PHY_Wakeup_Reg_Access_BM;




   -----------------------------
   -- E1000e_Read_Phy_Reg_Bm2 --
   -----------------------------

   --    Read BM PHY register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to be read.
   --  *  @data:   Pointer to the read data.
   --  *
   --  *  Acquires semaphore, if necessary, then reads the PHY register at offset
   --  *  and storing the retrieved information in data.  Release any acquired
   --  *  semaphores before exiting.


   function E1000e_Read_Phy_Reg_Bm2
     (HW     : access E1000_HW;
      Offset : in     u32;
      Data   : in     u16_Pointer) return s32
   is
      Ret_Val :          s32;
      Page    : constant Unsigned_16 := u16 (shift_Right (Offset, IGP_PAGE_SHIFT));

   begin
      Ret_Val := HW.Phy.Ops.Acquire (HW);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- Page 800 works differently than the rest so it has its own func.
      --
      if Page = BM_WUC_PAGE
      then
         Ret_Val := E1000_Access_Phy_Wakeup_Reg_Bm (HW, Offset, Data, True, False);
         goto Release;
      end if;


      HW.Phy.Addr := 1;

      if Offset > MAX_PHY_MULTI_PAGE_REG
      then
         -- Page is shifted left, PHY expects (page x 32).
         --
         Ret_Val := E1000e_Write_Phy_Reg_Mdic (HW, BM_PHY_PAGE_SELECT, Page);

         if Ret_Val /= 0
         then
            goto Release;
         end if;
      end if;


      Ret_Val := E1000e_Read_Phy_Reg_Mdic (HW,
                                           Offset and MAX_PHY_REG_ADDRESS,
                                           Data);
      <<Release>>

      HW.Phy.Ops.Release (HW);

      return Ret_Val;
   end E1000e_Read_Phy_Reg_Bm2;




   ------------------------------
   -- E1000e_Write_Phy_Reg_Bm2 --
   ------------------------------

   --    Write BM PHY register.
   --
   --  *  @hw:     Pointer to the HW structure
   --  *  @offset: Register offset to write to
   --  *  @data:   Data to write at register offset
   --  *
   --  *  Acquires semaphore, if necessary, then writes the data to PHY register
   --  *  at the offset.  Release any acquired semaphores before exiting.


   function E1000e_Write_Phy_Reg_Bm2
     (HW     : access E1000_HW;
      Offset : in     Unsigned_32;
      Data   : in     Unsigned_16) return s32
   is
      Ret_Val :          s32;
      Page    : constant Unsigned_16 := u16 (shift_Right (Offset, IGP_PAGE_SHIFT));

   begin
      Ret_Val := HW.Phy.Ops.Acquire (HW);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- Page 800 works differently than the rest so it has its own func.
      --
      if Page = BM_WUC_PAGE
      then
         Ret_Val := E1000_Access_Phy_Wakeup_Reg_Bm (HW, Offset, Data'unrestricted_Access, False, False);
         goto Release;
      end if;


      HW.Phy.Addr := 1;

      if Offset > MAX_PHY_MULTI_PAGE_REG
      then
         -- Page is shifted left, PHY expects (page x 32).
         --
         Ret_Val := E1000e_Write_Phy_Reg_Mdic (HW, BM_PHY_PAGE_SELECT, Page);

         if Ret_Val /= 0
         then
            goto Release;
         end if;
      end if;


      Ret_Val := E1000e_Write_Phy_Reg_Mdic (HW,
                                            MAX_PHY_REG_ADDRESS and Offset,
                                            Data);

      <<Release>>

      HW.Phy.Ops.Release (HW);

      return Ret_Val;
   end E1000e_Write_Phy_Reg_Bm2;




   -------------------------------
   -- E1000_Power_Up_PHY_Copper --
   -------------------------------

   --    Restore copper link in case of PHY power down.
   --
   --  * @hw: Pointer to the HW structure.
   --  *
   --  * In the case of a PHY power down to save power, or to turn off link during a
   --  * driver unload, or wake on lan is not enabled, restore the link to previous
   --  * settings.


   procedure E1000_Power_Up_PHY_Copper
     (HW : access E1000_HW)
   is
      MII_Reg : aliased u16 := 0;
      Ret_Val :         s32;

   begin
      -- The PHY will retain its settings across a power down/up cycle.
      --
      Ret_Val := E1E_RPHY (HW, MII_BMCR, MII_Reg'unchecked_Access);

      if Ret_Val /= 0
      then
         E_DBG ("Error reading PHY register");
         return;

      end if;

      MII_Reg := MII_Reg and (not BMCR_PDOWN);
      E1E_WPHY (HW, MII_BMCR, MII_Reg);
   end E1000_Power_Up_PHY_Copper;





   ---------------------------------
   -- e1000_power_down_phy_copper --
   ---------------------------------

   --  Restore copper link in case of PHY power down.
   --
   --  * @hw: Pointer to the HW structure.
   --  *
   --  * In the case of a PHY power down to save power, or to turn off link during a
   --  * driver unload, or wake on lan is not enabled, restore the link to previous
   --  * settings.


   procedure E1000_Power_Down_PHY_Copper
     (HW : access E1000_HW)
   is
      MII_Reg : aliased Unsigned_16 := 0;
      Ret_Val :         s32;

   begin
      -- The PHY will retain its settings across a power down/up cycle.
      --
      Ret_Val := E1E_RPHY (HW, MII_BMCR, MII_Reg'unchecked_Access);

      if Ret_Val /= 0
      then
         e_dbg ("Error reading PHY register");
         return;
      end if;


      MII_Reg := MII_Reg or BMCR_PDOWN;
      E1E_WPHY (HW, MII_BMCR, MII_Reg);

      delay 1_500.0 * Microseconds;
   end E1000_Power_Down_PHY_Copper;




   ------------------------------
   -- e1000e_Disable_Phy_Retry --
   ------------------------------

   procedure e1000e_Disable_Phy_Retry
     (HW : access E1000_HW)
   is
   begin
      HW.PHY.Retry_Enabled := False;
   end e1000e_Disable_Phy_Retry;




   -----------------------------
   -- e1000e_Enable_PHY_Retry --
   -----------------------------

   procedure e1000e_Enable_PHY_Retry
     (HW : access E1000_HW)
   is
   begin
      HW.PHY.Retry_Enabled := True;
   end e1000e_Enable_PHY_Retry;




   ------------------------------
   -- E1000e_Read_Phy_Reg_Mdic --
   ------------------------------

   --  Read MDI control register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to be read.
   --  *  @data:   p.
   --  *
   --  *  Reads the MDI control register in the PHY at offset and stores the
   --  *  information read to data.


   function E1000e_Read_Phy_Reg_Mdic
     (Hw     : access E1000_Hw;
      Offset : in     u32;
      Data   : in     u16_Pointer) return s32
   is
      Mdic          : Unsigned_32 := 0;
      Retry_Max     : u32;
      Success       : Boolean;

   begin
      if Offset > Max_Phy_Reg_Address
      then
         e_dbg ("PHY Address" & Offset'Image & " is out of range");
         return -E1000_Err_Param;
      end if;


      if Hw.Phy.Retry_Enabled
      then
         Retry_Max := Hw.Phy.Retry_Count;
      else
         Retry_Max := 0;
      end if;

      -- Set up Op-code, Phy Address, and register offset in the MDI
      -- Control register. The MAC will take care of interfacing with the
      -- PHY to retrieve the desired data.
      --
      for Retry_Counter in 0 .. Retry_Max
      loop
         Success := True;
         Mdic    :=    shift_Left (Offset, E1000_Mdic_Reg_Shift)
           or shift_Left (Unsigned_32 (Hw.Phy.Addr), E1000_Mdic_Phy_Shift)
           or E1000_Mdic_Op_Read;

         Ew32 (Hw.all, Devices.e1000e.Registers.E1000_MDIC, Mdic);

         -- Poll the ready bit to see if the MDI read completed
         -- Increasing the time out as testing showed failures with
         -- the lower time out.
         --
         for I in 1 .. E1000_Gen_Poll_Timeout * 3
         loop
            delay 50.0 * Microseconds;
            Mdic := Er32 (Hw.all, Devices.e1000e.Registers.E1000_MDIC);
            exit when (Mdic and E1000_Mdic_Ready) /= 0;
         end loop;

         if (Mdic and E1000_Mdic_Ready) = 0
         then
            e_dbg ("MDI Read PHY Reg Address" & Offset'Image & " did not complete");
            Success := False;
         end if;

         if (Mdic and E1000_Mdic_Error) /= 0
         then
            e_dbg ("MDI Read PHY Reg Address" & Offset'Image & " Error");
            Success := False;
         end if;

         if Field_Get (E1000_Mdic_Reg_Mask, Mdic) /= Offset
         then
            e_dbg (  "MDI Read offset error - requested" & Offset'Image
                     &                       ", returned"  & Field_Get (E1000_Mdic_Reg_Mask, Mdic)'Image);
            Success := False;
         end if;

         -- Allow some time after each MDIC transaction to avoid
         -- reading duplicate data in the next MDIC transaction.
         --
         if Hw.Mac.Mac_Type = E1000_Pch2lan
         then
            delay 100.0 * Microseconds;
         end if;

         if Success
         then
            Data.all := Unsigned_16 (Mdic);
            return 0;
         end if;


         if Retry_Counter /= Retry_Max
         then
            e_dbg ("Perform retry on PHY transaction...");
            delay 10.0 * Milliseconds;
         end if;
      end loop;


      return -E1000_Err_Phy;
   end E1000e_Read_Phy_Reg_Mdic;




   -------------------------------
   -- E1000E_Write_PHY_Reg_MDIC --
   -------------------------------

   --  Write MDI control register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to write to.
   --  *  @data:   Data to write to register at offset.
   --  *
   --  *  Writes data to MDI control register in the PHY at offset.


   function E1000E_Write_PHY_Reg_MDIC
     (HW     : access E1000_HW;
      Offset : in     Unsigned_32;
      Data   : in     Unsigned_16) return s32
   is
      PHY            : E1000_PHY_Info.item renames HW.PHY;
      MDIC           : Unsigned_32 := 0;
      Retry_Max      : u32;
      Success        : Boolean;

   begin
      if Offset > MAX_PHY_REG_ADDRESS
      then
         e_dbg ("PHY Address" & Offset'Image & " is out of range");
         return -E1000_ERR_PARAM;
      end if;


      Retry_Max := (if PHY.Retry_Enabled then PHY.Retry_Count
                    else 0);

      -- Set up Op-code, Phy Address, and register offset in the MDI
      -- Control register. The MAC will take care of interfacing with the
      -- PHY to retrieve the desired data.
      --
      for Retry_Counter in 0 .. Retry_Max
      loop
         Success := True;
         MDIC    :=    u32 (Data)
           or shift_Left (Offset,   E1000_MDIC_REG_SHIFT)
           or shift_Left (PHY.Addr, E1000_MDIC_PHY_SHIFT)
           or E1000_MDIC_OP_WRITE;

         EW32 (Hw.all, Devices.e1000e.Registers.E1000_MDIC, MDIC);

         -- Poll the ready bit to see if the MDI read completed
         -- Increasing the time out as testing showed failures with
         -- the lower time out.
         --
         for I in 1 .. E1000_GEN_POLL_TIMEOUT * 3
         loop
            delay 50.0 * Microseconds;
            MDIC := ER32 (Hw.all, Devices.e1000e.Registers.E1000_MDIC);
            exit when (MDIC and E1000_MDIC_READY) /= 0;
         end loop;

         if (MDIC and E1000_MDIC_READY) = 0
         then
            e_dbg ("MDI Write PHY Reg Address" & Offset'Image & " did not complete");
            Success := False;
         end if;

         if (MDIC and E1000_MDIC_ERROR) /= 0
         then
            e_dbg ("MDI Write PHY Reg Address" & Offset'Image & " Error");
            Success := False;
         end if;

         if Field_Get (E1000_MDIC_REG_MASK, MDIC) /= Offset
         then
            e_dbg ("MDI Write offset error - requested" & Offset'Image &
                     ", returned" & Field_Get (E1000_MDIC_REG_MASK, MDIC)'Image);
            Success := False;
         end if;

         -- Allow some time after each MDIC transaction to avoid
         -- reading duplicate data in the next MDIC transaction.
         --
         if HW.MAC.mac_type = E1000_PCH2LAN
         then
            delay 100.0 * Microseconds;
         end if;

         if Success
         then
            return 0;
         end if;


         if Retry_Counter /= Retry_Max
         then
            e_dbg ("Perform retry on PHY transaction...");
            delay 10.0 * Milliseconds;
         end if;
      end loop;


      return -E1000_ERR_PHY;
   end E1000E_Write_PHY_Reg_MDIC;




   ---------------------------
   -- E1000_Read_Phy_Reg_Hv --
   ---------------------------

   --    Read HV PHY register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to be read.
   --  *  @data:   Pointer to the read data.
   --  *
   --  *  Acquires semaphore then reads the PHY register at offset and stores
   --  *  the retrieved information in data.  Release the acquired semaphore
   --  *  before exiting.


   function E1000_Read_Phy_Reg_Hv
     (HW     : access E1000_HW;
      Offset : in     Unsigned_32;
      Data   : in     u16_Pointer) return s32
   is
   begin
      return E1000_Read_Phy_Reg_Hv (HW       => HW,
                                    Offset   => Offset,
                                    Data     => Data,
                                    Locked   => False,
                                    Page_Set => False);
   end E1000_Read_Phy_Reg_Hv;





   ----------------------------------
   -- e1000_read_phy_reg_hv_locked --
   ----------------------------------

   --    Read HV PHY register
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to be read.
   --  *  @data:   Pointer to the read data.
   --  *
   --  *  Reads the PHY register at offset and stores the retrieved information
   --  *  in data.  Assumes semaphore already acquired.


   function E1000_Read_Phy_Reg_Hv_Locked
     (HW     : access E1000_HW;
      Offset : in     Unsigned_32;
      Data   : in     u16_Pointer) return s32
   is
   begin
      return E1000_Read_Phy_Reg_Hv (HW       => HW,
                                    Offset   => Offset,
                                    Data     => Data,
                                    Locked   => True,
                                    Page_Set => False);
   end E1000_Read_Phy_Reg_Hv_Locked;




   --------------------------------
   -- e1000_read_phy_reg_page_hv --
   --------------------------------

   --    Read HV PHY register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to write to.
   --  *  @data:   Data to write at register offset.
   --  *
   --  *  Reads the PHY register at offset and stores the retrieved information
   --  *  in data.  Assumes semaphore already acquired and page already set.


   function E1000_Read_Phy_Reg_Page_Hv
     (HW     : access E1000_HW;
      Offset : in     Unsigned_32;
      Data   : in     u16_Pointer) return s32
   is
   begin
      return E1000_Read_Phy_Reg_Hv (HW       => HW,
                                    Offset   => Offset,
                                    Data     => Data,
                                    Locked   => True,
                                    Page_Set => True);
   end E1000_Read_Phy_Reg_Page_Hv;




   ----------------------------
   -- E1000_Write_Phy_Reg_Hv --
   ----------------------------

   --    Write HV PHY register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to write to.
   --  *  @data:   Data to write at register offset.
   --  *
   --  *  Acquires semaphore then writes the data to PHY register at the offset.
   --  *  Release the acquired semaphores before exiting.


   function E1000_Write_Phy_Reg_Hv
     (HW     : access E1000_HW;
      Offset : in     u32;
      Data   : in     u16) return s32
   is
   begin
      return E1000_Write_Phy_Reg_Hv (HW,
                                     Offset,
                                     Data,
                                     False,
                                     False);
   end E1000_Write_Phy_Reg_Hv;




   -----------------------------------
   -- e1000_write_phy_reg_hv_locked --
   -----------------------------------

   --    Write HV PHY register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to write to.
   --  *  @data:   Data to write at register offset.
   --  *
   --  *  Writes the data to PHY register at the offset.  Assumes semaphore
   --  *  already acquired.


   function E1000_Write_Phy_Reg_Hv_Locked
     (HW     : access E1000_HW;
      Offset : in     u32;
      Data   : in     u16) return s32
   is
   begin
      return E1000_Write_Phy_Reg_Hv (HW, Offset, Data, True, False);
   end E1000_Write_Phy_Reg_Hv_Locked;




   ---------------------------------
   -- e1000_write_phy_reg_page_hv --
   ---------------------------------

   --    Write HV PHY register.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Register offset to write to.
   --  *  @data:   Data to write at register offset.
   --  *
   --  *  Writes the data to PHY register at the offset.  Assumes semaphore
   --  *  already acquired and page already set.


   function E1000_Write_Phy_Reg_Page_HV
     (HW     : access E1000_HW;
      Offset : in     u32;
      Data   : in     u16) return s32
   is
   begin
      return E1000_Write_Phy_Reg_HV (HW, Offset, Data, True, True);
   end E1000_Write_Phy_Reg_Page_HV;




   ------------------------------------
   -- E1000_Link_Stall_Workaround_HV --
   ------------------------------------

   --    Si workaround.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  This function works around a Si bug where the link partner can get
   --  *  a link up indication before the PHY does.  If small packets are sent
   --  *  by the link partner they can be placed in the packet buffer without
   --  *  being properly accounted for by the PHY and will stall preventing
   --  *  further packets from being received.  The workaround is to clear the
   --  *  packet buffer after the PHY detects link up.


   function E1000_Link_Stall_Workaround_HV
     (HW : access E1000_HW) return s32
   is
      use Devices.e1000e.Ich8Lan;

      Ret_Val :         s32        := 0;
      Data    : aliased Unsigned_16;

   begin
      if HW.PHY.phy_type /= E1000_PHY_82578
      then
         return 0;
      end if;


      -- Do not apply workaround if in PHY loopback bit 14 set.
      --
      Ret_Val := E1E_RPHY (HW, MII_BMCR, Data'unchecked_Access);

      if Ret_Val /= 0
      then
         e_dbg ("Error reading PHY register");
         return Ret_Val;
      end if;


      if (Data and BMCR_LOOPBACK) /= 0
      then
         return 0;
      end if;


      -- check if link is up and at 1Gbps.
      --
      Ret_Val := E1E_RPHY (HW, BM_CS_STATUS, Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Data := Data and (   BM_CS_STATUS_LINK_UP
                        or BM_CS_STATUS_RESOLVED
                        or BM_CS_STATUS_SPEED_MASK);

      if Data /= (   BM_CS_STATUS_LINK_UP
                     or BM_CS_STATUS_RESOLVED
                     or BM_CS_STATUS_SPEED_1000)
      then
         return 0;
      end if;


      delay 200.0 * Milliseconds;  -- Equivalent to msleep (200).

      -- Flush the packets in the fifo buffer.
      --
      Ret_Val := E1E_WPHY (HW,
                           HV_MUX_DATA_CTRL,
                           (   HV_MUX_DATA_CTRL_GEN_TO_MAC
                            or HV_MUX_DATA_CTRL_FORCE_SPEED));
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      return E1E_WPHY (HW,
                       HV_MUX_DATA_CTRL,
                       HV_MUX_DATA_CTRL_GEN_TO_MAC);
   end E1000_Link_Stall_Workaround_HV;




   -----------------------------------
   -- E1000_Copper_Link_Setup_82577 --
   -----------------------------------

   --  Setup 82577 PHY for copper link.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Sets up Carrier-sense on Transmit and downshift values.


   function E1000_Copper_Link_Setup_82577
     (HW : access E1000_HW) return s32
   is
      Ret_Val  :         s32;
      Phy_Data : aliased Unsigned_16;

   begin
      -- Enable CRS on Tx. This must be set for half-duplex operation.
      --
      Ret_Val := E1e_Rphy (HW, I82577_CFG_REG, Phy_Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Phy_Data := Phy_Data or I82577_CFG_ASSERT_CRS_ON_TX;

      -- Enable downshift.
      --
      Phy_Data := Phy_Data or I82577_CFG_ENABLE_DOWNSHIFT;
      Ret_Val  := E1e_Wphy (HW, I82577_CFG_REG, Phy_Data);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- Set MDI/MDIX mode.
      --
      Ret_Val := E1e_Rphy (HW, I82577_PHY_CTRL_2, Phy_Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Phy_Data := Phy_Data and (not I82577_PHY_CTRL2_MDIX_CFG_MASK);

      -- Options:
      --
      --   0 - Auto (default)
      --   1 - MDI mode
      --   2 - MDI-X mode
      --
      case HW.Phy.Mdix
      is
         when 1      =>   null;
         when 2      =>   Phy_Data := Phy_Data or I82577_PHY_CTRL2_MANUAL_MDIX;
         when others =>   Phy_Data := Phy_Data or I82577_PHY_CTRL2_AUTO_MDI_MDIX;
      end case;

      Ret_Val := E1e_Wphy (HW, I82577_PHY_CTRL_2, Phy_Data);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      return E1000_Set_Master_Slave_Mode (HW);
   end E1000_Copper_Link_Setup_82577;




   --------------------------------
   -- E1000_Check_Polarity_82577 --
   --------------------------------

   --  Checks the polarity.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Success returns 0, Failure returns -E1000_ERR_PHY (-2)
   --  *
   --  *  Polarity is determined based on the PHY specific status register.


   function E1000_Check_Polarity_82577
     (HW : access E1000_HW) return s32
   is
      Ret_Val :         s32;
      Data    : aliased Unsigned_16;

   begin
      Ret_Val := E1e_Rphy (HW, I82577_PHY_STATUS_2, Data'unchecked_Access);

      if Ret_Val = 0
      then
         HW.PHY.Cable_Polarity := (if (Data and I82577_PHY_STATUS2_REV_POLARITY) /= 0 then E1000_Rev_Polarity_Reversed
                                                                                      else E1000_Rev_Polarity_Normal);
      end if;

      return Ret_Val;
   end E1000_Check_Polarity_82577;




   ------------------------------
   -- e1000_get_phy_info_82577 --
   ------------------------------

   --    Retrieve I82577 PHY information.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Read PHY status to determine if link is up.  If link is up, then
   --  *  set/determine 10base-T extended distance and polarity correction.  Read
   --  *  PHY port status to determine MDI/MDIx and speed.  Based on the speed,
   --  *  determine on the cable length, local and remote receiver.


   function E1000_Get_Phy_Info_82577
     (HW : access E1000_HW) return s32
   is
      Phy     :         E1000_Phy_Info.item renames HW.Phy;
      Ret_Val :         s32;
      Data    : aliased Unsigned_16;
      Link    :         Boolean;

   begin
      Ret_Val := E1000e_Phy_Has_Link_Generic (HW, 1, 0, Link);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      if not Link
      then
         e_dbg ("Phy info is only valid if link is up");
         return -E1000_ERR_CONFIG;
      end if;


      Phy.Polarity_Correction := True;

      Ret_Val := E1000_Check_Polarity_82577 (HW);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Ret_Val := E1e_Rphy (HW, I82577_PHY_STATUS_2, Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Phy.Is_Mdix := (Data and I82577_PHY_STATUS2_MDIX) /= 0;

      if (Data and I82577_PHY_STATUS2_SPEED_MASK) = I82577_PHY_STATUS2_SPEED_1000MBPS
      then
         Ret_Val := HW.Phy.Ops.Get_Cable_Length (HW);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Ret_Val := E1e_Rphy (HW, MII_STAT1000, Data'unchecked_Access);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Phy.Local_Rx := (if (Data and LPA_1000LOCALRXOK) /= 0 then E1000_1000t_Rx_Status_Ok
                                                               else E1000_1000t_Rx_Status_Not_Ok);

         Phy.Remote_Rx := (if (Data and LPA_1000REMRXOK)  /= 0 then E1000_1000t_Rx_Status_Ok
                                                               else E1000_1000t_Rx_Status_Not_Ok);
      else
         Phy.Cable_Length := E1000_CABLE_LENGTH_UNDEFINED;
         Phy.Local_Rx     := E1000_1000t_Rx_Status_Undefined;
         Phy.Remote_Rx    := E1000_1000t_Rx_Status_Undefined;
      end if;

      return 0;
   end E1000_Get_Phy_Info_82577;





   ----------------------------------------
   -- e1000_phy_force_speed_duplex_82577 --
   ----------------------------------------

   --    Force speed/duplex for I82577 PHY.
   --
   --  *  @hw: pointer to the HW structure.
   --  *
   --  *  Calls the PHY setup function to force speed and duplex.


   function E1000_Phy_Force_Speed_Duplex_82577
     (HW : access E1000_HW) return s32
   is
      Phy      :         E1000_Phy_Info.ITEM renames HW.Phy;
      Ret_Val  :         s32;
      Phy_Data : aliased Unsigned_16;
      Link     :         Boolean;

   begin
      Ret_Val := E1e_Rphy (HW, MII_BMCR, Phy_Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      E1000e_Phy_Force_Speed_Duplex_Setup (HW, Phy_Data'unchecked_Access);

      Ret_Val := E1e_Wphy (HW, MII_BMCR, Phy_Data);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      delay 1.0 * Microseconds;

      if Phy.Autoneg_Wait_To_Complete
      then
         E_Dbg ("Waiting for forced speed/duplex link on 82577 phy");

         Ret_Val := E1000e_Phy_Has_Link_Generic (HW,
                                                 PHY_FORCE_LIMIT,
                                                 100_000,
                                                 Link);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         if not Link
         then
            E_Dbg ("Link taking longer than expected.");
         end if;

         -- Try once more.
         --
         Ret_Val := E1000e_Phy_Has_Link_Generic (HW,
                                                 PHY_FORCE_LIMIT,
                                                 100_000,
                                                 Link);
      end if;


      return Ret_Val;
   end E1000_Phy_Force_Speed_Duplex_82577;





   ----------------------------------
   -- e1000_get_cable_length_82577 --
   ----------------------------------

   --    Determine cable length for 82577 PHY.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  * Reads the diagnostic status register and verifies result is valid before
   --  * placing it in the phy_cable_length field.


   function E1000_Get_Cable_Length_82577
     (HW : access E1000_HW) return s32
   is
      Phy      :         E1000_PHY_Info.item renames HW.Phy;
      Ret_Val  :         s32;
      Phy_Data : aliased Unsigned_16;
      Length   :         Unsigned_16;

   begin
      Ret_Val := E1e_Rphy (HW,
                           I82577_PHY_DIAG_STATUS,
                           Phy_Data'unchecked_Access);
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Length := FIELD_GET (I82577_DSTATUS_CABLE_LENGTH, Phy_Data);

      if Length = E1000_CABLE_LENGTH_UNDEFINED
      then
         return -E1000_ERR_PHY;
      end if;


      Phy.Cable_Length := Length;

      return 0;
   end E1000_Get_Cable_Length_82577;


end Devices.e1000e.Physical_Layer;
