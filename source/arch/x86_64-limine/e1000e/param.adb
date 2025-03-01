with
     Interfaces.C;



package body Param
is
   use Interfaces;



   procedure dummy is null;




   E1000_MAX_NIC : constant := 32;

   type Option_State is (Unset, Disabled, Enabled);
   for Option_State use (Unset => -1, Disabled => 0, Enabled => 1);

   COPYBREAK_DEFAULT : constant   := 256;
   Copybreak         : C.unsigned := COPYBREAK_DEFAULT;



   ------------------
   -- E1000_Option --
   ------------------

   type a_Range_Option is
      record
         Min : Integer;
         Max : Integer;
      end record;

   type E1000_Opt_List;
   type E1000_Opt_List_Access is access E1000_Opt_List;

   type E1000_Opt_List is record
      I   :        Integer;
      Str : access String;
   end record;

   type a_List_Option is
      record
         Nr : Integer;
         P  : E1000_Opt_List_Access;
      end record;

   type Option_Arg (Is_Range : Boolean := True) is
      record
         case Is_Range
         is
            when True  =>   R : a_Range_Option;
            when False =>   L : a_List_Option;
         end case;
      end record
     with
       unchecked_Union;


   type Option_Type is (Enable_Option, Range_Option, List_Option);

   type E1000_Option is
      record
         Option      :        Option_Type;
         Name        : access String;
         Err         : access String;
         Def         :        Integer;
         Arg         :        Option_Arg;
      end record;






