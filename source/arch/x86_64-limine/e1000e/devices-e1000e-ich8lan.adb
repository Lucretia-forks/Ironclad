with
     Devices.e1000e.Hardware.e1000_phy_info,
     Devices.e1000e.Hardware.e1000_nvm_info,
     Devices.e1000e.Hardware.E1000_mac_Info,
     Devices.e1000e.Registers,
     Devices.e1000e.Manage,
     Devices.e1000e.Base.Port;


package body Devices.e1000e.Ich8Lan
is
   use Devices.e1000e.Hardware,
       Devices.e1000e.Base.Port,
       Linux,
       Interfaces.C;


   ---------------------------
   -- ICH8_HWS_Flash_Status --
   ---------------------------

   -- ICH GbE Flash Hardware Sequencing Flash Status Register bit breakdown
   -- Offset 04h HSFSTS

   type Sector_Erase_Size is mod 4;

   type ICH8_HSFSTS is
      record
         FLCDONE    : Boolean;               -- bit 0    Flash Cycle Done
         FLCERR     : Boolean;               -- bit 1    Flash Cycle Error
         DAEL       : Boolean;               -- bit 2    Direct Access error Log
         BERASESZ   : Sector_Erase_Size;     -- bit 4:3  Sector Erase Size
         FLCINPROG  : Boolean;               -- bit 5    flash cycle in Progress
         Reserved1  : Unsigned_8;            -- bit 13:6 Reserved
         FLDESVALID : Boolean;               -- bit 14   Flash Descriptor Valid
         FLOCKDN    : Boolean;               -- bit 15   Flash Config Lock-Down
      end record
     with
       Size => 16;

   for ICH8_HSFSTS use
      record
         FLCDONE    at 0 range  0 ..  0;
         FLCERR     at 0 range  1 ..  1;
         DAEL       at 0 range  2 ..  2;
         BERASESZ   at 0 range  3 ..  4;
         FLCINPROG  at 0 range  5 ..  5;
         Reserved1  at 0 range  6 .. 13;
         FLDESVALID at 0 range 14 .. 14;
         FLOCKDN    at 0 range 15 .. 15;
      end record;


   type ICH8_HWS_Flash_Status (As_Value : Boolean := False) is
      record
         case As_Value
         is
            when False =>   HSF_Status : ICH8_HSFSTS;
            when True  =>   REGVAL     : Unsigned_16;
         end case;
      end record
     with
       Size => 16,
       unchecked_Union;

   for ICH8_HWS_Flash_Status use
      record
         HSF_Status at 0 range 0 .. 15;
         REGVAL     at 0 range 0 .. 15;
      end record;




   -------------------------
   -- ICH8_HWS_FLASH_CTRL --
   -------------------------

   -- ICH GbE Flash Hardware Sequencing Flash control Register bit breakdown
   -- Offset 06h FLCTL

   type ICH8_HSFLCTL is record
      FLCGO     : Unsigned_16 range 0 ..  1;    -- 0     Flash Cycle Go
      FLCYCLE   : Unsigned_16 range 0 ..  3;    -- 2:1   Flash Cycle
      RESERVED1 : Unsigned_16 range 0 .. 31;    -- 7:3   Reserved
      FLDBCOUNT : Unsigned_16 range 0 ..  3;    -- 9:8   Flash Data Byte Count
      FLOCKDN   : Unsigned_16 range 0 .. 63;    -- 15:10 Reserved
   end record;

   for ICH8_HSFLCTL use record
      FLCGO     at 0 range  0 ..  0;
      FLCYCLE   at 0 range  1 ..  2;
      RESERVED1 at 0 range  3 ..  7;
      FLDBCOUNT at 0 range  8 ..  9;
      FLOCKDN   at 0 range 10 .. 15;
   end record;


   type ICH8_HWS_FLASH_CTRL (Discriminant : Boolean := False) is
      record
         case Discriminant
         is
            when False =>   HSF_CTRL : ICH8_HSFLCTL;
            when True  =>   REGVAL   : Unsigned_16;
         end case;
      end record
     with
       Size => 16,
       unchecked_Union;



   ---------------------------
   -- ICH8_HWS_FLASH_REGACC --
   ---------------------------

   -- ICH Flash Region Access Permissions.

   type ICH8_FLRACC is
      record
         GRRA  : Unsigned_8;  -- 0:7   GbE region Read Access
         GRWA  : Unsigned_8;  -- 8:15  GbE region Write Access
         GMRAG : Unsigned_8;  -- 16:23 GbE Master Read Access Grant
         GMWAG : Unsigned_8;  -- 24:31 GbE Master Write Access Grant
      end record;

   for ICH8_FLRACC use
      record
         GRRA  at 0 range  0 ..  7;
         GRWA  at 0 range  8 .. 15;
         GMRAG at 0 range 16 .. 23;
         GMWAG at 0 range 24 .. 31;
      end record;


   type ICH8_HWS_FLASH_REGACC (As_FLRACC : Boolean := True) is
      record
         case As_FLRACC
         is
            when True  =>   HSF_FLREGACC : ICH8_FLRACC;
            when False =>   REGVAL       : Unsigned_32;
         end case;
      end record
     with
       Size => 32,
       unchecked_Union;

   for ICH8_HWS_FLASH_REGACC use
      record
         HSF_FLREGACC at 0 range 0 .. 31;
         REGVAL       at 0 range 0 .. 31;
      end record;



   --------------------------------
   -- ICH8_Flash_Protected_Range --
   --------------------------------

   -- ICH Flash Protected Region

   type ICH8_PR is
      record
         Base      : Unsigned_32 range 0 .. 2**13 - 1;     -- 0:12  Protected Range Base
         Reserved1 : Unsigned_32 range 0 .. 2**2  - 1;     -- 13:14 Reserved
         RPE       : Boolean;                              -- 15    Read Protection Enable
         Limit     : Unsigned_32 range 0 .. 2**13 - 1;     -- 16:28 Protected Range Limit
         Reserved2 : Unsigned_32 range 0 .. 2**2  - 1;     -- 29:30 Reserved
         WPE       : Boolean;                              -- 31    Write Protection Enable
      end record
     with Size => 32;

   for ICH8_PR use
      record
         Base      at 0 range  0 .. 12;
         Reserved1 at 0 range 13 .. 14;
         RPE       at 0 range 15 .. 15;
         Limit     at 0 range 16 .. 28;
         Reserved2 at 0 range 29 .. 30;
         WPE       at 0 range 31 .. 31;
      end record;


   type ICH8_Flash_Protected_Range (As_Record : Boolean := True) is
      record
         case As_Record
         is
            when True  =>   my_Range : ICH8_PR;
            when False =>   Regval   : Unsigned_32;
         end case;
      end record
     with
       Size => 32,
       unchecked_Union;

   for ICH8_Flash_Protected_Range use
      record
         my_Range at 0 range 0 .. 31;
         Regval   at 0 range 0 .. 31;
      end record;




   ------------------------
   -- Hw Flash Utilities --
   ------------------------


   function Er16flash (Hw : access e1000_hw; Reg : C.Unsigned_Long) return Unsigned_16
   is
   begin
      return readw (hw.flash_address + Storage_Offset (reg));
   end Er16flash;


   function Er32flash (Hw : access e1000_hw; Reg : C.Unsigned_Long) return Unsigned_32 is
   begin
      return readl (hw.flash_address + Storage_Offset (reg));
   end Er32flash;


   procedure Ew16flash (Hw : access e1000_hw; Reg : C.Unsigned_Long; Val : Unsigned_16) is
   begin
      writew (val,
              hw.flash_address + Storage_Offset (Reg));
   end Ew16flash;


   procedure Ew32flash (Hw : access e1000_hw; Reg : C.Unsigned_Long; Val : Unsigned_32) is
   begin
      writel (val,
              hw.flash_address + Storage_Offset (Reg));
   end Ew32flash;




   --------------------------------
   -- Internal Subprograms Specs --
   --------------------------------



   --  procedure E1000_Clear_Hw_Cntrs_Ich8lan (Hw : access E1000_HW);

   procedure E1000_Initialize_Hw_Bits_Ich8lan        (Hw : access E1000_HW);
   procedure E1000_Power_Down_Phy_Copper_Ich8lan     (Hw : access E1000_HW);
   procedure E1000_Lan_Init_Done_Ich8lan             (Hw : access E1000_HW);
   procedure E1000_Gate_Hw_Phy_Config_Ich8lan        (Hw : access E1000_HW;   Gate     : in Boolean);

   function  E1000_Retry_Write_Flash_Byte_Ich8lan    (Hw : access E1000_HW;   Offset   : in Unsigned_32;   Byte  : in     Unsigned_8)  return s32;
   function  E1000_Read_Flash_Byte_Ich8lan           (Hw : access E1000_HW;   Offset   : in Unsigned_32;   Data  :    out Unsigned_8)  return s32;
   function  E1000_Read_Flash_Word_Ich8lan           (Hw : access E1000_HW;   Offset   : in Unsigned_32;   Data  :    out Unsigned_16) return s32;
   function  E1000_Read_Flash_Data32_Ich8lan         (Hw : access E1000_HW;   Offset   : in Unsigned_32;   Data  :    out Unsigned_32) return s32;
   function  E1000_Read_Flash_Dword_Ich8lan          (Hw : access E1000_HW;   Offset   : in Unsigned_32;   Data  :    out Unsigned_32) return s32;
   function  E1000_Write_Flash_Data32_Ich8lan        (Hw : access E1000_HW;   Offset   : in Unsigned_32;   Data  : in     Unsigned_32) return s32;
   function  E1000_Retry_Write_Flash_Dword_Ich8lan   (Hw : access E1000_HW;   Offset   : in Unsigned_32;   Dword : in     Unsigned_32) return s32;
   function  E1000_Rar_Set_Pch2lan                   (Hw : access E1000_HW;   Addr     : in u8_Pointer;    Index : in     u32)         return C.int;
   function  E1000_Rar_Set_Pch_Lpt                   (Hw : access E1000_HW;   Addr     : in u8_Pointer;    Index : in     u32)         return C.int;
   function  E1000_Read_Flash_Data_Ich8lan           (Hw : access E1000_HW;   Offset   : in Unsigned_32;   Size  : in     Unsigned_8;
                                                                                                           Data  :    out Unsigned_16) return s32;

   function  E1000_Set_Lplu_State_Pchlan             (Hw : access E1000_HW;   Active   : in Boolean)     return s32;
   function  E1000_K1_Gig_Workaround_Hv              (Hw : access E1000_HW;   Link     : in Boolean)     return s32;
   function  E1000_Disable_Ulp_Lpt_Lp                (Hw : access E1000_HW;   Force    : in Boolean)     return s32;
   function  E1000_Oem_Bits_Config_Ich8lan           (Hw : access E1000_HW;   D0_State : in Boolean)     return s32;
   function  E1000_Erase_Flash_Bank_Ich8lan          (Hw : access E1000_HW;   Bank     : in Unsigned_32) return s32;

   function  E1000_Id_Led_Init_Pchlan                (Hw : access E1000_Hw) return s32;
   function  E1000_Setup_Led_Pchlan                  (Hw : access E1000_HW) return s32;
   function  E1000_Cleanup_Led_Pchlan                (Hw : access E1000_HW) return s32;
   function  E1000_Led_On_Pchlan                     (Hw : access E1000_HW) return s32;
   function  E1000_Led_Off_Pchlan                    (Hw : access E1000_HW) return s32;
   function  E1000_K1_Workaround_Lv                  (Hw : access E1000_HW) return s32;
   function  E1000_Setup_Copper_Link_Pch_Lpt         (Hw : access E1000_HW) return s32;
   function  E1000_Kmrn_Lock_Loss_Workaround_Ich8lan (Hw : access E1000_HW) return s32;
   function  E1000_Cleanup_Led_Ich8lan               (Hw : access E1000_HW) return s32;
   function  E1000_Led_On_Ich8lan                    (Hw : access E1000_HW) return s32;
   function  E1000_Led_Off_Ich8lan                   (Hw : access E1000_HW) return s32;
   function  E1000_Rar_Get_Count_Pch_Lpt             (Hw : access E1000_HW) return u32;
   function  E1000_Set_Mdio_Slow_Mode_Hv             (Hw : access E1000_HW) return s32;
   function  E1000_Check_Mng_Mode_Ich8lan            (Hw : access E1000_HW) return Boolean;
   function  E1000_Check_Mng_Mode_Pchlan             (Hw : access E1000_HW) return Boolean;






   ---------------------------------
   -- Internal Subprograms Bodies --
   ---------------------------------



   ------------------------------------
   -- E1000_Phy_Is_Accessible_Pchlan --
   ------------------------------------

   --  Check if able to access PHY registers.
   --  @hw: pointer to the HW structure
   --
   --  Test access to the PHY registers by reading the PHY ID registers.  If
   --  the PHY ID is already known (e.g. resume path) compare it with known ID,
   --  otherwise assume the read PHY ID is correct if it is valid.
   --
   --  Assumes the sw/fw/hw semaphore is already acquired.

   function E1000_Phy_Is_Accessible_Pchlan
     (Hw : access e1000_hw) return Boolean
   is
      Phy_Reg     : aliased Unsigned_16 := 0;
      Phy_Id      :         Unsigned_32 := 0;
      Ret_Val     :         s32         := 0;
      Retry_Count :         Unsigned_16;
      Mac_Reg     :         Unsigned_32 := 0;

   begin
      for Retry_Count in 0 .. 1
      loop
         Ret_Val := E1e_Rphy_Locked (Hw,
                                     MII_PHYSID1,
                                     Phy_Reg'unchecked_Access);
         if        Ret_Val /= 0
           or else Phy_Reg  = 16#FFFF#
         then
            goto Continue;
         end if;

         Phy_Id  := Unsigned_32 (Phy_Reg) * 2**16;

         Ret_Val := E1e_Rphy_Locked (Hw,
                                     MII_PHYSID2,
                                     Phy_Reg'unchecked_Access);

         if        Ret_Val /= 0
           or else Phy_Reg  = 16#FFFF#
         then
            Phy_Id := 0;
            goto Continue;
         end if;

         Phy_Id :=     Phy_Id
                   or (Unsigned_32 (Phy_Reg) and PHY_REVISION_MASK);
         exit;

         <<Continue>>
      end loop;


      if Hw.Phy.Id /= 0
      then
         if Hw.Phy.Id = Phy_Id
         then
            goto Done;
         end if;

      elsif Phy_Id /= 0
      then
         Hw.Phy.Id := Phy_Id;
         Hw.Phy.Revision := Unsigned_32 (Phy_Reg) and not PHY_REVISION_MASK;
         goto Done;
      end if;


      -- In case the PHY needs to be in mdio slow mode,
      -- set slow mode and try to get the PHY id again.
      --
      if Hw.Mac.mac_Type < E1000_PCH_LPT
      then
         Hw.Phy.Ops.Release (Hw);
         Ret_Val := E1000_Set_Mdio_Slow_Mode_Hv (Hw);

         if Ret_Val = 0
         then
            Ret_Val := E1000e_Get_Phy_Id (Hw);
         end if;

         declare
            Unused : s32;
         begin
            Unused := Hw.Phy.Ops.Acquire (Hw);
         end;
      end if;

      if Ret_Val /= 0
      then
         return False;
      end if;


      <<Done>>
      if Hw.Mac.mac_Type >= E1000_PCH_LPT
      then
         -- Only unforce SMBus if ME is not active.
         if (    Er32 (Hw.all, Devices.e1000e.Registers.E1000_FWSM)
             and E1000_ICH_FWSM_FW_VALID)       = 0
         then
            -- Switching PHY interface always returns MDI error
            -- so disable retry mechanism to avoid wasting time.
            E1000e_Disable_Phy_Retry (Hw);

            -- Unforce SMBus mode in PHY.
            declare
               Unused : s32;
            begin
               Unused  := E1e_Rphy_Locked (Hw,
                                           CV_SMB_CTRL,
                                           Phy_Reg'unchecked_Access);
               Phy_Reg := Phy_Reg and not CV_SMB_CTRL_FORCE_SMBUS;
               Unused  := E1e_Wphy_Locked (Hw,
                                           CV_SMB_CTRL,
                                           Phy_Reg);
            end;

            E1000e_Enable_Phy_Retry (Hw);

            -- Unforce SMBus mode in MAC.
            Mac_Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT);
            Mac_Reg := Mac_Reg and not E1000_CTRL_EXT_FORCE_SMBUS;

            Ew32 (Hw.all,
                  Devices.e1000e.Registers.E1000_CTRL_EXT,
                  Mac_Reg);
         end if;
      end if;

      return True;
   end E1000_Phy_Is_Accessible_Pchlan;




   -----------------------------------
   -- E1000_Toggle_Lanphypc_Pch_Lpt --
   -----------------------------------

   --  Toggle the LANPHYPC pin value.
   --  @hw: pointer to the HW structure
   --
   --  Toggling the LANPHYPC pin value fully power-cycles the PHY and is
   --  used to reset the PHY to a quiescent state when necessary.

   procedure E1000_Toggle_Lanphypc_Pch_Lpt
     (HW : access E1000_HW)
   is

      Mac_Reg : Unsigned_32;
   begin
      -- Set Phy Config Counter to 50msec.
      --
      Mac_Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_FEXTNVM3);
      Mac_Reg := Mac_Reg and (not E1000_FEXTNVM3_PHY_CFG_COUNTER_MASK);
      Mac_Reg := Mac_Reg or E1000_FEXTNVM3_PHY_CFG_COUNTER_50MSEC;

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_FEXTNVM3, Mac_Reg);

      -- Toggle LANPHYPC Value bit.
      --
      Mac_Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);
      Mac_Reg := Mac_Reg or E1000_CTRL_LANPHYPC_OVERRIDE;
      Mac_Reg := Mac_Reg and (not E1000_CTRL_LANPHYPC_VALUE);

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, Mac_Reg);
      E1E_Flush (Hw);
      delay 0.000015;  -- 15 microseconds

      Mac_Reg := Mac_Reg and (not E1000_CTRL_LANPHYPC_OVERRIDE);

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, Mac_Reg);
      E1E_Flush (Hw);


      if HW.Mac.Mac_Type < E1000_Pch_Lpt
      then
         delay 0.050;  -- 50 milliseconds
      else
         declare
            Count : Natural := 20;
            Ctrl_Ext_Result : Unsigned_32;
         begin
            loop
               delay 0.0055;  -- 5.5 milliseconds
               Ctrl_Ext_Result := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT);
               exit when   (Ctrl_Ext_Result and E1000_CTRL_EXT_LPCD) /= 0
                         or Count = 0;
               Count := Count - 1;
            end loop;

            delay 0.030;  -- 30 milliseconds
         end;
      end if;
   end E1000_Toggle_Lanphypc_Pch_Lpt;




   ---------------------------------------
   -- E1000_Init_PHY_Workarounds_PCHLAN --
   ---------------------------------------

   --  PHY initialization workarounds.
   --  @hw: pointer to the HW structure
   --
   --  Workarounds/flow necessary for PHY initialization during driver load
   --  and resume paths.

   function E1000_Init_PHY_Workarounds_PCHLAN (HW : access E1000_HW) return s32
   is
      Adapter : access   E1000_Adapter.item := HW.Adapter;
      FWSM    : constant Unsigned_32        := ER32 (HW.all, Devices.e1000e.Registers.E1000_FWSM);
      MAC_Reg :          Unsigned_32;
      Ret_Val :          s32;
   begin
      -- Gate automatic PHY configuration by hardware on managed and
      -- non-managed 82579 and newer adapters.
      --
      E1000_Gate_HW_PHY_Config_ICH8LAN (HW, True);

      -- It is not possible to be certain of the current state of ULP
      -- so forcibly disable it.
      --
      HW.Dev_Spec.ICH8LAN.ULP_State := E1000_ULP_State_Unknown;
      Ret_Val                       := E1000_Disable_ULP_LPT_LP (HW, True);

      if Ret_Val /= 0
      then
         e_warn ("Failed to disable ULP");
      end if;

      Ret_Val := HW.PHY.Ops.Acquire (HW);

      if Ret_Val /= 0
      then
         e_dbg ("Failed to initialize PHY flow");
         return Ret_Val;
      end if;

      -- There is no guarantee that the PHY is accessible at this time
      -- so disable retry mechanism to avoid wasting time.
      --
      E1000E_Disable_PHY_Retry (HW);

      -- The MAC-PHY interconnect may be in SMBus mode. If the PHY is
      -- inaccessible and resetting the PHY is not blocked, toggle the
      -- LANPHYPC Value bit to force the interconnect to PCIe mode.
      --
      case HW.MAC.mac_Type
      is
         when E1000_PCH_LPT | E1000_PCH_SPT | E1000_PCH_CNP | E1000_PCH_TGP |
              E1000_PCH_ADP | E1000_PCH_MTP | E1000_PCH_LNP | E1000_PCH_PTP |
              E1000_PCH_NVP =>
            if E1000_PHY_Is_Accessible_PCHLAN (HW)
            then
               null;
            else
               -- Before toggling LANPHYPC, see if PHY is accessible by
               -- forcing MAC to SMBus mode first.
               --
               MAC_Reg := ER32 (HW.all, Devices.e1000e.Registers.E1000_CTRL_EXT);
               MAC_Reg := MAC_Reg or E1000_CTRL_EXT_FORCE_SMBUS;
               EW32 (HW.all,
                     Devices.e1000e.Registers.E1000_CTRL_EXT,
                     MAC_Reg);

               -- Wait 50 milliseconds for MAC to finish any retries
               -- that it might be trying to perform from previous
               -- attempts to acknowledge any phy read requests.
               --
               delay 0.050;
            end if;

         when E1000_PCH2LAN =>
            if not E1000_PHY_Is_Accessible_PCHLAN (HW)
            then
               null;
            end if;

         when E1000_PCHLAN =>
            if (HW.MAC.mac_Type = E1000_PCHLAN) and
              ((FWSM and E1000_ICH_FWSM_FW_VALID) /= 0)
            then
               null;
            end if;

            if HW.PHY.Ops.Check_Reset_Block (HW) /= 0
            then
               e_dbg ("Required LANPHYPC toggle blocked by ME");
               Ret_Val := -E1000_ERR_PHY;
            else
               -- Toggle LANPHYPC Value bit.
               --
               E1000_Toggle_LANPHYPC_PCH_LPT (HW);

               if HW.MAC.mac_Type >= E1000_PCH_LPT
               then
                  if E1000_PHY_Is_Accessible_PCHLAN(HW)
                  then
                     null;
                  else
                     -- Toggling LANPHYPC brings the PHY out of SMBus mode
                     -- so ensure that the MAC is also out of SMBus mode.
                     --
                     MAC_Reg := ER32 (HW.all, Devices.e1000e.Registers.E1000_CTRL_EXT);
                     MAC_Reg := MAC_Reg and (not E1000_CTRL_EXT_FORCE_SMBUS);

                     EW32 (HW.all, Devices.e1000e.Registers.E1000_CTRL_EXT, MAC_Reg);

                     if not E1000_PHY_Is_Accessible_PCHLAN (HW)
                     then
                        Ret_Val := -E1000_ERR_PHY;
                     end if;
                  end if;
               end if;
            end if;

         when others =>
            null;
      end case;

      E1000E_Enable_PHY_Retry (HW);

      HW.PHY.Ops.Release (HW);

      if Ret_Val = 0
      then
         -- Check to see if able to reset PHY. Print error if not.
         --
         if HW.PHY.Ops.Check_Reset_Block (HW) /= 0
         then
            e_err ("Reset blocked by ME");
            return Ret_Val;
         end if;

         -- Reset the PHY before any access to it. Doing so, ensures
         -- that the PHY is in a known good state before we read/write
         -- PHY registers. The generic reset is sufficient here,
         -- because we haven't determined the PHY type yet.
         --
         Ret_Val := E1000E_PHY_HW_Reset_Generic (HW);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;

         -- On a successful reset, possibly need to wait for the PHY
         -- to quiesce to an accessible state before returning control
         -- to the calling function. If the PHY does not quiesce, then
         -- return E1000E_BLK_PHY_RESET, as this is the condition that
         -- the PHY is in.
         --
         Ret_Val := HW.PHY.Ops.Check_Reset_Block (HW);

         if Ret_Val /= 0
         then
            e_err ("ME blocked access to PHY after reset");
         end if;
      end if;

      -- Ungate automatic PHY configuration on non-managed 82579.
      --
      if (HW.MAC.mac_Type = E1000_PCH2LAN) and
        ((FWSM and E1000_ICH_FWSM_FW_VALID) = 0)
      then
         delay 0.0105;
         E1000_Gate_HW_PHY_Config_ICH8LAN(HW, False);
      end if;

      return Ret_Val;
   end E1000_Init_PHY_Workarounds_PCHLAN;




   ----------------------------------
   -- E1000_Init_PHY_Params_PCHLAN --
   ----------------------------------

   --  Initialize PHY function pointers.
   --  @hw: pointer to the HW structure
   --
   --  Initialize family-specific PHY parameters and function pointers.

   function E1000_Init_PHY_Params_PCHLAN (HW : access E1000_HW) return s32
   is

      PHY     : constant access E1000_PHY_INFO.item := HW.PHY'Access;
      RET_VAL :                 s32                 := 0;
   begin
      PHY.ADDR           := 1;
      PHY.RESET_DELAY_US := 100;

      PHY.OPS.SET_PAGE          := E1000_Set_Page_IGP                 'Access;
      PHY.OPS.READ_REG          := E1000_Read_PHY_Reg_HV              'Access;
      PHY.OPS.READ_REG_LOCKED   := E1000_Read_PHY_Reg_HV_Locked       'Access;
      PHY.OPS.READ_REG_PAGE     := E1000_Read_PHY_Reg_Page_HV         'Access;
      PHY.OPS.SET_D0_LPLU_STATE := E1000_Set_LPLU_State_PCHLAN        'Access;
      PHY.OPS.SET_D3_LPLU_STATE := E1000_Set_LPLU_State_PCHLAN        'Access;
      PHY.OPS.WRITE_REG         := E1000_Write_PHY_Reg_HV             'Access;
      PHY.OPS.WRITE_REG_LOCKED  := E1000_Write_PHY_Reg_HV_Locked      'Access;
      PHY.OPS.WRITE_REG_PAGE    := E1000_Write_PHY_Reg_Page_HV        'Access;
      PHY.OPS.POWER_UP          := E1000_Power_Up_PHY_Copper          'Access;
      PHY.OPS.POWER_DOWN        := E1000_Power_Down_PHY_Copper_ICH8LAN'Access;
      PHY.AUTONEG_MASK          := AUTONEG_ADVERTISE_SPEED_DEFAULT;

      PHY.ID := E1000_PHY_UNKNOWN'Enum_Rep;

      if HW.MAC.mac_Type = E1000_PCH_MTP
      then
         PHY.RETRY_COUNT := 2;
         E1000E_Enable_PHY_Retry (HW);
      end if;

      RET_VAL := E1000_Init_PHY_Workarounds_PCHLAN (HW);

      if RET_VAL /= 0
      then
         return RET_VAL;
      end if;

      if PHY.ID = E1000_PHY_UNKNOWN'Enum_Rep
      then
         case HW.MAC.mac_type     -- TODO: This looks very wrong. Re-check the port!
         is
            when others =>
               RET_VAL := E1000E_Get_PHY_ID (HW);

               if RET_VAL /= 0
               then
                  return RET_VAL;
               end if;

               if    PHY.ID /= 0
                 and PHY.ID /= PHY_REVISION_MASK
               then
                  null;
               else
                  case HW.MAC.mac_type
                  is
                     when e1000_pch2lan
                        | e1000_pch_lpt
                        | e1000_pch_spt
                        | e1000_pch_cnp
                        | e1000_pch_tgp
                        | e1000_pch_adp
                        | e1000_pch_mtp
                        | e1000_pch_lnp
                        | e1000_pch_ptp
                        | e1000_pch_nvp =>
                        --  In case the PHY needs to be in mdio slow mode,
                        --  set slow mode and try to get the PHY id again.
                        --
                        RET_VAL := E1000_Set_MDIO_Slow_Mode_HV (HW);

                        if RET_VAL /= 0
                        then
                           return RET_VAL;
                        end if;

                        RET_VAL := E1000E_Get_PHY_ID (HW);

                        if RET_VAL /= 0
                        then
                           return RET_VAL;
                        end if;

                     when others =>
                        null;
                  end case;

               end if;
         end case;
      end if;


      PHY.phy_type := E1000E_Get_PHY_Type_From_ID (PHY.ID);

      case PHY.phy_type
      is
         when E1000_PHY_82577
            | E1000_PHY_82579
            | E1000_PHY_I217 =>
            PHY.OPS.CHECK_POLARITY     := E1000_Check_Polarity_82577        'Access;
            PHY.OPS.FORCE_SPEED_DUPLEX := E1000_PHY_Force_Speed_Duplex_82577'Access;
            PHY.OPS.GET_CABLE_LENGTH   := E1000_Get_Cable_Length_82577      'Access;
            PHY.OPS.GET_INFO           := E1000_Get_PHY_Info_82577          'Access;
            PHY.OPS.COMMIT             := E1000E_PHY_SW_Reset               'Access;

         when E1000_PHY_82578 =>
            PHY.OPS.CHECK_POLARITY     := E1000_Check_Polarity_M88         'Access;
            PHY.OPS.FORCE_SPEED_DUPLEX := E1000E_PHY_Force_Speed_Duplex_M88'Access;
            PHY.OPS.GET_CABLE_LENGTH   := E1000E_Get_Cable_Length_M88      'Access;
            PHY.OPS.GET_INFO           := E1000E_Get_PHY_Info_M88          'Access;

         when others =>
            RET_VAL := -E1000_ERR_PHY;
      end case;

      return RET_VAL;
   end E1000_Init_PHY_Params_PCHLAN;




   -----------------------------------
   -- E1000_Init_PHY_Params_ICH8LAN --
   -----------------------------------

   --  Initialize PHY function pointers.
   --  @hw: pointer to the HW structure
   --
   --  Initialize family-specific PHY parameters and function pointers.

   function E1000_Init_PHY_Params_ICH8LAN (HW : access E1000_HW) return s32
   is
      PHY     : E1000_PHY_Info.item renames HW.PHY;
      Ret_Val : s32;
      I       : Natural := 0;
   begin
      PHY.Addr           := 1;
      PHY.Reset_Delay_Us := 100;

      PHY.Ops.Power_Up   := E1000_Power_Up_PHY_Copper          'Access;
      PHY.Ops.Power_Down := E1000_Power_Down_PHY_Copper_ICH8LAN'Access;

      -- We may need to do this twice - once for IGP and if that fails,
      -- we'll set BM func pointers and try again.
      --
      Ret_Val := E1000e_Determine_PHY_Address (HW);

      if Ret_Val /= 0
      then
         PHY.Ops.Write_Reg := E1000e_Write_PHY_Reg_BM'Access;
         PHY.Ops.Read_Reg  := E1000e_Read_PHY_Reg_BM 'Access;
         Ret_Val           := E1000e_Determine_PHY_Address (HW);

         if Ret_Val /= 0
         then
            e_dbg ("Cannot determine PHY addr. Erroring out");
            return Ret_Val;
         end if;
      end if;


      PHY.Id := 0;

      while     E1000e_Get_PHY_Type_From_Id (PHY.Id) = E1000_PHY_Unknown
            and I < 100
      loop
         delay 0.00105;  -- Ada equivalent of usleep_range(1000, 1100).

         Ret_Val := E1000e_Get_PHY_Id (HW);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;

         I := I + 1;
      end loop;


      -- Verify phy id.
      --
      case PHY.Id
      is
         when IGP03E1000_E_PHY_ID =>
            PHY.PHY_Type               := E1000_PHY_IGP_3;
            PHY.Autoneg_Mask           := AUTONEG_ADVERTISE_SPEED_DEFAULT;
            PHY.Ops.Read_Reg_Locked    := E1000e_Read_PHY_Reg_IGP_Locked   'Access;
            PHY.Ops.Write_Reg_Locked   := E1000e_Write_PHY_Reg_IGP_Locked  'Access;
            PHY.Ops.Get_Info           := E1000e_Get_PHY_Info_IGP          'Access;
            PHY.Ops.Check_Polarity     := E1000_Check_Polarity_IGP         'Access;
            PHY.Ops.Force_Speed_Duplex := E1000e_PHY_Force_Speed_Duplex_IGP'Access;

         when IFE_E_PHY_ID
            | IFE_PLUS_E_PHY_ID
            | IFE_C_E_PHY_ID =>
            PHY.PHY_Type               := E1000_PHY_IFE;
            PHY.Autoneg_Mask           := u16 (E1000_ALL_NOT_GIG);
            PHY.Ops.Get_Info           := E1000_Get_PHY_Info_IFE          'Access;
            PHY.Ops.Check_Polarity     := E1000_Check_Polarity_IFE        'Access;
            PHY.Ops.Force_Speed_Duplex := E1000_PHY_Force_Speed_Duplex_IFE'Access;

         when BME1000_E_PHY_ID =>
            PHY.PHY_Type               := E1000_PHY_BM;
            PHY.Autoneg_Mask           := AUTONEG_ADVERTISE_SPEED_DEFAULT;
            PHY.Ops.Read_Reg           := E1000e_Read_PHY_Reg_BM           'Access;
            PHY.Ops.Write_Reg          := E1000e_Write_PHY_Reg_BM          'Access;
            PHY.Ops.Commit             := E1000e_PHY_SW_Reset              'Access;
            PHY.Ops.Get_Info           := E1000e_Get_PHY_Info_M88          'Access;
            PHY.Ops.Check_Polarity     := E1000_Check_Polarity_M88         'Access;
            PHY.Ops.Force_Speed_Duplex := E1000e_PHY_Force_Speed_Duplex_M88'Access;

         when others =>
            return -E1000_ERR_PHY;
      end case;

      return 0;
   end E1000_Init_PHY_Params_ICH8LAN;




   -----------------------------------
   -- E1000_Init_NVM_Params_ICH8LAN --
   -----------------------------------

   --  Initialize NVM function pointers
   --  @hw: pointer to the HW structure
   --
   --  Initialize family-specific NVM parameters and function
   --  pointers.

   function E1000_Init_NVM_Params_ICH8LAN (HW : access E1000_HW) return s32
   is
      use type system.Address;

      NVM             : E1000_NVM_Info.item renames HW.NVM;
      GFPREG,
      Sector_Base_Addr,
      Sector_End_Addr : Unsigned_32;
      NVM_Size        : Unsigned_32;

   begin
      NVM.NVM_Type := E1000_NVM_Flash_SW;

      if HW.MAC.MAC_Type >= E1000_PCH_SPT
      then
         -- In SPT, GFPREG doesn't exist. NVM size is taken from the
         -- STRAP register. This is because in SPT the GbE Flash region
         -- is no longer accessed through the flash registers. Instead,
         -- the mechanism has changed, and the Flash region access
         -- registers are now implemented in GbE memory space.
         --
         NVM.Flash_Base_Addr := 0;
         NVM_Size            :=   ((    shift_Right (ER32 (Hw.all, E1000_STRAP),
                                                     1)
                                     and 16#1F#)
                                   + 1)
                                * NVM_SIZE_MULTIPLIER;
         NVM.Flash_Bank_Size := NVM_Size / 2;

         -- Adjust to word count.
         --
         NVM.Flash_Bank_Size := NVM.Flash_Bank_Size / Unsigned_32 (Unsigned_16'Size / 8);

         -- Set the base address for flash register access.
         --
         HW.Flash_Address := HW.HW_Addr + E1000_FLASH_BASE_ADDR;

      else
         -- Can't read flash registers if register set isn't mapped.
         --
         if HW.Flash_Address = System.Null_Address
         then
            e_dbg ("Flash registers not mapped");
            return -E1000_ERR_CONFIG;
         end if;

         GFPREG := ER32Flash (Hw, ICH_FLASH_GFPREG);

         -- sector_X_addr is a "sector"-aligned address (4096 bytes)
         -- Add 1 to sector_end_addr since this sector is included in
         -- the overall size.
         --
         Sector_Base_Addr := GFPREG and FLASH_GFPREG_BASE_MASK;
         Sector_End_Addr  :=   (    shift_Right (GFPREG, 16)
                                and FLASH_GFPREG_BASE_MASK)
                             + 1;

         -- flash_base_addr is byte-aligned.
         --
         NVM.Flash_Base_Addr := shift_Left (Sector_Base_Addr, FLASH_SECTOR_ADDR_SHIFT);

         -- Find total size of the NVM, then cut in half since the total
         -- size represents two separate NVM banks.
         --
         NVM.Flash_Bank_Size := Shift_Left(Sector_End_Addr - Sector_Base_Addr, FLASH_SECTOR_ADDR_SHIFT);
         NVM.Flash_Bank_Size := NVM.Flash_Bank_Size / 2;

         -- Adjust to word count.
         --
         NVM.Flash_Bank_Size := NVM.Flash_Bank_Size / Unsigned_32 (Unsigned_16'Size / 8);
      end if;


      NVM.Word_Size := E1000_ICH8_SHADOW_RAM_WORDS;

      -- Clear shadow ram.
      --
      for I in 0 .. C.size_t (NVM.Word_Size) - 1
      loop
         HW.Dev_Spec.ICH8LAN.Shadow_Ram (I).Modified := False;
         HW.Dev_Spec.ICH8LAN.Shadow_Ram (I).Value    := 16#FFFF#;
      end loop;

      return 0;
   end E1000_Init_NVM_Params_ICH8LAN;




   -----------------------------------
   -- E1000_Init_Mac_Params_Ich8lan --
   -----------------------------------

   --  Initialize MAC function pointers.
   --  @hw: pointer to the HW structure.
   --
   --  Initialize family-specific MAC parameters and function pointers.

   function E1000_Init_Mac_Params_Ich8lan (Hw : access E1000_Hw) return s32
   is
      use
          Devices.e1000e.Media_Access_Control;

      Mac : constant access E1000_Mac_Info.item := Hw.Mac'Access;
   begin
      Hw.Phy.Media_Type   := E1000_Media_Type_Copper;     -- Set media type function pointer.
      Mac.Mta_Reg_Count   := 32;                          -- Set mta register count.
      Mac.Rar_Entry_Count := E1000_ICH_RAR_ENTRIES;       -- Set rar entry count.

      if Mac.mac_type = E1000_Ich8lan
      then
         Mac.Rar_Entry_Count := Mac.Rar_Entry_Count - 1;
      end if;

      Mac.Has_Fwsm            := True;      -- FWSM register
      Mac.Arc_Subsystem_Valid := False;     -- ARC subsystem not supported.
      Mac.Adaptive_Ifs        := True;      -- Adaptive IFS supported

      -- LED and other operations.
      --
      case Mac.mac_type
      is
         when E1000_Ich8lan
            | E1000_Ich9lan
            | E1000_Ich10lan =>

            Mac.Ops.Check_Mng_Mode := E1000_Check_Mng_Mode_Ich8lan'Access;     -- Check management mode.
            Mac.Ops.Id_Led_Init    := E1000e_Id_Led_Init_Generic  'Access;     -- ID LED init.
            Mac.Ops.Blink_Led      := E1000e_Blink_Led_Generic    'Access;     -- Blink LED.
            Mac.Ops.Setup_Led      := E1000e_Setup_Led_Generic    'Access;     -- Setup LED.
            Mac.Ops.Cleanup_Led    := E1000_Cleanup_Led_Ich8lan   'Access;     -- Cleanup LED
            Mac.Ops.Led_On         := E1000_Led_On_Ich8lan        'Access;     -- Turn on/off LED.
            Mac.Ops.Led_Off        := E1000_Led_Off_Ich8lan       'Access;

         when E1000_Pch2lan =>
            Mac.Rar_Entry_Count := E1000_PCH2_RAR_ENTRIES;
            Mac.Ops.Rar_Set     := E1000_Rar_Set_Pch2lan'Access;

         when E1000_Pch_Lpt
            | E1000_Pch_Spt
            | E1000_Pch_Cnp
            | E1000_Pch_Tgp
            | E1000_Pch_Adp
            | E1000_Pch_Mtp
            | E1000_Pch_Lnp
            | E1000_Pch_Ptp
            | E1000_Pch_Nvp
            | E1000_Pchlan =>
            Mac.Ops.Check_Mng_Mode := E1000_Check_Mng_Mode_Pchlan'Access;     -- Check management mode.
            Mac.Ops.Id_Led_Init    := E1000_Id_Led_Init_Pchlan   'Access;     -- ID LED init.
            Mac.Ops.Setup_Led      := E1000_Setup_Led_Pchlan     'Access;     -- Setup LED.
            Mac.Ops.Cleanup_Led    := E1000_Cleanup_Led_Pchlan   'Access;     -- Cleanup LED.
            Mac.Ops.Led_On         := E1000_Led_On_Pchlan        'Access;     -- Turn on/off LED.
            Mac.Ops.Led_Off        := E1000_Led_Off_Pchlan       'Access;

         when others =>
            null;
      end case;

      if Mac.mac_type >= E1000_Pch_Lpt
      then
         Mac.Rar_Entry_Count              := E1000_PCH_LPT_RAR_ENTRIES;
         Mac.Ops.Rar_Set                  := E1000_Rar_Set_Pch_Lpt          'Access;
         Mac.Ops.Setup_Physical_Interface := E1000_Setup_Copper_Link_Pch_Lpt'Access;
         Mac.Ops.Rar_Get_Count            := E1000_Rar_Get_Count_Pch_Lpt    'Access;
      end if;

      -- Enable PCS Lock-loss workaround for ICH8.
      --
      if Mac.mac_type = E1000_Ich8lan
      then
         E1000e_Set_Kmrn_Lock_Loss_Workaround_Ich8lan (Hw, True);
      end if;

      return 0;
   end E1000_Init_Mac_Params_Ich8lan;




   ---------------------------------
   -- E1000_Access_EMI_Reg_Locked --
   ---------------------------------

   --  Read/write EMI register.
   --
   --  @hw:      pointer to the HW structure.
   --  @address: EMI address to program.
   --  @data:    pointer to value to read/write from/to the EMI address.
   --  @read:    boolean flag to indicate read or write.
   --
   --  This helper function assumes the SW/FW/HW Semaphore is already acquired.

   function E1000_Access_EMI_Reg_Locked
     (HW      : access E1000_HW;
      Address : in     Unsigned_16;
      Data    : in     u16_Pointer;
      Read    : in     Boolean) return s32
   is
      Ret_Val : s32;

   begin
      Ret_Val := E1e_Wphy_Locked (HW, I82579_EMI_ADDR, Address);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;

      if Read
      then
         Ret_Val := E1e_Rphy_Locked (HW, I82579_EMI_DATA, Data);
      else
         Ret_Val := E1e_Wphy_Locked (HW, I82579_EMI_DATA, Data.all);
      end if;

      return Ret_Val;
   end E1000_Access_EMI_Reg_Locked;




   --------------------------------
   -- E1000_K1_Workaround_LPT_LP --
   --------------------------------

   --  K1 workaround on Lynxpoint-LP.
   --  *  @hw:   Pointer to the HW structure
   --  *  @link: Link up bool flag
   --  *
   --  *  When K1 is enabled for 1Gbps, the MAC can miss 2 DMA completion indications
   --  *  preventing further DMA write requests.  Workaround the issue by disabling
   --  *  the de-assertion of the clock request when in 1Gpbs mode.
   --  *  Also, set appropriate Tx re-transmission timeouts for 10 and 100Half link
   --  *  speeds in order to avoid Tx hangs.


   function E1000_K1_Workaround_LPT_LP
     (HW   : access E1000_HW;
      Link : in     Boolean) return s32
   is
      fextnvm6_Value :          u32 := ER32 (HW.all, Devices.e1000e.Registers.E1000_FEXTNVM6);
      Status_Value   : constant u32 := ER32 (HW.all, Devices.e1000e.Registers.E1000_STATUS);
      Ret_Val        :          s32 := 0;
      Reg            : aliased  u16;

   begin
      if Link and then (Status_Value and E1000_STATUS_SPEED_1000) /= 0
      then
         Ret_Val := HW.PHY.Ops.Acquire (HW);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Ret_Val := E1000E_Read_KMRN_Reg_Locked (HW,
                                                 E1000_KMRNCTRLSTA_K1_CONFIG,
                                                 Reg'unchecked_Access);
         if Ret_Val /= 0
         then
            goto Release;
         end if;


         Ret_Val := E1000E_Write_KMRN_Reg_Locked (HW,
                                                  E1000_KMRNCTRLSTA_K1_CONFIG,
                                                  Reg and (not E1000_KMRNCTRLSTA_K1_ENABLE));
         if Ret_Val /= 0
         then
            goto Release;
         end if;

         delay 0.000015;  -- Equivalent to usleep_range (10, 20).

         EW32 (HW.all,
               Devices.e1000e.Registers.E1000_FEXTNVM6,
               fextnvm6_Value or E1000_FEXTNVM6_REQ_PLL_CLK);

         Ret_Val := E1000E_Write_KMRN_Reg_Locked (HW,
                                                  E1000_KMRNCTRLSTA_K1_CONFIG,
                                                  Reg);
         <<Release>>
         HW.PHY.Ops.Release (HW);

      else
         -- Clear FEXTNVM6 bit 8 on link down or 10/100.
         --
         fextnvm6_Value := fextnvm6_Value and (not E1000_FEXTNVM6_REQ_PLL_CLK);

         if   HW.PHY.Revision > 5
           or not Link
           or (    (Status_Value and E1000_STATUS_SPEED_100) /= 0
               and (Status_Value and E1000_STATUS_FD)        /= 0)
         then
            goto Update_FEXTNVM6;
         end if;


         Ret_Val := E1E_RPHY (HW,
                              I217_INBAND_CTRL,
                              Reg'unchecked_Access);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         -- Clear link status transmit timeout.
         --
         Reg := Reg and (not I217_INBAND_CTRL_LINK_STAT_TX_TIMEOUT_MASK);

         if (Status_Value and E1000_STATUS_SPEED_100) /= 0
         then
            -- Set inband Tx timeout to 5x10us for 100Half.
            --
            Reg := Reg or shift_Left (5,
                                      I217_INBAND_CTRL_LINK_STAT_TX_TIMEOUT_SHIFT);

            -- Do not extend the K1 entry latency for 100Half.
            --
            fextnvm6_Value := fextnvm6_Value and (not E1000_FEXTNVM6_ENABLE_K1_ENTRY_CONDITION);

         else
            -- Set inband Tx timeout to 50x10us for 10Full/Half.
            --
            Reg := Reg or Shift_Left (50,
                                      I217_INBAND_CTRL_LINK_STAT_TX_TIMEOUT_SHIFT);

            -- Extend the K1 entry latency for 10 Mbps.
            --
            fextnvm6_Value := fextnvm6_Value or E1000_FEXTNVM6_ENABLE_K1_ENTRY_CONDITION;
         end if;


         Ret_Val := E1E_WPHY (HW,
                              I217_INBAND_CTRL,
                              Reg);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         <<Update_FEXTNVM6>>
         EW32 (HW.all, Devices.e1000e.Registers.E1000_FEXTNVM6, fextnvm6_Value);
      end if;


      return Ret_Val;
   end E1000_K1_Workaround_LPT_LP;




   -------------------------------
   -- E1000_Platform_PM_PCH_LPT --
   -------------------------------

   --  Set platform power management values.
   --
   --  *  @hw:   Pointer to the HW structure.
   --  *  @link: Boolean indicating link status.
   --  *
   --  *  Set the Latency Tolerance Reporting (LTR) values for the "PCIe-like"
   --  *  GbE MAC in the Lynx Point PCH based on Rx buffer size and link speed
   --  *  when link is up (which must not exceed the maximum latency supported
   --  *  by the platform), otherwise specify there is no LTR requirement.
   --  *  Unlike true-PCIe devices which set the LTR maximum snoop/no-snoop
   --  *  latencies in the LTR Extended Capability Structure in the PCIe Extended
   --  *  Capability register set, on this device LTR is set by writing the
   --  *  equivalent snoop/no-snoop latencies in the LTRV register in the MAC and
   --  *  set the SEND bit to send an Intel On-chip System Fabric sideband (IOSF-SB)
   --  *  message to the PMC.


   function E1000_Platform_PM_PCH_LPT
     (HW   : access E1000_HW;
      Link : in     Boolean) return s32
   is
      Reg           : Unsigned_32;
      Max_LTR_Enc_D : Unsigned_32 := 0;        -- Maximum LTR decoded by platform.
      Lat_Enc_D     : Unsigned_32 := 0;        -- Latency decoded.
      Lat_Enc       : Unsigned_16 := 0;        -- Latency encoded.

   begin
      Reg :=    shift_Left (Boolean'Pos (Link), E1000_LTRV_REQ_SHIFT + E1000_LTRV_NOSNOOP_SHIFT)
             or shift_Left (Boolean'Pos (Link), E1000_LTRV_REQ_SHIFT)
             or E1000_LTRV_SEND;

      if Link
      then
         declare
            Speed       : aliased Unsigned_16;
            Duplex      : aliased Unsigned_16;
            Scale       :         Unsigned_16 := 0;
            Max_Snoop,
            Max_Nosnoop : aliased Unsigned_16;
            Max_LTR_Enc :         Unsigned_16;           -- Max LTR latency encoded.
            Value       :         Unsigned_64;
            RXA         :         Unsigned_32;
            Unused      :         s32;
         begin
            if HW.Adapter.Max_Frame_Size = 0
            then
               E_DBG ("max_frame_size not set.");
               return -E1000_ERR_CONFIG;
            end if;

            Unused := HW.Mac.Ops.Get_Link_Up_Info (HW,
                                                   Speed 'unchecked_Access,
                                                   Duplex'unchecked_Access);
            if Speed = 0
            then
               E_DBG ("Speed not set.");
               return -E1000_ERR_CONFIG;
            end if;


            -- Rx Packet Buffer Allocation size (KB).
            --
            RXA := ER32 (Hw.all, Devices.e1000e.Registers.E1000_PBA) and E1000_PBA_RXA_MASK;

            -- Determine the maximum latency tolerated by the device.
            --
            --  Per the PCIe spec, the tolerated latencies are encoded as
            --  * a 3-bit encoded scale (only 0-5 are valid) multiplied by
            --  * a 10-bit value (0-1023) to provide a range from 1 ns to
            --  * 2^25*(2^10-1) ns.  The scale is encoded as 0=2^0ns,
            --  * 1=2^5ns, 2=2^10ns,...5=2^25ns.
            --
            RXA := RXA * 512;

            if RXA > HW.Adapter.Max_Frame_Size
            then
               Value := u64 (RXA - HW.Adapter.Max_Frame_Size) * u64 (16_000 / Speed);
            else
               Value := 0;
            end if;

            while Value > PCI_LTR_VALUE_MASK
            loop
               Scale := Scale + 1;
               Value := (Value + 31) / 32;     -- DIV_ROUND_UP equivalent.     -- TODO: Check this is equivalent to C's     value = DIV_ROUND_UP (value, BIT(5));
            end loop;

            if Scale > E1000_LTRV_SCALE_MAX
            then
               E_DBG ("Invalid LTR latency scale" & Scale'Image);
               return -E1000_ERR_CONFIG;
            end if;

            Lat_Enc := Unsigned_16 (   shift_Left (Unsigned_64 (Scale),
                                                   PCI_LTR_SCALE_SHIFT)
                                    or Value);

            -- Determine the maximum latency tolerated by the platform.
            --
            declare
               Unused : C.int;
            begin
               Unused := PCI_Read_Config_Word (HW.Adapter.PDEV, E1000_PCI_LTR_CAP_LPT,     Max_Snoop  'unchecked_Access);
               Unused := PCI_Read_Config_Word (HW.Adapter.PDEV, E1000_PCI_LTR_CAP_LPT + 2, Max_Nosnoop'unchecked_Access);
            end;

            Max_LTR_Enc   := Unsigned_16'Max (Max_Snoop, Max_Nosnoop);

            Lat_Enc_D     :=   Unsigned_32 (Lat_Enc and E1000_LTRV_VALUE_MASK)
                             * shift_Left (1,   E1000_LTRV_SCALE_FACTOR
                                              * Natural (FIELD_GET (E1000_LTRV_SCALE_MASK, lat_enc)));

            Max_LTR_Enc_D :=   Unsigned_32 (Max_LTR_Enc and E1000_LTRV_VALUE_MASK)
                             * shift_Left (1,   E1000_LTRV_SCALE_FACTOR
                                              * Natural (FIELD_GET (E1000_LTRV_SCALE_MASK, max_ltr_enc)));

            if Lat_Enc_D > Max_LTR_Enc_D
            then
               Lat_Enc := Max_LTR_Enc;
            end if;
         end;
      end if;


      -- Set Snoop and No-Snoop latencies the same.
      --
      Reg := Reg or Unsigned_32 (Lat_Enc) or Shift_Left (Unsigned_32 (Lat_Enc), E1000_LTRV_NOSNOOP_SHIFT);
      EW32 (HW.all, E1000_LTRV, Reg);

      return 0;
   end E1000_Platform_PM_PCH_LPT;




   ------------------------
   -- E1000e_Force_Smbus --
   ------------------------

   --  Force interfaces to transition to SMBUS mode.
   --
   --  *  @hw: pointer to the HW structure
   --  *
   --  *  Force the MAC and the PHY to SMBUS mode. Assumes semaphore already
   --  *  acquired.
   --  *
   --  * Return: 0 on success, negative errno on failure.


   function E1000e_Force_Smbus (Hw : access E1000_HW) return s32
   is

      Smb_Ctrl       : aliased Unsigned_16 := 0;
      Ctrl_Ext_Value :         Unsigned_32;
      Ret_Val        :         s32;
      Unused         :         s32;
   begin
      -- Switching PHY interface always returns MDI error
      -- so disable retry mechanism to avoid wasting time.
      --
      E1000e_Disable_Phy_Retry (Hw);

      -- Force SMBus mode in the PHY.
      --
      Ret_Val := E1000_Read_Phy_Reg_Hv_Locked (Hw,
                                               CV_SMB_CTRL,
                                               Smb_Ctrl'unchecked_Access);
      if Ret_Val /= 0
      then
         E1000e_Enable_Phy_Retry (Hw);
         return Ret_Val;
      end if;

      Smb_Ctrl := Smb_Ctrl or CV_SMB_CTRL_FORCE_SMBUS;
      Unused := E1000_Write_Phy_Reg_Hv_Locked (Hw,
                                               CV_SMB_CTRL,
                                               Smb_Ctrl);
      E1000e_Enable_Phy_Retry (Hw);

      -- Force SMBus mode in the MAC.
      --
      Ctrl_Ext_Value := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT);
      Ctrl_Ext_Value := Ctrl_Ext_Value or E1000_CTRL_EXT_FORCE_SMBUS;

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT, Ctrl_Ext_Value);

      return 0;
   end E1000e_Force_Smbus;




   ------------------------------
   -- e1000_disable_ULP_LPT_LP --
   ------------------------------

   --  Unconfigure Ultra Low Power mode for LynxPoint-LP
   --
   --  *  @hw:    Pointer to the HW structure
   --  *  @force: Boolean indicating whether or not to force disabling ULP
   --  *
   --  *  Un-configure ULP mode when link is up, the system is transitioned from
   --  *  Sx or the driver is unloaded.  If on a Manageability Engine (ME) enabled
   --  *  system, poll for an indication from ME that ULP has been un-configured.
   --  *  If not on an ME enabled system, un-configure the ULP mode by software.
   --  *
   --  *  During nominal operation, this function is called when link is acquired
   --  *  to disable ULP mode (force=false); otherwise, for example when unloading
   --  *  the driver or during Sx->S0 transitions, this is called with force=true
   --  *  to forcibly disable ULP.


   function e1000_disable_ULP_LPT_LP (HW : access E1000_HW; Force : Boolean) return s32
   is
      Ret_Val :         s32        := 0;
      Mac_Reg :         Unsigned_32;
      Phy_Reg : aliased Unsigned_16;
      I       :         Integer    := 0;
      Unused  :         s32;
   begin
      if        HW.Mac.mac_Type < E1000_PCH_LPT
        or else HW.Adapter.Pdev.Device = E1000_DEV_ID_PCH_LPT_I217_LM
        or else HW.Adapter.Pdev.Device = E1000_DEV_ID_PCH_LPT_I217_V
        or else HW.Adapter.Pdev.Device = E1000_DEV_ID_PCH_I218_LM2
        or else HW.Adapter.Pdev.Device = E1000_DEV_ID_PCH_I218_V2
        or else HW.Dev_Spec.Ich8lan.ULP_State = E1000_ULP_State_Off
      then
         return 0;
      end if;

      if (ER32 (Hw.all, Devices.e1000e.Registers.E1000_FWSM) and E1000_ICH_FWSM_FW_VALID) /= 0
      then
         declare
            Adapter      : E1000_Adapter.item renames HW.Adapter.all;
            Firmware_Bug : Boolean := False;
         begin
            if Force
            then
               -- Request ME un-configure ULP mode in the PHY.
               --
               Mac_Reg := ER32 (Hw.all, E1000_H2ME);
               Mac_Reg := Mac_Reg and (not E1000_H2ME_ULP);
               Mac_Reg := Mac_Reg or E1000_H2ME_ENFORCE_SETTINGS;

               EW32 (Hw.all, E1000_H2ME, Mac_Reg);
            end if;

            -- Poll up to 2.5 seconds for ME to clear ULP_CFG_DONE.
            -- If this takes more than 1 second, show a warning indicating a
            -- firmware bug.
            --
            while (ER32 (Hw.all, Devices.e1000e.Registers.E1000_FWSM) and E1000_FWSM_ULP_CFG_DONE) /= 0
            loop
               if I = 250
               then
                  Ret_Val := -E1000_ERR_PHY;
                  goto Out_Label;
               end if;

               if I > 100 and not Firmware_Bug
               then
                  Firmware_Bug := True;
               end if;

               delay 0.0105; -- Equivalent to usleep_range(10000, 11000)
               I := I + 1;
            end loop;


            if Firmware_Bug
            then
               e_warn ("ULP_CONFIG_DONE took" & Integer'Image (I * 10) & " msec. This is a firmware bug");
            else
               e_dbg ("ULP_CONFIG_DONE cleared after" & Integer'Image (I * 10) & " msec");
            end if;


            if Force
            then
               Mac_Reg := ER32 (Hw.all, E1000_H2ME);
               Mac_Reg := Mac_Reg and (not E1000_H2ME_ENFORCE_SETTINGS);

               EW32 (Hw.all, E1000_H2ME, Mac_Reg);
            else
               -- Clear H2ME.ULP after ME ULP configuration.
               --
               Mac_Reg := ER32 (Hw.all, E1000_H2ME);
               Mac_Reg := Mac_Reg and (not E1000_H2ME_ULP);

               EW32 (Hw.all, E1000_H2ME, Mac_Reg);
            end if;

            goto Out_Label;
         end;
      end if;


      Ret_Val := HW.Phy.Ops.Acquire (HW);

      if Ret_Val /= 0
      then
         goto Out_Label;
      end if;

      if Force
      then
         -- Toggle LANPHYPC Value bit.
         --
         E1000_Toggle_Lanphypc_Pch_Lpt (HW);
      end if;

      -- Switching PHY interface always returns MDI error
      -- so disable retry mechanism to avoid wasting time.
      --
      E1000e_Disable_Phy_Retry (HW);

      -- Unforce SMBus mode in PHY.
      --
      Ret_Val := E1000_Read_Phy_Reg_Hv_Locked (HW,
                                               CV_SMB_CTRL,
                                               Phy_Reg'unchecked_Access);
      if Ret_Val /= 0
      then
         -- The MAC might be in PCIe mode, so temporarily force to
         -- SMBus mode in order to access the PHY.
         --
         Mac_Reg := ER32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT);
         Mac_Reg := Mac_Reg or E1000_CTRL_EXT_FORCE_SMBUS;

         EW32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT, Mac_Reg);

         delay 0.050; -- Equivalent to msleep(50)

         Ret_Val := E1000_Read_Phy_Reg_Hv_Locked (HW,
                                                  CV_SMB_CTRL,
                                                  Phy_Reg'unchecked_Access);
         if Ret_Val /= 0
         then
            goto Release_Label;
         end if;
      end if;

      Phy_Reg := Phy_Reg and (not CV_SMB_CTRL_FORCE_SMBUS);
      Unused  := E1000_Write_Phy_Reg_Hv_Locked (HW,
                                                CV_SMB_CTRL,
                                                Phy_Reg);

      E1000e_Enable_Phy_Retry (HW);

      -- Unforce SMBus mode in MAC.
      --
      Mac_Reg := ER32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT);
      Mac_Reg := Mac_Reg and (not E1000_CTRL_EXT_FORCE_SMBUS);
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT, Mac_Reg);

      -- When ULP mode was previously entered, K1 was disabled by the
      -- hardware.  Re-Enable K1 in the PHY when exiting ULP.
      --
      Ret_Val := E1000_Read_Phy_Reg_Hv_Locked (HW,
                                               HV_PM_CTRL,
                                               Phy_Reg'unchecked_Access);
      if Ret_Val /= 0
      then
         goto Release_Label;
      end if;

      Phy_Reg := Phy_Reg or HV_PM_CTRL_K1_ENABLE;
      Unused  := E1000_Write_Phy_Reg_Hv_Locked (HW,
                                                HV_PM_CTRL,
                                                Phy_Reg);

      -- Clear ULP enabled configuration.
      --
      Ret_Val := E1000_Read_Phy_Reg_Hv_Locked (HW,
                                               I218_ULP_CONFIG1,
                                               Phy_Reg'unchecked_Access);

      if Ret_Val /= 0
      then
         goto Release_Label;
      end if;

      Phy_Reg := Phy_Reg and (not (I218_ULP_CONFIG1_IND or
                                   I218_ULP_CONFIG1_STICKY_ULP or
                                   I218_ULP_CONFIG1_RESET_TO_SMBUS or
                                   I218_ULP_CONFIG1_WOL_HOST or
                                   I218_ULP_CONFIG1_INBAND_EXIT or
                                   I218_ULP_CONFIG1_EN_ULP_LANPHYPC or
                                   I218_ULP_CONFIG1_DIS_CLR_STICKY_ON_PERST or
                                   I218_ULP_CONFIG1_DISABLE_SMB_PERST));

      Unused := E1000_Write_Phy_Reg_Hv_Locked (HW,
                                               I218_ULP_CONFIG1,
                                               Phy_Reg);

      -- Commit ULP changes by starting auto ULP configuration.
      --
      Phy_Reg := Phy_Reg or I218_ULP_CONFIG1_START;
      Unused  := E1000_Write_Phy_Reg_Hv_Locked (HW,
                                                I218_ULP_CONFIG1,
                                                Phy_Reg);

      -- Clear Disable SMBus Release on PERST# in MAC.
      --
      Mac_Reg := ER32 (Hw.all, Devices.e1000e.Registers.E1000_FEXTNVM7);
      Mac_Reg := Mac_Reg and (not E1000_FEXTNVM7_DISABLE_SMB_PERST);
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_FEXTNVM7, Mac_Reg);


      <<Release_Label>>

      HW.Phy.Ops.Release (HW);

      if Force
      then
         Unused := E1000_Phy_Hw_Reset (HW);
         delay 0.050;                      -- Equivalent to msleep(50)
      end if;


      <<Out_Label>>

      if Ret_Val /= 0
      then
         e_dbg ("Error in ULP disable flow:" & Ret_Val'Image);
      else
         HW.Dev_Spec.Ich8lan.ULP_State := E1000_ULP_State_Off;
      end if;

      return Ret_Val;
   end e1000_disable_ULP_LPT_LP;





   -----------------------------------------
   -- E1000_Check_For_Copper_Link_Ich8lan --
   -----------------------------------------

   --  Check for link (Copper).
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Checks to see of the link status of the hardware has changed.  If a
   --  *  change in link status has been detected, then we read the PHY registers
   --  *  to get the current speed/duplex if link exists.


   function E1000_Check_For_Copper_Link_Ich8lan (Hw : access E1000_Hw) return s32
   is
      use Devices.e1000e.Media_Access_Control;

      Mac      :         E1000_Mac_Info.item renames Hw.Mac;
      Ret_Val  :         s32         := 0;
      Tipg_Reg :         Unsigned_32 := 0;
      Emi_Addr :         Unsigned_16;
      Emi_Val  : aliased Unsigned_16 := 0;
      Link     :         Boolean;
      Phy_Reg  : aliased Unsigned_16;
      Unused   :         s32;

   begin
      --  We only want to go out to the PHY registers to see if Auto-Neg
      --  has completed and/or if our link status has changed.  The
      --  get_link_status flag is set upon receiving a Link Status
      --  Change or Rx Sequence Error interrupt.
      --
      if not Mac.Get_Link_Status
      then
         return 0;
      end if;

      Mac.Get_Link_Status := False;


      --  First we want to see if the MII Status Register reports
      --  link.  If so, then we want to get the current speed/duplex
      --  of the PHY.
      --
      Ret_Val := E1000e_Phy_Has_Link_Generic (Hw, 1, 0, Link);

      if Ret_Val /= 0
      then
         goto Out_Label;
      end if;

      if Hw.Mac.Mac_Type = E1000_Pchlan
      then
         Ret_Val := E1000_K1_Gig_Workaround_Hv (Hw, Link);

         if Ret_Val /= 0
         then
            goto Out_Label;
         end if;
      end if;


      --  When connected at 10Mbps half-duplex, some parts are excessively
      --  aggressive resulting in many collisions. To avoid this, increase
      --  the IPG and reduce Rx latency in the PHY.
      --
      if Hw.Mac.Mac_Type >= E1000_Pch2lan and then Link
      then
         declare
            Speed  : aliased Unsigned_16;
            Duplex : aliased Unsigned_16;
         begin
            Unused := E1000e_Get_Speed_And_Duplex_Copper (Hw,
                                                          Speed 'unchecked_Access,
                                                          Duplex'unchecked_Access);
            Tipg_Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_TIPG);
            Tipg_Reg := Tipg_Reg and (not E1000_TIPG_IPGT_MASK);

            if    Duplex = HALF_DUPLEX
              and Speed  = SPEED_10
            then
               Tipg_Reg := Tipg_Reg or 16#FF#;
               Emi_Val := 0;                        -- Reduce Rx latency in analog PHY.

            elsif     Hw.Mac.Mac_Type >= E1000_Pch_Spt
                  and Duplex = FULL_DUPLEX
                  and Speed /= SPEED_1000
            then
               Tipg_Reg := Tipg_Reg or 16#C#;
               Emi_Val := 1;

            else
               -- Roll back the default values.
               --
               Tipg_Reg := Tipg_Reg or 16#8#;
               Emi_Val := 1;
            end if;


            Ew32 (Hw.all, Devices.e1000e.Registers.E1000_TIPG, Tipg_Reg);

            Ret_Val := Hw.Phy.Ops.Acquire (Hw);

            if Ret_Val /= 0
            then
               goto Out_Label;
            end if;

            if Hw.Mac.Mac_Type = E1000_Pch2lan
            then
               Emi_Addr := I82579_RX_CONFIG;
            else
               Emi_Addr := I217_RX_CONFIG;
            end if;

            Ret_Val := E1000_Write_Emi_Reg_Locked (Hw, Emi_Addr, Emi_Val);


            if Hw.Mac.Mac_Type >= E1000_Pch_Lpt
            then
               Unused := E1e_Rphy_Locked (Hw,
                                          I217_PLL_CLOCK_GATE_REG,
                                          Phy_Reg'unchecked_Access);

               Phy_Reg := Phy_Reg and (not I217_PLL_CLOCK_GATE_MASK);

               if Speed = SPEED_100 or Speed = SPEED_10
               then
                  Phy_Reg := Phy_Reg or 16#3E8#;
               else
                  Phy_Reg := Phy_Reg or 16#FA#;
               end if;

               Unused := E1e_Wphy_Locked (Hw,
                                          I217_PLL_CLOCK_GATE_REG,
                                          Phy_Reg);
               if Speed = SPEED_1000
               then
                  Unused  := Hw.Phy.Ops.Read_Reg_Locked (Hw,
                                                         HV_PM_CTRL,
                                                         Phy_Reg'unchecked_Access);
                  Phy_Reg := Phy_Reg or HV_PM_CTRL_K1_CLK_REQ;
                  Unused  := Hw.Phy.Ops.Write_Reg_Locked (Hw,
                                                          HV_PM_CTRL,
                                                          Phy_Reg);
               end if;
            end if;


            Hw.Phy.Ops.Release (Hw);

            if Ret_Val /= 0
            then
               goto Out_Label;
            end if;


            if Hw.Mac.Mac_Type >= E1000_Pch_Spt
            then
               declare
                  Data    : aliased Unsigned_16;
                  Ptr_Gap :         Unsigned_16;
               begin
                  if Speed = SPEED_1000
                  then
                     Ret_Val := Hw.Phy.Ops.Acquire (Hw);

                     if Ret_Val /= 0
                     then
                        goto Out_Label;
                     end if;

                     Ret_Val := E1e_Rphy_Locked (Hw,
                                                 Devices.e1000e.Ich8Lan.PHY_REG (776, 20),
                                                 Data'unchecked_Access);

                     if Ret_Val /= 0
                     then
                        Hw.Phy.Ops.Release (Hw);
                        goto Out_Label;
                     end if;

                     Ptr_Gap := Shift_Right (Data and (16#3FF# * 4), 2);

                     if Ptr_Gap < 16#18#
                     then
                        Data    := Data and (not (16#3FF# * 4));
                        Data    := Data or (16#18# * 4);
                        Ret_Val := E1e_Wphy_Locked (Hw,
                                                    Devices.e1000e.Ich8Lan.PHY_REG (776, 20),
                                                    Data);
                     end if;

                     Hw.Phy.Ops.Release (Hw);

                     if Ret_Val /= 0
                     then
                        goto Out_Label;
                     end if;

                  else
                     Ret_Val := Hw.Phy.Ops.Acquire (Hw);

                     if Ret_Val /= 0
                     then
                        goto Out_Label;
                     end if;

                     Ret_Val := E1e_Wphy_Locked (Hw,
                                                 Devices.e1000e.Ich8Lan.PHY_REG (776, 20),
                                                 16#C023#);
                     Hw.Phy.Ops.Release (Hw);

                     if Ret_Val /= 0
                     then
                        goto Out_Label;
                     end if;
                  end if;
               end;
            end if;
         end;
      end if;


      --  I217 Packet Loss issue:
      --  Ensure that FEXTNVM4 Beacon Duration is set correctly
      --  on power up.
      --  Set the Beacon Duration for I217 to 8 usec.
      --
      if Hw.Mac.Mac_Type >= E1000_Pch_Lpt
      then
         declare
            Mac_Reg : Unsigned_32;
         begin
            Mac_Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_FEXTNVM4);
            Mac_Reg := Mac_Reg and (not E1000_FEXTNVM4_BEACON_DURATION_MASK);
            Mac_Reg := Mac_Reg or E1000_FEXTNVM4_BEACON_DURATION_8USEC;
            Ew32 (Hw.all, Devices.e1000e.Registers.E1000_FEXTNVM4, Mac_Reg);
         end;
      end if;

      --  Work-around I218 hang issue.
      --
      if Hw.Adapter.Pdev.Device = E1000_DEV_ID_PCH_LPTLP_I218_LM or
         Hw.Adapter.Pdev.Device = E1000_DEV_ID_PCH_LPTLP_I218_V or
         Hw.Adapter.Pdev.Device = E1000_DEV_ID_PCH_I218_LM3 or
         Hw.Adapter.Pdev.Device = E1000_DEV_ID_PCH_I218_V3
      then
         Ret_Val := E1000_K1_Workaround_Lpt_Lp (Hw, Link);

         if Ret_Val /= 0
         then
            goto Out_Label;
         end if;
      end if;


      if Hw.Mac.Mac_Type >= E1000_Pch_Lpt
      then
         --  Set platform power management values for
         --  Latency Tolerance Reporting (LTR)
         --
         Ret_Val := E1000_Platform_Pm_Pch_Lpt (Hw, Link);

         if Ret_Val /= 0
         then
            goto Out_Label;
         end if;
      end if;


      Hw.Dev_Spec.Ich8lan.Eee_Lp_Ability := 0;     -- Clear link partner's EEE ability.

      if Hw.Mac.Mac_Type >= E1000_Pch_Lpt
      then
         declare
            Fextnvm6 : Unsigned_32 := Er32 (Hw.all, Devices.e1000e.Registers.E1000_FEXTNVM6);
         begin
            if Hw.Mac.Mac_Type = E1000_Pch_Spt
            then
               -- FEXTNVM6 K1-off workaround - for SPT only.
               --
               declare
                  Pcieanacfg : constant Unsigned_32 := Er32 (Hw.all, Devices.e1000e.Registers.E1000_PCIEANACFG);
               begin
                  if (Pcieanacfg and E1000_FEXTNVM6_K1_OFF_ENABLE) /= 0
                  then
                     Fextnvm6 := Fextnvm6 or E1000_FEXTNVM6_K1_OFF_ENABLE;
                  else
                     Fextnvm6 := Fextnvm6 and (not E1000_FEXTNVM6_K1_OFF_ENABLE);
                  end if;
               end;
            end if;

            Ew32 (Hw.all, Devices.e1000e.Registers.E1000_FEXTNVM6, Fextnvm6);
         end;
      end if;


      if not Link then
         goto Out_Label;
      end if;


      case Hw.Mac.Mac_Type
      is
         when E1000_Pch2lan =>
            Ret_Val := E1000_K1_Workaround_Lv (Hw);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;

         when E1000_Pchlan =>
            if Hw.Phy.Phy_Type = E1000_Phy_82578
            then
               Ret_Val := E1000_Link_Stall_Workaround_Hv (Hw);

               if Ret_Val /= 0 then
                  return Ret_Val;
               end if;
            end if;

            --  Workaround for PCHx parts in half-duplex:
            --  Set the number of preambles removed from the packet
            --  when it is passed from the PHY to the MAC to prevent
            --  the MAC from misinterpreting the packet type.
            --
            Unused  := E1e_Rphy (Hw,
                                 HV_KMRN_FIFO_CTRLSTA,
                                 Phy_Reg'unchecked_Access);
            Phy_Reg := Phy_Reg and (not HV_KMRN_FIFO_CTRLSTA_PREAMBLE_MASK);

            if  (Er32 (Hw.all, Devices.e1000e.Registers.E1000_STATUS) and E1000_STATUS_FD)
              /= E1000_STATUS_FD
            then
               Phy_Reg := Phy_Reg or Shift_Left (1, HV_KMRN_FIFO_CTRLSTA_PREAMBLE_SHIFT);
            end if;

            Unused := E1e_Wphy (Hw,
                                HV_KMRN_FIFO_CTRLSTA,
                                Phy_Reg);

         when others =>
            null;
      end case;


      --  Check if there was DownShift, must be checked
      --  immediately after link-up.
      --
      Unused := E1000e_Check_Downshift (Hw);

      -- Enable/Disable EEE after link up.
      --
      if Hw.Phy.Phy_Type > E1000_Phy_82579
      then
         Ret_Val := E1000_Set_Eee_Pchlan (Hw);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;
      end if;


      --  If we are forcing speed/duplex, then we simply return since
      --  we have already determined whether we have link or not.
      --
      if not Mac.Autoneg
      then
         return -E1000_ERR_CONFIG;
      end if;


      --  Auto-Neg is enabled.  Auto Speed Detection takes care
      --  of MAC speed/duplex configuration.  So we only need to
      --  configure Collision Distance in the MAC.
      --
      Mac.Ops.Config_Collision_Dist (Hw);

      --  Configure Flow Control now that Auto-Neg has completed.
      --  First, we need to restore the desired flow control
      --  settings because we may have had to re-autoneg with a
      --  different link partner.
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
   end E1000_Check_For_Copper_Link_Ich8lan;




   --------------------------------
   -- E1000_Get_Variants_Ich8lan --
   --------------------------------

   function E1000_Get_Variants_Ich8lan
     (Adapter : access Devices.e1000e.Base.E1000_Adapter.item) return s32
   is
      Hw : constant access E1000_Hw := Adapter.Hw'Access;
      Rc :                 s32;
   begin
      Rc := E1000_Init_Mac_Params_Ich8lan (Hw);

      if Rc /= 0
      then
         return Rc;
      end if;


      Rc := E1000_Init_Nvm_Params_Ich8lan (Hw);

      if Rc /= 0
      then
         return Rc;
      end if;


      case Hw.Mac.Mac_Type
      is
         when E1000_Ich8lan
            | E1000_Ich9lan
            | E1000_Ich10lan =>
            Rc := E1000_Init_Phy_Params_Ich8lan (Hw);

         when E1000_Pchlan
            | E1000_Pch2lan
            | E1000_Pch_Lpt
            | E1000_Pch_Spt
            | E1000_Pch_Cnp
            | E1000_Pch_Tgp
            | E1000_Pch_Adp
            | E1000_Pch_Mtp
            | E1000_Pch_Lnp
            | E1000_Pch_Ptp
            | E1000_Pch_Nvp =>
            Rc := E1000_Init_Phy_Params_Pchlan (Hw);

         when others =>
            null;
      end case;

      if Rc /= 0
      then
         return Rc;
      end if;


      -- Disable Jumbo Frame support on parts with Intel 10/100 PHY or
      -- on parts with MACsec enabled in NVM (reflected in CTRL_EXT).
      --
      if         Adapter.Hw.Phy.Phy_Type  = E1000_Phy_Ife
        or else (          Adapter.Hw.Mac.Mac_Type >= E1000_Pch2lan
                 and then (    Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT)
                           and E1000_CTRL_EXT_LSECCK) = 0)
      then
         Adapter.Flags             := Adapter.Flags and (not C.unsigned (FLAG_HAS_JUMBO_FRAMES));
         Adapter.Max_Hw_Frame_Size := VLAN_ETH_FRAME_LEN + ETH_FCS_LEN;
         Hw.Mac.Ops.Blink_Led      := null;
      end if;


      if         Adapter.Hw.Mac.Mac_Type  = E1000_Ich8lan
        and then Adapter.Hw.Phy.Phy_Type /= E1000_Phy_Ife
      then
         Adapter.Flags := Adapter.Flags or C.unsigned (FLAG_LSC_GIG_SPEED_DROP);
      end if;


      -- Enable workaround for 82579 w/ ME enabled.
      --
      if         Adapter.Hw.Mac.Mac_Type = E1000_Pch2lan
        and then (    Er32 (Hw.all, Devices.e1000e.Registers.E1000_FWSM)
                  and E1000_ICH_FWSM_FW_VALID) /= 0
      then
         Adapter.Flags2 := Adapter.Flags2 or C.unsigned (FLAG2_PCIM2PCI_ARBITER_WA);
      end if;


      return 0;
   end E1000_Get_Variants_Ich8lan;




   nvm_mutex : Mutex;



   -------------------------------
   -- E1000_Acquire_NVM_ICH8LAN --
   -------------------------------

   --  Acquire NVM mutex.
   --
   --  *  @hw: Pointer to the HW structure
   --  *
   --  *  Acquires the mutex for performing NVM operations.


   function E1000_Acquire_NVM_ICH8LAN
     (HW : access E1000_HW with Unreferenced) return s32
   is
   begin
      NVM_Mutex.acquire;
      return 0;
   end E1000_Acquire_NVM_ICH8LAN;





   -------------------------------
   -- E1000_Release_NVM_ICH8LAN --
   -------------------------------

   -- Release NVM mutex.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Releases the mutex used while performing NVM operations.


   procedure E1000_Release_NVM_ICH8LAN
     (HW : access E1000_HW with Unreferenced)
   is
   begin
      NVM_Mutex.release;
   end E1000_Release_NVM_ICH8LAN;




   ----------------------------------
   -- E1000_Acquire_Swflag_Ich8lan --
   ----------------------------------

   --  Acquire software control flag.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Acquires the software control flag for performing PHY and select
   --  *  MAC CSR accesses.


   function E1000_Acquire_Swflag_Ich8lan
     (Hw : access E1000_Hw) return s32
   is
      Extcnf_Ctrl : Interfaces.Unsigned_32;
      Timeout     : Natural               := PHY_CFG_TIMEOUT;
      Ret_Val     : s32                   := 0;

   begin
      if Test_And_Set_Bit (E1000_ACCESS_SHARED_RESOURCE'enum_Rep,
                           Hw.Adapter.State'Access)
      then
         e_dbg ("contention for Phy access");
         return -E1000_ERR_PHY;
      end if;


      while Timeout > 0
      loop
         Extcnf_Ctrl := Er32 (Hw.all, Devices.e1000e.Registers.E1000_EXTCNF_CTRL);

         if (Extcnf_Ctrl and E1000_EXTCNF_CTRL_SWFLAG) = 0
         then
            exit;
         end if;

         delay 0.001;  -- 1 millisecond delay
         Timeout := Timeout - 1;
      end loop;


      if Timeout = 0
      then
         e_dbg ("SW has already locked the resource.");
         Ret_Val := -E1000_ERR_CONFIG;
         goto Out_Label;
      end if;

      Timeout := SW_FLAG_TIMEOUT;

      Extcnf_Ctrl := Extcnf_Ctrl or E1000_EXTCNF_CTRL_SWFLAG;
      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_EXTCNF_CTRL, Extcnf_Ctrl);


      while Timeout > 0
      loop
         Extcnf_Ctrl := Er32 (Hw.all, Devices.e1000e.Registers.E1000_EXTCNF_CTRL);

         if (Extcnf_Ctrl and E1000_EXTCNF_CTRL_SWFLAG) /= 0
         then
            exit;
         end if;

         delay 0.001;  -- 1 millisecond delay
         Timeout := Timeout - 1;
      end loop;


      if Timeout = 0
      then
         e_dbg (  "Failed to acquire the semaphore, FW or HW has it: FWSM="
                & Er32 (Hw.all, Devices.e1000e.Registers.E1000_FWSM)'Image
                & " EXTCNF_CTRL="
                & Extcnf_Ctrl'Image);

         Extcnf_Ctrl := Extcnf_Ctrl and (not E1000_EXTCNF_CTRL_SWFLAG);

         Ew32 (Hw.all, Devices.e1000e.Registers.E1000_EXTCNF_CTRL, Extcnf_Ctrl);

         Ret_Val := -E1000_ERR_CONFIG;

         goto Out_Label;
      end if;


      <<Out_Label>>

      if Ret_Val /= 0
      then
         clear_Bit (E1000_ACCESS_SHARED_RESOURCE'enum_Rep,
                    Hw.Adapter.State'Address);
      end if;


      return Ret_Val;
   end E1000_Acquire_Swflag_Ich8lan;




   ----------------------------------
   -- E1000_Release_Swflag_Ich8lan --
   ----------------------------------

   --  Release software control flag.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Releases the software control flag for performing PHY and select
   --  *  MAC CSR accesses.


   procedure E1000_Release_Swflag_Ich8lan
     (HW : access E1000_HW)
   is
      Extcnf_Ctrl : u32;

   begin
      Extcnf_Ctrl := Er32 (Hw.all, Devices.e1000e.Registers.E1000_EXTCNF_CTRL);

      if (Extcnf_Ctrl and E1000_EXTCNF_CTRL_SWFLAG) /= 0
      then
         Extcnf_Ctrl := Extcnf_Ctrl and (not E1000_EXTCNF_CTRL_SWFLAG);
         Ew32 (Hw.all, Devices.e1000e.Registers.E1000_EXTCNF_CTRL, Extcnf_Ctrl);
      else
         e_dbg ("Semaphore unexpectedly released by sw/fw/hw");
      end if;

      clear_Bit (E1000_ACCESS_SHARED_RESOURCE'enum_Rep,
                 HW.Adapter.State'Address);
   end E1000_Release_Swflag_Ich8lan;




   ----------------------------------
   -- E1000_Check_Mng_Mode_Ich8lan --
   ----------------------------------

   --  Checks management mode.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  This checks if the adapter has any manageability enabled.
   --  *  This is a function pointer entry point only called by read/write
   --  *  routines for the PHY and NVM parts.


   function E1000_Check_Mng_Mode_Ich8lan
     (HW : access E1000_HW) return Boolean
   is
      Fwsm : Unsigned_32;
   begin
      Fwsm := Er32 (Hw.all, Devices.e1000e.Registers.E1000_FWSM);

      return     (Fwsm and E1000_ICH_FWSM_FW_VALID)    /= 0
        and then (Fwsm and Devices.e1000e.Manage.E1000_FWSM_MODE_MASK) = shift_Left (E1000_ICH_MNG_IAMT_MODE,
                                                                      Devices.e1000e.Manage.E1000_FWSM_MODE_SHIFT);
   end E1000_Check_Mng_Mode_Ich8lan;




   ---------------------------------
   -- E1000_Check_Mng_Mode_Pchlan --
   ---------------------------------

   --  Checks management mode.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  This checks if the adapter has iAMT enabled.
   --  *  This is a function pointer entry point only called by read/write
   --  *  routines for the PHY and NVM parts.

   function E1000_Check_Mng_Mode_Pchlan (Hw : access E1000_HW) return Boolean
   is
      FWSM : Unsigned_32;
   begin
       Fwsm := Er32 (Hw.all, Devices.e1000e.Registers.E1000_FWSM);

      return     (FWSM and E1000_ICH_FWSM_FW_VALID)                   /= 0
        and then (FWSM and shift_Left (E1000_ICH_MNG_IAMT_MODE,
                                       Devices.e1000e.Manage.E1000_FWSM_MODE_SHIFT)) /= 0;
   end E1000_Check_Mng_Mode_Pchlan;




   ---------------------------
   -- E1000_Rar_Set_Pch2lan --
   ---------------------------

   --  Set receive address register.
   --
   --  *  @hw:    Pointer to the HW structure.
   --  *  @addr:  Pointer to the receive address.
   --  *  @index: Receive address array register.
   --  *
   --  *  Sets the receive address array register at index to the address passed
   --  *  in by addr.  For 82579, RAR[0] is the base address register that is to
   --  *  contain the MAC address but RAR[1-6] are reserved for manageability (ME).
   --  *  Use SHRA[0-3] in place of those reserved for ME.


   function E1000_Rar_Set_Pch2lan
     (Hw    : access E1000_Hw;
      Addr  : in     u8_Pointer;
      Index : in     Unsigned_32) return C.int
   is
      Rar_Low,
      Rar_High  : Unsigned_32;

      Addr_Data : u8_array (0 .. 5)
        with
          Address => Addr.all'Address;

   begin
      -- HW expects these in little endian so we reverse the byte order
      -- from network order (big endian) to little endian.
      --
      Rar_Low  :=                u32 (Addr_Data (0))
                  or shift_Left (u32 (Addr_Data (1)),  8)
                  or shift_Left (u32 (Addr_Data (2)), 16)
                  or shift_Left (u32 (Addr_Data (3)), 24);

      Rar_High :=                u32 (Addr_Data (4))
                  or shift_Left (u32 (Addr_Data (5)), 8);

      -- If MAC address zero, no need to set the AV bit.
      --
      if   Rar_Low  /= 0
        or Rar_High /= 0
      then
         Rar_High := Rar_High or E1000_RAH_AV;
      end if;


      if Index = 0
      then
         Ew32 (Hw.all,
               Devices.e1000e.Registers.E1000_RAL (Index),
               Rar_Low);
         E1E_Flush (Hw);

         Ew32 (Hw.all,
               Devices.e1000e.Registers.E1000_RAH (Index),
               Rar_High);
         E1E_Flush (Hw);

         return 0;
      end if;


      -- RAR[1-6] are owned by manageability. Skip those and program the
      -- next address into the SHRA register array.
      --
      if Index < u32 (Hw.Mac.Rar_Entry_Count)
      then
         declare
            Ret_Val : Integer;
         begin
            Ret_Val := Integer (E1000_Acquire_Swflag_Ich8lan (Hw));

            if Ret_Val /= 0
            then
               goto Out_Label;
            end if;

            Ew32 (Hw.all,
                  Devices.e1000e.Registers.E1000_SHRAL (Integer_Address (Index - 1)),
                  Rar_Low);

            E1E_Flush (Hw);

            Ew32 (Hw.all,
                  Devices.e1000e.Registers.E1000_SHRAH (Integer_Address (Index - 1)),
                  Rar_High);

            E1E_Flush (Hw);

            E1000_Release_Swflag_Ich8lan (Hw);

            -- verify the register updates
            if    Er32 (Hw.all,
                        Devices.e1000e.Registers.E1000_SHRAL (Integer_Address (Index - 1)))
              =   Rar_Low
              and Er32 (Hw.all,
                        Devices.e1000e.Registers.E1000_SHRAH (Integer_Address (Index - 1)))
              =   Rar_High
            then
               return 0;
            end if;

            E_Dbg (  "SHRA["
                   & Integer'Image (Integer (Index) - 1)
                   & "] might be locked by ME - FWSM=0x"
                   & Er32 (Hw.all, Devices.e1000e.Registers.E1000_FWSM)'Image);
         end;
      end if;


      <<Out_Label>>

      E_Dbg("Failed to write receive address at index " & Index'Image);
      return -E1000_ERR_CONFIG;
   end E1000_Rar_Set_Pch2lan;




   ---------------------------------
   -- E1000_Rar_Get_Count_Pch_Lpt --
   ---------------------------------

   --  Get the number of available SHRA.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Get the number of available receive registers that the Host can
   --  *  program. SHRA[0-10] are the shared receive address registers
   --  *  that are shared between the Host and manageability engine (ME).
   --  *  ME can reserve any number of addresses and the host needs to be
   --  *  able to tell how many available registers it has access to.


   function E1000_Rar_Get_Count_Pch_Lpt
     (Hw : access E1000_Hw) return Unsigned_32
   is
      Wlock_Mac   : Unsigned_32;
      Num_Entries : Unsigned_32;

   begin
      Wlock_Mac := Er32 (Hw.all, Devices.e1000e.Registers.E1000_FWSM) and E1000_FWSM_WLOCK_MAC_MASK;
      Wlock_Mac := Shift_Right (Wlock_Mac, E1000_FWSM_WLOCK_MAC_SHIFT);

      case Wlock_Mac
      is
         when 0      =>   Num_Entries := u32 (Hw.Mac.Rar_Entry_Count);     -- All SHRA[0..10] and RAR[0] available.
         when 1      =>   Num_Entries := 1;                                -- Only RAR[0] available.
         when others =>   Num_Entries := Wlock_Mac + 1;                    -- SHRA [0..(wlock_mac - 1)] available + RAR [0].
      end case;

      return Num_Entries;
   end E1000_Rar_Get_Count_Pch_Lpt;




   ---------------------------
   -- E1000_Rar_Set_Pch_Lpt --
   ---------------------------

   --  Set receive address registers
   --  *  @hw:    Pointer to the HW structure
   --  *  @addr:  Pointer to the receive address
   --  *  @index: Receive address array register
   --  *
   --  *  Sets the receive address register array at index to the address passed
   --  *  in by addr. For LPT, RAR[0] is the base address register that is to
   --  *  contain the MAC address. SHRA[0-10] are the shared receive address
   --  *  registers that are shared between the Host and manageability engine (ME).


   function E1000_Rar_Set_Pch_Lpt
     (Hw    : access E1000_Hw;
      Addr  : in     u8_Pointer;
      Index : in     Unsigned_32) return C.int
   is
      Rar_Low,
      Rar_High  : Unsigned_32;
      Wlock_Mac : Unsigned_32;

      Addr_Data : u8_array (0 .. 5)
        with
          Address => Addr.all'Address;

   begin
      -- HW expects these in little endian so we reverse the byte order
      -- from network order (big endian) to little endian.
      --
      Rar_Low  :=                U32 (Addr_Data (0))
                  or shift_Left (U32 (Addr_Data (1)),  8)
                  or shift_Left (U32 (Addr_Data (2)), 16)
                  or shift_Left (U32 (Addr_Data (3)), 24);

      Rar_High :=    U32 (Addr_Data (4))
                  or Shift_Left (U32 (Addr_Data (5)),  8);


      -- If MAC address zero, no need to set the AV bit.
      --
      if   Rar_Low  /= 0
        or Rar_High /= 0
      then
         Rar_High := Rar_High or E1000_RAH_AV;
      end if;

      if Index = 0
      then
         Ew32 (Hw.all,
               Devices.e1000e.Registers.E1000_RAL (Index),
               Rar_Low);
         E1E_Flush (Hw);

         Ew32 (Hw.all,
               Devices.e1000e.Registers.E1000_RAH (Index),
               Rar_High);
         E1E_Flush (Hw);

         return 0;
      end if;


      -- The manageability engine (ME) can lock certain SHRAR registers that
      -- it is using - those registers are unavailable for use.
      --
      if Index < u32 (Hw.Mac.Rar_Entry_Count)
      then
         Wlock_Mac := Shift_Right (    Er32 (Hw.all, Devices.e1000e.Registers.E1000_FWSM)
                                   and E1000_FWSM_WLOCK_MAC_MASK,
                                   E1000_FWSM_WLOCK_MAC_SHIFT);

         -- Check if all SHRAR registers are locked.
         --
         if Wlock_Mac = 1
         then
            goto Out_Label;
         end if;

         if Wlock_Mac = 0 or Index <= Wlock_Mac
         then
            declare
               Ret_Val : Integer;
            begin
               Ret_Val := Integer (E1000_Acquire_Swflag_Ich8lan (Hw));

               if Ret_Val /= 0
               then
                  goto Out_Label;
               end if;

               Ew32 (Hw.all,
                     to_ulong (E1000_SHRAL_PCH_LPT (Integer_Address (Index - 1))),
                     Rar_Low);
               E1E_Flush (Hw);

               Ew32 (Hw.all,
                     to_ulong (E1000_SHRAH_PCH_LPT (Integer_Address (Index - 1))),
                     Rar_High);
               E1E_Flush (Hw);

               E1000_Release_Swflag_Ich8lan (Hw);

               -- Verify the register updates.
               --
               if    Er32 (Hw.all,
                           to_ulong (E1000_SHRAL_PCH_LPT (Integer_Address (Index - 1)))) = Rar_Low
                 and Er32 (Hw.all,
                           to_ulong (E1000_SHRAH_PCH_LPT (Integer_Address (Index - 1)))) = Rar_High
               then
                  return 0;
               end if;
            end;
         end if;
      end if;


      <<Out_Label>>

      E_Dbg("Failed to write receive address at index" & Index'Image);
      return -E1000_ERR_CONFIG;
   end E1000_Rar_Set_Pch_Lpt;




   -------------------------------------
   -- E1000_Check_Reset_Block_Ich8lan --
   -------------------------------------

   --  Check if PHY reset is blocked.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Checks if firmware is blocking the reset of the PHY.
   --  *  This is a function pointer entry point only called by
   --  *  reset routines.


   function E1000_Check_Reset_Block_Ich8lan (Hw : access E1000_Hw) return s32
   is
      Blocked : Boolean := False;
      I       : Natural := 0;

   begin
      loop
         Blocked := (Er32 (Hw.all, Devices.e1000e.Registers.E1000_FWSM) and E1000_ICH_FWSM_RSPCIPHY) = 0;

         exit when not Blocked or I >= 30;

         delay Duration (0.010);  -- Sleep for 10ms.

         I := I + 1;
      end loop;


      if Blocked
      then
         return E1000_BLK_PHY_RESET;
      else
         return 0;
      end if;
   end E1000_Check_Reset_Block_Ich8lan;




   ----------------------------
   -- E1000_Write_Smbus_Addr --
   ----------------------------

   --  Write SMBus address to PHY needed during Sx states.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Assumes semaphore already acquired.


   function E1000_Write_Smbus_Addr (Hw : access E1000_Hw) return s32
   is
      Phy_Data : aliased Unsigned_16;
      Strap    :         Unsigned_32 := Er32 (Hw.all, E1000_STRAP);
      Freq     :         Unsigned_32 := shift_Right (Strap and E1000_STRAP_SMT_FREQ_MASK,
                                                     E1000_STRAP_SMT_FREQ_SHIFT);
      Ret_Val  : s32;

   begin
      Strap := Strap and E1000_STRAP_SMBUS_ADDRESS_MASK;

      Ret_Val := E1000_Read_Phy_Reg_Hv_Locked (Hw,
                                               HV_SMB_ADDR,
                                               Phy_Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;

      Phy_Data := Phy_Data and (not HV_SMB_ADDR_MASK);
      Phy_Data := Phy_Data or Unsigned_16 (Shift_Right (Strap, E1000_STRAP_SMBUS_ADDRESS_SHIFT));
      Phy_Data := Phy_Data or HV_SMB_ADDR_PEC_EN or HV_SMB_ADDR_VALID;

      if Hw.Phy.Phy_Type = E1000_Phy_I217
      then
         -- Restore SMBus frequency.
         --
         if Freq /= 0
         then
            Freq     := Freq - 1;
            Phy_Data := Phy_Data and (not HV_SMB_ADDR_FREQ_MASK);
            Phy_Data := Phy_Data or Shift_Left (Unsigned_16 (Freq and 1),
                                                HV_SMB_ADDR_FREQ_LOW_SHIFT);
            Phy_Data := Phy_Data or Shift_Left (Unsigned_16 (Shift_Right (Freq and 2, 1)),
                                                HV_SMB_ADDR_FREQ_HIGH_SHIFT);
         else
            e_dbg ("Unsupported SMB frequency in PHY");
         end if;
      end if;


      return E1000_Write_Phy_Reg_Hv_Locked (Hw,
                                            HV_SMB_ADDR,
                                            Phy_Data);
   end E1000_Write_Smbus_Addr;





   ---------------------------------
   -- E1000_Sw_Lcd_Config_Ich8lan --
   ---------------------------------

   --  SW-based LCD Configuration
   --
   --  *  @hw:   Pointer to the HW structure.
   --  *
   --  *  SW should configure the LCD from the NVM extended configuration region
   --  *  as a workaround for certain parts.


   function E1000_Sw_Lcd_Config_Ich8lan (Hw : access E1000_Hw) return s32
   is
      Phy         :         E1000_Phy_Info.item renames Hw.Phy;
      Data,
      Cnf_Size,
      Cnf_Base_Addr,
      Sw_Cfg_Mask :         Unsigned_32;
      Ret_Val     :         s32 := 0;
      Word_Addr,
      Reg_Data,
      Reg_Addr    : aliased Unsigned_16;
      Phy_Page    :         Unsigned_16 := 0;

   begin
      -- Initialize the PHY from the NVM on ICH platforms.
      -- This is needed due to an issue where the NVM configuration is
      -- not properly autoloaded after power transitions.
      -- Therefore, after each PHY reset, we will load the
      -- configuration data out of the NVM manually.
      --
      case Hw.Mac.Mac_Type
      is
         when E1000_Ich8lan =>
            if Phy.Phy_Type /= E1000_Phy_Igp_3
            then
               return Ret_Val;
            end if;

            if   Hw.Adapter.Pdev.Device = E1000_DEV_ID_ICH8_IGP_AMT
              or Hw.Adapter.Pdev.Device = E1000_DEV_ID_ICH8_IGP_C
            then
               Sw_Cfg_Mask := E1000_FEXTNVM_SW_CONFIG;
            else
               Sw_Cfg_Mask := E1000_FEXTNVM_SW_CONFIG_ICH8M;
            end if;

         when E1000_Pchlan
            | E1000_Pch2lan
            | E1000_Pch_Lpt
            | E1000_Pch_Spt
            | E1000_Pch_Cnp
            | E1000_Pch_Tgp
            | E1000_Pch_Adp
            | E1000_Pch_Mtp
            | E1000_Pch_Lnp
            | E1000_Pch_Ptp
            | E1000_Pch_Nvp =>
            Sw_Cfg_Mask := E1000_FEXTNVM_SW_CONFIG_ICH8M;

         when others =>
            return Ret_Val;
      end case;


      Ret_Val := Hw.Phy.Ops.Acquire (Hw);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Data := Er32 (Hw.all, Devices.e1000e.Registers.E1000_FEXTNVM);

      if (Data and Sw_Cfg_Mask) = 0
      then
         goto Release_Label;
      end if;


      -- Make sure HW does not configure LCD from PHY
      -- extended configuration before SW configuration.
      --
      Data := Er32 (Hw.all, Devices.e1000e.Registers.E1000_EXTCNF_CTRL);

      if     Hw.Mac.Mac_Type < E1000_Pch2lan
        and (Data and E1000_EXTCNF_CTRL_LCD_WRITE_ENABLE) /= 0
      then
         goto Release_Label;
      end if;


      Cnf_Size := Er32 (Hw.all, Devices.e1000e.Registers.E1000_EXTCNF_SIZE);
      Cnf_Size := Cnf_Size and E1000_EXTCNF_SIZE_EXT_PCIE_LENGTH_MASK;
      Cnf_Size := shift_Right (Cnf_Size,
                               E1000_EXTCNF_SIZE_EXT_PCIE_LENGTH_SHIFT);

      if Cnf_Size = 0
      then
         goto Release_Label;
      end if;


      Cnf_Base_Addr := Data and E1000_EXTCNF_CTRL_EXT_CNF_POINTER_MASK;
      Cnf_Base_Addr := shift_Right (Cnf_Base_Addr,
                                    E1000_EXTCNF_CTRL_EXT_CNF_POINTER_SHIFT);

      if   (     Hw.Mac.Mac_Type = E1000_Pchlan
            and (Data and E1000_EXTCNF_CTRL_OEM_WRITE_ENABLE) = 0)
        or Hw.Mac.Mac_Type > E1000_Pchlan
      then
         -- HW configures the SMBus address and LEDs when the
         -- OEM and LCD Write Enable bits are set in the NVM.
         -- When both NVM bits are cleared, SW will configure
         -- them instead.
         --
         Ret_Val := E1000_Write_Smbus_Addr (Hw);

         if Ret_Val /= 0
         then
            goto Release_Label;
         end if;


         Data    := Er32 (Hw.all, Devices.e1000e.Registers.E1000_LEDCTL);
         Ret_Val := E1000_Write_Phy_Reg_Hv_Locked (Hw,
                                                   HV_LED_CONFIG,
                                                   Unsigned_16 (Data));
         if Ret_Val /= 0
         then
            goto Release_Label;
         end if;
      end if;


      -- Configure LCD from extended configuration region.
      --

      -- cnf_base_addr is in DWORD.
      --
      Word_Addr := Unsigned_16 (Shift_Left (Cnf_Base_Addr, 1));

      for I in 0 .. u16 (Cnf_Size) - 1
      loop
         Ret_Val := E1000_Read_Nvm (Hw,
                                    Word_Addr + I * 2,
                                    1,
                                    Reg_Data'unchecked_Access);
         if Ret_Val /= 0
         then
            goto Release_Label;
         end if;

         Ret_Val := E1000_Read_Nvm (Hw,
                                    Word_Addr + I * 2 + 1,
                                    1,
                                    Reg_Addr'unchecked_Access);
         if Ret_Val /= 0
         then
            goto Release_Label;
         end if;


         -- Save off the PHY page for future writes.
         --
         if Reg_Addr = IGP01E1000_PHY_PAGE_SELECT
         then
            Phy_Page := Reg_Data;
            goto Continue_Loop;
         end if;

         Reg_Addr := Reg_Addr and PHY_REG_MASK;
         Reg_Addr := Reg_Addr or Phy_Page;


         Ret_Val := E1e_Wphy_Locked (Hw,
                                     Unsigned_32 (Reg_Addr),
                                     Reg_Data);
         if Ret_Val /= 0
         then
            goto Release_Label;
         end if;

         <<Continue_Loop>>
      end loop;


      <<Release_Label>>

      Hw.Phy.Ops.Release (Hw);
      return Ret_Val;
   end E1000_Sw_Lcd_Config_Ich8lan;




   --------------------------------
   -- E1000_K1_Gig_Workaround_HV --
   --------------------------------

   --  K1 Si workaround.
   --
   --  *  @hw:   Pointer to the HW structure.
   --  *  @link: Link up bool flag.
   --  *
   --  *  If K1 is enabled for 1Gbps, the MAC might stall when transitioning
   --  *  from a lower speed.  This workaround disables K1 whenever link is at 1Gig
   --  *  If link is down, the function will restore the default K1 setting located
   --  *  in the NVM.


   function E1000_K1_Gig_Workaround_HV
     (HW   : access E1000_HW;
      Link : in     Boolean) return s32
   is

      Ret_Val    :         s32         := 0;
      Status_Reg : aliased Unsigned_16 := 0;
      K1_Enable  :         Boolean     := HW.Dev_Spec.ICH8LAN.NVM_K1_Enabled;

   begin
      if HW.Mac.Mac_Type /= E1000_PCHLAN
      then
         return 0;
      end if;

      -- Wrap the whole flow with the sw flag.
      --
      Ret_Val := HW.Phy.Ops.Acquire (HW);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;

      -- Disable K1 when link is 1Gbps, otherwise use the NVM setting.
      --
      if Link
      then
         if HW.Phy.Phy_Type = E1000_PHY_82578
         then
            Ret_Val := E1E_RPhy_Locked (HW,
                                        BM_CS_STATUS,
                                        Status_Reg'unchecked_Access);
            if Ret_Val /= 0
            then
               goto Release;
            end if;

            Status_Reg := Status_Reg and (   BM_CS_STATUS_LINK_UP
                                          or BM_CS_STATUS_RESOLVED
                                          or BM_CS_STATUS_SPEED_MASK);

            if Status_Reg = (   BM_CS_STATUS_LINK_UP
                             or BM_CS_STATUS_RESOLVED
                             or BM_CS_STATUS_SPEED_1000)
            then
               K1_Enable := False;
            end if;
         end if;


         if HW.Phy.Phy_Type = E1000_PHY_82577
         then
            Ret_Val := E1E_RPhy_Locked (HW,
                                        HV_M_STATUS,
                                        Status_Reg'unchecked_Access);
            if Ret_Val /= 0
            then
               goto Release;
            end if;

            Status_Reg := Status_Reg and (HV_M_STATUS_LINK_UP or
                                          HV_M_STATUS_AUTONEG_COMPLETE or
                                          HV_M_STATUS_SPEED_MASK);

            if Status_Reg = (HV_M_STATUS_LINK_UP or
                             HV_M_STATUS_AUTONEG_COMPLETE or
                                 HV_M_STATUS_SPEED_1000)
            then
               K1_Enable := False;
            end if;
         end if;


         -- Link stall fix for link up.
         --
         Ret_Val := E1E_WPhy_Locked (HW,
                                     PHY_REG (770, 19),
                                     16#0100#);
         if Ret_Val /= 0
         then
            goto Release;
         end if;

      else
         -- Link stall fix for link down.
         --
         Ret_Val := E1E_WPhy_Locked (HW,
                                     PHY_REG (770, 19),
                                     16#4100#);
         if Ret_Val /= 0
         then
            goto Release;
         end if;
      end if;

      Ret_Val := E1000_Configure_K1_ICH8LAN (HW, K1_Enable);


      <<Release>>

      HW.Phy.Ops.Release (HW);
      return Ret_Val;
   end E1000_K1_Gig_Workaround_HV;








   -----------------------------------
   -- E1000_Oem_Bits_Config_Ich8lan --
   -----------------------------------

   --  SW-based LCD Configuration.
   --
   --  *  @hw:       Pointer to the HW structure.
   --  *  @d0_state: Boolean if entering d0 or d3 device state.
   --  *
   --  *  SW will configure Gbe Disable and LPLU based on the NVM. The four bits are
   --  *  collectively called OEM bits.  The OEM Write Enable bit and SW Config bit
   --  *  in NVM determines whether HW should configure LPLU and Gbe Disable.


   function E1000_Oem_Bits_Config_Ich8lan
     (Hw       : access E1000_Hw;
      D0_State : in     Boolean) return s32
   is

      Ret_Val :         s32        := 0;
      Mac_Reg :         Unsigned_32;
      Oem_Reg : aliased Unsigned_16;

   begin
      if Hw.Mac.Mac_Type < E1000_Pchlan
      then
         return Ret_Val;
      end if;


      Ret_Val := Hw.Phy.Ops.Acquire (Hw);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      if Hw.Mac.Mac_Type = E1000_Pchlan
      then
         Mac_Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_EXTCNF_CTRL);

         if (Mac_Reg and E1000_EXTCNF_CTRL_OEM_WRITE_ENABLE) /= 0
         then
            goto Release;
         end if;
      end if;


      Mac_Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_FEXTNVM);

      if (Mac_Reg and E1000_FEXTNVM_SW_CONFIG_ICH8M) = 0
      then
         goto Release;
      end if;


      Mac_Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_PHY_CTRL);
      Ret_Val := E1e_Rphy_Locked (Hw,
                                  HV_OEM_BITS,
                                  Oem_Reg'unchecked_Access);

      if Ret_Val /= 0
      then
         goto Release;
      end if;


      Oem_Reg := Oem_Reg and not (HV_OEM_BITS_GBE_DIS or HV_OEM_BITS_LPLU);

      if D0_State
      then
         if (Mac_Reg and E1000_PHY_CTRL_GBE_DISABLE) /= 0
         then
            Oem_Reg := Oem_Reg or HV_OEM_BITS_GBE_DIS;
         end if;

         if (Mac_Reg and E1000_PHY_CTRL_D0A_LPLU) /= 0
         then
            Oem_Reg := Oem_Reg or HV_OEM_BITS_LPLU;
         end if;

      else
         if (Mac_Reg and (   E1000_PHY_CTRL_GBE_DISABLE
                          or E1000_PHY_CTRL_NOND0A_GBE_DISABLE)) /= 0
         then
            Oem_Reg := Oem_Reg or HV_OEM_BITS_GBE_DIS;
         end if;

         if (Mac_Reg and (   E1000_PHY_CTRL_D0A_LPLU
                          or E1000_PHY_CTRL_NOND0A_LPLU)) /= 0
         then
            Oem_Reg := Oem_Reg or HV_OEM_BITS_LPLU;
         end if;
      end if;


      -- Set Restart auto-neg to activate the bits.
      --
      if    (   D0_State
             or Hw.Mac.Mac_Type /= E1000_Pchlan)
        and Hw.Phy.Ops.Check_Reset_Block (Hw) = 0
      then
         Oem_Reg := Oem_Reg or HV_OEM_BITS_RESTART_AN;
      end if;

      Ret_Val := E1e_Wphy_Locked (Hw,
                                  HV_OEM_BITS,
                                  Oem_Reg);
      <<Release>>

      Hw.Phy.Ops.Release (Hw);
      return Ret_Val;
   end E1000_Oem_Bits_Config_Ich8lan;




   ---------------------------------
   -- E1000_Set_MDIO_Slow_Mode_HV --
   ---------------------------------

   --  Set slow MDIO access mode.
   --
   --  *  @hw:   Pointer to the HW structure.


   function E1000_Set_MDIO_Slow_Mode_HV
     (HW : access E1000_HW) return s32
   is
      Ret_Val :         s32;
      Data    : aliased u16;
   begin
      Ret_Val := E1E_RPhY (HW,
                           HV_KMRN_MODE_CTRL,
                           Data'unchecked_Access);
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;

      Data    := Data or HV_KMRN_MDIO_SLOW;
      Ret_Val := E1E_WPhY (HW,
                           HV_KMRN_MODE_CTRL,
                           Data);
      return Ret_Val;
   end E1000_Set_MDIO_Slow_Mode_HV;




   --------------------------------------
   -- E1000_HV_PHY_Workarounds_ICH8LAN --
   --------------------------------------

   --  Apply PHY workarounds.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  A series of PHY workarounds to be done after every PHY reset.


   function E1000_HV_PHY_Workarounds_ICH8LAN
     (HW : access E1000_HW) return s32
   is

      Unused   :         s32;
      Ret_Val  :         s32        := 0;
      PHY_Data : aliased Unsigned_16;

   begin
      if HW.Mac.mac_Type /= E1000_PCHLAN
      then
         return 0;
      end if;

      -- Set MDIO slow mode before any other MDIO access.
      --
      if HW.PHY.phy_Type = E1000_PHY_82577
      then
         Ret_Val := E1000_Set_MDIO_Slow_Mode_HV (HW);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;
      end if;


      if (       HW.PHY.phy_Type = E1000_PHY_82577
             and (   HW.PHY.Revision = 1
                  or HW.PHY.Revision = 2))
          or (    HW.PHY.phy_Type = E1000_PHY_82578
              and HW.PHY.Revision = 1)
      then
         -- Disable generation of early preamble.
         --
         Ret_Val := E1E_WPHY (HW,
                              PHY_REG (769, 25),
                              16#4431#);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;

         -- Preamble tuning for SSC.
         --
         Ret_Val := E1E_WPHY (HW,
                              HV_KMRN_FIFO_CTRLSTA,
                              16#A204#);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;
      end if;


      if HW.PHY.phy_Type = E1000_PHY_82578
      then
         -- Return registers to default by doing a soft reset then
         -- writing 0x3140 to the control register.
         --
         if HW.PHY.Revision < 2
         then
            Unused  := E1000E_PHY_SW_Reset (HW);
            Ret_Val := E1E_WPHY (HW, MII_BMCR, 16#3140#);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;
         end if;
      end if;


      -- Select page 0.
      --
      Ret_Val := HW.PHY.Ops.Acquire (HW);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      HW.PHY.Addr := 1;
      Ret_Val     := E1000E_Write_PHY_Reg_MDIC (HW, IGP01E1000_PHY_PAGE_SELECT, 0);
      HW.PHY.Ops.Release (HW);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- Configure the K1 Si workaround during phy reset assuming there is
      -- link so that it disables K1 if link is in 1Gbps.
      --
      Ret_Val := E1000_K1_Gig_Workaround_HV (HW, True);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- Workaround for link disconnects on a busy hub in half duplex.
      --
      Ret_Val := HW.PHY.Ops.Acquire (HW);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Ret_Val := E1E_RPHY_Locked (HW,
                                  BM_PORT_GEN_CFG,
                                  PHY_Data'unchecked_Access);
      if Ret_Val /= 0
      then
         goto Release;
      end if;


      Ret_Val := E1E_WPHY_Locked (HW,
                                  BM_PORT_GEN_CFG,
                                  PHY_Data and 16#00FF#);
      if Ret_Val /= 0
      then
         goto Release;
      end if;

      -- Set MSE higher to enable link to stay up when noise is high.
      --
      Ret_Val := E1000_Write_EMI_Reg_Locked (HW, I82577_MSE_THRESHOLD, 16#0034#);


      <<Release>>

      HW.PHY.Ops.Release (HW);
      return Ret_Val;
   end E1000_HV_PHY_Workarounds_ICH8LAN;




   --------------------------------------
   -- E1000_Lv_Phy_Workarounds_Ich8lan --
   --------------------------------------

   --  Apply ich8 specific workarounds.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  A series of PHY workarounds to be done after every PHY reset.


   function E1000_Lv_Phy_Workarounds_Ich8lan
     (Hw : access E1000_Hw) return s32
   is
      Ret_Val : s32 := 0;
   begin
      if Hw.Mac.mac_Type /= E1000_Pch2lan
      then
         return 0;
      end if;

      -- Set MDIO slow mode before any other MDIO access.
      --
      Ret_Val := E1000_Set_Mdio_Slow_Mode_Hv (Hw);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Ret_Val := Hw.Phy.Ops.Acquire (Hw);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- Set MSE higher to enable link to stay up when noise is high.
      --
      Ret_Val := E1000_Write_Emi_Reg_Locked (Hw, I82579_MSE_THRESHOLD, 16#0034#);

      if Ret_Val /= 0
      then
         goto Release;
      end if;


      -- Drop link after 5 times MSE threshold was reached.
      --
      Ret_Val := E1000_Write_Emi_Reg_Locked (Hw, I82579_MSE_LINK_DOWN, 16#0005#);


      <<Release>>

      Hw.Phy.Ops.Release (Hw);
      return Ret_Val;
   end E1000_Lv_Phy_Workarounds_Ich8lan;




   --  K1 Si workaround.
   --
   --  *  @hw:   Pointer to the HW structure.
   --  *
   --  *  Workaround to set the K1 beacon duration for 82579 parts in 10Mbps
   --  *  Disable K1 in 1000Mbps and 100Mbps

   function E1000_K1_Workaround_LV
     (HW : access E1000_HW) return s32
   is
      Ret_Val    :         s32         := 0;
      Status_Reg : aliased Unsigned_16 := 0;
      PM_PHY_Reg : aliased Unsigned_16;
      Mac_Reg    :         Unsigned_32;

   begin
      if HW.Mac.mac_type /= E1000_PCH2LAN
      then
         return 0;
      end if;

      -- Set K1 beacon duration based on 10Mbs speed.
      --
      Ret_Val := E1E_RPHY (HW,
                           HV_M_STATUS,
                           Status_Reg'unchecked_Access);
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      if  (Status_Reg and (   HV_M_STATUS_LINK_UP
                           or HV_M_STATUS_AUTONEG_COMPLETE))
        = (   HV_M_STATUS_LINK_UP
           or HV_M_STATUS_AUTONEG_COMPLETE)
      then
         if (Status_Reg and (   HV_M_STATUS_SPEED_1000
                             or HV_M_STATUS_SPEED_100)) /= 0
         then
            -- LV 1G/100 Packet drop issue wa.
            --
            Ret_Val := E1E_RPHY (HW,
                                 HV_PM_CTRL,
                                 PM_PHY_Reg'unchecked_Access);
            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;


            PM_PHY_Reg := PM_PHY_Reg and (not HV_PM_CTRL_K1_ENABLE);
            Ret_Val    := E1E_WPHY (HW,
                                    HV_PM_CTRL,
                                    PM_PHY_Reg);
            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;

         else
            Mac_Reg := ER32 (Hw.all, Devices.e1000e.Registers.E1000_FEXTNVM4);
            Mac_Reg := Mac_Reg and (not E1000_FEXTNVM4_BEACON_DURATION_MASK);
            Mac_Reg := Mac_Reg or E1000_FEXTNVM4_BEACON_DURATION_16USEC;

            EW32 (Hw.all,
                  Devices.e1000e.Registers.E1000_FEXTNVM4,
                  Mac_Reg);
         end if;
      end if;


      return Ret_Val;
   end E1000_K1_Workaround_LV;




   --  Sisable PHY config via hardware.
   --
   --  *  @hw:   Pointer to the HW structure.
   --  *  @gate: Boolean set to true to gate, false to ungate.
   --  *
   --  *  Gate/ungate the automatic PHY configuration via hardware; perform
   --  *  the configuration via software instead.


   procedure E1000_Gate_HW_PHY_Config_ICH8LAN
     (HW : access E1000_HW; Gate : Boolean)
   is
      Extcnf_Ctrl : aliased Unsigned_32;
   begin
      if HW.Mac.mac_Type < E1000_PCH2LAN
      then
         return;
      end if;

      Extcnf_Ctrl := ER32 (Hw.all, Devices.e1000e.Registers.E1000_EXTCNF_CTRL);

      if Gate
      then
         Extcnf_Ctrl := Extcnf_Ctrl or E1000_EXTCNF_CTRL_GATE_PHY_CFG;
      else
         Extcnf_Ctrl := Extcnf_Ctrl and (not E1000_EXTCNF_CTRL_GATE_PHY_CFG);
      end if;

      EW32 (Hw.all, Devices.e1000e.Registers.E1000_EXTCNF_CTRL, Extcnf_Ctrl);
   end E1000_Gate_HW_PHY_Config_ICH8LAN;





   ---------------------------------
   -- E1000_Lan_Init_Done_Ich8lan --
   ---------------------------------

   --  Check for PHY config completion.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Check the appropriate indication the MAC has finished configuring the
   --  *  PHY after a software reset.


   procedure E1000_Lan_Init_Done_Ich8lan
     (Hw : access E1000_Hw)
   is
      Data       : u32;
      Loop_Count : Integer := E1000_ICH8_LAN_INIT_TIMEOUT;

   begin
      -- Wait for basic configuration completes before proceeding.
      --
      loop
         Data := Er32 (Hw.all, Devices.e1000e.Registers.E1000_Status);
         Data := Data and E1000_STATUS_LAN_INIT_DONE;

         delay 0.00015;                                     -- Equivalent to usleep_range(100, 200).
         exit when Data /= 0 or else Loop_Count = 0;

         Loop_Count := Loop_Count - 1;
      end loop;

      -- If basic configuration is incomplete before the above loop
      -- count reaches 0, loading the configuration from NVM will
      -- leave the PHY in a bad state possibly resulting in no link.
      --
      if Loop_Count = 0
      then
         e_dbg ("LAN_INIT_DONE not set, increase timeout");
      end if;

      -- Clear the Init Done bit for the next init event.
      --
      Data := Er32 (Hw.all, Devices.e1000e.Registers.E1000_Status);
      Data := Data and (not E1000_STATUS_LAN_INIT_DONE);

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_Status, Data);
   end E1000_Lan_Init_Done_Ich8lan;




   ----------------------------------
   -- E1000_Post_Phy_Reset_Ich8lan --
   ----------------------------------

   --  Perform steps required after a PHY reset.
   --
   --  *  @hw: Pointer to the HW structure.


   function E1000_Post_Phy_Reset_Ich8lan
     (Hw : access E1000_Hw) return s32
   is
      Unused  :         s32;
      Ret_Val :         s32        := 0;
      Reg     : aliased Unsigned_16;

   begin
      if Hw.Phy.Ops.Check_Reset_Block (Hw) /= 0
      then
         return 0;
      end if;


      -- Allow time for h/w to get to quiescent state after reset.
      --
      delay 0.01;

      -- Perform any necessary post-reset workarounds.
      --
      case Hw.Mac.Mac_Type
      is
         when E1000_Pchlan =>
            Ret_Val := E1000_Hv_Phy_Workarounds_Ich8lan (Hw);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;

         when E1000_Pch2lan =>
            Ret_Val := E1000_Lv_Phy_Workarounds_Ich8lan (Hw);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;

         when others =>
            null;
      end case;


      -- Clear the host wakeup bit after lcd reset.
      --
      if Hw.Mac.Mac_Type >= E1000_Pchlan
      then
         Unused := E1e_Rphy (Hw,
                             BM_PORT_GEN_CFG,
                             Reg'unchecked_Access);
         Reg    := Reg and (not BM_WUC_HOST_WU_BIT);
         Unused := E1e_Wphy (Hw,
                             BM_PORT_GEN_CFG,
                             Reg);
      end if;

      -- Configure the LCD with the extended configuration region in NVM.
      --
      Ret_Val := E1000_Sw_Lcd_Config_Ich8lan (Hw);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- Configure the LCD with the OEM bits in NVM.
      --
      Ret_Val := E1000_Oem_Bits_Config_Ich8lan (Hw, True);

      if Hw.Mac.Mac_Type = E1000_Pch2lan
      then
         -- Ungate automatic PHY configuration on non-managed 82579.
         --
         if (    Er32 (Hw.all, Devices.e1000e.Registers.E1000_FWSM)
             and E1000_ICH_FWSM_FW_VALID) = 0
         then
            delay 0.01;
            E1000_Gate_Hw_Phy_Config_Ich8lan (Hw, False);
         end if;

         -- Set EEE LPI Update Timer to 200usec.
         --
         Ret_Val := Hw.Phy.Ops.Acquire (Hw);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;

         Ret_Val := E1000_Write_Emi_Reg_Locked (Hw,
                                                I82579_LPI_UPDATE_TIMER,
                                                16#1387#);
         Hw.Phy.Ops.Release (Hw);
      end if;


      return Ret_Val;
   end E1000_Post_Phy_Reset_Ich8lan;



   --------------------------------
   -- E1000_Phy_Hw_Reset_Ich8lan --
   --------------------------------

   --  Performs a PHY reset.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Resets the PHY
   --  *  This is a function pointer entry point called by drivers
   --  *  or other shared routines.


   function E1000_Phy_Hw_Reset_Ich8lan
     (Hw : access E1000_Hw) return s32
   is
      Ret_Val : s32 := 0;
   begin
      -- Gate automatic PHY configuration by hardware on non-managed 82579.
      --
      if         Hw.Mac.Mac_Type = E1000_Pch2lan
        and then (Er32 (Hw.all, Devices.e1000e.Registers.E1000_FWSM) and E1000_ICH_FWSM_FW_VALID) = 0
      then
         E1000_Gate_Hw_Phy_Config_Ich8lan (Hw, True);
      end if;

      Ret_Val := E1000e_Phy_Hw_Reset_Generic (Hw);

      if Ret_Val /= 0 then
         return Ret_Val;
      end if;

      return E1000_Post_Phy_Reset_Ich8lan (Hw);
   end E1000_Phy_Hw_Reset_Ich8lan;




   ---------------------------------
   -- E1000_Set_LPLU_State_PCHLAN --
   ---------------------------------

   --  Set Low Power Link Up state.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @active: True to enable LPLU, false to disable.
   --  *
   --  *  Sets the LPLU state according to the active flag.  For PCH, if OEM write
   --  *  bit are disabled in the NVM, writing the LPLU bits in the MAC will not set
   --  *  the phy speed. This function will manually set the LPLU bit and restart
   --  *  auto-neg as hw would do. D3 and D0 LPLU will call the same function
   --  *  since it configures the same bit.


   function E1000_Set_LPLU_State_PCHLAN
     (HW     : access E1000_HW;
      Active : in     Boolean) return s32
   is
      Ret_Val :         s32;
      OEM_Reg : aliased Unsigned_16;
   begin
      Ret_Val := E1e_Rphy (HW, HV_OEM_BITS, OEM_Reg'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      if Active
      then
         OEM_Reg := OEM_Reg or HV_OEM_BITS_LPLU;
      else
         OEM_Reg := OEM_Reg and (not HV_OEM_BITS_LPLU);
      end if;

      if HW.Phy.Ops.Check_Reset_Block (HW) = 0
      then
         OEM_Reg := OEM_Reg or HV_OEM_BITS_RESTART_AN;
      end if;


      return E1e_Wphy (HW, HV_OEM_BITS, OEM_Reg);
   end E1000_Set_LPLU_State_PCHLAN;




   -------------------------------------
   -- E1000_Set_D0_LPLU_State_ICH8LAN --
   -------------------------------------

   --  Set Low Power Linkup D0 state.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @active: True to enable LPLU, false to disable.
   --  *
   --  *  Sets the LPLU D0 state according to the active flag.  When
   --  *  activating LPLU this function also disables smart speed
   --  *  and vice versa.  LPLU will not be activated unless the
   --  *  device autonegotiation advertisement meets standards of
   --  *  either 10 or 10/100 or 10/100/1000 at all duplexes.
   --  *  This is a function pointer entry point only called by
   --  *  PHY setup routines.


   function E1000_Set_D0_LPLU_State_ICH8LAN
     (HW     : access E1000_HW;
      Active : in     Boolean) return s32
   is
      PHY      :         E1000_PHY_Info.item renames HW.PHY;
      PHY_Ctrl :         Unsigned_32;
      Ret_Val  :         s32        := 0;
      Data     : aliased Unsigned_16;

   begin
      if PHY.phy_type = E1000_PHY_IFE
      then
         return 0;
      end if;


      PHY_Ctrl := ER32 (Hw.all, Devices.e1000e.Registers.E1000_PHY_CTRL);

      if Active
      then
         PHY_Ctrl := PHY_Ctrl or E1000_PHY_CTRL_D0A_LPLU;
         EW32 (Hw.all, Devices.e1000e.Registers.E1000_PHY_CTRL, PHY_Ctrl);

         if PHY.phy_type /= E1000_PHY_IGP_3
         then
            return 0;
         end if;


         -- Call gig speed drop workaround on LPLU before accessing
         -- any PHY registers.
         --
         if HW.MAC.mac_type = E1000_ICH8LAN
         then
            E1000E_Gig_Downshift_Workaround_ICH8LAN (HW);
         end if;

         -- When LPLU is enabled, we should disable SmartSpeed.
         --
         Ret_Val := E1E_RPHY (HW, IGP01E1000_PHY_PORT_CONFIG, Data'unchecked_Access);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Data    := Data and (not IGP01E1000_PSCFR_SMART_SPEED);
         Ret_Val := E1E_WPHY (HW, IGP01E1000_PHY_PORT_CONFIG, Data);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;

      else
         PHY_Ctrl := PHY_Ctrl and (not E1000_PHY_CTRL_D0A_LPLU);
         EW32 (Hw.all, Devices.e1000e.Registers.E1000_PHY_CTRL, PHY_Ctrl);

         if PHY.phy_type /= E1000_PHY_IGP_3
         then
            return 0;
         end if;


         -- LPLU and SmartSpeed are mutually exclusive. LPLU is used
         -- during Dx states where the power conservation is most
         -- important. During driver activity we should enable
         -- SmartSpeed, so performance is maintained.
         --
         if PHY.Smart_Speed = E1000_Smart_Speed_On
         then
            Ret_Val := E1E_RPHY (HW, IGP01E1000_PHY_PORT_CONFIG, Data'unchecked_Access);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;

            Data    := Data or IGP01E1000_PSCFR_SMART_SPEED;
            Ret_Val := E1E_WPHY (HW, IGP01E1000_PHY_PORT_CONFIG, Data);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;

         elsif PHY.Smart_Speed = E1000_Smart_Speed_Off
         then
            Ret_Val := E1E_RPHY (HW, IGP01E1000_PHY_PORT_CONFIG, Data'unchecked_Access);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;

            Data    := Data and (not IGP01E1000_PSCFR_SMART_SPEED);
            Ret_Val := E1E_WPHY (HW, IGP01E1000_PHY_PORT_CONFIG, Data);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;

         end if;
      end if;


      return 0;
   end E1000_Set_D0_LPLU_State_ICH8LAN;




   -------------------------------------
   -- E1000_Set_D3_LPLU_State_ICH8LAN --
   -------------------------------------

   --  Set Low Power Linkup D3 state.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @active: Rrue to enable LPLU, false to disable.
   --  *
   --  *  Sets the LPLU D3 state according to the active flag.  When
   --  *  activating LPLU this function also disables smart speed
   --  *  and vice versa.  LPLU will not be activated unless the
   --  *  device autonegotiation advertisement meets standards of
   --  *  either 10 or 10/100 or 10/100/1000 at all duplexes.
   --  *  This is a function pointer entry point only called by
   --  *  PHY setup routines.


   function E1000_Set_D3_LPLU_State_ICH8LAN
     (HW     : access E1000_HW;
      Active : in     Boolean) return s32
   is
      PHY      :         E1000_PHY_Info.item renames HW.PHY;
      PHY_Ctrl :         Unsigned_32;
      Ret_Val  :         s32        := 0;
      Data     : aliased Unsigned_16;

   begin
      PHY_Ctrl := ER32 (HW.all, Devices.e1000e.Registers.E1000_PHY_CTRL);

      if not Active
      then
         PHY_Ctrl := PHY_Ctrl and (not E1000_PHY_CTRL_NOND0A_LPLU);
         EW32 (HW.all, Devices.e1000e.Registers.E1000_PHY_CTRL, PHY_Ctrl);

         if PHY.PHY_Type /= E1000_PHY_IGP_3
         then
            return 0;
         end if;


         -- LPLU and SmartSpeed are mutually exclusive. LPLU is used
         -- during Dx states where the power conservation is most
         -- important. During driver activity we should enable
         -- SmartSpeed, so performance is maintained.
         --
         if PHY.Smart_Speed = E1000_Smart_Speed_On
         then
            Ret_Val := E1E_RPHY (HW, IGP01E1000_PHY_PORT_CONFIG, Data'unchecked_Access);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;


            Data    := Data or IGP01E1000_PSCFR_SMART_SPEED;
            Ret_Val := E1E_WPHY (HW, IGP01E1000_PHY_PORT_CONFIG, Data);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;

         elsif PHY.Smart_Speed = E1000_Smart_Speed_Off
         then
            Ret_Val := E1E_RPHY (HW, IGP01E1000_PHY_PORT_CONFIG, Data'unchecked_Access);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;


            Data    := Data and (not IGP01E1000_PSCFR_SMART_SPEED);
            Ret_Val := E1E_WPHY (HW, IGP01E1000_PHY_PORT_CONFIG, Data);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;
         end if;

      elsif     (PHY.Autoneg_Advertised = u16 (E1000_ALL_SPEED_DUPLEX))
            or  (PHY.Autoneg_Advertised = u16 (E1000_ALL_NOT_GIG))
            or  (PHY.Autoneg_Advertised = u16 (E1000_ALL_10_SPEED))
      then
         PHY_Ctrl := PHY_Ctrl or E1000_PHY_CTRL_NOND0A_LPLU;
         EW32 (HW.all, Devices.e1000e.Registers.E1000_PHY_CTRL, PHY_Ctrl);

         if PHY.PHY_Type /= E1000_PHY_IGP_3
         then
            return 0;
         end if;


         -- Call gig speed drop workaround on LPLU before accessing
         -- any PHY registers.
         --
         if HW.MAC.MAC_Type = E1000_ICH8LAN
         then
            E1000E_Gig_Downshift_Workaround_ICH8LAN (HW);
         end if;

         -- When LPLU is enabled, we should disable SmartSpeed.
         --
         Ret_Val := E1E_RPHY (HW, IGP01E1000_PHY_PORT_CONFIG, Data'unchecked_Access);

         if Ret_Val /= 0 then
            return Ret_Val;
         end if;


         Data    := Data and (not IGP01E1000_PSCFR_SMART_SPEED);
         Ret_Val := E1E_WPHY (HW, IGP01E1000_PHY_PORT_CONFIG, Data);
      end if;


      return Ret_Val;
   end E1000_Set_D3_LPLU_State_ICH8LAN;







   -----------------------------------------
   -- E1000_Valid_NVM_Bank_Detect_ICH8LAN --
   -----------------------------------------

   --  Finds out the valid bank 0 or 1.
   --
   --  *  @hw:    Pointer to the HW structure.
   --  *  @bank:  Pointer to the variable that returns the active bank.
   --  *
   --  *  Reads signature byte from the NVM using the flash access registers.
   --  *  Word 0x13 bits 15:14 = 10b indicate a valid signature for that bank.


   function E1000_Valid_NVM_Bank_Detect_ICH8LAN
     (HW   : access E1000_HW;
      Bank :    out Interfaces.Unsigned_32) return s32
   is
      NVM          : E1000_NVM_Info.item renames HW.NVM;
      Bank1_Offset : Unsigned_32 := NVM.Flash_Bank_Size * 2;
      Act_Offset   : Unsigned_32 := u32 (E1000_ICH_NVM_SIG_WORD * 2 + 1);
      NVM_Dword    : Unsigned_32 := 0;
      Sig_Byte     : Unsigned_8  := 0;
      EECD         : Unsigned_32;
      Ret_Val      : s32;

   begin
      case HW.MAC.Mac_Type
      is
         when E1000_PCH_SPT
            | E1000_PCH_CNP
            | E1000_PCH_TGP
            | E1000_PCH_ADP
            | E1000_PCH_MTP
            | E1000_PCH_LNP
            | E1000_PCH_PTP
            | E1000_PCH_NVP =>
            Bank1_Offset := NVM.Flash_Bank_Size;
            Act_Offset   := u32 (E1000_ICH_NVM_SIG_WORD);

            -- Set bank to 0 in case flash read fails.
            --
            Bank := 0;

            -- Check bank 0.
            --
            Ret_Val := E1000_Read_Flash_Dword_ICH8LAN (HW, Act_Offset, NVM_Dword);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;


            Sig_Byte := Interfaces.Unsigned_8 (Interfaces.Shift_Right (NVM_Dword and 16#FF00#, 8));

            if (C.unsigned (Sig_Byte) and E1000_ICH_NVM_VALID_SIG_MASK) = E1000_ICH_NVM_SIG_VALUE
            then
               Bank := 0;
               return 0;
            end if;


            -- Check bank 1.
            --
            Ret_Val := E1000_Read_Flash_Dword_ICH8LAN (HW, Act_Offset + Bank1_Offset, NVM_Dword);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;


            Sig_Byte := Interfaces.Unsigned_8 (Interfaces.Shift_Right (NVM_Dword and 16#FF00#, 8));

            if (C.unsigned (Sig_Byte) and E1000_ICH_NVM_VALID_SIG_MASK) = E1000_ICH_NVM_SIG_VALUE
            then
               Bank := 1;
               return 0;
            end if;


            e_dbg ("ERROR: No valid NVM bank present");
            return -E1000_ERR_NVM;

         when E1000_ICH8LAN
            | E1000_ICH9LAN =>
            EECD := ER32 (HW.all, Devices.e1000e.Registers.E1000_EECD);

            if (EECD and E1000_EECD_SEC1VAL_VALID_MASK) = E1000_EECD_SEC1VAL_VALID_MASK
            then
               if (EECD and E1000_EECD_SEC1VAL) /= 0
               then
                  Bank := 1;
               else
                  Bank := 0;
               end if;

               return 0;
            end if;

            e_dbg ("Unable to determine valid NVM bank via EEC - reading flash signature");

         when others =>
            null;
      end case;

      -- Set bank to 0 in case flash read fails.
      --
      Bank := 0;

      -- Check bank 0.
      --
      Ret_Val := E1000_Read_Flash_Byte_ICH8LAN (HW, Act_Offset, Sig_Byte);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      if (C.unsigned (Sig_Byte) and E1000_ICH_NVM_VALID_SIG_MASK) = E1000_ICH_NVM_SIG_VALUE
      then
         Bank := 0;
         return 0;
      end if;


      -- Check bank 1.
      --
      Ret_Val := E1000_Read_Flash_Byte_ICH8LAN (HW, Act_Offset + Bank1_Offset, Sig_Byte);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      if (C.unsigned (Sig_Byte) and E1000_ICH_NVM_VALID_SIG_MASK) = E1000_ICH_NVM_SIG_VALUE
      then
         Bank := 1;
         return 0;
      end if;


      e_dbg ("ERROR: No valid NVM bank present");
      return -E1000_ERR_NVM;
   end E1000_Valid_NVM_Bank_Detect_ICH8LAN;




   ------------------------
   -- E1000_Read_NVM_SPT --
   ------------------------

   --  NVM access for SPT.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: The offset (in bytes) of the word(s) to read.
   --  *  @words:  Size of data to read in words.
   --  *  @data:   Pointer to the word(s) to read at offset.
   --  *
   --  *  Reads a word(s) from the NVM.


   function E1000_Read_NVM_SPT
     (HW     : access E1000_HW;
      Offset : in     Unsigned_16;
      Words  : in     Unsigned_16;
      Data   : in     u16_Pointer) return s32
   is
      NVM            :          E1000_NVM_Info.item renames HW.NVM;
      Act_Offset     :          Unsigned_32;
      Ret_Val        :          s32         := 0;
      Bank           :          Unsigned_32 := 0;
      Dword          :          Unsigned_32 := 0;
      Offset_To_Read :          Unsigned_16;
      Unused         :          s32;
      Offset_Value   : constant C.size_t    := C.size_t (Offset);

      Data_array     : u16_array (0 .. C.size_t (Words) - 1)
        with
          Address => Data.all'Address;

   begin
      if   Offset >= NVM.Word_Size
        or Words  >  NVM.Word_Size - Offset
        or Words  =  0
      then
         e_dbg ("nvm parameter(s) out of bounds");
         return -E1000_ERR_NVM;
      end if;

      Unused := NVM.Ops.Acquire (HW);

      Ret_Val := E1000_Valid_NVM_Bank_Detect_ICH8LAN (HW, Bank);

      if Ret_Val /= 0
      then
         e_dbg ("Could not detect valid bank, assuming bank 0");
         Bank := 0;
      end if;

      Act_Offset := (if Bank /= 0 then NVM.Flash_Bank_Size else 0);
      Act_Offset := Act_Offset + Unsigned_32 (Offset);

      for I in Data_array'Range
      loop
         if I mod 2 = 0
         then
            if C.size_t (Words) - I = 1
            then
               if HW.Dev_Spec.ICH8LAN.Shadow_RAM (Offset_Value + I).Modified
               then
                  Data_array (I) := HW.Dev_Spec.ICH8LAN.Shadow_RAM (Offset_Value + I).Value;

               else
                  Offset_To_Read := Unsigned_16 (    Act_Offset + Unsigned_32 (I)
                                                 - ((Act_Offset + Unsigned_32 (I)) mod 2));

                  Ret_Val        := E1000_Read_Flash_Dword_ICH8LAN (HW,
                                                                    u32 (Offset_To_Read),
                                                                    Dword);
                  if Ret_Val /= 0
                  then
                     exit;
                  end if;

                  if (Act_Offset + Unsigned_32 (I)) mod 2 = 0
                  then
                     Data_array (I) := Unsigned_16 (Dword and 16#FFFF#);
                  else
                     Data_array (I) := Unsigned_16 (    shift_Right (Dword, 16)
                                                    and 16#FFFF#);
                  end if;
               end if;

            else
               Offset_To_Read := Unsigned_16 (Act_Offset + Unsigned_32 (I));

               if   not HW.Dev_Spec.ICH8LAN.Shadow_RAM (Offset_Value + I)    .Modified
                 or not HW.Dev_Spec.ICH8LAN.Shadow_RAM (Offset_Value + I + 1).Modified
               then
                  Ret_Val := E1000_Read_Flash_Dword_ICH8LAN (HW,
                                                             u32 (Offset_To_Read),
                                                             Dword);
                  if Ret_Val /= 0
                  then
                     exit;
                  end if;
               end if;


               if HW.Dev_Spec.ICH8LAN.Shadow_RAM (Offset_Value + I).Modified
               then
                  Data_array (I) := HW.Dev_Spec.ICH8LAN.Shadow_RAM (Offset_Value + I).Value;
               else
                  Data_array (I) := Unsigned_16 (Dword and 16#FFFF#);
               end if;


               if HW.Dev_Spec.ICH8LAN.Shadow_RAM (Offset_Value + I + 1).Modified
               then
                  Data_array (I + 1) := HW.Dev_Spec.ICH8LAN.Shadow_RAM (Offset_Value + I + 1).Value;
               else
                  Data_array (I + 1) := Unsigned_16 (shift_Right (Dword, 16) and 16#FFFF#);
               end if;

            end if;
         end if;
      end loop;


      NVM.Ops.Release (HW);

      if Ret_Val /= 0
      then
         e_dbg ("NVM read error:" & Ret_Val'Image);
      end if;

      return Ret_Val;
   end E1000_Read_NVM_SPT;




   ----------------------------
   -- E1000_Read_NVM_ICH8LAN --
   ----------------------------

   --  Read word(s) from the NVM.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: The offset (in bytes) of the word(s) to read.
   --  *  @words:  Size of data to read in words.
   --  *  @data:   Pointer to the word(s) to read at offset.
   --  *
   --  *  Reads a word(s) from the NVM using the flash access registers.


   function E1000_Read_NVM_ICH8LAN
     (HW      : access E1000_HW;
      Offset  : in     Unsigned_16;
      Words   : in     Unsigned_16;
      Data    : in     u16_Pointer) return s32
   is
      NVM          :          E1000_NVM_Info.item renames HW.NVM;
      Act_Offset   :          Unsigned_32;
      Ret_Val      :          s32         := 0;
      Bank         :          Unsigned_32 := 0;
      Word         :          Unsigned_16;
      Offset_Value : constant C.size_t    := C.size_t (Offset);
      Unused       :          s32;

      Data_array   : u16_array (0 .. C.size_t (Words) - 1)
        with
          Address => Data.all'Address;

   begin
      if   Offset >= NVM.Word_Size
        or Words  >  NVM.Word_Size - Offset
        or Words  =  0
      then
         e_dbg ("nvm parameter(s) out of bounds");
         Ret_Val := -E1000_ERR_NVM;
         goto Done;
      end if;


      Unused  := NVM.Ops.Acquire (HW);
      Ret_Val := E1000_Valid_NVM_Bank_Detect_ICH8LAN (HW, Bank);

      if Ret_Val /= 0
      then
         e_dbg ("Could not detect valid bank, assuming bank 0");
         Bank := 0;
      end if;

      Act_Offset := (if Bank /= 0 then NVM.Flash_Bank_Size
                                  else 0);
      Act_Offset := Act_Offset + Unsigned_32 (Offset);
      Ret_Val    := 0;


      for I in 0 .. C.size_t (Words) - 1
      loop
         if HW.Dev_Spec.ICH8LAN.Shadow_Ram (Offset_Value + I).Modified
         then
            Data_array (I) := HW.Dev_Spec.ICH8LAN.Shadow_Ram (Offset_Value + I).Value;

         else
            Ret_Val := E1000_Read_Flash_Word_ICH8LAN (HW,
                                                      Act_Offset + Unsigned_32 (I),
                                                      Word);
            if Ret_Val /= 0
            then
               exit;
            end if;

            Data_array (I) := Word;
         end if;
      end loop;


      NVM.Ops.Release (HW);


      <<Done>>

      if Ret_Val /= 0
      then
         e_dbg ("NVM read error:" & Ret_Val'Image);
      end if;

      return Ret_Val;
   end E1000_Read_NVM_ICH8LAN;






   ------------------------------------
   -- E1000_Flash_Cycle_Init_Ich8lan --
   ------------------------------------

   --  Initialize flash.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  This function does initial flash setup so that a new read/write/erase cycle
   --  *  can be started.


   function E1000_Flash_Cycle_Init_Ich8lan
     (Hw : access E1000_Hw) return s32
   is
      Hsfsts  : Ich8_Hws_Flash_Status;
      Ret_Val : s32                  := -E1000_ERR_NVM;

   begin
      Hsfsts.Regval := Er16flash (Hw, ICH_FLASH_HSFSTS);

      -- Check if the flash descriptor is valid.
      --
      if not Hsfsts.Hsf_Status.Fldesvalid
      then
         e_dbg ("Flash descriptor invalid. SW Sequencing must be used.");
         return -E1000_ERR_NVM;
      end if;


      -- Clear FCERR and DAEL in hw status by writing 1.
      --
      Hsfsts.Hsf_Status.Flcerr := True;
      Hsfsts.Hsf_Status.Dael   := True;

      if Hw.Mac.Mac_Type >= E1000_Pch_Spt
      then
         Ew32flash (Hw, ICH_FLASH_HSFSTS, u32 (Hsfsts.Regval and 16#FFFF#));
      else
         Ew16flash (Hw, ICH_FLASH_HSFSTS, Hsfsts.Regval);
      end if;

      if not Hsfsts.Hsf_Status.Flcinprog
      then
         -- There is no cycle running at present, so we can start a cycle.
         -- Begin by setting Flash Cycle Done.
         --
         Hsfsts.Hsf_Status.Flcdone := True;

         if Hw.Mac.Mac_Type >= E1000_Pch_Spt
         then
            Ew32flash (Hw, ICH_FLASH_HSFSTS, u32 (Hsfsts.Regval and 16#FFFF#));
         else
            Ew16flash (Hw, ICH_FLASH_HSFSTS, Hsfsts.Regval);
         end if;

         Ret_Val := 0;

      else
         -- Otherwise poll for sometime so the current cycle has a chance to end before giving up.
         --
         for I in 1 .. ICH_FLASH_READ_COMMAND_TIMEOUT
         loop
            Hsfsts.Regval := Er16flash (Hw, ICH_FLASH_HSFSTS);

            if not Hsfsts.Hsf_Status.Flcinprog
            then
               Ret_Val := 0;
               exit;
            end if;

            delay 0.000001;     -- Equivalent to udelay(1)
         end loop;


         if Ret_Val = 0
         then
            -- Successful in waiting for previous cycle to timeout,
            -- now set the Flash Cycle Done.
            --
            Hsfsts.Hsf_Status.Flcdone := True;

            if Hw.Mac.Mac_Type >= E1000_Pch_Spt
            then
               Ew32flash (Hw, ICH_FLASH_HSFSTS, u32 (Hsfsts.Regval and 16#FFFF#));
            else
               Ew16flash (Hw, ICH_FLASH_HSFSTS, Hsfsts.Regval);
            end if;

         else
            e_dbg ("Flash controller busy, cannot get access");
         end if;
      end if;


      return Ret_Val;
   end E1000_Flash_Cycle_Init_Ich8lan;




   -------------------------------
   -- E1000_Flash_Cycle_Ich8lan --
   -------------------------------

   function E1000_Flash_Cycle_Ich8lan
     (Hw      : access E1000_Hw;
      Timeout : in     Unsigned_32) return s32
   is
      Hsflctl : Ich8_Hws_Flash_Ctrl;
      Hsfsts  : Ich8_Hws_Flash_Status;
      I       : Unsigned_32          := 0;

   begin
      -- Start a cycle by writing 1 in Flash Cycle Go in Hw Flash Control.
      --
      if Hw.Mac.mac_type >= E1000_Pch_Spt
      then
         Hsflctl.REGVAL := u16 (shift_Right (Er32flash (Hw, ICH_FLASH_HSFSTS),
                                             16));
      else
         Hsflctl.REGVAL := Er16flash (Hw, ICH_FLASH_HSFCTL);
      end if;

      Hsflctl.Hsf_Ctrl.Flcgo := 1;

      if Hw.Mac.mac_type >= E1000_Pch_Spt
      then
         Ew32flash (Hw, ICH_FLASH_HSFSTS, shift_Left (u32 (Hsflctl.REGVAL),
                                                      16));
      else
         Ew16flash (Hw, ICH_FLASH_HSFCTL, Hsflctl.REGVAL);
      end if;

      -- Wait till FDONE bit is set to 1.
      --
      loop
         Hsfsts.REGVAL := Er16flash (Hw, ICH_FLASH_HSFSTS);
         exit when Hsfsts.Hsf_Status.Flcdone;

         delay 0.00_000_1;                             -- Equivalent to udelay(1).

         I := I + 1;
         exit when I >= Timeout;
      end loop;

      if        Hsfsts.Hsf_Status.Flcdone
        and not Hsfsts.Hsf_Status.Flcerr
      then
         return 0;
      end if;


      return -E1000_ERR_NVM;
   end E1000_Flash_Cycle_Ich8lan;




   ------------------------------------
   -- E1000_Read_Flash_Dword_Ich8lan --
   ------------------------------------

   --  Read dword from flash.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Offset to data location.
   --  *  @data:   Pointer to the location for storing the data.
   --  *
   --  *  Reads the flash dword at offset into data.  Offset is converted
   --  *  to bytes before read.


   function E1000_Read_Flash_Dword_Ich8lan
     (HW     : access E1000_HW;
      Offset : in     Unsigned_32;
      Data   :    out Unsigned_32) return s32
   is
      Byte_Offset : constant Unsigned_32 := Shift_Left(Offset, 1);     -- Must convert word offset into bytes.
   begin
      return E1000_Read_Flash_Data32_Ich8lan (HW, Byte_Offset, Data);
   end E1000_Read_Flash_Dword_Ich8lan;




   -----------------------------------
   -- E1000_Read_Flash_Word_Ich8lan --
   -----------------------------------

   --  Read word from flash.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Offset to data location.
   --  *  @data:   Pointer to the location for storing the data.
   --  *
   --  *  Reads the flash word at offset into data.  Offset is converted
   --  *  to bytes before read.


   function E1000_Read_Flash_Word_Ich8lan
     (Hw     : access E1000_Hw;
      Offset : in     Unsigned_32;
      Data   :    out Unsigned_16) return s32
   is
      Byte_Offset : constant Unsigned_32 := Shift_Left(Offset, 1);     -- Must convert offset into bytes.
   begin
      return E1000_Read_Flash_Data_Ich8lan (Hw, Byte_Offset, 2, Data);
   end E1000_Read_Flash_Word_Ich8lan;




   -----------------------------------
   -- E1000_Read_Flash_Byte_Ich8lan --
   -----------------------------------

   --  Read byte from flash.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: The offset of the byte to read.
   --  *  @data:   Pointer to a byte to store the value read.
   --  *
   --  *  Reads a single byte from the NVM using the flash access registers.


   function E1000_Read_Flash_Byte_Ich8lan
     (HW     : access E1000_HW;
      Offset : in     Interfaces.Unsigned_32;
      Data   :    out Unsigned_8) return s32
   is
      Ret_Val : s32;
      Word    : Unsigned_16 := 0;

   begin
      -- In SPT, only 32 bits access is supported,
      -- so this function should not be called.
      --
      if HW.Mac.Mac_Type >= E1000_Pch_Spt
      then
         return -E1000_ERR_NVM;
      else
         Ret_Val := E1000_Read_Flash_Data_Ich8lan (HW     => HW,
                                                   Offset => Offset,
                                                   Size   => 1,
                                                   Data   => Word);
      end if;

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Data := Unsigned_8 (Word and 16#FF#);

      return 0;
   end E1000_Read_Flash_Byte_Ich8lan;





   -----------------------------------
   -- E1000_Read_Flash_Data_Ich8lan --
   -----------------------------------
   function E1000_Read_Flash_Data_Ich8lan
     (Hw     : access E1000_Hw;
      Offset : in     Unsigned_32;
      Size   : in     Unsigned_8;
      Data   :    out Unsigned_16) return s32
   is
      Hsfsts            : Ich8_Hws_Flash_Status;
      Hsflctl           : Ich8_Hws_Flash_Ctrl;
      Flash_Linear_Addr : Unsigned_32;
      Flash_Data        : Unsigned_32 := 0;
      Ret_Val           : s32         := -E1000_ERR_NVM;
      Count             : Unsigned_8  := 0;
   begin
      if Size < 1 or Size > 2 or Offset > ICH_FLASH_LINEAR_ADDR_MASK
      then
         return -E1000_ERR_NVM;
      end if;

      Flash_Linear_Addr := ((ICH_FLASH_LINEAR_ADDR_MASK and Offset) +
                              Hw.Nvm.Flash_Base_Addr);

      loop
         delay 0.00_000_1;  -- 1 microsecond delay.

         -- Steps.
         --
         Ret_Val := E1000_Flash_Cycle_Init_Ich8lan (Hw);
         exit when Ret_Val /= 0;

         Hsflctl.Regval := Er16flash (Hw, ICH_FLASH_HSFCTL);

         -- 0b/1b corresponds to 1 or 2 byte size, respectively.
         --
         Hsflctl.Hsf_Ctrl.Fldbcount := u16 (Size) - 1;
         Hsflctl.Hsf_Ctrl.Flcycle   := ICH_CYCLE_READ;

         Ew16flash (Hw, ICH_FLASH_HSFCTL, Hsflctl.Regval);
         Ew32flash (Hw, ICH_FLASH_FADDR,  Flash_Linear_Addr);

         Ret_Val := E1000_Flash_Cycle_Ich8lan (Hw, ICH_FLASH_READ_COMMAND_TIMEOUT);

         -- Check if FCERR is set to 1, if set to 1, clear it
         -- and try the whole sequence a few more times, else
         -- read in (shift in) the Flash Data0, the order is
         -- least significant byte first msb to lsb.
         --
         if Ret_Val = 0
         then
            Flash_Data := Er32flash (Hw, ICH_FLASH_FDATA0);

            if Size = 1
            then
               Data := Unsigned_16 (Flash_Data and 16#000000FF#);
            elsif Size = 2
            then
               Data := Unsigned_16 (Flash_Data and 16#0000FFFF#);
            end if;

            exit;

         else
            -- If we've gotten here, then things are probably
            -- completely hosed, but if the error condition is
            -- detected, it won't hurt to give it another try...
            -- ICH_FLASH_CYCLE_REPEAT_COUNT times.
            --
            Hsfsts.Regval := Er16flash (Hw, ICH_FLASH_HSFSTS);

            if Hsfsts.Hsf_Status.Flcerr
            then
               -- Repeat for some time before giving up.
               --
               null;

            elsif not Hsfsts.Hsf_Status.Flcdone
            then
               E_Dbg ("Timeout error - flash cycle did not complete.");
               exit;
            end if;
         end if;

         exit when Count >= ICH_FLASH_CYCLE_REPEAT_COUNT;
         Count := Count + 1;
      end loop;


      return Ret_Val;
   end E1000_Read_Flash_Data_Ich8lan;





   -------------------------------------
   -- E1000_Read_Flash_Data32_Ich8lan --
   -------------------------------------

   --  Read dword from NVM.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: The offset (in bytes) of the dword to read.
   --  *  @data:   Pointer to the dword to store the value read.
   --  *
   --  *  Reads a byte or word from the NVM using the flash access registers.


   function E1000_Read_Flash_Data32_Ich8lan
     (Hw     : access E1000_Hw;
      Offset : in     Unsigned_32;
      Data   :    out Unsigned_32) return s32
   is
      Hsfsts            : Ich8_Hws_Flash_Status;
      Hsflctl           : Ich8_Hws_Flash_Ctrl;
      Flash_Linear_Addr : Unsigned_32;
      Ret_Val           : s32        := -E1000_ERR_NVM;
      Count             : Natural    := 0;

   begin
      if        Offset          > ICH_FLASH_LINEAR_ADDR_MASK
        or else Hw.Mac.mac_type < E1000_Pch_Spt
      then
         return -E1000_ERR_NVM;
      end if;

      Flash_Linear_Addr := (ICH_FLASH_LINEAR_ADDR_MASK and Offset) + Hw.Nvm.Flash_Base_Addr;


      loop
         delay 0.00_000_1;  -- 1 microsecond delay.

         -- Steps.
         --
         Ret_Val := E1000_Flash_Cycle_Init_Ich8lan (Hw);
         exit when Ret_Val /= 0;

         -- In SPT, this register is in Lan memory space, not flash.
         -- Therefore, only 32 bit access is supported.
         --
         Hsflctl.Regval := shift_Right (u16 (Er32flash (Hw, ICH_FLASH_HSFSTS)),
                                        16);

         -- 0b/1b corresponds to 1 or 2 byte size, respectively.
         --
         Hsflctl.Hsf_Ctrl.Fldbcount := Unsigned_32'Size / 8 - 1;
         Hsflctl.Hsf_Ctrl.Flcycle   := ICH_CYCLE_READ;

         -- In SPT, This register is in Lan memory space, not flash.
         -- Therefore, only 32 bit access is supported.
         --
         Ew32flash (Hw,
                    ICH_FLASH_HSFSTS,
                    shift_Left (Unsigned_32 (Hsflctl.Regval),
                                16));
         Ew32flash (Hw,
                    ICH_FLASH_FADDR,  Flash_Linear_Addr);

         Ret_Val := E1000_Flash_Cycle_Ich8lan (Hw, ICH_FLASH_READ_COMMAND_TIMEOUT);

         -- Check if FCERR is set to 1, if set to 1, clear it
         -- and try the whole sequence a few more times, else
         -- read in (shift in) the Flash Data0, the order is
         -- least significant byte first msb to lsb.
         --
         if Ret_Val = 0
         then
            Data := Er32flash (Hw, ICH_FLASH_FDATA0);
            exit;
         else
            -- If we've gotten here, then things are probably
            -- completely hosed, but if the error condition is
            -- detected, it won't hurt to give it another try...
            -- ICH_FLASH_CYCLE_REPEAT_COUNT times.
            --
            Hsfsts.Regval := Er16flash (Hw, ICH_FLASH_HSFSTS);

            if Hsfsts.Hsf_Status.Flcerr
            then
               null;     -- Repeat for some time before giving up.

            elsif not Hsfsts.Hsf_Status.Flcdone
            then
               E_Dbg ("Timeout error - flash cycle did not complete.");
               exit;
            end if;
         end if;

         exit when Count >= ICH_FLASH_CYCLE_REPEAT_COUNT;
         Count := Count + 1;
      end loop;

      return Ret_Val;
   end E1000_Read_Flash_Data32_Ich8lan;




   -----------------------------
   -- E1000_Write_NVM_ICH8LAN --
   -----------------------------

   --  Write word(s) to the NVM.
   --
   --  *  @hw: pointer to the HW structure
   --  *  @offset: The offset (in bytes) of the word(s) to write.
   --  *  @words: Size of data to write in words
   --  *  @data: Pointer to the word(s) to write at offset.
   --  *
   --  *  Writes a byte or word to the NVM using the flash access registers.


   function E1000_Write_NVM_ICH8LAN
     (HW     : access E1000_HW;
      Offset : in     Unsigned_16;
      Words  : in     Unsigned_16;
      Data   : in     u16_Pointer) return s32
   is
      NVM    : E1000_NVM_Info.item renames HW.NVM;
      Unused : s32;
      Buffer : u16_array (0 .. C.size_t (Words) - 1)
        with
          Address => Data.all'Address;

   begin
      if        Offset >= NVM.Word_Size
        or else Words  > NVM.Word_Size - Offset
        or else Words  = 0
      then
         e_dbg ("nvm parameter(s) out of bounds");
         return -E1000_ERR_NVM;
      end if;

      Unused := NVM.Ops.Acquire (HW);

      for I in 0 .. c.Size_t (Words) - 1
      loop
         HW.Dev_Spec.ICH8LAN.Shadow_RAM (C.size_t (Offset) + I).Modified := True;
         HW.Dev_Spec.ICH8LAN.Shadow_RAM (C.size_t (Offset) + I).Value    := Buffer (I);
      end loop;

      NVM.Ops.Release (HW);

      return 0;
   end E1000_Write_NVM_ICH8LAN;





   -----------------------------------
   -- E1000_Update_NVM_Checksum_SPT --
   -----------------------------------

   --  Update the checksum for NVM.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  The NVM checksum is updated by calling the generic update_nvm_checksum,
   --  *  which writes the checksum to the shadow ram.  The changes in the shadow
   --  *  ram are then committed to the EEPROM by processing each bank at a time
   --  *  checking for the modified bit and writing only the pending changes.
   --  *  After a successful commit, the shadow ram is cleared and is ready for
   --  *  future writes.


   function E1000_Update_NVM_Checksum_SPT
     (HW : access E1000_HW) return s32
   is
      use Devices.e1000e.Non_Volatile_Memory;

      NVM             : E1000_NVM_Info.item renames HW.NVM;
      Act_Offset,
      New_Bank_Offset,
      Old_Bank_Offset : Unsigned_32;
      Bank            : Unsigned_32;
      Ret_Val         : s32;
      Dword           : Unsigned_32 := 0;
      Unused          : s32;

   begin
      Ret_Val := E1000e_Update_NVM_Checksum_Generic (HW);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      if NVM.NVM_Type /= E1000_NVM_Flash_SW
      then
         return Ret_Val;
      end if;


      Unused := NVM.Ops.Acquire (HW);

      -- We're writing to the opposite bank so if we're on bank 1,
      -- write to bank 0 etc.  We also need to erase the segment that
      -- is going to be written.
      --
      Ret_Val := E1000_Valid_NVM_Bank_Detect_ICH8LAN (HW, Bank);

      if Ret_Val /= 0
      then
         e_dbg ("Could not detect valid bank, assuming bank 0");
         Bank := 0;
      end if;

      if Bank = 0
      then
         New_Bank_Offset := NVM.Flash_Bank_Size;
         Old_Bank_Offset := 0;
         Ret_Val         := E1000_Erase_Flash_Bank_ICH8LAN (HW, 1);

         if Ret_Val /= 0
         then
            goto Release;
         end if;

      else
         Old_Bank_Offset := NVM.Flash_Bank_Size;
         New_Bank_Offset := 0;
         Ret_Val         := E1000_Erase_Flash_Bank_ICH8LAN (HW, 0);

         if Ret_Val /= 0
         then
            goto Release;
         end if;
      end if;


      for I in 0 .. C.size_t (E1000_ICH8_SHADOW_RAM_WORDS) - 1
      loop
         exit when I mod 2 /= 0;

         -- Determine whether to write the value stored
         -- in the other NVM bank or a modified value stored
         -- in the shadow RAM.
         --
         Ret_Val := E1000_Read_Flash_Dword_ICH8LAN (HW,
                                                    u32 (I) + Old_Bank_Offset,
                                                    Dword);

         if HW.Dev_Spec.ICH8LAN.Shadow_RAM (I).Modified
         then
            Dword :=    (Dword and 16#FFFF0000#)
                     or u32 (HW.Dev_Spec.ICH8LAN.Shadow_RAM (I).Value and 16#FFFF#);
         end if;

         if HW.Dev_Spec.ICH8LAN.Shadow_RAM (I + 1).Modified
         then
            Dword :=    (Dword and 16#0000FFFF#)
                     or shift_Left (Unsigned_32 (    HW.Dev_Spec.ICH8LAN.Shadow_RAM (I + 1).Value
                                                 and 16#FFFF#),
                                    16);
         end if;

         if Ret_Val /= 0
         then
            exit;
         end if;

         -- If the word is 0x13, then make sure the signature bits
         -- (15:14) are 11b until the commit has completed.
         -- This will allow us to write 10b which indicates the
         -- signature is valid.  We want to do this after the write
         -- has completed so that we don't mark the segment valid
         -- while the write is still in progress.
         --
         if I = C.size_t (E1000_ICH_NVM_SIG_WORD) - 1
         then
            Dword := Dword or shift_Left (u32 (E1000_ICH_NVM_SIG_MASK),
                                          16);
         end if;

         -- Convert offset to bytes.
         --
         Act_Offset := shift_Left (u32 (I) + New_Bank_Offset,                   -- TODO: 'Act_Offset' is overwritten after the delay. Why ?
                                   1);
         delay 0.00_015;

         -- Write the data to the new bank. Offset in words.
         --
         Act_Offset := u32 (I) + New_Bank_Offset;
         Ret_Val    := E1000_Retry_Write_Flash_Dword_ICH8LAN (HW, Act_Offset, Dword);

         if Ret_Val /= 0
         then
            exit;
         end if;
      end loop;


      -- Don't bother writing the segment valid bits if sector
      -- programming failed.
      --
      if Ret_Val /= 0
      then
         -- Possibly read-only, see 'e1000e_write_protect_nvm_ich8lan'.
         --
         e_dbg ("Flash commit failed.");
         goto Release;
      end if;


      -- Finally validate the new segment by setting bit 15:14
      -- to 10b in word 0x13 , this can be done without an
      -- erase as well since these bits are 11 to start with
      -- and we need to change bit 14 to 0b.
      --
      Act_Offset := New_Bank_Offset + u32 (E1000_ICH_NVM_SIG_WORD);

      -- Offset in words but we read dword.
      --
      Act_Offset := Act_Offset - 1;
      Ret_Val    := E1000_Read_Flash_Dword_ICH8LAN (HW, Act_Offset, Dword);

      if Ret_Val /= 0
      then
         goto Release;
      end if;

      Dword   := Dword and 16#BFFFFFFF#;
      Ret_Val := E1000_Retry_Write_Flash_Dword_ICH8LAN (HW, Act_Offset, Dword);

      if Ret_Val /= 0
      then
         goto Release;
      end if;

      -- Offset in words but we read dword.
      --
      Act_Offset := Old_Bank_Offset + u32 (E1000_ICH_NVM_SIG_WORD) - 1;
      Ret_Val    := E1000_Read_Flash_Dword_ICH8LAN (HW, Act_Offset, Dword);

      if Ret_Val /= 0
      then
         goto Release;
      end if;

      Dword   := Dword and 16#00FFFFFF#;
      Ret_Val := E1000_Retry_Write_Flash_Dword_ICH8LAN (HW, Act_Offset, Dword);

      if Ret_Val /= 0
      then
         goto Release;
      end if;

      -- Great!  Everything worked, we can now clear the cached entries.
      --
      for I in 0 .. C.size_t (E1000_ICH8_SHADOW_RAM_WORDS) - 1
      loop
         HW.Dev_Spec.ICH8LAN.Shadow_RAM (I).Modified := False;
         HW.Dev_Spec.ICH8LAN.Shadow_RAM (I).Value    := 16#FFFF#;
      end loop;


      <<Release>>

      NVM.Ops.Release (HW);

      -- Reload the EEPROM, or else modifications will not appear
      -- until after the next adapter reset.
      --
      if Ret_Val = 0
      then
         NVM.Ops.Reload (HW);
         delay 0.01;
      end if;

      if Ret_Val /= 0
      then
         e_dbg ("NVM update error: " & Integer'Image (Integer (Ret_Val)));
      end if;


      return Ret_Val;
   end E1000_Update_NVM_Checksum_SPT;





   ---------------------------------------
   -- E1000_Update_NVM_Checksum_ICH8LAN --
   ---------------------------------------

   --  Update the checksum for NVM.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  The NVM checksum is updated by calling the generic update_nvm_checksum,
   --  *  which writes the checksum to the shadow ram.  The changes in the shadow
   --  *  ram are then committed to the EEPROM by processing each bank at a time
   --  *  checking for the modified bit and writing only the pending changes.
   --  *  After a successful commit, the shadow ram is cleared and is ready for
   --  *  future writes.


   function E1000_Update_NVM_Checksum_ICH8LAN (HW : access E1000_HW) return s32
   is
      use Devices.e1000e.Non_Volatile_Memory;

      NVM             : E1000_NVM_Info.item renames HW.NVM;
      --  Dev_Spec : E1000_Dev_Spec_ICH8LAN renames HW.Dev_Spec.ICH8LAN;
      Act_Offset,
      New_Bank_Offset,
      Old_Bank_Offset : Unsigned_32;
      Bank            : Unsigned_32;
      Ret_Val         : s32;
      Data            : Unsigned_16 := 0;
      Unused          : s32;

   begin
      Ret_Val := E1000E_Update_NVM_Checksum_Generic (HW);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      if NVM.NVM_Type /= E1000_NVM_Flash_SW
      then
         return 0;
      end if;


      Unused := NVM.Ops.Acquire (HW);

      Ret_Val := E1000_Valid_NVM_Bank_Detect_ICH8LAN (HW, Bank);

      if Ret_Val /= 0
      then
         e_dbg ("Could not detect valid bank, assuming bank 0");
         Bank := 0;
      end if;

      if Bank = 0
      then
         New_Bank_Offset := NVM.Flash_Bank_Size;
         Old_Bank_Offset := 0;
         Ret_Val         := E1000_Erase_Flash_Bank_ICH8LAN (HW, 1);

         if Ret_Val /= 0
         then
            goto Release;
         end if;

      else
         Old_Bank_Offset := NVM.Flash_Bank_Size;
         New_Bank_Offset := 0;
         Ret_Val         := E1000_Erase_Flash_Bank_ICH8LAN (HW, 0);

         if Ret_Val /= 0
         then
            goto Release;
         end if;
      end if;


      for I in 0 .. C.size_t (E1000_ICH8_SHADOW_RAM_WORDS - 1)
      loop
         if HW.Dev_Spec.ICH8LAN.Shadow_Ram (I).Modified
         then
            Data := HW.Dev_Spec.ICH8LAN.Shadow_Ram (I).Value;
         else
            Ret_Val := E1000_Read_Flash_Word_ICH8LAN (HW, u32 (I) + Old_Bank_Offset, Data);

            if Ret_Val /= 0
            then
               exit;
            end if;
         end if;


         if I = C.size_t (E1000_ICH_NVM_SIG_WORD)
         then
            Data := Data or u16 (E1000_ICH_NVM_SIG_MASK);
         end if;

         Act_Offset := (u32 (I) + New_Bank_Offset) * 2;

         delay 0.0001;
         Ret_Val := E1000_Retry_Write_Flash_Byte_ICH8LAN (HW, Act_Offset, Unsigned_8 (Data and 16#FF#));

         if Ret_Val /= 0
         then
            exit;
         end if;

         delay 0.0001;
         Ret_Val := E1000_Retry_Write_Flash_Byte_ICH8LAN (HW, Act_Offset + 1, Unsigned_8 (Shift_Right (Data, 8)));

         if Ret_Val /= 0
         then
            exit;
         end if;
      end loop;


      if Ret_Val /= 0
      then
         e_dbg ("Flash commit failed.");
         goto Release;
      end if;

      Act_Offset := New_Bank_Offset + u32 (E1000_ICH_NVM_SIG_WORD);
      Ret_Val    := E1000_Read_Flash_Word_ICH8LAN (HW, Act_Offset, Data);
      if Ret_Val /= 0 then
         goto Release;
      end if;

      Data    := Data and 16#BFFF#;
      Ret_Val := E1000_Retry_Write_Flash_Byte_ICH8LAN (HW, Act_Offset * 2 + 1, Unsigned_8 (Shift_Right (Data, 8)));

      if Ret_Val /= 0
      then
         goto Release;
      end if;

      Act_Offset := (Old_Bank_Offset + u32 (E1000_ICH_NVM_SIG_WORD)) * 2 + 1;
      Ret_Val    := E1000_Retry_Write_Flash_Byte_ICH8LAN (HW, Act_Offset, 0);

      if Ret_Val /= 0
      then
         goto Release;
      end if;

      for I in 0 .. C.size_t (E1000_ICH8_SHADOW_RAM_WORDS) - 1
      loop
         HW.Dev_Spec.ICH8LAN.Shadow_Ram (I).Modified := False;
         HW.Dev_Spec.ICH8LAN.Shadow_Ram (I).Value    := 16#FFFF#;
      end loop;


      <<Release>>

      NVM.Ops.Release (HW);

      if Ret_Val = 0
      then
         NVM.Ops.Reload (HW);
         delay 0.01;
      end if;

      if Ret_Val /= 0
      then
         e_dbg ("NVM update error: " & Ret_Val'Image);
      end if;


      return Ret_Val;
   end E1000_Update_NVM_Checksum_ICH8LAN;





   -----------------------------------------
   -- e1000_validate_nvm_checksum_ich8lan --
   -----------------------------------------

   --  Validate EEPROM checksum.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Check to see if checksum needs to be fixed by reading bit 6 in word 0x19.
   --  *  If the bit is 0, that the EEPROM had been modified, but the checksum was not
   --  *  calculated, in which case we need to calculate the checksum and set bit 6.


   function e1000_validate_nvm_checksum_ich8lan
     (hw : access e1000_hw) return s32
   is
      ret_val         :         s32;
      data            : aliased u16;
      word            :         u16;
      valid_csum_mask :         u16;
   begin
      -- Read NVM and check Invalid Image CSUM bit.  If this bit is 0,
      -- the checksum needs to be fixed.  This bit is an indication that
      -- the NVM was prepared by OEM software and did not calculate
      -- the checksum ... a likely scenario.
      --
      case hw.mac.Mac_Type
      is
         when e1000_pch_lpt
            | e1000_pch_spt
            | e1000_pch_cnp
            | e1000_pch_tgp
            | e1000_pch_adp
            | e1000_pch_mtp
            | e1000_pch_lnp
            | e1000_pch_ptp
            | e1000_pch_nvp =>

            word            := NVM_COMPAT;
            valid_csum_mask := NVM_COMPAT_VALID_CSUM;

         when others =>

            word            := NVM_FUTURE_INIT_WORD1;
            valid_csum_mask := NVM_FUTURE_INIT_WORD1_VALID_CSUM;
      end case;


      ret_val := e1000_read_nvm (Hw, word, 1, data'unchecked_Access);

      if ret_val /= 0
      then
         return ret_val;
      end if;


      if (data and valid_csum_mask) = 0
      then
         e_dbg ("NVM Checksum valid bit not set");

         if hw.mac.Mac_Type < e1000_pch_tgp
         then
            data    := data or valid_csum_mask;
            ret_val := e1000_write_nvm (hw, word, 1, data'unchecked_Access);

            if ret_val /= 0
            then
               return ret_val;
            end if;

            ret_val := e1000e_update_nvm_checksum (Hw);

            if ret_val /= 0
            then
               return ret_val;
            end if;
         end if;

      end if;

      return Devices.e1000e.Non_Volatile_Memory.e1000e_validate_nvm_checksum_generic (hw);
   end e1000_validate_nvm_checksum_ich8lan;






   ------------------------------------
   -- E1000_Write_Flash_Data_Ich8lan --
   ------------------------------------

   --  Writes bytes to the NVM.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: The offset (in bytes) of the byte/word to read.
   --  *  @size:   Size of data to read, 1=byte 2=word.
   --  *  @data:   The byte(s) to write to the NVM.
   --  *
   --  *  Writes one/two bytes to the NVM using the flash access registers.


   function E1000_Write_Flash_Data_Ich8lan
     (Hw     : access E1000_Hw;
      Offset : in     Unsigned_32;
      Size   : in     Unsigned_8;
      Data   : in     Unsigned_16) return s32
   is
      Hsfsts            : Ich8_Hws_Flash_Status;
      Hsflctl           : Ich8_Hws_Flash_Ctrl;
      Flash_Linear_Addr : Unsigned_32;
      Flash_Data        : Unsigned_32 := 0;
      Ret_Val           : Integer_32;
      Count             : Unsigned_8  := 0;

   begin
      if Hw.Mac.mac_type >= E1000_Pch_Spt
      then
         if   Size  /= 4
           or Offset > ICH_FLASH_LINEAR_ADDR_MASK
         then
            return -E1000_ERR_NVM;
         end if;

      else
         if   Size   < 1
           or Size   > 2
           or Offset > ICH_FLASH_LINEAR_ADDR_MASK
         then
            return -E1000_ERR_NVM;
         end if;
      end if;


      Flash_Linear_Addr := ((ICH_FLASH_LINEAR_ADDR_MASK and Offset) +
                            Hw.Nvm.Flash_Base_Addr);

      loop
         delay Duration (0.00_000_1);      -- udelay (1).

         -- Steps.
         --
         Ret_Val := E1000_Flash_Cycle_Init_Ich8lan (Hw);
         exit when Ret_Val /= 0;

         if Hw.Mac.mac_type >= E1000_Pch_Spt
         then
            Hsflctl.Regval := u16 (shift_Right (Er32flash (Hw, ICH_FLASH_HSFSTS),
                                                16));
         else
            Hsflctl.Regval := Er16flash (Hw, ICH_FLASH_HSFCTL);
         end if;

         -- 0b/1b corresponds to 1 or 2 byte size, respectively.
         --
         Hsflctl.Hsf_Ctrl.Fldbcount := u16 (Size) - 1;
         Hsflctl.Hsf_Ctrl.Flcycle   := ICH_CYCLE_WRITE;

         if Hw.Mac.mac_type >= E1000_Pch_Spt
         then
            Ew32flash (Hw,
                       ICH_FLASH_HSFSTS,
                       u32 (shift_Left (Hsflctl.Regval, 16)));
         else
            Ew16flash (Hw,
                       ICH_FLASH_HSFCTL,
                       Hsflctl.Regval);
         end if;

         Ew32flash (Hw, ICH_FLASH_FADDR, Flash_Linear_Addr);

         if Size = 1
         then
            Flash_Data := Unsigned_32 (Data and 16#00FF#);
         else
            Flash_Data := Unsigned_32 (Data);
         end if;

         Ew32flash (Hw, ICH_FLASH_FDATA0, Flash_Data);

         Ret_Val := E1000_Flash_Cycle_Ich8lan (Hw, ICH_FLASH_WRITE_COMMAND_TIMEOUT);
         exit when Ret_Val = 0;

         Hsfsts.Regval := Er16flash (Hw, ICH_FLASH_HSFSTS);

         if Hsfsts.Hsf_Status.Flcerr
         then
            null;     -- Repeat for some time before giving up.

         elsif not Hsfsts.Hsf_Status.Flcdone
         then
            E_Dbg ("Timeout error - flash cycle did not complete.");
            exit;
         end if;

         Count := Count + 1;
         exit when Count >= ICH_FLASH_CYCLE_REPEAT_COUNT;
      end loop;


      return Ret_Val;
   end E1000_Write_Flash_Data_Ich8lan;




   --------------------------------------
   -- E1000_Write_Flash_Data32_Ich8lan --
   --------------------------------------

   --  Writes 4 bytes to the NVM.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: The offset (in bytes) of the dwords to read.
   --  *  @data:   The 4 bytes to write to the NVM.
   --  *
   --  *  Writes one/two/four bytes to the NVM using the flash access registers.


   function E1000_Write_Flash_Data32_Ich8lan
     (Hw     : access E1000_Hw;
      Offset : in     Interfaces.Unsigned_32;
      Data   : in     Interfaces.Unsigned_32) return s32
   is
      Hsfsts            : Ich8_Hws_Flash_Status;
      Hsflctl           : Ich8_Hws_Flash_Ctrl;
      Flash_Linear_Addr : Interfaces.Unsigned_32;
      Ret_Val           : s32;
      Count             : Natural := 0;

   begin
      if Hw.Mac.Mac_Type >= E1000_Pch_Spt
      then
         if Offset > ICH_FLASH_LINEAR_ADDR_MASK
         then
            return -E1000_ERR_NVM;
         end if;
      end if;

      Flash_Linear_Addr := ((ICH_FLASH_LINEAR_ADDR_MASK and Offset)
                            + Hw.Nvm.Flash_Base_Addr);

      loop
         delay 0.00_000_1;               -- udelay(1) equivalent.

         -- Steps.
         --
         Ret_Val := E1000_Flash_Cycle_Init_Ich8lan (Hw);
         exit when Ret_Val /= 0;

         -- In SPT, This register is in Lan memory space, not flash.
         -- Therefore, only 32 bit access is supported.
         --
         if Hw.Mac.Mac_Type >= E1000_Pch_Spt
         then
            Hsflctl.Regval := shift_Right (u16 (Er32flash (Hw, ICH_FLASH_HSFSTS)),
                                           16);
         else
            Hsflctl.Regval := Er16flash (Hw, ICH_FLASH_HSFCTL);
         end if;

         Hsflctl.Hsf_Ctrl.Fldbcount := Interfaces.Unsigned_32'Size / 8 - 1;
         Hsflctl.Hsf_Ctrl.Flcycle   := ICH_CYCLE_WRITE;

         -- In SPT, This register is in Lan memory space, not flash.
         -- Therefore, only 32 bit access is supported.
         --
         if Hw.Mac.Mac_Type >= E1000_Pch_Spt
         then
            Ew32flash (Hw, ICH_FLASH_HSFSTS, u32 (shift_Left (Hsflctl.Regval,
                                                              16)));
         else
            Ew16flash (Hw, ICH_FLASH_HSFCTL, Hsflctl.Regval);
         end if;

         Ew32flash (Hw, ICH_FLASH_FADDR,  Flash_Linear_Addr);
         Ew32flash (Hw, ICH_FLASH_FDATA0, Data);

         -- Check if FCERR is set to 1, if set to 1, clear it
         -- and try the whole sequence a few more times else done.
         --
         Ret_Val := E1000_Flash_Cycle_Ich8lan (Hw, ICH_FLASH_WRITE_COMMAND_TIMEOUT);

         exit when Ret_Val = 0;

         -- If we're here, then things are most likely completely hosed,
         -- but if the error condition is detected, it won't hurt to give it another
         -- try ... ICH_FLASH_CYCLE_REPEAT_COUNT times.
         --
         Hsfsts.Regval := Er16flash (Hw, ICH_FLASH_HSFSTS);

         if Hsfsts.Hsf_Status.Flcerr
         then
            null;     -- Repeat for some time before giving up.

         elsif not Hsfsts.Hsf_Status.Flcdone
         then
            e_dbg ("Timeout error - flash cycle did not complete.");
            exit;
         end if;

         Count := Count + 1;
         exit when Count >= ICH_FLASH_CYCLE_REPEAT_COUNT;
      end loop;


      return Ret_Val;
   end E1000_Write_Flash_Data32_Ich8lan;




   ------------------------------------
   -- E1000_Write_Flash_Byte_Ich8lan --
   ------------------------------------

   --  Write a single byte to NVM.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: The index of the byte to read.
   --  *  @data:   The byte to write to the NVM.
   --  *
   --  *  Writes a single byte to the NVM using the flash access registers.


   function E1000_Write_Flash_Byte_Ich8lan
     (HW     : access E1000_HW;
      Offset : Unsigned_32;
      Data   : Unsigned_8) return Integer_32
   is
      Word  : Unsigned_16;
   begin
      Word := u16 (Data);
      return E1000_Write_Flash_Data_Ich8lan (HW, Offset, 1, Word);
   end E1000_Write_Flash_Byte_Ich8lan;




   -------------------------------------
   -- e1000_Retry_Write_Flash_Dword_Ich8lan --
   -------------------------------------

   --  Writes a dword to NVM.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: The offset of the word to write.
   --  *  @dword:  The dword to write to the NVM.
   --  *
   --  *  Writes a single dword to the NVM using the flash access registers.
   --  *  Goes through a retry algorithm before giving up.


   function e1000_Retry_Write_Flash_Dword_Ich8lan
     (Hw     : access E1000_Hw;
      Offset : in     Unsigned_32;
      Dword  : in     Unsigned_32) return s32
   is
      Ret_Val         : s32;
      Adjusted_Offset : Unsigned_32;

   begin
      -- Must convert word offset into bytes.
      --
      Adjusted_Offset := Interfaces.shift_Left (Offset, 1);
      Ret_Val         := E1000_Write_Flash_Data32_Ich8lan (Hw, Adjusted_Offset, Dword);

      if Ret_Val = 0
      then
         return Ret_Val;
      end if;


      for I in 1 .. 100
      loop
         e_dbg (  "Retrying Byte " & Dword          'Image
                & " at offset "    & Adjusted_Offset'Image);

         delay 0.00_015;      -- Equivalent to usleep_range (100, 200).

         Ret_Val := E1000_Write_Flash_Data32_Ich8lan (Hw, Adjusted_Offset, Dword);

         if Ret_Val = 0
         then
            return 0;
         end if;
      end loop;


      return -E1000_ERR_NVM;
   end e1000_Retry_Write_Flash_Dword_Ich8lan;





   ------------------------------------------
   -- e1000_Retry_Write_Flash_Byte_Ich8lan --
   ------------------------------------------

   --  Writes a single byte to NVM.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: The offset of the byte to write.
   --  *  @byte:   The byte to write to the NVM.
   --  *
   --  *  Writes a single byte to the NVM using the flash access registers.
   --  *  Goes through a retry algorithm before giving up.


   function e1000_Retry_Write_Flash_Byte_Ich8lan
     (Hw     : access E1000_Hw;
      Offset : in     Unsigned_32;
      Byte   : in     Unsigned_8) return Interfaces.Integer_32
   is
      Ret_Val         : s32;
      Program_Retries : Interfaces.Unsigned_16 := 0;

   begin
      Ret_Val := e1000_Write_Flash_Byte_Ich8lan (Hw, Offset, Byte);

      if Ret_Val = 0
      then
         return Ret_Val;
      end if;


      while Program_Retries < 100
      loop
         Program_Retries := Program_Retries + 1;

         e_dbg (  "Retrying Byte " & Byte  'Image
                & " at offset "    & Offset'Image);

         delay 0.00_015;      -- Equivalent to usleep_range(100, 200)

         Ret_Val := e1000_Write_Flash_Byte_Ich8lan (Hw, Offset, Byte);

         if Ret_Val = 0
         then
            exit;
         end if;
      end loop;


      if Program_Retries = 100
      then
         return -E1000_ERR_NVM;
      end if;

      return 0;
   end e1000_Retry_Write_Flash_Byte_Ich8lan;




   ------------------------------------
   -- E1000_Erase_Flash_Bank_Ich8lan --
   ------------------------------------

   --  Erase a bank (4k) from NVM.
   --
   --  *  @hw:   Pointer to the HW structure.
   --  *  @bank: 0 for first bank, 1 for second bank, etc.
   --  *
   --  *  Erases the bank specified. Each bank is a 4k block. Banks are 0 based.
   --  *  bank N is 4096 * N + flash_reg_addr.


   function E1000_Erase_Flash_Bank_Ich8lan
     (Hw   : access E1000_Hw;
      Bank : in     Unsigned_32) return s32
   is
      Nvm               :          E1000_Nvm_Info.item renames Hw.Nvm;
      Hsfsts            :          Ich8_Hws_Flash_Status;
      Hsflctl           :          Ich8_Hws_Flash_Ctrl;
      Flash_Linear_Addr :          Unsigned_32;
      Flash_Bank_Size   : constant Unsigned_32 := Nvm.Flash_Bank_Size * 2;
      Ret_Val           :          s32;
      Count             :          Integer_32  := 0;
      Iteration         :          Integer_32;
      Sector_Size       :          Integer_32;

   begin
      Hsfsts.Regval := Er16flash (Hw, ICH_FLASH_HSFSTS);

      case Hsfsts.Hsf_Status.Berasesz
      is
         when 0 =>
            Sector_Size := ICH_FLASH_SEG_SIZE_256;
            Iteration := Integer_32 (Flash_Bank_Size / ICH_FLASH_SEG_SIZE_256);

         when 1 =>
            Sector_Size := ICH_FLASH_SEG_SIZE_4K;
            Iteration := 1;

         when 2 =>
            Sector_Size := ICH_FLASH_SEG_SIZE_8K;
            Iteration := 1;

         when 3 =>
            Sector_Size := ICH_FLASH_SEG_SIZE_64K;
            Iteration := 1;

         when others =>
            return -E1000_ERR_NVM;
      end case;


      Flash_Linear_Addr := Hw.Nvm.Flash_Base_Addr;

      if Bank /= 0
      then
         Flash_Linear_Addr := Flash_Linear_Addr + Flash_Bank_Size;
      end if;


      for J in 0 .. Iteration - 1
      loop

         loop
            declare
               Timeout : constant Unsigned_32 := ICH_FLASH_ERASE_COMMAND_TIMEOUT;
            begin
               Ret_Val := E1000_Flash_Cycle_Init_Ich8lan (Hw);

               if Ret_Val /= 0
               then
                  return Ret_Val;
               end if;

               if Hw.Mac.Mac_Type >= E1000_Pch_Spt
               then
                  Hsflctl.Regval := u16 (shift_Right (Er32flash (Hw, ICH_FLASH_HSFSTS),
                                                      16));
               else
                  Hsflctl.Regval := Er16flash (Hw, ICH_FLASH_HSFCTL);
               end if;

               Hsflctl.Hsf_Ctrl.Flcycle := ICH_CYCLE_ERASE;

               if Hw.Mac.Mac_Type >= E1000_Pch_Spt
               then
                  Ew32flash (Hw, ICH_FLASH_HSFSTS, shift_Left (u32 (Hsflctl.Regval),
                                                               16));
               else
                  Ew16flash (Hw, ICH_FLASH_HSFCTL, Hsflctl.Regval);
               end if;

               Flash_Linear_Addr := Flash_Linear_Addr + Unsigned_32 (J * Sector_Size);
               Ew32flash (Hw, ICH_FLASH_FADDR, Flash_Linear_Addr);

               Ret_Val := E1000_Flash_Cycle_Ich8lan (Hw, Timeout);
               exit when Ret_Val = 0;

               Hsfsts.Regval := Er16flash (Hw, ICH_FLASH_HSFSTS);

               if Hsfsts.Hsf_Status.Flcerr
               then
                  null;
               elsif not Hsfsts.Hsf_Status.Flcdone
               then
                  return Ret_Val;
               end if;
            end;

            Count := Count + 1;
            exit when Count >= ICH_FLASH_CYCLE_REPEAT_COUNT;
         end loop;

      end loop;


      return 0;
   end E1000_Erase_Flash_Bank_Ich8lan;





   -------------------------------------
   -- E1000_Valid_Led_Default_Ich8lan --
   -------------------------------------
   --  Set the default LED settings.
   --
   --   *  @hw:   Pointer to the HW structure.
   --   *  @data: Pointer to the LED settings.
   --   *
   --   *  Reads the LED default settings from the NVM to data.  If the NVM LED
   --   *  settings is all 0's or F's, set the LED default to a valid LED default
   --   *  setting.


   function E1000_Valid_Led_Default_Ich8lan
     (HW   : access E1000_HW;
      Data : in     u16_Pointer) return s32
   is
      Ret_Val :s32;
   begin
      Ret_Val := E1000_Read_NVM (Hw,
                                 NVM_ID_LED_SETTINGS,
                                 1,
                                 Data);
      if Ret_Val /= 0
      then
         e_dbg ("NVM Read Error");
         return Ret_Val;
      end if;

      if   Data.all = ID_LED_RESERVED_0000
        or Data.all = ID_LED_RESERVED_FFFF
      then
         Data.all := u16 (ID_LED_DEFAULT_ICH8LAN);
      end if;

      return 0;
   end E1000_Valid_Led_Default_Ich8lan;




   ------------------------------
   -- E1000_Id_Led_Init_Pchlan --
   ------------------------------

   function E1000_Id_Led_Init_Pchlan (Hw : access E1000_Hw) return s32
   is
      Mac        :          E1000_Mac_Info.item renames Hw.Mac;
      Ret_Val    :          s32;
      Ledctl_On  : constant Unsigned_32 := E1000_LEDCTL_MODE_LINK_UP;
      Ledctl_Off : constant Unsigned_32 := E1000_LEDCTL_MODE_LINK_UP or E1000_PHY_LED0_IVRT;
      Data       : aliased  Unsigned_16;
      Temp       :          Unsigned_16;
      Shift      :          Integer;

   begin
      -- Get default ID LED modes.
      --
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
         Temp  :=     shift_Right (Data, I * 4)
                  and E1000_LEDCTL_LED0_MODE_MASK;
         Shift := I * 5;

         case Temp
         is
            when ID_LED_ON1_DEF2
               | ID_LED_ON1_ON2
               | ID_LED_ON1_OFF2 =>
               Mac.Ledctl_Mode1 := Mac.Ledctl_Mode1 and not shift_Left (E1000_PHY_LED0_MASK, Shift);
               Mac.Ledctl_Mode1 := Mac.Ledctl_Mode1 or      shift_Left (Ledctl_On,           Shift);

            when ID_LED_OFF1_DEF2
               | ID_LED_OFF1_ON2
               | ID_LED_OFF1_OFF2 =>
               Mac.Ledctl_Mode1 := Mac.Ledctl_Mode1 and not shift_Left (E1000_PHY_LED0_MASK, Shift);
               Mac.Ledctl_Mode1 := Mac.Ledctl_Mode1 or      shift_Left (Ledctl_Off,          Shift);
            when others =>
               null;         -- Do nothing
         end case;

         case Temp
         is
            when ID_LED_DEF1_ON2
               | ID_LED_ON1_ON2
               | ID_LED_OFF1_ON2 =>
               Mac.Ledctl_Mode2 := Mac.Ledctl_Mode2 and not shift_Left (E1000_PHY_LED0_MASK, Shift);
               Mac.Ledctl_Mode2 := Mac.Ledctl_Mode2 or      shift_Left (Ledctl_On,           Shift);

            when ID_LED_DEF1_OFF2
               | ID_LED_ON1_OFF2
               | ID_LED_OFF1_OFF2 =>
               Mac.Ledctl_Mode2 := Mac.Ledctl_Mode2 and not shift_Left (E1000_PHY_LED0_MASK, Shift);
               Mac.Ledctl_Mode2 := Mac.Ledctl_Mode2 or      shift_Left (Ledctl_Off,          Shift);
            when others =>
               null;         -- Do nothing
         end case;
      end loop;

      return 0;
   end E1000_Id_Led_Init_Pchlan;






   --------------------------------
   -- E1000_Get_Bus_Info_Ich8lan --
   --------------------------------

   --  Get/Set the bus type and width.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  ICH8 use the PCI Express bus, but does not contain a PCI Express Capability
   --  *  register, so the bus width is hard coded.


   function E1000_Get_Bus_Info_Ich8lan
     (HW : access E1000_HW) return s32
   is
      Ret_Val : s32;
   begin
      Ret_Val := Devices.e1000e.Media_Access_Control.e1000e_Get_Bus_Info_Pcie (HW);

      -- ICH devices are "PCI Express"-ish. They have
      -- a configuration space, but do not contain
      -- PCI Express Capability registers, so bus width
      -- must be hardcoded.
      --
      if HW.Bus.Width = E1000_Bus_Width_Unknown
      then
         HW.Bus.Width := E1000_Bus_Width_Pcie_X1;
      end if;

      return Ret_Val;
   end E1000_Get_Bus_Info_Ich8lan;




   ----------------------------
   -- E1000_Reset_HW_ICH8LAN --
   ----------------------------

   --  Reset the hardware.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Does a full reset of the hardware which includes a reset of the PHY and MAC.


   function E1000_Reset_HW_ICH8LAN (HW : access E1000_HW) return s32
   is
      --  Dev_Spec : E1000_Dev_Spec_ICH8LAN.item renames HW.Dev_Spec.ICH8LAN;
      KUM_CFG  : aliased Interfaces.Unsigned_16;
      CTRL,
      REG      :         Interfaces.Unsigned_32;
      Ret_Val  :         s32;
      Unused   :         u32;

   begin
      -- Prevent the PCI-E bus from sticking if there is no TLP connection
      -- on the last TLP read/write transaction when MAC is reset.
      --
      Ret_Val := Devices.e1000e.Media_Access_Control.E1000E_Disable_PCIE_Master (HW);

      if Ret_Val /= 0
      then
         e_dbg ("PCI-E Master disable polling has failed.");
      end if;

      e_dbg ("Masking off all interrupts");
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_IMC, 16#FFFFFFFF#);

      -- Disable the Transmit and Receive units. Then delay to allow
      -- any pending transactions to complete before we hit the MAC
      -- with the global reset.
      --
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_RCTL, 0);
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_TCTL, E1000_TCTL_PSP);
      E1E_Flush (Hw);

      delay 0.015;

      -- Workaround for ICH8 bit corruption issue in FIFO memory.
      --
      if HW.MAC.mac_type = E1000_ICH8LAN
      then
         EW32 (Hw.all, Devices.e1000e.Registers.E1000_PBA, E1000_PBA_8K);          -- Set Tx and Rx buffer allocation to 8k apiece.
         EW32 (Hw.all, Devices.e1000e.Registers.E1000_PBS, E1000_PBS_16K);         -- Set Packet Buffer Size to 16k.
      end if;

      if HW.MAC.mac_type = E1000_PCHLAN
      then
         -- Save the NVM K1 bit setting.
         --
         Ret_Val := E1000_Read_NVM (Hw, E1000_NVM_K1_CONFIG, 1, KUM_CFG'unchecked_Access);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;

         if (KUM_CFG and E1000_NVM_K1_ENABLE) /= 0
         then
            HW.Dev_Spec.ICH8LAN.NVM_K1_Enabled := True;
         else
            HW.Dev_Spec.ICH8LAN.NVM_K1_Enabled := False;
         end if;
      end if;

      CTRL := ER32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);

      if HW.PHY.OPS.Check_Reset_Block (Hw) = 0
      then
         -- Full-chip reset requires MAC and PHY reset at the same
         -- time to make sure the interface between MAC and the
         -- external PHY is reset.
         --
         CTRL := CTRL or E1000_CTRL_PHY_RST;

         -- Gate automatic PHY configuration by hardware on
         -- non-managed 82579.
         --
         if          HW.MAC.mac_type = E1000_PCH2LAN
           and then (ER32 (Hw.all, Devices.e1000e.Registers.E1000_FWSM) and E1000_ICH_FWSM_FW_VALID) = 0
         then
            E1000_Gate_HW_PHY_Config_ICH8LAN (HW, True);
         end if;
      end if;

      Ret_Val := E1000_Acquire_SWFLAG_ICH8LAN (HW);
      e_dbg ("Issuing a global reset to ich8lan");
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, CTRL or E1000_CTRL_RST);
      -- Cannot issue a flush here because it hangs the hardware.
      delay 0.02;

      -- Set Phy Config Counter to 50msec.
      --
      if HW.MAC.mac_type = E1000_PCH2LAN
      then
         REG := ER32 (Hw.all, Devices.e1000e.Registers.E1000_FEXTNVM3);
         REG := REG and (not E1000_FEXTNVM3_PHY_CFG_COUNTER_MASK);
         REG := REG or       E1000_FEXTNVM3_PHY_CFG_COUNTER_50MSEC;
         EW32 (Hw.all, Devices.e1000e.Registers.E1000_FEXTNVM3, REG);
      end if;

      if Ret_Val = 0
      then
         clear_bit (E1000_ACCESS_SHARED_RESOURCE'Enum_Rep, HW.Adapter.State'Address);
      end if;

      if (CTRL and E1000_CTRL_PHY_RST) /= 0
      then
         Ret_Val := HW.PHY.OPS.Get_CFG_Done (HW);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;

         Ret_Val := E1000_Post_PHY_Reset_ICH8LAN (HW);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;
      end if;

      -- For PCH, this write will make sure that any noise
      -- will be detected as a CRC error and be dropped rather than show up
      -- as a bad packet to the DMA engine.
      --
      if HW.MAC.mac_type = E1000_PCHLAN
      then
         EW32 (Hw.all, Devices.e1000e.Registers.E1000_CRC_OFFSET, 16#65656565#);
      end if;

      EW32 (Hw.all, Devices.e1000e.Registers.E1000_IMC, 16#FFFFFFFF#);
      Unused := ER32 (Hw.all, Devices.e1000e.Registers.E1000_ICR);

      REG := ER32 (Hw.all, Devices.e1000e.Registers.E1000_KABGTXD);
      REG := REG or E1000_KABGTXD_BGSQLBIAS;
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_KABGTXD, REG);

      return 0;
   end E1000_Reset_HW_ICH8LAN;




   ---------------------------
   -- E1000_Init_HW_ICH8LAN --
   ---------------------------

   --  Initialize the hardware.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Prepares the hardware for transmit and receive by doing the following:
   --  *   - initialize hardware bits
   --  *   - initialize LED identification
   --  *   - setup receive address registers
   --  *   - setup flow control
   --  *   - setup transmit descriptors
   --  *   - clear statistics


   function E1000_Init_HW_ICH8LAN
     (HW : access E1000_HW) return s32
   is
      use Devices.e1000e.Media_Access_Control;

      MAC      :         E1000_MAC_INFO.item renames HW.MAC;
      CTRL_EXT,
      TXDCTL,
      SNOOP,
      FFLT_DBG :         Interfaces.Unsigned_32;
      RET_VAL  :         s32;
      I        : aliased Interfaces.Unsigned_16;
      Unused   :         s32;

   begin
      E1000_Initialize_HW_Bits_ICH8LAN (HW);

      -- Initialize identification LED.
      --
      RET_VAL := HW.MAC.OPS.ID_LED_Init (HW);

      -- An error is not fatal and we should not stop init due to this.
      --
      if RET_VAL /= 0
      then
         e_dbg ("Error initializing identification LED");
      end if;

      -- Setup the receive address.
      --
      E1000E_Init_RX_Addrs (HW, MAC.RAR_Entry_Count);

      -- Zero out the Multicast HASH table.
      --
      e_dbg ("Zeroing the MTA");

      for I in 0 .. MAC.MTA_Reg_Count - 1
      loop
         E1000_WRITE_REG_ARRAY (HW,
                                Devices.e1000e.Registers.E1000_MTA,
                                u32 (I),
                                0);
      end loop;

      -- The 82578 Rx buffer will stall if wakeup is enabled in host and
      -- the ME. Disable wakeup by clearing the host wakeup bit.
      -- Reset the phy after disabling host wakeup to reset the Rx buffer.
      --
      if HW.PHY.PHY_Type = E1000_PHY_82578
      then
         Unused := E1E_RPHY (HW, BM_PORT_GEN_CFG, I'unchecked_Access);
         I      := I and (not BM_WUC_HOST_WU_BIT);
         Unused := E1E_WPHY (HW, BM_PORT_GEN_CFG, I);

         RET_VAL := E1000_PHY_HW_Reset_ICH8LAN (HW);

         if RET_VAL /= 0
         then
            return RET_VAL;
         end if;
      end if;

      -- Setup link and flow control.
      --
      RET_VAL := MAC.OPS.Setup_Link (HW);

      -- Set the transmit descriptor write-back policy for both queues.
      --
      TXDCTL := ER32 (Hw.all, Devices.e1000e.Registers.E1000_TXDCTL (0));
      TXDCTL := (TXDCTL and (not E1000_TXDCTL_WTHRESH)) or E1000_TXDCTL_FULL_TX_DESC_WB;
      TXDCTL := (TXDCTL and (not E1000_TXDCTL_PTHRESH)) or E1000_TXDCTL_MAX_TX_DESC_PREFETCH;
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_TXDCTL (0), TXDCTL);

      TXDCTL := ER32 (Hw.all, Devices.e1000e.Registers.E1000_TXDCTL (1));
      TXDCTL := (TXDCTL and (not E1000_TXDCTL_WTHRESH)) or E1000_TXDCTL_FULL_TX_DESC_WB;
      TXDCTL := (TXDCTL and (not E1000_TXDCTL_PTHRESH)) or E1000_TXDCTL_MAX_TX_DESC_PREFETCH;
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_TXDCTL (1), TXDCTL);

      -- ICH8 has opposite polarity of no_snoop bits.
      -- By default, we should use snoop behavior.
      --
      if MAC.MAC_Type = E1000_ICH8LAN
      then
         SNOOP := PCIE_ICH8_SNOOP_ALL;
      else
         SNOOP := u32 (not (PCIE_NO_SNOOP_ALL));
      end if;

      E1000E_Set_PCIE_No_Snoop (HW, SNOOP);

      -- Enable workaround for packet loss issue on TGP PCH
      -- Do not gate DMA clock from the modPHY block.
      --
      if MAC.MAC_Type >= E1000_PCH_TGP
      then
         FFLT_DBG := ER32 (Hw.all, Devices.e1000e.Registers.E1000_FFLT_DBG);
         FFLT_DBG := FFLT_DBG or E1000_FFLT_DBG_DONT_GATE_WAKE_DMA_CLK;
         EW32 (Hw.all, Devices.e1000e.Registers.E1000_FFLT_DBG, FFLT_DBG);
      end if;

      CTRL_EXT := ER32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT);
      CTRL_EXT := CTRL_EXT or E1000_CTRL_EXT_RO_DIS;
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT, CTRL_EXT);

      -- Clear all of the statistics registers (clear on read). It is
      -- important that we do this after we have tried to establish link
      -- because the symbol error count will increment wildly if there
      -- is no link.
      --
      E1000_Clear_HW_CNTRS_ICH8LAN (HW);

      return RET_VAL;
   end E1000_Init_HW_ICH8LAN;






   --------------------------------------
   -- E1000_Initialize_HW_Bits_ICH8LAN --
   --------------------------------------

   --  Initialize required hardware bits.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Sets/Clears required hardware bits necessary for correctly setting up the
   --  *  hardware for transmit and receive.


   procedure E1000_Initialize_HW_Bits_ICH8LAN (HW : access E1000_HW)
   is
      Reg : Unsigned_32;
   begin
      -- Extended Device Control.
      --
      Reg := ER32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT);
      Reg := Reg or Shift_Left (1, 22);

      -- Enable PHY low-power state when MAC is at D3 w/o WoL.
      --
      if HW.Mac.mac_type >= E1000_PCHLAN
      then
         Reg := Reg or E1000_CTRL_EXT_PHYPDEN;
      end if;

      EW32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT, Reg);

      -- Transmit Descriptor Control 0.
      --
      Reg := ER32 (Hw.all, Devices.e1000e.Registers.E1000_TXDCTL (0));
      Reg := Reg or Shift_Left (1, 22);
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_TXDCTL (0), Reg);

      -- Transmit Descriptor Control 1.
      --
      Reg := ER32 (Hw.all, Devices.e1000e.Registers.E1000_TXDCTL (1));
      Reg := Reg or Shift_Left (1, 22);
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_TXDCTL (1), Reg);

      -- Transmit Arbitration Control 0.
      --
      Reg := ER32 (Hw.all, Devices.e1000e.Registers.E1000_TARC (0));

      if HW.Mac.mac_type = E1000_ICH8LAN
      then
         Reg := Reg or Shift_Left (1, 28) or Shift_Left (1, 29);
      end if;

      Reg := Reg or shift_Left (1, 23)
                 or shift_Left (1, 24)
                 or shift_Left (1, 26)
                 or shift_Left (1, 27);
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_TARC (0), Reg);

      -- Transmit Arbitration Control 1.
      --
      Reg := ER32 (Hw.all, Devices.e1000e.Registers.E1000_TARC (1));

      if (ER32 (Hw.all, Devices.e1000e.Registers.E1000_TCTL) and E1000_TCTL_MULR) /= 0
      then
         Reg := Reg and not Shift_Left (1, 28);
      else
         Reg := Reg or Shift_Left (1, 28);
      end if;

      Reg := Reg or shift_Left (1, 24)
                 or shift_Left (1, 26)
                 or shift_Left (1, 30);
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_TARC (1), Reg);

      -- Device Status.
      --
      if HW.Mac.mac_type = E1000_ICH8LAN
      then
         Reg := ER32 (Hw.all, Devices.e1000e.Registers.E1000_STATUS);
         Reg := Reg and not shift_Left (1, 31);
         EW32 (Hw.all, Devices.e1000e.Registers.E1000_STATUS, Reg);
      end if;

      -- Work-around descriptor data corruption issue during nfs v2 udp
      -- traffic, just disable the nfs filtering capability.
      --
      Reg := ER32 (Hw.all, Devices.e1000e.Registers.E1000_RFCTL);
      Reg := Reg or (   E1000_RFCTL_NFSW_DIS
                     or E1000_RFCTL_NFSR_DIS);

      -- Disable IPv6 extension header parsing because some malformed
      -- IPv6 headers can hang the Rx.
      --
      if HW.Mac.mac_type = E1000_ICH8LAN
      then
         Reg := Reg or (   E1000_RFCTL_IPV6_EX_DIS
                        or E1000_RFCTL_NEW_IPV6_EXT_DIS);
      end if;

      EW32 (Hw.all, Devices.e1000e.Registers.E1000_RFCTL, Reg);

      -- Enable ECC on Lynxpoint.
      --
      if HW.Mac.mac_type >= E1000_PCH_LPT
      then
         Reg := ER32 (Hw.all, Devices.e1000e.Registers.E1000_PBECCSTS);
         Reg := Reg or E1000_PBECCSTS_ECC_ENABLE;
         EW32 (Hw.all, Devices.e1000e.Registers.E1000_PBECCSTS, Reg);

         Reg := ER32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);
         Reg := Reg or E1000_CTRL_MEHE;
         EW32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, Reg);
      end if;
   end E1000_Initialize_HW_Bits_ICH8LAN;





   ------------------------------
   -- E1000_Setup_Link_Ich8lan --
   ------------------------------

   --  Setup flow control and link settings.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Determines which flow control settings to use, then configures flow
   --  *  control.  Calls the appropriate media-specific link configuration
   --  *  function.  Assuming the adapter has a valid link partner, a valid link
   --  *  should be established.  Assumes the hardware has previously been reset
   --  *  and the transmitter and receiver are not enabled.


   function E1000_Setup_Link_Ich8lan
     (Hw : access E1000_Hw) return s32
   is
      Ret_Val : s32;

   begin
      if Hw.Phy.Ops.Check_Reset_Block (Hw) /= 0
      then
         return 0;
      end if;

      -- ICH parts do not have a word in the NVM to determine
      -- the default flow control setting, so we explicitly
      -- set it to full.
      --
      if Hw.Fc.Requested_Mode = E1000_Fc_Default
      then
         -- Workaround h/w hang when Tx flow control enabled.
         --
         if Hw.Mac.mac_type = E1000_Pchlan
         then
            Hw.Fc.Requested_Mode := E1000_Fc_Rx_Pause;
         else
            Hw.Fc.Requested_Mode := E1000_Fc_Full;
         end if;
      end if;

      -- Save off the requested flow control mode for use later.  Depending
      -- on the link partner's capabilities, we may or may not use this mode.
      --
      Hw.Fc.Current_Mode := Hw.Fc.Requested_Mode;

      e_dbg ("After fix-ups FlowControl is now =" & Hw.Fc.Current_Mode'Image);

      -- Continue to configure the copper link.
      --
      Ret_Val := Hw.Mac.Ops.Setup_Physical_Interface (Hw);
      --
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_FCTTV, u32 (Hw.Fc.Pause_Time));

      if   Hw.Phy.phy_type = E1000_Phy_82578
        or Hw.Phy.phy_type = E1000_Phy_82579
        or Hw.Phy.phy_type = E1000_Phy_I217
        or Hw.Phy.phy_type = E1000_Phy_82577
      then
         Ew32 (Hw.all, E1000_FCRTV_PCH, u32 (Hw.Fc.Refresh_Time));

         Ret_Val := E1e_Wphy (Hw,
                              PHY_REG (BM_PORT_CTRL_PAGE, 27),
                              Hw.Fc.Pause_Time);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;
      end if;

      return Devices.e1000e.Media_Access_Control.E1000e_Set_Fc_Watermarks (Hw);
   end E1000_Setup_Link_Ich8lan;





   -------------------------------------
   -- E1000_Setup_Copper_Link_Ich8lan --
   -------------------------------------

   --  Configure MAC/PHY interface.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Configures the kumeran interface to the PHY to wait the appropriate time
   --  *  when polling the PHY, then call the generic setup_copper_link to finish
   --  *  configuring the copper link.


   function E1000_Setup_Copper_Link_Ich8lan
     (HW : access E1000_HW) return s32
   is
      Ctrl     :         Unsigned_32;
      Ret_Val  :         s32;
      Reg_Data : aliased Unsigned_16;

   begin
      Ctrl := ER32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);
      Ctrl := Ctrl or E1000_CTRL_SLU;
      Ctrl := Ctrl and (not (   E1000_CTRL_FRCSPD
                             or E1000_CTRL_FRCDPX));
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, Ctrl);

      -- Set the mac to wait the maximum time between each iteration
      -- and increase the max iterations when polling the phy;
      -- this fixes erroneous timeouts at 10Mbps.
      --
      Ret_Val := E1000e_Write_Kmrn_Reg (HW, E1000_KMRNCTRLSTA_TIMEOUTS, 16#FFFF#);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Ret_Val := E1000e_Read_Kmrn_Reg (HW,
                                       E1000_KMRNCTRLSTA_INBAND_PARAM,
                                       Reg_Data'unchecked_Access);
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Reg_Data := Reg_Data or 16#3F#;
      Ret_Val  := E1000e_Write_Kmrn_Reg (HW,
                                         E1000_KMRNCTRLSTA_INBAND_PARAM,
                                         Reg_Data);
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      case HW.Phy.Phy_Type
      is
         when E1000_Phy_Igp_3 =>
            Ret_Val := E1000e_Copper_Link_Setup_Igp (HW);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;

         when E1000_Phy_Bm
            | E1000_Phy_82578 =>
            Ret_Val := E1000e_Copper_Link_Setup_M88 (HW);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;

         when E1000_Phy_82577
            | E1000_Phy_82579 =>
            Ret_Val := E1000_Copper_Link_Setup_82577 (HW);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;

         when E1000_Phy_Ife =>
            Ret_Val := E1e_Rphy (HW,
                                 IFE_PHY_MDIX_CONTROL,
                                 Reg_Data'unchecked_Access);
            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;

            Reg_Data := Reg_Data and (not IFE_PMC_AUTO_MDIX);

            case HW.Phy.Mdix
            is
               when 1 =>
                  Reg_Data := Reg_Data and (not IFE_PMC_FORCE_MDIX);
               when 2 =>
                  Reg_Data := Reg_Data or IFE_PMC_FORCE_MDIX;
               when others =>
                  Reg_Data := Reg_Data or IFE_PMC_AUTO_MDIX;
            end case;

            Ret_Val := E1e_Wphy (HW, IFE_PHY_MDIX_CONTROL, Reg_Data);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;

         when others =>
            null;
      end case;


      return E1000e_Setup_Copper_Link (HW);
   end E1000_Setup_Copper_Link_Ich8lan;




   -------------------------------------
   -- E1000_Setup_Copper_Link_Pch_Lpt --
   -------------------------------------

   --    Configure MAC/PHY interface.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Calls the PHY specific link setup function and then calls the
   --  *  generic setup_copper_link to finish configuring the link for
   --  *  Lynxpoint PCH devices.


   function E1000_Setup_Copper_Link_Pch_Lpt
     (Hw : access E1000_Hw) return s32
   is
      Ctrl    : Unsigned_32;
      Ret_Val : s32;

   begin
      Ctrl := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);
      Ctrl := Ctrl or E1000_CTRL_SLU;
      Ctrl := Ctrl and (not (   E1000_CTRL_FRCSPD
                             or E1000_CTRL_FRCDPX));
      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, Ctrl);

      Ret_Val := E1000_Copper_Link_Setup_82577 (Hw);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;

      return E1000e_Setup_Copper_Link (Hw);
   end E1000_Setup_Copper_Link_Pch_Lpt;





   ------------------------------------
   -- E1000_Get_Link_Up_Info_Ich8lan --
   ------------------------------------

   --  Get current link speed and duplex.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @speed:  Pointer to store current link speed.
   --  *  @duplex: Pointer to store the current link duplex.
   --  *
   --  *  Calls the generic get_speed_and_duplex to retrieve the current link
   --  *  information and then calls the Kumeran lock loss workaround for links at
   --  *  gigabit speeds.


   function E1000_Get_Link_Up_Info_Ich8lan
     (Hw     : access E1000_Hw;
      Speed  : in     u16_Pointer;
      Duplex : in     u16_Pointer) return s32
   is
      Ret_Val : s32;

   begin
      Ret_Val := Devices.e1000e.Media_Access_Control.E1000e_Get_Speed_And_Duplex_Copper (Hw,
                                                         Speed,
                                                         Duplex);
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      if         Hw.Mac.Mac_Type = E1000_Ich8lan
        and then Hw.Phy.Phy_Type = E1000_Phy_Igp_3
        and then Speed.all       = SPEED_1000
      then
         Ret_Val := E1000_Kmrn_Lock_Loss_Workaround_Ich8lan (Hw);
      end if;

      return Ret_Val;
   end E1000_Get_Link_Up_Info_Ich8lan;




   ---------------------------------------------
   -- E1000_Kmrn_Lock_Loss_Workaround_Ich8lan --
   ---------------------------------------------

   --  Kumeran workaround.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Work-around for 82566 Kumeran PCS lock loss:
   --  *  On link status change (i.e. PCI reset, speed change) and link is up and
   --  *  speed is gigabit-
   --  *    0) if workaround is optionally disabled do nothing
   --  *    1) wait 1ms for Kumeran link to come up
   --  *    2) check Kumeran Diagnostic register PCS lock loss bit
   --  *    3) if not set the link is locked (all is good), otherwise...
   --  *    4) reset the PHY
   --  *    5) repeat up to 10 times
   --  *  Note: this is only called for IGP3 copper when speed is 1gb.


   function E1000_Kmrn_Lock_Loss_Workaround_Ich8lan
     (Hw : access E1000_Hw) return s32
   is
      Phy_Ctrl :         Interfaces.Unsigned_32;
      Ret_Val  :         s32;
      Data     : aliased Interfaces.Unsigned_16;
      Link     :         Boolean;
      Unused   :         s32;
   begin
      if not Hw.Dev_Spec.Ich8lan.Kmrn_Lock_Loss_Workaround_Enabled
      then
         return 0;
      end if;

      -- Make sure link is up before proceeding. If not just return.
      -- Attempting this while link is negotiating fouled up link stability.
      --
      Ret_Val := E1000e_Phy_Has_Link_Generic (Hw, 1, 0, Link);

      if not Link
      then
         return 0;
      end if;


      for I in 1 .. 10
      loop
         -- Read once to clear.
         --
         Ret_Val := E1e_Rphy (Hw, IGP3_KMRN_DIAG, Data'unchecked_Access);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;

         -- And again to get new status.
         --
         Ret_Val := E1e_Rphy (Hw, IGP3_KMRN_DIAG, Data'unchecked_Access);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         -- Check for PCS lock.
         --
         if (Data and IGP3_KMRN_DIAG_PCS_LOCK_LOSS) = 0
         then
            return 0;
         end if;


         -- Issue PHY reset.
         --
         Unused := E1000_Phy_Hw_Reset (Hw);
         delay Duration (0.00_5);      -- 5 milliseconds.
      end loop;

      -- Disable GigE link negotiation.
      --
      Phy_Ctrl := Er32 (Hw.all, Devices.e1000e.Registers.E1000_PHY_CTRL);
      Phy_Ctrl := Phy_Ctrl or (   E1000_PHY_CTRL_GBE_DISABLE
                               or E1000_PHY_CTRL_NOND0A_GBE_DISABLE);
      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_PHY_CTRL, Phy_Ctrl);

      -- Call gig speed drop workaround on Gig disable before accessing
      -- any PHY registers.
      --
      E1000e_Gig_Downshift_Workaround_Ich8lan (Hw);

      -- Unable to acquire PCS lock.
      --
      return -E1000_ERR_PHY;
   end E1000_Kmrn_Lock_Loss_Workaround_Ich8lan;





   ----------------------------------
   -- Powerdown_Workaround_ICH8LAN --
   ----------------------------------

   --  Power down workaround on D3.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Workaround for 82566 power-down on D3 entry:
   --  *    1) disable gigabit link
   --  *    2) write VR power-down enable
   --  *    3) read it back
   --  *  Continue if successful, else issue LCD reset and repeat


   procedure e1000e_Powerdown_Workaround_ICH8LAN
     (HW : access E1000_HW)
   is
      Reg    :         Unsigned_32;
      Data   : aliased Unsigned_16;
      Retry  :         Unsigned_8 := 0;
      Unused :         s32;

   begin
      if HW.PHY.phy_type /= E1000_PHY_IGP_3
      then
         return;
      end if;


      -- Try the workaround twice (if needed).
      --
      loop
         -- Disable link.
         --
         Reg := ER32 (Hw.all, Devices.e1000e.Registers.E1000_PHY_CTRL);
         Reg := Reg or (   E1000_PHY_CTRL_GBE_DISABLE
                        or E1000_PHY_CTRL_NOND0A_GBE_DISABLE);
         EW32 (Hw.all, Devices.e1000e.Registers.E1000_PHY_CTRL, Reg);

         -- Call gig speed drop workaround on Gig disable before
         -- accessing any PHY registers.
         --
         if HW.MAC.mac_type = E1000_ICH8LAN
         then
            E1000e_Gig_Downshift_Workaround_ICH8LAN (HW);
         end if;

         -- Write VR power-down enable.
         --
         Unused := E1E_RPHY (HW,
                             IGP3_VR_CTRL,
                             Data'unchecked_Access);

         Data := Data and (not IGP3_VR_CTRL_DEV_POWERDOWN_MODE_MASK);

         Unused := E1E_WPHY (HW,
                             IGP3_VR_CTRL,
                             Data or IGP3_VR_CTRL_MODE_SHUTDOWN);

         -- Read it back and test.
         --
         Unused := E1E_RPHY (HW, IGP3_VR_CTRL, Data'unchecked_Access);
         Data   := Data and IGP3_VR_CTRL_DEV_POWERDOWN_MODE_MASK;

         if (Data = IGP3_VR_CTRL_MODE_SHUTDOWN) or (Retry > 0)
         then
            exit;
         end if;

         -- Issue PHY reset and repeat at most one more time.
         --
         Reg := ER32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);
         EW32 (Hw.all,
               Devices.e1000e.Registers.E1000_CTRL,
               Reg or E1000_CTRL_PHY_RST);

         Retry := Retry + 1;
         exit when Retry > 1;
      end loop;
   end e1000e_Powerdown_Workaround_ICH8LAN;





   -------------------------------
   -- E1000_Cleanup_Led_Ich8lan --
   -------------------------------

   --  Restore the default LED operation.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Return the LED back to the default configuration.


   function E1000_Cleanup_Led_Ich8lan
     (HW : access E1000_HW) return s32
   is
   begin
      if HW.Phy.Phy_Type = E1000_Phy_Ife
      then
         return E1e_Wphy (HW, IFE_PHY_SPECIAL_CONTROL_LED, 0);
      end if;

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_LEDCTL, HW.Mac.Ledctl_Default);
      return 0;
   end E1000_Cleanup_Led_Ich8lan;




   --------------------------
   -- E1000_LED_On_ICH8LAN --
   --------------------------

   --  Turn LEDs on.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Turn on the LEDs.


   function E1000_LED_On_ICH8LAN
     (HW : access E1000_HW) return s32
   is
   begin
      if HW.PHY.phy_type = E1000_PHY_IFE
      then
         return E1E_WPHY (HW,
                          IFE_PHY_SPECIAL_CONTROL_LED,
                          IFE_PSCL_PROBE_MODE or IFE_PSCL_PROBE_LEDS_ON);
      end if;

      EW32 (Hw.all, Devices.e1000e.Registers.E1000_LEDCTL, HW.MAC.LEDCTL_Mode2);
      return 0;
   end E1000_LED_On_ICH8LAN;




   ---------------------------
   -- E1000_Led_Off_Ich8lan --
   ---------------------------

   --  Turn LEDs off.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Turn off the LEDs.


   function E1000_Led_Off_Ich8lan
     (HW : access E1000_HW) return s32
   is
   begin
      if HW.Phy.phy_type = E1000_Phy_Ife
      then
         return E1e_Wphy (HW,
                          IFE_PHY_SPECIAL_CONTROL_LED,
                             IFE_PSCL_PROBE_MODE
                          or IFE_PSCL_PROBE_LEDS_OFF);
      end if;

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_LEDCTL, HW.Mac.Ledctl_Mode1);
      return 0;
   end E1000_Led_Off_Ich8lan;




   ----------------------------
   -- E1000_Setup_Led_Pchlan --
   ----------------------------

   --  Configures SW controllable LED.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  This prepares the SW controllable LED for use.


   function E1000_Setup_Led_Pchlan
     (Hw : access E1000_Hw) return s32
   is
   begin
      return E1e_Wphy (Hw,
                       HV_LED_CONFIG,
                       Unsigned_16 (Hw.Mac.Ledctl_Mode1));
   end E1000_Setup_Led_Pchlan;




   ------------------------------
   -- E1000_Cleanup_Led_Pchlan --
   ------------------------------

   --  Restore the default LED operation
   --  *  @hw: pointer to the HW structure
   --  *
   --  *  Return the LED back to the default configuration.


   function E1000_Cleanup_Led_Pchlan
     (HW : access E1000_HW) return S32
   is
   begin
      return E1e_Wphy (HW,
                       HV_LED_CONFIG,
                       u16 (HW.Mac.Ledctl_Default));
   end E1000_Cleanup_Led_Pchlan;





   -------------------------
   -- E1000_LED_On_PCHLAN --
   -------------------------

   --  Turn LEDs on.
   --
   --  *  @hw: pointer to the HW structure
   --  *
   --  *  Turn on the LEDs.


   function E1000_LED_On_PCHLAN
     (HW : access E1000_HW) return s32
   is
      Data : Unsigned_16 := Unsigned_16 (HW.Mac.LEDCTL_Mode2);
      LED  : Unsigned_32;
   begin
      -- If no link, then turn LED on by setting the invert bit
      -- for each LED that's mode is "link_up" in ledctl_mode2.
      --
      if (ER32 (Hw.all, Devices.e1000e.Registers.E1000_STATUS) and E1000_STATUS_LU) = 0
      then
         for I in 0 .. 2
         loop
            LED :=     shift_Right (u32 (Data), Natural (I * 5))
                   and E1000_PHY_LED0_MASK;

            if (LED and E1000_PHY_LED0_MODE_MASK) /= E1000_LEDCTL_MODE_LINK_UP
            then
               goto Continue;
            end if;


            if (LED and E1000_PHY_LED0_IVRT) /= 0
            then
               Data := Data and not shift_Left (E1000_PHY_LED0_IVRT, Natural (I * 5));
            else
               Data := Data or      shift_Left (E1000_PHY_LED0_IVRT, Natural (I * 5));
            end if;


            <<Continue>>
         end loop;
      end if;


      return E1E_WPhy (HW, HV_LED_CONFIG, Data);
   end E1000_LED_On_PCHLAN;





   --------------------------
   -- E1000_Led_Off_Pchlan --
   --------------------------

   --  Turn LEDs off.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Turn off the LEDs.


   function E1000_Led_Off_Pchlan
     (HW : access E1000_HW) return s32
   is
      Data : Unsigned_16 := Unsigned_16 (HW.Mac.Ledctl_Mode1);
      Led  : Unsigned_32;
   begin
      -- If no link, then turn LED off by clearing the invert bit
      -- for each LED that's mode is "link_up" in ledctl_mode1.
      --
      if (Er32 (Hw.all, Devices.e1000e.Registers.E1000_STATUS) and E1000_STATUS_LU) = 0
      then
         for I in 0 .. 2
         loop
            Led := Shift_Right (Unsigned_32 (Data), I * 5) and E1000_PHY_LED0_MASK;

            if (Led and E1000_PHY_LED0_MODE_MASK) /= E1000_LEDCTL_MODE_LINK_UP
            then
               goto Continue;
            end if;

            if (Led and E1000_PHY_LED0_IVRT) /= 0
            then
               Data := Data and not Shift_Left (E1000_PHY_LED0_IVRT, I * 5);
            else
               Data := Data or Shift_Left (E1000_PHY_LED0_IVRT, I * 5);
            end if;


            <<Continue>>
         end loop;
      end if;

      return E1e_Wphy (HW, HV_LED_CONFIG, Data);
   end E1000_Led_Off_Pchlan;




   --------------------------------
   -- E1000_Get_Cfg_Done_Ich8lan --
   --------------------------------

   --  Read config done bit after Full or PHY reset.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Read appropriate register for the config done bit for completion status
   --  *  and configure the PHY through s/w for EEPROM-less parts.
   --  *
   --  *  NOTE: some silicon which is EEPROM-less will fail trying to read the
   --  *  config done bit, so only an error is logged and continues.  If we were
   --  *  to return with error, EEPROM-less silicon would not be able to be reset
   --  *  or change link.


   function E1000_Get_Cfg_Done_Ich8lan
     (Hw : access E1000_Hw) return s32
   is
      Ret_Val : s32         := 0;
      Bank    : Unsigned_32 := 0;
      Status  : Unsigned_32;
      Unused  : s32;

   begin
      Unused := E1000e_Get_Cfg_Done_Generic (Hw);

      -- Wait for indication from h/w that it has completed basic config.
      --
      if Hw.Mac.Mac_Type >= E1000_Ich10lan
      then
         E1000_Lan_Init_Done_Ich8lan (Hw);

      else
         Ret_Val := Devices.e1000e.Media_Access_Control.E1000e_Get_Auto_Rd_Done (Hw);

         if Ret_Val /= 0
         then
            -- When auto config read does not complete, do not
            -- return with an error. This can happen in situations
            -- where there is no eeprom and prevents getting link.
            --
            e_dbg ("Auto Read Done did not complete");
            Ret_Val := 0;
         end if;
      end if;


      -- Clear PHY Reset Asserted bit.
      --
      Status := Er32 (Hw.all, Devices.e1000e.Registers.E1000_STATUS);

      if (Status and E1000_STATUS_PHYRA) /= 0
      then
         Ew32 (Hw.all,
               Devices.e1000e.Registers.E1000_STATUS,
               Status and (not E1000_STATUS_PHYRA));
      else
         e_dbg ("PHY Reset Asserted not set - needs delay");
      end if;


      -- If EEPROM is not marked present, init the IGP 3 PHY manually.
      --
      if Hw.Mac.Mac_Type <= E1000_Ich9lan
      then
         if    ((    Er32 (Hw.all, Devices.e1000e.Registers.E1000_EECD)
                 and E1000_EECD_PRES) = 0)
           and (Hw.Phy.Phy_Type = E1000_Phy_Igp_3)
         then
            Unused := E1000e_Phy_Init_Script_Igp3 (Hw);
         end if;

      else
         if E1000_Valid_Nvm_Bank_Detect_Ich8lan (Hw, Bank) /= 0
         then
            -- Maybe we should do a basic PHY config.
            --
            e_dbg ("EEPROM not present");
            Ret_Val := -E1000_ERR_CONFIG;
         end if;
      end if;


      return Ret_Val;
   end E1000_Get_Cfg_Done_Ich8lan;





   -----------------------------------------
   -- E1000_Power_Down_PHY_Copper_ICH8LAN --
   -----------------------------------------

   --  Remove link during PHY power down.
   --
   --  * @hw: Pointer to the HW structure.
   --  *
   --  * In the case of a PHY power down to save power, or to turn off link during a
   --  * driver unload, or wake on lan is not enabled, remove the link.


   procedure E1000_Power_Down_PHY_Copper_ICH8LAN
     (HW : access E1000_Hw)
   is
   begin
      -- If the management interface is not enabled, then power down.
      --
      if not (   HW.MAC.OPS.Check_MNG_Mode    (HW)
              or HW.PHY.OPS.Check_Reset_Block (HW) /= 0)
      then
         E1000_Power_Down_PHY_Copper (HW);
      end if;
   end E1000_Power_Down_PHY_Copper_ICH8LAN;





   ----------------------------------
   -- E1000_Clear_HW_Cntrs_ICH8LAN --
   ----------------------------------

   --  Clear statistical counters.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Clears hardware counters specific to the silicon family and calls
   --  *  clear_hw_cntrs_generic to clear all general purpose counters.


   procedure E1000_Clear_HW_Cntrs_ICH8LAN
     (HW : access E1000_HW)
   is
      PHY_Data : aliased Interfaces.Unsigned_16;
      Ret_Val  :         s32;
      Unused   :         u32;
      Unused2  :         Interfaces.Integer_32;

   begin
      Devices.e1000e.Media_Access_Control.E1000E_Clear_HW_Cntrs_Base (HW);

      -- Read and discard values from these registers.
      --
      Unused := ER32 (Hw.all, Devices.e1000e.Registers.E1000_ALGNERRC);
      Unused := ER32 (Hw.all, Devices.e1000e.Registers.E1000_RXERRC);
      Unused := ER32 (Hw.all, Devices.e1000e.Registers.E1000_TNCRS);
      Unused := ER32 (Hw.all, Devices.e1000e.Registers.E1000_CEXTERR);
      Unused := ER32 (Hw.all, Devices.e1000e.Registers.E1000_TSCTC);
      Unused := ER32 (Hw.all, Devices.e1000e.Registers.E1000_TSCTFC);

      Unused := ER32 (Hw.all, Devices.e1000e.Registers.E1000_MGTPRC);
      Unused := ER32 (Hw.all, Devices.e1000e.Registers.E1000_MGTPDC);
      Unused := ER32 (Hw.all, Devices.e1000e.Registers.E1000_MGTPTC);

      Unused := ER32 (Hw.all, Devices.e1000e.Registers.E1000_IAC);
      Unused := ER32 (Hw.all, Devices.e1000e.Registers.E1000_ICRXOC);

      -- Clear PHY statistics registers.
      --
      if   HW.PHY.PHY_Type = E1000_PHY_82578
        or HW.PHY.PHY_Type = E1000_PHY_82579
        or HW.PHY.PHY_Type = E1000_PHY_I217
        or HW.PHY.PHY_Type = E1000_PHY_82577
      then
         Ret_Val := HW.PHY.Ops.Acquire (HW);

         if Ret_Val /= 0
         then
            return;
         end if;


         Ret_Val := HW.PHY.Ops.Set_Page (HW,
                                         shift_Left (HV_STATS_PAGE,
                                                     IGP_PAGE_SHIFT));
         if Ret_Val /= 0
         then
            goto Release;
         end if;

         Unused2 := HW.PHY.Ops.Read_Reg_Page (HW, HV_SCC_UPPER,     PHY_Data'unchecked_Access);
         Unused2 := HW.PHY.Ops.Read_Reg_Page (HW, HV_SCC_LOWER,     PHY_Data'unchecked_Access);
         Unused2 := HW.PHY.Ops.Read_Reg_Page (HW, HV_ECOL_UPPER,    PHY_Data'unchecked_Access);
         Unused2 := HW.PHY.Ops.Read_Reg_Page (HW, HV_ECOL_LOWER,    PHY_Data'unchecked_Access);
         Unused2 := HW.PHY.Ops.Read_Reg_Page (HW, HV_MCC_UPPER,     PHY_Data'unchecked_Access);
         Unused2 := HW.PHY.Ops.Read_Reg_Page (HW, HV_MCC_LOWER,     PHY_Data'unchecked_Access);
         Unused2 := HW.PHY.Ops.Read_Reg_Page (HW, HV_LATECOL_UPPER, PHY_Data'unchecked_Access);
         Unused2 := HW.PHY.Ops.Read_Reg_Page (HW, HV_LATECOL_LOWER, PHY_Data'unchecked_Access);
         Unused2 := HW.PHY.Ops.Read_Reg_Page (HW, HV_COLC_UPPER,    PHY_Data'unchecked_Access);
         Unused2 := HW.PHY.Ops.Read_Reg_Page (HW, HV_COLC_LOWER,    PHY_Data'unchecked_Access);
         Unused2 := HW.PHY.Ops.Read_Reg_Page (HW, HV_DC_UPPER,      PHY_Data'unchecked_Access);
         Unused2 := HW.PHY.Ops.Read_Reg_Page (HW, HV_DC_LOWER,      PHY_Data'unchecked_Access);
         Unused2 := HW.PHY.Ops.Read_Reg_Page (HW, HV_TNCRS_UPPER,   PHY_Data'unchecked_Access);
         Unused2 := HW.PHY.Ops.Read_Reg_Page (HW, HV_TNCRS_LOWER,   PHY_Data'unchecked_Access);


         <<Release>>

         HW.PHY.Ops.Release (HW);
      end if;
   end E1000_Clear_HW_Cntrs_ICH8LAN;







   ------------------------
   -- Public Subprograms --
   ------------------------


   --------------------------------------
   -- E1000e_Write_Protect_NVM_ICH8LAN --
   --------------------------------------

   --  Make the NVM read-only.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  To prevent malicious write/erase of the NVM, set it to be read-only
   --  *  so that the hardware ignores all write/erase cycles of the NVM via
   --  *  the flash control registers.  The shadow-ram copy of the NVM will
   --  *  still be updated, however any updates to this copy will not stick
   --  *  across driver reloads.


   procedure E1000e_Write_Protect_NVM_ICH8LAN
     (HW : access E1000_HW)
   is
      NVM    : E1000_NVM_Info.item renames HW.NVM;
      PR0    : ICH8_Flash_Protected_Range;
      HSFSTS : ICH8_HWS_Flash_Status;
      GFPREG : Unsigned_32;
      Unused : s32;

   begin
      Unused := NVM.Ops.Acquire (HW);
      GFPREG := ER32Flash (Hw, ICH_FLASH_GFPREG);

      -- Write-protect GbE Sector of NVM.
      --
      PR0.Regval         := ER32Flash (Hw, ICH_FLASH_PR0);
      PR0.my_Range.Base  := GFPREG and FLASH_GFPREG_BASE_MASK;
      PR0.my_Range.Limit := shift_Right (GFPREG, 16) and FLASH_GFPREG_BASE_MASK;
      PR0.my_Range.WPE   := True;

      EW32Flash (Hw, ICH_FLASH_PR0, PR0.Regval);

      -- Lock down a subset of GbE Flash Control Registers, e.g.
      -- PR0 to prevent the write-protection from being lifted.
      -- Once FLOCKDN is set, the registers protected by it cannot
      -- be written until FLOCKDN is cleared by a hardware reset.
      --
      HSFSTS.REGVAL             := ER16Flash (Hw, ICH_FLASH_HSFSTS);
      HSFSTS.HSF_Status.FLOCKDN := True;

      EW32Flash (Hw, ICH_FLASH_HSFSTS, u32 (HSFSTS.REGVAL));

      NVM.Ops.Release (HW);
   end E1000e_Write_Protect_NVM_ICH8LAN;





   -------------------------------------------
   -- Set_Kmrn_Lock_Loss_Workaround_Ich8lan --
   -------------------------------------------

   --  Set Kumeran workaround state.
   --
   --  *  @hw:    Pointer to the HW structure.
   --  *  @state: Boolean value used to set the current Kumeran workaround state.
   --  *
   --  *  If ICH8, set the current Kumeran workaround state (enabled - true
   --  *  /disabled - false).


   procedure e1000e_Set_Kmrn_Lock_Loss_Workaround_Ich8lan
     (hw    : access e1000_hw;
      state : in     Boolean)
   is
   begin
      if HW.Mac.mac_type /= e1000_ich8lan
      then
         e_dbg ("Workaround applies to ICH8 only.");
         return;
      end if;

      HW.Dev_Spec.Ich8lan.Kmrn_Lock_Loss_Workaround_Enabled := State;
   end e1000e_Set_Kmrn_Lock_Loss_Workaround_Ich8lan;





   --------------------------------------------------
   -- e1000e_igp3_phy_powerdown_workaround_ich8lan --
   --------------------------------------------------

   --  Power down workaround on D3.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Workaround for 82566 power-down on D3 entry:
   --  *    1) disable gigabit link
   --  *    2) write VR power-down enable
   --  *    3) read it back
   --  *  Continue if successful, else issue LCD reset and repeat


   procedure e1000e_igp3_phy_powerdown_workaround_ich8lan
     (HW : access E1000_HW)
   is
      Reg    :         Unsigned_32;
      Data   : aliased Unsigned_16;
      Retry  :         Unsigned_8 := 0;
      Unused :         s32;

   begin
      if HW.PHY.phy_type /= E1000_PHY_IGP_3
      then
         return;
      end if;

      -- Try the workaround twice (if needed).
      --
      loop
         -- Disable link.
         --
         Reg := ER32 (Hw.all, Devices.e1000e.Registers.E1000_PHY_CTRL);
         Reg := Reg or (   E1000_PHY_CTRL_GBE_DISABLE
                        or E1000_PHY_CTRL_NOND0A_GBE_DISABLE);
         EW32 (Hw.all, Devices.e1000e.Registers.E1000_PHY_CTRL, Reg);

         -- Call gig speed drop workaround on Gig disable before
         -- accessing any PHY registers.
         --
         if HW.MAC.mac_type = E1000_ICH8LAN
         then
            E1000e_Gig_Downshift_Workaround_ICH8LAN (HW);
         end if;

         -- Write VR power-down enable.
         --
         Unused := E1E_RPHY (HW, IGP3_VR_CTRL, Data'unchecked_Access);
         Data   := Data and (not IGP3_VR_CTRL_DEV_POWERDOWN_MODE_MASK);
         Unused := E1E_WPHY (HW, IGP3_VR_CTRL, Data or IGP3_VR_CTRL_MODE_SHUTDOWN);

         -- Read it back and test.
         --
         Unused := E1E_RPHY (HW, IGP3_VR_CTRL, Data'unchecked_Access);
         Data   := Data and IGP3_VR_CTRL_DEV_POWERDOWN_MODE_MASK;

         if (Data = IGP3_VR_CTRL_MODE_SHUTDOWN) or (Retry > 0)
         then
            exit;
         end if;

         -- Issue PHY reset and repeat at most one more time.
         --
         Reg := ER32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);
         EW32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, Reg or E1000_CTRL_PHY_RST);

         Retry := Retry + 1;
         exit when Retry > 1;
      end loop;
   end e1000e_igp3_phy_powerdown_workaround_ich8lan;




   ---------------------------------------------
   -- E1000e_Gig_Downshift_Workaround_Ich8lan --
   ---------------------------------------------

   --  WoL from S5 stops working.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Steps to take when dropping from 1Gb/s (eg. link cable removal (LSC),
   --  *  LPLU, Gig disable, MDIC PHY reset):
   --  *    1) Set Kumeran Near-end loopback
   --  *    2) Clear Kumeran Near-end loopback
   --  *  Should only be called for ICH8[m] devices with any 1G Phy.


   procedure E1000e_Gig_Downshift_Workaround_Ich8lan
     (HW : access E1000_HW)
   is
      Ret_Val  :         s32;
      Reg_Data : aliased Unsigned_16;
      Unused   :         s32;

   begin
      if   HW.Mac.mac_type /= E1000_Ich8lan
        or HW.Phy.phy_type  = E1000_Phy_Ife
      then
         return;
      end if;


      Ret_Val := E1000e_Read_Kmrn_Reg (HW,
                                       E1000_KMRNCTRLSTA_DIAG_OFFSET,
                                       Reg_Data'unchecked_Access);
      if Ret_Val /= 0
      then
         return;
      end if;


      Reg_Data := Reg_Data or E1000_KMRNCTRLSTA_DIAG_NELPBK;
      Ret_Val  := E1000e_Write_Kmrn_Reg (HW,
                                         E1000_KMRNCTRLSTA_DIAG_OFFSET,
                                         Reg_Data);
      if Ret_Val /= 0
      then
         return;
      end if;


      Reg_Data := Reg_Data and (not E1000_KMRNCTRLSTA_DIAG_NELPBK);
      Unused   := E1000e_Write_Kmrn_Reg (HW,
                                         E1000_KMRNCTRLSTA_DIAG_OFFSET,
                                         Reg_Data);
   end E1000e_Gig_Downshift_Workaround_Ich8lan;





   ---------------------------------------
   -- E1000_Suspend_Workarounds_Ich8lan --
   ---------------------------------------

   --  Workarounds needed during S0->Sx.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  During S0 to Sx transition, it is possible the link remains at gig
   --  *  instead of negotiating to a lower speed.  Before going to Sx, set
   --  *  'Gig Disable' to force link speed negotiation to a lower speed based on
   --  *  the LPLU setting in the NVM or custom setting.  For PCH and newer parts,
   --  *  the OEM bits PHY register (LED, GbE disable and LPLU configurations) also
   --  *  needs to be written.
   --  *  Parts that support (and are linked to a partner which support) EEE in
   --  *  100Mbps should disable LPLU since 100Mbps w/ EEE requires less power
   --  *  than 10Mbps w/o EEE.


   procedure E1000_Suspend_Workarounds_Ich8lan
     (HW : access E1000_HW)
   is
      Phy_Ctrl : Unsigned_32;
      Ret_Val  : s32;
      Unused   : s32;

   begin
      Phy_Ctrl := Er32 (Hw.all, Devices.e1000e.Registers.E1000_PHY_CTRL);
      Phy_Ctrl := Phy_Ctrl or E1000_PHY_CTRL_GBE_DISABLE;

      if HW.Phy.phy_type = E1000_Phy_I217
      then
         declare
            Phy_Reg    : aliased  Unsigned_16;
            Device_Id  : constant Unsigned_16 := HW.Adapter.Pdev.Device;
         begin
            if   Device_Id        = E1000_DEV_ID_PCH_LPTLP_I218_LM
              or Device_Id        = E1000_DEV_ID_PCH_LPTLP_I218_V
              or Device_Id        = E1000_DEV_ID_PCH_I218_LM3
              or Device_Id        = E1000_DEV_ID_PCH_I218_V3
              or HW.Mac.mac_type >= E1000_Pch_Spt
            then
               declare
                  Fextnvm6 : Unsigned_32;
               begin
                  Fextnvm6 := Er32 (Hw.all, Devices.e1000e.Registers.E1000_FEXTNVM6);
                  Ew32 (Hw.all, Devices.e1000e.Registers.E1000_FEXTNVM6, Fextnvm6 and (not E1000_FEXTNVM6_REQ_PLL_CLK));
               end;
            end if;

            Ret_Val := HW.Phy.Ops.Acquire (HW);

            if Ret_Val /= 0
            then
               goto Out_Label;
            end if;

            if not HW.Dev_Spec.Ich8lan.Eee_Disable
            then
               declare
                  Eee_Advert : aliased Unsigned_16;
               begin
                  Ret_Val := E1000_Read_Emi_Reg_Locked (HW, I217_EEE_ADVERTISEMENT, Eee_Advert'unchecked_Access);

                  if Ret_Val /= 0
                  then
                     goto Release_Label;
                  end if;

                  if    (Eee_Advert                         and I82579_EEE_100_SUPPORTED) /= 0
                    and (HW.Dev_Spec.Ich8lan.Eee_Lp_Ability and I82579_EEE_100_SUPPORTED) /= 0
                    and (HW.Phy.Autoneg_Advertised          and ADVERTISE_100_FULL)       /= 0
                  then
                     Phy_Ctrl := Phy_Ctrl and (not (   E1000_PHY_CTRL_D0A_LPLU
                                                    or E1000_PHY_CTRL_NOND0A_LPLU));

                     Unused  := E1e_Rphy_Locked (HW, I217_LPI_GPIO_CTRL, Phy_Reg'unchecked_Access);
                     Phy_Reg := Phy_Reg or I217_LPI_GPIO_CTRL_AUTO_EN_LPI;
                     Unused  := E1e_Wphy_Locked (HW, I217_LPI_GPIO_CTRL, Phy_Reg);
                  end if;
               end;
            end if;

            declare
               Fwsm : aliased Unsigned_32;
            begin
               Fwsm := Er32 (Hw.all, Devices.e1000e.Registers.E1000_FWSM);

               if (Fwsm and E1000_ICH_FWSM_FW_VALID) = 0
               then
                  Unused  := E1e_Rphy_Locked (HW, I217_PROXY_CTRL, Phy_Reg'unchecked_Access);
                  Phy_Reg := Phy_Reg or I217_PROXY_CTRL_AUTO_DISABLE;
                  Unused  := E1e_Wphy_Locked (HW, I217_PROXY_CTRL, Phy_Reg);

                  Unused  := E1e_Rphy_Locked (HW, I217_SxCTRL, Phy_Reg'unchecked_Access);
                  Phy_Reg := Phy_Reg or I217_SxCTRL_ENABLE_LPI_RESET;
                  Unused  := E1e_Wphy_Locked (HW, I217_SxCTRL, Phy_Reg);

                  Unused  := E1e_Rphy_Locked (HW, I217_MEMPWR, Phy_Reg'unchecked_Access);
                  Phy_Reg := Phy_Reg and (not I217_MEMPWR_DISABLE_SMB_RELEASE);
                  Unused  := E1e_Wphy_Locked (HW, I217_MEMPWR, Phy_Reg);
               end if;
            end;

            Unused  := E1e_Rphy_Locked (HW, I217_CGFREG, Phy_Reg'unchecked_Access);
            Phy_Reg := Phy_Reg or I217_CGFREG_ENABLE_MTA_RESET;
            Unused  := E1e_Wphy_Locked (HW, I217_CGFREG, Phy_Reg);

            <<Release_Label>>

            HW.Phy.Ops.Release (HW);
         end;
      end if;


      <<Out_Label>>

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_PHY_CTRL, Phy_Ctrl);

      if HW.Mac.mac_type = E1000_Ich8lan
      then
         E1000e_Gig_Downshift_Workaround_Ich8lan (HW);
      end if;

      if HW.Mac.mac_type >= E1000_Pchlan
      then
         Unused := E1000_Oem_Bits_Config_Ich8lan (HW, False);

         if HW.Mac.mac_type = E1000_Pchlan
         then
            Unused := E1000e_Phy_Hw_Reset_Generic (HW);
         end if;

         Ret_Val := HW.Phy.Ops.Acquire (HW);

         if Ret_Val = 0
         then
            Unused := E1000_Write_Smbus_Addr (HW);
            HW.Phy.Ops.Release (HW);
         end if;
      end if;
   end E1000_Suspend_Workarounds_Ich8lan;





   -------------------------------------
   -- E1000_Resume_Workarounds_Pchlan --
   -------------------------------------

   --  Workarounds needed during Sx->S0.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  During Sx to S0 transitions on non-managed devices or managed devices
   --  *  on which PHY resets are not blocked, if the PHY registers cannot be
   --  *  accessed properly by the s/w toggle the LANPHYPC value to power cycle
   --  *  the PHY.
   --  *  On i217, setup Intel Rapid Start Technology.


   procedure E1000_Resume_Workarounds_Pchlan
     (HW : access E1000_HW)
   is
      Ret_Val :         s32;
      Phy_Reg : aliased Unsigned_16;
      Unused  :         s32;

   begin
      if HW.Mac.Mac_Type < E1000_Pch2lan
      then
         return;
      end if;


      Ret_Val := E1000_Init_Phy_Workarounds_Pchlan (HW);

      if Ret_Val /= 0
      then
         e_dbg ("Failed to init PHY flow ret_val =" & Ret_Val'Image);
         return;
      end if;


      -- For i217 Intel Rapid Start Technology support when the system
      -- is transitioning from Sx and no manageability engine is present
      -- configure SMBus to restore on reset, disable proxy, and enable
      -- the reset on MTA (Multicast table array).
      --
      if HW.Phy.Phy_Type = E1000_Phy_I217
      then
         Ret_Val := HW.Phy.Ops.Acquire (HW);

         if Ret_Val /= 0
         then
            e_dbg ("Failed to setup iRST");
            return;
         end if;


         -- Clear Auto Enable LPI after link up.
         --
         Unused  := E1e_Rphy_Locked (HW, I217_LPI_GPIO_CTRL, Phy_Reg'unchecked_Access);
         Phy_Reg := Phy_Reg and (not I217_LPI_GPIO_CTRL_AUTO_EN_LPI);
         Unused  := E1e_Wphy_Locked (HW, I217_LPI_GPIO_CTRL, Phy_Reg);

         if (Er32 (Hw.all, Devices.e1000e.Registers.E1000_FWSM) and E1000_ICH_FWSM_FW_VALID) = 0
         then
            -- Restore clear on SMB if no manageability engine
            -- is present.
            --
            Ret_Val := E1e_Rphy_Locked (HW, I217_MEMPWR, Phy_Reg'unchecked_Access);

            if Ret_Val /= 0
            then
               goto Release;
            end if;

            Phy_Reg := Phy_Reg or I217_MEMPWR_DISABLE_SMB_RELEASE;
            Unused  := E1e_Wphy_Locked (HW, I217_MEMPWR, Phy_Reg);

            -- Disable Proxy.
            --
            Unused := E1e_Wphy_Locked (HW, I217_PROXY_CTRL, 0);
         end if;


         -- Enable reset on MTA.
         --
         Ret_Val := E1e_Rphy_Locked (HW, I217_CGFREG, Phy_Reg'unchecked_Access);

         if Ret_Val /= 0
         then
            goto Release;
         end if;

         Phy_Reg := Phy_Reg and (not I217_CGFREG_ENABLE_MTA_RESET);
         Unused  := E1e_Wphy_Locked (HW, I217_CGFREG, Phy_Reg);


         <<Release>>

         if Ret_Val /= 0
         then
            e_dbg ("Error" & Ret_Val'Image & " in resume workarounds");
         end if;

         HW.Phy.Ops.Release (HW);
      end if;
   end E1000_Resume_Workarounds_Pchlan;








   --------------------------------
   -- e1000_Configure_K1_Ich8lan --
   --------------------------------

   --  Configure K1 power state.
   --
   --  *  @hw:        Pointer to the HW structure.
   --  *  @k1_enable: K1 state to configure.
   --  *
   --  *  Configure the K1 power state based on the provided parameter.
   --  *  Assumes semaphore already acquired.
   --  *
   --  *  Success returns 0, Failure returns -E1000_ERR_PHY (-2).


   function e1000_Configure_K1_Ich8lan
     (Hw        : access E1000_Hw;
      K1_Enable : in     Boolean) return s32
   is
      Ret_Val  :         s32         := 0;
      Ctrl_Reg :         Unsigned_32 := 0;
      Ctrl_Ext :         Unsigned_32 := 0;
      Reg      :         Unsigned_32 := 0;
      Kmrn_Reg : aliased Unsigned_16 := 0;

   begin
      Ret_Val := E1000e_Read_Kmrn_Reg_Locked (Hw,
                                              E1000_KMRNCTRLSTA_K1_CONFIG,
                                              Kmrn_Reg'unchecked_Access);
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      if K1_Enable
      then
         Kmrn_Reg := Kmrn_Reg or E1000_KMRNCTRLSTA_K1_ENABLE;
      else
         Kmrn_Reg := Kmrn_Reg and (not E1000_KMRNCTRLSTA_K1_ENABLE);
      end if;


      Ret_Val := E1000e_Write_Kmrn_Reg_Locked (Hw,
                                               E1000_KMRNCTRLSTA_K1_CONFIG,
                                               Kmrn_Reg);
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;

      delay Duration (Float (20) / 1_000_000.0);

      Ctrl_Ext := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT);
      Ctrl_Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);

      Reg := Ctrl_Reg and (not (E1000_CTRL_SPD_1000 or E1000_CTRL_SPD_100));
      Reg := Reg or E1000_CTRL_FRCSPD;

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL,     Reg);
      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT, Ctrl_Ext or E1000_CTRL_EXT_SPD_BYPS);
      E1E_Flush (Hw);

      delay Duration (Float (20) / 1_000_000.0);

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL,     Ctrl_Reg);
      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT, Ctrl_Ext);
      E1E_Flush (Hw);

      delay Duration (Float (20) / 1_000_000.0);

      return 0;
   end e1000_Configure_K1_Ich8lan;




   ----------------------------------------
   -- E1000_Copy_Rx_Addrs_To_Phy_Ich8lan --
   ----------------------------------------

   --  Copy Rx addresses from MAC to PHY.
   --
   --  *  @hw:   Pointer to the HW structure.


   procedure E1000_Copy_Rx_Addrs_To_Phy_Ich8lan
     (Hw : access E1000_Hw)
   is

      Mac_Reg :         Unsigned_32;
      Phy_Reg : aliased Unsigned_16 := 0;
      Ret_Val :         s32;
      Unused  :         s32;

   begin
      Ret_Val := Hw.Phy.Ops.Acquire (Hw);

      if Ret_Val /= 0
      then
         return;
      end if;


      Ret_Val := E1000_Enable_Phy_Wakeup_Reg_Access_Bm (Hw,
                                                        Phy_Reg'unchecked_Access);
      if Ret_Val /= 0
      then
         goto Release;
      end if;


      -- Copy both RAL/H (rar_entry_count) and SHRAL/H to PHY.
      --
      for I in 0 .. u32 (Hw.Mac.Rar_Entry_Count - 1)
      loop
         Mac_Reg := Er32 (Hw.all,
                          Devices.e1000e.Registers.E1000_RAL (I));

         Unused  := Hw.Phy.Ops.Write_Reg_Page (Hw,
                                               BM_RAR_L (I),
                                               Unsigned_16 (Mac_Reg and 16#FFFF#));

         Unused  := Hw.Phy.Ops.Write_Reg_Page (Hw,
                                               BM_RAR_M (I),
                                               Unsigned_16 ((shift_Right (Mac_Reg, 16) and 16#FFFF#)));

         Mac_Reg := Er32 (Hw.all,
                          Devices.e1000e.Registers.E1000_RAH (I));

         Unused  := Hw.Phy.Ops.Write_Reg_Page (Hw,
                                               BM_RAR_H (I),
                                               Unsigned_16 (Mac_Reg and 16#FFFF#));

         Unused  := Hw.Phy.Ops.Write_Reg_Page (Hw,
                                               BM_RAR_CTRL (I),
                                               Unsigned_16 (Shift_Right (Mac_Reg and E1000_RAH_AV, 16)));
      end loop;


      Unused := E1000_Disable_Phy_Wakeup_Reg_Access_Bm (Hw, Phy_Reg'unchecked_Access);


      <<Release>>

      Hw.Phy.Ops.Release (Hw);
   end E1000_Copy_Rx_Addrs_To_Phy_Ich8lan;




   ---------------------------------------
   -- E1000_Lv_Jumbo_Workaround_Ich8lan --
   ---------------------------------------

   --  Required for jumbo frame operation with 82579 PHY.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @enable: Flag to enable/disable workaround when enabling/disabling jumbos.


   function E1000_Lv_Jumbo_Workaround_Ich8lan
     (Hw     : access E1000_Hw;
      Enable : in     Boolean) return s32
   is
      Ret_Val        :         s32 := 0;
      Phy_Reg_Value  : aliased u16;
      Data           : aliased Unsigned_16;
      Mac_Reg        :         Unsigned_32;
      Unused         :         s32;

      subtype Eth_Addr is String (1 .. 6);

   begin
      if Hw.Mac.mac_Type < E1000_Pch2lan
      then
         return 0;
      end if;


      -- Disable Rx path while enabling/disabling workaround.
      --
      Unused := E1e_Rphy (Hw,
                          PHY_REG (769, 20),
                          Phy_Reg_Value'unchecked_Access);

      Ret_Val := E1e_Wphy (Hw,
                           PHY_REG (769, 20),
                           Phy_Reg_Value or Shift_Left (1, 14));
      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      if Enable
      then
         -- Write Rx addresses and initial CRC values to the MAC.
         --
         for I in 0 .. u32 (Hw.Mac.Rar_Entry_Count) - 1
         loop
            declare
               Mac_Addr : u8_array (0 .. ETH_ALEN - 1) := [others => 0];
               Addr_High,
               Addr_Low : Unsigned_32;
            begin
               Addr_High := Er32 (Hw.all,
                                  Devices.e1000e.Registers.E1000_RAH (I));

               if (Addr_High and E1000_RAH_AV) = 0
               then
                  goto Continue;
               end if;

               Addr_Low     := Er32 (Hw.all,
                                     Devices.e1000e.Registers.E1000_RAL (I));

               Mac_Addr (0) := u8 (Addr_Low                   and 16#FF#);
               Mac_Addr (1) := u8 (shift_Right (Addr_Low,  8) and 16#FF#);
               Mac_Addr (2) := u8 (shift_Right (Addr_Low, 16) and 16#FF#);
               Mac_Addr (3) := u8 (shift_Right (Addr_Low, 24) and 16#FF#);
               Mac_Addr (4) := u8 (Addr_High                  and 16#FF#);
               Mac_Addr (5) := u8 (shift_Right (Addr_High, 8) and 16#FF#);

               Ew32 (Hw.all,
                     E1000_PCH_RAICC (Integer_Address (I)),
                     not u32 (Ether_Crc_Le (ETH_ALEN,                              -- TODO: Check this !
                       Mac_Addr)));
            end;

            <<Continue>>
         end loop;


         -- Write Rx addresses to the PHY.
         --
         E1000_Copy_Rx_Addrs_To_Phy_Ich8lan (Hw);

         -- Enable jumbo frame workaround in the MAC.
         --
         Mac_Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_FFLT_DBG);
         Mac_Reg := Mac_Reg and not Shift_Left (1, 14);
         Mac_Reg := Mac_Reg or Shift_Left (7, 15);

         Ew32 (Hw.all, Devices.e1000e.Registers.E1000_FFLT_DBG, Mac_Reg);

         Mac_Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_RCTL);
         Mac_Reg := Mac_Reg or E1000_RCTL_SECRC;

         Ew32 (Hw.all, Devices.e1000e.Registers.E1000_RCTL, Mac_Reg);

         Ret_Val := E1000e_Read_Kmrn_Reg (Hw,
                                          E1000_KMRNCTRLSTA_CTRL_OFFSET,
                                          Data'unchecked_Access);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Ret_Val := E1000e_Write_Kmrn_Reg (Hw,
                                           E1000_KMRNCTRLSTA_CTRL_OFFSET,
                                           Data or Shift_Left (1, 0));
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Ret_Val := E1000e_Read_Kmrn_Reg (Hw,
                                          E1000_KMRNCTRLSTA_HD_CTRL,
                                          Data'unchecked_Access);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Data    :=    (Data and not Shift_Left (16#F#, 8))
           or Shift_Left (16#B#, 8);

         Ret_Val := E1000e_Write_Kmrn_Reg (Hw,
                                           E1000_KMRNCTRLSTA_HD_CTRL,
                                           Data);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         -- Enable jumbo frame workaround in the PHY.
         --
         Unused := E1e_Rphy (Hw,
                             PHY_REG (769, 23),
                             Data'unchecked_Access);

         Data    :=    (Data and not Shift_Left (16#7F#, 5))
           or Shift_Left (16#37#, 5);

         Ret_Val := E1e_Wphy (Hw,
                              PHY_REG (769, 23),
                              Data);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Unused := E1e_Rphy (Hw,
                             PHY_REG (769, 16),
                             Data'unchecked_Access);

         Data    := Data and not Shift_Left (1, 13);
         Ret_Val := E1e_Wphy (Hw,
                              PHY_REG (769, 16),
                              Data);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Unused := E1e_Rphy (Hw,
                             PHY_REG (776, 20),
                             Data'unchecked_Access);

         Data    :=    (Data and not shift_Left (16#3FF#, 2))
           or shift_Left (E1000_TX_PTR_GAP, 2);
         Ret_Val := E1e_Wphy (Hw,
                              PHY_REG (776, 20),
                              Data);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Ret_Val := E1e_Wphy (Hw,
                              PHY_REG (776, 23),
                              16#F100#);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Unused := E1e_Rphy (Hw,
                             HV_PM_CTRL,
                             Data'unchecked_Access);
         Ret_Val := E1e_Wphy (Hw,
                              HV_PM_CTRL,
                              Data or Shift_Left (1, 10));
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;

      else
         -- Write MAC register values back to h/w defaults.
         --
         Mac_Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_FFLT_DBG);
         Mac_Reg := Mac_Reg and not Shift_Left (16#F#, 14);

         Ew32 (Hw.all, Devices.e1000e.Registers.E1000_FFLT_DBG, Mac_Reg);

         Mac_Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_RCTL);
         Mac_Reg := Mac_Reg and not E1000_RCTL_SECRC;

         Ew32 (Hw.all, Devices.e1000e.Registers.E1000_RCTL, Mac_Reg);

         Ret_Val := E1000e_Read_Kmrn_Reg (Hw,
                                          E1000_KMRNCTRLSTA_CTRL_OFFSET,
                                          Data'unchecked_Access);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Ret_Val := E1000e_Write_Kmrn_Reg (Hw,
                                           E1000_KMRNCTRLSTA_CTRL_OFFSET,
                                           Data and not Shift_Left (1, 0));
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Ret_Val := E1000e_Read_Kmrn_Reg (Hw,
                                          E1000_KMRNCTRLSTA_HD_CTRL,
                                          Data'unchecked_Access);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Data    := (Data and not Shift_Left (16#F#, 8)) or Shift_Left (16#B#, 8);
         Ret_Val := E1000e_Write_Kmrn_Reg (Hw,
                                           E1000_KMRNCTRLSTA_HD_CTRL,
                                           Data);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         -- Write PHY register values back to h/w defaults.
         --
         Unused := E1e_Rphy (Hw,
                             PHY_REG (769, 23),
                             Data'unchecked_Access);

         Data    := Data and not shift_Left (16#7F#, 5);
         Ret_Val := E1e_Wphy (Hw,
                              PHY_REG (769, 23),
                              Data);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Unused := E1e_Rphy (Hw,
                             PHY_REG (769, 16),
                             Data'unchecked_Access);

         Data    := Data or Shift_Left (1, 13);
         Ret_Val := E1e_Wphy (Hw,
                              PHY_REG (769, 16),
                              Data);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Unused := E1e_Rphy (Hw,
                             PHY_REG (776, 20),
                             Data'unchecked_Access);

         Data    :=    (Data and not shift_Left (16#3FF#, 2))
           or shift_Left (8, 2);

         Ret_Val := E1e_Wphy (Hw,
                              PHY_REG (776, 20),
                              Data);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Ret_Val := E1e_Wphy (Hw,
                              PHY_REG (776, 23),
                              16#7E00#);
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         Unused  := E1e_Rphy (Hw,
                              HV_PM_CTRL,
                              Data'unchecked_Access);

         Ret_Val := E1e_Wphy (Hw,
                              HV_PM_CTRL,
                              Data and not Shift_Left (1, 10));
         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;

      end if;


      -- Re-enable Rx path after enabling/disabling workaround.
      --
      return E1e_Wphy (Hw,
                       PHY_REG (769, 20),
                       Phy_Reg_Value and not Bit (14));
   end E1000_Lv_Jumbo_Workaround_Ich8lan;




   -------------------------------
   -- E1000_Read_EMI_Reg_Locked --
   -------------------------------

   --  Read Extended Management Interface register.
   --  *  @hw:   Pointer to the HW structure.
   --  *  @addr: EMI address to program.
   --  *  @data: Value to be read from the EMI address.
   --  *
   --  *  Assumes the SW/FW/HW Semaphore is already acquired.

   function E1000_Read_EMI_Reg_Locked
     (HW   : access E1000_HW;
      Addr : in     Unsigned_16;
      Data : in     u16_Pointer) return s32
   is
   begin
      return E1000_Access_EMI_Reg_Locked (HW, Addr, Data, Read => True);
   end E1000_Read_EMI_Reg_Locked;




   -------------------------------
   -- E1000_Write_EMI_Reg_Locked --
   -------------------------------

   --  Write Extended Management Interface register.
   --  *  @hw:   Pointer to the HW structure.
   --  *  @addr: EMI address to program.
   --  *  @data: Value to be written to the EMI address.
   --  *
   --  *  Assumes the SW/FW/HW Semaphore is already acquired.

   function E1000_Write_EMI_Reg_Locked
     (HW   : access E1000_HW;
      Addr : in     Unsigned_16;
      Data : in     u16) return s32
   is
   begin
      return E1000_Access_EMI_Reg_Locked (HW,
                                          Addr,
                                          Data'unrestricted_Access,
                                          Read => False);
   end E1000_Write_EMI_Reg_Locked;





   --------------------------
   -- E1000_Set_EEE_PCHLAN --
   --------------------------

   --  Enable/disable EEE support.
   --  *  @hw: pointer to the HW structure
   --  *
   --  *  Enable/disable EEE based on setting in dev_spec structure, the duplex of
   --  *  the link and the EEE capabilities of the link partner.  The LPI Control
   --  *  register bits will remain set only if/when link is up.
   --  *
   --  *  EEE LPI must not be asserted earlier than one second after link is up.
   --  *  On 82579, EEE LPI should not be enabled until such time otherwise there
   --  *  can be link issues with some switches.  Other devices can have EEE LPI
   --  *  enabled immediately upon link up since they have a timer in hardware which
   --  *  prevents LPI from being asserted too early.

   function E1000_Set_EEE_PCHLAN
     (HW : access E1000_HW) return S32
   is
      Unused,
      Ret_Val  :         S32;

      LPA,
      PCS_Status,
      Adv_Addr :         U16;

      Adv,
      Data ,
      LPI_Ctrl : aliased u16;

   begin
      case HW.PHY.PHY_Type
      is
         when E1000_PHY_82579 =>
            LPA        := I82579_EEE_LP_ABILITY;
            PCS_Status := I82579_EEE_PCS_STATUS;
            Adv_Addr   := I82579_EEE_ADVERTISEMENT;

         when E1000_PHY_I217 =>
            LPA        := I217_EEE_LP_ABILITY;
            PCS_Status := I217_EEE_PCS_STATUS;
            Adv_Addr   := I217_EEE_ADVERTISEMENT;

         when others =>
            return 0;
      end case;


      Ret_Val := HW.PHY.Ops.Acquire (HW);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      Ret_Val := E1E_RPHY_Locked (HW,
                                  I82579_LPI_CTRL,
                                  LPI_Ctrl'unchecked_Access);
      if Ret_Val /= 0
      then
         goto Release;
      end if;


      -- Clear bits that enable EEE in various speeds.
      --
      LPI_Ctrl := LPI_Ctrl and (not I82579_LPI_CTRL_ENABLE_MASK);


      -- Enable EEE if not disabled by user.
      --
      if not HW.Dev_Spec.ICH8LAN.EEE_Disable
      then
         -- Save off link partner's EEE ability.
         --
         Ret_Val := E1000_Read_EMI_Reg_Locked (HW,
                                               LPA,
                                               HW.Dev_Spec.ICH8LAN.EEE_LP_Ability'unrestricted_Access);
         if Ret_Val /= 0
         then
            goto Release;
         end if;

         -- Read EEE advertisement.
         --
         Ret_Val := E1000_Read_EMI_Reg_Locked (HW,
                                               Adv_Addr,
                                               Adv'unchecked_Access);
         if Ret_Val /= 0
         then
            goto Release;
         end if;

         -- Enable EEE only for speeds in which the link partner is
         -- EEE capable and for which we advertise EEE.
         --
         if (    Adv
             and HW.Dev_Spec.ICH8LAN.EEE_LP_Ability
             and I82579_EEE_1000_SUPPORTED)         /= 0
         then
            LPI_Ctrl := LPI_Ctrl or I82579_LPI_CTRL_1000_ENABLE;
         end if;

         if (    Adv
             and HW.Dev_Spec.ICH8LAN.EEE_LP_Ability
             and I82579_EEE_100_SUPPORTED)          /= 0
         then
            Unused := E1E_RPHY_Locked (HW,
                                       MII_LPA,
                                       Data'unchecked_Access);

            if (Data and LPA_100FULL) /= 0
            then
               LPI_Ctrl := LPI_Ctrl or I82579_LPI_CTRL_100_ENABLE;
            else
               -- EEE is not supported in 100Half, so ignore
               -- partner's EEE in 100 ability if full-duplex
               -- is not advertised.
               --
               HW.Dev_Spec.ICH8LAN.EEE_LP_Ability := @ and (not I82579_EEE_100_SUPPORTED);
            end if;
         end if;
      end if;


      if HW.PHY.PHY_Type = E1000_PHY_82579
      then
         Ret_Val := E1000_Read_EMI_Reg_Locked (HW,
                                               I82579_LPI_PLL_SHUT,
                                               Data'unchecked_Access);

         if Ret_Val /= 0
         then
            goto Release;
         end if;

         Data    := Data and (not I82579_LPI_100_PLL_SHUT);
         Ret_Val := E1000_Write_EMI_Reg_Locked (HW,
                                                I82579_LPI_PLL_SHUT,
                                                Data);
      end if;

      -- R/Clr IEEE MMD 3.1 bits 11:10 - Tx/Rx LPI Received.
      --
      Ret_Val := E1000_Read_EMI_Reg_Locked (HW, PCS_Status, Data'unchecked_Access);

      if Ret_Val /= 0
      then
         goto Release;
      end if;

      Ret_Val := E1E_WPHY_Locked (HW,
                                  I82579_LPI_CTRL,
                                  LPI_Ctrl);

      <<Release>>
      HW.PHY.Ops.Release (HW);

      return Ret_Val;
   end E1000_Set_EEE_PCHLAN;




   -----------------------------
   -- e1000_enable_ULP_LPT_LP --
   -----------------------------

   --  configure Ultra Low Power mode for LynxPoint-LP.
   --
   --  *  @hw:    Pointer to the HW structure.
   --  *  @to_sx: Boolean indicating a system power state transition to Sx.
   --  *
   --  *  When link is down, configure ULP mode to significantly reduce the power
   --  *  to the PHY. If on a Manageability Engine (ME) enabled system, tell the
   --  *  ME firmware to start the ULP configuration.  If not on an ME enabled
   --  *  system, configure the ULP mode by software.


   function e1000_enable_ULP_LPT_LP (HW : access E1000_HW; To_SX : Boolean) return s32
   is
      Mac_Reg :         Unsigned_32;
      Ret_Val :         s32         := 0;
      Phy_Reg : aliased Unsigned_16;
      OEM_Reg : aliased Unsigned_16 := 0;
      Unused  :         s32;
   begin
      if        HW.Mac.Mac_Type < E1000_PCH_LPT
        or else HW.Adapter.Pdev.Device = E1000_DEV_ID_PCH_LPT_I217_LM
        or else HW.Adapter.Pdev.Device = E1000_DEV_ID_PCH_LPT_I217_V
        or else HW.Adapter.Pdev.Device = E1000_DEV_ID_PCH_I218_LM2
        or else HW.Adapter.Pdev.Device = E1000_DEV_ID_PCH_I218_V2
        or else HW.Dev_Spec.Ich8lan.ULP_State = E1000_ULP_State_On
      then
         return 0;
      end if;


      if (er32 (HW.all, Devices.e1000e.Registers.E1000_FWSM) and E1000_ICH_FWSM_FW_VALID) /= 0
      then
         -- Request ME configure ULP mode in the PHY.
         --
         Mac_Reg := er32 (HW.all, E1000_H2ME);
         Mac_Reg := Mac_Reg or E1000_H2ME_ULP or E1000_H2ME_ENFORCE_SETTINGS;

         ew32 (HW.all, E1000_H2ME, Mac_Reg);
         goto Exit_Function;
      end if;


      if not To_SX
      then
         declare
            I : Integer := 0;
         begin
            -- Poll up to 5 seconds for Cable Disconnected indication.
            --
            while (er32 (HW.all, Devices.e1000e.Registers.E1000_FEXT) and E1000_FEXT_PHY_CABLE_DISCONNECTED) = 0
            loop
               -- Bail if link is re-acquired.
               --
               if (er32 (HW.all, Devices.e1000e.Registers.E1000_STATUS) and E1000_STATUS_LU) /= 0
               then
                  return -E1000_ERR_PHY;
               end if;

               if I = 100
               then
                  exit;
               end if;

               delay 0.05;
               I := I + 1;
            end loop;

            e_dbg (  "CABLE_DISCONNECTED"
                     & (if (er32 (HW.all, Devices.e1000e.Registers.E1000_FEXT) and E1000_FEXT_PHY_CABLE_DISCONNECTED) /= 0 then ""
                       else " not")
                     & " set after" & Integer'Image (I * 50) & "msec.");
         end;
      end if;


      Ret_Val := HW.Phy.Ops.Acquire (HW);

      if Ret_Val /= 0
      then
         goto Exit_Function;
      end if;


      if HW.Mac.Mac_Type /= E1000_PCH_MTP
      then
         Ret_Val := e1000e_force_SMBus (HW);

         if Ret_Val /= 0
         then
            e_dbg ("Failed to force SMBUS:" & Ret_Val'Image);
            goto Release;
         end if;
      end if;

      -- Si workaround for ULP entry flow on i127/rev6 h/w.  Enable
      -- LPLU and disable Gig speed when entering ULP.
      --
      if HW.Phy.Phy_Type = E1000_PHY_I217 and HW.Phy.Revision = 6
      then
         Ret_Val := e1000_Read_PHY_Reg_HV_Locked (HW,
                                                  HV_OEM_BITS,
                                                  OEM_Reg'unchecked_Access);
         if Ret_Val /= 0
         then
            goto Release;
         end if;

         Phy_Reg := OEM_Reg;
         Phy_Reg := Phy_Reg or HV_OEM_BITS_LPLU or HV_OEM_BITS_GBE_DIS;

         Ret_Val := e1000_Write_PHY_Reg_HV_Locked (HW,
                                                   HV_OEM_BITS,
                                                   Phy_Reg);
         if Ret_Val /= 0
         then
            goto Release;
         end if;
      end if;


      -- Set Inband ULP Exit, Reset to SMBus mode and
      -- Disable SMBus Release on PERST# in PHY.
      --
      Ret_Val := e1000_Read_PHY_Reg_HV_Locked (HW,
                                               I218_ULP_CONFIG1,
                                               Phy_Reg'unchecked_Access);
      if Ret_Val /= 0
      then
         goto Release;
      end if;

      Phy_Reg := Phy_Reg or (I218_ULP_CONFIG1_RESET_TO_SMBUS or
                               I218_ULP_CONFIG1_DISABLE_SMB_PERST);
      if To_SX
      then
         if (er32 (HW.all, Devices.e1000e.Registers.E1000_WUFC) and E1000_WUFC_LNKC) /= 0
         then
            Phy_Reg := Phy_Reg or I218_ULP_CONFIG1_WOL_HOST;
         else
            Phy_Reg := Phy_Reg and (not I218_ULP_CONFIG1_WOL_HOST);
         end if;

         Phy_Reg := Phy_Reg or I218_ULP_CONFIG1_STICKY_ULP;
         Phy_Reg := Phy_Reg and (not I218_ULP_CONFIG1_INBAND_EXIT);

      else
         Phy_Reg := Phy_Reg or I218_ULP_CONFIG1_INBAND_EXIT;
         Phy_Reg := Phy_Reg and (not I218_ULP_CONFIG1_STICKY_ULP);
         Phy_Reg := Phy_Reg and (not I218_ULP_CONFIG1_WOL_HOST);
      end if;

      Unused := e1000_Write_PHY_Reg_HV_Locked (HW,
                                               I218_ULP_CONFIG1,
                                               Phy_Reg);

      -- Set Disable SMBus Release on PERST# in MAC.
      --
      Mac_Reg := er32 (HW.all, Devices.e1000e.Registers.E1000_FEXTNVM7);
      Mac_Reg := Mac_Reg or E1000_FEXTNVM7_DISABLE_SMB_PERST;

      ew32 (HW.all, Devices.e1000e.Registers.E1000_FEXTNVM7, Mac_Reg);

      -- Commit ULP changes in PHY by starting auto ULP configuration.
      --
      Phy_Reg := Phy_Reg or I218_ULP_CONFIG1_START;
      Unused  := e1000_Write_PHY_Reg_HV_Locked (HW,
                                                I218_ULP_CONFIG1,
                                                Phy_Reg);
      if    HW.Phy.Phy_Type = E1000_PHY_I217
        and HW.Phy.Revision = 6
        and To_SX
        and (    er32 (HW.all, Devices.e1000e.Registers.E1000_STATUS)
             and E1000_STATUS_LU) /= 0
      then
         Ret_Val := e1000_write_PHY_Reg_HV_Locked (HW,
                                                   HV_OEM_BITS,
                                                   OEM_Reg);
         if Ret_Val /= 0
         then
            goto Release;
         end if;
      end if;


      <<Release>>

      if HW.Mac.Mac_Type = E1000_PCH_MTP
      then
         Ret_Val := e1000e_force_SMBus (HW);

         if Ret_Val /= 0
         then
            e_dbg ("Failed to force SMBUS over MTL system:" & Ret_Val'Image);
         end if;
      end if;

      HW.Phy.Ops.Release (HW);


      <<Exit_Function>>

      if Ret_Val /= 0
      then
         e_dbg ("Error in ULP enable flow:" & Ret_Val'Image);
      else
         HW.Dev_Spec.Ich8lan.ULP_State := E1000_ULP_State_On;
      end if;

      return Ret_Val;
   end e1000_enable_ULP_LPT_LP;


end Devices.e1000e.Ich8Lan;
