with
     Devices.e1000e.Core.Pointers,
     Devices.e1000e.Base.Port,
     Devices.e1000e.Hardware.e1000_host_mng_dhcp_cookie,
     Devices.e1000e.Registers,
     Devices.e1000e.Defines,
     Devices.e1000e.Hardware.E1000_Host_Mng_Command_Header,
     Devices.e1000e.an_82571,
     Interfaces.C;


package body Devices.e1000e.Manage
is
   use Devices.e1000e.Core,
       Devices.e1000e.Core.Pointers,
       Devices.e1000e.Registers,
       Devices.e1000e.Defines,
       Devices.e1000e.Base,
       Devices.e1000e.Base.Port,
       Devices.e1000e.Hardware,
       Interfaces;


   use type u32,
            C.size_t;



   --  Calculate checksum for buffer.
   --
   --  @buffer: Pointer to EEPROM.
   --  @length: Size of EEPROM to calculate a checksum for.
   --
   --  Calculates the checksum for some buffer on a specified length.  The
   --  checksum calculated is returned.


   function e1000_calculate_checksum
     (buffer : access U8;
      length : in     U32) return U8
   is
      the_Buffer : u8_array (0 .. C.size_t (Length - 1))
        with
          Address => buffer.all'Address;

      sum : U8 := 0;

   begin
      if buffer = null
      then
         return 0;
      end if;


      for i in 0 .. C.size_t (length - 1)
      loop
         sum := U8'Pos (sum) + U8'Pos (the_buffer (i));
      end loop;

      return U8'Val (0 - U8'Pos(sum));
   end e1000_calculate_checksum;





   --  Checks host interface is enabled.
   --
   --  @hw: Pointer to the HW structure.
   --
   --  Returns 0 upon success, else -E1000_ERR_HOST_INTERFACE_COMMAND
   --
   --  This function checks whether the HOST IF is enabled for command operation
   --  and also checks whether the previous command is completed.  It busy waits
   --  in case of previous command is not completed.


   function e1000_mng_enable_host_if
     (hw : access E1000_Hw) return S32
   is
      hicr : U32;
      i    : U8;

   begin
      if not hw.mac.arc_subsystem_valid
      then
         e_dbg ("ARC subsystem not valid.");
         return -E1000_ERR_HOST_INTERFACE_COMMAND;
      end if;


      --  Check that the host interface is enabled.
      --
      hicr := er32 (Hw.all, E1000_HICR);

      if (hicr and E1000_HICR_EN) = 0
      then
         e_dbg ("E1000_HOST_EN bit disabled.");
         return -E1000_ERR_HOST_INTERFACE_COMMAND;
      end if;


      --  Check the previous command is completed.
      --
      i := 0;

      while i < E1000_MNG_DHCP_COMMAND_TIMEOUT - 1
      loop
         hicr := er32 (Hw.all, E1000_HICR);

         if (hicr and E1000_HICR_C) = 0
         then
            exit;
         end if;

         delay 1.0 * Milliseconds;
         i := i + 1;
      end loop;

      if i = E1000_MNG_DHCP_COMMAND_TIMEOUT
      then
         e_dbg ("Previous command timeout failed.");
         return -E1000_ERR_HOST_INTERFACE_COMMAND;
      end if;

      return 0;
   end e1000_mng_enable_host_if;




   --  Generic check management mode.
   --
   --  @hw: Pointer to the HW structure.
   --
   --  Reads the firmware semaphore register and returns true (>0) if
   --  manageability is enabled, else false (0).


   function e1000e_check_mng_mode_generic
     (hw : access E1000_Hw) return Boolean
   is
      fwsm : constant U32 := er32 (Hw.all, E1000_FWSM);
   begin
      return (fwsm and E1000_FWSM_MODE_MASK) = shift_Left (E1000_MNG_IAMT_MODE, E1000_FWSM_MODE_SHIFT);
   end e1000e_check_mng_mode_generic;





   --  Enable packet filtering on Tx.
   --
   --  @hw: Pointer to the HW structure.
   --
   --  Enables packet filtering on transmit packets if manageability is enabled
   --  and host interface is enabled.


   function e1000e_enable_tx_pkt_filtering
     (Hw : access E1000_Hw) return Boolean
   is
      hdr    : access  Devices.e1000e.Hardware.e1000_host_mng_dhcp_cookie.item := hw.mng_cookie'Access;
      hdr_u8 : aliased U8
        with
          Address => hdr.all'Address;

      offset   : U32;
      ret_val  : S32;
      hdr_csum : S32;
      csum     : S32;
      len      : U8;

   begin
      hw.mac.tx_pkt_filtering := True;

      --  No manageability, no filtering.
      --
      if not hw.mac.ops.check_mng_mode (hw)
      then
         hw.mac.tx_pkt_filtering := False;
         return hw.mac.tx_pkt_filtering;
      end if;


      --  If we can't read from the host interface for whatever
      --  reason, disable filtering.
      --
      ret_val := e1000_mng_enable_host_if (hw);

      if ret_val /= 0
      then
         hw.mac.tx_pkt_filtering := False;
         return hw.mac.tx_pkt_filtering;
      end if;


      --  Read in the header.  Length and offset are in dwords.
      --
      len    := U8  (E1000_MNG_DHCP_COOKIE_LENGTH / 4);
      offset := U32 (E1000_MNG_DHCP_COOKIE_OFFSET / 4);

      declare
         buffer : Devices.e1000e.Core.u32_array (0 .. C.size_t (len - 1))
           with
             Address => hw.mng_cookie'Address;
      begin
         for i in 0 .. C.size_t (len - 1)
         loop
            buffer (i) := E1000_READ_REG_ARRAY (Hw,
                                                E1000_HOST_IF,
                                                offset + u32 (i));
         end loop;
      end;

      hdr_csum     := s32 (hdr.checksum);
      hdr.checksum := 0;
      csum         := s32 (e1000_calculate_checksum (hdr_u8'Access, E1000_MNG_DHCP_COOKIE_LENGTH));

      --  If either the checksums or signature don't match, then
      --  the cookie area isn't considered valid, in which case we
      --  take the safe route of assuming Tx filtering is enabled.
      --
      if   hdr_csum      /= csum
        or hdr.signature /= E1000_IAMT_SIGNATURE
      then
         hw.mac.tx_pkt_filtering := True;
         return hw.mac.tx_pkt_filtering;
      end if;


      --  Cookie area is valid, make the final check for filtering.
      --
      if (hdr.status and E1000_MNG_DHCP_COOKIE_STATUS_PARSING) = 0
      then
         hw.mac.tx_pkt_filtering := False;
      end if;

      return hw.mac.tx_pkt_filtering;
   end e1000e_enable_tx_pkt_filtering;





   --   Writes manageability command header.
   --
   --   @hw:  Pointer to the HW structure.
   --   @hdr: Pointer to the host interface command header.
   --
   --   Writes the command header after does the checksum calculation.


   function e1000_mng_write_cmd_header
     (hw  : access E1000_Hw;
      hdr : access E1000_Host_Mng_Command_Header.item) return S32
   is
      length :         U16 := U16 (E1000_Host_Mng_Command_Header.item'Size / 8);
      hdr_u8 : aliased U8
        with
          Address => hdr.all'Address;

   begin
      --  Write the whole command header structure with new checksum.
      --
      hdr.checksum := e1000_calculate_checksum (hdr_u8'Access, u32 (length));

      length := length / 4;

      --  Write the relevant command block into the ram area.
      --
      declare
         buffer : Devices.e1000e.Core.u32_array (0 .. C.size_t (length - 1))
           with
             Address => hdr.all'Address;
      begin
         for i in 0 .. C.size_t (length - 1)
         loop
            E1000_WRITE_REG_ARRAY (hw,
                                   E1000_HOST_IF,
                                   u32 (i),
                                   Buffer (i));
            e1e_flush (Hw);
         end loop;
      end;

      return 0;
   end e1000_mng_write_cmd_header;




   --  Write to the manageability host interface.
   --
   --  @hw:     Pointer to the HW structure.
   --  @buffer: Pointer to the host interface buffer.
   --  @length: Size of the buffer.
   --  @offset: Location in the buffer to write to.
   --  @sum:    Sum of the data (not checksum).
   --
   --  This function writes the buffer content at the offset given on the host if.
   --  It also does alignment considerations to do the writes in most efficient
   --  way.  Also fills up the sum of the buffer in *buffer parameter.


   function e1000_mng_host_if_write
     (hw     : access E1000_Hw;
      buffer : access U8;
      length : in     U16;
      offset : in     U16;
      sum    : in     u8_Pointer) return S32
   is
      use C_u8_Pointers;

      len    :         u16 := length;
      data   : aliased U32 := 0;
      tmp    : u8_array (0 .. u32'Size / 8 - 1)
        with
          Address => data'Address;

      bufptr     : u8_Pointer := buffer.all'Access;
      remaining  : U16;
      i          : U16;
      j          : U16;
      prev_bytes : U16;
      the_Offset : u16;

   begin
      --  sum = only sum of the data and it is not checksum.
      --
      if        length = 0
        or else offset + length > E1000_HI_MAX_MNG_DATA_LENGTH
      then
         return -E1000_ERR_PARAM;
      end if;


      prev_bytes := offset and 3;
      the_Offset := offset / 4;

      if prev_bytes > 0
      then
         data := E1000_READ_REG_ARRAY (hw, E1000_HOST_IF, u32 (the_Offset));

         for j in C.size_t (prev_bytes) .. tmp'Last
         loop
            tmp (j) := u8_Pointer (bufptr + C.ptrdiff_t (j)).all;     -- TODO: Check precedence is correct for bufptr for line     *(tmp + j) = *bufptr++;
            sum.all := sum.all + tmp (j);
            bufptr  := bufptr + 1;
         end loop;

         E1000_WRITE_REG_ARRAY (hw, E1000_HOST_IF, u32 (the_Offset), data);

         len        := len - j - prev_bytes;
         the_Offset := the_Offset + 1;
      end if;

      remaining := len and 3;
      len       := len - remaining;

      --  Calculate length in DWORDs.
      --
      len := len / 4;

      --  The device driver writes the relevant command block into the ram area.
      --
      for i in 0 .. len - 1
      loop
         for j in 0 .. tmp'Last - 1
         loop
            tmp (j) := u8_Pointer (bufptr + C.ptrdiff_t (j)).all;    -- TODO: Check precedence is correct for bufptr for line     *(tmp + j) = *bufptr++;
            sum.all := sum.all + tmp (j);
            bufptr  := bufptr + 1;
         end loop;

         E1000_WRITE_REG_ARRAY (hw,
                                Devices.e1000e.Registers.E1000_HOST_IF,
                                u32 (the_Offset) + u32 (i),
                                data);
      end loop;

      if remaining > 0
      then
         for j in 0 .. tmp'Last - 1
         loop
            if u16 (j) < remaining
            then
               tmp (j) := u8_Pointer (bufptr + C.ptrdiff_t (j)).all;    -- TODO: Check precedence is correct for bufptr for line     *(tmp + j) = *bufptr++;
               bufptr  := bufptr + 1;
            else
               tmp (j) := 0;
            end if;

            sum.all := sum.all + tmp (j);
         end loop;

         E1000_WRITE_REG_ARRAY (hw,
                                Devices.e1000e.Registers.E1000_HOST_IF,
                                u32 (the_Offset) + u32 (i),
                                data);
      end if;

      return 0;
   end e1000_mng_host_if_write;





   --  Writes DHCP info to host interface.
   --
   --  @hw:     Pointer to the HW structure.
   --  @buffer: Pointer to the host interface.
   --  @length: Size of the buffer.
   --
   --  Writes the DHCP information to the host interface.


   function e1000e_mng_write_dhcp_info
     (hw     : access E1000_Hw;
      buffer : in     u8_Pointer;
      length : in     U16) return S32
   is
      hdr     : aliased E1000_Host_Mng_Command_Header.item;
      ret_val :         S32;
      hicr    :         U32;

   begin
      hdr.command_id     := E1000_MNG_DHCP_TX_PAYLOAD_CMD;
      hdr.command_length := length;
      hdr.reserved1      := 0;
      hdr.reserved2      := 0;
      hdr.checksum       := 0;

      --  Enable the host interface.
      --
      ret_val := e1000_mng_enable_host_if (hw);

      if ret_val /= 0
      then
         return ret_val;
      end if;


      --  Populate the host interface with the contents of "buffer."
      --
      ret_val := e1000_mng_host_if_write (hw,
                                          buffer,
                                          length,
                                          e1000_host_mng_command_header.item'Size / 8,
                                          hdr.checksum'unchecked_Access);
      if ret_val /= 0
      then
         return ret_val;
      end if;


      --   Write the manageability command header.
      --
      ret_val := e1000_mng_write_cmd_header (hw, hdr'Access);

      if ret_val /= 0
      then
         return ret_val;
      end if;


      --  Tell the ARC a new command is pending.
      --
      hicr := er32 (Hw.all, Devices.e1000e.Registers.E1000_HICR);

      ew32 (Hw.all, E1000_HICR, hicr or E1000_HICR_C);

      return 0;
   end e1000e_mng_write_dhcp_info;





   -- Check if management passthrough is needed.
   --
   --  @hw: Pointer to the HW structure.
   --
   --  Verifies the hardware needs to leave interface enabled so that frames can
   --  be directed to and from the management interface.


   function e1000e_enable_mng_pass_thru
     (hw : access E1000_Hw) return Boolean
   is
      manc   : U32;
      fwsm   : U32;
      factps : U32;

   begin
      manc := er32 (Hw.all, Devices.e1000e.Registers.E1000_MANC);

      if (manc and E1000_MANC_RCV_TCO_EN) = 0
      then
         return False;
      end if;


      if hw.mac.has_fwsm
      then
         fwsm   := er32 (Hw.all, Devices.e1000e.Registers.E1000_FWSM);
         factps := er32 (Hw.all, Devices.e1000e.Registers.E1000_FACTPS);

         if         (factps and E1000_FACTPS_MNGCG) = 0
           and then (fwsm   and E1000_FWSM_MODE_MASK) = shift_Left (u32 (e1000_mng_mode_pt'enum_Rep), E1000_FWSM_MODE_SHIFT)
         then
            return True;
         end if;

      elsif     (hw.mac.mac_type = e1000_82574)
        or else (hw.mac.mac_type = e1000_82583)
      then
         declare
            data    : aliased u16;
            ret_val :         S32;
         begin
            factps  := er32 (Hw.all, Devices.e1000e.Registers.E1000_FACTPS);
            ret_val := e1000_read_nvm (hw, Devices.e1000e.Defines.NVM_INIT_CONTROL2_REG, 1, data'unchecked_Access);

            if ret_val /= 0
            then
               return False;
            end if;

            if         (factps and E1000_FACTPS_MNGCG) = 0
              and then (data   and Devices.e1000e.an_82571.E1000_NVM_INIT_CTRL2_MNGM) = shift_Left (e1000_mng_mode_pt'enum_Rep, 13)
            then
               return True;
            end if;
         end;

      elsif      (manc and Devices.e1000e.Defines.E1000_MANC_SMBUS_EN) /= 0
        and then (manc and Devices.e1000e.Defines.E1000_MANC_ASF_EN)    = 0
      then
         return True;
      end if;


      return False;
   end e1000e_enable_mng_pass_thru;


end Devices.e1000e.Manage;