--     function E1000_Validate_Option
--    (Value   : in out Natural;
--     Opt     : access constant E1000_Option;
--     Adapter : access E1000_Adapter) return Integer is
--
--     procedure Dev_Info (Message : String) is
--     begin
--        E_Dbg (Adapter.Pdev.Dev'Access, Message);
--     end Dev_Info;
--
--  begin
--     if Value = OPTION_UNSET then
--        Value := Opt.Def;
--        return 0;
--     end if;
--
--     case Opt.Option_Type is
--        when Enable_Option =>
--           case Value is
--              when OPTION_ENABLED =>
--                 Dev_Info (Opt.Name & " Enabled");
--                 return 0;
--              when OPTION_DISABLED =>
--                 Dev_Info (Opt.Name & " Disabled");
--                 return 0;
--              when others =>
--                 null;
--           end case;
--
--        when Range_Option =>
--           if Value >= Opt.Arg.R.Min and Value <= Opt.Arg.R.Max then
--              Dev_Info (Opt.Name & " set to " & Value'Image);
--              return 0;
--           end if;
--
--        when List_Option =>
--           for I in 1 .. Opt.Arg.L.Nr loop
--              declare
--                 Ent : E1000_Opt_List renames Opt.Arg.L.P (I);
--              begin
--                 if Value = Ent.I then
--                    if Ent.Str /= "" then
--                       Dev_Info (Ent.Str);
--                    end if;
--                    return 0;
--                 end if;
--              end;
--           end loop;
--
--        when others =>
--           raise Program_Error with "Invalid option type";
--     end case;
--
--     Dev_Info ("Invalid " & Opt.Name & " value specified (" & Value'Image & ") " & Opt.Err);
--     Value := Opt.Def;
--     return -1;
--  end E1000_Validate_Option;








   --  procedure E1000e_Check_Options (Adapter : access E1000_Adapter) is
   --     HW : access E1000_HW := Adapter.HW'Access;
   --     BD : Integer := Adapter.BD_Number;
   --
   --  begin
   --     if BD >= E1000_MAX_NIC then
   --        e_dbg ("Warning: no configuration for board #" & Integer'Image (BD));
   --        e_dbg ("Using defaults for all values");
   --     end if;
   --
   --     -- Transmit Interrupt Delay
   --     declare
   --        Opt : constant E1000_Option := (
   --                                        Option_Type => Range_Option,
   --                                        Name        => "Transmit Interrupt Delay",
   --                                        Err         => "using default of " & DEFAULT_TIDV'Image,
   --                                        Def         => DEFAULT_TIDV,
   --                                        Arg         => (R => (Min => MIN_TXDELAY, Max => MAX_TXDELAY))
   --                                       );
   --     begin
   --        if Num_TxIntDelay > BD then
   --           Adapter.Tx_Int_Delay := TxIntDelay (BD);
   --           Validate_Option (Adapter.Tx_Int_Delay, Opt, Adapter);
   --        else
   --           Adapter.Tx_Int_Delay := Opt.Def;
   --        end if;
   --     end;
   --
   --     -- Transmit Absolute Interrupt Delay
   --     declare
   --        Opt : constant E1000_Option := (
   --                                        Option_Type => Range_Option,
   --                                        Name        => "Transmit Absolute Interrupt Delay",
   --                                        Err         => "using default of " & DEFAULT_TADV'Image,
   --                                        Def         => DEFAULT_TADV,
   --                                        Arg         => (R => (Min => MIN_TXABSDELAY, Max => MAX_TXABSDELAY))
   --                                       );
   --     begin
   --        if Num_TxAbsIntDelay > BD then
   --           Adapter.Tx_Abs_Int_Delay := TxAbsIntDelay (BD);
   --           Validate_Option (Adapter.Tx_Abs_Int_Delay, Opt, Adapter);
   --        else
   --           Adapter.Tx_Abs_Int_Delay := Opt.Def;
   --        end if;
   --     end;
   --
   --     -- Receive Interrupt Delay
   --     declare
   --        Opt : E1000_Option := (
   --                               Option_Type => Range_Option,
   --                               Name        => "Receive Interrupt Delay",
   --                               Err         => "using default of " & DEFAULT_RDTR'Image,
   --                               Def         => DEFAULT_RDTR,
   --                               Arg         => (R => (Min => MIN_RXDELAY, Max => MAX_RXDELAY))
   --                              );
   --     begin
   --        if (Adapter.Flags2 and FLAG2_DMA_BURST) /= 0 then
   --           Opt.Def := BURST_RDTR;
   --        end if;
   --
   --        if Num_RxIntDelay > BD then
   --           Adapter.Rx_Int_Delay := RxIntDelay (BD);
   --           Validate_Option (Adapter.Rx_Int_Delay, Opt, Adapter);
   --        else
   --           Adapter.Rx_Int_Delay := Opt.Def;
   --        end if;
   --     end;
   --
   --     -- Receive Absolute Interrupt Delay
   --     declare
   --        Opt : E1000_Option := (
   --                               Option_Type => Range_Option,
   --                               Name        => "Receive Absolute Interrupt Delay",
   --                               Err         => "using default of " & DEFAULT_RADV'Image,
   --                               Def         => DEFAULT_RADV,
   --                               Arg         => (R => (Min => MIN_RXABSDELAY, Max => MAX_RXABSDELAY))
   --                              );
   --     begin
   --        if (Adapter.Flags2 and FLAG2_DMA_BURST) /= 0 then
   --           Opt.Def := BURST_RADV;
   --        end if;
   --
   --        if Num_RxAbsIntDelay > BD then
   --           Adapter.Rx_Abs_Int_Delay := RxAbsIntDelay (BD);
   --           Validate_Option (Adapter.Rx_Abs_Int_Delay, Opt, Adapter);
   --        else
   --           Adapter.Rx_Abs_Int_Delay := Opt.Def;
   --        end if;
   --     end;
   --
   --     -- Interrupt Throttling Rate
   --     declare
   --        Opt : constant E1000_Option := (
   --                                        Option_Type => Range_Option,
   --                                        Name        => "Interrupt Throttling Rate (ints/sec)",
   --                                        Err         => "using default of " & DEFAULT_ITR'Image,
   --                                        Def         => DEFAULT_ITR,
   --                                        Arg         => (R => (Min => MIN_ITR, Max => MAX_ITR))
   --                                       );
   --     begin
   --        if Num_InterruptThrottleRate > BD then
   --           Adapter.ITR := InterruptThrottleRate (BD);
   --
   --           if Adapter.ITR > 4 and then
   --             Validate_Option (Adapter.ITR, Opt, Adapter) then
   --              Adapter.ITR := Opt.Def;
   --           end if;
   --        else
   --           Adapter.ITR := Opt.Def;
   --
   --           if Adapter.ITR > 4 then
   --              e_dbg (Opt.Name & " set to default " & Adapter.ITR'Image);
   --           end if;
   --        end if;
   --
   --        Adapter.ITR_Setting := Adapter.ITR;
   --        case Adapter.ITR is
   --        when 0 =>
   --           e_dbg (Opt.Name & " turned off");
   --        when 1 =>
   --           e_dbg (Opt.Name & " set to dynamic mode");
   --           Adapter.ITR := 20000;
   --        when 2 =>
   --           e_dbg (Opt.Name & " Invalid mode - setting default");
   --           Adapter.ITR_Setting := Opt.Def;
   --           Adapter.ITR := 20000;
   --        when 3 =>
   --           e_dbg (Opt.Name & " set to dynamic conservative mode");
   --           Adapter.ITR := 20000;
   --        when 4 =>
   --           e_dbg (Opt.Name & " set to simplified (2000-8000 ints) mode");
   --        when others =>
   --           Adapter.ITR_Setting := Adapter.ITR_Setting and not 3;
   --        end case;
   --     end;
   --
   --     -- Interrupt Mode
   --     declare
   --        Opt : E1000_Option := (
   --                               Option_Type => Range_Option,
   --                               Name        => "Interrupt Mode",
   --                               Err         => "defaulting to 0 (legacy)",
   --                               Def         => E1000E_INT_MODE_LEGACY,
   --                               Arg         => (R => (Min => 0, Max => 0))
   --                              );
   --     begin
   --        if Num_IntMode > BD then
   --           declare
   --              Int_Mode : Integer := IntMode (BD);
   --           begin
   --              Validate_Option (Int_Mode, Opt, Adapter);
   --              Adapter.Int_Mode := Int_Mode;
   --           end;
   --        else
   --           Adapter.Int_Mode := Opt.Def;
   --        end if;
   --     end;
   --
   --     -- Smart Power Down
   --     declare
   --        Opt : constant E1000_Option := (
   --                                        Option_Type => Enable_Option,
   --                                        Name        => "PHY Smart Power Down",
   --                                        Err         => "defaulting to Disabled",
   --                                        Def         => OPTION_DISABLED
   --                                       );
   --     begin
   --        if Num_SmartPowerDownEnable > BD then
   --           declare
   --              SPD : Integer := SmartPowerDownEnable (BD);
   --           begin
   --              Validate_Option (SPD, Opt, Adapter);
   --              if (Adapter.Flags and FLAG_HAS_SMART_POWER_DOWN) /= 0 and SPD /= 0 then
   --                 Adapter.Flags := Adapter.Flags or FLAG_SMART_POWER_DOWN;
   --              end if;
   --           end;
   --        end if;
   --     end;
   --
   --     -- CRC Stripping
   --     declare
   --        Opt : constant E1000_Option := (
   --                                        Option_Type => Enable_Option,
   --                                        Name        => "CRC Stripping",
   --                                        Err         => "defaulting to Enabled",
   --                                        Def         => OPTION_ENABLED
   --                                       );
   --     begin
   --        if Num_CrcStripping > BD then
   --           declare
   --              CRC_Stripping : Integer := CrcStripping (BD);
   --           begin
   --              Validate_Option (CRC_Stripping, Opt, Adapter);
   --              if CRC_Stripping = OPTION_ENABLED then
   --                 Adapter.Flags2 := Adapter.Flags2 or FLAG2_CRC_STRIPPING;
   --                 Adapter.Flags2 := Adapter.Flags2 or FLAG2_DFLT_CRC_STRIPPING;
   --              end if;
   --           end;
   --        else
   --           Adapter.Flags2 := Adapter.Flags2 or FLAG2_CRC_STRIPPING;
   --           Adapter.Flags2 := Adapter.Flags2 or FLAG2_DFLT_CRC_STRIPPING;
   --        end if;
   --     end;
   --
   --     -- Kumeran Lock Loss Workaround
   --     declare
   --        Opt : constant E1000_Option := (
   --                                        Option_Type => Enable_Option,
   --                                        Name        => "Kumeran Lock Loss Workaround",
   --                                        Err         => "defaulting to Enabled",
   --                                        Def         => OPTION_ENABLED
   --                                       );
   --        Enabled : Boolean := Opt.Def = OPTION_ENABLED;
   --     begin
   --        if Num_KumeranLockLoss > BD then
   --           declare
   --              KMRN_Lock_Loss : Integer := KumeranLockLoss (BD);
   --           begin
   --              Validate_Option (KMRN_Lock_Loss, Opt, Adapter);
   --              Enabled := KMRN_Lock_Loss = OPTION_ENABLED;
   --           end;
   --        end if;
   --
   --        if HW.Mac.Mac_Type = e1000_ich8lan then
   --           E1000e_Set_Kmrn_Lock_Loss_Workaround_Ich8lan (HW, Enabled);
   --        end if;
   --     end;
   --
   --     -- Write-protect NVM
   --     declare
   --        Opt : constant E1000_Option := (
   --                                        Option_Type => Enable_Option,
   --                                        Name        => "Write-protect NVM",
   --                                        Err         => "defaulting to Enabled",
   --                                        Def         => OPTION_ENABLED
   --                                       );
   --     begin
   --        if (Adapter.Flags and FLAG_IS_ICH) /= 0 then
   --           if Num_WriteProtectNVM > BD then
   --              declare
   --                 Write_Protect_NVM : Integer := WriteProtectNVM (BD);
   --              begin
   --                 Validate_Option (Write_Protect_NVM, Opt, Adapter);
   --                 if Write_Protect_NVM = OPTION_ENABLED then
   --                    Adapter.Flags := Adapter.Flags or FLAG_READ_ONLY_NVM;
   --                 end if;
   --              end;
   --           elsif Opt.Def = OPTION_ENABLED then
   --              Adapter.Flags := Adapter.Flags or FLAG_READ_ONLY_NVM;
   --           end if;
   --        end if;
   --     end;
   --  end E1000e_Check_Options;


end Param;
