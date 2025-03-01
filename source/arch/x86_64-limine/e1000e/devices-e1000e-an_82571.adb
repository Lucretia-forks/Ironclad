with
     Devices.e1000e.Registers,
     Devices.e1000e.Hardware.E1000_PHY_Info,
     Devices.e1000e.Hardware.E1000_NVM_Info,
     Devices.e1000e.Hardware.E1000_Mac_Info,
     Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32,
     Devices.e1000e.Manage,
     Devices.e1000e.Base.Port,
     interfaces.C;


package body Devices.e1000e.an_82571
is
   use Devices.e1000e.Core.Pointers,
       Devices.e1000e.Physical_Layer,
       Devices.e1000e.Media_Access_Control,
       Devices.e1000e.Non_Volatile_Memory,
       Devices.e1000e.Manage,
       Devices.e1000e.Base.Port,
       Linux;



   ----------------------
   -- Subprogram Specs --
   ----------------------

   function E1000_Get_Phy_Id_82571
     (HW : access E1000_HW) return s32;

   function E1000_Setup_Copper_Link_82571
     (HW : access E1000_HW) return s32;

   function E1000_Setup_Fiber_Serdes_Link_82571
     (HW : access E1000_HW) return s32;

   function E1000_Check_For_Serdes_Link_82571
     (HW : access E1000_HW) return s32;

   function E1000_Write_NVM_EEWR_82571
     (HW     : access E1000_HW;
      Offset : in     Unsigned_16;
      Words  : in     Unsigned_16;
      Data   : in     u16_Pointer) return s32;

   function E1000_Fix_NVM_Checksum_82571
     (HW : access E1000_HW) return s32;

   procedure E1000_Initialize_HW_Bits_82571
     (HW : access E1000_HW);

   --  procedure E1000_Clear_HW_Cntrs_82571
   --    (HW : access E1000_HW);

   function E1000_Check_MNG_Mode_82574
     (HW : access E1000_HW) return Boolean;

   function E1000_LED_On_82574
     (HW : access E1000_HW) return s32;

   --  procedure E1000_Put_HW_Semaphore_82571
   --    (HW : access E1000_HW);

   procedure E1000_Power_Down_PHY_Copper_82571
     (HW : access E1000_HW) is null;

   procedure E1000_Put_HW_Semaphore_82573
     (HW : access E1000_HW);

   function E1000_Get_HW_Semaphore_82574
     (HW : access E1000_HW) return s32;

   procedure E1000_Put_HW_Semaphore_82574
     (HW : access E1000_HW);

   function E1000_Set_D0_LPLU_State_82574
     (HW     : access E1000_HW;
      Active : in     Boolean) return s32;

   function E1000_Set_D3_LPLU_State_82574
     (HW     : access E1000_HW;
      Active : in     Boolean) return s32;





   ---------------------------------------------------------------------------
   --                             Subprogram Bodies                         --
   ---------------------------------------------------------------------------



   ---------------------------------
   -- E1000_Init_PHY_Params_82571 --
   ---------------------------------

   --  Init PHY func ptrs.
   --
   --  *  @hw: Pointer to the HW structure.


   function E1000_Init_PHY_Params_82571
     (HW : access E1000_HW) return s32
   is
      PHY     : E1000_PHY_Info.item renames HW.PHY;
      Ret_Val : s32;

   begin
      if HW.PHY.Media_Type /= E1000_Media_Type_Copper
      then
         PHY.PHY_Type := E1000_PHY_None;
         return 0;
      end if;


      PHY.Addr           := 1;
      PHY.Autoneg_Mask   := AUTONEG_ADVERTISE_SPEED_DEFAULT;
      PHY.Reset_Delay_Us := 100;

      PHY.Ops.Power_Up   := E1000_Power_Up_PHY_Copper        'Access;
      PHY.Ops.Power_Down := E1000_Power_Down_PHY_Copper_82571'Access;

      case HW.MAC.MAC_Type
      is
         when E1000_82571
            | E1000_82572 =>

            PHY.PHY_Type := E1000_PHY_IGP_2;

         when E1000_82573 =>

            PHY.PHY_Type := E1000_PHY_M88;

         when E1000_82574
            | E1000_82583 =>

            PHY.PHY_Type              := E1000_PHY_BM;
            PHY.Ops.Acquire           := E1000_Get_HW_Semaphore_82574'Access;
            PHY.Ops.Release           := E1000_Put_HW_Semaphore_82574'Access;
            PHY.Ops.Set_D0_LPLU_State := E1000_Set_D0_LPLU_State_82574'Access;
            PHY.Ops.Set_D3_LPLU_State := E1000_Set_D3_LPLU_State_82574'Access;

         when others =>
            return -E1000_ERR_PHY;
      end case;


      -- This can only be done after all function pointers are setup.
      --
      Ret_Val := E1000_Get_PHY_ID_82571 (HW);

      if Ret_Val /= 0
      then
         e_dbg ("Error getting PHY ID");
         return Ret_Val;
      end if;


      -- Verify phy id.
      --
      case HW.MAC.MAC_Type
      is
         when E1000_82571
            | E1000_82572 =>

            if PHY.ID /= IGP01E1000_I_PHY_ID
            then
               Ret_Val := -E1000_ERR_PHY;
            end if;

         when E1000_82573 =>

            if PHY.ID /= M88E1111_I_PHY_ID
            then
               Ret_Val := -E1000_ERR_PHY;
            end if;

         when E1000_82574
            | E1000_82583 =>

            if PHY.ID /= BME1000_E_PHY_ID_R2
            then
               Ret_Val := -E1000_ERR_PHY;
            end if;

         when others =>
            Ret_Val := -E1000_ERR_PHY;
      end case;


      if Ret_Val /= 0
      then
         e_dbg ("PHY ID unknown: type = " & PHY.ID'Image);
      end if;

      return Ret_Val;
   end E1000_Init_PHY_Params_82571;




   ---------------------------------
   -- E1000_Init_NVM_Params_82571 --
   ---------------------------------

   --  Init NVM func ptrs.
   --
   --  *  @hw: Pointer to the HW structure.


   function E1000_Init_NVM_Params_82571 (HW : access E1000_HW) return s32
   is
      NVM  : E1000_NVM_Info.item renames HW.NVM;
      EECD : Unsigned_32 := ER32 (Hw.all, Devices.e1000e.Registers.E1000_EECD);
      Size : Unsigned_16;

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


      declare
         procedure do_Default
         is
         begin
            NVM.NVM_Type := E1000_NVM_EEPROM_SPI;
            Size         := FIELD_GET (E1000_EECD_SIZE_EX_MASK, u16 (EECD));

            -- Added to a constant, "Size" becomes the left-shift value for setting word_size.
            --
            Size := Size + NVM_WORD_SIZE_BASE_SHIFT;

            -- EEPROM access above 16k is unsupported.
            --
            if Size > 14
            then
               Size := 14;
            end if;

            NVM.Word_Size := BIT (Natural (Size));
         end do_Default;

      begin
         case HW.MAC.Mac_Type
         is
            when E1000_82573
               | E1000_82574
               | E1000_82583 =>

               if (shift_Right (EECD, 15) and 16#3#) = 16#3#
               then
                  NVM.NVM_Type  := E1000_NVM_Flash_HW;
                  NVM.Word_Size := 2048;

                  -- Autonomous Flash update bit must be cleared due to Flash update issue.
                  --
                  EECD := EECD and (not E1000_EECD_AUPDEN);
                  EW32 (Hw.all, Devices.e1000e.Registers.E1000_EECD, EECD);

               else
                  do_Default;
               end if;

            when others =>
               do_Default;
         end case;
      end;


      -- Function Pointers.
      --
      case HW.MAC.Mac_Type
      is
         when E1000_82574
            | E1000_82583 =>

            NVM.Ops.Acquire := E1000_Get_HW_Semaphore_82574'Access;
            NVM.Ops.Release := E1000_Put_HW_Semaphore_82574'Access;

         when others =>
            null;
      end case;


      return 0;
   end E1000_Init_NVM_Params_82571;




   ---------------------------------
   -- E1000_Init_Mac_Params_82571 --
   ---------------------------------

   --  Init MAC func ptrs.
   --
   --  *  @hw: Pointer to the HW structure.


   function E1000_Init_Mac_Params_82571
     (Hw : access E1000_Hw) return s32
   is
      Mac              : E1000_Mac_Info.item renames Hw.Mac;
      Swsm             : Unsigned_32 := 0;
      Swsm2            : Unsigned_32 := 0;
      Force_Clear_Smbi : Boolean     := False;

   begin
      -- Set media type and media-dependent function pointers.
      --
      case Hw.Adapter.Pdev.Device
      is
         when E1000_DEV_ID_82571EB_FIBER
            | E1000_DEV_ID_82572EI_FIBER
            | E1000_DEV_ID_82571EB_QUAD_FIBER =>

            Hw.Phy.Media_Type                := E1000_Media_Type_Fiber;
            Mac.Ops.Setup_Physical_Interface := E1000_Setup_Fiber_Serdes_Link_82571     'Access;
            Mac.Ops.Check_For_Link           := E1000e_Check_For_Fiber_Link             'Access;
            Mac.Ops.Get_Link_Up_Info         := E1000e_Get_Speed_And_Duplex_Fiber_Serdes'Access;

         when E1000_DEV_ID_82571EB_SERDES
            | E1000_DEV_ID_82571EB_SERDES_DUAL
            | E1000_DEV_ID_82571EB_SERDES_QUAD
            | E1000_DEV_ID_82572EI_SERDES =>

            Hw.Phy.Media_Type                := E1000_Media_Type_Internal_Serdes;
            Mac.Ops.Setup_Physical_Interface := E1000_Setup_Fiber_Serdes_Link_82571     'Access;
            Mac.Ops.Check_For_Link           := E1000_Check_For_Serdes_Link_82571       'Access;
            Mac.Ops.Get_Link_Up_Info         := E1000e_Get_Speed_And_Duplex_Fiber_Serdes'Access;

         when others =>

            Hw.Phy.Media_Type                := E1000_Media_Type_Copper;
            Mac.Ops.Setup_Physical_Interface := E1000_Setup_Copper_Link_82571     'Access;
            Mac.Ops.Check_For_Link           := E1000e_Check_For_Copper_Link      'Access;
            Mac.Ops.Get_Link_Up_Info         := E1000e_Get_Speed_And_Duplex_Copper'Access;
      end case;


      Mac.Mta_Reg_Count   := 128;                    -- Set mta register count.
      Mac.Rar_Entry_Count := E1000_RAR_ENTRIES;      -- Set rar entry count.
      Mac.Adaptive_Ifs    := True;                   -- Adaptive IFS supported.

      -- MAC-specific function pointers.
      --
      case Hw.Mac.Mac_Type
      is
         when E1000_82573 =>

            Mac.Ops.Set_Lan_Id     := E1000_Set_Lan_Id_Single_Port 'Access;
            Mac.Ops.Check_Mng_Mode := E1000e_Check_Mng_Mode_Generic'Access;
            Mac.Ops.Led_On         := E1000e_Led_On_Generic        'Access;
            Mac.Ops.Blink_Led      := E1000e_Blink_Led_Generic     'Access;

            -- FWSM register.
            --
            Mac.Has_Fwsm := True;

            -- ARC supported; valid only if manageability features are enabled.
            --
            Mac.Arc_Subsystem_Valid := (    Er32 (Hw.all, Devices.e1000e.Registers.E1000_FWSM)
                                        and E1000_FWSM_MODE_MASK          ) /= 0;

         when E1000_82574
            | E1000_82583 =>

            Mac.Ops.Set_Lan_Id     := E1000_Set_Lan_Id_Single_Port'Access;
            Mac.Ops.Check_Mng_Mode := E1000_Check_Mng_Mode_82574  'Access;
            Mac.Ops.Led_On         := E1000_Led_On_82574          'Access;

         when others =>

            Mac.Ops.Check_Mng_Mode := E1000e_Check_Mng_Mode_Generic'Access;
            Mac.Ops.Led_On         := E1000e_Led_On_Generic        'Access;
            Mac.Ops.Blink_Led      := E1000e_Blink_Led_Generic     'Access;

            -- FWSM register.
            --
            Mac.Has_Fwsm := True;
      end case;


      -- Ensure that the inter-port SWSM.SMBI lock bit is clear before
      -- first NVM or PHY access. This should be done for single-port
      -- devices, and for one port only on dual-port devices so that
      -- for those devices we can still use the SMBI lock to synchronize
      -- inter-port accesses to the PHY & NVM.
      --
      case Hw.Mac.Mac_Type
      is
         when E1000_82571
            | E1000_82572 =>

            Swsm2 := Er32 (Hw.all, Devices.e1000e.Registers.E1000_SWSM2);

            if (Swsm2 and E1000_SWSM2_LOCK) = 0
            then
               -- Only do this for the first interface on this card.
               --
               Ew32 (Hw.all,
                     Devices.e1000e.Registers.E1000_SWSM2,
                     Swsm2 or E1000_SWSM2_LOCK);

               Force_Clear_Smbi := True;
            else
               Force_Clear_Smbi := False;
            end if;

         when others =>

            Force_Clear_Smbi := True;
      end case;


      if Force_Clear_Smbi
      then
         -- Make sure SWSM.SMBI is clear.
         --
         Swsm := Er32 (Hw.all, Devices.e1000e.Registers.E1000_SWSM);

         if (Swsm and E1000_SWSM_SMBI) /= 0
         then
            -- This bit should not be set on a first interface, and
            -- indicates that the bootagent or EFI code has
            -- improperly left this bit enabled.
            --
            e_dbg ("Please update your 82571 Bootagent");
         end if;

         Ew32 (Hw.all,
               Devices.e1000e.Registers.E1000_SWSM,
               Swsm and (not E1000_SWSM_SMBI));
      end if;


      -- Initialize device specific counter of SMBI acquisition timeouts.
      --
      Hw.Dev_Spec.E82571.Smb_Counter := 0;

      return 0;
   end E1000_Init_Mac_Params_82571;




   ------------------------------
   -- E1000_Get_Variants_82571 --
   ------------------------------

   Global_Quad_Port_A : Integer := 0;     -- Global port A indication.


   function E1000_Get_Variants_82571
     (Adapter : access E1000_Adapter.item) return s32
   is
      use type C.unsigned;

      Hw                 : E1000_Hw renames Adapter.Hw;
      Pdev               : PCI_Dev  renames Adapter.Pdev.all;

      Is_Port_B          : constant Boolean := (    Er32 (Hw, Devices.e1000e.Registers.E1000_Status)
                                                and E1000_STATUS_FUNC_1         ) /= 0;
      Rc                 :          s32;

   begin
      Rc := E1000_Init_Mac_Params_82571 (Hw'Access);

      if Rc /= 0
      then
         return Rc;
      end if;


      Rc := E1000_Init_Nvm_Params_82571 (Hw'Access);

      if Rc /= 0
      then
         return Rc;
      end if;


      Rc := E1000_Init_Phy_Params_82571 (Hw'Access);

      if Rc /= 0
      then
         return Rc;
      end if;


      -- Tag quad port adapters first, it's used below.
      --
      case Pdev.Device
      is
         when E1000_DEV_ID_82571EB_QUAD_COPPER
            | E1000_DEV_ID_82571EB_QUAD_FIBER
            | E1000_DEV_ID_82571EB_QUAD_COPPER_LP
            | E1000_DEV_ID_82571PT_QUAD_COPPER =>

            Adapter.Flags := Adapter.Flags or C.unsigned (FLAG_IS_QUAD_PORT);

            -- Mark the first port.
            --
            if Global_Quad_Port_A = 0
            then
               Adapter.Flags := Adapter.Flags or C.unsigned (FLAG_IS_QUAD_PORT_A);
            end if;

            -- Reset for multiple quad port adapters.
            --
            Global_Quad_Port_A := Global_Quad_Port_A + 1;

            if Global_Quad_Port_A = 4
            then
               Global_Quad_Port_A := 0;
            end if;

         when others =>
            null;
      end case;


      case Adapter.Hw.Mac.Mac_Type
      is
         when E1000_82571 =>
            -- These dual ports don't have WoL on port B at all.
            --
            if (     (Pdev.Device = E1000_DEV_ID_82571EB_FIBER)
                  or (Pdev.Device = E1000_DEV_ID_82571EB_SERDES)
                  or (Pdev.Device = E1000_DEV_ID_82571EB_COPPER))
              and Is_Port_B
            then
               Adapter.Flags := Adapter.Flags and (not C.unsigned (FLAG_HAS_WOL));
            end if;

            -- Quad ports only support WoL on port A.
            --
            if    (Adapter.Flags and C.unsigned (FLAG_IS_QUAD_PORT))  /= 0
              and (Adapter.Flags and C.unsigned (FLAG_IS_QUAD_PORT_A)) = 0
            then
               Adapter.Flags := Adapter.Flags and (not C.unsigned (FLAG_HAS_WOL));
            end if;

            -- Does not support WoL on any port.
            --
            if Pdev.Device = E1000_DEV_ID_82571EB_SERDES_QUAD
            then
               Adapter.Flags := Adapter.Flags and (not C.unsigned (FLAG_HAS_WOL));
            end if;

         when E1000_82573 =>

            if Pdev.Device = E1000_DEV_ID_82573L
            then
               Adapter.Flags             := Adapter.Flags or C.unsigned (FLAG_HAS_JUMBO_FRAMES);
               Adapter.Max_Hw_Frame_Size := DEFAULT_JUMBO;
            end if;

         when others =>
            null;
      end case;


      return 0;
   end E1000_Get_Variants_82571;





   ----------------------------
   -- E1000_Get_Phy_Id_82571 --
   ----------------------------

   --  Retrieve the PHY ID and revision.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Reads the PHY registers and stores the PHY ID and possibly the PHY
   --  *  revision in the hardware structure.


   function E1000_Get_Phy_Id_82571
     (Hw : access E1000_Hw) return s32
   is
      Phy     : E1000_Phy_Info.item renames Hw.Phy;
      Ret_Val :         s32;
      Phy_Id  : aliased u16 := 0;

   begin
      case Hw.Mac.Mac_Type
      is
         when E1000_82571
            | E1000_82572 =>

            -- The 82571 firmware may still be configuring the PHY.
            -- In this case, we cannot access the PHY until the
            -- configuration is done. So we explicitly set the PHY ID.
            --
            Phy.Id := IGP01E1000_I_PHY_ID;

         when E1000_82573 =>

            return E1000e_Get_Phy_Id (Hw);

         when E1000_82574 | E1000_82583 =>

            Ret_Val := E1e_Rphy (Hw, MII_PHYSID1, Phy_Id'unchecked_Access);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;

            Phy.Id := Interfaces.shift_Left (u32 (Phy_Id), 16);

            delay 30.0 * Microseconds;     -- Equivalent to usleep_range (20, 40).

            Ret_Val := E1e_Rphy (Hw, MII_PHYSID2, Phy_Id'unchecked_Access);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;

            Phy.Id       := Phy.Id or u32 (Phy_Id);
            Phy.Revision := u32 (Phy_Id) and not PHY_REVISION_MASK;

         when others =>
            return -E1000_ERR_PHY;
      end case;


      return 0;
   end E1000_Get_Phy_Id_82571;




   ----------------------------------
   -- E1000_Get_HW_Semaphore_82571 --
   ----------------------------------

   --  Acquire hardware semaphore.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Acquire the HW semaphore to access the PHY or NVM


   function E1000_Get_HW_Semaphore_82571
     (HW : access E1000_HW) return s32
   is
      SWSM       :          Unsigned_32;
      SW_Timeout :          Integer_32 := Integer_32 (HW.NVM.Word_Size) + 1;
      FW_Timeout : constant Integer_32 := Integer_32 (HW.NVM.Word_Size) + 1;
      I          :          Integer_32 := 0;

   begin
      -- If we have timedout 3 times on trying to acquire
      -- the inter-port SMBI semaphore, there is old code
      -- operating on the other port, and it is not
      -- releasing SMBI. Modify the number of times that
      -- we try for the semaphore to interwork with this
      -- older code.
      --
      if HW.Dev_Spec.E82571.SMB_Counter > 2
      then
         SW_Timeout := 1;
      end if;

      -- Get the SW semaphore.
      --
      while I < SW_Timeout
      loop
         SWSM := ER32 (Hw.all, Devices.e1000e.Registers.E1000_SWSM);

         if (SWSM and E1000_SWSM_SMBI) = 0
         then
            exit;
         end if;

         delay 75.0 * Microseconds;     -- Equivalent to usleep_range (50, 100).
         I := I + 1;
      end loop;


      if I = SW_Timeout
      then
         e_dbg ("Driver can't access device - SMBI bit is set.");
         HW.Dev_Spec.E82571.SMB_Counter := HW.Dev_Spec.E82571.SMB_Counter + 1;
      end if;

      -- Get the FW semaphore.
      --
      I := 0;

      while I < FW_Timeout
      loop
         SWSM := ER32 (Hw.all, Devices.e1000e.Registers.E1000_SWSM);
         EW32 (Hw.all, Devices.e1000e.Registers.E1000_SWSM, SWSM or E1000_SWSM_SWESMBI);

         -- Semaphore acquired if bit latched.
         --
         if (ER32 (Hw.all, Devices.e1000e.Registers.E1000_SWSM) and E1000_SWSM_SWESMBI) /= 0
         then
            exit;
         end if;

         delay 75.0 * Microseconds;     -- Equivalent to usleep_range (50, 100).
         I := I + 1;
      end loop;


      if I = FW_Timeout
      then
         -- Release semaphores.
         --
         E1000_Put_HW_Semaphore_82571 (HW);
         e_dbg ("Driver can't access the NVM");
         return -E1000_ERR_NVM;
      end if;

      return 0;
   end E1000_Get_HW_Semaphore_82571;




   ----------------------------------
   -- E1000_Put_HW_Semaphore_82571 --
   ----------------------------------

   --  Release hardware semaphore.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Release hardware semaphore used to access the PHY or NVM


   procedure E1000_Put_HW_Semaphore_82571
     (HW : access E1000_HW)
   is
      SWSM : Unsigned_32;
   begin
      SWSM := ER32 (Hw.all, Devices.e1000e.Registers.E1000_SWSM);
      SWSM := SWSM and (not (E1000_SWSM_SMBI or E1000_SWSM_SWESMBI));
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_SWSM, SWSM);
   end E1000_Put_HW_Semaphore_82571;





   ----------------------------------
   -- E1000_Get_HW_Semaphore_82573 --
   ----------------------------------

   --  Acquire hardware semaphore.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Acquire the HW semaphore during reset.


   function E1000_Get_HW_Semaphore_82573
     (HW : access E1000_HW) return s32
   is
      Extcnf_Ctrl : Unsigned_32;
      I           : Integer    := 0;

   begin
      Extcnf_Ctrl := ER32 (Hw.all, Devices.e1000e.Registers.E1000_EXTCNF_CTRL);

      loop
         Extcnf_Ctrl := Extcnf_Ctrl or E1000_EXTCNF_CTRL_MDIO_SW_OWNERSHIP;
         EW32 (Hw.all, Devices.e1000e.Registers.E1000_EXTCNF_CTRL, Extcnf_Ctrl);
         Extcnf_Ctrl := ER32 (Hw.all, Devices.e1000e.Registers.E1000_EXTCNF_CTRL);

         exit when (Extcnf_Ctrl and E1000_EXTCNF_CTRL_MDIO_SW_OWNERSHIP) /= 0;

         delay 3000.0 * Microseconds;     -- Simulating usleep_range (2000, 4000).
         I := I + 1;

         exit when I >= MDIO_OWNERSHIP_TIMEOUT;
      end loop;


      if I = MDIO_OWNERSHIP_TIMEOUT
      then
         -- Release semaphores.
         --
         E1000_Put_HW_Semaphore_82573 (HW);
         e_dbg ("Driver can't access the PHY");
         return -E1000_ERR_PHY;
      end if;

      return 0;
   end E1000_Get_HW_Semaphore_82573;




   ----------------------------------
   -- E1000_Put_HW_Semaphore_82573 --
   ----------------------------------

   procedure E1000_Put_HW_Semaphore_82573
     (HW : access E1000_HW)
   is
      Extcnf_Ctrl : unsigned_32;

   begin
      Extcnf_Ctrl := Er32 (Hw.all, Devices.e1000e.Registers.E1000_EXTCNF_CTRL);
      Extcnf_Ctrl := Extcnf_Ctrl and (not E1000_EXTCNF_CTRL_MDIO_SW_OWNERSHIP);

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_EXTCNF_CTRL, Extcnf_Ctrl);
   end E1000_Put_HW_Semaphore_82573;




   ----------------------------------
   -- E1000_Get_HW_Semaphore_82574 --
   ----------------------------------

   swflag_mutex : Devices.e1000e.Core.Mutex;


   function E1000_Get_HW_Semaphore_82574
     (HW : access E1000_HW) return s32
   is
      Ret_Val      : s32;
   begin
      Swflag_Mutex.acquire;
      Ret_Val := E1000_Get_HW_Semaphore_82573 (HW);

      if Ret_Val /= 0
      then
         Swflag_Mutex.release;
      end if;

      return Ret_Val;
   end E1000_Get_HW_Semaphore_82574;




   ----------------------------------
   -- E1000_Put_HW_Semaphore_82574 --
   ----------------------------------

   --  Release hardware semaphore
   --  *  @hw: pointer to the HW structure
   --  *
   --  *  Release hardware semaphore used to access the PHY or NVM


   procedure E1000_Put_HW_Semaphore_82574
     (HW : access E1000_HW)
   is
   begin
      E1000_Put_HW_Semaphore_82573 (HW);
      Swflag_Mutex.release;
   end E1000_Put_HW_Semaphore_82574;




   -----------------------------------
   -- E1000_Set_D0_LPLU_State_82574 --
   -----------------------------------

   --  Set Low Power Linkup D0 state.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @active: True to enable LPLU, false to disable.
   --  *
   --  *  Sets the LPLU D0 state according to the active flag.
   --  *  LPLU will not be activated unless the
   --  *  device autonegotiation advertisement meets standards of
   --  *  either 10 or 10/100 or 10/100/1000 at all duplexes.
   --  *  This is a function pointer entry point only called by
   --  *  PHY setup routines.


   function E1000_Set_D0_LPLU_State_82574
     (Hw     : access E1000_HW;
      Active : in     Boolean) return s32
   is
      Data    : Unsigned_32;
   begin
      -- Assuming er32 and ew32 are functions to read and write 32-bit registers.
      --
      Data := Er32 (Hw.all, Devices.e1000e.Registers.E1000_POEMB);

      if Active then Data := Data or       E1000_PHY_CTRL_D0A_LPLU;
                else Data := Data and (not E1000_PHY_CTRL_D0A_LPLU);
      end if;

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_POEMB, Data);
      return 0;
   end E1000_Set_D0_LPLU_State_82574;





   -----------------------------------
   -- E1000_Set_D3_LPLU_State_82574 --
   -----------------------------------

   --  Sets low power link up state for D3.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @active: Boolean used to enable/disable lplu.
   --  *
   --  *  The low power link up (lplu) state is set to the power management level D3
   --  *  when active is true, else clear lplu for D3. LPLU
   --  *  is used during Dx states where the power conservation is most important.
   --  *  During driver activity, SmartSpeed should be enabled so performance is
   --  *  maintained.


   function E1000_Set_D3_LPLU_State_82574
     (Hw     : access E1000_Hw;
      Active : in     Boolean) return s32
   is
      Data : Unsigned_32;
   begin
      Data := Er32 (Hw.all, Devices.e1000e.Registers.E1000_POEMB);

      if not Active
      then
         Data := Data and (not E1000_PHY_CTRL_NOND0A_LPLU);

      elsif Hw.Phy.Autoneg_Advertised = u16 (E1000_ALL_SPEED_DUPLEX)
        or  Hw.Phy.Autoneg_Advertised = u16 (E1000_ALL_NOT_GIG)
        or  Hw.Phy.Autoneg_Advertised = u16 (E1000_ALL_10_SPEED)
      then
         Data := Data or E1000_PHY_CTRL_NOND0A_LPLU;
      end if;

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_POEMB, Data);
      return 0;
   end E1000_Set_D3_LPLU_State_82574;




   -----------------------------
   -- E1000_Acquire_NVM_82571 --
   -----------------------------

   --  Request for access to the EEPROM.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  To gain access to the EEPROM, first we must obtain a hardware semaphore.
   --  *  Then for non-82573 hardware, set the EEPROM access request bit and wait
   --  *  for EEPROM access grant bit.  If the access grant bit is not set, release
   --  *  hardware semaphore.


   function E1000_Acquire_NVM_82571
     (HW :  access E1000_Hw) return s32
   is
      Ret_Val : s32;

   begin
      Ret_Val := E1000_Get_HW_Semaphore_82571 (HW);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      case HW.Mac.Mac_Type
      is
         when E1000_82573 => null;
         when others      => Ret_Val := E1000e_Acquire_NVM (HW);
      end case;


      if Ret_Val /= 0
      then
         E1000_Put_HW_Semaphore_82571 (HW);
      end if;

      return Ret_Val;
   end E1000_Acquire_NVM_82571;




   -----------------------------
   -- E1000_Release_NVM_82571 --
   -----------------------------

   --  Release exclusive access to EEPROM.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Stop any current commands to the EEPROM and clear the EEPROM request bit.


   procedure E1000_Release_NVM_82571
     (HW : access E1000_HW)
   is
   begin
      E1000e_Release_NVM (HW);
      E1000_Put_HW_Semaphore_82571 (HW);
   end E1000_Release_NVM_82571;




   ---------------------------
   -- E1000_Write_NVM_82571 --
   ---------------------------

   --  Write to EEPROM using appropriate interface.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Offset within the EEPROM to be written to.
   --  *  @words:  Number of words to write.
   --  *  @data:   16 bit word(s) to be written to the EEPROM.
   --  *
   --  *  For non-82573 silicon, write data to EEPROM at offset using SPI interface.
   --  *
   --  *  If e1000e_update_nvm_checksum is not called after this function, the
   --  *  EEPROM will most likely contain an invalid checksum.


   function E1000_Write_NVM_82571
     (HW     : access E1000_HW;
      Offset : in     Unsigned_16;
      Words  : in     Unsigned_16;
      Data   : in     u16_Pointer) return s32
   is
      Ret_Val : s32;

   begin
      case HW.Mac.Mac_Type
      is
         when E1000_82573
            | E1000_82574
            | E1000_82583 =>

            Ret_Val := E1000_Write_NVM_EEWR_82571 (HW, Offset, Words, Data);

         when E1000_82571
            | E1000_82572 =>

            Ret_Val := E1000E_Write_NVM_SPI (HW, Offset, Words, Data);

         when others =>
            Ret_Val := -E1000_ERR_NVM;
      end case;


      return Ret_Val;
   end E1000_Write_NVM_82571;





   -------------------------------------
   -- E1000_Update_NVM_Checksum_82571 --
   -------------------------------------

   --    Update EEPROM checksum.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Updates the EEPROM checksum by reading/adding each word of the EEPROM
   --  *  up to the checksum.  Then calculates the EEPROM checksum and writes the
   --  *  value to the EEPROM.


   function E1000_Update_NVM_Checksum_82571
     (HW : access E1000_HW) return s32
   is
      EECD    : Interfaces.Unsigned_32;
      Ret_Val : s32;
      I       : Natural;

   begin
      Ret_Val := E1000e_Update_NVM_Checksum_Generic (HW);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      -- If our nvm is an EEPROM, then we're done
      -- otherwise, commit the checksum to the flash NVM.
      --
      if HW.NVM.NVM_Type /= E1000_NVM_Flash_HW
      then
         return 0;
      end if;


      -- Check for pending operations.
      --
      for J in 1 .. E1000_FLASH_UPDATES
      loop
         delay 1_500.0 * Microseconds;

         exit when (ER32 (Hw.all, Devices.e1000e.Registers.E1000_EECD) and E1000_EECD_FLUPD) = 0;

         I := J;
      end loop;

      if I = E1000_FLASH_UPDATES
      then
         return -E1000_ERR_NVM;
      end if;


      -- Reset the firmware if using STM opcode.
      --
      if (ER32 (Hw.all, Devices.e1000e.Registers.E1000_FLOP) and 16#FF00#) = E1000_STM_OPCODE
      then
         -- The enabling of and the actual reset must be done
         -- in two write cycles.
         --
         EW32 (Hw.all, Devices.e1000e.Registers.E1000_HICR, E1000_HICR_FW_RESET_ENABLE);
         E1E_Flush (Hw);
         EW32 (Hw.all, Devices.e1000e.Registers.E1000_HICR, E1000_HICR_FW_RESET);
      end if;

      -- Commit the write to flash.
      --
      EECD := ER32 (Hw.all, Devices.e1000e.Registers.E1000_EECD) or E1000_EECD_FLUPD;
      EW32 (Hw.all, Devices.e1000e.Registers.E1000_EECD, EECD);


      for J in 1 .. E1000_FLASH_UPDATES
      loop
         delay 1_500.0 * Microseconds;

         exit when (ER32 (Hw.all, Devices.e1000e.Registers.E1000_EECD) and E1000_EECD_FLUPD) = 0;

         I := J;
      end loop;

      if I = E1000_FLASH_UPDATES
      then
         return -E1000_ERR_NVM;
      end if;


      return 0;
   end E1000_Update_NVM_Checksum_82571;





   ---------------------------------------
   -- E1000_Validate_NVM_Checksum_82571 --
   ---------------------------------------

   --  Validate EEPROM checksum.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Calculates the EEPROM checksum by reading/adding each word of the EEPROM
   --  *  and then verifies that the sum of the EEPROM is equal to 0xBABA.


   function E1000_Validate_NVM_Checksum_82571
     (HW : access E1000_HW) return s32
   is
      Unused : s32;
   begin
      if HW.NVM.NVM_Type = E1000_NVM_Flash_HW
      then
         Unused := E1000_Fix_NVM_Checksum_82571 (HW);
      end if;

      return E1000E_Validate_NVM_Checksum_Generic (HW);
   end E1000_Validate_NVM_Checksum_82571;





   --------------------------------
   -- E1000_Write_NVM_EEWR_82571 --
   --------------------------------

   --  Write to EEPROM for 82573 silicon.
   --
   --  *  @hw:     Pointer to the HW structure.
   --  *  @offset: Offset within the EEPROM to be written to.
   --  *  @words:  Number of words to write.
   --  *  @data:   16 bit word(s) to be written to the EEPROM.
   --  *
   --  *  After checking for invalid values, poll the EEPROM to ensure the previous
   --  *  command has completed before trying to write the next word.  After write
   --  *  poll for completion.
   --  *
   --  *  If e1000e_update_nvm_checksum is not called after this function, the
   --  *  EEPROM will most likely contain an invalid checksum.


   function E1000_Write_NVM_EEWR_82571
     (HW     : access E1000_HW;
      Offset : in     Unsigned_16;
      Words  : in     Unsigned_16;
      Data   : in     u16_Pointer) return s32
   is
      use C_u16_Pointers;
      use type C.size_t;

      NVM     : E1000_NVM_Info.item renames HW.NVM;
      EEWR    : Interfaces.Unsigned_32 := 0;
      Ret_Val : s32                    := 0;

      Buffer  : u16_array renames Value (Data,
                                         Length => C.ptrdiff_t (Words));

   begin
      -- A check for invalid values: offset too large, too many words,
      -- and not enough words.
      --
      if   Offset >= NVM.Word_Size
        or Words  > (NVM.Word_Size - Offset)
        or Words  =  0
      then
         E_DBG ("nvm parameter(s) out of bounds");
         return -E1000_ERR_NVM;
      end if;


      for I in 0 .. Words - 1
      loop
         EEWR :=    shift_Left (u32 (Buffer (C.size_t (I))), E1000_NVM_RW_REG_DATA)
                 or shift_Left (u32 (Offset + I),            E1000_NVM_RW_ADDR_SHIFT)
                 or                                          E1000_NVM_RW_REG_START;

         Ret_Val := E1000e_Poll_EERD_EEWR_Done (HW, E1000_NVM_POLL_WRITE);

         exit when Ret_Val /= 0;

         EW32 (Hw.all, Devices.e1000e.Registers.E1000_EEWR, EEWR);

         Ret_Val := E1000e_Poll_EERD_EEWR_Done (HW, E1000_NVM_POLL_WRITE);

         exit when Ret_Val /= 0;
      end loop;


      return Ret_Val;
   end E1000_Write_NVM_EEWR_82571;




   ------------------------------
   -- E1000_Get_Cfg_Done_82571 --
   ------------------------------

   --  Poll for configuration done.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Reads the management control register for the config done bit to be set.


   function E1000_Get_Cfg_Done_82571
     (Hw : access E1000_Hw) return s32
   is
      Timeout : s32 := PHY_CFG_TIMEOUT;

   begin
      while Timeout > 0
      loop
         exit when (    Er32 (Hw.all, Devices.e1000e.Registers.E1000_EEMNGCTL)
                    and E1000_NVM_CFG_DONE_PORT_0         ) /= 0;

         delay 1_500.0 * Microseconds;
         Timeout := Timeout - 1;
      end loop;

      if Timeout = 0
      then
         e_dbg ("MNG configuration cycle has not completed.");
         return -E1000_ERR_RESET;
      end if;

      return 0;
   end E1000_Get_Cfg_Done_82571;




   -----------------------------------
   -- E1000_Set_D0_LPLU_State_82571 --
   -----------------------------------

   --    Set Low Power Linkup D0 state.
   --
   --  *  @hw: pointer to the HW structure
   --  *  @active: true to enable LPLU, false to disable
   --  *
   --  *  Sets the LPLU D0 state according to the active flag.  When activating LPLU
   --  *  this function also disables smart speed and vice versa.  LPLU will not be
   --  *  activated unless the device autonegotiation advertisement meets standards
   --  *  of either 10 or 10/100 or 10/100/1000 at all duplexes.  This is a function
   --  *  pointer entry point only called by PHY setup routines.


   function E1000_Set_D0_LPLU_State_82571
     (HW     : access E1000_HW;
      Active : in     Boolean) return s32
   is
      PHY     :         E1000_PHY_Info.item renames HW.PHY;
      Ret_Val :         s32;
      Data    : aliased Unsigned_16;

   begin
      Ret_Val := E1e_Rphy (HW, IGP02E1000_PHY_POWER_MGMT, Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      if Active
      then
         Data    := Data or IGP02E1000_PM_D0_LPLU;
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


         Data    := Data and (not IGP01E1000_PSCFR_SMART_SPEED);
         Ret_Val := E1e_Wphy (HW, IGP01E1000_PHY_PORT_CONFIG, Data);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;

      else
         Data    := Data and (not IGP02E1000_PM_D0_LPLU);
         Ret_Val := E1e_Wphy (HW, IGP02E1000_PHY_POWER_MGMT, Data);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;


         -- LPLU and SmartSpeed are mutually exclusive. LPLU is used
         -- during Dx states where the power conservation is most
         -- important. During driver activity we should enable
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
      end if;

      return 0;
   end E1000_Set_D0_LPLU_State_82571;





   ---------------------------
   -- e1000e_Reset_HW_82571 --
   ---------------------------

   function e1000_Reset_HW_82571 (HW : access E1000_HW) return s32
   is
      Ctrl,
      Ctrl_Ext,
      Eecd, Tctl : Interfaces.Unsigned_32;
      Ret_Val    : s32;
      Unused     : u32;

   begin
      -- Prevent the PCI-E bus from sticking if there is no TLP connection
      -- on the last TLP read/write transaction when MAC is reset.
      --
      Ret_Val := E1000e_Disable_Pcie_Master (HW);

      if Ret_Val /= 0
      then
         e_dbg ("PCI-E Master disable polling has failed.");
      end if;

      e_dbg ("Masking off all interrupts");
      ew32 (Hw.all, Devices.e1000e.Registers.E1000_IMC, 16#FFFFFFFF#);

      ew32 (Hw.all, Devices.e1000e.Registers.E1000_RCTL, 0);
      Tctl := er32 (Hw.all, Devices.e1000e.Registers.E1000_TCTL);
      Tctl := Tctl and (not E1000_TCTL_EN);
      ew32 (Hw.all, Devices.e1000e.Registers.E1000_TCTL, Tctl);
      E1E_Flush (Hw);

      delay 10_500.0 * Microseconds;

      -- Must acquire the MDIO ownership before MAC reset.
      -- Ownership defaults to firmware after a reset.
      --
      case HW.Mac.Mac_Type
      is
         when E1000_82573 =>

            Ret_Val := E1000_Get_HW_Semaphore_82573 (HW);

         when E1000_82574
            | E1000_82583 =>

            Ret_Val := E1000_Get_HW_Semaphore_82574 (HW);

         when others =>
            null;
      end case;

      Ctrl := er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);

      e_dbg ("Issuing a global reset to MAC");
      ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, Ctrl or E1000_CTRL_RST);

      -- Must release MDIO ownership and mutex after MAC reset.
      --
      case HW.Mac.Mac_Type
      is
         when E1000_82573 =>

            -- Release mutex only if the hw semaphore is acquired.
            --
            if Ret_Val = 0
            then
               E1000_Put_HW_Semaphore_82573 (HW);
            end if;

         when E1000_82574
            | E1000_82583 =>

            -- Release mutex only if the hw semaphore is acquired.
            --
            if Ret_Val = 0
            then
               E1000_Put_HW_Semaphore_82574 (HW);
            end if;

         when others =>
            null;
      end case;


      if HW.Nvm.Nvm_Type = E1000_NVM_FLASH_HW
      then
         delay 15.0 * Microseconds;

         Ctrl_Ext := er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT);
         Ctrl_Ext := Ctrl_Ext or E1000_CTRL_EXT_EE_RST;
         ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT, Ctrl_Ext);
         E1E_Flush (Hw);
      end if;


      Ret_Val := E1000e_Get_Auto_Rd_Done (HW);

      if Ret_Val /= 0 then
         -- We don't want to continue accessing MAC registers.
         --
         return Ret_Val;
      end if;


      -- Phy configuration from NVM just starts after EECD_AUTO_RD is set.
      -- Need to wait for Phy configuration completion before accessing
      -- NVM and Phy.

      case HW.Mac.Mac_Type
      is
         when E1000_82571
            | E1000_82572 =>

            -- REQ and GNT bits need to be cleared when using AUTO_RD
            -- to access the EEPROM.
            --
            Eecd := er32 (Hw.all, Devices.e1000e.Registers.E1000_EECD);
            Eecd := Eecd and (not (E1000_EECD_REQ or E1000_EECD_GNT));
            ew32 (Hw.all, Devices.e1000e.Registers.E1000_EECD, Eecd);

         when E1000_82573
            | E1000_82574
            | E1000_82583 =>

            delay 25.0 * Milliseconds;

         when others =>
            null;
      end case;


      -- Clear any pending interrupt events.
      --
      ew32 (Hw.all, Devices.e1000e.Registers.E1000_IMC, 16#FFFFFFFF#);
      Unused := er32 (Hw.all, Devices.e1000e.Registers.E1000_ICR);

      if HW.Mac.Mac_Type = E1000_82571
      then
         -- Install any alternate MAC address into RAR0.
         --
         Ret_Val := E1000_Check_Alt_Mac_Addr_Generic (HW);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;

         E1000e_Set_Laa_State_82571 (HW, True);
      end if;


      -- Reinitialize the 82571 serdes link state machine.
      --
      if HW.Phy.Media_Type = E1000_MEDIA_TYPE_INTERNAL_SERDES
      then
         HW.Mac.Serdes_Link_State := E1000_SERDES_LINK_DOWN;
      end if;

      return 0;
   end e1000_Reset_HW_82571;




   -------------------------
   -- E1000_Init_HW_82571 --
   -------------------------

   --  Initialize hardware.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  This inits the hardware readying it for operation.


   function E1000_Init_HW_82571
     (HW : access E1000_HW) return s32
   is
      MAC       : E1000_MAC_Info.item renames HW.MAC;
      Rar_Count : Unsigned_16 := MAC.Rar_Entry_Count;
      Reg_Data  : Unsigned_32;
      Ret_Val   : s32;
      Unused    : Boolean;

   begin
      E1000_Initialize_HW_Bits_82571 (HW);

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
      MAC.Ops.Clear_Vfta (HW);

      -- Setup the receive address.
      -- If, however, a locally administered address was assigned to the
      -- 82571, we must reserve a RAR for it to work around an issue where
      -- resetting one port will reload the MAC on the other port.
      --
      if E1000e_Get_Laa_State_82571 (HW)
      then
         Rar_Count := Rar_Count - 1;
      end if;

      E1000e_Init_Rx_Addrs (HW, Rar_Count);

      -- Zero out the Multicast HASH table.
      --
      e_dbg ("Zeroing the MTA");

      for i in 0 .. MAC.Mta_Reg_Count - 1
      loop
         E1000_Write_Reg_Array (HW, Devices.e1000e.Registers.E1000_MTA, Interfaces.Unsigned_32 (i), 0);
      end loop;

      -- Setup link and flow control.
      --
      Ret_Val := MAC.Ops.Setup_Link (HW);

      -- Set the transmit descriptor write-back policy.
      --
      Reg_Data := Er32 (Hw.all, Devices.e1000e.Registers.E1000_TXDCTL (0));
      Reg_Data :=   (Reg_Data and not E1000_TXDCTL_WTHRESH)
                  or E1000_TXDCTL_FULL_TX_DESC_WB
                  or E1000_TXDCTL_COUNT_DESC;
      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_TXDCTL (0), Reg_Data);

      -- ... for both queues.
      --
      declare
         procedure do_Common
         is
         begin
            Reg_Data := Er32 (Hw.all, Devices.e1000e.Registers.E1000_GCR);
            Reg_Data := Reg_Data or E1000_GCR_L1_ACT_WITHOUT_L0S_RX;
            Ew32 (Hw.all, Devices.e1000e.Registers.E1000_GCR, Reg_Data);
         end do_Common;

      begin
         case MAC.Mac_Type
         is
            when E1000_82573 =>

               Unused := E1000e_Enable_Tx_Pkt_Filtering (HW);
               do_Common;

            when E1000_82574
               | E1000_82583 =>

               do_Common;

            when others =>

               Reg_Data := Er32 (Hw.all, Devices.e1000e.Registers.E1000_TXDCTL (1));
               Reg_Data :=   (Reg_Data and not E1000_TXDCTL_WTHRESH)
                           or E1000_TXDCTL_FULL_TX_DESC_WB
                           or E1000_TXDCTL_COUNT_DESC;
               Ew32 (Hw.all, Devices.e1000e.Registers.E1000_TXDCTL (1), Reg_Data);
         end case;
      end;

      -- Clear all of the statistics registers (clear on read).  It is
      -- important that we do this after we have tried to establish link
      -- because the symbol error count will increment wildly if there
      -- is no link.
      --
      E1000_Clear_HW_Cntrs_82571 (HW);

      return Ret_Val;
   end E1000_Init_HW_82571;




   ------------------------------------
   -- E1000_Initialize_HW_Bits_82571 --
   ------------------------------------

   --  Initialize hardware-dependent bits.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Initializes required hardware-dependent bits needed for normal operation.


   procedure E1000_Initialize_HW_Bits_82571
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
      Reg := Reg and not (Shift_Left (16#F#, 27));     -- 30:27

      case HW.Mac.Mac_Type
      is
         when E1000_82571
            | E1000_82572 =>

            Reg := Reg or BIT (23) or BIT (24) or BIT (25) or BIT (26);

         when E1000_82574
            | E1000_82583 =>

            Reg := Reg or BIT (26);

         when others =>
            null;
      end case;

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_TARC (0), Reg);

      -- Transmit Arbitration Control 1.
      --
      Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_TARC (1));

      case HW.Mac.Mac_Type
      is
         when E1000_82571
            | E1000_82572 =>

            Reg := Reg and not (BIT (29) or BIT (30));
            Reg := Reg or BIT (22) or BIT (24) or BIT (25) or BIT (26);

            if (Er32 (Hw.all, Devices.e1000e.Registers.E1000_TCTL) and E1000_TCTL_MULR) /= 0
            then
               Reg := Reg and not BIT (28);
            else
               Reg := Reg or BIT (28);
            end if;

            Ew32 (Hw.all, Devices.e1000e.Registers.E1000_TARC (1), Reg);

         when others =>
            null;
      end case;

      -- Device Control.
      --
      case HW.Mac.Mac_Type
      is
         when E1000_82573
            | E1000_82574
            | E1000_82583 =>

            Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);
            Reg := Reg and not BIT (29);
            Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, Reg);

         when others =>
            null;
      end case;

      -- Extended Device Control.
      --
      case HW.Mac.Mac_Type
      is
         when E1000_82573
            | E1000_82574
            | E1000_82583 =>

            Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT);
            Reg := (Reg and not BIT (23)) or BIT (22);
            Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT, Reg);

         when others =>
            null;
      end case;

      if HW.Mac.Mac_Type = E1000_82571
      then
         Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_PBA_ECC);
         Reg := Reg or E1000_PBA_ECC_CORR_EN;
         Ew32 (Hw.all, Devices.e1000e.Registers.E1000_PBA_ECC, Reg);
      end if;

      -- Workaround for hardware errata.
      -- Ensure that DMA Dynamic Clock gating is disabled on 82571 and 82572.
      --
      if   HW.Mac.Mac_Type = E1000_82571
        or HW.Mac.Mac_Type = E1000_82572
      then
         Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT);
         Reg := Reg and not E1000_CTRL_EXT_DMA_DYN_CLK_EN;
         Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL_EXT, Reg);
      end if;

      -- Disable IPv6 extension header parsing because some malformed
      -- IPv6 headers can hang the Rx.
      --
      if HW.Mac.Mac_Type <= E1000_82573
      then
         Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_RFCTL);
         Reg := Reg or (E1000_RFCTL_IPV6_EX_DIS or E1000_RFCTL_NEW_IPV6_EXT_DIS);
         Ew32 (Hw.all, Devices.e1000e.Registers.E1000_RFCTL, Reg);
      end if;

      -- PCI-Ex Control Registers.
      --
      case HW.Mac.Mac_Type
      is
         when E1000_82574
            | E1000_82583 =>

            Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_GCR);
            Reg := Reg or BIT (22);
            Ew32 (Hw.all, Devices.e1000e.Registers.E1000_GCR, Reg);

            -- Workaround for hardware errata.
            -- apply workaround for hardware errata documented in errata
            -- docs Fixes issue where some error prone or unreliable PCIe
            -- completions are occurring, particularly with ASPM enabled.
            -- Without fix, issue can cause Tx timeouts.
            --
            Reg := Er32 (Hw.all, Devices.e1000e.Registers.E1000_GCR2);
            Reg := Reg or 1;
            Ew32 (Hw.all, Devices.e1000e.Registers.E1000_GCR2, Reg);

         when others =>
            null;
      end case;
   end E1000_Initialize_HW_Bits_82571;




   ----------------------------
   -- E1000_Clear_VFTA_82571 --
   ----------------------------

   --    Clear VLAN filter table.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Clears the register array which contains the VLAN filter table by
   --  *  setting all the values to 0.


   procedure E1000_Clear_VFTA_82571
     (HW : access E1000_HW)
   is
      VFTA_Value      : Unsigned_32 := 0;
      VFTA_Offset     : Unsigned_32 := 0;
      VFTA_Bit_In_Reg : Unsigned_32 := 0;

   begin
      case HW.MAC.mac_type
      is
         when E1000_82573
            | E1000_82574
            | E1000_82583 =>

            if HW.MNG_Cookie.VLAN_ID /= 0
            then
               -- The VFTA is a 4096b bit-field, each identifying
               -- a single VLAN ID.  The following operations
               -- determine which 32b entry (i.e. offset) into the
               -- array we want to set the VLAN ID (i.e. bit) of
               -- the manageability unit.
               --
               VFTA_Offset     :=     shift_Right (u32 (HW.MNG_Cookie.VLAN_ID),
                                                   E1000_VFTA_ENTRY_SHIFT)
                                  and E1000_VFTA_ENTRY_MASK;
               VFTA_Bit_In_Reg := BIT (Natural (HW.MNG_Cookie.VLAN_ID and E1000_VFTA_ENTRY_BIT_SHIFT_MASK));
            end if;

         when others =>
            null;
      end case;


      for Offset in 0 .. u32 (E1000_VLAN_FILTER_TBL_SIZE) - 1
      loop
         -- If the offset we want to clear is the same offset of the
         -- manageability VLAN ID, then clear all bits except that of
         -- the manageability unit.
         --
         if Offset = VFTA_Offset
         then
            VFTA_Value := VFTA_Bit_In_Reg;
         else
            VFTA_Value := 0;
         end if;

         E1000_WRITE_REG_ARRAY (HW, Devices.e1000e.Registers.E1000_VFTA, Offset, VFTA_Value);
         E1E_Flush (Hw);
      end loop;
   end E1000_Clear_VFTA_82571;




   --------------------------------
   -- E1000_Check_Mng_Mode_82574 --
   --------------------------------

   --  Check manageability is enabled.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Reads the NVM Initialization Control Word 2 and returns true
   --  *  (>0) if any manageability is enabled, else false (0).


   function E1000_Check_Mng_Mode_82574
     (HW : access E1000_HW) return Boolean
   is
      Data   : aliased Unsigned_16;
      Unused :         s32;

   begin
      Unused := E1000_Read_NVM (HW,
                                NVM_INIT_CONTROL2_REG,
                                1,
                                Data'unchecked_Access);

      return (Data and E1000_NVM_INIT_CTRL2_MNGM) /= 0;
   end E1000_Check_Mng_Mode_82574;




   ------------------------
   -- E1000_Led_On_82574 --
   ------------------------

   --  Turn LED on.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Turn LED on.


   function E1000_Led_On_82574
     (Hw : access E1000_Hw) return s32
   is
      Ctrl : Unsigned_32;

   begin
      Ctrl := Hw.Mac.Ledctl_Mode2;

      if (E1000_STATUS_LU and Er32 (Hw.all, Devices.e1000e.Registers.E1000_STATUS)) = 0
      then
         -- If no link, then turn LED on by setting the invert bit
         -- for each LED that's "on" (0x0E) in ledctl_mode2.
         --
         for I in 0 .. 3
         loop
            if (    shift_Right (Hw.Mac.Ledctl_Mode2,
                                 Natural (I * 8))
                and 16#FF#                           ) = E1000_LEDCTL_MODE_LED_ON
            then
               Ctrl := Ctrl or shift_Left (E1000_LEDCTL_LED0_IVRT,
                                           Natural (I * 8));
            end if;
         end loop;
      end if;

      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_LEDCTL, Ctrl);

      return 0;
   end E1000_Led_On_82574;




   ----------------------------
   -- E1000_Setup_Link_82571 --
   ----------------------------

   --  Setup flow control and link settings.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Determines which flow control settings to use, then configures flow
   --  *  control.  Calls the appropriate media-specific link configuration
   --  *  function.  Assuming the adapter has a valid link partner, a valid link
   --  *  should be established.  Assumes the hardware has previously been reset
   --  *  and the transmitter and receiver are not enabled.


   function E1000_Setup_Link_82571
     (HW : access E1000_HW) return S32
   is
   begin
      -- 82573 does not have a word in the NVM to determine
      -- the default flow control setting, so we explicitly
      -- set it to full.
      --
      case HW.Mac.Mac_Type
      is
         when E1000_82573
            | E1000_82574
            | E1000_82583 =>

            if HW.Fc.Requested_Mode = E1000_Fc_Default
            then
               HW.Fc.Requested_Mode := E1000_Fc_Full;
            end if;

         when others =>
            null;
      end case;


      return E1000e_Setup_Link_Generic (HW);
   end E1000_Setup_Link_82571;




   -----------------------------------
   -- E1000_Setup_Copper_Link_82571 --
   -----------------------------------

   --  Configure copper link settings.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Configures the link for auto-neg or forced speed and duplex.  Then we check
   --  *  for link, once link is established calls to configure collision distance
   --  *  and flow control are called.


   function E1000_Setup_Copper_Link_82571
     (Hw : access E1000_Hw) return s32
   is
      Ctrl    : Unsigned_32;
      Ret_Val : s32;

   begin
      Ctrl := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);
      Ctrl := Ctrl or E1000_CTRL_SLU;
      Ctrl := Ctrl and (not (E1000_CTRL_FRCSPD or E1000_CTRL_FRCDPX));
      Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, Ctrl);

      case Hw.Phy.Phy_Type
      is
         when E1000_Phy_M88
            | E1000_Phy_Bm =>

            Ret_Val := E1000e_Copper_Link_Setup_M88 (Hw);

         when E1000_Phy_Igp_2 =>

            Ret_Val := E1000e_Copper_Link_Setup_Igp (Hw);

         when others =>
            return -E1000_ERR_PHY;
      end case;


      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;

      return E1000e_Setup_Copper_Link (Hw);
   end E1000_Setup_Copper_Link_82571;




   -----------------------------------------
   -- E1000_Setup_Fiber_Serdes_Link_82571 --
   -----------------------------------------

   --  Setup link for fiber/serdes.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Configures collision distance and flow control for fiber and serdes links.
   --  *  Upon successful setup, poll for link.


   function E1000_Setup_Fiber_Serdes_Link_82571
     (HW : access E1000_HW) return s32
   is
   begin
      case HW.Mac.Mac_Type
      is
         when E1000_82571
            | E1000_82572 =>

            -- If SerDes loopback mode is entered, there is no form
            -- of reset to take the adapter out of that mode. So we
            -- have to explicitly take the adapter out of loopback
            -- mode. This prevents drivers from twiddling their thumbs
            -- if another tool failed to take it out of loopback mode.
            --
            EW32 (Hw.all, Devices.e1000e.Registers.E1000_SCTL, E1000_SCTL_DISABLE_SERDES_LOOPBACK);

         when others =>
            null;
      end case;

      return E1000e_Setup_Fiber_Serdes_Link (HW);
   end E1000_Setup_Fiber_Serdes_Link_82571;




   ---------------------------------------
   -- E1000_Check_For_Serdes_Link_82571 --
   ---------------------------------------

   --  Check for link (Serdes).
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Reports the link state as up or down.
   --  *
   --  *  If autonegotiation is supported by the link partner, the link state is
   --  *  determined by the result of autonegotiation. This is the most likely case.
   --  *  If autonegotiation is not supported by the link partner, and the link
   --  *  has a valid signal, force the link up.
   --  *
   --  *  The link state is represented internally here by 4 states:
   --  *
   --  *  1) down
   --  *  2) autoneg_progress
   --  *  3) autoneg_complete (the link successfully autonegotiated)
   --  *  4) forced_up (the link has been forced up, it did not autonegotiate)


   function E1000_Check_For_Serdes_Link_82571
     (HW : access E1000_HW) return s32
   is
      Mac     : E1000_Mac_Info.item renames HW.Mac;
      Rxcw    : Unsigned_32;
      Ctrl    : Unsigned_32;
      Status  : Unsigned_32;
      Txcw    : Unsigned_32;
      Ret_Val : s32        := 0;
      Unused  : u32;

   begin
      Ctrl   := Er32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL);
      Status := Er32 (Hw.all, Devices.e1000e.Registers.E1000_STATUS);
      Unused := Er32 (Hw.all, Devices.e1000e.Registers.E1000_RXCW);

      -- SYNCH bit and IV bit are sticky.
      --
      delay 15.0 * Microseconds;     -- Equivalent to usleep_range(10, 20)
      Rxcw := Er32 (Hw.all, Devices.e1000e.Registers.E1000_RXCW);


      if         (Rxcw and E1000_RXCW_SYNCH) /= 0
        and then (Rxcw and E1000_RXCW_IV)     = 0
      then
         -- Receiver is synchronized with no invalid bits.
         --
         case Mac.Serdes_Link_State
         is
            when E1000_Serdes_Link_Autoneg_Complete =>

               if (Status and E1000_STATUS_LU) = 0
               then
                  -- We have lost link, retry autoneg before reporting link failure.
                  --
                  Mac.Serdes_Link_State := E1000_Serdes_Link_Autoneg_Progress;
                  Mac.Serdes_Has_Link   := False;

                  e_dbg ("AN_UP     -> AN_PROG");
               else
                  Mac.Serdes_Has_Link := True;
               end if;


            when E1000_Serdes_Link_Forced_Up =>

               -- If we are receiving /C/ ordered sets, re-enable auto-negotiation in the TXCW register
               -- and disable forced link in the Device Control register in an attempt to auto-negotiate
               -- with our link partner.
               --
               if (Rxcw and E1000_RXCW_C) /= 0
               then
                  -- Enable autoneg, and unforce link up.
                  --
                  Ew32 (Hw.all, Devices.e1000e.Registers.E1000_TXCW, Mac.Txcw);
                  Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, (Ctrl and (not E1000_CTRL_SLU)));

                  Mac.Serdes_Link_State := E1000_Serdes_Link_Autoneg_Progress;
                  Mac.Serdes_Has_Link := False;

                  e_dbg ("FORCED_UP -> AN_PROG");
               else
                  Mac.Serdes_Has_Link := True;
               end if;


            when E1000_Serdes_Link_Autoneg_Progress =>

               if (Rxcw and E1000_RXCW_C) /= 0
               then
                  -- We received /C/ ordered sets, meaning the link partner has autonegotiated,
                  -- and we can trust the Link Up (LU) status bit.
                  --
                  if (Status and E1000_STATUS_LU) /= 0
                  then
                     Mac.Serdes_Link_State := E1000_Serdes_Link_Autoneg_Complete;
                     e_dbg ("AN_PROG   -> AN_UP");
                     Mac.Serdes_Has_Link := True;
                  else
                     -- Autoneg completed, but failed.
                     --
                     Mac.Serdes_Link_State := E1000_Serdes_Link_Down;
                     e_dbg ("AN_PROG   -> DOWN");
                  end if;

               else
                  -- The link partner did not autoneg. Force link up and full duplex, and change state to forced.
                  --
                  Ew32 (Hw.all, Devices.e1000e.Registers.E1000_TXCW, (Mac.Txcw and (not E1000_TXCW_ANE)));
                  Ctrl := Ctrl or (E1000_CTRL_SLU or E1000_CTRL_FD);
                  Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, Ctrl);

                  -- Configure Flow Control after link up.
                  --
                  Ret_Val := E1000e_Config_Fc_After_Link_Up (HW);

                  if Ret_Val /= 0
                  then
                     e_dbg ("Error config flow control");
                     return Ret_Val;
                  end if;

                  Mac.Serdes_Link_State := E1000_Serdes_Link_Forced_Up;
                  Mac.Serdes_Has_Link   := True;
                  e_dbg ("AN_PROG   -> FORCED_UP");
               end if;


            when others =>

               -- The link was down but the receiver has now gained valid sync, so lets see if we can bring the link up.
               --
               Ew32 (Hw.all, Devices.e1000e.Registers.E1000_TXCW, Mac.Txcw);
               Ew32 (Hw.all, Devices.e1000e.Registers.E1000_CTRL, (Ctrl and (not E1000_CTRL_SLU)));

               Mac.Serdes_Link_State := E1000_Serdes_Link_Autoneg_Progress;
               Mac.Serdes_Has_Link   := False;

               e_dbg ("DOWN      -> AN_PROG");
         end case;

      else
         if (Rxcw and E1000_RXCW_SYNCH) = 0
         then
            Mac.Serdes_Has_Link   := False;
            Mac.Serdes_Link_State := E1000_Serdes_Link_Down;

            e_dbg ("ANYSTATE  -> DOWN");

         else
            -- Check several times, if SYNCH bit and CONFIG bit both are consistently 1
            -- then simply ignore the IV bit and restart Autoneg.
            --
            for I in 1 .. AN_RETRY_COUNT
            loop
               delay 15.0 * Microseconds;     -- Equivalent to usleep_range(10, 20).

               Rxcw := Er32 (Hw.all, Devices.e1000e.Registers.E1000_RXCW);

               if         (Rxcw and E1000_RXCW_SYNCH) /= 0
                 and then (Rxcw and E1000_RXCW_C)     /= 0
               then
                  goto Continue;
               end if;

               if (Rxcw and E1000_RXCW_IV) /= 0
               then
                  Mac.Serdes_Has_Link   := False;
                  Mac.Serdes_Link_State := E1000_Serdes_Link_Down;

                  e_dbg ("ANYSTATE  -> DOWN");

                  return Ret_Val;
               end if;

               <<Continue>>
            end loop;

            Txcw := Er32 (Hw.all, Devices.e1000e.Registers.E1000_TXCW);
            Txcw := Txcw or E1000_TXCW_ANE;
            Ew32 (Hw.all, Devices.e1000e.Registers.E1000_TXCW, Txcw);

            Mac.Serdes_Link_State := E1000_Serdes_Link_Autoneg_Progress;
            Mac.Serdes_Has_Link   := False;

            e_dbg ("ANYSTATE  -> AN_PROG");
         end if;

      end if;


      return Ret_Val;
   end E1000_Check_For_Serdes_Link_82571;




   -----------------------------------
   -- E1000_Valid_LED_Default_82571 --
   -----------------------------------

   --    Verify a valid default LED config.
   --
   --  *  @hw:   Pointer to the HW structure.
   --  *  @data: Pointer to the NVM (EEPROM).
   --  *
   --  *  Read the EEPROM for the current default LED configuration.  If the
   --  *  LED configuration is not valid, set to a valid LED configuration.


   function E1000_Valid_LED_Default_82571
     (HW   : access E1000_HW;
      Data : in     u16_Pointer) return s32
   is
      Ret_Val : s32;

   begin
      Ret_Val := E1000_Read_NVM (HW, NVM_ID_LED_SETTINGS, 1, Data);

      if Ret_Val /= 0
      then
         e_dbg("NVM Read Error");
         return Ret_Val;
      end if;


      case HW.Mac.Mac_Type
      is
         when E1000_82573
            | E1000_82574
            | E1000_82583 =>

            if Data.all = ID_LED_RESERVED_F746
            then
               Data.all := u16 (ID_LED_DEFAULT_82573);
            end if;

         when others =>

            if   Data.all = ID_LED_RESERVED_0000
              or Data.all = ID_LED_RESERVED_FFFF
            then
               Data.all := u16 (ID_LED_DEFAULT);
            end if;
      end case;


      return 0;
   end E1000_Valid_LED_Default_82571;




   ----------------------------------
   -- E1000_Fix_NVM_Checksum_82571 --
   ----------------------------------

   function E1000_Fix_NVM_Checksum_82571
     (HW : access E1000_HW) return s32
   is
      NVM     : E1000_NVM_Info.item renames HW.NVM;
      Ret_Val :         s32;
      Data    : aliased Unsigned_16;

   begin
      if NVM.NVM_Type /= E1000_NVM_Flash_HW
      then
         return 0;
      end if;

      -- Check bit 4 of word 10h. If it is 0, firmware is done updating
      -- 10h-12h. Checksum may need to be fixed.
      --
      Ret_Val := E1000_Read_NVM (HW, 16#10#, 1, Data'unchecked_Access);

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      if (Data and 16#10#) = 0
      then
         -- Read 0x23 and check bit 15. This bit is a 1
         -- when the checksum has already been fixed. If
         -- the checksum is still wrong and this bit is a
         -- 1, we need to return bad checksum. Otherwise,
         -- we need to set this bit to a 1 and update the
         -- checksum.
         --
         Ret_Val := E1000_Read_NVM (HW, 16#23#, 1, Data'unchecked_Access);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;

         if (Data and 16#8000#) = 0
         then
            Data    := Data or 16#8000#;
            Ret_Val := E1000_Write_NVM (HW, 16#23#, 1, Data'unchecked_Access);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;

            Ret_Val := E1000e_Update_NVM_Checksum (HW);

            if Ret_Val /= 0
            then
               return Ret_Val;
            end if;
         end if;
      end if;


      return 0;
   end E1000_Fix_NVM_Checksum_82571;




   -------------------------------
   -- E1000_Read_Mac_Addr_82571 --
   -------------------------------

   --  Read device MAC address.
   --
   --  *  @hw: Pointer to the HW structure.


   function E1000_Read_Mac_Addr_82571
     (HW : access E1000_HW) return S32
   is
      Ret_Val : S32;

   begin
      if HW.Mac.Mac_Type = E1000_82571
      then
         -- If there's an alternate MAC address place it in RAR0
         -- so that it will override the Si installed default perm
         -- address.
         --
         Ret_Val := E1000_Check_Alt_Mac_Addr_Generic (HW);

         if Ret_Val /= 0
         then
            return Ret_Val;
         end if;
      end if;

      return E1000_Read_Mac_Addr_Generic (HW);
   end E1000_Read_Mac_Addr_82571;




   ---------------------------------
   -- Power_Down_PHY_Copper_82571 --
   ---------------------------------

   --  Remove link during PHY power down.
   --
   --  * @hw: Pointer to the HW structure.
   --  *
   --  * In the case of a PHY power down to save power, or to turn off link during a
   --  * driver unload, or wake on lan is not enabled, remove the link.


   procedure Power_Down_PHY_Copper_82571
     (HW : access E1000_HW)
   is
      use type Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.item;

      PHY : E1000_PHY_Info.item renames HW.PHY;
      MAC : E1000_MAC_Info.item renames HW.MAC;

   begin
      if PHY.Ops.Check_Reset_Block = null
      then
         return;
      end if;

      -- If the management interface is not enabled, then power down.
      --
      if not (        MAC.Ops.Check_Mng_Mode    (HW)
              or else PHY.Ops.Check_Reset_Block (HW) /= 0)
      then
         e1000_power_down_phy_copper (HW);
      end if;
   end Power_Down_PHY_Copper_82571;




   --------------------------------
   -- E1000_Clear_Hw_Cntrs_82571 --
   --------------------------------

   --  Clear device specific hardware counters.
   --
   --  *  @hw: Pointer to the HW structure.
   --  *
   --  *  Clears the hardware counters by reading the counter registers.


   procedure E1000_Clear_Hw_Cntrs_82571
     (Hw : access E1000_Hw)
   is
   begin
      E1000e_Clear_Hw_Cntrs_Base (Hw);

      Er32 (Hw.all, Devices.e1000e.Registers.E1000_PRC64);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_PRC127);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_PRC255);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_PRC511);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_PRC1023);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_PRC1522);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_PTC64);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_PTC127);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_PTC255);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_PTC511);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_PTC1023);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_PTC1522);

      Er32 (Hw.all, Devices.e1000e.Registers.E1000_ALGNERRC);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_RXERRC);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_TNCRS);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_CEXTERR);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_TSCTC);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_TSCTFC);

      Er32 (Hw.all, Devices.e1000e.Registers.E1000_MGTPRC);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_MGTPDC);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_MGTPTC);

      Er32 (Hw.all, Devices.e1000e.Registers.E1000_IAC);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_ICRXOC);

      Er32 (Hw.all, Devices.e1000e.Registers.E1000_ICRXPTC);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_ICRXATC);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_ICTXPTC);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_ICTXATC);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_ICTXQEC);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_ICTXQMTC);
      Er32 (Hw.all, Devices.e1000e.Registers.E1000_ICRXDMTC);
   end E1000_Clear_Hw_Cntrs_82571;




   ---------------------------------------------------------------------------
   --                              Public Subprograms                       --
   ---------------------------------------------------------------------------


   ---------------------------
   -- e1000_check_phy_82574 --
   ---------------------------

   -- Check 82574 phy hung state.
   --
   --  @hw: Pointer to the HW structure.
   --
   --  Returns whether phy is hung or not.


   function e1000_check_phy_82574
     (hw    : access e1000_hw) return Boolean
   is
      Status_1kbt    : aliased Unsigned_16 := 0;
      Receive_Errors : aliased Unsigned_16 := 0;
      Ret_Val        :         s32;

   begin
      -- Read PHY Receive Error counter first, if it is max - all F's then
      -- read the Base1000T status register. If both are max then PHY is hung.
      --
      Ret_Val := E1e_rPhy (Hw,
                           E1000_Receive_Error_Counter,
                           Receive_Errors'unchecked_Access);
      if Ret_Val /= 0
      then
         return False;
      end if;

      if Receive_Errors = E1000_Receive_Error_Max
      then
         Ret_Val := E1e_rPhy (Hw,
                              E1000_Base1000t_Status,
                              Status_1kbt'unchecked_Access);
         if Ret_Val /= 0
         then
            return False;
         end if;

         if (Status_1kbt and E1000_Idle_Error_Count_Mask) = E1000_Idle_Error_Count_Mask
         then
            return True;
         end if;
      end if;

      return False;
   end e1000_check_phy_82574;




   --------------------------------
   -- e1000e_get_laa_state_82571 --
   --------------------------------

   --   Get locally administered address state.
   --
   --   @hw: Pointer to the HW structure.
   --
   --   Retrieve and return the current locally administered address state.

   function e1000e_get_laa_state_82571 (hw : access e1000_hw) return Boolean
   is
   begin
      if hw.mac.mac_type /= e1000_82571
      then
         return False;
      end if;

      return hw.dev_spec.e82571.laa_is_present;
   end e1000e_get_laa_state_82571;




   --------------------------------
   -- e1000e_set_laa_state_82571 --
   --------------------------------

   --   Set locally administered address state.
   --
   --   @hw:    Pointer to the HW structure.
   --   @state: Enable/disable locally administered address.
   --
   --   Enable/Disable the current locally administered address state.

   procedure e1000e_set_laa_state_82571
     (hw    : access e1000_hw;
      state : in     Boolean)
   is
   begin
      if hw.mac.mac_type /= e1000_82571
      then
         return;
      end if;

      hw.dev_spec.e82571.laa_is_present := state;

      if state     -- Workaround is activated.
      then
         -- Hold a copy of the LAA in RAR[14] This is done so that
         -- between the time RAR[0] gets clobbered and the time it
         -- gets fixed, the actual LAA is in one of the RARs and no
         -- incoming packets directed to this port are dropped.
         -- Eventually the LAA will be in RAR[0] and RAR[14].
         --
         declare
            Unused : c.Int;
         begin
            Unused := hw.mac.ops.rar_set (hw,
                                          hw.mac.addr (hw.mac.addr'First)'Access,
                                          u32 (hw.mac.rar_entry_count - 1));
         end;
      end if;
   end e1000e_set_laa_state_82571;


end Devices.e1000e.an_82571;
