with
     Devices.e1000e.Core,
     Devices.e1000e.Defines,
     Devices.e1000e.Registers,
     Devices.e1000e.Hardware.E1000_Hw,
     Devices.e1000e.NetDev,
     Devices.e1000e.Base.Port,
     Linux,
     interfaces.C,
     system.Address_to_Access_Conversions;


package body Devices.e1000e.Precision_Time_Protocol
is
   use Devices.e1000e.Core,
       Devices.e1000e.Defines,
       Devices.e1000e.Hardware,
       Devices.e1000e.Registers,
       Devices.e1000e.Base.Port,
       Linux,
       Interfaces;

   use type C.unsigned,
            C.int;


   subtype e1000_hw is Devices.e1000e.Hardware.e1000_hw.item;


   package E1000_Adapter_Conversions is new system.Address_to_Access_Conversions (E1000_Adapter.item);




   --  Adjust the frequency of the hardware clock.
   --
   --  * @ptp:   Ptp clock structure.
   --  * @delta: Desired frequency chance in scaled parts per million.
   --  *
   --  * Adjust the frequency of the PHC cycle counter by the indicated delta from
   --  * the base frequency.
   --  *
   --  * Scaled parts per million is ppm but with a 16 bit binary fractional field.


   function E1000e_Phc_Adjfine
     (Ptp       : access PTP_Clock_Info;
      the_Delta : in     C.long) return C.int
   is
      Adapter  : constant E1000_Adapter.Pointer := E1000_Adapter.Pointer (E1000_Adapter_Conversions.to_Pointer (container_of (Ptp.all'Address)));
                                                                                                                          --  struct e1000_adapter,
                                                                                                                          --      ptp_clock_info);
      Hw       : constant access E1000_HW       := Adapter.Hw'Access;
      Flags    :                 C.unsigned_long;
      Incvalue :                 Unsigned_64;
      Timinca  : aliased         Unsigned_32;
      Ret_Val  :                 C.int;

   begin
      -- Get the System Time Register SYSTIM base frequency.
      --
      Ret_Val := C.int (Devices.e1000e.NetDev.E1000e_Get_Base_Timinca (Adapter, Timinca'Access));

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      spin_lock_irqsave (adapter.systim_lock'Access, flags);

      Incvalue := Unsigned_64 (Timinca and E1000_TIMINCA_INCVALUE_MASK);
      Incvalue := Adjust_By_Scaled_Ppm (Incvalue, the_Delta);

      Timinca := Timinca and (not E1000_TIMINCA_INCVALUE_MASK);
      Timinca := Timinca or Unsigned_32 (Incvalue);

      Ew32 (Hw.all, E1000_TIMINCA, Timinca);

      Adapter.Ptp_Delta := the_Delta;

      spin_unlock_irqrestore (adapter.systim_lock'Access, flags);

      return 0;
   end E1000e_Phc_Adjfine;





   -- Shift the time of the hardware clock.
   --
   --  * @ptp:   Ptp clock structure
   --  * @delta: Desired change in nanoseconds
   --  *
   --  * Adjust the timer by resetting the timecounter structure.


   function E1000e_Phc_Adjtime
     (Ptp       : access PTP_Clock_Info;
      the_Delta : in     Integer_64) return C.int
   is
      Adapter : constant E1000_Adapter.Pointer := E1000_Adapter.Pointer (E1000_Adapter_Conversions.to_Pointer (container_of (Ptp.all'Address)));
                                                                                                                          --  struct e1000_adapter,
                                                                                                                          --      ptp_clock_info);
      Flags   : C.unsigned_long;

   begin
      spin_lock_irqsave (adapter.systim_lock'Access, flags);

      Timecounter_Adjtime (Adapter.Tc'Access, the_Delta);

      spin_unlock_irqrestore (adapter.systim_lock'Access, flags);

      return 0;
   end E1000e_Phc_Adjtime;





--  #ifdef CONFIG_E1000E_HWTS

   MAX_HW_WAIT_COUNT : constant := 3;



   --  Callback given to timekeeping code reads system/device registers.
   --
   --   * @device: Current device time.
   --   * @system: System counter value read synchronously with device time.
   --   * @ctx:    Context provided by timekeeping code.
   --   *
   --   * Read device and system (ART) clock simultaneously and return the corrected
   --   * clock values in ns.


   function E1000e_PHC_Get_Syncdevicetime
     (Device : access ktime_t;
      System : access System_Counterval_T;
      Ctx    : in     void_ptr) return C.int
   is
      Adapter : E1000_Adapter.item
        with
          Import,
          Address => Ctx;

      Hw         : constant access E1000_HW       := Adapter.Hw'Access;
      Flags      :                 C.unsigned_long;
      Tsync_Ctrl :                 Unsigned_32;
      Dev_Cycles :                 Unsigned_64;
      Sys_Cycles :                 Unsigned_64;

   begin
      Tsync_Ctrl := Er32 (Hw.all, E1000_TSYNCTXCTL);
      Tsync_Ctrl :=    Tsync_Ctrl
                    or E1000_TSYNCTXCTL_START_SYNC
                    or E1000_TSYNCTXCTL_MAX_ALLOWED_DLY_MASK;
      Ew32 (Hw.all, E1000_TSYNCTXCTL, Tsync_Ctrl);

      for I in 1 .. MAX_HW_WAIT_COUNT
      loop
         delay 0.00_000_1;     -- 1 microsecond delay.
         Tsync_Ctrl := Er32 (Hw.all, E1000_TSYNCTXCTL);
         exit when (Tsync_Ctrl and E1000_TSYNCTXCTL_SYNC_COMP) /= 0;
      end loop;

      if (Tsync_Ctrl and E1000_TSYNCTXCTL_SYNC_COMP) = 0
      then
         return -ETIMEDOUT;
      end if;

      Dev_Cycles :=    shift_Left (Unsigned_64 (Er32 (Hw.all, E1000_SYSSTMPH)), 32)
                    or Unsigned_64 (Er32 (Hw.all, E1000_SYSSTMPL));

      spin_lock_irqsave (adapter.systim_lock'Access, flags);
      Device.all := NS_To_kTime (Timecounter_Cyc2time (Adapter.Tc'Access, Dev_Cycles));
      spin_unlock_irqrestore (adapter.systim_lock'Access, flags);

      Sys_Cycles    :=    shift_Left (Unsigned_64 (Er32 (Hw.all, E1000_PLTSTMPH)), 32)
                       or Unsigned_64 (Er32 (Hw.all, E1000_PLTSTMPL));
      System.Cycles := Sys_Cycles;
      System.Cs_Id  := CSID_X86_ART;

      return 0;
   end E1000e_PHC_Get_Syncdevicetime;




   --  Reads the current system/device cross timestamp.
   --
   --  * @ptp:     Ptp clock structure
   --  * @xtstamp: Structure containing timestamp
   --  *
   --  * Read device and system (ART) clock simultaneously and return the scaled
   --  * clock values in ns.


   function E1000e_Phc_Getcrosststamp
     (PTP     : access PTP_Clock_Info;
      Xtstamp : access System_Device_Crosststamp) return C.int
   is
      Adapter : constant E1000_Adapter.Pointer := E1000_Adapter.Pointer (E1000_Adapter_Conversions.to_Pointer (container_of (Ptp.all'Address)));
                                                                                                                         --  struct e1000_adapter,
                                                                                                                     --      ptp_clock_info);
   begin
      return Get_Device_System_Crosststamp (E1000e_Phc_Get_Syncdevicetime'Access,
                                            Adapter.all'Address,
                                            null,
                                            Xtstamp);
   end E1000e_Phc_Getcrosststamp;


   --  #endif /*CONFIG_E1000E_HWTS*/








   --  Reads the current time from the hardware clock and system clock.
   --
   --   * @ptp: Ptp clock structure.
   --   * @ts:  Timespec structure to hold the current PHC time.
   --   * @sts: Structure to hold the current system time.
   --   *
   --   * Read the timecounter and return the correct value in ns after converting
   --   * it into a struct timespec.


   function E1000e_Phc_Gettimex
     (Ptp  : access PTP_Clock_Info;
      Ts   : access timespec64;
      Sts  : access PTP_System_Timestamp) return C.int
   is
      Adapter : constant E1000_Adapter.Pointer := E1000_Adapter.Pointer (E1000_Adapter_Conversions.to_Pointer (container_of (Ptp.all'Address)));
                                                                                                                         --  struct e1000_adapter,
                                                                                                                     --      ptp_clock_info);
      Flags   : C.unsigned_long;
      Cycles  : Unsigned_64;
      Ns      : Unsigned_64;

   begin
      spin_lock_irqsave (adapter.systim_lock'Access, flags);

      -- NOTE: Non-monotonic SYSTIM readings may be returned
      Cycles := Devices.e1000e.NetDev.E1000e_Read_Systim (Adapter, Sts);
      Ns     := Timecounter_Cyc2time (Adapter.Tc'Access, Cycles);

      spin_unlock_irqrestore (adapter.systim_lock'Access, flags);

      ts.all := ns_to_timespec64 (Integer_64 (ns));

      return 0;
   end E1000e_Phc_Gettimex;





   --  Set the current time on the hardware clock.
   --
   --   * @ptp: Ptp clock structure.
   --   * @ts:  Timespec containing the new time for the cycle counter.
   --   *
   --   * Reset the timecounter to use a new base value instead of the kernel
   --   * wall timer value.


   function E1000e_Phc_Settime
     (Ptp : access          PTP_Clock_Info;
      Ts  : access constant Timespec64) return C.int
   is
      Adapter : constant E1000_Adapter.Pointer := E1000_Adapter.Pointer (E1000_Adapter_Conversions.to_Pointer (container_of (Ptp.all'Address)));
                                                                                                                         --  struct e1000_adapter,
                                                                                                                     --      ptp_clock_info);
      Ns    : Unsigned_64;
      Flags : C.Unsigned_Long;

   begin
      Ns := Unsigned_64 (Timespec64_To_Ns (Ts));

      -- Reset the timecounter.
      --
      Spin_Lock_Irqsave      (Adapter.Systim_Lock'Access, Flags);
      Timecounter_Init       (Adapter.Tc'Access, Adapter.Cc'Access, Ns);
      Spin_Unlock_Irqrestore (Adapter.Systim_Lock'Access, Flags);

      return 0;
   end E1000e_Phc_Settime;





   --  Enable or disable an ancillary feature.
   --
   --   * @ptp:     Ptp clock structure.
   --   * @request: Desired resource to enable or disable.
   --   * @on:      Caller passes one to enable or zero to disable.
   --   *
   --   * Enable (or disable) ancillary features of the PHC subsystem.
   --   * Currently, no ancillary features are supported.


   function E1000e_Phc_Enable
     (Ptp     : access PTP_Clock_Info;
      Request : access PTP_Clock_Request;
      On      : in     C.int) return C.int
   is
      pragma Unreferenced (Ptp);
      pragma Unreferenced (Request);
      pragma Unreferenced (On);
   begin
      return -EOPNOTSUPP;
   end E1000e_Phc_Enable;





   procedure E1000e_Systim_Overflow_Work (Work : access Work_Struct)
   is
      Adapter  : constant E1000_Adapter.Pointer := E1000_Adapter.Pointer (E1000_Adapter_Conversions.to_Pointer (container_of (Work.all'Address)));
                                                                                                            --  struct e1000_adapter,
                                                                                                            --  systim_overflow_work.work);
      Hw     : access E1000_Hw := Adapter.Hw'Access;
      Ts     :        timespec64;
      Ns     :        Unsigned_64;
      Unused :        Boolean;

   begin
      -- Update the timecounter.
      --
      Ns := Timecounter_Read (Adapter.Tc'Access);
      ts := ns_to_timespec64 (Integer_64 (ns));

      e_dbg ("SYSTIM overflow check at" & ts.tv_sec'Image & " seconds" & ts.tv_nsec'Image & " nanoseconds.");

      Unused := Schedule_Delayed_Work (Adapter.Systim_Overflow_Work'Access, E1000_SYSTIM_OVERFLOW_PERIOD);
   end E1000e_Systim_Overflow_Work;






   E1000e_PTP_Clock_Info : constant PTP_Clock_Info := (Owner      => null,
                                                       N_Alarm    => 0,
                                                       N_Ext_Ts   => 0,
                                                       N_Per_Out  => 0,
                                                       N_Pins     => 0,
                                                       PPS        => 0,
                                                       Adjfine    => E1000e_PHC_Adjfine 'Access,
                                                       Adjtime    => E1000e_PHC_Adjtime 'Access,
                                                       Gettimex64 => E1000e_PHC_Gettimex'Access,
                                                       Settime64  => E1000e_PHC_Settime 'Access,
                                                       Enable     => E1000e_PHC_Enable  'Access,
                                                       others     => <>);




   --  Initialize PTP for devices which support it.
   --
   --   * @adapter: Board private structure.
   --   *
   --   * This function performs the required steps for enabling PTP support.
   --   * If PTP support has already been loaded it simply calls the cyclecounter
   --   * init routine and exits.


   procedure E1000e_Ptp_Init (Adapter : access E1000_Adapter.item)
   is
      Hw     : access E1000_Hw := Adapter.Hw'Access;
      Unused :        Boolean;

   begin
      Adapter.Ptp_Clock := null;

      if (Adapter.Flags and C.unsigned (FLAG_HAS_HW_TIMESTAMP)) = 0
      then
         return;
      end if;


      Adapter.Ptp_Clock_Info := E1000e_Ptp_Clock_Info;

      declare
         Last : constant Integer := Adapter.Netdev.Perm_Addr'Image'Size;
      begin
         Adapter.Ptp_Clock_Info.Name (1 .. Last) := Adapter.Netdev.Perm_Addr'Image;
      end;

      case Hw.Mac.Mac_Type
      is
         when E1000_Pch2lan =>

            Adapter.Ptp_Clock_Info.Max_Adj := MAX_PPB_96MHZ;


         when E1000_Pch_Lpt =>

            if (Er32 (Hw.all, E1000_TSYNCRXCTL) and E1000_TSYNCRXCTL_SYSCFI) /= 0 then
               Adapter.Ptp_Clock_Info.Max_Adj := MAX_PPB_96MHZ;
            else
               Adapter.Ptp_Clock_Info.Max_Adj := MAX_PPB_25MHZ;
            end if;


         when E1000_Pch_Spt =>

            Adapter.Ptp_Clock_Info.Max_Adj := MAX_PPB_24MHZ;


         when E1000_Pch_Cnp
            | E1000_Pch_Tgp
            | E1000_Pch_Adp
            | E1000_Pch_Mtp
            | E1000_Pch_Lnp
            | E1000_Pch_Ptp
            | E1000_Pch_Nvp =>

            if (Er32 (Hw.all, E1000_TSYNCRXCTL) and E1000_TSYNCRXCTL_SYSCFI) /= 0 then
               Adapter.Ptp_Clock_Info.Max_Adj := MAX_PPB_24MHZ;
            else
               Adapter.Ptp_Clock_Info.Max_Adj := MAX_PPB_38400KHZ;
            end if;


         when E1000_82574 | E1000_82583 =>

            Adapter.Ptp_Clock_Info.Max_Adj := MAX_PPB_25MHZ;


         when others =>
            null;
      end case;


      -- TODO: Assuming CONFIG_E1000E_HWTS is defined.
      --
      --  #ifdef CONFIG_E1000E_HWTS


      --  CPU must have ART and GBe must be from Sunrise Point or greater.
      --
      if         Hw.Mac.Mac_Type >= E1000_Pch_Spt
        --  and then Boot_Cpu_Has (X86_FEATURE_ART)     -- TODO: Can't find this anywhere.
      then
         Adapter.Ptp_Clock_Info.Getcrosststamp := E1000e_Phc_Getcrosststamp'Access;
      end if;

      --  #endif CONFIG_E1000E_HWTS


      Init_Delayed_Work (Adapter.Systim_Overflow_Work, E1000e_Systim_Overflow_Work'Access);

      Unused := Schedule_Delayed_Work (Adapter.Systim_Overflow_Work'Access, E1000_SYSTIM_OVERFLOW_PERIOD);

      Adapter.Ptp_Clock := Ptp_Clock_Register (Adapter.Ptp_Clock_Info'Access, Adapter.Pdev.Dev'Access);

      if Adapter.Ptp_Clock = null
      then
         e_dbg ("ptp_clock_register failed");

      elsif Adapter.Ptp_Clock /= null
      then
         e_dbg ("registered PHC clock");
      end if;
   end E1000e_Ptp_Init;





   --  Disable PTP device and stop the overflow check.
   --
   --   * @adapter: Board private structure.
   --   *
   --   * Stop the PTP support, and cancel the delayed work.


   procedure E1000e_Ptp_Remove (Adapter : access E1000_Adapter.item)
   is
      Unused  : Boolean;
      Unused2 : C.int;

   begin
      if (Adapter.Flags and C.unsigned (FLAG_HAS_HW_TIMESTAMP)) = 0
      then
         return;
      end if;

      Unused := Cancel_Delayed_Work_Sync (Adapter.Systim_Overflow_Work'Access);

      if Adapter.Ptp_Clock /= null
      then
         Unused2           := Ptp_Clock_Unregister (Adapter.Ptp_Clock);
         Adapter.Ptp_Clock := null;

         e_dbg ("removed PHC");
      end if;
   end E1000e_Ptp_Remove;



end Devices.e1000e.Precision_Time_Protocol;
