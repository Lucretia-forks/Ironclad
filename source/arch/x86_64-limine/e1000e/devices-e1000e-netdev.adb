with
     Devices.e1000e.Core.Pointers,
     Devices.e1000e.Defines,
     Devices.e1000e.Registers,
     Devices.e1000e.Hardware.e1000_hw,
     Devices.e1000e.Hardware.e1000_tx_desc,
     Devices.e1000e.Hardware.e1000_rx_desc_extended,
     Devices.e1000e.Hardware.e1000_rx_desc_packet_split,
     Devices.e1000e.Hardware.proc_arg1_e1000_hw,
     Devices.e1000e.Hardware.e1000_mac_info,
     Devices.e1000e.Hardware.e1000_phy_info,
     Devices.e1000e.Hardware.e1000_fc_info,
     Devices.e1000e.Hardware.e1000_context_desc,
     Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32,
     Devices.e1000e.Base,
     Devices.e1000e.Base.e1000_Info,
     Devices.e1000e.Base.e1000_Adapter,
     Devices.e1000e.Base.e1000_Buffer,
     Devices.e1000e.Base.e1000_ps_Page,
     Devices.e1000e.Base.e1000_ring,
     Devices.e1000e.Base.e1000_phy_regs,
     Devices.e1000e.Base.alloc_rx_buf_proc,
     Devices.e1000e.Base.clean_rx_func,
     Devices.e1000e.Base.Port,
     Devices.e1000e.Base.Utility,
     Devices.e1000e.Media_Access_Control,
     Devices.e1000e.Physical_Layer,
     Devices.e1000e.Ich8Lan,
     Devices.e1000e.an_82571,
     Devices.e1000e.Precision_Time_Protocol,
     Devices.e1000e.Manage,
     Linux,

     ada.Strings.fixed,
     interfaces.C.Strings,

     system.Storage_Elements,
     system.Address_to_Access_Conversions,
     system.Memory_Copy,
     system.CRTL;



package body Devices.e1000e.NetDev
is

   use Devices.e1000e.Core,
       Devices.e1000e.Defines,
       Devices.e1000e.Registers,
       Devices.e1000e.Hardware,
       Devices.e1000e.Base,
       Devices.e1000e.Base.Port,
       Devices.e1000e.Base.e1000_buffer.C_Pointers,
       Linux,
       Interfaces;

   use type Devices.e1000e.Base.alloc_rx_buf_proc.item,
            linux.msix_entry_pointer,
            C.unsigned,
            C.unsigned_long,
            C.int,
            C.size_t,
            system.Crtl.size_t;



   procedure dummy is null;




   DEFAULT_MSG_ENABLE : constant u32 := NETIF_MSG_DRV or NETIF_MSG_PROBE or NETIF_MSG_LINK;
   debug : C.int := -1;





   subtype e1000_hw is Devices.e1000e.Hardware.e1000_hw.item;


   package E1000_Adapter_Conversions is new system.Address_to_Access_Conversions (E1000_Adapter.item);


   SPEED_MODE_BIT : constant Unsigned_32 := BIT (21);



   E1000_Info_Tbl : constant array (e1000_boards) of E1000_Info.view
     := [Board_82571       => E1000_82571_Info  'Access,
         Board_82572       => E1000_82572_Info  'Access,
         Board_82573       => E1000_82573_Info  'Access,
         Board_82574       => E1000_82574_Info  'Access,
         Board_82583       => E1000_82583_Info  'Access,
         Board_80003es2lan => E1000_Es2_Info    'Access,
         Board_Ich8lan     => E1000_Ich8_Info   'Access,
         Board_Ich9lan     => E1000_Ich9_Info   'Access,
         Board_Ich10lan    => E1000_Ich10_Info  'Access,
         Board_Pchlan      => E1000_Pch_Info    'Access,
         Board_Pch2lan     => E1000_Pch2_Info   'Access,
         Board_Pch_Lpt     => E1000_Pch_Lpt_Info'Access,
         Board_Pch_Spt     => E1000_Pch_Spt_Info'Access,
         Board_Pch_Cnp     => E1000_Pch_Cnp_Info'Access,
         Board_Pch_Tgp     => E1000_Pch_Tgp_Info'Access,
         Board_Pch_Adp     => E1000_Pch_Adp_Info'Access,
         Board_Pch_Mtp     => E1000_Pch_Mtp_Info'Access];



   type String_view is access String;

   type E1000_Reg_Info is
      record
         Ofs  : u32;
         Name : String_view;
      end record;



   type E1000_Reg_Info_Array is array (Natural range <>) of aliased E1000_Reg_Info;

   E1000_Reg_Info_Tbl : constant E1000_Reg_Info_Array
     := [-- General Registers.
         --
         (E1000_CTRL,     new String' ("CTRL")),
         (E1000_STATUS,   new String' ("STATUS")),
         (E1000_CTRL_EXT, new String' ("CTRL_EXT")),

         -- Interrupt Registers.
         --
         (E1000_ICR,      new String' ("ICR")),

         -- Rx Registers.
         --
         (E1000_RCTL,             new String' ("RCTL")),
         (E1000_RDLEN  (0),       new String' ("RDLEN")),
         (E1000_RDH    (0),       new String' ("RDH")),
         (E1000_RDT    (0),       new String' ("RDT")),
         (E1000_RDTR,             new String' ("RDTR")),
         (u32 (E1000_RXDCTL (0)), new String' ("RXDCTL")),
         (E1000_ERT,              new String' ("ERT")),
         (E1000_RDBAL  (0),       new String' ("RDBAL")),
         (E1000_RDBAH  (0),       new String' ("RDBAH")),
         (E1000_RDFH,             new String' ("RDFH")),
         (E1000_RDFT,             new String' ("RDFT")),
         (E1000_RDFHS,            new String' ("RDFHS")),
         (E1000_RDFTS,            new String' ("RDFTS")),
         (E1000_RDFPC,            new String' ("RDFPC")),

         -- Tx Registers.
         --
         (     E1000_TCTL,        new String' ("TCTL")),
         (     E1000_TDBAL  (0),  new String' ("TDBAL")),
         (     E1000_TDBAH  (0),  new String' ("TDBAH")),
         (u32 (E1000_TDLEN  (0)), new String' ("TDLEN")),
         (     E1000_TDH    (0),  new String' ("TDH")),
         (u32 (E1000_TDT    (0)), new String' ("TDT")),
         (     E1000_TIDV,        new String' ("TIDV")),
         (u32 (E1000_TXDCTL (0)), new String' ("TXDCTL")),
         (     E1000_TADV,        new String' ("TADV")),
         (u32 (E1000_TARC   (0)), new String' ("TARC")),
         (     E1000_TDFH,        new String' ("TDFH")),
         (     E1000_TDFT,        new String' ("TDFT")),
         (     E1000_TDFHS,       new String' ("TDFHS")),
         (     E1000_TDFTS,       new String' ("TDFTS")),
         (     E1000_TDFPC,       new String' ("TDFPC")),

         -- List Terminator.
         --
         (0, null)];





   -------------------
   -- E1000_Regdump --
   -------------------

   --  Register printout routine.
   --
   --  * @hw:      Pointer to the HW structure
   --  * @reginfo: Pointer to the register info table


   procedure E1000_Regdump
     (HW      : access          E1000_HW;
      Reginfo : access constant E1000_Reg_Info)
   is
      use ada.Strings.fixed;

      Rname : String    (1 .. 16) := (others => ' ');
      Regs  : u32_array (0 ..  7);

   begin
      if Reginfo.Ofs = u32 (E1000_RXDCTL (0))
      then
         for I in C.size_t (0) .. 1
         loop
            Regs (I) := er32 (HW.all, E1000_RXDCTL (I));
         end loop;

      elsif Reginfo.Ofs = u32 (E1000_TXDCTL (0))
      then
         for I in C.size_t (0) .. 1
         loop
            Regs (I) := er32 (HW.all, E1000_TXDCTL (I));
         end loop;

      elsif Reginfo.Ofs = u32 (E1000_TARC (0))
      then
         for I in C.size_t (0) .. 1
         loop
            Regs (I) := er32 (HW.all, E1000_TARC (I));
         end loop;

      else
         e_info (Reginfo.Name.all & " " & er32 (HW.all,
                                                C.unsigned_long (Reginfo.Ofs))'Image);
         return;
      end if;


      move (Source  => Reginfo.Name.all & "[0-1]",
            Target  => Rname,
            Justify => ada.Strings.Left);

      e_info (Rname & " " & Regs (0)'Image & " " & Regs (1)'Image);
   end E1000_Regdump;




   --------------------------
   -- E1000e_Dump_Ps_Pages --
   --------------------------

   procedure E1000e_Dump_Ps_Pages
     (Adapter : access E1000_Adapter.item;
      Bi      : access E1000_Buffer.item)
   is
      --  use type C.unsigned;

      the_Pages : e1000_ps_Page.item_array (0 .. C.size_t (Adapter.Rx_Ps_Pages - 1))
        with
          Address => Bi.Tx_Rx.Rx.Ps_Pages.all'Address,
          Import;

   begin
      for I in the_Pages'Range
      loop
         declare
            Ps_Page : E1000_Ps_Page.item renames the_Pages (I);
         begin
            if Ps_Page.Page /= null
            then
               e_info ("packet dump for ps_page" & I'Image & ":");

               print_hex_Dump (Level       => KERN_INFO,
                               Prefix_Str  => "",
                               Prefix_Type => DUMP_PREFIX_ADDRESS,
                               Rowsize     => 16,
                               Groupsize   => 1,
                               Buf         => page_address (Ps_Page.Page),
                               Len         => PAGE_SIZE,
                               Ascii       => True);
            end if;
         end;
      end loop;
   end E1000e_Dump_Ps_Pages;





   -----------------
   -- E1000E_Dump --
   -----------------

   --  Print registers, Tx-ring and Rx-ring.
   --
   --  * @adapter: Board private structure.

   procedure E1000E_Dump
     (Adapter : access E1000_Adapter.item) is null;     -- TODO

   --  procedure E1000E_Dump
   --    (Adapter : access E1000_Adapter.item)
   --  is
   --     Netdev  : access Net_Device        := Adapter.Netdev;
   --     HW      : access E1000_HW          := Adapter.HW'Access;
   --     Reginfo : access E1000_Reg_Info;
   --     Tx_Ring : access E1000_Ring.item   := Adapter.Tx_Ring;
   --     Tx_Desc : access E1000_Tx_Desc.item;
   --
   --     type My_U0 is
   --        record
   --           A : Integer_64;
   --           B : Integer_64;
   --        end record;
   --
   --     U0          : access My_U0;
   --     Buffer_Info : access E1000_Buffer.item;
   --     Rx_Ring     : access E1000_Ring.item                := Adapter.Rx_Ring;
   --     Rx_Desc_Ps  : access E1000_Rx_Desc_Packet_Split.item;
   --     Rx_Desc     : access E1000_Rx_Desc_Extended.item;
   --
   --     type My_U1 is
   --        record
   --           A : Integer_64;
   --           B : Integer_64;
   --           C : Integer_64;
   --           D : Integer_64;
   --        end record;
   --
   --     U1      : access My_U1;
   --     StatErr :        s32;
   --     I       :        Integer     := 0;
   --     Ret_Val :        Integer_32;
   --
   --  begin
   --     if not Netif_Msg_Hw (Adapter)
   --     then
   --        return;
   --     end if;
   --
   --     -- Print netdevice Info.
   --     --
   --     if Netdev /= null
   --     then
   --        Dev_Info (Adapter.Pdev.Device, "Net device Info");
   --        Pr_Info  ("Device Name     state            trans_start");
   --        Pr_Info  (Netdev.Name.all & "      " & Netdev.State'Image & "        "  & Dev_Trans_Start (Netdev)'Image);
   --     end if;
   --
   --     -- Print Registers.
   --     --
   --     Dev_Info (Adapter.Pdev.Device, "Register Dump");
   --     Pr_Info (" Register Name   Value");
   --     --  Reginfo := E1000_Reg_Info_Tbl'Access;
   --
   --     for Each of e1000_reg_info_tbl
   --     loop
   --        E1000_Regdump (HW, Each'Access);
   --     end loop;
   --
   --     -- Print Tx Ring Summary.
   --     --
   --     if            Netdev = null
   --       or else not Netif_Running (Netdev)
   --     then
   --        return;
   --     end if;
   --
   --
   --     Dev_Info (Adapter.Pdev.Device, "Tx Ring Summary");
   --     Pr_Info  ("Queue [NTU] [NTC] [bi(ntc)->dma  ] leng ntw timestamp");
   --
   --     Buffer_Info := Tx_Ring.Buffer_Info (Tx_Ring.Next_To_Clean);
   --
   --     Pr_Info(" %5d %5X %5X %016llX %04X %3X %016llX",
   --             0, Tx_Ring.Next_To_Use, Tx_Ring.Next_To_Clean,
   --             Buffer_Info.Dma, Buffer_Info.Length,
   --             Buffer_Info.Next_To_Watch, Buffer_Info.Time_Stamp);
   --
   --     -- Print Tx Ring.
   --     --
   --     if not Netif_Msg_Tx_Done (Adapter)
   --     then
   --        goto Rx_Ring_Summary;
   --     end if;
   --
   --
   --     Dev_Info (Adapter.Pdev.Dev, "Tx Ring Dump");
   --
   --     --  * Transmit Descriptor Formats - DEXT[29] is 0 (Legacy) or 1 (Extended)
   --     --  *
   --     --  * Legacy Transmit Descriptor
   --     --  *   +--------------------------------------------------------------+
   --     --  * 0 |         Buffer Address [63:0] (Reserved on Write Back)       |
   --     --  *   +--------------------------------------------------------------+
   --     --  * 8 | Special  |    CSS     | Status |  CMD    |  CSO   |  Length  |
   --     --  *   +--------------------------------------------------------------+
   --     --  *   63       48 47        36 35    32 31     24 23    16 15        0
   --     --  *
   --     --  * Extended Context Descriptor (DTYP=0x0) for TSO or checksum offload
   --     --  *   63      48 47    40 39       32 31             16 15    8 7      0
   --     --  *   +----------------------------------------------------------------+
   --     --  * 0 |  TUCSE  | TUCS0  |   TUCSS   |     IPCSE       | IPCS0 | IPCSS |
   --     --  *   +----------------------------------------------------------------+
   --     --  * 8 |   MSS   | HDRLEN | RSV | STA | TUCMD | DTYP |      PAYLEN      |
   --     --  *   +----------------------------------------------------------------+
   --     --  *   63      48 47    40 39 36 35 32 31   24 23  20 19                0
   --     --  *
   --     --  * Extended Data Descriptor (DTYP=0x1)
   --     --  *   +----------------------------------------------------------------+
   --     --  * 0 |                     Buffer Address [63:0]                      |
   --     --  *   +----------------------------------------------------------------+
   --     --  * 8 | VLAN tag |  POPTS  | Rsvd | Status | Command | DTYP |  DTALEN  |
   --     --  *   +----------------------------------------------------------------+
   --     --  *   63       48 47     40 39  36 35    32 31     24 23  20 19        0
   --
   --     Pr_Info("Tl[desc]     [address 63:0  ] [SpeCssSCmCsLen] [bi->dma       ] leng  ntw timestamp        bi->skb <-- Legacy format");
   --     Pr_Info("Tc[desc]     [Ce CoCsIpceCoS] [MssHlRSCm0Plen] [bi->dma       ] leng  ntw timestamp        bi->skb <-- Ext Context format");
   --     Pr_Info("Td[desc]     [address 63:0  ] [VlaPoRSCm1Dlen] [bi->dma       ] leng  ntw timestamp        bi->skb <-- Ext Data format");
   --
   --     for I in 0 .. Tx_Ring.Count - 1
   --     loop
   --        declare
   --           Next_Desc : String;
   --        begin
   --           Tx_Desc     := E1000_TX_DESC (Tx_Ring, I);
   --           Buffer_Info := Tx_Ring.Buffer_Info (I);
   --           U0          := My_U0 (Tx_Desc);
   --
   --           if         I = Tx_Ring.Next_To_Use
   --             and then I = Tx_Ring.Next_To_Clean
   --           then
   --              Next_Desc := " NTC/U";
   --           elsif I = Tx_Ring.Next_To_Use
   --           then
   --              Next_Desc := " NTU";
   --           elsif I = Tx_Ring.Next_To_Clean
   --           then
   --              Next_Desc := " NTC";
   --           else
   --              Next_Desc := "";
   --           end if;
   --
   --           Pr_Info ("T%c[0x%03X]    %016llX %016llX %016llX %04X  %3X %016llX %p%s",
   --                    (if (Le64_To_Cpu (U0.B) and Bit (29)) = 0 then 'l'
   --                                                              else (if (Le64_To_Cpu (U0.B) and Bit (20)) /= 0 then 'd'
   --                                                                                                              else 'c')),
   --                    I,
   --                    Le64_To_Cpu (U0.A),
   --                    Le64_To_Cpu (U0.B),
   --                    Buffer_Info.Dma,
   --                    Buffer_Info.Length,
   --                    Buffer_Info.Next_To_Watch,
   --                    Buffer_Info.Time_Stamp,
   --                    Buffer_Info.Skb,
   --                    Next_Desc);
   --
   --           if         Netif_Msg_Pktdata (Adapter)
   --             and then Buffer_Info.Skb /= null
   --           then
   --              Print_Hex_Dump (KERN_INFO, "",
   --                              DUMP_PREFIX_ADDRESS,
   --                              16,
   --                              1,
   --                              Buffer_Info.Skb.Data,
   --                              Buffer_Info.Skb.Len,
   --                              True);
   --           end if;
   --        end;
   --     end loop;
   --
   --
   --     -- Print Rx Ring Summary.
   --     --
   --     <<Rx_Ring_Summary>>
   --
   --     Dev_Info (Adapter.Pdev.Dev, "Rx Ring Summary");
   --     Pr_Info ("Queue [NTU] [NTC]");
   --     Pr_Info (" %5d %5X %5X",
   --              0,
   --              Rx_Ring.Next_To_Use,
   --              Rx_Ring.Next_To_Clean);
   --
   --     -- Print Rx Ring.
   --     --
   --     if not Netif_Msg_Rx_Status(Adapter)
   --     then
   --        return;
   --     end if;
   --
   --
   --     Dev_Info(Adapter.Pdev.Dev, "Rx Ring Dump");
   --
   --     case Adapter.Rx_Ps_Pages
   --     is
   --        when 1 | 2 | 3 =>
   --
   --           --  [Extended] Packet Split Receive Descriptor Format
   --           --  *
   --           --  *    +-----------------------------------------------------+
   --           --  *  0 |                Buffer Address 0 [63:0]              |
   --           --  *    +-----------------------------------------------------+
   --           --  *  8 |                Buffer Address 1 [63:0]              |
   --           --  *    +-----------------------------------------------------+
   --           --  * 16 |                Buffer Address 2 [63:0]              |
   --           --  *    +-----------------------------------------------------+
   --           --  * 24 |                Buffer Address 3 [63:0]              |
   --           --  *    +-----------------------------------------------------+
   --
   --           Pr_Info("R  [desc]      [buffer 0 63:0 ] [buffer 1 63:0 ] [buffer 2 63:0 ] [buffer 3 63:0 ] [bi->dma       ] [bi->skb] <-- Ext Pkt Split format");
   --
   --           --  [Extended] Receive Descriptor (Write-Back) Format
   --           --  *
   --           --  *   63       48 47    32 31     13 12    8 7    4 3        0
   --           --  *   +------------------------------------------------------+
   --           --  * 0 | Packet   | IP     |  Rsvd   | MRQ   | Rsvd | MRQ RSS |
   --           --  *   | Checksum | Ident  |         | Queue |      |  Type   |
   --           --  *   +------------------------------------------------------+
   --           --  * 8 | VLAN Tag | Length | Extended Error | Extended Status |
   --           --  *   +------------------------------------------------------+
   --           --  *   63       48 47    32 31            20 19               0
   --
   --           Pr_Info("RWB[desc]      [ck ipid mrqhsh] [vl   l0 ee  es] [ l3  l2  l1 hs] [reserved      ] ---------------- [bi->skb] <-- Ext Rx Write-Back format");
   --
   --           for I in 0 .. Rx_Ring.Count - 1
   --           loop
   --              declare
   --                 Next_Desc : String;
   --              begin
   --                 Buffer_Info := Rx_Ring.Buffer_Info (I);
   --                 Rx_Desc_Ps  := E1000_RX_DESC_PS (Rx_Ring, I);
   --                 U1          := My_U1 (Rx_Desc_Ps);
   --                 StatErr     := Le32_To_Cpu (Rx_Desc_Ps.Wb.Middle.Status_Error);
   --
   --                 if I = Rx_Ring.Next_To_Use
   --                 then
   --                    Next_Desc := " NTU";
   --                 elsif I = Rx_Ring.Next_To_Clean
   --                 then
   --                    Next_Desc := " NTC";
   --                 else
   --                    Next_Desc := "";
   --                 end if;
   --
   --                 if StatErr and E1000_RXD_STAT_DD /= 0
   --                 then
   --                    -- Descriptor Done.
   --                    --
   --                    Pr_Info("%s[0x%03X]     %016llX %016llX %016llX %016llX ---------------- %p%s",
   --                            "RWB",
   --                            I,
   --                            Le64_To_Cpu (U1.A),
   --                            Le64_To_Cpu (U1.B),
   --                            Le64_To_Cpu (U1.C),
   --                            Le64_To_Cpu (U1.D),
   --                            Buffer_Info.Skb,
   --                            Next_Desc);
   --                 else
   --                    Pr_Info("%s[0x%03X]     %016llX %016llX %016llX %016llX %016llX %p%s",
   --                            "R  ",
   --                            I,
   --                            Le64_To_Cpu (U1.A),
   --                            Le64_To_Cpu (U1.B),
   --                            Le64_To_Cpu (U1.C),
   --                            Le64_To_Cpu (U1.D),
   --                            Buffer_Info.Dma,
   --                            Buffer_Info.Skb,
   --                            Next_Desc);
   --
   --                    if Netif_Msg_Pktdata (Adapter)
   --                    then
   --                       E1000E_Dump_Ps_Pages (Adapter, Buffer_Info);
   --                    end if;
   --                 end if;
   --              end;
   --           end loop;
   --
   --        when others =>
   --
   --           --  /* Extended Receive Descriptor (Read) Format
   --           --  *
   --           --  *   +-----------------------------------------------------+
   --           --  * 0 |                Buffer Address [63:0]                |
   --           --  *   +-----------------------------------------------------+
   --           --  * 8 |                      Reserved                       |
   --           --  *   +-----------------------------------------------------+
   --
   --           Pr_Info("R  [desc]      [buf addr 63:0 ] [reserved 63:0 ] [bi->dma       ] [bi->skb] <-- Ext (Read) format");
   --
   --           --  /* Extended Receive Descriptor (Write-Back) Format
   --           --  *
   --           --  *   63       48 47    32 31    24 23            4 3        0
   --           --  *   +------------------------------------------------------+
   --           --  *   |     RSS Hash      |        |               |         |
   --           --  * 0 +-------------------+  Rsvd  |   Reserved    | MRQ RSS |
   --           --  *   | Packet   | IP     |        |               |  Type   |
   --           --  *   | Checksum | Ident  |        |               |         |
   --           --  *   +------------------------------------------------------+
   --           --  * 8 | VLAN Tag | Length | Extended Error | Extended Status |
   --           --  *   +------------------------------------------------------+
   --           --  *   63       48 47    32 31            20 19               0
   --
   --           Pr_Info("RWB[desc]      [cs ipid    mrq] [vt   ln xe  xs] [bi->skb] <-- Ext (Write-Back) format");
   --
   --           for I in 0 .. Rx_Ring.Count - 1
   --           loop
   --              declare
   --                 Next_Desc : String;
   --              begin
   --                 Buffer_Info := Rx_Ring.Buffer_Info (I);
   --                 Rx_Desc     := E1000_RX_DESC_EXT (Rx_Ring, I);
   --                 U1          := My_U1 (Rx_Desc);
   --                 StatErr     := Le32_To_Cpu (Rx_Desc.Wb.Upper.Status_Error);
   --
   --                 if I = Rx_Ring.Next_To_Use
   --                 then
   --                    Next_Desc := " NTU";
   --                 elsif I = Rx_Ring.Next_To_Clean
   --                 then
   --                    Next_Desc := " NTC";
   --                 else
   --                    Next_Desc := "";
   --                 end if;
   --
   --                 if StatErr and E1000_RXD_STAT_DD /= 0
   --                 then
   --                    --  Descriptor Done.
   --                    --
   --                    Pr_Info ("%s[0x%03X]     %016llX %016llX ---------------- %p%s",
   --                             "RWB",
   --                             I,
   --                             Le64_To_Cpu (U1.A),
   --                             Le64_To_Cpu (U1.B),
   --                             Buffer_Info.Skb,
   --                             Next_Desc);
   --                 else
   --                    Pr_Info ("%s[0x%03X]     %016llX %016llX %016llX %p%s",
   --                             "R  ",
   --                             I,
   --                             Le64_To_Cpu (U1.A),
   --                             Le64_To_Cpu (U1.B),
   --                             Buffer_Info.Dma,
   --                             Buffer_Info.Skb,
   --                             Next_Desc);
   --
   --                    if         Netif_Msg_Pktdata (Adapter)
   --                      and then Buffer_Info.Skb /= null
   --                    then
   --                       Print_Hex_Dump (KERN_INFO,
   --                                       "",
   --                                       DUMP_PREFIX_ADDRESS,
   --                                       16,
   --                                       1,
   --                                       Buffer_Info.Skb.Data,
   --                                       Adapter.Rx_Buffer_Len,
   --                                       True);
   --                    end if;
   --                 end if;
   --              end;
   --           end loop;
   --     end case;
   --
   --  end E1000E_Dump;





   -----------------------
   -- E1000_Desc_Unused --
   -----------------------

   --  Calculate if we have unused descriptors.
   --
   --   * @ring: Pointer to ring struct to perform calculation on.


   function E1000_Desc_Unused
     (Ring : access e1000_ring.item) return u16
   is
   begin
      if Ring.Next_To_Clean > Ring.Next_To_Use
      then
         return Ring.Next_To_Clean - Ring.Next_To_Use - 1;
      else
         return u16 (Ring.Count) + Ring.Next_To_Clean - Ring.Next_To_Use - 1;
      end if;
   end E1000_Desc_Unused;





   -------------------------------
   -- E1000e_Systim_To_Hwtstamp --
   -------------------------------

   --  Convert system time value to hw time stamp.
   --
   --  * @adapter:   Board private structure.
   --  * @hwtstamps: Time stamp structure to update.
   --  * @systim:    Unsigned 64bit system time value.
   --  *
   --  * Convert the system time value stored in the RX/TXSTMP registers into a
   --  * hwtstamp which can be used by the upper level time stamping functions.
   --  *
   --  * The 'systim_lock' spinlock is used to protect the consistency of the
   --  * system time value. This is needed because reading the 64 bit time
   --  * value involves reading two 32 bit registers. The first read latches the
   --  * value.


   procedure E1000e_Systim_To_Hwtstamp
     (Adapter    : access E1000_Adapter.item;
      Hwtstamps  : access Skb_Shared_Hwtstamps;
      Systim     : in     Unsigned_64)
   is
      Ns    : Unsigned_64;
      Flags : C.unsigned_long;
   begin
      spin_lock_irqsave          (Adapter.systim_lock'Access, flags);
      Ns := Timecounter_Cyc2time (Adapter.Tc         'Access, Systim);
      spin_unlock_irqrestore     (Adapter.systim_lock'Access, flags);

      Hwtstamps.Hwtstamp := 0;                      -- TODO: Why is this needed ?
      Hwtstamps.Hwtstamp := Ns_To_Ktime (Ns);
   end E1000e_Systim_To_Hwtstamp;



   ------------------------
   -- E1000e_Rx_Hwtstamp --
   ------------------------

   --    Utility function which checks for Rx time stamp.
   --
   --  * @adapter: Board private structure.
   --  * @status:  Descriptor extended error and status field.
   --  * @skb:     Particular skb to include time stamp.
   --  *
   --  * If the time stamp is valid, convert it into the timecounter ns value
   --  * and store that result into the shhwtstamps structure which is passed
   --  * up the network stack.


   procedure E1000e_Rx_Hwtstamp (Adapter : access E1000_Adapter.item;
                                 Status  : in     u32;
                                 SKB     : access SK_Buff)
   is
      --  use type C.unsigned;

      HW     : E1000_HW renames Adapter.HW;
      Rxstmp : Interfaces.Unsigned_64;

   begin
      if        (Adapter.Flags                    and C.unsigned (FLAG_HAS_HW_TIMESTAMP))   = 0
        or else (Status                           and             E1000_RXDEXT_STATERR_TST) = 0
        or else (Er32 (HW, Devices.e1000e.Registers.E1000_TSYNCRXCTL) and             E1000_TSYNCRXCTL_VALID)   = 0
      then
         return;
      end if;


      -- The Rx time stamp registers contain the time stamp. No other
      -- received packet will be time stamped until the Rx time stamp
      -- registers are read. Because only one packet can be time stamped
      -- at a time, the register values must belong to this packet and
      -- therefore none of the other additional attributes need to be
      -- compared.

      Rxstmp := u64 (Er32 (HW, Devices.e1000e.Registers.E1000_RXSTMPL));
      Rxstmp := Rxstmp or shift_Left (u64 (Er32 (HW, Devices.e1000e.Registers.E1000_RXSTMPH)),
                                      32);

      E1000e_Systim_To_Hwtstamp (Adapter,
                                 SKB_Hwtstamps (SKB),
                                 Rxstmp);

      Adapter.Flags2 := Adapter.Flags2 and (not C.unsigned (FLAG2_CHECK_RX_HWTSTAMP));
   end E1000e_Rx_Hwtstamp;




   -----------------------
   -- E1000_Receive_SKB --
   -----------------------

   --    Helper function to handle Rx indications.
   --
   --  * @adapter: Board private structure.
   --  * @netdev:  Pointer to netdev struct.
   --  * @staterr: Descriptor extended error and status field as written by hardware.
   --  * @vlan:    Descriptor vlan field as written by hardware (no le/be conversion).
   --  * @skb:     Pointer to sk_buff to be indicated to stack.


   procedure E1000_Receive_SKB
     (Adapter  : access E1000_Adapter.item;
      Netdev   : access Net_Device;
      SKB      : access sk_buff;
      Staterr  : in     Unsigned_32;
      VLAN     : in     Unsigned_16)
   is
      Tag    : Unsigned_16;
      Unused : Gro_Result_t;

   begin
      e1000e_rx_hwtstamp (Adapter, Staterr, SKB);

      SKB.Protocol := Eth_Type_Trans (SKB, Netdev);

      if (Staterr and E1000_RXD_STAT_VP) /= 0
      then
         Tag := CPU_To_Le16 (VLAN).Value;
         vlan_hwaccel_put_tag (SKB,
                               HtoNS (ETH_P_8021Q),
                               Tag);
      end if;

      Unused := NAPI_GRO_Receive (Adapter.NAPI'Access, SKB);
   end E1000_Receive_SKB;





   -----------------------
   -- E1000_Rx_Checksum --
   -----------------------

   --    Receive Checksum Offload.
   --
   --  * @adapter:    Board private structure.
   --  * @status_err: Receive descriptor status and error fields.
   --  * @skb:        Socket buffer with received data.


   procedure E1000_Rx_Checksum
     (Adapter    : access E1000_Adapter.item;
      Status_Err : in     u32;
      Skb        : access Sk_Buff)
   is
      Status : constant Unsigned_16 := Unsigned_16 (Status_Err);
      Errors : constant Unsigned_8  := Unsigned_8  (shift_Right (Status_Err, 24));

      Netdev : access Net_Device renames Adapter.Netdev;

   begin
      Skb_Checksum_None_Assert (Skb);

      -- Rx checksum disabled.
      --
      if (Netdev.Features and NETIF_F_RXCSUM) = 0
      then
         return;
      end if;


      -- Ignore Checksum bit is set.
      --
      if (Status and E1000_RXD_STAT_IXSM) /= 0
      then
         return;
      end if;


      -- TCP/UDP checksum error bit or IP checksum error bit is set.
      --
      if (     Errors
          and (E1000_RXD_ERR_TCPE or E1000_RXD_ERR_IPE)) /= 0
      then
         -- Let the stack verify checksum errors.
         --
         Adapter.Hw_Csum_Err := Adapter.Hw_Csum_Err + 1;
         return;
      end if;


      -- TCP/UDP Checksum has not been calculated.
      --
      if (     Status
          and (E1000_RXD_STAT_TCPCS or E1000_RXD_STAT_UDPCS)) = 0
      then
         return;
      end if;


      -- It must be a TCP or UDP packet with a valid checksum.
      --
      Skb.Ip_Summed        := CHECKSUM_UNNECESSARY;
      Adapter.Hw_Csum_Good := Adapter.Hw_Csum_Good + 1;
   end E1000_Rx_Checksum;




   --------------------------
   -- E1000e_Update_Rdt_Wa --
   --------------------------

   procedure E1000e_Update_Rdt_Wa
     (Rx_Ring : access E1000_Ring.item;
      I       : in     Unsigned_32)
   is
      Adapter : access E1000_Adapter.item renames Rx_Ring.Adapter;
      Hw      :        E1000_Hw           renames Adapter.Hw;

   begin
      ew32_prepare (Hw);
      writel (I, Rx_Ring.Tail);

      if unlikely (i /= readl (rx_ring.tail))
      then
         declare
            Rctl : constant Unsigned_32 := Er32 (HW, Devices.e1000e.Registers.E1000_RCTL);
         begin
            Ew32 (HW,
                  Devices.e1000e.Registers.E1000_RCTL,
                  Rctl and (not E1000_RCTL_EN));

            e_err ("ME firmware caused invalid RDT - resetting");
            Schedule_Work (Adapter.Reset_Task'Access);
         end;
      end if;
   end E1000e_Update_Rdt_Wa;




   --------------------------
   -- E1000e_Update_Tdt_Wa --
   --------------------------

   procedure E1000e_Update_Tdt_Wa
     (Tx_Ring : access E1000_Ring.item;
      I       : in     Unsigned_32)
   is
      Adapter : access E1000_Adapter.item renames Tx_Ring.Adapter;
      Hw      :        E1000_Hw           renames Adapter.Hw;

   begin
      Ew32_Prepare (Hw);
      Writel (I, Tx_Ring.Tail);

      if I /= Readl (Tx_Ring.Tail)
      then
         declare
            Tctl : constant Unsigned_32 := Er32 (Hw, E1000_TCTL);
         begin
            Ew32 (Hw,
                  E1000_TCTL,
                  Tctl and (not E1000_TCTL_EN));

            e_err ("ME firmware caused invalid TDT - resetting");
            schedule_work (Adapter.reset_task'Access);
         end;
      end if;
   end E1000e_Update_Tdt_Wa;



   ----------------------------
   -- E1000_Alloc_Rx_Buffers --
   ----------------------------

   --  Replace used receive buffers.
   --
   --  * @rx_ring:       Rx descriptor ring.
   --  * @cleaned_count: Number to reallocate.
   --  * @gfp:           Flags for allocation.


   procedure E1000_Alloc_Rx_Buffers
     (Rx_Ring       : access E1000_Ring.item;
      Cleaned_Count : in     C.int;
      Gfp           : in     gfp_t)
   is
      use -- e1000_buffer.C_Pointers,
          Devices.e1000e.Base.Utility;

      use type -- C.int,
               --  C.unsigned,
               C.ptrdiff_t;

      Adapter     : access   E1000_Adapter.item renames Rx_Ring.Adapter;
      Netdev      : access   Net_Device         renames Adapter.Netdev;
      Pdev        : access   PCI_Dev            renames Adapter.Pdev;

      Rx_Desc     : access   E1000_Rx_Desc_Extended.item;
      Buffer_Info :          E1000_Buffer.Pointer;
      Skb         : access   SK_Buff;
      I           :          C.ptrdiff_t;
      Bufsz       : constant C.unsigned := C.unsigned (Adapter.Rx_Buffer_Len);
      Clean_Count :          C.int      := Cleaned_Count;

   begin
      I           := C.ptrdiff_t (Rx_Ring.Next_To_Use);
      Buffer_Info := Rx_Ring.Buffer_Info + I;

      while Clean_Count > 0
      loop
         Skb := Buffer_Info.Skb;

         if Skb /= null
         then
            skb_trim (Skb, 0);
            goto Map_Skb;
         end if;


         Skb := Netdev_Alloc_Skb_Ip_Align (Netdev, Bufsz, Gfp);

         if Skb = null
         then
            -- Better luck next round.
            --
            Adapter.Alloc_Rx_Buff_Failed := Adapter.Alloc_Rx_Buff_Failed + 1;
            exit;
         end if;

         Buffer_Info.Skb := Skb.all'unchecked_Access;

         <<Map_Skb>>

         Buffer_Info.Dma := DMA_Map_Single (Dev  => Pdev.Dev'Access,
                                            Data => Skb.Data,
                                            Size => C.size_t (Adapter.Rx_Buffer_Len),
                                            Dir  => DMA_FROM_DEVICE);

         if DMA_Mapping_Error (Pdev.Dev'Access, Buffer_Info.Dma) /= 0
         then
            Dev_Err (Pdev.Dev'Access, "Rx DMA map failed");
            Adapter.Rx_Dma_Failed := Adapter.Rx_Dma_Failed + 1;
            exit;
         end if;

         Rx_Desc                  := E1000_RX_DESC_EXT (Rx_Ring.all,
                                                        Integer (I));
         Rx_Desc.Read.Buffer_Addr := CPU_To_Le64 (Buffer_Info.Dma);

         if I mod E1000_RX_BUFFER_WRITE = E1000_RX_BUFFER_WRITE - 1
         then
            -- Force memory writes to complete before letting h/w
            -- know there are new descriptors to fetch. (Only
            -- applicable for weak-ordered memory model archs,
            -- such as IA-64).
            --
            wmb;

            if (Adapter.Flags2 and C.unsigned (FLAG2_PCIM2PCI_ARBITER_WA)) /= 0
            then
               E1000e_Update_Rdt_Wa (Rx_Ring, u32 (I));
            else
               writel (u32 (I),
                       Rx_Ring.Tail);
            end if;
         end if;

         I := I + 1;

         if C.unsigned (I) = Rx_Ring.Count
         then
            I := 0;
         end if;

         Buffer_Info   := Rx_Ring.Buffer_Info + I;
         Clean_Count := Clean_Count - 1;
      end loop;

      Rx_Ring.Next_To_Use := u16 (I);
   end E1000_Alloc_Rx_Buffers;



   -------------------------------
   -- E1000_Alloc_Rx_Buffers_Ps --
   -------------------------------

   --    Replace used receive buffers; packet split.
   --
   --  * @rx_ring:       Rx descriptor ring.
   --  * @cleaned_count: Number to reallocate.
   --  * @gfp:           Flags for allocation.


   procedure E1000_Alloc_Rx_Buffers_Ps
     (Rx_Ring      : access E1000_Ring.item;
      Cleaned_Count: in     C.int;
      Gfp          : in     Gfp_T)
   is
      use -- e1000_buffer .C_Pointers,
          e1000_ps_page.C_Pointers,
          Devices.e1000e.Base.Utility,
          Devices.e1000e.Hardware.e1000_rx_desc_packet_split;

      use type C.ptrdiff_t;

      Adapter     : access E1000_Adapter.item renames Rx_Ring.Adapter;
      Netdev      : access Net_Device         renames Adapter.Netdev;
      Pdev        : access pci_dev            renames Adapter.Pdev;

      Rx_Desc     : access E1000_Rx_Desc_Packet_Split.item;
      Buffer_Info :        E1000_Buffer.pointer;
      Ps_Page     : access E1000_Ps_Page.item;
      Skb         : access sk_buff;
      I           :        C.ptrdiff_t;
      Clean_Count :        C.int      := Cleaned_Count;

   begin
      I           := C.ptrdiff_t (Rx_Ring.Next_To_Use);
      Buffer_Info := Rx_Ring.Buffer_Info + I;

      while Clean_Count > 0
      loop
         Rx_Desc := E1000_Rx_Desc_Ps (Rx_Ring.all,
                                      Integer (I));

         for J in 0 .. C.ptrdiff_t (PS_PAGE_BUFFERS) - 1
         loop
            Ps_Page := Buffer_Info.Tx_Rx.Rx.Ps_Pages + J;

            if C.unsigned (J) >= Adapter.Rx_Ps_Pages
            then
               -- All unused desc entries get hw null ptr.
               --
               Rx_Desc.read.Buffer_Addr (C.size_t (J) + 1) := (Value => not cpu_to_le64 (0).Value);
               goto Continue;
            end if;


            if Ps_Page.Page = null
            then
               Ps_Page.Page := Alloc_Page (Gfp);

               if Ps_Page.Page = null
               then
                  Adapter.Alloc_Rx_Buff_Failed := Adapter.Alloc_Rx_Buff_Failed + 1;
                  goto No_Buffers;
               end if;


               Ps_Page.Dma := Dma_Map_Page (Pdev.Dev'Access,
                                            Ps_Page.Page,
                                            0,
                                            PAGE_SIZE,
                                            DMA_FROM_DEVICE);

               if Dma_Mapping_Error (Pdev.Dev'Access, Ps_Page.Dma) /= 0
               then
                  dev_err (Adapter.pdev.dev'Access,
                           "Rx DMA page map failed");
                  Adapter.Rx_Dma_Failed := Adapter.Rx_Dma_Failed + 1;

                  goto No_Buffers;
               end if;

            end if;

            --  Refresh the desc even if buffer_addrs didn't change because each write-back
            --  erases this info.
            --
            Rx_Desc.read.Buffer_Addr (C.size_t (J) + 1) := (Value => Ps_Page.Dma);

            <<Continue>>
         end loop;


         Skb := Netdev_Alloc_Skb_Ip_Align (Netdev,
                                           C.unsigned (Adapter.Rx_Ps_Bsize0),
                                           Gfp);
         if Skb = null
         then
            Adapter.Alloc_Rx_Buff_Failed := Adapter.Alloc_Rx_Buff_Failed + 1;
            exit;
         end if;

         Buffer_Info.Skb := Skb.all'unchecked_Access;
         Buffer_Info.Dma := Dma_Map_Single (Pdev.Dev'Access,
                                            Skb.Data,
                                            C.size_t (Adapter.Rx_Ps_Bsize0),
                                            DMA_FROM_DEVICE);

         if Dma_Mapping_Error (Pdev.Dev'Access, Buffer_Info.Dma) /= 0
         then
            dev_err (Adapter.pdev.dev'Access,
                     "Rx DMA map failed");
            Adapter.Rx_Dma_Failed := Adapter.Rx_Dma_Failed + 1;

            -- Cleanup skb.
            --
            Dev_Kfree_Skb_Any (Skb);
            Buffer_Info.Skb := null;
            exit;
         end if;

         Rx_Desc.read.Buffer_Addr (0) := (Value => Buffer_Info.Dma);

         if unlikely ((u16 (I) and (E1000_RX_BUFFER_WRITE - 1)) = 0)
         then
            -- Force memory writes to complete before letting h/w
            -- know there are new descriptors to fetch.  (Only
            -- applicable for weak-ordered memory model archs,
            -- such as IA-64).
            --
            Wmb;

            if (Adapter.Flags2 and C.unsigned (FLAG2_PCIM2PCI_ARBITER_WA)) /= 0
            then
               E1000e_Update_Rdt_Wa (Rx_Ring, u32 (I) * 2);
            else
               Writel (u32 (I) * 2, Rx_Ring.Tail);
            end if;
         end if;

         I := I + 1;

         if C.unsigned (I) = Rx_Ring.Count
         then
            I := 0;
         end if;

         Buffer_Info := Rx_Ring.Buffer_Info + I;
         Clean_Count := Clean_Count - 1;
      end loop;


      <<No_Buffers>>

      Rx_Ring.Next_To_Use := u16 (I);
   end E1000_Alloc_Rx_Buffers_Ps;




   ----------------------------------
   -- E1000_Alloc_Jumbo_Rx_Buffers --
   ----------------------------------

   --    Replace used jumbo receive buffers.
   --
   --  * @rx_ring:       Rx descriptor ring.
   --  * @cleaned_count: Number of buffers to allocate this pass.
   --  * @gfp:           Flags for allocation.


   procedure E1000_Alloc_Jumbo_Rx_Buffers
     (Rx_Ring       : access E1000_Ring.item;
      Cleaned_Count : in     C.int;
      Gfp           : in     Gfp_T)
   is
      use -- e1000.e1000_buffer.C_Pointers,
          Devices.e1000e.Base.Utility;

      use type -- C.int,
               --  C.unsigned,
               C.ptrdiff_t;

      Adapter     : access   E1000_Adapter.item renames Rx_Ring.Adapter;
      Netdev      : access   Net_Device         renames Adapter.Netdev;
      Pdev        : access   pci_dev            renames Adapter.Pdev;

      Rx_Desc     : access   E1000_Rx_Desc_Extended.item;
      Buffer_Info : access   E1000_Buffer.item;
      Skb         : access   sk_buff;
      I           :          C.ptrdiff_t;
      Bufsz       : constant            := 256 - 16;     -- For skb_reserve.
      Clean_Count :          C.int      := Cleaned_Count;

   begin
      I           := C.ptrdiff_t (Rx_Ring.Next_To_Use);
      Buffer_Info := Rx_Ring.Buffer_Info + I;

      while Clean_Count > 0
      loop
         Skb := Buffer_Info.Skb;

         if Skb /= null
         then
            skb_trim (Skb, 0);
            goto Check_Page;
         end if;


         Skb := netdev_alloc_skb_ip_align (Netdev, Bufsz, Gfp);

         if unlikely (Skb = null)
         then
            -- Better luck next round.
            --
            Adapter.Alloc_Rx_Buff_Failed := Adapter.Alloc_Rx_Buff_Failed + 1;
            exit;
         end if;

         Buffer_Info.Skb := Skb.all'unchecked_Access;


         <<Check_Page>>

         --  Allocate a new page if necessary.
         --
         if Buffer_Info.Tx_Rx.Rx.Page = null
         then
            Buffer_Info.Tx_Rx.Rx.Page := alloc_page (gfp);

            if unlikely (Buffer_Info.Tx_Rx.Rx.Page = null)
            then
               Adapter.Alloc_Rx_Buff_Failed := Adapter.Alloc_Rx_Buff_Failed + 1;
               exit;
            end if;
         end if;


         if Buffer_Info.Dma = 0
         then
            Buffer_Info.Dma := dma_map_page (Pdev.Dev'Access,
                                             Buffer_Info.Tx_Rx.Rx.Page,
                                             0,
                                             Page_Size,
                                             DMA_FROM_DEVICE);

            if dma_mapping_error (Pdev.Dev'Access, Buffer_Info.Dma) /= 0
            then
               Adapter.Alloc_Rx_Buff_Failed := Adapter.Alloc_Rx_Buff_Failed + 1;
               exit;
            end if;
         end if;

         Rx_Desc                  := E1000_Rx_Desc_Ext (Rx_Ring.all, Integer (I));
         Rx_Desc.Read.Buffer_Addr := cpu_to_le64 (Buffer_Info.Dma);

         I := I + 1;

         if I = C.ptrdiff_t (Rx_Ring.Count)
         then
            I := 0;
         end if;

         Buffer_Info := Rx_Ring.Buffer_Info + I;
         Clean_Count := Clean_Count - 1;
      end loop;


      if Rx_Ring.Next_To_Use /= u16 (I)
      then
         Rx_Ring.Next_To_Use := u16 (I);

         if unlikely (I = 0)
         then
            I := C.ptrdiff_t (Rx_Ring.Count - 1);
         else
            I := I - 1;
         end if;

         -- Force memory writes to complete before letting h/w
         -- know there are new descriptors to fetch.  (Only
         -- applicable for weak-ordered memory model archs,
         -- such as IA-64).
         --
         wmb;

         if (Adapter.Flags2 and C.unsigned (FLAG2_PCIM2PCI_ARBITER_WA)) /= 0
         then
            E1000E_Update_Rdt_Wa (Rx_Ring, u32 (I));
         else
            writel (u32 (I),
                    Rx_Ring.Tail);
         end if;
      end if;

   end E1000_Alloc_Jumbo_Rx_Buffers;




   -------------------
   -- E1000_Rx_Hash --
   -------------------

   procedure E1000_Rx_Hash
     (Netdev : access Net_Device;
      RSS    : in     le32;
      SKB    : access SK_Buff)
   is
   begin
      if (Netdev.Features and NETIF_F_RXHASH) /= 0
      then
         skb_set_hash (SKB,
                       le32_to_cpu (RSS),
                       PKT_HASH_TYPE_L3);
      end if;
   end E1000_Rx_Hash;




   ------------------------
   -- E1000_Clean_Rx_Irq --
   ------------------------

   --    Send received data up the network stack.
   --
   --  * @rx_ring:    Rx descriptor ring.
   --  * @work_done:  Output parameter for indicating completed work.
   --  * @work_to_do: How many packets we can clean.
   --  *
   --  * The return value indicates whether actual cleaning was done, there
   --  * is no guarantee that everything was cleaned.

   function E1000_Clean_Rx_Irq
     (Rx_Ring    : access E1000_Ring.item;
      Work_Done  : access Integer;
      Work_To_Do : in     C.int) return Boolean;

   pragma Convention (C, E1000_Clean_Rx_Irq);




   function E1000_Clean_Rx_Irq
     (Rx_Ring    : access E1000_Ring.item;
      Work_Done  : access Integer;
      Work_To_Do : in     C.int) return Boolean
   is
      use -- E1000_Buffer.C_Pointers,
          Devices.e1000e.Base.Utility;

      Adapter : access E1000_Adapter.item renames Rx_Ring.Adapter;
      Netdev  : access Net_Device         renames Adapter.Netdev;
      Pdev    : access PCI_Dev            renames Adapter.Pdev;
      --  Hw      :        E1000_Hw           renames Adapter.Hw;

      Rx_Desc,
      Next_Rxd         : access E1000_Rx_Desc_Extended.item;

      Buffer_Info,
      Next_Buffer      : E1000_Buffer.pointer;

      Length,
      Staterr          : Interfaces.Unsigned_32;

      I                : Natural;
      Cleaned_Count    : Integer    := 0;
      Cleaned          : Boolean    := False;
      Total_Rx_Bytes,
      Total_Rx_Packets : C.unsigned := 0;

   begin
      I           := Integer (Rx_Ring.Next_To_Clean);
      Rx_Desc     := E1000_RX_DESC_EXT (Rx_Ring.all, I);
      Staterr     := le32_to_cpu (Rx_Desc.Wb.Upper.Status_Error);
      Buffer_Info := Rx_Ring.Buffer_Info + C.ptrdiff_t (I);

      while (Staterr and E1000_RXD_STAT_DD) /= 0
      loop
         declare
            use system.Storage_Elements;
            Skb    : access SK_Buff;
            Unused :        void_ptr;

         begin
            if C.int (Work_Done.all) >= Work_To_Do
            then
               exit;
            end if;

            Work_Done.all := Work_Done.all + 1;

            dma_rmb;     -- Read descriptor and rx_buffer_info after status DD.

            Skb             := Buffer_Info.Skb;
            Buffer_Info.Skb := null;

            prefetch (skb.data - NET_IP_ALIGN);

            I := I + 1;

            if I = Natural (Rx_Ring.Count)
            then
               I := 0;
            end if;

            Next_Rxd := E1000_RX_DESC_EXT (Rx_Ring.all, I);
            prefetch (next_rxd.all'Address);                            -- TODO: Check.

            Next_Buffer   := Rx_Ring.Buffer_Info + C.ptrdiff_t (I);
            Cleaned       := True;
            Cleaned_Count := Cleaned_Count + 1;

            dma_unmap_single (pdev.dev'Access,
                              buffer_info.dma,
                              adapter.rx_buffer_len,
                              DMA_FROM_DEVICE);

            Buffer_Info.Dma := 0;

            Length := u32 (le16_to_cpu (rx_desc.wb.upper.length));

            --  !EOP means multiple descriptors were used to store a single
            --  packet, if that's the case we need to toss it.  In fact, we
            --  need to toss every packet with the EOP bit clear and the
            --  next frame that _does_ have the EOP bit set, as it is by
            --  definition only a frame fragment
            --
            if unlikely ((Staterr and u32 (E1000_RXD_STAT_EOP)) = 0)
            then
               Adapter.Flags2 := Adapter.Flags2 or C.unsigned (FLAG2_IS_DISCARDING);
            end if;

            if (Adapter.Flags2 and C.unsigned (FLAG2_IS_DISCARDING)) /= 0
            then
               -- All receives must fit into a single buffer.
               --
               e_dbg ("Receive packet consumed multiple buffers");

               -- Recycle.
               --
               Buffer_Info.Skb := Skb;

               if (Staterr and E1000_RXD_STAT_EOP) /= 0
               then
                  Adapter.Flags2 := Adapter.Flags2 and (not C.unsigned (FLAG2_IS_DISCARDING));
               end if;

               goto Next_Desc;
            end if;


            if unlikely (    (Staterr and E1000_RXDEXT_ERR_FRAME_ERR_MASK) /= 0
                         and (Netdev.Features and NETIF_F_RXALL) = 0)
            then
               -- Recycle.
               --
               Buffer_Info.Skb := Skb;
               goto Next_Desc;
            end if;


            -- Adjust length to remove Ethernet CRC.
            --
            if (Adapter.Flags2 and C.unsigned (FLAG2_CRC_STRIPPING)) = 0
            then
               -- If configured to store CRC, don't subtract FCS,
               -- but keep the FCS bytes out of the total_rx_bytes counter.
               --
               if (Netdev.Features and NETIF_F_RXFCS) /= 0
               then
                  Total_Rx_Bytes := Total_Rx_Bytes - 4;
               else
                  Length := Length - 4;
               end if;
            end if;


            Total_Rx_Bytes   := Total_Rx_Bytes + C.unsigned (Length);
            Total_Rx_Packets := Total_Rx_Packets + 1;

            -- Code added for copybreak, this should improve
            -- performance for small packets with large amounts
            -- of reassembly being done in the stack.
            --
            if length < u32 (copybreak)
            then
               Copybreak_Code:
               declare
                  new_skb : constant access sk_buff := napi_alloc_skb (adapter.napi'Access,
                                                                       C.unsigned (length));
               begin
                  if new_skb /= null
                  then
                     skb_copy_to_linear_data_offset (new_skb,
                                                     -NET_IP_ALIGN,
                                                     skb.data            - NET_IP_ALIGN,
                                                     C.unsigned (length) + NET_IP_ALIGN);
                     -- Save the skb in buffer_info as good.
                     --
                     buffer_info.skb := skb;
                     skb             := new_skb.all'unchecked_Access;
                  end if;
               end Copybreak_Code;

            else
               null;     -- Just continue with the old one.
            end if;


            Unused := Skb_Put (Skb, C.unsigned (Length));

            -- Receive Checksum Offload.
            --
            E1000_Rx_Checksum (Adapter, Staterr, Skb);
            E1000_Rx_Hash     (Netdev,  Rx_Desc.Wb.Lower.Hi_Dword.Rss, Skb);
            E1000_Receive_Skb (Adapter, Netdev, Skb, Staterr, Rx_Desc.Wb.Upper.Vlan.Value);


            <<Next_Desc>>

            Rx_Desc.Wb.Upper.Status_Error := (Value => Rx_Desc.Wb.Upper.Status_Error.Value and not 16#FF#);

            -- Return some buffers to hardware, one at a time is too slow.
            --
            if Cleaned_Count >= E1000_RX_BUFFER_WRITE
            then
               Adapter.Alloc_Rx_Buf (Rx_Ring, C.int (Cleaned_Count), GFP_ATOMIC);
               Cleaned_Count := 0;
            end if;

            -- Use prefetched values.
            --
            Rx_Desc := Next_Rxd;
            Buffer_Info := Next_Buffer;

            Staterr := le32_to_cpu (Rx_Desc.Wb.Upper.Status_Error);
         end;
      end loop;


      Rx_Ring.Next_To_Clean := u16 (I);
      Cleaned_Count         := Integer (E1000_Desc_Unused (Rx_Ring));

      if Cleaned_Count > 0
      then
         Adapter.Alloc_Rx_Buf (Rx_Ring,
                               C.int (Cleaned_Count),
                               GFP_ATOMIC);
      end if;

      Adapter.Total_Rx_Bytes   := Adapter.Total_Rx_Bytes   + Total_Rx_Bytes;
      Adapter.Total_Rx_Packets := Adapter.Total_Rx_Packets + Total_Rx_Packets;

      return Cleaned;
   end E1000_Clean_Rx_Irq;



   ---------------------
   -- E1000_Put_Txbuf --
   ---------------------

   procedure E1000_Put_Txbuf
     (Tx_Ring      : access E1000_Ring.item;
      Buffer_Info  : access E1000_Buffer.item;
      Drop         : in     Boolean)
   is
      Adapter : access E1000_Adapter.item renames Tx_Ring.Adapter;

   begin
      if Buffer_Info.DMA /= 0
      then
         if Buffer_Info.Tx_Rx.Tx.Mapped_As_Page /= 0
         then
            DMA_Unmap_Page (Dev    => Adapter.Pdev.Dev'Access,
                            Addr   => Buffer_Info.DMA,
                            Size   => C.size_t (Buffer_Info.Tx_Rx.Tx.Length),
                            Dir    => DMA_To_Device);
         else
            DMA_Unmap_Single (Dev    => Adapter.Pdev.Dev'Access,
                              DMA    => Buffer_Info.DMA,
                              Length => u32 (Buffer_Info.Tx_Rx.Tx.Length),
                              Dir    => DMA_To_Device);
         end if;

         Buffer_Info.DMA := 0;
      end if;

      if Buffer_Info.SKB /= null
      then
         if Drop
         then
            Dev_Kfree_Skb_Any (Buffer_Info.SKB);
         else
            Dev_Consume_Skb_Any (Buffer_Info.SKB);
         end if;

         Buffer_Info.SKB := null;
      end if;

      Buffer_Info.Tx_Rx.Tx.Time_Stamp := 0;
   end E1000_Put_Txbuf;



   -------------------------
   -- E1000_Print_HW_Hang --
   -------------------------

   procedure E1000_Print_HW_Hang
     (Work : access Work_Struct)
   is
      --  use e1000.e1000_buffer.C_Pointers;

      --  Adapter  : access E1000_Adapter.item
      --    with
      --      Address => container_of (Work.all'Address);
      --                          -- , struct e1000_adapter                     -- TODO
      --                          -- , print_hang_task);
      Adapter  : constant E1000_Adapter.Pointer := E1000_Adapter.Pointer (E1000_Adapter_Conversions.to_Pointer (container_of (Work.all'Address)));

      Hw       :        E1000_HW           renames Adapter.Hw;
      Netdev   : access Net_Device         renames Adapter.Netdev;
      Tx_Ring  :        E1000_Ring.Pointer renames Adapter.Tx_Ring;

      I        : constant        C.ptrdiff_t        := C.ptrdiff_t (Tx_Ring.Next_To_Clean);
      Eop      : constant        u16                := Pointer' (Tx_Ring.Buffer_Info + I).Tx_Rx.Tx.Next_To_Watch;
      Eop_Desc : constant access E1000_Tx_Desc.item := utility.E1000_TX_DESC (Tx_Ring.all, Integer (Eop));

      Phy_Status,
      Phy_1000t_Status,
      Phy_Ext_Status : aliased Unsigned_16;
      Pci_Status     : aliased Unsigned_16;
      Unused         :         s32;

   begin
      if test_bit (E1000_DOWN'Enum_Rep, Adapter.State'Address)
      then
         return;
      end if;


      if          not Adapter.Tx_Hang_Recheck
        and then (Adapter.Flags2 and C.unsigned (FLAG2_DMA_BURST)) /= 0
      then
         -- May be block on write-back, flush and detect again
         -- flush pending descriptor writebacks to memory.
         --
         Ew32 (Hw, E1000_TIDV, Adapter.Tx_Int_Delay or E1000_TIDV_FPD);

         -- Execute the writes immediately.
         --
         E1E_Flush (Hw'Access);

         -- Due to rare timing issues, write to TIDV again to ensure
         -- the write is successful.
         --
         Ew32 (Hw, E1000_TIDV, Adapter.Tx_Int_Delay or E1000_TIDV_FPD);

         -- Execute the writes immediately.
         --
         E1E_Flush (Hw'Access);
         Adapter.Tx_Hang_Recheck := True;
         return;
      end if;


      Adapter.Tx_Hang_Recheck := False;

      if  Er32 (Hw, C.unsigned_long (E1000_TDH (0)))
        = Er32 (Hw, E1000_TDT (0))
      then
         e_dbg ("false hang detected, ignoring");
         return;
      end if;


      -- Real hang detected.
      --
      Netif_Stop_Queue (Netdev);

      Unused := E1e_Rphy (Hw'Access, MII_BMSR,     Phy_Status      'unchecked_Access);
      Unused := E1e_Rphy (Hw'Access, MII_STAT1000, Phy_1000t_Status'unchecked_Access);
      Unused := E1e_Rphy (Hw'Access, MII_ESTATUS,  Phy_Ext_Status  'unchecked_Access);

      Unused := s32 (Pci_Read_Config_Word (Adapter.Pdev,
                                           C.int (PCI_STATUS),
                                           Pci_Status'unchecked_Access));
      -- Detected Hardware unit hang.
      --
      e_err ("Detected Hardware Unit Hang:");
      e_err ("  TDH                  <" & readl (Tx_Ring.Head) 'Image & ">");
      e_err ("  TDT                  <" & readl (Tx_Ring.Tail) 'Image & ">");
      e_err ("  next_to_use          <" & Tx_Ring.Next_To_Use  'Image & ">");
      e_err ("  next_to_clean        <" & Tx_Ring.Next_To_Clean'Image & ">");
      e_err ("buffer_info[next_to_clean]:");
      e_err ("  time_stamp           <" & Pointer' (Tx_Ring.Buffer_Info + C.ptrdiff_t (Eop)
                                                   ).Tx_Rx.Tx.Time_Stamp'Image & ">");
      e_err ("  next_to_watch        <" & Eop                           'Image & ">");
      e_err ("  jiffies              <" & Jiffies                       'Image & ">");
      e_err ("  next_to_watch.status <" & Eop_Desc.Upper.Fields.Status  'Image & ">");
      e_err ("MAC Status             <" & Er32 (Hw, E1000_STATUS)       'Image & ">");
      e_err ("PHY Status             <" & Phy_Status                    'Image & ">");
      e_err ("PHY 1000BASE-T Status  <" & Phy_1000t_Status              'Image & ">");
      e_err ("PHY Extended Status    <" & Phy_Ext_Status                'Image & ">");
      e_err ("PCI Status             <" & Pci_Status                    'Image & ">");

      E1000e_Dump (Adapter);

      -- Suggest workaround for known h/w issue.
      --
      if          Hw.Mac.Mac_Type = e1000_pchlan
        and then (Er32 (Hw, E1000_CTRL) and E1000_CTRL_TFCE) /= 0
      then
         e_err ("Try turning off Tx pause (flow control) via ethtool");
      end if;
   end E1000_Print_HW_Hang;




   -----------------------------
   -- E1000e_Tx_Hwtstamp_Work --
   -----------------------------

   --    Check for Tx time stamp.
   --
   --  * @work: Pointer to work struct.
   --  *
   --  * This work function polls the TSYNCTXCTL valid bit to determine when a
   --  * timestamp has been taken for the current stored skb.  The timestamp must
   --  * be for this skb because only one such packet is allowed in the queue.


   procedure E1000e_Tx_Hwtstamp_Work
     (Work : access Work_Struct)
   is
      --  Adapter  : access E1000_Adapter.item
      --    with
      --      Address => container_of (Work.all'Address);
      --                          -- , struct e1000_adapter                     -- TODO
      --                          -- , print_hang_task);
      Adapter  : E1000_Adapter.Pointer := E1000_Adapter.Pointer (E1000_Adapter_Conversions.to_Pointer (container_of (Work.all'Address)));

      Hw : E1000_Hw renames Adapter.Hw;

   begin
      if (Er32 (Hw, E1000_TSYNCTXCTL) and E1000_TSYNCTXCTL_VALID) /= 0
      then
         declare
            Skb         : constant access Sk_Buff             := Adapter.Tx_Hwtstamp_Skb;
            Shhwtstamps : aliased         Skb_Shared_Hwtstamps;
            Txstmp      :                 u64;
         begin
            Txstmp := u64 (Er32 (Hw, E1000_TXSTMPL));
            Txstmp := Txstmp or shift_Left (u64 (Er32 (Hw, E1000_TXSTMPH)), 32);

            E1000e_Systim_To_Hwtstamp (Adapter, Shhwtstamps'Access, Txstmp);

            -- Clear the global tx_hwtstamp_skb pointer and force writes
            -- prior to notifying the stack of a Tx timestamp.
            --
            Adapter.Tx_Hwtstamp_Skb := null;
            wmb;     -- Force write prior to skb_tstamp_tx.

            Skb_Tstamp_Tx (Skb, Shhwtstamps'Access);
            Dev_Consume_Skb_Any (Skb);
         end;

      elsif time_after (jiffies,
                          adapter.tx_hwtstamp_start
                        + C.unsigned_long (adapter.tx_timeout_factor) * HZ)     -- TODO: Check.
      then
         Dev_Kfree_Skb_Any (Adapter.Tx_Hwtstamp_Skb);
         Adapter.Tx_Hwtstamp_Skb      := null;
         Adapter.Tx_Hwtstamp_Timeouts := Adapter.Tx_Hwtstamp_Timeouts + 1;
         e_warn ("clearing Tx timestamp hang");

      else
         -- Reschedule to check later.
         --
         Schedule_Work (Adapter.Tx_Hwtstamp_Work'Access);
      end if;
   end E1000e_Tx_Hwtstamp_Work;




   ------------------------
   -- E1000_Clean_Tx_Irq --
   ------------------------

   --  Reclaim resources after transmit completes.
   --
   --  * @tx_ring: Tx descriptor ring.
   --  *
   --  * The return value indicates whether actual cleaning was done, there
   --  * is no guarantee that everything was cleaned.


   function E1000_Clean_Tx_Irq
     (Tx_Ring : access E1000_Ring.item) return Boolean
   is
      Adapter  : access E1000_Adapter.item renames Tx_Ring.Adapter;
      Netdev   : access Net_Device         renames Adapter.Netdev;
      Hw       :        E1000_Hw           renames Adapter.Hw;

      I        :        u16                := Tx_Ring.Next_To_Clean;
      Eop      :        u16                := Pointer' (Tx_Ring.Buffer_Info + C.ptrdiff_t (I)
                                                      ).Tx_Rx.Tx.Next_To_Watch;
      Eop_Desc : access E1000_Tx_Desc.item := utility.E1000_TX_DESC (Tx_Ring.all, Integer (Eop));

      Buffer_Info       : access E1000_Buffer.item;

      Count             : C.unsigned := 0;
      Total_Tx_Bytes,
      Total_Tx_Packets  : C.unsigned := 0;
      Bytes_Compl,
      Pkts_Compl        : u32        := 0;

      TX_WAKE_THRESHOLD : constant   := 32;

   begin
      while (Eop_Desc.Upper.Data.Value and cpu_to_le32 (E1000_TXD_STAT_DD).Value) /= 0
        and  Count < Tx_Ring.Count
      loop
         declare
            Cleaned : Boolean := False;
         begin
            dma_rmb;      -- Read buffer_info after eop_desc.

            while not Cleaned
            loop
               declare
                  Tx_Desc : constant access E1000_Tx_Desc.item := utility.E1000_TX_DESC (Tx_Ring.all,
                                                                                         Integer (Eop));
               begin
                  Buffer_Info := Tx_Ring.Buffer_Info + C.ptrdiff_t (I);
                  Cleaned     := I = Eop;

                  if Cleaned
                  then
                     Total_Tx_Packets := Total_Tx_Packets + Buffer_Info.Tx_Rx.Tx.Segs;
                     Total_Tx_Bytes   := Total_Tx_Bytes   + Buffer_Info.Tx_Rx.Tx.Bytecount;

                     if Buffer_Info.Skb /= null
                     then
                        Bytes_Compl := Bytes_Compl + u32 (Buffer_Info.Skb.Len);
                        Pkts_Compl  := Pkts_Compl  + 1;
                     end if;
                  end if;

                  E1000_Put_Txbuf (Tx_Ring, Buffer_Info, False);
                  Tx_Desc.Upper.Data := (Value => 0);

                  I := I + 1;

                  if I = u16 (Tx_Ring.Count)
                  then
                     I := 0;
                  end if;

                  Count := Count + 1;
               end;
            end loop;


            if I = Tx_Ring.Next_To_Use
            then
               exit;
            end if;

            Eop      := Pointer' (Tx_Ring.Buffer_Info + C.ptrdiff_t (I)).Tx_Rx.Tx.Next_To_Watch;
            Eop_Desc := utility.E1000_TX_DESC (Tx_Ring.all, Integer (Eop));
         end;
      end loop;


      Tx_Ring.Next_To_Clean := I;

      Netdev_Completed_Queue (Netdev, Pkts_Compl, Bytes_Compl);


      if         Count > 0
        and then Netif_Carrier_Ok  (Netdev)
        and then E1000_Desc_Unused (Tx_Ring) >= TX_WAKE_THRESHOLD
      then
         -- Make sure that anybody stopping the queue after this
         -- sees the new next_to_clean.
         --
         smp_mb;

         if         Netif_Queue_Stopped (Netdev)
           and then not test_bit (E1000_DOWN'Enum_Rep, adapter.state'Address)
         then
            Netif_Wake_Queue (Netdev);
            Adapter.Restart_Queue := Adapter.Restart_Queue + 1;
         end if;
      end if;


      if Adapter.Detect_Tx_Hung
      then
         -- Detect a transmit hang in hardware, this serializes the
         -- check with the clearing of time_stamp and movement of i.
         --
         Adapter.Detect_Tx_Hung := False;

         if         Pointer' (Tx_Ring.Buffer_Info + C.ptrdiff_t (I)
                             ).Tx_Rx.Tx.Time_Stamp /= 0
           and then time_after (jiffies,
                                  Pointer' (tx_ring.buffer_info + C.ptrdiff_t (I)
                                           ).Tx_Rx.Tx.time_stamp
                                + C.unsigned_long (adapter.tx_timeout_factor) * HZ)
           and then (    Er32 (Hw, E1000_STATUS)
                     and E1000_STATUS_TXOFF         ) = 0
         then
            Schedule_Work (Adapter.Print_Hang_Task'Access);
         else
            Adapter.Tx_Hang_Recheck := False;
         end if;
      end if;


      Adapter.Total_Tx_Bytes   := Adapter.Total_Tx_Bytes   + Total_Tx_Bytes;
      Adapter.Total_Tx_Packets := Adapter.Total_Tx_Packets + Total_Tx_Packets;

      return Count < Tx_Ring.Count;
   end E1000_Clean_Tx_Irq;




   ---------------------------
   -- E1000_Clean_Rx_Irq_Ps --
   ---------------------------

   -- Send received data up the network stack; packet split.
   --
   --  * @rx_ring:    Rx descriptor ring.
   --  * @work_done:  Output parameter for indicating completed work.
   --  * @work_to_do: How many packets we can clean.
   --  *
   --  * The return value indicates whether actual cleaning was done, there
   --  * is no guarantee that everything was cleaned.


   function E1000_Clean_Rx_Irq_Ps
     (Rx_Ring    : access E1000_Ring.item;
      Work_Done  : access Integer;
      Work_To_Do : in     C.int) return Boolean
     with
       Convention => C;


   function E1000_Clean_Rx_Irq_Ps
     (Rx_Ring    : access E1000_Ring.item;
      Work_Done  : access Integer;
      Work_To_Do : in     C.int) return Boolean
   is
      use Devices.e1000e.Hardware.e1000_rx_desc_packet_split,
          e1000_ps_page.C_Pointers,
          system.Storage_Elements,
          system.Memory_Copy;

      use type C.ptrdiff_t;


      Adapter : access E1000_Adapter.item renames Rx_Ring.Adapter;
      --  Hw      :        E1000_Hw           renames Adapter.Hw;
      Netdev  : access Net_Device         renames Adapter.Netdev;
      Pdev    : access PCI_Dev            renames Adapter.Pdev;

      Buffer_Info,
      Next_Buffer : access E1000_Buffer .item;
      Ps_Page     :        E1000_Ps_Page.pointer;
      Skb         : access Sk_Buff;

      I                : Unsigned_32   := 0;
      Length,
      Staterr          : Unsigned_32;
      Cleaned_Count    : Integer       := 0;
      Cleaned          : Boolean       := False;
      Total_Rx_Bytes,
      Total_Rx_Packets : Unsigned_32   := 0;
      Unused           : system.Address;
      Unused1          : C.unsigned;

      Rx_Desc,
      Next_Rxd         : access E1000_Rx_Desc_Packet_Split.item;

   begin
      I           := u32 (Rx_Ring.Next_To_Clean);
      Rx_Desc     := utility.E1000_RX_DESC_PS (Rx_Ring.all, Integer (I));
      Staterr     := le32_to_cpu (Rx_Desc.Wb.Middle.Status_Error);
      Buffer_Info := Rx_Ring.Buffer_Info + C.ptrdiff_t (I);

      while (Staterr and E1000_RXD_STAT_DD) /= 0
      loop
         if C.int (Work_Done.all) >= Work_To_Do
         then
            exit;
         end if;

         Work_Done.all := Work_Done.all + 1;
         Skb           := Buffer_Info.Skb;
         dma_rmb;                                 -- Read descriptor and rx_buffer_info after status DD.

         -- In the packet split case this is header only.
         --
         prefetch (skb.data - NET_IP_ALIGN);

         I := I + 1;

         if I = u32 (Rx_Ring.Count)
         then
            I := 0;
         end if;

         Next_Rxd := utility.E1000_RX_DESC_PS (Rx_Ring.all,
                                               Integer (I));
         prefetch (next_rxd.all'Address);

         Next_Buffer := Rx_Ring.Buffer_Info + C.ptrdiff_t (I);

         Cleaned         := True;
         Cleaned_Count   := Cleaned_Count + 1;
         DMA_Unmap_Single (Pdev.Dev'Access,
                           Buffer_Info.Dma,
                           u32 (Adapter.Rx_Ps_Bsize0),
                           DMA_FROM_DEVICE);
         Buffer_Info.Dma := 0;

         --  See !EOP comment in other Rx routine.
         --
         if (Staterr and E1000_RXD_STAT_EOP) = 0
         then
            Adapter.Flags2 := Adapter.Flags2 or C.unsigned (FLAG2_IS_DISCARDING);
         end if;

         if (Adapter.Flags2 and C.unsigned (FLAG2_IS_DISCARDING)) /= 0
         then
            e_dbg ("Packet Split buffers didn't pick up the full packet");
            Dev_Kfree_Skb_Irq (Skb);

            if (Staterr and u32 (E1000_RXD_STAT_EOP)) /= 0
            then
               Adapter.Flags2 := Adapter.Flags2 and (C.unsigned (not FLAG2_IS_DISCARDING));
            end if;

            goto Next_Desc;
         end if;

         if    ((Staterr and E1000_RXDEXT_ERR_FRAME_ERR_MASK) /= 0)
           and ((Netdev.Features and NETIF_F_RXALL) = 0)
         then
            Dev_Kfree_Skb_Irq (Skb);
            goto Next_Desc;
         end if;

         Length :=  u32 (Rx_Desc.Wb.Middle.Length0.Value);

         if Length = 0
         then
            e_dbg ("Last part of the packet spanning multiple descriptors");
            Dev_Kfree_Skb_Irq (Skb);
            goto Next_Desc;
         end if;

         -- Good Receive.
         --
         Unused := Skb_Put (Skb, C.unsigned (Length));

         declare
            -- This looks ugly, but it seems compiler issues make
            -- it more efficient than reusing j.
            --
            L1 : u16 := le16_to_cpu (Rx_Desc.Wb.Upper.Length (0));
         begin
            -- Page alloc/put takes too long and effects small
            -- packet throughput, so unsplit small packets and
            -- save the alloc/put.
            --
            if    L1                /= 0
              and L1                <= u16 (Copybreak)
              and u16 (Length) + L1 <= Adapter.Rx_Ps_Bsize0
            then
               Ps_Page := Buffer_Info.Tx_Rx.Rx.Ps_Pages;

               DMA_Sync_Single_For_CPU (Pdev.Dev'Access,
                                        Ps_Page.Dma,
                                        PAGE_SIZE,
                                        DMA_FROM_DEVICE);

               memCpy (Skb_Tail_Pointer (Skb),
                       Page_Address (Ps_Page.Page),
                       System.CRTL.size_t (L1));

               DMA_Sync_Single_For_Device (Pdev.Dev'Access,
                                           Ps_Page.Dma,
                                           PAGE_SIZE,
                                           DMA_FROM_DEVICE);

               if (Adapter.Flags2 and C.unsigned (FLAG2_CRC_STRIPPING)) = 0
               then
                  if (Netdev.Features and NETIF_F_RXFCS) = 0
                  then
                     L1 := L1 - 4;
                  end if;
               end if;

               Unused := Skb_Put (Skb, C.unsigned (L1));
               goto Copydone;
            end if;
         end;


         for J in 0 .. C.ptrdiff_t (PS_PAGE_BUFFERS) - 1
         loop
            Length := u32 (Rx_Desc.Wb.Upper.Length (C.size_t (J)).Value);

            if Length = 0
            then
               exit;
            end if;

            Ps_Page      := Buffer_Info.Tx_Rx.Rx.Ps_Pages + J;
            DMA_Unmap_Page (Pdev.Dev'Access, Ps_Page.Dma, PAGE_SIZE, DMA_FROM_DEVICE);
            Ps_Page.Dma  := 0;
            Skb_Fill_Page_Desc (Skb,
                                Integer (J),
                                Ps_Page.Page,
                                0,
                                Integer (Length));
            Ps_Page.Page := null;
            Skb.Len      := Skb.Len + Natural (Length);
            Skb.Data_Len := Skb.Data_Len + Length;
            Skb.Truesize := Skb.Truesize + PAGE_SIZE;
         end loop;


         if (Adapter.Flags2 and C.unsigned (FLAG2_CRC_STRIPPING)) = 0
         then
            if (Netdev.Features and NETIF_F_RXFCS) = 0
            then
               Unused1 := Pskb_Trim (Skb, u32 (Skb.Len) - 4);
            end if;
         end if;


         <<Copydone>>

         Total_Rx_Bytes   := Total_Rx_Bytes + u32 (Skb.Len);
         Total_Rx_Packets := Total_Rx_Packets + 1;

         E1000_Rx_Checksum (Adapter, Staterr, Skb);

         E1000_Rx_Hash (Netdev, Rx_Desc.Wb.Lower.Hi_Dword.Rss, Skb);

         if (    Rx_Desc.Wb.Upper.Header_Status         .Value
             and cpu_to_le16 (E1000_RXDPS_HDRSTAT_HDRSP).Value) /= 0
         then
            Adapter.Rx_Hdr_Split := Adapter.Rx_Hdr_Split + 1;
         end if;

         E1000_Receive_Skb (Adapter, Netdev, Skb, Staterr, Rx_Desc.Wb.Middle.Vlan.Value);


         <<Next_Desc>>

         Rx_Desc.Wb.Middle.Status_Error.Value := Rx_Desc.Wb.Middle.Status_Error.Value and not cpu_to_le32 (16#FF#).Value;
         Buffer_Info.Skb                      := null;

         if Cleaned_Count >= E1000_RX_BUFFER_WRITE
         then
            Adapter.Alloc_Rx_Buf (Rx_Ring, C.int (Cleaned_Count), GFP_ATOMIC);
            Cleaned_Count := 0;
         end if;

         Rx_Desc     := Next_Rxd;
         Buffer_Info := Next_Buffer;
         Staterr     := le32_to_cpu (Rx_Desc.Wb.Middle.Status_Error);
      end loop;


      Rx_Ring.Next_To_Clean := u16 (I);

      Cleaned_Count := Integer (E1000_Desc_Unused (Rx_Ring));

      if Cleaned_Count /= 0
      then
         Adapter.Alloc_Rx_Buf (Rx_Ring, C.int (Cleaned_Count), GFP_ATOMIC);
      end if;

      Adapter.Total_Rx_Bytes   := Adapter.Total_Rx_Bytes   + C.unsigned (Total_Rx_Bytes);
      Adapter.Total_Rx_Packets := Adapter.Total_Rx_Packets + C.unsigned (Total_Rx_Packets);

      return Cleaned;
   end E1000_Clean_Rx_Irq_Ps;




   ------------------------
   -- E1000_Consume_Page --
   ------------------------

   procedure E1000_Consume_Page
     (
      Bi     : access E1000_Buffer.item;
      Skb    : access sk_buff;
      Length : in     u16)
   is
   begin
      Bi.Tx_Rx.RX.Page := null;
      Skb.Len          := Skb.Len      + Natural (Length);
      Skb.Data_Len     := Skb.Data_Len + u32     (Length);
      Skb.Truesize     := Skb.Truesize + u32     (PAGE_SIZE);
   end E1000_Consume_Page;




   ------------------------------
   -- E1000_Clean_Jumbo_Rx_Irq --
   ------------------------------

   --    Send received data up the network stack; legacy.
   --
   --  * @rx_ring:    Rx descriptor ring.
   --  * @work_done:  Output parameter for indicating completed work.
   --  * @work_to_do: How many packets we can clean.
   --  *
   --  * The return value indicates whether actual cleaning was done, there
   --  * is no guarantee that everything was cleaned.

   function E1000_Clean_Jumbo_Rx_Irq
     (Rx_Ring    : access E1000_Ring.item;
      Work_Done  : access Integer;
      Work_To_Do : in     C.int) return Boolean
     with
       Convention => C;


   function E1000_Clean_Jumbo_Rx_Irq
     (Rx_Ring    : access E1000_Ring.item;
      Work_Done  : access Integer;
      Work_To_Do : in     C.int) return Boolean
   is
      use system.Memory_Copy;
      use type C.ptrdiff_t;

      Adapter : access E1000_Adapter.item renames Rx_Ring.Adapter;
      Netdev  : access Net_Device         renames Adapter.Netdev;
      Pdev    : access PCI_Dev            renames Adapter.Pdev;

      Rx_Desc     : access E1000_Rx_Desc_Extended.item;
      Next_Rxd    : access E1000_Rx_Desc_Extended.item;
      Buffer_Info :        E1000_Buffer.pointer;
      Next_Buffer :        E1000_Buffer.pointer;
      Length      :        u32;
      Staterr     :        u32;

      I                :        C.ptrdiff_t;
      Cleaned_Count    :        Natural     := 0;
      Cleaned          :        Boolean     := False;
      Total_Rx_Bytes   :        Natural     := 0;
      Total_Rx_Packets :        Natural     := 0;
      Unused           :        system.Address;
      Shinfo           : access Skb_Shared_Info;

   begin
      I           := C.ptrdiff_t (Rx_Ring.Next_To_Clean);
      Rx_Desc     := utility.E1000_RX_DESC_EXT (Rx_Ring.all, Integer (I));
      Staterr     := le32_to_cpu (Rx_Desc.Wb.Upper.Status_Error);
      Buffer_Info := Rx_Ring.Buffer_Info + I;

      while (Staterr and E1000_RXD_STAT_DD) /= 0
      loop
         declare
            Skb : access Sk_Buff;
         begin
            if C.int (Work_Done.all) >= Work_To_Do
            then
               exit;
            end if;

            Work_Done.all := Work_Done.all + 1;

            Dma_Rmb;     -- Read descriptor and rx_buffer_info after status DD.

            Skb             := Buffer_Info.Skb;
            Buffer_Info.Skb := null;

            I := I + 1;

            if C.unsigned (I) = Rx_Ring.Count
            then
               I := 0;
            end if;

            Next_Rxd := utility.E1000_RX_DESC_EXT (Rx_Ring.all, Integer (I));
            prefetch (next_rxd.all'Address);     -- TODO: Check.

            Next_Buffer := Rx_Ring.Buffer_Info + I;

            Cleaned         := True;
            Cleaned_Count   := Cleaned_Count + 1;
            Dma_Unmap_Page (Pdev.Dev'Access, Buffer_Info.Dma, PAGE_SIZE, DMA_FROM_DEVICE);
            Buffer_Info.Dma := 0;

            Length := u32 (le16_to_cpu (Rx_Desc.Wb.Upper.Length));

            -- Errors is only valid for DD + EOP descriptors.
            --
            if unlikely (         (Staterr and E1000_RXD_STAT_EOP) /= 0
                         and then (         (Staterr         and E1000_RXDEXT_ERR_FRAME_ERR_MASK) /= 0
                                   and then (Netdev.Features and NETIF_F_RXALL) = 0))
            then
               -- Recycle both page and skb.
               --
               Buffer_Info.Skb := Skb;

               -- An error means any chain goes out the window too.
               --
               if Rx_Ring.Rx_Skb_Top /= null
               then
                  Dev_Kfree_Skb_Irq (Rx_Ring.Rx_Skb_Top);
               end if;

               Rx_Ring.Rx_Skb_Top := null;
               goto Next_Desc;
            end if;


            if (Staterr and E1000_RXD_STAT_EOP) = 0
            then
               -- This descriptor is only the beginning (or middle).
               --
               if Rx_Ring.Rx_Skb_Top = null
               then
                  -- This is the beginning of a chain.
                  --
                  Rx_Ring.Rx_Skb_Top := Skb;
                  Skb_Fill_Page_Desc (Rx_Ring.Rx_Skb_Top,
                                      0,
                                      Buffer_Info.Tx_Rx.Rx.Page,
                                      0,
                                      Integer (Length));
               else
                  -- This is the middle of a chain.
                  --
                  Shinfo := Skb_Shinfo (Rx_Ring.Rx_Skb_Top);
                  Skb_Fill_Page_Desc (Rx_Ring.Rx_Skb_Top,
                                      Integer (Shinfo.Nr_Frags),
                                      Buffer_Info.Tx_Rx.Rx.Page,
                                      0,
                                      Integer (Length));
                  -- Re-use the skb, only consumed the page.
                  --
                  Buffer_Info.Skb := Skb;
               end if;

               E1000_Consume_Page (Buffer_Info, Rx_Ring.Rx_Skb_Top, u16 (Length));
               goto Next_Desc;

            else
               if Rx_Ring.Rx_Skb_Top /= null
               then
                  -- End of the chain.
                  --
                  Shinfo := Skb_Shinfo (Rx_Ring.Rx_Skb_Top);
                  Skb_Fill_Page_Desc (Rx_Ring.Rx_Skb_Top,
                                      Integer (Shinfo.Nr_Frags),
                                      Buffer_Info.Tx_Rx.Rx.Page,
                                      0,
                                      Integer (Length));

                  -- Re-use the current skb, we only consumed the page.
                  --
                  Buffer_Info.Skb    := Skb;
                  Skb                := Rx_Ring.Rx_Skb_Top;
                  Rx_Ring.Rx_Skb_Top := null;
                  E1000_Consume_Page (Buffer_Info, Skb, u16 (Length));
               else
                  -- No chain, got EOP, this buf is the packet
                  -- Copybreak to save the put_page/alloc_page.
                  --
                  if         Length             <= u32 (Copybreak)
                    and then Skb_Tailroom (Skb) >= Integer (Length)
                  then
                     memcpy (skb_tail_pointer(skb),
                             page_address (buffer_info.Tx_Rx.Rx.page),
                             System.CRTL.size_t (length));
                     -- Re-use the page, so don't erase 'Buffer_Info.Page'.
                     --
                     Unused := Skb_Put (Skb, C.unsigned (Length));
                  else
                     Skb_Fill_Page_Desc (Skb,
                                         0,
                                         Buffer_Info.Tx_Rx.Rx.Page,
                                         0,
                                         Integer (Length));
                     E1000_Consume_Page (Buffer_Info, Skb, u16 (Length));
                  end if;
               end if;
            end if;

            -- Receive Checksum Offload.
            --
            E1000_Rx_Checksum (Adapter, Staterr, Skb);
            E1000_Rx_Hash     (Netdev,  Rx_Desc.Wb.Lower.Hi_Dword.Rss, Skb);

            -- Probably a little skewed due to removing CRC.
            --
            Total_Rx_Bytes   := Total_Rx_Bytes   + Skb.Len;
            Total_Rx_Packets := Total_Rx_Packets + 1;

            -- Eth type trans needs skb->data to point to something.
            --
            if not Pskb_May_Pull (Skb, ETH_HLEN)
            then
               e_err ("pskb_may_pull failed.");
               Dev_Kfree_Skb_Irq (Skb);
               goto Next_Desc;
            end if;


            E1000_Receive_Skb (Adapter,
                               Netdev,
                               Skb,
                               Staterr,
                               Rx_Desc.Wb.Upper.Vlan.Value);

            <<Next_Desc>>

            Rx_Desc.Wb.Upper.Status_Error.Value := Rx_Desc.Wb.Upper.Status_Error.Value and (not 16#FF#);

            -- Return some buffers to hardware, one at a time is too slow.
            --
            if Cleaned_Count >= E1000_RX_BUFFER_WRITE
            then
               Adapter.Alloc_Rx_Buf (Rx_Ring, C.int (Cleaned_Count), GFP_ATOMIC);
               Cleaned_Count := 0;
            end if;

            -- Use prefetched values.
            --
            Rx_Desc     := Next_Rxd;
            Buffer_Info := Next_Buffer;

            Staterr := le32_to_cpu (Rx_Desc.Wb.Upper.Status_Error);
         end;
      end loop;


      Rx_Ring.Next_To_Clean := u16 (I);
      Cleaned_Count         := Integer (E1000_Desc_Unused (Rx_Ring));

      if Cleaned_Count /= 0
      then
         Adapter.Alloc_Rx_Buf (Rx_Ring, C.int (Cleaned_Count), GFP_ATOMIC);
      end if;

      Adapter.Total_Rx_Bytes   := Adapter.Total_Rx_Bytes   + C.unsigned (Total_Rx_Bytes);
      Adapter.Total_Rx_Packets := Adapter.Total_Rx_Packets + C.unsigned (Total_Rx_Packets);

      return Cleaned;
   end E1000_Clean_Jumbo_Rx_Irq;




   -------------------------
   -- E1000_Clean_Rx_Ring --
   -------------------------

   --  Free Rx Buffers per Queue.
   --
   --  * @rx_ring: Rx descriptor ring.


   procedure E1000_Clean_Rx_Ring
     (Rx_Ring : access E1000_Ring.item)
   is
      use Devices.e1000e.Hardware.e1000_rx_desc_packet_split,
          Devices.e1000e.Base.e1000_ps_page.C_Pointers;

      use type Devices.e1000e.Base.clean_rx_func.item;

      Adapter     : access E1000_Adapter.item renames Rx_Ring.Adapter;
      Pdev        : access PCI_Dev            renames Adapter.Pdev;
      Buffer_Info : access E1000_Buffer.item;
      Ps_Page     : access E1000_Ps_Page.item;
      Unused      :        Integer;

   begin
      -- Free all the Rx ring sk_buffs.
      --
      for I in 0 .. Rx_Ring.Count - 1
      loop
         Buffer_Info := Rx_Ring.Buffer_Info + C.ptrdiff_t (I);

         if Buffer_Info.Dma /= 0
         then
            if Adapter.Clean_Rx = E1000_Clean_Rx_Irq'Access
            then
               DMA_Unmap_Single (Pdev.Dev'Access, Buffer_Info.Dma,
                                 Adapter.Rx_Buffer_Len,
                                 DMA_FROM_DEVICE);

            elsif Adapter.Clean_Rx = E1000_Clean_Jumbo_Rx_Irq'Access
            then
               DMA_Unmap_Page (Pdev.Dev'Access, Buffer_Info.Dma,
                               PAGE_SIZE, DMA_FROM_DEVICE);

            elsif Adapter.Clean_Rx = E1000_Clean_Rx_Irq_Ps'Access
            then
               DMA_Unmap_Single (Pdev.Dev'Access, Buffer_Info.Dma,
                                 u32 (Adapter.Rx_Ps_Bsize0),
                                 DMA_FROM_DEVICE);
            end if;

            Buffer_Info.Dma := 0;
         end if;


         if Buffer_Info.Tx_Rx.Rx.Page /= null
         then
            Unused                    := Put_Page (Buffer_Info.Tx_Rx.Rx.Page);
            Buffer_Info.Tx_Rx.Rx.Page := null;
         end if;

         if Buffer_Info.Skb /= null
         then
            Dev_Kfree_Skb (Buffer_Info.Skb);
            Buffer_Info.Skb := null;
         end if;

         for J in 0 .. C.ptrdiff_t (PS_PAGE_BUFFERS - 1)
         loop
            Ps_Page := Buffer_Info.Tx_Rx.Rx.Ps_Pages + J;
            exit when Ps_Page.Page = null;

            DMA_Unmap_Page (Pdev.Dev'Access,
                            Ps_Page.Dma,
                            PAGE_SIZE,
                            DMA_FROM_DEVICE);

            Ps_Page.Dma  := 0;
            Unused       := Put_Page (Ps_Page.Page);
            Ps_Page.Page := null;
         end loop;

      end loop;


      -- There also may be some cached data from a chained receive.
      --
      if Rx_Ring.Rx_Skb_Top /= null
      then
         Dev_Kfree_Skb (Rx_Ring.Rx_Skb_Top);
         Rx_Ring.Rx_Skb_Top := null;
      end if;

      -- Zero out the descriptor ring.
      --
      memset (rx_ring.desc, 0, rx_ring.size);

      Rx_Ring.Next_To_Clean := 0;
      Rx_Ring.Next_To_Use   := 0;
      Adapter.Flags2        := Adapter.Flags2 and c.unsigned (not FLAG2_IS_DISCARDING);
   end E1000_Clean_Rx_Ring;




   ---------------------------------
   -- E1000e_Downshift_Workaround --
   ---------------------------------

   procedure E1000e_Downshift_Workaround
     (Work : access Work_Struct)
   is
      use Devices.e1000e.Ich8Lan;

      --  Adapter  : access E1000_Adapter.item
      --    with
      --      Address => container_of (Work.all'Address);
      --  -- , struct e1000_adapter                     -- TODO
      --  -- , downshift_task);

      Adapter  : E1000_Adapter.Pointer := E1000_Adapter.Pointer (E1000_Adapter_Conversions.to_Pointer (container_of (Work.all'Address)));

   begin
      if Test_Bit (E1000_DOWN'Enum_Rep, Adapter.State'Address)
      then
         return;
      end if;

      E1000e_Gig_Downshift_Workaround_Ich8lan (Adapter.Hw'Access);
   end E1000e_Downshift_Workaround;




   --------------------
   -- E1000_Intr_MSI --
   --------------------

   --    Interrupt Handler.
   --
   --  * @irq:  Interrupt number.
   --  * @data: Pointer to a network interface device structure.


   function E1000_Intr_MSI
     (Irq  : in C.int;
      Data : in void_ptr) return IrqReturn_t
   is
      Netdev  : aliased Net_Device
        with
          Address => Data,
          Import;

      --  Adapter : access E1000_Adapter.item
      --    with
      --      Address => Netdev_Priv (Netdev'Access);

      Adapter : E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev'Access);

      Hw      : constant access E1000_HW := Adapter.Hw'Access;
      Icr     : constant        u32      := Er32 (Hw.all, E1000_ICR);
      Unused  :                 Integer;
      Unused2 :                 Boolean;

   begin
      -- Read ICR disables interrupts using IAM.
      --
      if (Icr and E1000_ICR_LSC) /= 0
      then
         Hw.Mac.Get_Link_Status := True;

         -- ICH8 workaround-- Call gig speed drop workaround on cable
         -- disconnect (LSC) before accessing any PHY registers.
         --
         if    (Adapter.Flags and C.unsigned (FLAG_LSC_GIG_SPEED_DROP)) /= 0
           and (Er32 (Hw.all, E1000_STATUS) and E1000_STATUS_LU)         = 0
         then
            Schedule_Work (Adapter.Downshift_Task'Access);
         end if;

         -- 80003ES2LAN workaround-- For packet buffer work-around on
         -- link down event; disable receives here in the ISR and reset
         -- adapter in watchdog.
         --
         if    Netif_Carrier_Ok (Netdev'Access)
           and (Adapter.Flags and C.unsigned (FLAG_RX_NEEDS_RESTART)) /= 0
         then
            -- Disable receives.
            --
            declare
               Rctl : constant Unsigned_32 := Er32 (Hw.all, E1000_RCTL);
            begin
               Ew32 (Hw.all, E1000_RCTL, Rctl and (not E1000_RCTL_EN));
               Adapter.Flags := Adapter.Flags or C.unsigned (FLAG_RESTART_NOW);
            end;
         end if;

         -- Guard against interrupt when we're going down.
         --
         if not Test_Bit (E1000_DOWN'Enum_Rep,
                          Adapter.State'Address)
         then
            Unused := Mod_Timer (Adapter.Watchdog_Timer'Access,
                                 Jiffies + 1);
         end if;
      end if;


      -- Reset on uncorrectable ECC error.
      --
      if    ((Icr and E1000_ICR_ECCER) /= 0)
        and (Hw.Mac.mac_Type           >= E1000_Pch_Lpt)
      then
         declare
            Pbeccsts : constant Unsigned_32 := Er32 (Hw.all, E1000_PBECCSTS);
         begin
            Adapter.Corr_Errors   := Adapter.Corr_Errors   + C.unsigned ((Pbeccsts and E1000_PBECCSTS_CORR_ERR_CNT_MASK));
            Adapter.Uncorr_Errors := Adapter.Uncorr_Errors + C.unsigned (Field_Get (E1000_PBECCSTS_UNCORR_ERR_CNT_MASK, Pbeccsts));

            -- Do the reset outside of interrupt context.
            --
            Schedule_Work (Adapter.Reset_Task'Access);

            -- Return immediately since reset is imminent.
            --
            return IRQ_HANDLED;
         end;
      end if;


      if Napi_Schedule_Prep (Adapter.Napi'Access)
      then
         Adapter.Total_Tx_Bytes   := 0;
         Adapter.Total_Tx_Packets := 0;
         Adapter.Total_Rx_Bytes   := 0;
         Adapter.Total_Rx_Packets := 0;

         Unused2 := Napi_Schedule (Adapter.Napi'Access);
      end if;

      return IRQ_HANDLED;
   end E1000_Intr_MSI;




   ----------------
   -- E1000_Intr --
   ----------------

   --  Interrupt Handler.
   --
   --  * @irq:  Interrupt number.
   --  * @data: Pointer to a network interface device structure.


   function E1000_Intr
     (Irq    : in C.int with Unreferenced;
      Data   : in void_ptr               ) return irqreturn_t
   is
      Netdev  : aliased Net_Device
        with
          Address => Data,
          Import;

      Adapter : aliased E1000_Adapter.item
        with
          Address => netdev_priv (Netdev'Access),
          Import;

      Hw      : constant access E1000_Hw := Adapter.Hw'Access;
      Icr     : constant        U32      := Er32 (Hw.all, E1000_ICR);
      Rctl    :                 U32;
      Unused  :                 Integer;
      Unused2 :                 Boolean;

   begin
      if        Icr = 0
        or else Test_Bit (E1000_DOWN'enum_Rep, Adapter.State'Address)
      then
         return IRQ_NONE;     -- Not our interrupt.
      end if;


      -- IMS will not auto-mask if INT_ASSERTED is not set, and if it is
      -- not set, then the adapter didn't send an interrupt.
      --
      if (Icr and E1000_ICR_INT_ASSERTED) = 0
      then
         return IRQ_NONE;
      end if;

      -- Interrupt Auto-Mask...upon reading ICR,
      -- interrupts are masked. No need for the IMC write.
      --
      if (Icr and E1000_ICR_LSC) /= 0
      then
         Hw.Mac.Get_Link_Status := True;

         -- ICH8 workaround-- Call gig speed drop workaround on cable
         -- disconnect (LSC) before accessing any PHY registers.
         --
         if    (Adapter.Flags           and C.unsigned (FLAG_LSC_GIG_SPEED_DROP)) /= 0
           and (Er32 (Hw.all, E1000_STATUS) and E1000_STATUS_LU        )  = 0
         then
            Schedule_Work (Adapter.Downshift_Task'Access);
         end if;

         -- 80003ES2LAN workaround.
         -- For packet buffer work-around on link down event;
         -- disable receives here in the ISR and reset adapter in watchdog.
         --
         if    Netif_Carrier_Ok (Netdev'Access)
           and (Adapter.Flags and C.unsigned (FLAG_RX_NEEDS_RESTART)) /= 0
         then
            -- Disable receives.
            --
            Rctl          := Er32 (Hw.all, E1000_RCTL);
            Ew32 (Hw.all, E1000_RCTL, Rctl and (not E1000_RCTL_EN));
            Adapter.Flags := Adapter.Flags or C.unsigned (FLAG_RESTART_NOW);
         end if;

         -- Guard against interrupt when we're going down.
         --
         if not Test_Bit (E1000_DOWN'enum_Rep, Adapter.State'Address)
         then
            Unused := mod_Timer (Adapter.Watchdog_Timer'Access, Jiffies + 1);
         end if;
      end if;


      -- Reset on uncorrectable ECC error.
      --
      if    (Icr and E1000_ICR_ECCER) /= 0
        and Hw.Mac.Mac_Type >= E1000_Pch_Lpt
      then
         declare
            Pbeccsts : constant U32 := Er32 (Hw.all, E1000_PBECCSTS);
         begin
            Adapter.Corr_Errors   := @ + C.unsigned (Pbeccsts and E1000_PBECCSTS_CORR_ERR_CNT_MASK);
            Adapter.Uncorr_Errors := @ + C.unsigned (Field_Get (E1000_PBECCSTS_UNCORR_ERR_CNT_MASK, Pbeccsts));

            -- Do the reset outside of interrupt context.
            --
            Schedule_Work (Adapter.Reset_Task'Access);

            -- Return immediately since reset is imminent.
            --
            return IRQ_HANDLED;
         end;
      end if;

      if Napi_Schedule_Prep (Adapter.Napi'Access)
      then
         Adapter.Total_Tx_Bytes   := 0;
         Adapter.Total_Tx_Packets := 0;
         Adapter.Total_Rx_Bytes   := 0;
         Adapter.Total_Rx_Packets := 0;
         Unused2                  := Napi_Schedule (Adapter.Napi'Access);
      end if;

      return IRQ_HANDLED;
   end E1000_Intr;




   ----------------------
   -- E1000_MSIX_Other --
   ----------------------

   function E1000_MSIX_Other
     (Irq   : in C.int with Unreferenced;
      Data  : in void_ptr                 ) return irqreturn_t
   is
      Netdev  : aliased Net_Device
        with
          Address => Data,
          Import;

      Adapter : aliased E1000_Adapter.item
        with
          Address => netdev_priv (Netdev'Access),
          Import;

      Hw      : constant access E1000_Hw := Adapter.Hw'Access;
      Icr     : constant        u32      := Er32 (Hw.all, E1000_ICR);
      Unused  :                 Integer;

   begin
      if (Icr and Adapter.Eiac_Mask) /= 0
      then
         Ew32 (Hw.all,
               E1000_ICS,
               Icr and Adapter.Eiac_Mask);
      end if;

      if (Icr and E1000_ICR_LSC) /= 0
      then
         Hw.Mac.Get_Link_Status := True;

         -- Guard against interrupt when we're going down.
         --
         if not test_bit (E1000_DOWN'Enum_Rep, adapter.state'Address)
         then
            Unused := mod_timer (adapter.watchdog_timer'Access, jiffies + 1);
         end if;
      end if;

      if not test_bit (E1000_DOWN'Enum_Rep, adapter.state'Address)
      then
         ew32 (Hw.all,
               E1000_IMS,
               E1000_IMS_OTHER or IMS_OTHER_MASK);
      end if;

      return IRQ_HANDLED;
   end E1000_MSIX_Other;




   ------------------------
   -- E1000_Intr_MSIX_TX --
   ------------------------

   function E1000_Intr_MSIX_TX
     (Irq  : in C.int with Unreferenced;
      Data : in void_ptr               ) return irqreturn_t
   is
      Netdev  : aliased Net_Device
        with
          Address => Data,
          Import;

      Adapter : aliased E1000_Adapter.item
        with
          Address => netdev_priv (Netdev'Access),
        Import;

      Hw      : constant access E1000_Hw        := Adapter.Hw'Access;
      TX_Ring : constant access E1000_Ring.item := Adapter.TX_Ring;

   begin
      Adapter.Total_TX_Bytes   := 0;
      Adapter.Total_TX_Packets := 0;

      if not E1000_Clean_TX_IRQ (TX_Ring)
      then
         -- Ring was not completely cleaned, so fire another interrupt.
         --
         EW32 (Hw.all, E1000_ICS, TX_Ring.IMS_Val);
      end if;

      if not Test_Bit (E1000_DOWN'Enum_Rep, Adapter.State'Address)
      then
         EW32 (Hw.all, E1000_IMS, Adapter.TX_Ring.IMS_Val);
      end if;

      return IRQ_HANDLED;
   end E1000_Intr_MSIX_TX;




   ------------------------
   -- E1000_Intr_MSIX_RX --
   ------------------------

   function E1000_Intr_MSIX_RX
     (Irq  : in C.int with Unreferenced;
      Data : in void_ptr               ) return irqreturn_t
   is
      Netdev  : aliased Net_Device
        with
          Address => Data,
          Import;

      Adapter : aliased E1000_Adapter.item
        with
          Address => netdev_priv (Netdev'Access),
        Import;

      Rx_Ring : constant access E1000_Ring.item := Adapter.Rx_Ring;
      Unused  :                 Boolean;

   begin
      -- Write the ITR value calculated at the end of the previous interrupt.
      --
      if Rx_Ring.Set_ITR /= 0
      then
         declare
            ITR : Unsigned_32;
         begin
            if Rx_Ring.ITR_Val /= 0
            then
               ITR := 1_000_000_000 / (Rx_Ring.ITR_Val * 256);
            else
               ITR := 0;
            end if;

            Writel (ITR, Rx_Ring.ITR_Register);
            Rx_Ring.Set_ITR := 0;
         end;
      end if;

      if NAPI_Schedule_Prep (Adapter.NAPI'Access)
      then
         Adapter.Total_RX_Bytes   := 0;
         Adapter.Total_RX_Packets := 0;

         Unused := NAPI_Schedule (Adapter.NAPI'Access);
      end if;

      return IRQ_HANDLED;
   end E1000_Intr_MSIX_RX;




   --------------------------
   -- E1000_Configure_MSIX --
   --------------------------

   --    Configure MSI-X hardware.
   --
   --  * @adapter: Board private structure.
   --  *
   --  * e1000_configure_msix sets up the hardware to properly
   --  * generate MSI-X interrupts.


   procedure E1000_Configure_MSIX
     (Adapter : access E1000_Adapter.item)
   is
      use Devices.e1000e.an_82571,
          System.Storage_Elements;

      HW       : constant access E1000_HW        := Adapter.HW'Access;
      Rx_Ring  : constant access E1000_Ring.item := Adapter.Rx_Ring;
      Tx_Ring  : constant access E1000_Ring.item := Adapter.Tx_Ring;

      Vector   : Integer     := 0;
      Ivar     : Unsigned_32 := 0;
      Ctrl_Ext : Unsigned_32;

   begin
      Adapter.EIAC_Mask := 0;

      -- Workaround issue with spurious interrupts on 82574 in MSI-X mode.
      --
      if HW.Mac.Mac_Type = E1000_82574
      then
         declare
            Rfctl : Unsigned_32 := Er32 (HW.all, E1000_RFCTL);
         begin
            Rfctl := Rfctl or E1000_RFCTL_ACK_DIS;
            Ew32 (Hw.all, E1000_RFCTL, Rfctl);
         end;
      end if;

      -- Configure Rx vector.
      --
      Rx_Ring.IMS_Val   := E1000_IMS_RXQ0;
      Adapter.EIAC_Mask := Adapter.EIAC_Mask or Rx_Ring.IMS_Val;

      if Rx_Ring.ITR_Val /= 0
      then
         Writel (1_000_000_000 / (Rx_Ring.ITR_Val * 256),
                 Rx_Ring.ITR_Register);
      else
         Writel (1, Rx_Ring.ITR_Register);
      end if;

      Ivar := E1000_IVAR_INT_ALLOC_VALID or Unsigned_32 (Vector);

      -- Configure Tx vector.
      --
      Tx_Ring.IMS_Val := E1000_IMS_TXQ0;
      Vector          := Vector + 1;

      if Tx_Ring.ITR_Val /= 0
      then
         Writel (1_000_000_000 / (Tx_Ring.ITR_Val * 256),
                 Tx_Ring.ITR_Register);
      else
         Writel (1, Tx_Ring.ITR_Register);
      end if;

      Adapter.EIAC_Mask := Adapter.EIAC_Mask or Tx_Ring.IMS_Val;
      Ivar              := Ivar              or shift_Left (E1000_IVAR_INT_ALLOC_VALID or Unsigned_32 (Vector),
                                                            8);

      -- Set vector for Other Causes, e.g. link changes.
      --
      Vector := Vector + 1;
      Ivar   := Ivar or shift_Left (E1000_IVAR_INT_ALLOC_VALID or Unsigned_32 (Vector),
                                    16);
      if Rx_Ring.ITR_Val /= 0
      then
         Writel (1_000_000_000 / (Rx_Ring.ITR_Val * 256),
                 HW.HW_Addr + storage_Offset (E1000_EITR_82574 (Vector)));
      else
         Writel (1, HW.HW_Addr + storage_Offset (E1000_EITR_82574 (Vector)));
      end if;

      -- Cause Tx interrupts on every write back.
      --
      Ivar := Ivar or shift_Left (1, 31);

      Ew32 (Hw.all, E1000_IVAR, Ivar);

      -- Enable MSI-X PBA support.
      --
      Ctrl_Ext := Er32 (Hw.all, E1000_CTRL_EXT) and (not E1000_CTRL_EXT_IAME);
      Ctrl_Ext := Ctrl_Ext or E1000_CTRL_EXT_PBA_CLR or E1000_CTRL_EXT_EIAME;

      Ew32 (Hw.all, E1000_CTRL_EXT, Ctrl_Ext);
      E1e_Flush (Hw);
   end E1000_Configure_MSIX;



   ---------------------------------------
   -- E1000e_Reset_Interrupt_Capability --
   ---------------------------------------

   procedure E1000e_Reset_Interrupt_Capability
     (Adapter : access E1000_Adapter.item)
   is
   begin
      if Adapter.Msix_Entries /= null
      then
         PCI_Disable_MSIX (Adapter.Pdev);
         kFree (Adapter.Msix_Entries'Address);
         Adapter.Msix_Entries := null;

      elsif (Adapter.Flags and C.unsigned (FLAG_MSI_ENABLED)) /= 0
      then
         PCI_Disable_MSI (Adapter.Pdev);
         Adapter.Flags := Adapter.Flags and (not C.unsigned (FLAG_MSI_ENABLED));
      end if;
   end E1000e_Reset_Interrupt_Capability;




   -------------------------------------
   -- E1000e_Set_Interrupt_Capability --
   -------------------------------------

   --    Set MSI or MSI-X if supported.
   --
   --  * @adapter: Board private structure.
   --  *
   --  * Attempt to configure interrupts using the best available
   --  * capabilities of the hardware and kernel.


   package msix_entry_Conversions is new system.Address_To_Access_Conversions (msix_Entry);


   procedure E1000e_Set_Interrupt_Capability
     (Adapter : access E1000_Adapter.item)
   is
      use msix_entry_Conversions;

      Err : Integer;

   begin
      case Adapter.Int_Mode
      is
         when E1000E_INT_MODE_MSIX =>

            if (Adapter.Flags and C.unsigned (FLAG_HAS_MSIX)) /= 0
            then
               Adapter.Num_Vectors  := 3;                                   -- RxQ0, TxQ0 and other.
               Adapter.MSIX_Entries := msix_entry_pointer (to_Pointer (kcalloc (Integer (adapter.num_vectors),
                                                                                msix_entry'Size / 8,
                                                                                GFP_KERNEL)));

               if Adapter.MSIX_Entries /= null
               then
                  declare
                     Last    : constant C.size_t := C.size_t (Adapter.Num_Vectors - 1);

                     Entries : msix_entry_array (0 .. Last)
                       with
                         Address => Adapter.msix_entries.all'Address;
                  begin
                     for i in 0 .. Last
                     loop
                        Entries (i).the_Entry := u16 (i);
                     end loop;
                  end;

                  Err := PCI_Enable_MSIX_Range (Dev     => Adapter.Pdev,
                                                Entries => Adapter.MSIX_Entries,
                                                Minvec  => Integer (Adapter.Num_Vectors),
                                                Maxvec  => Integer (Adapter.Num_Vectors));

                  if Err > 0
                  then
                     return;
                  end if;
               end if;


               -- MSI-X failed, so fall through and try MSI.
               --
               e_err ("Failed to initialize MSI-X interrupts. Falling back to MSI interrupts.");
               E1000e_Reset_Interrupt_Capability (Adapter.all'Access);
            end if;

            Adapter.Int_Mode := E1000E_INT_MODE_MSI;


         when E1000E_INT_MODE_MSI =>

            if PCI_Enable_MSI (Adapter.Pdev) = 0
            then
               Adapter.Flags := Adapter.Flags or C.unsigned (FLAG_MSI_ENABLED);
            else
               Adapter.Int_Mode := E1000E_INT_MODE_LEGACY;
               e_err ("Failed to initialize MSI interrupts. Falling back to legacy interrupts.");
            end if;


         when E1000E_INT_MODE_LEGACY =>

            null;     -- Don't do anything; this is the system default.


         when others =>

            raise program_Error;
      end case;


      Adapter.Num_Vectors := 1;          -- Store the number of vectors being used.
   end E1000e_Set_Interrupt_Capability;




   ------------------------
   -- E1000_Request_MSIX --
   ------------------------

   --    Initialize MSI-X interrupts.
   --
   --  * @adapter: Board private structure.
   --  *
   --  * e1000_request_msix allocates MSI-X vectors and requests interrupts from the kernel.


   function E1000_Request_MSIX
     (Adapter : access E1000_Adapter.item) return C.int
   is
      use Devices.e1000e.an_82571,
          system.CRTL,
          system.Storage_Elements,
          interfaces.C.Strings;

      Netdev  : constant access Net_Device := Adapter.Netdev;
      Err     :                 C.int      := 0;
      Vector  :                 C.size_t   := 0;

      Last    : constant C.size_t := 2;
      Entries : msix_entry_array (0 .. Last)
        with
          Address => Adapter.msix_entries.all'Address;

   begin
      if Netdev.Name.all'Length < IFNAMSIZ - 5
      then
         Snprintf (Adapter.Rx_Ring.Name,
                   Adapter.Rx_Ring.Name'Length - 1,
                   Netdev.Name.all & "-rx-0");
      else
         memcpy (Adapter.Rx_Ring.Name'Address,
                 Netdev.Name.all     'Address,
                 IFNAMSIZ);
      end if;

      Err := Request_IRQ (C.unsigned (Entries (Vector).Vector),
                          E1000_Intr_MSIX_RX'Access,
                          0,
                          new_Char_Array (Adapter.Rx_Ring.Name),
                          Netdev.all'Address);
      if Err /= 0
      then
         return Err;
      end if;


      Adapter.Rx_Ring.Itr_Register := Adapter.Hw.Hw_Addr + storage_Offset (E1000_EITR_82574 (Integer (Vector)));
      Adapter.Rx_Ring.Itr_Val      := Adapter.Itr;
      Vector                       := Vector + 1;

      if Netdev.Name.all'Length < IFNAMSIZ - 5
      then
         Snprintf (Adapter.Tx_Ring.Name,
                   Adapter.Tx_Ring.Name'Length - 1,
                   Netdev.Name.all & "-tx-0");
      else
         memcpy (Adapter.Tx_Ring.Name'Address,
                 Netdev.Name.all     'Address,
                 IFNAMSIZ);
      end if;

      Err := Request_IRQ (C.unsigned (Entries (Vector).Vector),
                          E1000_Intr_MSIX_TX'Access,
                          0,
                          new_Char_Array (Adapter.Tx_Ring.Name),
                          Netdev.all'Address);
      if Err /= 0
      then
         return Err;
      end if;


      Adapter.Tx_Ring.Itr_Register := Adapter.Hw.Hw_Addr + storage_Offset (E1000_EITR_82574 (Integer (Vector)));
      Adapter.Tx_Ring.Itr_Val      := Adapter.Itr;
      Vector                       := Vector + 1;

      Err := Request_IRQ (C.unsigned (Entries (Vector).Vector),
                          E1000_MSIX_Other'Access,
                          0,
                          new_String (Netdev.Name.all),
                          Netdev.all'Address);
      if Err /= 0
      then
         return Err;
      end if;


      E1000_Configure_MSIX (Adapter);
      return 0;
   end E1000_Request_MSIX;




   -----------------------
   -- E1000_Request_IRQ --
   -----------------------

   --    Initialize interrupts.
   --
   --  * @adapter: Board private structure.
   --  *
   --  * Attempts to configure interrupts using the best available
   --  * capabilities of the hardware and kernel.


   function E1000_Request_IRQ
     (Adapter : access E1000_Adapter.item) return C.int
   is
      use C.Strings;

      Netdev : constant access Net_Device := Adapter.Netdev;
      Err    :                 C.int;

   begin
      if Adapter.Msix_Entries /= null
      then
         Err := E1000_Request_MSIX (Adapter);

         if Err = 0
         then
            return Err;
         end if;


         -- Fall back to MSI.
         --
         E1000e_Reset_Interrupt_Capability (Adapter.all'Access);
         Adapter.Int_Mode := E1000E_INT_MODE_MSI;
         E1000e_Set_Interrupt_Capability (Adapter.all'Access);
      end if;


      if (Adapter.Flags and C.unsigned (FLAG_MSI_ENABLED)) /= 0
      then
         Err := Request_IRQ (IRQ     => Adapter.Pdev.IRQ,
                             Handler => E1000_Intr_MSI'Access,
                             Flags   => 0,
                             Name    => new_String (Netdev.Name.all),
                             Dev     => Netdev.all'Address);
         if Err = 0
         then
            return Err;
         end if;


         -- Fall back to legacy interrupt.
         --
         E1000e_Reset_Interrupt_Capability (Adapter.all'Access);
         Adapter.Int_Mode := E1000E_INT_MODE_LEGACY;
      end if;

      Err := Request_IRQ (IRQ     => Adapter.Pdev.IRQ,
                          Handler => E1000_Intr'Access,
                          Flags   => IRQF_SHARED,
                          Name    => new_String (Netdev.Name.all),
                          Dev     => Netdev.all'Address);
      if Err /= 0
      then
         e_err ("Unable to allocate interrupt, Error:" & Err'Image);
      end if;

      return Err;
   end E1000_Request_IRQ;




   --------------------
   -- E1000_Free_IRQ --
   --------------------

   procedure E1000_Free_IRQ
     (Adapter : access E1000_Adapter.item)
   is
      Netdev  : constant access   Net_Device := Adapter.Netdev;
      Unused  :                   void_ptr;
      Last    : constant          C.size_t   := 2;
      Entries :                   msix_entry_array (0 .. Last)
        with
          Address => Adapter.msix_entries.all'Address;

   begin
      if Adapter.MSIX_Entries /= null
      then
         declare
            Vector : C.size_t := 0;
         begin
            Unused := Free_IRQ (C.unsigned (Entries (Vector).Vector), Netdev.all'Address);
            Vector := Vector + 1;

            Unused := Free_IRQ (C.unsigned (Entries (Vector).Vector), Netdev.all'Address);
            Vector := Vector + 1;

            -- Other Causes interrupt vector.
            --
            Unused := Free_IRQ (C.unsigned (Entries (Vector).Vector), Netdev.all'Address);
            return;
         end;
      end if;

      Unused := Free_IRQ (Adapter.Pdev.IRQ, Netdev.all'Address);
   end E1000_Free_IRQ;





   -----------------------
   -- E1000_IRQ_Disable --
   -----------------------

   --  Mask off interrupt generation on the NIC.
   --
   --  * @adapter: Board private structure.


   procedure E1000_IRQ_Disable
     (Adapter : access E1000_Adapter.item)
   is
      use Devices.e1000e.an_82571;

      Hw : constant access E1000_HW := Adapter.Hw'Access;

   begin
      EW32 (Hw.all, E1000_IMC, not 0);

      if Adapter.MSIX_Entries /= null
      then
         EW32 (Hw.all, E1000_EIAC_82574, 0);
      end if;

      E1E_Flush (Hw);


      if Adapter.MSIX_Entries /= null
      then
         declare
            Last    : constant C.size_t   := C.size_t (Adapter.Num_Vectors - 1);
            Entries :          msix_entry_array (0 .. Last)
              with
                Address => Adapter.msix_entries.all'Address;
         begin
            for i in 0 .. Last
            loop
               Synchronize_IRQ (C.unsigned (Entries (i).Vector));
            end loop;
         end;
      else
         Synchronize_IRQ (Adapter.PDEV.IRQ);
      end if;
   end E1000_IRQ_Disable;




   ----------------------
   -- E1000_IRQ_Enable --
   ----------------------

   --  Enable default interrupt generation settings.
   --
   --  * @adapter: Board private structure.


   procedure E1000_IRQ_Enable
     (Adapter : access E1000_Adapter.item)
   is
      use Devices.e1000e.an_82571;

      HW : constant access E1000_HW := Adapter.HW'Access;

   begin
      if Adapter.MSIX_Entries /= null
      then
         EW32 (Hw.all, E1000_EIAC_82574, Adapter.EIAC_Mask and E1000_EIAC_MASK_82574);
         EW32 (Hw.all, E1000_IMS, Adapter.EIAC_Mask or E1000_IMS_OTHER or IMS_OTHER_MASK);

      elsif HW.Mac.mac_Type >= E1000_PCH_LPT
      then
         EW32 (Hw.all, E1000_IMS, u32 (IMS_ENABLE_MASK) or E1000_IMS_ECCER);

      else
         EW32 (Hw.all, E1000_IMS, u32 (IMS_ENABLE_MASK));
      end if;

      E1E_Flush (Hw);
   end E1000_IRQ_Enable;




   ---------------------------
   -- E1000e_Get_HW_Control --
   ---------------------------

   --    Get control of the h/w from f/w.
   --
   --  * @adapter: Address of board private structure.
   --  *
   --  * e1000e_get_hw_control sets {CTRL_EXT|SWSM}:DRV_LOAD bit.
   --  * For ASF and Pass Through versions of f/w this means that
   --  * the driver is loaded. For AMT version (only with 82573)
   --  * of the f/w this means that the network i/f is open.


   procedure E1000e_Get_HW_Control
     (Adapter : access E1000_Adapter.item)
   is
      HW       : constant access E1000_HW   := Adapter.HW'Access;
      Ctrl_Ext :                 Unsigned_32;
      SWSM     :                 Unsigned_32;
   begin
      -- Let firmware know the driver has taken over.
      --
      if (Adapter.Flags and C.unsigned (FLAG_HAS_SWSM_ON_LOAD)) /= 0
      then
         SWSM := Er32 (HW.all, E1000_SWSM);
         Ew32 (HW.all, E1000_SWSM, SWSM or E1000_SWSM_DRV_LOAD);

      elsif (Adapter.Flags and C.unsigned (FLAG_HAS_CTRLEXT_ON_LOAD)) /= 0
      then
         Ctrl_Ext := Er32 (HW.all, E1000_CTRL_EXT);
         Ew32 (HW.all, E1000_CTRL_EXT, Ctrl_Ext or E1000_CTRL_EXT_DRV_LOAD);
      end if;
   end E1000e_Get_HW_Control;




   -------------------------------
   -- E1000e_Release_HW_Control --
   -------------------------------

   --  Release control of the h/w to f/w.
   --
   --  * @adapter: Address of board private structure.
   --  *
   --  * e1000e_release_hw_control resets {CTRL_EXT|SWSM}:DRV_LOAD bit.
   --  * For ASF and Pass Through versions of f/w this means that the
   --  * driver is no longer loaded. For AMT version (only with 82573) i
   --  * of the f/w this means that the network i/f is closed.


   procedure E1000e_Release_HW_Control
     (Adapter : access E1000_Adapter.item)
   is
      HW       : constant access E1000_HW   := Adapter.HW'Access;
      Ctrl_Ext :                 Unsigned_32;
      SWSM     :                 Unsigned_32;

   begin
      -- Let firmware take over control of h/w.
      --
      if (Adapter.Flags and C.unsigned (FLAG_HAS_SWSM_ON_LOAD)) /= 0
      then
         SWSM := Er32 (HW.all, E1000_SWSM);
         Ew32 (HW.all, E1000_SWSM, SWSM and (not E1000_SWSM_DRV_LOAD));

      elsif (Adapter.Flags and C.unsigned (FLAG_HAS_CTRLEXT_ON_LOAD)) /= 0
      then
         Ctrl_Ext := Er32 (HW.all, E1000_CTRL_EXT);
         Ew32 (HW.all, E1000_CTRL_EXT, Ctrl_Ext and (not E1000_CTRL_EXT_DRV_LOAD));
      end if;
   end E1000e_Release_HW_Control;




   --------------------------
   -- E1000_Alloc_Ring_DMA --
   --------------------------

   --    Allocate memory for a ring structure.
   --
   --  * @adapter: Board private structure.
   --  * @ring:    Ring struct for which to allocate dma.


   function E1000_Alloc_Ring_DMA
     (Adapter : access E1000_Adapter.item;
      Ring    : access E1000_Ring.item) return Interfaces.C.int
   is
      use type system.Address;

      PDev : constant access PCI_Dev := Adapter.PDev;

   begin
      Ring.Desc := DMA_Alloc_Coherent (Dev         => PDev.Dev'Access,
                                       Size        => C.size_t (Ring.Size),
                                       DMA_Handle  => Ring.DMA'Access,
                                       GFP         => GFP_KERNEL);

      if Ring.Desc = System.Null_Address
      then
         return -ENOMEM;
      end if;

      return 0;
   end E1000_Alloc_Ring_DMA;




   -------------------------------
   -- E1000e_Setup_Tx_Resources --
   -------------------------------

   --    Allocate Tx resources (Descriptors).
   --
   --  * @tx_ring: Tx descriptor ring.
   --  *
   --  * Return 0 on success, negative on failure.

   package e1000_buffer_Conversions is new system.Address_to_Access_Conversions (e1000_buffer.item);


   function E1000e_Setup_Tx_Resources
     (Tx_Ring : access E1000_Ring.item) return C.int
   is
      Adapter : constant access E1000_Adapter.item := Tx_Ring.Adapter;
      Err     :                 C.int              := -ENOMEM;
      Size    :                 Integer;

   begin
      Size                := E1000_Buffer.item'Size * Integer (Tx_Ring.Count) / 8;
      Tx_Ring.Buffer_Info := e1000_Buffer.Pointer (e1000_buffer_Conversions.to_Pointer (vzalloc (C.int (Size))));

      if Tx_Ring.Buffer_Info = null
      then
         goto Err_Out;
      end if;


      -- Round up to nearest 4K.
      --
      Tx_Ring.Size := Tx_Ring.Count * E1000_Tx_Desc.item'Size / 8;
      Tx_Ring.Size := (Tx_Ring.Size + 4095) and not 4095;

      Err := E1000_Alloc_Ring_Dma (Adapter, Tx_Ring);

      if Err /= 0
      then
         goto Err_Out;
      end if;


      Tx_Ring.Next_To_Use   := 0;
      Tx_Ring.Next_To_Clean := 0;

      return 0;


      <<Err_Out>>

      vFree (Tx_Ring.Buffer_Info.all'Address);
      e_err ("Unable to allocate memory for the transmit descriptor ring");
      return Err;
   end E1000e_Setup_Tx_Resources;






   -------------------------------
   -- E1000e_Setup_Rx_Resources --
   -------------------------------

   --    Allocate Rx resources (Descriptors).
   --
   --  * @rx_ring: Rx descriptor ring.
   --  *
   --  * Returns 0 on success, negative on failure.

   package Ps_Page_Conversions is new system.Address_to_Access_Conversions (e1000_Ps_Page.item);


   function E1000e_Setup_Rx_Resources
     (Rx_Ring : access E1000_Ring.item) return C.int
   is
      use Devices.e1000e.Hardware.e1000_rx_desc_packet_split;

      use type Devices.e1000e.Base.e1000_ps_page.Pointer,
               C.ptrdiff_t;

      Adapter     : constant access E1000_Adapter.item := Rx_Ring.Adapter;
      Buffer_Info :                 E1000_Buffer.Pointer;
      Size        :                 Integer;
      Desc_Len    :                 Integer;
      Err         :                 C.int  := -ENOMEM;

   begin
      Size                := Integer (Rx_Ring.Count) * E1000_Buffer.item'Size / system.Storage_Unit;
      Rx_Ring.Buffer_Info := e1000_Buffer.Pointer (e1000_buffer_Conversions.to_Pointer (vzalloc (C.int (Size))));

      if Rx_Ring.Buffer_Info = null
      then
         goto Err_Out;
      end if;


      for I in 0 .. C.ptrdiff_t (Rx_Ring.Count) - 1
      loop
         Buffer_Info                   := Rx_Ring.Buffer_Info + I;
         Buffer_Info.Tx_Rx.Rx.Ps_Pages := Devices.e1000e.Base.e1000_ps_page.Pointer (Ps_Page_Conversions.to_Pointer (kcalloc (PS_PAGE_BUFFERS,
                                                                                                                e1000_ps_page.item'Size / system.Storage_Unit,
                                                                                                                GFP_KERNEL)));
         if Buffer_Info.Tx_Rx.Rx.Ps_Pages = null
         then
            goto Err_Pages;
         end if;
      end loop;

      Desc_Len := E1000_Rx_Desc_Packet_Split.item'Size / system.Storage_Unit;

      -- Round up to nearest 4K.
      --
      Rx_Ring.Size := Rx_Ring.Count * C.unsigned (Desc_Len);
      Rx_Ring.Size := ALIGN (Rx_Ring.Size, 4096);

      Err := E1000_Alloc_Ring_Dma (Adapter, Rx_Ring);

      if Err /= 0
      then
         goto Err_Pages;
      end if;

      Rx_Ring.Next_To_Clean := 0;
      Rx_Ring.Next_To_Use   := 0;
      Rx_Ring.Rx_Skb_Top    := null;

      return 0;


      <<Err_Pages>>

      for I in 0 .. C.ptrdiff_t (Rx_Ring.Count) - 1
      loop
         Buffer_Info := Rx_Ring.Buffer_Info + I;
         kfree (Buffer_Info.Tx_Rx.Rx.Ps_Pages.all'Address);
      end loop;


      <<Err_Out>>

      vfree (Rx_Ring.Buffer_Info.all'Address);
      e_err ("Unable to allocate memory for the receive descriptor ring");
      return Err;
   end E1000e_Setup_Rx_Resources;




   -------------------------
   -- E1000_Clean_Tx_Ring --
   -------------------------

   --  Free Tx Buffers.
   --
   --  * @tx_ring: Tx descriptor ring.


   procedure E1000_Clean_Tx_Ring
     (Tx_Ring : access E1000_Ring.item)
   is
      use type C.ptrdiff_t;

      Adapter     : constant access E1000_Adapter.item := Tx_Ring.Adapter;
      Buffer_Info :                 E1000_Buffer.Pointer;
      Size        :                 C.unsigned;

   begin
      for I in 0 .. C.ptrdiff_t (Tx_Ring.Count) - 1
      loop
         Buffer_Info := Tx_Ring.Buffer_Info + I;
         E1000_Put_Txbuf (Tx_Ring, Buffer_Info, False);
      end loop;

      Netdev_Reset_Queue (Adapter.Netdev);

      Size := E1000_Buffer.item'Size / System.Storage_Unit * Tx_Ring.Count;
      memset (Tx_Ring.Buffer_Info.all'Address, 0, Size);

      memset (Tx_Ring.Desc'Address, 0, Tx_Ring.size);

      Tx_Ring.Next_To_Use   := 0;
      Tx_Ring.Next_To_Clean := 0;
   end E1000_Clean_Tx_Ring;




   ------------------------------
   -- E1000e_Free_Tx_Resources --
   ------------------------------

   --  Free Tx Resources per Queue.
   --
   --  * @tx_ring: Tx descriptor ring.
   --  *
   --  * Free all transmit software resources.


   procedure E1000e_Free_Tx_Resources
     (Tx_Ring : access E1000_Ring.item)
   is
      Adapter : constant access E1000_Adapter.item := Tx_Ring.Adapter;
      Pdev    :          access PCI_Dev            := Adapter.Pdev;

   begin
      E1000_Clean_Tx_Ring (Tx_Ring);

      vFree (Tx_Ring.Buffer_Info.all'Address);
      Tx_Ring.Buffer_Info := null;

      DMA_Free_Coherent (Dev        => Pdev.Dev'Access,
                         Size       => C.size_t (Tx_Ring.Size),
                         Cpu_Addr   => Tx_Ring.Desc,
                         Dma_Handle => Tx_Ring.Dma);
      Tx_Ring.Desc := system.Null_Address;
   end E1000e_Free_Tx_Resources;




   ------------------------------
   -- E1000e_Free_Rx_Resources --
   ------------------------------

   --  Free Rx Resources.
   --
   --  * @rx_ring: Rx descriptor ring.
   --  *
   --  * Free all receive software resources.


   procedure E1000e_Free_Rx_Resources
     (Rx_Ring : access E1000_Ring.item)
   is
      Adapter     : constant access E1000_Adapter.item  := Rx_Ring.Adapter;
      Pdev        :          access PCI_Dev             := Adapter.Pdev;
      Buffer_Info :                 E1000_Buffer.Pointer;
   begin
      E1000_Clean_Rx_Ring (Rx_Ring);

      for I in 0 .. C.ptrdiff_t (Rx_Ring.Count - 1)
      loop
         Buffer_Info := Rx_Ring.Buffer_Info + I;
         kfree (Buffer_Info.Tx_Rx.Rx.Ps_Pages.all'Address);
      end loop;

      vFree (Rx_Ring.Buffer_Info.all'Address);
      rx_ring.buffer_info := null;

      DMA_Free_Coherent
        (Dev        => Pdev.Dev'Access,
         Size       => C.size_t (Rx_Ring.Size),
         Cpu_Addr   => Rx_Ring.Desc'Address,
         DMA_Handle => Rx_Ring.DMA);

      Rx_Ring.Desc := system.Null_Address;
   end E1000e_Free_Rx_Resources;




   ----------------------
   -- E1000_Update_ITR --
   ----------------------

   --    Update the dynamic ITR value based on statistics.
   --
   --  * @itr_setting: Current adapter->itr.
   --  * @packets:     The number of packets during this measurement interval.
   --  * @bytes:       The number of bytes during this measurement interval.
   --  *
   --  *      Stores a new ITR value based on packets and byte
   --  *      counts during the last interrupt.  The advantage of per interrupt
   --  *      computation is faster updates and more accurate ITR for the current
   --  *      traffic pattern.  Constants in this function were computed
   --  *      based on theoretical maximum wire speed and thresholds were set based
   --  *      on testing data as well as attempting to minimize response time
   --  *      while increasing bulk throughput.  This functionality is controlled
   --  *      by the InterruptThrottleRate module parameter.


   function E1000_Update_ITR
     (ITR_Setting : in latency_range;
      Packets     : in C.unsigned;
      Bytes       : in C.unsigned) return C.unsigned
   is
      Retval : latency_range := ITR_Setting;

   begin
      if Packets = 0
      then
         return Retval'Enum_Rep;
      end if;


      case ITR_Setting
      is
         when Lowest_Latency =>
            -- Handle TSO and jumbo frames.
            --
            if Bytes / Packets > 8000
            then
               Retval := Bulk_Latency;

            elsif (Packets < 5) and (Bytes > 512)
            then
               Retval := Low_Latency;
            end if;


         when Low_Latency =>
            -- 50 usec aka 20000 ints/s.
            --
            if Bytes > 10000
            then
               -- This if handles the TSO accounting.
               --
               if Bytes / Packets > 8000
               then
                  Retval := Bulk_Latency;

               elsif (Packets < 10) or ((Bytes / Packets) > 1200)
               then
                  Retval := Bulk_Latency;

               elsif Packets > 35
               then
                  Retval := Lowest_Latency;
               end if;

            elsif Bytes / Packets > 2000
            then
               Retval := Bulk_Latency;

            elsif Packets <= 2 and Bytes < 512
            then
               Retval := Lowest_Latency;
            end if;


         when Bulk_Latency =>
            -- 250 usec aka 4000 ints/s.
            --
            if Bytes > 25000
            then
               if Packets > 35
               then
                  Retval := Low_Latency;
               end if;

            elsif Bytes < 6000
            then
               Retval := Low_Latency;
            end if;

         when others =>
            null;
      end case;


      return Retval'Enum_Rep;
   end E1000_Update_ITR;




   ----------------------
   -- E1000e_Write_Itr --
   ----------------------

   --    Write the ITR value to the appropriate registers.
   --
   --  * @adapter: Address of board private structure.
   --  * @itr:     New ITR value to program.
   --  *
   --  * e1000e_write_itr determines if the adapter is in MSI-X mode
   --  * and, if so, writes the EITR registers with the ITR value.
   --  * Otherwise, it writes the ITR value into the ITR register.


   procedure E1000e_Write_Itr
     (Adapter : access E1000_Adapter.item;
      Itr     : in     Unsigned_32)
   is
      use Devices.e1000e.an_82571,
          system.Storage_Elements;

      Hw      : constant access E1000_Hw   := Adapter.Hw'Access;
      New_Itr :                 Unsigned_32;

   begin
      if Itr /= 0
      then
         New_Itr := 1_000_000_000 / (Itr * 256);
      else
         New_Itr := 0;
      end if;


      if Adapter.Msix_Entries /= null
      then
         for Vector in 0 .. Integer (Adapter.Num_Vectors) - 1
         loop
            writel (New_Itr,
                    Hw.Hw_Addr + Storage_Offset (E1000_EITR_82574 (Vector)));
         end loop;

      else
         Ew32 (Hw.all, E1000_ITR, New_Itr);
      end if;
   end E1000e_Write_Itr;





   -------------------
   -- E1000_Set_ITR --
   -------------------

   procedure E1000_Set_ITR
     (Adapter : access E1000_Adapter.item)
   is
      Current_ITR : Unsigned_16;
      New_ITR     : Unsigned_32 := Adapter.ITR;


      procedure Set_ITR_Now
      is
      begin
         if New_ITR /= Adapter.ITR
         then
            -- This attempts to bias the interrupt rate towards Bulk
            -- by adding intermediate steps when interrupt rate is increasing.
            --
            if New_ITR > Adapter.ITR
            then
               New_ITR := Unsigned_32'Min (Adapter.ITR + shift_Right (New_ITR, 2),
                                           New_ITR);
            end if;

            Adapter.ITR             := New_ITR;
            Adapter.Rx_Ring.ITR_Val := New_ITR;

            if Adapter.MSIX_Entries /= null
            then
               Adapter.Rx_Ring.Set_ITR := 1;
            else
               E1000e_Write_ITR (Adapter.all'Access,
                                 New_ITR);
            end if;
         end if;
      end Set_ITR_Now;


   begin
      -- For non-gigabit speeds, just fix the interrupt rate at 4000.
      --
      if Adapter.Link_Speed /= SPEED_1000
      then
         New_ITR := 4000;
         Set_ITR_Now;
         return;
      end if;


      if (Adapter.Flags2 and C.unsigned (FLAG2_DISABLE_AIM)) /= 0
      then
         New_ITR := 0;
         Set_ITR_Now;
         return;
      end if;


      Adapter.TX_ITR := u16 (E1000_Update_ITR (latency_range'Enum_Val (Adapter.TX_ITR),
                                               Adapter.Total_TX_Packets,
                                               Adapter.Total_TX_Bytes));

      -- Conservative mode (ITR 3) eliminates the lowest_latency setting.
      --
      if    Adapter.ITR_Setting = 3
        and Adapter.TX_ITR      = Lowest_Latency'Enum_Rep
      then
         Adapter.TX_ITR := Low_Latency'Enum_Rep;
      end if;

      Adapter.RX_ITR := u16 (E1000_Update_ITR (latency_range'Enum_Val (Adapter.RX_ITR),
                                               Adapter.Total_RX_Packets,
                                               Adapter.Total_RX_Bytes));

      -- Conservative mode (ITR 3) eliminates the lowest_latency setting.
      --
      if    Adapter.ITR_Setting = 3
        and Adapter.RX_ITR      = Lowest_Latency'Enum_Rep
      then
         Adapter.RX_ITR := Low_Latency'Enum_Rep;
      end if;

      Current_ITR := Unsigned_16'Max (Adapter.RX_ITR,
                                      Adapter.TX_ITR);

      -- Counts and packets in update_itr are dependent on these numbers.
      --
      case latency_range'Enum_Val (Current_ITR)
      is
         when Lowest_Latency =>   New_ITR := 70_000;
         when Low_Latency    =>   New_ITR := 20_000;     -- aka hwitr = ~200
         when Bulk_Latency   =>   New_ITR :=  4_000;
         when others         =>   null;
      end case;

      Set_ITR_Now;
   end E1000_Set_ITR;





   ------------------------
   -- E1000_Alloc_Queues --
   ------------------------

   --  Allocate memory for all rings.
   --
   --  * @adapter: Board private structure to initialize.


   package e1000_ring_Conversions is new system.Address_to_Access_Conversions (Devices.e1000e.Base.e1000_ring.item);


   function E1000_Alloc_Queues
     (Adapter : access E1000_Adapter.item) return Integer
   is
      use type Devices.e1000e.Base.e1000_ring.Pointer;

      Size : constant Integer := E1000_Ring.item'Size / system.Storage_Unit;

   begin
      Adapter.Tx_Ring := e1000_ring.Pointer (e1000_ring_Conversions.to_Pointer (kzalloc (size,
                                                                                         GFP_KERNEL)));

      if Adapter.Tx_Ring = null
      then
         goto Err;
      end if;

      adapter.tx_ring.count   := C.unsigned (adapter.tx_ring_count);
      adapter.tx_ring.adapter := adapter;


      Adapter.Rx_Ring := e1000_ring.Pointer (e1000_ring_Conversions.to_Pointer (kzalloc (size,
                                                                                         GFP_KERNEL)));
      if Adapter.Rx_Ring = null
      then
         goto Err;
      end if;

      adapter.Rx_ring.count   := C.unsigned (adapter.Rx_ring_count);
      adapter.Rx_ring.adapter := adapter;


      return 0;


      <<Err>>

      e_err ("Unable to allocate memory for queues");
      kFree (Adapter.Rx_Ring.all'Address);
      kFree (Adapter.Tx_Ring.all'Address);

      return -ENOMEM;
   end E1000_Alloc_Queues;




   -----------------
   -- E1000e_Poll --
   -----------------

   --    NAPI Rx polling callback.
   --
   --  * @napi:   Struct associated with this polling callback.
   --  * @budget: Number of packets driver is allowed to process this poll.


   function E1000e_Poll
     (Napi   : access NAPI_Struct;
      Budget : in     C.int) return C.int
   is
      Adapter  : E1000_Adapter.Pointer := E1000_Adapter.Pointer (E1000_Adapter_Conversions.to_Pointer (container_of (Napi.all'Address)));
                                                                                                                     -- , struct e1000_adapter                     -- TODO
                                                                                                                     -- , Napi);
      HW         : constant access E1000_HW   := Adapter.HW'Access;
      Poll_Dev   : constant access Net_Device := Adapter.Netdev;
      Tx_Cleaned :                 Boolean    := True;
      Work_Done  : aliased         Integer    := 0;
      Unused     :                 Boolean;

   begin
      Adapter := E1000_Adapter.Pointer (E1000_Adapter_Conversions.to_Pointer (Netdev_Priv (Poll_Dev)));

      if         Adapter.MSIX_Entries          = null
        or else (    Adapter.Rx_Ring.IMS_Val
                 and Adapter.Tx_Ring.IMS_Val) /= 0
      then
         Tx_Cleaned := E1000_Clean_Tx_Irq (Adapter.Tx_Ring);
      end if;

      Unused := Adapter.Clean_Rx (Adapter.Rx_Ring, Work_Done'Access, Budget);

      if    not Tx_Cleaned
        or else C.int (Work_Done) = Budget
      then
         return Budget;
      end if;


      -- Exit the polling mode, but don't re-enable interrupts if stack might
      -- poll us due to busy-polling.
      --
      if NAPI_Complete_Done (Napi, Work_Done)
      then
         if (Adapter.ITR_Setting and 3) /= 0
         then
            E1000_Set_ITR (Adapter);
         end if;

         if not Test_Bit (E1000_DOWN'Enum_Rep, Adapter.State'Address)
         then
            if Adapter.MSIX_Entries /= null
            then
               EW32 (Hw.all, E1000_IMS, Adapter.Rx_Ring.IMS_Val);
            else
               E1000_IRQ_Enable (Adapter);
            end if;
         end if;
      end if;

      return C.int (Work_Done);
   end E1000e_Poll;




   ---------------------------
   -- E1000_Vlan_Rx_Add_Vid --
   ---------------------------

   function E1000_Vlan_Rx_Add_Vid
     (Netdev : access Net_Device;
      Proto  : in     Unsigned_16 with Unreferenced;
      Vid    : in     Unsigned_16                  ) return C.int
   is
      Adapter : E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev);

      Hw      : constant access E1000_Hw   := Adapter.Hw'Access;
      Vfta    :                 Unsigned_32;
      Index   :                 Unsigned_32;

   begin
      -- Don't update vlan cookie if already programmed.
      --
      if         (    Adapter.Hw.Mng_Cookie.Status
                  and Devices.e1000e.Manage.E1000_MNG_DHCP_Cookie_Status_Vlan) /= 0
        and then Vid = Adapter.Mng_Vlan_Id
      then
         return 0;
      end if;


      -- Add VID to filter table.
      --
      if (Adapter.Flags and C.unsigned (Flag_Has_Hw_Vlan_Filter)) /= 0
      then
         Index := shift_Right (Unsigned_32 (Vid), 5) and 16#7F#;
         Vfta  := E1000_Read_Reg_Array (Hw, E1000_VFTA, Index);
         Vfta  := Vfta or BIT (Natural (Vid and 16#1F#));

         Hw.Mac.Ops.Write_Vfta (Hw, Index, Vfta);
      end if;

      Set_Bit (Natural (Vid), Adapter.Active_Vlans'Address);

      return 0;
   end E1000_Vlan_Rx_Add_Vid;




   ----------------------------
   -- E1000_Vlan_Rx_Kill_Vid --
   ----------------------------

   function E1000_Vlan_Rx_Kill_Vid
     (Netdev : access Net_Device;
      Proto  : in     Unsigned_16 with Unreferenced;
      Vid    : in     Unsigned_16                  ) return C.int
   is
      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev);

      Hw      : constant access E1000_Hw   := Adapter.Hw'Access;
      Vfta    :                 Unsigned_32;
      Index   :                 Unsigned_32;

   begin
      if         (    Adapter.Hw.Mng_Cookie.Status
                  and Devices.e1000e.Manage.E1000_MNG_DHCP_COOKIE_STATUS_VLAN) /= 0
        and then Vid = Adapter.Mng_Vlan_Id
      then
         -- Release control to f/w.
         --
         standard.Devices.e1000e.NetDev.E1000e_Release_Hw_Control (Adapter'Access);
         return 0;
      end if;


      -- Remove VID from filter table.
      --
      if (Adapter.Flags and C.unsigned (FLAG_HAS_HW_VLAN_FILTER)) /= 0
      then
         Index := shift_Right (unsigned_32 (Vid), 5) and 16#7F#;
         Vfta  := E1000_READ_REG_ARRAY (Hw, E1000_VFTA, Index);
         Vfta  := Vfta and not Shift_Left (1, Natural (Vid and 16#1F#));

         Hw.Mac.Ops.Write_Vfta (Hw, Index, Vfta);
      end if;

      Clear_Bit (C.long (Vid), Adapter.Active_Vlans'Address);

      return 0;
   end E1000_Vlan_Rx_Kill_Vid;




   --------------------------------
   -- E1000e_Vlan_Filter_Disable --
   --------------------------------

   --  Helper to disable hw VLAN filtering.
   --
   --  * @adapter: Board private structure to initialize.


   procedure E1000e_Vlan_Filter_Disable
     (Adapter : access E1000_Adapter.item)
   is
      Netdev : constant access Net_Device := Adapter.Netdev;
      Hw     : constant access E1000_Hw   := Adapter.Hw'Access;
      Rctl   :                 Unsigned_32;
      Unused :                 C.int;
   begin
      if (Adapter.Flags and C.unsigned (FLAG_HAS_HW_VLAN_FILTER)) /= 0
      then
         -- Disable VLAN receive filtering.
         --
         Rctl := Er32 (Hw.all, E1000_RCTL);
         Rctl := Rctl and not (E1000_RCTL_VFE or E1000_RCTL_CFIEN);
         Ew32 (HW.all, E1000_RCTL, Rctl);

         if Adapter.Mng_Vlan_Id /= E1000_MNG_VLAN_NONE
         then
            Unused := E1000_Vlan_Rx_Kill_Vid (Netdev,
                                              u16 (Htons (ETH_P_8021Q).Value),
                                              Adapter.Mng_Vlan_Id);
            Adapter.Mng_Vlan_Id := E1000_MNG_VLAN_NONE;
         end if;
      end if;
   end E1000e_Vlan_Filter_Disable;




   -------------------------------
   -- E1000e_Vlan_Filter_Enable --
   -------------------------------

   --  Helper to enable HW VLAN filtering.
   --
   --  * @adapter: Board private structure to initialize.


   procedure E1000e_Vlan_Filter_Enable
     (Adapter : access E1000_Adapter.item)
   is
      Hw   : constant access E1000_Hw   := Adapter.Hw'Access;
      Rctl :                 Unsigned_32;

   begin
      if (Adapter.Flags and C.unsigned (FLAG_HAS_HW_VLAN_FILTER)) /= 0
      then
         -- Enable VLAN receive filtering.
         --
         Rctl := Er32 (Hw.all, E1000_RCTL);
         Rctl := Rctl or E1000_RCTL_VFE;
         Rctl := Rctl and (not E1000_RCTL_CFIEN);

         Ew32 (Hw.all, E1000_RCTL, Rctl);
      end if;
   end E1000e_Vlan_Filter_Enable;



   -------------------------------
   -- E1000e_Vlan_Strip_Disable --
   -------------------------------

   --  Helper to disable HW VLAN stripping.
   --
   --  * @adapter: Board private structure to initialize.


   procedure E1000e_Vlan_Strip_Disable
     (Adapter : access E1000_Adapter.item)
   is
      Hw   : constant access E1000_Hw   := Adapter.Hw'Access;
      Ctrl :                 Unsigned_32;

   begin
      -- Disable VLAN tag insert/strip.
      --
      Ctrl := Er32 (Hw.all, E1000_CTRL);
      Ctrl := Ctrl and (not E1000_CTRL_VME);
      Ew32 (Hw.all, E1000_CTRL, Ctrl);
   end E1000e_Vlan_Strip_Disable;



   ------------------------------
   -- E1000e_VLAN_Strip_Enable --
   ------------------------------

   --  Helper to enable HW VLAN stripping.
   --
   --  * @adapter: Board private structure to initialize.


   procedure E1000e_VLAN_Strip_Enable
     (Adapter : access E1000_Adapter.item)
   is
      HW   : constant access E1000_HW   := Adapter.HW'Access;
      Ctrl :                 Unsigned_32;

   begin
      -- Enable VLAN tag insert/strip.
      --
      Ctrl := ER32 (HW.all, E1000_CTRL);
      Ctrl := Ctrl or E1000_CTRL_VME;
      EW32 (HW.all, E1000_CTRL, Ctrl);
   end E1000e_VLAN_Strip_Enable;




   ---------------------------
   -- E1000_Update_Mng_Vlan --
   ---------------------------

   procedure E1000_Update_Mng_Vlan
     (Adapter : access E1000_Adapter.item)
   is
      Netdev  : constant access Net_Device  := Adapter.Netdev;
      Vid     : constant        Unsigned_16 := Adapter.Hw.Mng_Cookie.Vlan_Id;
      Old_Vid : constant        Unsigned_16 := Adapter.Mng_Vlan_Id;
      Unused  :                 C.int;

   begin
      if (Adapter.Hw.Mng_Cookie.Status and Devices.e1000e.Manage.E1000_MNG_DHCP_COOKIE_STATUS_VLAN) /= 0
      then
         Unused := e1000_vlan_rx_add_vid (Netdev,
                                          htons (ETH_P_8021Q).Value,
                                          Vid);
         Adapter.Mng_Vlan_Id := Vid;
      end if;

      if    Old_Vid /= E1000_MNG_VLAN_NONE
        and Vid     /= Old_Vid
      then
         Unused := e1000_vlan_rx_kill_vid (Netdev,
                                           htons (ETH_P_8021Q).Value,
                                           Old_Vid);
      end if;
   end E1000_Update_Mng_Vlan;



   ------------------------
   -- E1000_Restore_VLAN --
   ------------------------

   procedure E1000_Restore_VLAN
     (Adapter : access E1000_Adapter.item)
   is
      vid     : u16;
      Unused1 : u16;
      Unused2 : C.int;

   begin
      Unused1 := for_each_set_bit (vid,
                                   adapter.active_vlans'Address,
                                   VLAN_N_VID);
      -- TODO : The following function should be called for each bit set, as per the above 'loop' macro.
         Unused2 := E1000_VLAN_RX_Add_VID (Adapter.Netdev,
                                           htons (ETH_P_8021Q).Value,
                                           vid);
   end E1000_Restore_VLAN;




   ---------------------------------
   -- E1000_Init_Manageability_Pt --
   ---------------------------------

   procedure E1000_Init_Manageability_Pt
     (Adapter : access E1000_Adapter.item)
   is
      HW     : constant access E1000_HW   := Adapter.HW'Access;
      Manc   :                 Unsigned_32;
      Manc2h :                 Unsigned_32;
      Mdef   :                 Unsigned_32;
      I, J   :                 u32;

   begin
      if not ((Adapter.Flags and C.unsigned (FLAG_MNG_PT_ENABLED)) /= 0)
      then
         return;
      end if;


      Manc := Er32 (Hw.all, E1000_MANC);

      -- Enable receiving management packets to the host. This will probably
      -- generate destination unreachable messages from the host OS, but
      -- the packets will be handled on SMBUS.
      --
      Manc   := Manc or E1000_MANC_EN_MNG2HOST;
      Manc2h := Er32 (Hw.all, E1000_MANC2H);

      case HW.Mac.Mac_Type
      is
         when E1000_82574
            | E1000_82583 =>

            -- Check if IPMI pass-through decision filter already exists;
            -- if so, enable it.
            --
            I := 0;
            J := 0;

            while I < 8
            loop
               Mdef := Er32 (Hw.all, E1000_MDEF (C.unsigned_long (I)));

               -- Ignore filters with anything other than IPMI ports.
               --
               if (         Mdef
                   and not (E1000_MDEF_PORT_623 or E1000_MDEF_PORT_664)) = 0
               then
                  -- Enable this decision filter in MANC2H.
                  --
                  if Mdef /= 0
                  then
                     Manc2h := Manc2h or BIT (Natural (I));
                  end if;

                  J := J or Mdef;
               end if;

               I := I + 1;
            end loop;


            if J = (E1000_MDEF_PORT_623 or E1000_MDEF_PORT_664)
            then
               goto End_Of_Case;
            end if;

            -- Create new decision filter in an empty filter.
            --
            I := 0;
            J := 0;

            while I < 8
            loop
               if Er32 (Hw.all, E1000_MDEF (C.unsigned_long (I))) = 0
               then
                  Ew32 (Hw.all, E1000_MDEF (C.unsigned_long (I)),
                        E1000_MDEF_PORT_623 or E1000_MDEF_PORT_664);
                  Manc2h := Manc2h or BIT (1);                               -- TODO: This is what the C code does but 'BIT (1)' looks odd. Check it.
                  J      := J + 1;
                  exit;
               end if;

               I := I + 1;
            end loop;

            if J = 0
            then
               e_warn ("Unable to create IPMI pass-through filter");
            end if;


         when others =>
            Manc2h := Manc2h or (E1000_MANC2H_PORT_623 or E1000_MANC2H_PORT_664);
      end case;


      <<End_Of_Case>>

      Ew32 (Hw.all, E1000_MANC2H, Manc2h);
      Ew32 (Hw.all, E1000_MANC,   Manc);
   end E1000_Init_Manageability_Pt;




   ------------------------
   -- E1000_Configure_Tx --
   ------------------------

   --  Configure Transmit Unit after Reset.
   --
   --  * @adapter: Board private structure.
   --  *
   --  * Configure the Tx unit of the MAC after a reset.


   procedure E1000_Configure_Tx
     (Adapter : access E1000_Adapter.item)
   is
      use Interfaces.C;
      use System,
          system.Storage_Elements;

      Hw      : constant access E1000_Hw        := Adapter.Hw'Access;
      Tx_Ring : constant access E1000_Ring.item := Adapter.Tx_Ring;
      Tdba    :                 Unsigned_64;
      Tdlen,
      Tctl,
      Tarc    :                 Unsigned_32;

   begin
      -- Setup the HW Tx Head and Tail descriptor pointers.
      --
      Tdba  := Tx_Ring.Dma;
      Tdlen := Unsigned_32 (Tx_Ring.Count * E1000_Tx_Desc.item'Size / 8);

      Ew32 (Hw.all, C.unsigned_long (E1000_TDBAL (0)), Unsigned_32 (Tdba and 16#FFFFFFFF#));
      Ew32 (Hw.all, C.unsigned_long (E1000_TDBAH (0)), Unsigned_32 (shift_Right (Tdba, 32)));
      Ew32 (Hw.all, E1000_TDLEN (0), Tdlen);
      Ew32 (Hw.all, C.unsigned_long (E1000_TDH   (0)), 0);
      Ew32 (Hw.all, E1000_TDT   (0), 0);

      Tx_Ring.Head := Adapter.Hw.Hw_Addr + storage_Offset (E1000_TDH (0));
      Tx_Ring.Tail := Adapter.Hw.Hw_Addr + storage_Offset (E1000_TDT (0));

      writeL (0, Tx_Ring.Head);

      if (Adapter.Flags2 and C.unsigned (FLAG2_PCIM2PCI_ARBITER_WA)) /= 0
      then
         E1000e_Update_Tdt_Wa (Tx_Ring, 0);
      else
         writeL (0, Tx_Ring.Tail);
      end if;

      -- Set the Tx Interrupt Delay register.
      --
      Ew32 (Hw.all, E1000_TIDV, Adapter.Tx_Int_Delay);

      -- Tx irq moderation.
      --
      Ew32 (Hw.all, E1000_TADV, Adapter.Tx_Abs_Int_Delay);

      if (Adapter.Flags2 and C.unsigned (FLAG2_DMA_BURST)) /= 0
      then
         declare
            Txdctl : Unsigned_32 := Er32 (Hw.all, E1000_TXDCTL (0));
         begin
            Txdctl := Txdctl and not (   E1000_TXDCTL_PTHRESH
                                      or E1000_TXDCTL_HTHRESH
                                      or E1000_TXDCTL_WTHRESH);

            -- Set up some performance related parameters to encourage the
            -- hardware to use the bus more efficiently in bursts, depends
            -- on the tx_int_delay to be enabled.
            --
            -- wthresh =    1 ==> burst write is disabled to avoid Tx stalls.
            -- hthresh =    1 ==> prefetch when one or more available.
            -- pthresh = 0x1f ==> prefetch if internal cache 31 or less.
            --
            -- BEWARE: this seems to work but should be considered first if
            --         there are Tx hangs or other Tx related bugs.
            --
            Txdctl := Txdctl or E1000_TXDCTL_DMA_BURST_ENABLE;

            Ew32 (Hw.all, E1000_TXDCTL (0), Txdctl);
         end;
      end if;

      -- Erratum work around: set txdctl the same for both queues.
      --
      Ew32 (Hw.all, E1000_TXDCTL (1), Er32 (Hw.all, E1000_TXDCTL (0)));

      -- Program the Transmit Control Register.
      --
      Tctl := Er32 (Hw.all, E1000_TCTL);
      Tctl := Tctl and not  E1000_TCTL_CT;
      Tctl := Tctl or E1000_TCTL_PSP
                   or E1000_TCTL_RTLC
                   or shift_Left (E1000_COLLISION_THRESHOLD, E1000_CT_SHIFT);

      if (Adapter.Flags and C.unsigned (FLAG_TARC_SPEED_MODE_BIT)) /= 0
      then
         Tarc := Er32 (Hw.all, E1000_TARC (0));

         -- Set the speed mode bit, we'll clear it if we're not at gigabit link later.
         --
         Tarc := Tarc or SPEED_MODE_BIT;
         Ew32 (Hw.all, E1000_TARC (0), Tarc);
      end if;

      -- Errata: program both queues to unweighted RR.
      --
      if (Adapter.Flags and C.unsigned (FLAG_TARC_SET_BIT_ZERO)) /= 0
      then
         Tarc := Er32 (Hw.all, E1000_TARC (0));
         Tarc := Tarc or 1;
         Ew32 (Hw.all, E1000_TARC (0), Tarc);

         Tarc := Er32 (Hw.all, E1000_TARC (1));
         Tarc := Tarc or 1;
         Ew32 (Hw.all, E1000_TARC (1), Tarc);
      end if;

      -- Setup Transmit Descriptor Settings for eop descriptor.
      --
      Adapter.Txd_Cmd := E1000_TXD_CMD_EOP or E1000_TXD_CMD_IFCS;

      -- Only set IDE if we are delaying interrupts using the timers.
      --
      if Adapter.Tx_Int_Delay /= 0
      then
         Adapter.Txd_Cmd := Adapter.Txd_Cmd or E1000_TXD_CMD_IDE;
      end if;

      -- Enable Report Status bit.
      --
      Adapter.Txd_Cmd := Adapter.Txd_Cmd or E1000_TXD_CMD_RS;

      Ew32 (Hw.all, E1000_TCTL, Tctl);

      Hw.Mac.Ops.Config_Collision_Dist (Hw);

      -- SPT and KBL Si errata workaround to avoid data corruption.
      --
      if Hw.Mac.Mac_Type = E1000_Pch_Spt
      then
         declare
            use Devices.e1000e.Ich8Lan;
            Reg_Val : Unsigned_32;
         begin
            Reg_Val := Er32 (Hw.all, E1000_IOSFPC);
            Reg_Val := Reg_Val or E1000_RCTL_RDMTS_HEX;
            Ew32 (Hw.all, E1000_IOSFPC, Reg_Val);

            Reg_Val := Er32 (Hw.all, E1000_TARC (0));

            -- SPT and KBL Si errata workaround to avoid Tx hang.
            -- Dropping the number of outstanding requests from
            -- 3 to 2 in order to avoid a buffer overrun.
            --
            Reg_Val := Reg_Val and not E1000_TARC0_CB_MULTIQ_3_REQ;
            Reg_Val := Reg_Val or E1000_TARC0_CB_MULTIQ_2_REQ;
            Ew32 (Hw.all, E1000_TARC (0), Reg_Val);
         end;
      end if;
   end E1000_Configure_Tx;





   function Page_Use_Count
     (S : u32) return u32
   is
   begin
      return   shift_Right (S, PAGE_SHIFT)
             + (if (S and (PAGE_SIZE - 1)) /= 0 then 1
                                                else 0);
   end Page_Use_Count;




   ----------------------
   -- E1000_Setup_RCTL --
   ----------------------

   --  Configure the receive control registers.
   --
   --  * @adapter: Board private structure.


   procedure E1000_Setup_RCTL
     (Adapter : access E1000_Adapter.item)
   is
      Hw     : constant access E1000_HW   := Adapter.HW'Access;
      RCTL,
      RFCTL  :                 Unsigned_32;
      Pages  :                 u32        := 0;
      Netdev : constant access Net_Device := Adapter.Netdev;

   begin
      -- Workaround Si errata on PCHx - configure jumbo frame flow.
      -- If jumbo frames not set, program related MAC/PHY registers
      -- to h/w defaults.
      --
      if Hw.Mac.Mac_Type >= E1000_PCH2LAN
      then
         declare
            Ret_Val : s32;
         begin
            if Netdev.MTU > ETH_DATA_LEN
            then
               Ret_Val := Devices.e1000e.Ich8Lan.E1000_LV_Jumbo_Workaround_ICH8LAN (HW, True);
            else
               Ret_Val := Devices.e1000e.Ich8Lan.E1000_LV_Jumbo_Workaround_ICH8LAN (HW, False);
            end if;

            if Ret_Val /= 0
            then
               e_dbg ("failed to enable|disable jumbo frame workaround mode");
            end if;
         end;
      end if;


      -- Program MC offset vector base.
      --
      RCTL := ER32 (Hw.all, E1000_RCTL);
      RCTL := RCTL and not Shift_Left (3, E1000_RCTL_MO_SHIFT);
      RCTL := RCTL or E1000_RCTL_EN     or E1000_RCTL_BAM
                   or E1000_RCTL_LBM_NO or E1000_RCTL_RDMTS_HALF
                   or shift_Left (Unsigned_32 (HW.Mac.MC_Filter_Type),
                                  E1000_RCTL_MO_SHIFT);

      -- Do not Store bad packets.
      --
      RCTL := RCTL and not E1000_RCTL_SBP;

      -- Enable Long Packet receive.
      --
      if Netdev.MTU <= ETH_DATA_LEN
      then
         RCTL := RCTL and not E1000_RCTL_LPE;
      else
         RCTL := RCTL or E1000_RCTL_LPE;
      end if;

      -- Some systems expect that the CRC is included in SMBUS traffic. The
      -- hardware strips the CRC before sending to both SMBUS (BMC) and to
      -- host memory when this is enabled.
      --
      if (Adapter.Flags2 and C.unsigned (FLAG2_CRC_STRIPPING)) /= 0
      then
         RCTL := RCTL or E1000_RCTL_SECRC;
      end if;

      -- Workaround Si errata on 82577 PHY - configure IPG for jumbos.
      --
      if    HW.Phy.Phy_Type = E1000_PHY_82577
        and (RCTL and E1000_RCTL_LPE) /= 0
      then
         declare
            Phy_Data : aliased Unsigned_16;
            Unused   :         s32;
         begin
            Unused := E1E_RPHY (HW, Devices.e1000e.Ich8Lan.PHY_REG (770, 26), Phy_Data'unchecked_Access);
            Phy_Data := Phy_Data and 16#FFF8#;
            Phy_Data := Phy_Data or BIT (2);
            E1E_WPHY (HW, Devices.e1000e.Ich8Lan.PHY_REG (770, 26), Phy_Data);

            Unused := E1E_RPHY (HW, 22, Phy_Data'unchecked_Access);
            Phy_Data := Phy_Data and 16#0FFF#;
            Phy_Data := Phy_Data or BIT (14);
            E1E_WPHY (HW, 16#10#, 16#2823#);
            E1E_WPHY (HW, 16#11#, 16#0003#);
            E1E_WPHY (HW, 22, Phy_Data);
         end;
      end if;

      -- Setup buffer sizes.
      --
      RCTL := RCTL and not E1000_RCTL_SZ_4096;
      RCTL := RCTL or E1000_RCTL_BSEX;

      case Adapter.RX_Buffer_Len
      is
         when 2048 =>
            RCTL := RCTL or E1000_RCTL_SZ_2048;
            RCTL := RCTL and not E1000_RCTL_BSEX;

         when 4096 =>
            RCTL := RCTL or E1000_RCTL_SZ_4096;

         when 8192 =>
            RCTL := RCTL or E1000_RCTL_SZ_8192;

         when 16384 =>
            RCTL := RCTL or E1000_RCTL_SZ_16384;

         when others =>
            RCTL := RCTL or E1000_RCTL_SZ_2048;
            RCTL := RCTL and not E1000_RCTL_BSEX;
      end case;

      -- Enable Extended Status in all Receive Descriptors.
      --
      RFCTL := ER32 (Hw.all, E1000_RFCTL);
      RFCTL := RFCTL or E1000_RFCTL_EXTEN;
      EW32 (Hw.all, E1000_RFCTL, RFCTL);

      -- 82571 and greater support packet-split where the protocol
      -- header is placed in skb->data and the packet data is
      -- placed in pages hanging off of skb_shinfo(skb)->nr_frags.
      -- In the case of a non-split, skb->data is linearly filled,
      -- followed by the page buffers.  Therefore, skb->data is
      -- sized to hold the largest protocol header.
      --
      -- allocations using alloc_page take too long for regular MTU
      -- so only enable packet split for jumbo frames
      --
      -- Using pages when the page size is greater than 16k wastes
      -- a lot of memory, since we allocate 3 pages at all times
      -- per packet.
      --
      Pages := PAGE_USE_COUNT (u32 (Netdev.MTU));

      if    Pages     <= 3
        and PAGE_SIZE <= 16384
        and (RCTL and E1000_RCTL_LPE) /= 0
      then
         Adapter.RX_PS_Pages := C.unsigned (Pages);
      else
         Adapter.RX_PS_Pages := 0;
      end if;


      if Adapter.RX_PS_Pages /= 0
      then
         declare
            PSRCTL : Unsigned_32 := 0;
         begin
            -- Enable Packet split descriptors.
            --
            RCTL   := RCTL   or E1000_RCTL_DTYP_PS;
            PSRCTL := PSRCTL or u32 (shift_Right (Adapter.RX_PS_BSize0,
                                                  E1000_PSRCTL_BSIZE0_SHIFT));
            case Adapter.RX_PS_Pages
            is
               when 3 =>
                  PSRCTL := PSRCTL or Shift_Left  (PAGE_SIZE, E1000_PSRCTL_BSIZE3_SHIFT);
                  PSRCTL := PSRCTL or Shift_Left  (PAGE_SIZE, E1000_PSRCTL_BSIZE2_SHIFT);
                  PSRCTL := PSRCTL or Shift_Right (PAGE_SIZE, E1000_PSRCTL_BSIZE1_SHIFT);

               when 2 =>
                  PSRCTL := PSRCTL or Shift_Left  (PAGE_SIZE, E1000_PSRCTL_BSIZE2_SHIFT);
                  PSRCTL := PSRCTL or Shift_Right (PAGE_SIZE, E1000_PSRCTL_BSIZE1_SHIFT);

               when 1 =>
                  PSRCTL := PSRCTL or Shift_Right (PAGE_SIZE, E1000_PSRCTL_BSIZE1_SHIFT);

               when others =>
                  null;
            end case;

            EW32 (Hw.all, E1000_PSRCTL, PSRCTL);
         end;
      end if;


      -- This is useful for sniffing bad packets.
      --
      if (Netdev.Features and NETIF_F_RXALL) /= 0
      then
         -- UPE and MPE will be handled by normal PROMISC logic
         -- in e1000e_set_rx_mode.
         --
         RCTL := RCTL or (   E1000_RCTL_SBP                -- Receive bad packets.
                          or E1000_RCTL_BAM                -- RX All Bcast Pkts.
                          or E1000_RCTL_PMCF);             -- RX All MAC Ctrl Pkts.

         RCTL := RCTL and not (   E1000_RCTL_VFE           -- Disable VLAN filter.
                               or E1000_RCTL_DPF           -- Allow filtered pause.
                               or E1000_RCTL_CFIEN);       -- Dis VLAN CFIEN Filter.

         -- Do not mess with E1000_CTRL_VME, it affects transmit as well,
         -- and that breaks VLANs.
      end if;

      EW32 (Hw.all, E1000_RCTL, RCTL);

      -- Just started the receive unit, no need to restart.
      --
      Adapter.Flags := Adapter.Flags and not C.unsigned (FLAG_RESTART_NOW);
   end E1000_Setup_RCTL;




   ------------------------
   -- E1000_Configure_Rx --
   ------------------------

   --    Configure Receive Unit after Reset.
   --
   --  * @adapter: Board private structure.
   --  *
   --  * Configure the Rx unit of the MAC after a reset.


   procedure E1000_Configure_Rx
     (Adapter : access E1000_Adapter.item)
   is
      use system.Storage_Elements;

      Hw       : constant access E1000_Hw        := Adapter.Hw'Access;
      Rx_Ring  : constant access E1000_Ring.item := Adapter.Rx_Ring;
      Rdba     :                 Unsigned_64;
      Rdlen,
      Rctl,
      Rxcsum,
      Ctrl_Ext :                 Unsigned_32;
      Netdev   : constant access Net_Device := Adapter.Netdev;

   begin
      if Adapter.Rx_Ps_Pages /= 0
      then
         -- This is a 32 byte descriptor.
         --
         Rdlen                := Unsigned_32 (Rx_Ring.Count * E1000_Rx_Desc_Packet_Split.item'Size / 8);
         Adapter.Clean_Rx     := E1000_Clean_Rx_Irq_Ps    'Access;
         Adapter.Alloc_Rx_Buf := E1000_Alloc_Rx_Buffers_Ps'Access;

      elsif Netdev.Mtu > ETH_FRAME_LEN + ETH_FCS_LEN
      then
         Rdlen                := Unsigned_32 (Rx_Ring.Count * E1000_Rx_Desc_Extended.item'Size / 8);
         Adapter.Clean_Rx     := E1000_Clean_Jumbo_Rx_Irq    'Access;
         Adapter.Alloc_Rx_Buf := E1000_Alloc_Jumbo_Rx_Buffers'Access;

      else
         Rdlen                := Interfaces.Unsigned_32 (Rx_Ring.Count * E1000_Rx_Desc_Extended.item'Size / 8);
         Adapter.Clean_Rx     := E1000_Clean_Rx_Irq    'Access;
         Adapter.Alloc_Rx_Buf := E1000_Alloc_Rx_Buffers'Access;
      end if;


      -- Disable receives while setting up the descriptors.
      --
      Rctl := Er32 (Hw.all, E1000_RCTL);

      if (Adapter.Flags2 and C.unsigned (FLAG2_NO_DISABLE_RX)) = 0
      then
         Ew32 (Hw.all, E1000_RCTL, Rctl and not E1000_RCTL_EN);
      end if;

      E1e_Flush (Hw);
      delay 0.015;      -- Equivalent to usleep_range(10000, 11000)

      if (Adapter.Flags2 and C.unsigned (FLAG2_DMA_BURST)) /= 0
      then
         -- Set the writeback threshold (only takes effect if the RDTR
         -- is set). set GRAN=1 and write back up to 0x4 worth, and
         -- enable prefetching of 0x20 Rx descriptors:
         --
         -- granularity = 01
         -- wthresh     = 04,
         -- hthresh     = 04,
         -- pthresh     = 0x20
         --
         Ew32 (Hw.all, E1000_RXDCTL (0), E1000_RXDCTL_DMA_BURST_ENABLE);
         Ew32 (Hw.all, E1000_RXDCTL (1), E1000_RXDCTL_DMA_BURST_ENABLE);
      end if;

      -- Set the Receive Delay Timer Register.
      --
      Ew32 (Hw.all, E1000_RDTR, Adapter.Rx_Int_Delay);

      -- IRQ moderation.
      --
      Ew32 (Hw.all, E1000_RADV, Adapter.Rx_Abs_Int_Delay);

      if    Adapter.Itr_Setting /= 0
        and Adapter.Itr         /= 0
      then
         E1000e_Write_Itr (Adapter, Adapter.Itr);
      end if;

      Ctrl_Ext := Er32 (Hw.all, E1000_CTRL_EXT);

      -- Auto-Mask interrupts upon ICR access.
      --
      Ctrl_Ext := Ctrl_Ext or E1000_CTRL_EXT_IAME;
      Ew32 (Hw.all, E1000_IAM, 16#ffffffff#);
      Ew32 (Hw.all, E1000_CTRL_EXT, Ctrl_Ext);
      E1e_Flush (Hw);

      -- Setup the HW Rx Head and Tail Descriptor Pointers and
      -- the Base and Length of the Rx Descriptor Ring.
      --
      Rdba := Rx_Ring.Dma;
      Ew32 (Hw.all, C.unsigned_long (E1000_RDBAL (0)), Interfaces.Unsigned_32 (Rdba and 16#ffffffff#));
      Ew32 (Hw.all, C.unsigned_long (E1000_RDBAH (0)), Interfaces.Unsigned_32 (Shift_Right (Rdba, 32)));
      Ew32 (Hw.all, C.unsigned_long (E1000_RDLEN (0)), Rdlen);
      Ew32 (Hw.all, C.unsigned_long (E1000_RDH   (0)), 0);
      Ew32 (Hw.all, C.unsigned_long (E1000_RDT   (0)), 0);

      Rx_Ring.Head := Adapter.Hw.Hw_Addr + storage_Offset (E1000_RDH (0));
      Rx_Ring.Tail := Adapter.Hw.Hw_Addr + storage_Offset (E1000_RDT (0));

      writeL (0, Rx_Ring.Head);

      if (Adapter.Flags2 and C.unsigned (FLAG2_PCIM2PCI_ARBITER_WA)) /= 0
      then
         E1000e_Update_Rdt_Wa (Rx_Ring, 0);
      else
         writeL (0, Rx_Ring.Tail);
      end if;

      -- Enable Receive Checksum Offload for TCP and UDP.
      --
      Rxcsum := Er32 (Hw.all, E1000_RXCSUM);

      if (Netdev.Features and NETIF_F_RXCSUM) /= 0
      then
         Rxcsum := Rxcsum or E1000_RXCSUM_TUOFL;
      else
         Rxcsum := Rxcsum and not E1000_RXCSUM_TUOFL;
      end if;

      Ew32 (Hw.all, E1000_RXCSUM, Rxcsum);

      -- With jumbo frames, excessive C-state transition latencies result
      -- in dropped transactions.
      --
      if Netdev.Mtu > ETH_DATA_LEN
      then
         declare
            Lat : constant Unsigned_32 :=   ((Er32 (Hw.all, E1000_PBA) and E1000_PBA_RXA_MASK) * 1024 - Adapter.Max_Frame_Size)
                                          * 8 / 1000;
         begin
            if (Adapter.Flags and C.unsigned (FLAG_IS_ICH)) /= 0
            then
               declare
                  Rxdctl : constant Unsigned_32 := Er32 (Hw.all, E1000_RXDCTL (0));
               begin
                  Ew32 (Hw.all, E1000_RXDCTL (0), Rxdctl or 16#0000_0103#);
               end;
            end if;

            dev_info (adapter.pdev.dev'Access,
                      "Some CPU C-states have been disabled in order to enable jumbo frames");
            Cpu_Latency_Qos_Update_Request (Adapter.Pm_Qos_Req'Access, s32 (Lat));
         end;
      else
         Cpu_Latency_Qos_Update_Request (Adapter.Pm_Qos_Req'Access, PM_QOS_DEFAULT_VALUE);
      end if;

      -- Enable Receives.
      --
      Ew32 (Hw.all, E1000_RCTL, Rctl);
   end E1000_Configure_Rx;




   -------------------------------
   -- E1000e_Write_Mc_Addr_List --
   -------------------------------

   --    Write multicast addresses to MTA.
   --
   --  * @netdev: Network interface device structure.
   --  *
   --  * Writes multicast address list to the MTA hash table.
   --  * Returns: -ENOMEM on failure
   --  *                0 on no addresses written
   --  *                X on writing X addresses to MTA

   package u8_Conversions is new system.Address_To_Access_Conversions (u8);


   function E1000e_Write_Mc_Addr_List
     (Netdev : access net_device) return Integer
   is
      use Devices.e1000e.Core.Pointers,
          u8_Conversions;

      use type u8_Pointer;

      Adapter : E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev);

      Hw       : constant access E1000_Hw  := Adapter.Hw'Access;
      Mta_List :                 u8_Pointer;
      I        :                 u32       := 0;

   begin
      if Netdev_Mc_Empty (Netdev)
      then
         -- Nothing to program, so clear mc list.
         --
         Hw.Mac.Ops.Update_Mc_Addr_List (Hw, null, 0);
         return 0;
      end if;


      Mta_List := u8_Pointer (to_Pointer (kcalloc (netdev_mc_count (netdev),
                                                   ETH_ALEN,
                                                   GFP_ATOMIC)));

      if Mta_List = null
      then
         return -ENOMEM;
      end if;


      -- Update_mc_addr_list expects a packed array of only addresses.     -- TODO
      --
    --  i = 0;
    --
    --    netdev_for_each_mc_addr(ha, netdev)
    --       memcpy(mta_list + (i++ * ETH_ALEN), ha->addr, ETH_ALEN);


      Hw.Mac.Ops.Update_Mc_Addr_List (Hw, Mta_List, I);
      Kfree (Mta_List.all'Address);                                        -- TODO: Check this.

      return Netdev_Mc_Count (Netdev);
   end E1000e_Write_Mc_Addr_List;




   -------------------------------
   -- E1000e_Write_Uc_Addr_List --
   -------------------------------

   --  Write unicast addresses to RAR table.
   --
   --  * @netdev: Network interface device structure.
   --  *
   --  * Writes unicast address list to the RAR table.
   --  * Returns: -ENOMEM on failure/insufficient address space
   --  *                0 on no addresses written
   --  *                X on writing X addresses to the RAR table


   function E1000e_Write_Uc_Addr_List
     (Netdev : access Net_Device) return Integer
   is
      Adapter : E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev);

      Hw          : constant access E1000_Hw := Adapter.Hw'Access;
      Count       : constant        Integer  := 0;
      Rar_Entries :                 u32;

   begin
      Rar_Entries := Hw.Mac.Ops.Rar_Get_Count (Hw);

      -- Save a rar entry for our hardware address.
      --
      Rar_Entries := Rar_Entries - 1;

      -- Save a rar entry for the LAA workaround.
      --
      if (Adapter.Flags and C.unsigned (FLAG_RESET_OVERWRITES_LAA)) /= 0
      then
         Rar_Entries := Rar_Entries - 1;
      end if;

      -- Return ENOMEM indicating insufficient memory for addresses.
      --
      if netdev_uc_count (Netdev) > Rar_Entries
      then
         return -ENOMEM;
      end if;


      if    not netdev_uc_empty (Netdev)
        and     Rar_Entries > 0
      then
         -- Write the addresses in reverse order to avoid write combining.
         --

         null;     -- TODO

         --  {
         --     struct netdev_hw_addr *ha;
         --
         --
         --     netdev_for_each_uc_addr (ha, netdev)
         --     {
         --         int ret_val;
         --
         --         if (!rar_entries)
         --            break;
         --
         --         ret_val = hw->mac.ops.rar_set (hw, ha->addr, rar_entries--);
         --
         --         if (ret_val < 0)
         --            return -ENOMEM;
         --
         --         count++;
         --     }
         --  }
      end if;


      -- Zero out the remaining RAR entries not used above.
      --
      for i in reverse 1 .. Rar_Entries
      loop
         Ew32 (Hw.all, E1000_RAH (i), 0);
         Ew32 (Hw.all, E1000_RAL (i), 0);
      end loop;

      E1e_Flush (Hw);

      return Count;
   end E1000e_Write_Uc_Addr_List;




   ------------------------
   -- E1000e_Set_Rx_Mode --
   ------------------------

   --    Secondary unicast, Multicast and Promiscuous mode set.
   --
   --  * @netdev: Network interface device structure.
   --  *
   --  * The ndo_set_rx_mode entry point is called whenever the unicast or multicast
   --  * address list or the network interface flags are updated.  This routine is
   --  * responsible for configuring the hardware for proper unicast, multicast,
   --  * promiscuous mode, and all-multi behavior.


   procedure E1000e_Set_Rx_Mode
     (Netdev : access Net_Device)
   is
      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev);

      HW   : constant access E1000_HW   := Adapter.HW'Access;
      RCTL :                 Unsigned_32;

   begin
      if PM_Runtime_Suspended (Netdev.Dev.Parent)
      then
         return;
      end if;


      -- Check for Promiscuous and All Multicast modes.
      --
      RCTL := ER32 (Hw.all, E1000_RCTL);

      -- Clear the affected bits.
      --
      RCTL := RCTL and not (E1000_RCTL_UPE or E1000_RCTL_MPE);


      if (Netdev.Flags and C.unsigned (IFF_PROMISC)) /= 0
      then
         RCTL := RCTL or (E1000_RCTL_UPE or E1000_RCTL_MPE);
         E1000e_VLAN_Filter_Disable (Adapter'Access);     -- Do not hardware filter VLANs in promisc mode.

      else
         declare
            Count : Integer;
         begin
            if (Netdev.Flags and C.unsigned (IFF_ALLMULTI)) /= 0
            then
               RCTL := RCTL or E1000_RCTL_MPE;
            else
               -- Write addresses to the MTA, if the attempt fails
               -- then we should just turn on promiscuous mode so
               -- that we can at least receive multicast traffic.
               --
               Count := E1000e_Write_MC_Addr_List (Netdev);

               if Count < 0
               then
                  RCTL := RCTL or E1000_RCTL_MPE;
               end if;
            end if;

            E1000e_VLAN_Filter_Enable (Adapter'Access);

            -- Write addresses to available RAR registers, if there is not
            -- sufficient space to store all the addresses then enable
            -- unicast promiscuous mode.
            --
            Count := E1000e_Write_UC_Addr_List (Netdev);

            if Count < 0
            then
               RCTL := RCTL or E1000_RCTL_UPE;
            end if;
         end;
      end if;


      EW32 (Hw.all, E1000_RCTL, RCTL);

      if (Netdev.Features and NETIF_F_HW_VLAN_CTAG_RX) /= 0
      then
         E1000e_VLAN_Strip_Enable  (Adapter'Access);
      else
         E1000e_VLAN_Strip_Disable (Adapter'Access);
      end if;
   end E1000e_Set_Rx_Mode;




   ---------------------------
   -- E1000e_Setup_RSS_Hash --
   ---------------------------

   procedure E1000e_Setup_RSS_Hash
     (Adapter : access E1000_Adapter.item)
   is
      HW      : constant access E1000_HW   := Adapter.HW'Access;
      MRQC    :                 Unsigned_32;
      RXCSUM  :                 Unsigned_32;
      RSS_Key :                 array (0 .. 9) of Unsigned_32;

   begin
      Netdev_RSS_Key_Fill (RSS_Key'Address, RSS_Key'Size / 8);

      for i in RSS_Key'Range
      loop
         EW32 (Hw.all,
               E1000_RSSRK (i),
               RSS_Key     (i));
      end loop;

      -- Direct all traffic to queue 0.
      --
      for i in 0 .. 31
      loop
         EW32 (Hw.all, E1000_RETA (i), 0);
      end loop;

      -- Disable raw packet checksumming so that RSS hash is placed in
      -- descriptor on writeback.
      --
      RXCSUM := ER32 (Hw.all, E1000_RXCSUM);
      RXCSUM := RXCSUM or E1000_RXCSUM_PCSD;

      EW32 (Hw.all, E1000_RXCSUM, RXCSUM);

      MRQC :=    E1000_MRQC_RSS_FIELD_IPV4
              or E1000_MRQC_RSS_FIELD_IPV4_TCP
              or E1000_MRQC_RSS_FIELD_IPV6
              or E1000_MRQC_RSS_FIELD_IPV6_TCP
              or E1000_MRQC_RSS_FIELD_IPV6_TCP_EX;

      EW32 (Hw.all, E1000_MRQC, MRQC);
   end E1000e_Setup_RSS_Hash;



   -----------------------------
   -- E1000e_Get_Base_Timinca --
   -----------------------------

   --    Get default SYSTIM time increment attributes.
   --
   --  * @adapter: Board private structure.
   --  * @timinca: Pointer to returned time increment attributes.
   --  *
   --  * Get attributes for incrementing the System Time Register SYSTIML/H at
   --  * the default base frequency, and set the cyclecounter shift value.


   function E1000e_Get_Base_Timinca
     (Adapter : access E1000_Adapter.item;
      Timinca : access Unsigned_32) return s32
   is
      Hw       : constant access E1000_Hw := Adapter.Hw'Access;
      Incvalue,
      Incperiod,
      Shift    :                 Unsigned_32;

   begin
      -- Make sure clock is enabled on I217/I218/I219 before checking the frequency.
      --
      if          Hw.Mac.Mac_Type >= E1000_Pch_Lpt
        and then (Er32 (Hw.all, E1000_TSYNCTXCTL) and E1000_TSYNCTXCTL_ENABLED) = 0
        and then (Er32 (Hw.all, E1000_TSYNCRXCTL) and E1000_TSYNCRXCTL_ENABLED) = 0
      then
         declare
            Fextnvm7 : constant Unsigned_32 := Er32 (Hw.all, E1000_FEXTNVM7);
         begin
            if (Fextnvm7 and BIT (0)) = 0
            then
               Ew32 (Hw.all, E1000_FEXTNVM7, Fextnvm7 or BIT (0));
               E1e_Flush (Hw);
            end if;
         end;
      end if;


      case Hw.Mac.Mac_Type
      is
         when E1000_Pch2lan =>
            -- Stable 96MHz frequency.
            --
            Incperiod        := INCPERIOD_96MHZ;
            Incvalue         := INCVALUE_96MHZ;
            Shift            := INCVALUE_SHIFT_96MHZ;
            Adapter.Cc.Shift := Shift + INCPERIOD_SHIFT_96MHZ;

         when E1000_Pch_Lpt =>
            if (Er32 (Hw.all, E1000_TSYNCRXCTL) and E1000_TSYNCRXCTL_SYSCFI) /= 0
            then
               -- Stable 96MHz frequency.
               --
               Incperiod        := INCPERIOD_96MHZ;
               Incvalue         := INCVALUE_96MHZ;
               Shift            := INCVALUE_SHIFT_96MHZ;
               Adapter.Cc.Shift := Shift + INCPERIOD_SHIFT_96MHZ;
            else
               -- Stable 25MHz frequency.
               --
               Incperiod        := INCPERIOD_25MHZ;
               Incvalue         := INCVALUE_25MHZ;
               Shift            := INCVALUE_SHIFT_25MHZ;
               Adapter.Cc.Shift := Shift;
            end if;

         when E1000_Pch_Spt =>
            -- Stable 24MHz frequency.
            --
            Incperiod        := INCPERIOD_24MHZ;
            Incvalue         := INCVALUE_24MHZ;
            Shift            := INCVALUE_SHIFT_24MHZ;
            Adapter.Cc.Shift := Shift;

         when E1000_Pch_Cnp
            | E1000_Pch_Tgp
            | E1000_Pch_Adp
            | E1000_Pch_Mtp
            | E1000_Pch_Lnp
            | E1000_Pch_Ptp
            | E1000_Pch_Nvp =>

            if (Er32 (Hw.all, E1000_TSYNCRXCTL) and E1000_TSYNCRXCTL_SYSCFI) /= 0
            then
               -- Stable 24MHz frequency.
               --
               Incperiod        := INCPERIOD_24MHZ;
               Incvalue         := INCVALUE_24MHZ;
               Shift            := INCVALUE_SHIFT_24MHZ;
               Adapter.Cc.Shift := Shift;
            else
               -- Stable 38400KHz frequency.
               --
               Incperiod        := INCPERIOD_38400KHZ;
               Incvalue         := INCVALUE_38400KHZ;
               Shift            := INCVALUE_SHIFT_38400KHZ;
               Adapter.Cc.Shift := Shift;
            end if;

         when E1000_82574
            | E1000_82583 =>
            -- Stable 25MHz frequency.
            --
            Incperiod        := INCPERIOD_25MHZ;
            Incvalue         := INCVALUE_25MHZ;
            Shift            := INCVALUE_SHIFT_25MHZ;
            Adapter.Cc.Shift := Shift;

         when others =>
            return -EINVAL;
      end case;


      Timinca.all :=     shift_Left (Incperiod, E1000_TIMINCA_INCPERIOD_SHIFT)
                     or (shift_Left (Incvalue, Natural (Shift)) and E1000_TIMINCA_INCVALUE_MASK);

      return 0;
   end E1000e_Get_Base_Timinca;



   ----------------------------
   -- E1000e_Config_Hwtstamp --
   ----------------------------

   --    Configure the hwtstamp registers and enable/disable.
   --
   --  * @adapter: Board private structure.
   --  * @config:  Timestamp configuration.
   --  *
   --  * Outgoing time stamping can be enabled and disabled. Play nice and
   --  * disable it when requested, although it shouldn't cause any overhead
   --  * when no packet needs it. At most one packet in the queue may be
   --  * marked for time stamping, otherwise it would be impossible to tell
   --  * for sure to which packet the hardware time stamp belongs.
   --  *
   --  * Incoming time stamping has to be configured via the hardware filters.
   --  * Not all combinations are supported, in particular event type has to be
   --  * specified. Matching the kind of event packet is not supported, with the
   --  * exception of "all V2 events regardless of level 2 or 4".


   function E1000e_Config_Hwtstamp
     (Adapter : access E1000_Adapter.item;
      Config  : access Hwtstamp_Config) return Integer
   is
      Hw           : constant access E1000_Hw := Adapter.Hw'Access;
      Tsync_Tx_Ctl :                 u32      := E1000_TSYNCTXCTL_ENABLED;
      Tsync_Rx_Ctl :                 u32      := E1000_TSYNCRXCTL_ENABLED;
      Rxmtrl       :                 u32      := 0;
      Rxudp        :                 u16      := 0;
      Is_L4        :                 Boolean  := False;
      Is_L2        :                 Boolean  := False;
      Regval       :                 u32;

   begin
      if (Adapter.Flags and C.unsigned (FLAG_HAS_HW_TIMESTAMP)) = 0
      then
         return -EINVAL;
      end if;


      case Config.Tx_Type
      is
         when HWTSTAMP_TX_OFF'Enum_Rep =>   Tsync_Tx_Ctl := 0;
         when HWTSTAMP_TX_ON 'Enum_Rep =>   null;
         when others                   =>   return -ERANGE;
      end case;


      case Config.Rx_Filter
      is
         when HWTSTAMP_FILTER_NONE'Enum_Rep =>

            Tsync_Rx_Ctl := 0;

         when HWTSTAMP_FILTER_PTP_V1_L4_SYNC'Enum_Rep =>

            Tsync_Rx_Ctl := Tsync_Rx_Ctl or E1000_TSYNCRXCTL_TYPE_L4_V1;
            Rxmtrl       := E1000_RXMTRL_PTP_V1_SYNC_MESSAGE;
            Is_L4        := True;

         when HWTSTAMP_FILTER_PTP_V1_L4_DELAY_REQ'Enum_Rep =>

            Tsync_Rx_Ctl := Tsync_Rx_Ctl or E1000_TSYNCRXCTL_TYPE_L4_V1;
            Rxmtrl       := E1000_RXMTRL_PTP_V1_DELAY_REQ_MESSAGE;
            Is_L4        := True;

         when HWTSTAMP_FILTER_PTP_V2_L2_SYNC'Enum_Rep =>
            --  Also time stamps V2 L2 Path Delay Request/Response.
            --
            Tsync_Rx_Ctl := Tsync_Rx_Ctl or E1000_TSYNCRXCTL_TYPE_L2_V2;
            Rxmtrl       := E1000_RXMTRL_PTP_V2_SYNC_MESSAGE;
            Is_L2        := True;

         when HWTSTAMP_FILTER_PTP_V2_L2_DELAY_REQ'Enum_Rep =>
            --  Also time stamps V2 L2 Path Delay Request/Response.
            --
            Tsync_Rx_Ctl := Tsync_Rx_Ctl or E1000_TSYNCRXCTL_TYPE_L2_V2;
            Rxmtrl       := E1000_RXMTRL_PTP_V2_DELAY_REQ_MESSAGE;
            Is_L2        := True;

         when HWTSTAMP_FILTER_PTP_V2_L4_SYNC'Enum_Rep                           -- Hardware cannot filter just V2 L4 Sync messages.
            | HWTSTAMP_FILTER_PTP_V2_SYNC   'Enum_Rep =>
            -- Also time stamps V2 Path Delay Request/Response.
            --
            Tsync_Rx_Ctl := Tsync_Rx_Ctl or E1000_TSYNCRXCTL_TYPE_L2_L4_V2;
            Rxmtrl       := E1000_RXMTRL_PTP_V2_SYNC_MESSAGE;
            Is_L2        := True;
            Is_L4        := True;

         when HWTSTAMP_FILTER_PTP_V2_L4_DELAY_REQ'Enum_Rep                      -- Hardware cannot filter just V2 L4 Delay Request messages.
            | HWTSTAMP_FILTER_PTP_V2_DELAY_REQ   'Enum_Rep=>
            -- Also time stamps V2 Path Delay Request/Response.
            --
            Tsync_Rx_Ctl := Tsync_Rx_Ctl or E1000_TSYNCRXCTL_TYPE_L2_L4_V2;
            Rxmtrl       := E1000_RXMTRL_PTP_V2_DELAY_REQ_MESSAGE;
            Is_L2        := True;
            Is_L4        := True;

         when HWTSTAMP_FILTER_PTP_V2_L4_EVENT'Enum_Rep
            | HWTSTAMP_FILTER_PTP_V2_L2_EVENT'Enum_Rep                          -- Hardware cannot filter just V2 L4 or L2 Event messages.
            | HWTSTAMP_FILTER_PTP_V2_EVENT   'Enum_Rep =>

            Tsync_Rx_Ctl     := Tsync_Rx_Ctl or E1000_TSYNCRXCTL_TYPE_EVENT_V2;
            Config.Rx_Filter := HWTSTAMP_FILTER_PTP_V2_EVENT'Enum_Rep;
            Is_L2            := True;
            Is_L4            := True;

         when HWTSTAMP_FILTER_PTP_V1_L4_EVENT'Enum_Rep                          -- For V1, the hardware can only filter Sync messages or
                                                                                -- Delay Request messages but not both so fall-through to
                                                                                -- time stamp all packets.
            | HWTSTAMP_FILTER_NTP_ALL        'Enum_Rep
            | HWTSTAMP_FILTER_ALL            'Enum_Rep =>

            Is_L2            := True;
            Is_L4            := True;
            Tsync_Rx_Ctl     := Tsync_Rx_Ctl or E1000_TSYNCRXCTL_TYPE_ALL;
            Config.Rx_Filter := HWTSTAMP_FILTER_ALL'Enum_Rep;

         when others =>
            return -ERANGE;
      end case;


      Adapter.Hwtstamp_Config := Config.all;

      -- Enable/disable Tx h/w time stamping.
      --
      Regval := Er32 (Hw.all, E1000_TSYNCTXCTL);
      Regval := Regval and not E1000_TSYNCTXCTL_ENABLED;
      Regval := Regval or Tsync_Tx_Ctl;
      Ew32 (Hw.all, E1000_TSYNCTXCTL, Regval);

      if (Er32 (Hw.all, E1000_TSYNCTXCTL) and E1000_TSYNCTXCTL_ENABLED) /=
        (Regval and E1000_TSYNCTXCTL_ENABLED)
      then
         e_err ("Timesync Tx Control register not set as expected");
         return -EAGAIN;
      end if;

      -- Enable/disable Rx h/w time stamping.
      --
      Regval := Er32 (Hw.all, E1000_TSYNCRXCTL);
      Regval := Regval and not (E1000_TSYNCRXCTL_ENABLED or E1000_TSYNCRXCTL_TYPE_MASK);
      Regval := Regval or Tsync_Rx_Ctl;
      Ew32 (Hw.all, E1000_TSYNCRXCTL, Regval);

      if (     Er32 (Hw.all, E1000_TSYNCRXCTL)
          and (   E1000_TSYNCRXCTL_ENABLED
               or E1000_TSYNCRXCTL_TYPE_MASK))
        /= (Regval and (   E1000_TSYNCRXCTL_ENABLED
                        or E1000_TSYNCRXCTL_TYPE_MASK))
      then
         e_err ("Timesync Rx Control register not set as expected");
         return -EAGAIN;
      end if;

      -- L2: define ethertype filter for time stamped packets.
      --
      if Is_L2
      then
         Rxmtrl := Rxmtrl or ETH_P_1588;
      end if;

      -- Define which PTP packets get time stamped.
      --
      Ew32 (Hw.all, E1000_RXMTRL, Rxmtrl);

      -- Filter by destination port.
      --
      if Is_L4
      then
         Rxudp := PTP_EV_PORT;
         Cpu_To_Be16s (Rxudp);
      end if;

      Ew32 (Hw.all, E1000_RXUDP, u32 (Rxudp));
      E1e_Flush (Hw);

      -- Clear TSYNCRXCTL_VALID & TSYNCTXCTL_VALID bit.
      --
      Er32 (Hw.all, E1000_RXSTMPH);
      Er32 (Hw.all, E1000_TXSTMPH);

      return 0;
   end E1000e_Config_Hwtstamp;



   ---------------------
   -- E1000_Configure --
   ---------------------

   --  configure the hardware for Rx and Tx.
   --
   --    * @adapter: Private board structure.


   procedure E1000_Configure
     (Adapter : access E1000_Adapter.item)
   is
      Rx_Ring : constant access E1000_Ring.item := Adapter.Rx_Ring;
      Netdev  : constant access Net_Device      := Adapter.Netdev;

   begin
      E1000e_Set_Rx_Mode (Netdev);

      E1000_Restore_Vlan (Adapter);
      E1000_Init_Manageability_Pt (Adapter);

      E1000_Configure_Tx (Adapter);

      if (Netdev.Features and NETIF_F_RXHASH) /= 0
      then
         E1000e_Setup_Rss_Hash (Adapter);
      end if;

      E1000_Setup_Rctl   (Adapter);
      E1000_Configure_Rx (Adapter);

      Adapter.Alloc_Rx_Buf (Rx_Ring    => Rx_Ring,
                            Desc_Count => C.int (E1000_Desc_Unused (Rx_Ring)),
                            Flags      => GFP_KERNEL);
   end E1000_Configure;




   -------------------------
   -- E1000e_Power_Up_Phy --
   -------------------------

   --    Restore link in case the phy was powered down.
   --
   --  * @adapter: Address of board private structure.
   --  *
   --  * The phy may be powered down to save power and turn off link when the
   --  * driver is unloaded and wake on lan is not enabled (among others)
   --  * *** This routine MUST be followed by a call to e1000e_reset! ***


   procedure E1000e_Power_Up_Phy
     (Adapter : access E1000_Adapter.item)
   is
      use type Devices.e1000e.Hardware.proc_arg1_e1000_hw.item;
      Unused : s32;

   begin
      if Adapter.Hw.Phy.Ops.Power_Up /= null
      then
         Adapter.Hw.Phy.Ops.Power_Up (Adapter.Hw'Access);
      end if;

      Unused := Adapter.Hw.Mac.Ops.Setup_Link (Adapter.Hw'Access);
   end E1000e_Power_Up_Phy;




   --------------------------
   -- E1000_Power_Down_Phy --
   --------------------------

   --    Power down the PHY.
   --
   --  * @adapter: Board private structure.
   --  *
   --  * Power down the PHY so no link is implied when interface is down.
   --  * The PHY cannot be powered down if management or WoL is active.


   procedure E1000_Power_Down_Phy
     (Adapter : access E1000_Adapter.item)
   is
      use type Devices.e1000e.Hardware.proc_arg1_e1000_hw.item;
   begin
      if Adapter.Hw.Phy.Ops.Power_Down /= null
      then
         Adapter.Hw.Phy.Ops.Power_Down (Adapter.Hw'Access);
      end if;
   end E1000_Power_Down_Phy;




   -------------------------
   -- E1000_Flush_Tx_Ring --
   -------------------------

   --    Remove all descriptors from the tx_ring.
   --
   --  * @adapter: Board private structure.
   --  *
   --  * We want to clear all pending descriptors from the TX ring.
   --  * zeroing happens when the HW reads the regs. We  assign the ring itself as
   --  * the data of the next descriptor. We don't care about the data we are about
   --  * to reset the HW.


   procedure E1000_Flush_Tx_Ring
     (Adapter : access E1000_Adapter.item)
   is
      Hw        : constant access   E1000_Hw           := Adapter.Hw'Access;
      Tx_Ring   : constant access   E1000_Ring.item    := Adapter.Tx_Ring;
      Tx_Desc   :          access   E1000_Tx_Desc.item := null;
      Tdt,
      Tctl      :                   Unsigned_32;
      Txd_Lower : constant          Unsigned_32        := E1000_TXD_CMD_IFCS;
      Size      : constant          Unsigned_16        := 512;

   begin
      Tctl := Er32 (Hw.all, E1000_TCTL);
      Ew32 (Hw.all, E1000_TCTL, Tctl or E1000_TCTL_EN);
      Tdt  := Er32 (Hw.all, E1000_TDT (0));

      if Tdt /= u32 (Tx_Ring.Next_To_Use)
      then
         raise Program_Error with "TDT mismatch";
      end if;

      Tx_Desc             := utility.E1000_TX_DESC (Tx_Ring.all, Integer (Tx_Ring.Next_To_Use));
      Tx_Desc.Buffer_Addr := le64' (Value => (shift_Left (Unsigned_64 (Tx_Ring.Dma), 0)));

      Tx_Desc.Lower.Data  := le32' (Value => shift_Left (Txd_Lower or Unsigned_32 (Size), 0));
      Tx_Desc.Upper.Data  := le32' (Value => 0);

      -- Flush descriptors to memory before notifying the HW.
      --
      wmb;

      Tx_Ring.Next_To_Use := Tx_Ring.Next_To_Use + 1;

      if Tx_Ring.Next_To_Use = u16 (Tx_Ring.Count)
      then
         Tx_Ring.Next_To_Use := 0;
      end if;

      Ew32 (Hw.all, E1000_TDT (0), Unsigned_32 (Tx_Ring.Next_To_Use));

      delay 0.000225;     -- Equivalent to usleep_range (200, 250).
   end E1000_Flush_Tx_Ring;




   -------------------------
   -- E1000_Flush_Rx_Ring --
   -------------------------

   --  Remove all descriptors from the rx_ring.
   --
   --  * @adapter: Board private structure.
   --  *
   --  * Mark all descriptors in the RX ring as consumed and disable the rx ring


   procedure E1000_Flush_Rx_Ring
     (Adapter : access E1000_Adapter.item)
   is
      Hw     : constant access E1000_HW := Adapter.Hw'Access;
      Rctl,
      Rxdctl :                 unsigned_32;

   begin
      Rctl := Er32 (Hw.all, E1000_RCTL);
      Ew32 (Hw.all, E1000_RCTL, Rctl and (not E1000_RCTL_EN));
      E1e_Flush (Hw);

      delay 125.0 * Microseconds;

      Rxdctl := Er32 (Hw.all, E1000_RXDCTL (0));

      -- Zero the lower 14 bits (prefetch and host thresholds).
      --
      Rxdctl := Rxdctl and 16#FFFFC000#;

      -- Update thresholds: prefetch threshold to 31, host threshold to 1
      -- and make sure the granularity is "descriptors" and not "cache lines".
      --
      Rxdctl := Rxdctl or (16#1F# or 2**8 or Devices.e1000e.Ich8Lan.E1000_RXDCTL_THRESH_UNIT_DESC);

      Ew32 (Hw.all, E1000_RXDCTL (0), Rxdctl);

      -- Momentarily enable the RX ring for the changes to take effect.
      --
      Ew32 (Hw.all, E1000_RCTL, Rctl or E1000_RCTL_EN);
      E1e_Flush (Hw);
      delay 125.0 * Microseconds;
      Ew32 (Hw.all, E1000_RCTL, Rctl and (not E1000_RCTL_EN));
   end E1000_Flush_Rx_Ring;




   ----------------------------
   -- E1000_Flush_Desc_Rings --
   ----------------------------

   --    Remove all descriptors from the descriptor rings.
   --
   --  * @adapter: Board private structure.
   --  *
   --  * In i219, the descriptor rings must be emptied before resetting the HW
   --  * or before changing the device state to D3 during runtime (runtime PM).
   --  *
   --  * Failure to do this will cause the HW to enter a unit hang state which can
   --  * only be released by PCI reset on the device


   procedure E1000_Flush_Desc_Rings
     (Adapter : access E1000_Adapter.item)
   is
      Hang_State : aliased Unsigned_16;
      Fext_Nvm11,
      Tdlen      :         Unsigned_32;
            Hw         : constant access  E1000_HW   := Adapter.Hw'Access;
      Unused     :         C.int;

   begin
      -- First, disable MULR fix in FEXTNVM11.
      --
      Fext_Nvm11 := Er32 (Hw.all, E1000_FEXTNVM11);
      Fext_Nvm11 := Fext_Nvm11 or Devices.e1000e.Ich8Lan.E1000_FEXTNVM11_DISABLE_MULR_FIX;
      Ew32 (Hw.all, E1000_FEXTNVM11, Fext_Nvm11);

      -- Do nothing if we're not in faulty state, or if the queue is empty.
      --
      Tdlen  := Er32 (Hw.all, E1000_TDLEN (0));
      Unused := Pci_Read_Config_Word (Adapter.Pdev, PCICFG_DESC_RING_STATUS, Hang_State'unchecked_Access);

      if   (Hang_State and FLUSH_DESC_REQUIRED) = 0
        or Tdlen = 0
      then
         return;
      end if;

      E1000_Flush_Tx_Ring (Adapter);

      -- Recheck, maybe the fault is caused by the rx ring.
      --
      Unused := Pci_Read_Config_Word (Adapter.Pdev, PCICFG_DESC_RING_STATUS, Hang_State'unchecked_Access);

      if (Hang_State and FLUSH_DESC_REQUIRED) /= 0
      then
         E1000_Flush_Rx_Ring (Adapter);
      end if;
   end E1000_Flush_Desc_Rings;




   -------------------------
   -- E1000e_Systim_Reset --
   -------------------------

   --    Reset the timesync registers after a hardware reset.
   --
   --  * @adapter: Board private structure.
   --  *
   --  * When the MAC is reset, all hardware bits for timesync will be reset to the
   --  * default values. This function will restore the settings last in place.
   --  * Since the clock SYSTIME registers are reset, we will simply restore the
   --  * cyclecounter to the kernel real clock time.


   procedure E1000e_Systim_Reset
     (Adapter : access E1000_Adapter.item)
   is
      Info    : constant access PTP_Clock_Info := Adapter.PTP_Clock_Info'Access;
      HW      : constant access E1000_HW       := Adapter.HW'Access;
      Flags   :                 C.Unsigned_Long;
      Timinca : aliased         Unsigned_32;
      Ret_Val :                 s32;
      Unused  :                 Integer;

   begin
      if (Adapter.Flags and C.unsigned (FLAG_HAS_HW_TIMESTAMP)) = 0
      then
         return;
      end if;


      if Info.Adjfine /= null
      then
         -- Restore the previous ptp frequency delta.
         --
         Ret_Val := s32 (Info.Adjfine (Info.all'Access, Adapter.PTP_Delta));
      else
         -- Set the default base frequency if no adjustment possible.
         --
         Ret_Val := E1000e_Get_Base_Timinca (Adapter, Timinca'Access);

         if Ret_Val = 0
         then
            EW32 (Hw.all, E1000_TIMINCA, Timinca);
         end if;
      end if;

      if Ret_Val /= 0
      then
         dev_warn (adapter.pdev.dev'Access,
                   "Failed to restore TIMINCA clock rate delta:" & ret_val'Image);
         return;
      end if;


      -- Reset the systim ns time counter.
      --
      Spin_Lock_Irqsave      (Adapter.Systim_Lock'Access,
                              Flags);
      Timecounter_Init       (Adapter.TC'Access,
                              Adapter.CC'Access,
                              u64 (Ktime_To_Ns (Ktime_Get_Real)));
      Spin_Unlock_Irqrestore (Adapter.Systim_Lock'Access,
                              Flags);

      -- Restore the previous hwtstamp configuration settings.
      --
      Unused := E1000e_Config_Hwtstamp (Adapter, Adapter.Hwtstamp_Config'Access);
   end E1000e_Systim_Reset;




   ------------------
   -- E1000e_Reset --
   ------------------

   --    Bring the hardware into a known good state.
   --
   --  * @adapter: Board private structure.
   --  *
   --  * This function boots the hardware and enables some settings that
   --  * require a configuration cycle of the hardware - those cannot be
   --  * set/changed during runtime. After reset the device needs to be
   --  * properly configured for Rx, Tx etc.

   procedure E1000e_Reset (Adapter : access E1000_Adapter.item)
   is
      use Devices.e1000e.Media_Access_Control;

      Mac          : constant access E1000_Mac_Info.item := Adapter.Hw.Mac'Access;
      Fc           : constant access E1000_Fc_Info.item  := Adapter.Hw.Fc 'Access;
      Hw           : constant access E1000_Hw            := Adapter.Hw    'Access;
      Tx_Space,
      Min_Tx_Space,
      Min_Rx_Space : Unsigned_32;
      Pba          : Unsigned_32 := Adapter.Pba;
      Hwm          : Unsigned_16;
      Unused       : s32;

   begin
      -- Reset Packet Buffer Allocation to default.
      --
      Ew32 (Hw.all, E1000_PBA, Pba);

      if Adapter.Max_Frame_Size > (VLAN_ETH_FRAME_LEN + ETH_FCS_LEN)
      then
         -- To maintain wire speed transmits, the Tx FIFO should be
         --  large enough to accommodate two full transmit packets,
         --  rounded up to the next 1KB and expressed in KB.  Likewise,
         --  the Rx FIFO should be large enough to accommodate at least
         --  one full receive packet and is similarly rounded up and
         --  expressed in KB.
         --
         Pba := Er32 (Hw.all, E1000_PBA);

         -- Upper 16 bits has Tx packet buffer allocation size in KB.
         --
         Tx_Space := Shift_Right (Pba, 16);

         -- Lower 16 bits has Rx packet buffer allocation size in KB.
         --
         Pba := Pba and 16#FFFF#;

         -- The Tx fifo also stores 16 bytes of information about the Tx
         -- but don't include ethernet FCS because hardware appends it.
         --
         Min_Tx_Space :=   (  Adapter.Max_Frame_Size
                            + E1000_Tx_Desc.item'Size / 8
                            - ETH_FCS_LEN)
                         * 2;
         Min_Tx_Space := u32 (Align (C.unsigned (Min_Tx_Space), 1024));
         Min_Tx_Space := Shift_Right (Min_Tx_Space, 10);

         -- Software strips receive CRC, so leave room for it.
         --
         Min_Rx_Space := Adapter.Max_Frame_Size;
         Min_Rx_Space := u32 (Align (C.unsigned (Min_Rx_Space), 1024));
         Min_Rx_Space := Shift_Right (Min_Rx_Space, 10);


         -- If current Tx allocation is less than the min Tx FIFO size,
         -- and the min Tx FIFO size is less than the current Rx FIFO
         -- allocation, take space away from current Rx allocation.
         --
         if          Tx_Space < Min_Tx_Space
           and then (Min_Tx_Space - Tx_Space) < Pba
         then
            Pba := Pba - (Min_Tx_Space - Tx_Space);

            -- If short on Rx space, Rx wins and must trump Tx adjustment.
            --
            if Pba < Min_Rx_Space
            then
               Pba := Min_Rx_Space;
            end if;
         end if;

         Ew32 (Hw.all, E1000_PBA, Pba);
      end if;


      -- Flow control settings.
      --
      -- The high water mark must be low enough to fit one full frame
      -- (or the size used for early receive) above it in the Rx FIFO.
      --
      -- Set it to the lower of:
      --    - 90% of the Rx FIFO size, and
      --    - the full Rx FIFO size minus one full frame
      --
      if (Adapter.Flags and C.unsigned (FLAG_DISABLE_FC_PAUSE_TIME)) /= 0
      then
         Fc.Pause_Time := 16#FFFF#;
      else
         Fc.Pause_Time := E1000_FC_PAUSE_TIME;
      end if;

      Fc.Send_Xon     := True;
      Fc.Current_Mode := Fc.Requested_Mode;

      case Hw.Mac.Mac_Type
      is
         when E1000_Ich9lan
            | E1000_Ich10lan =>

            if Adapter.Netdev.Mtu > ETH_DATA_LEN
            then
               Pba           := 14;
               Ew32 (Hw.all, E1000_PBA, Pba);
               Fc.High_Water := 16#2800#;
               Fc.Low_Water  := Fc.High_Water - 8;
            else
               Hwm           := u16 (u32'Min (((shift_Left (Pba, 10) * 9) / 10),
                                               (shift_Left (Pba, 10) - Adapter.Max_Frame_Size)));
               Fc.High_Water := u32 (Hwm and E1000_FCRTH_RTH);
               Fc.Low_Water  := Fc.High_Water - 8;
            end if;

         when E1000_Pchlan =>
            -- Workaround PCH LOM adapter hangs with certain network
            -- loads.  If hangs persist, try disabling Tx flow control.
            --
            if Adapter.Netdev.Mtu > ETH_DATA_LEN
            then
               Fc.High_Water := 16#3500#;
               Fc.Low_Water  := 16#1500#;
            else
               Fc.High_Water := 16#5000#;
               Fc.Low_Water  := 16#3000#;
            end if;

            Fc.Refresh_Time := 16#1000#;

         when E1000_Pch2lan
            | E1000_Pch_Lpt
            | E1000_Pch_Spt
            | E1000_Pch_Cnp
            | E1000_Pch_Tgp
            | E1000_Pch_Adp
            | E1000_Pch_Mtp
            | E1000_Pch_Lnp
            | E1000_Pch_Ptp
            | E1000_Pch_Nvp =>

            Fc.Refresh_Time := 16#FFFF#;
            Fc.Pause_Time   := 16#FFFF#;

            if Adapter.Netdev.Mtu <= ETH_DATA_LEN
            then
               Fc.High_Water := 16#05C20#;
               Fc.Low_Water  := 16#05048#;
            else
               Pba           := 14;
               Ew32 (Hw.all, E1000_PBA, Pba);
               Fc.High_Water := ((Shift_Left (Pba, 10) * 9) / 10) and E1000_FCRTH_RTH;
               Fc.Low_Water  := ((Shift_Left (Pba, 10) * 8) / 10) and E1000_FCRTL_RTL;
            end if;

         when others =>

            Hwm           := u16 (u32'Min (((shift_Left (Pba, 10) * 9) / 10),
                                            (shift_Left (Pba, 10) - Adapter.Max_Frame_Size)));
            Fc.High_Water := u32 (Hwm and E1000_FCRTH_RTH);
            Fc.Low_Water  := Fc.High_Water - 8;
      end case;


      -- Alignment of Tx data is on an arbitrary byte boundary with the
      -- maximum size per Tx descriptor limited only to the transmit
      -- allocation of the packet buffer minus 96 bytes with an upper
      -- limit of 24KB due to receive synchronization limitations.
      --
      Adapter.Tx_Fifo_Limit := Unsigned_32'Min ((Shift_Left (Shift_Right (Er32 (Hw.all, E1000_PBA),
                                                                          16),
                                                             10)
                                                - 96),
                                                Shift_Left (24, 10));

      -- Disable Adaptive Interrupt Moderation if 2 full packets cannot
      -- fit in receive buffer.
      --
      if (Adapter.Itr_Setting and 16#3#) /= 0
      then
         if (Adapter.Max_Frame_Size * 2) > Shift_Left (Pba, 10)
         then
            if (Adapter.Flags2 and C.unsigned (FLAG2_DISABLE_AIM)) = 0
            then
               dev_info (adapter.pdev.dev'Access,
                         "Interrupt Throttle Rate off\n");
               Adapter.Flags2 := Adapter.Flags2 or C.unsigned (FLAG2_DISABLE_AIM);
               E1000e_Write_Itr (Adapter, 0);
            end if;

         elsif (Adapter.Flags2 and C.unsigned (FLAG2_DISABLE_AIM)) /= 0
         then
            dev_info (adapter.pdev.dev'Access,
                      "Interrupt Throttle Rate on\n");

            Adapter.Flags2 := Adapter.Flags2 and (not C.unsigned (FLAG2_DISABLE_AIM));
            Adapter.Itr    := 20_000;
            E1000e_Write_Itr (Adapter, Adapter.Itr);
         end if;
      end if;


      if Hw.Mac.Mac_Type >= E1000_Pch_Spt
      then
         E1000_Flush_Desc_Rings (Adapter);
      end if;

      -- Allow time for pending master requests to run.
      --
      Unused := Mac.Ops.Reset_Hw (Hw);

      -- For parts with AMT enabled, let the firmware know
      -- that the network interface is in control.
      --
      if (Adapter.Flags and C.unsigned (FLAG_HAS_AMT)) /= 0
      then
         E1000e_Get_Hw_Control (Adapter);
      end if;

      Ew32 (Hw.all, E1000_WUC, 0);

      if Mac.Ops.Init_Hw (Hw) /= 0
      then
         e_err ("Hardware Error");
      end if;

      E1000_Update_Mng_Vlan (Adapter);

      -- Enable h/w to recognize an 802.1Q VLAN Ethernet packet.
      --
      Ew32 (Hw.all, E1000_VET, ETH_P_8021Q);

      E1000e_Reset_Adaptive (Hw);

      -- Restore systim and hwtstamp settings.
      --
      E1000e_Systim_Reset (Adapter);

      -- Set EEE advertisement as appropriate.
      --
      if (Adapter.Flags2 and C.unsigned (FLAG2_HAS_EEE)) /= 0
      then
         declare
            Ret_Val  : s32;
            Adv_Addr : Unsigned_16;
         begin
            case Hw.Phy.Phy_Type
            is
               when E1000_Phy_82579 =>   Adv_Addr := Devices.e1000e.Ich8Lan.I82579_EEE_ADVERTISEMENT;
               when E1000_Phy_I217  =>   Adv_Addr := Devices.e1000e.Ich8Lan.I217_EEE_ADVERTISEMENT;
               when others          =>   dev_err (adapter.pdev.dev'Access,
                                                  "Invalid PHY type setting EEE advertisement\n");
                                         return;
            end case;

            Ret_Val := Hw.Phy.Ops.Acquire (Hw);

            if Ret_Val /= 0
            then
               dev_err (adapter.pdev.dev'Access,
                        "EEE advertisement - unable to acquire PHY\n");
               return;
            end if;


            Unused := Devices.e1000e.Ich8Lan.E1000_Write_Emi_Reg_Locked (Hw, Adv_Addr,
                                                          (if Hw.Dev_Spec.Ich8lan.Eee_Disable then 0
                                                                                              else Adapter.Eee_Advert));
            Hw.Phy.Ops.Release (Hw);
         end;
      end if;


      if         not netif_running (adapter.netdev)
        and then not test_bit (E1000_TESTING'enum_Rep, Adapter.State'Address)
      then
         E1000_Power_Down_Phy (Adapter);
      end if;

      Unused := E1000_Get_Phy_Info (Hw);

      if         (Adapter.Flags and C.unsigned (FLAG_HAS_SMART_POWER_DOWN)) /= 0
        and then (Adapter.Flags and C.unsigned (FLAG_SMART_POWER_DOWN))      = 0
      then
         declare
            Phy_Data : aliased Unsigned_16 := 0;
         begin
            -- Speed up time to link by disabling smart power down, ignore
            -- the return value of this function because there is nothing
            -- different we would do if it failed.
            --
            Unused   := E1e_Rphy (Hw, Devices.e1000e.Physical_Layer.IGP02E1000_PHY_POWER_MGMT, Phy_Data'unchecked_Access);
            Phy_Data := Phy_Data and (not Devices.e1000e.Physical_Layer.IGP02E1000_PM_SPD);
            E1e_Wphy (Hw, Devices.e1000e.Physical_Layer.IGP02E1000_PHY_POWER_MGMT, Phy_Data);
         end;
      end if;

      if    Hw.Mac.Mac_Type >= E1000_Pch_Spt
        and Adapter.Int_Mode = 0
      then
         declare
            Reg : Unsigned_32;
         begin
            -- Fextnvm7 @ 0xe4[2] = 1
            --
            Reg := Er32 (Hw.all, E1000_FEXTNVM7);
            Reg := Reg or Devices.e1000e.Ich8Lan.E1000_FEXTNVM7_SIDE_CLK_UNGATE;
            Ew32 (Hw.all, E1000_FEXTNVM7, Reg);

            -- Fextnvm9 @ 0x5bb4[13:12] = 11
            --
            Reg := Er32 (Hw.all, E1000_FEXTNVM9);
            Reg := Reg or Devices.e1000e.Ich8Lan.E1000_FEXTNVM9_IOSFSB_CLKGATE_DIS or Devices.e1000e.Ich8Lan.E1000_FEXTNVM9_IOSFSB_CLKREQ_DIS;
            Ew32 (Hw.all, E1000_FEXTNVM9, Reg);
         end;
      end if;
   end E1000e_Reset;




   ------------------------
   -- E1000e_Trigger_Lsc --
   ------------------------

   --    Trigger an LSC interrupt.
   --
   --  * @adapter: Board private structure.
   --  *
   --  * Fire a link status change interrupt to start the watchdog.


   procedure E1000e_Trigger_Lsc
     (Adapter : access E1000_Adapter.item)
   is
      Hw : constant access E1000_Hw := Adapter.Hw'Access;

   begin
      if Adapter.Msix_Entries /= null
      then
         Ew32 (Hw.all, E1000_ICS, E1000_ICS_LSC or E1000_ICS_OTHER);
      else
         Ew32 (Hw.all, E1000_ICS, E1000_ICS_LSC);
      end if;
   end E1000e_Trigger_Lsc;




   ---------------
   -- E1000e_Up --
   ---------------

   procedure E1000e_Up
     (Adapter : access E1000_Adapter.item)
   is
   begin
      -- Hardware has been reset, we need to reload some things.
      --
      E1000_Configure (Adapter);

      Clear_Bit (E1000_DOWN'enum_Rep, Adapter.State'Address);

      if Adapter.Msix_Entries /= null
      then
         E1000_Configure_Msix (Adapter);
      end if;

      E1000_Irq_Enable (Adapter);

      -- Tx queue started by watchdog timer when link is up.
      --
      E1000e_Trigger_Lsc (Adapter);
   end E1000e_Up;




   ------------------------------
   -- E1000e_Flush_Descriptors --
   ------------------------------

   procedure E1000e_Flush_Descriptors
     (Adapter : access E1000_Adapter.item)
   is
      HW : constant access E1000_HW := Adapter.HW'Access;

   begin
      if (Adapter.Flags2 and C.unsigned (FLAG2_DMA_BURST)) = 0
      then
         return;
      end if;


      -- Flush pending descriptor writebacks to memory.
      --
      EW32 (Hw.all, E1000_TIDV, Adapter.Tx_Int_Delay or E1000_TIDV_FPD);
      EW32 (Hw.all, E1000_RDTR, Adapter.Rx_Int_Delay or E1000_RDTR_FPD);

      -- Execute the writes immediately.
      --
      E1e_Flush (Hw);

      -- Due to rare timing issues, write to TIDV/RDTR again to ensure the
      -- write is successful.
      --
      EW32 (Hw.all, E1000_TIDV, Adapter.Tx_Int_Delay or E1000_TIDV_FPD);
      EW32 (Hw.all, E1000_RDTR, Adapter.Rx_Int_Delay or E1000_RDTR_FPD);

      -- Execute the writes immediately.
      --
      E1e_Flush (Hw);
   end E1000e_Flush_Descriptors;






   procedure E1000e_Update_Stats
     (Adapter : access E1000_Adapter.item);




   -----------------
   -- E1000e_Down --
   -----------------

   --    Quiesce the device and optionally reset the hardware.
   --
   --  * @adapter: Board private structure.
   --  * @reset:   Boolean flag to reset the hardware or not.


   procedure E1000e_Down
     (Adapter : access E1000_Adapter.item;
      Reset   : in     Boolean)
   is
      Netdev : constant access Net_Device := Adapter.Netdev;
      Hw     : constant access E1000_HW   := Adapter.Hw'Access;
      Tctl,
      Rctl   :                 Unsigned_32;
      Unused :                 C.int;

   begin
      -- Signal that we're down so the interrupt handler does not
      -- reschedule our watchdog timer.
      --
      Set_Bit (E1000_DOWN'enum_Rep, Adapter.State'Address);

      netif_carrier_off (Netdev);

      -- Disable receives in the hardware.
      --
      Rctl := Er32 (Hw.all, E1000_RCTL);

      if (Adapter.Flags2 and C.unsigned (FLAG2_NO_DISABLE_RX)) = 0
      then
         Ew32 (Hw.all, E1000_RCTL, Rctl and (not E1000_RCTL_EN));
      end if;

      -- Flush and sleep below.

      netif_stop_queue (Netdev);

      -- Disable transmits in the hardware.
      --
      Tctl := Er32 (Hw.all, E1000_TCTL);
      Tctl := Tctl and (not E1000_TCTL_EN);
      Ew32 (Hw.all, E1000_TCTL, Tctl);

      -- Flush both disables and wait for them to finish.
      --
      E1e_Flush (Hw);
      delay 0.015;

      E1000_Irq_Disable (Adapter);

      Napi_Synchronize (Adapter.Napi'Access);

      Unused := del_timer_sync (adapter.watchdog_timer'Access);
      Unused := del_timer_sync (adapter.phy_info_timer'Access);

      spin_lock           (Adapter.stats64_lock'Access);
      E1000e_Update_Stats (Adapter);
      spin_unlock         (Adapter.stats64_lock'Access);

      E1000e_Flush_Descriptors (Adapter);

      Adapter.Link_Speed  := 0;
      Adapter.Link_Duplex := 0;

      -- Disable Si errata workaround on PCHx for jumbo frame flow.
      --
      if         Hw.Mac.Mac_Type >= E1000_Pch2lan
        and then Netdev.Mtu > ETH_DATA_LEN
        and then Devices.e1000e.Ich8Lan.E1000_Lv_Jumbo_Workaround_Ich8lan (Hw, False) /= 0
      then
         e_dbg ("failed to disable jumbo frame workaround mode");
      end if;

      if Pci_Channel_Offline (Adapter.Pdev) = 0
      then
         if Reset
         then
            E1000e_Reset (Adapter);

         elsif Hw.Mac.Mac_Type >= E1000_Pch_Spt
         then
            E1000_Flush_Desc_Rings (Adapter);
         end if;
      end if;

      E1000_Clean_Tx_Ring (Adapter.Tx_Ring);
      E1000_Clean_Rx_Ring (Adapter.Rx_Ring);
   end E1000e_Down;




   --------------------------
   -- E1000e_Reinit_Locked --
   --------------------------

   procedure E1000e_Reinit_Locked
     (Adapter : access E1000_Adapter.item)
   is
   begin
      Might_Sleep;

      while test_and_set_bit (E1000_RESETTING'enum_Rep,
                              Adapter.state'Access)
      loop
         delay 1_050.0 * Microseconds;
      end loop;

      E1000e_Down (Adapter, True);
      E1000e_Up   (Adapter);

      Clear_Bit (E1000_RESETTING'enum_Rep,
                 Adapter.State  'Address);
   end E1000e_Reinit_Locked;




   ----------------------------
   -- E1000e_Sanitize_Systim --
   ----------------------------

   --    Sanitize raw cycle counter reads.
   --
   --  * @hw:     Pointer to the HW structure.
   --  * @systim: PHC time value read, sanitized and returned.
   --  * @sts:    Structure to hold system time before and after reading SYSTIML may be NULL
   --  *
   --  * Errata for 82574/82583 possible bad bits read from SYSTIMH/L:
   --  * check to see that the time is incrementing at a reasonable
   --  * rate and is a multiple of incvalue.


   function E1000e_Sanitize_Systim
     (Hw     : access E1000_Hw;
      Systim : in     Unsigned_64;
      Sts    : access Ptp_System_Timestamp) return Unsigned_64
   is
      Time_Delta,
      Remainder,
      Temp          : Unsigned_64;
      Systim_Next   : Unsigned_64;
      Incvalue      : Unsigned_32;
      I             : Integer;
      Systim_Result : Unsigned_64 := Systim;

   begin
      Incvalue := Er32 (Hw.all, E1000_TIMINCA) and E1000_TIMINCA_INCVALUE_MASK;

      for I in 0 .. E1000_MAX_82574_SYSTIM_REREADS - 1
      loop
         -- Latch SYSTIMH on read of SYSTIML.
         --
         Ptp_Read_System_Prets (Sts);
         Systim_Next := Unsigned_64 (Er32 (Hw.all, E1000_SYSTIML));

         Ptp_Read_System_Postts (Sts);
         Systim_Next := Systim_Next or Shift_Left (Unsigned_64 (Er32 (Hw.all, E1000_SYSTIMH)), 32);

         Time_Delta := Systim_Next - Systim_Result;
         Temp       := Time_Delta;

         -- VMWare users have seen incvalue of zero, don't div / 0.
         --
         if Incvalue /= 0
         then
            Remainder := Temp mod u64 (Incvalue);
            Temp      := Temp /   u64 (Incvalue);
         else
            Remainder := (if Time_Delta /= 0 then 1 else 0);
         end if;

         Systim_Result := Systim_Next;

         exit when     Time_Delta < E1000_82574_SYSTIM_EPSILON
                   and Remainder = 0;
      end loop;


      return Systim_Result;
   end E1000e_Sanitize_Systim;




   ------------------------
   -- E1000e_Read_Systim --
   ------------------------

   --    Read SYSTIM register.
   --
   --  * @adapter: Board private structure
   --  * @sts:     Structure which will contain system time before and after reading SYSTIML, may be NULL.

   function E1000e_Read_Systim
     (Adapter : access E1000_Adapter.item;
      Sts     : access PTP_System_Timestamp) return Unsigned_64
   is
      Hw         : constant access E1000_HW   := Adapter.Hw'Access;
      Systimel   :                 Unsigned_32;
      Systimel_2 :                 Unsigned_32;
      Systimeh   :                 Unsigned_32;
      Systim     :                 Unsigned_64;

   begin
      -- SYSTIMH latching upon SYSTIML read does not work well.
      -- This means that if SYSTIML overflows after we read it but before
      -- we read SYSTIMH, the value of SYSTIMH has been incremented and we
      -- will experience a huge non linear increment in the systime value
      -- to fix that we test for overflow and if true, we re-read systime.
      --

      PTP_Read_System_Prets (Sts);
      Systimel := Er32 (Hw.all, E1000_SYSTIML);

      PTP_Read_System_Postts (Sts);
      Systimeh := Er32 (Hw.all, E1000_SYSTIMH);

      -- Is systimel is so large that overflow is possible?
      --
      if Systimel >= Unsigned_32'Last - E1000_TIMINCA_INCVALUE_MASK
      then
         PTP_Read_System_Prets (Sts);
         Systimel_2 := Er32 (Hw.all, E1000_SYSTIML);
         PTP_Read_System_Postts (Sts);

         if Systimel > Systimel_2
         then
            -- There was an overflow, read again SYSTIMH, and use systimel_2.
            --
            Systimeh := Er32 (Hw.all, E1000_SYSTIMH);
            Systimel := Systimel_2;
         end if;
      end if;

      Systim := Unsigned_64 (Systimel);
      Systim := Systim or Shift_Left (Unsigned_64 (Systimeh), 32);

      if (Adapter.Flags2 and C.unsigned (FLAG2_CHECK_SYSTIM_OVERFLOW)) /= 0
      then
         Systim := E1000e_Sanitize_Systim (Hw, Systim, Sts);
      end if;

      return Systim;
   end E1000e_Read_Systim;





   ------------------------------
   -- E1000e_Cyclecounter_Read --
   ------------------------------

   --  Read raw cycle counter (used by time counter).
   --
   --  * @cc: Cyclecounter structure.


   function E1000e_Cyclecounter_Read
     (CC : access Cyclecounter) return U64
   is
      Adapter : constant E1000_Adapter.Pointer := E1000_Adapter.Pointer (E1000_Adapter_Conversions.to_Pointer (container_of (CC.all'Address)));
                                                                                                                             -- , struct e1000_adapter                     -- TODO
                                                                                                                             -- , cc);
   begin
      return E1000e_Read_Systim (Adapter, null);
   end E1000e_Cyclecounter_Read;




   -------------------
   -- E1000_SW_Init --
   -------------------

   --    Initialize general software structures (struct e1000_adapter).
   --
   --  * @adapter: Board private structure to initialize.
   --  *
   --  * e1000_sw_init initializes the Adapter private data structure.
   --  * Fields are initialized based on PCI device information and
   --  * OS network device settings (MTU size).


   function E1000_SW_Init
     (Adapter : access E1000_Adapter.item) return C.int
   is
      Netdev : constant access Net_Device := Adapter.Netdev;

   begin
      Adapter.Rx_Buffer_Len  := VLAN_ETH_FRAME_LEN + ETH_FCS_LEN;
      Adapter.Rx_Ps_Bsize0   := 128;
      Adapter.Max_Frame_Size := u32 (Netdev.MTU + VLAN_ETH_HLEN + ETH_FCS_LEN);
      Adapter.Min_Frame_Size := ETH_ZLEN   + ETH_FCS_LEN;
      Adapter.Tx_Ring_Count  := E1000_DEFAULT_TXD;
      Adapter.Rx_Ring_Count  := E1000_DEFAULT_RXD;

      spin_lock_init (adapter.stats64_lock'Access);

      E1000e_Set_Interrupt_Capability (Adapter);

      if E1000_Alloc_Queues (Adapter) /= 0
      then
         return -ENOMEM;
      end if;

      -- Setup hardware time stamping cyclecounter.
      --
      if (Adapter.Flags and C.unsigned (FLAG_HAS_HW_TIMESTAMP)) /= 0
      then
         Adapter.CC.Read := E1000e_Cyclecounter_Read'Access;
         Adapter.CC.Mask := CYCLECOUNTER_MASK (64);
         Adapter.CC.Mult := 1;
         -- cc.shift is set in e1000e_get_base_tininca.

         spin_lock_init (adapter.systim_lock'Access);
         INIT_WORK (adapter.tx_hwtstamp_work'Access,
                    e1000e_tx_hwtstamp_work 'Access);
      end if;

      -- Explicitly disable IRQ since the NIC can be in any state.
      --
      E1000_IRQ_Disable (Adapter);

      set_bit (E1000_DOWN'enum_Rep, adapter.state'Address);

      return 0;
   end E1000_SW_Init;




   -------------------------
   -- E1000_Intr_MSI_Test --
   -------------------------

   --  Interrupt Handler.
   --
   --  * @irq:  Interrupt number.
   --  * @data: Pointer to a network interface device structure.


   function E1000_Intr_MSI_Test
     (Irq  : C.int with Unreferenced;
      Data : System.Address         ) return irqreturn_t
   is
      Netdev  : aliased Net_Device
        with
          Import,
          Address => Data;

      Adapter : E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev'Access);

      Hw      : constant access E1000_HW   := Adapter.Hw'Access;
      ICR     :                 Unsigned_32;

   begin
      ICR := Er32 (Hw.all, E1000_ICR);

      e_dbg ("icr is " & ICR'Image);

      if (ICR and E1000_ICR_RXSEQ) /= 0
      then
         Adapter.Flags := Adapter.Flags and (not C.unsigned (FLAG_MSI_TEST_FAILED));

         -- Force memory writes to complete before acknowledging the interrupt is handled.
         --
         wmb;
      end if;

      return IRQ_HANDLED;
   end E1000_Intr_MSI_Test;




   ------------------------------
   -- E1000_Test_MSI_Interrupt --
   ------------------------------

   --    Returns 0 for successful test.
   --
   --  * @adapter: Board private struct.
   --  *
   --  * Code flow taken from 'tg3.c'.


   function E1000_Test_MSI_Interrupt
     (Adapter : access E1000_Adapter.item) return C.int
   is
      use C.Strings;

      Netdev  : constant access Net_Device := Adapter.Netdev;
      Hw      : constant access E1000_HW   := Adapter.HW'Access;
      Err     :                 C.int;
      Unused  :                 u32;
      Unused2 :                 void_ptr;
   begin
      -- 'poll_enable' hasn't been called yet, so don't need disable.
      -- Clear any pending events.
      --
      Unused := ER32 (Hw.all, E1000_ICR);

      -- Free the real vector and request a test handler.
      --
      E1000_Free_IRQ (Adapter);
      E1000e_Reset_Interrupt_Capability (Adapter);

      -- Assume that the test fails, if it succeeds then the test
      -- MSI irq handler will unset this flag.
      --
      Adapter.Flags := Adapter.Flags or C.unsigned (FLAG_MSI_TEST_FAILED);

      Err := PCI_Enable_MSI (Adapter.Pdev);

      if Err /= 0
      then
         goto MSI_Test_Failed;
      end if;


      Err := Request_IRQ (Adapter.Pdev.IRQ,
                          E1000_Intr_MSI_Test'Access,
                          0,
                          new_String (Netdev.Name.all),
                          Netdev.all'Address);
      if Err /= 0
      then
         PCI_Disable_MSI (Adapter.Pdev);
         goto MSI_Test_Failed;
      end if;

      -- Force memory writes to complete before enabling and firing an interrupt.
      --
      wmb;

      E1000_IRQ_Enable (Adapter);

      -- Fire an unusual interrupt on the test handler.
      --
      EW32 (Hw.all, E1000_ICS, E1000_ICS_RXSEQ);
      E1e_Flush (Hw);
      delay 0.1;     -- Equivalent to msleep(100).

      E1000_IRQ_Disable (Adapter);

      rmb;           -- Read flags after interrupt has been fired.

      if (Adapter.Flags and C.unsigned (FLAG_MSI_TEST_FAILED)) /= 0
      then
         Adapter.Int_Mode := E1000E_INT_MODE_LEGACY;
         e_info ("MSI interrupt test failed, using legacy interrupt.");
      else
         e_dbg  ("MSI interrupt test succeeded!");
      end if;

      Unused2 := Free_IRQ (Adapter.Pdev.IRQ, Netdev.all'Address);
      PCI_Disable_MSI (Adapter.Pdev);


      <<MSI_Test_Failed>>

      E1000e_Set_Interrupt_Capability (Adapter);
      return E1000_Request_IRQ (Adapter);
   end E1000_Test_MSI_Interrupt;



   --------------------
   -- E1000_Test_MSI --
   --------------------

   --    Returns 0 if MSI test succeeds or INTx mode is restored.
   --
   --  * @adapter: Board private struct.
   --  *
   --  * Code flow taken from 'tg3.c', called with e1000 interrupts disabled.


   function E1000_Test_MSI
     (Adapter : access E1000_Adapter.item) return C.int
   is
      Err     :         C.int;
      PCI_Cmd : aliased Unsigned_16;
      Unused  :         C.int;

   begin
      if (Adapter.Flags and C.unsigned (FLAG_MSI_ENABLED)) = 0
      then
         return 0;
      end if;


      -- Disable SERR in case the MSI write causes a master abort.
      --
      PCI_Cmd := Unsigned_16 (PCI_Read_Config_Word (Adapter.Pdev,
                                                    PCI_COMMAND,
                                                    pci_cmd'Access));

      if (PCI_Cmd and PCI_COMMAND_SERR) /= 0
      then
         Unused := PCI_Write_Config_Word (Adapter.Pdev,
                                          PCI_COMMAND,
                                          PCI_Cmd and (not PCI_COMMAND_SERR));
      end if;

      Err := E1000_Test_MSI_Interrupt (Adapter);

      -- Re-enable SERR.
      --
      if (PCI_Cmd and PCI_COMMAND_SERR) /= 0
      then
         PCI_Cmd := Unsigned_16 (PCI_Read_Config_Word (Adapter.Pdev,
                                                       PCI_COMMAND,
                                                       PCI_Cmd'Access));
         PCI_Cmd := PCI_Cmd or PCI_COMMAND_SERR;

         Unused  := PCI_Write_Config_Word (Adapter.Pdev,
                                           PCI_COMMAND,
                                           PCI_Cmd);
      end if;

      return Err;
   end E1000_Test_MSI;



   -----------------
   -- E1000e_Open --
   -----------------

   --    Called when a network interface is made active.
   --
   --  * @netdev: Network interface device structure.
   --  *
   --  * Returns 0 on success, negative value on failure.
   --  *
   --  * The open entry point is called when a network interface is made
   --  * active by the system (IFF_UP).  At this point all resources needed
   --  * for transmit and receive operations are allocated, the interrupt
   --  * handler is registered with the OS, the watchdog timer is started,
   --  * and the stack is notified that the interface is ready.


   function E1000e_Open (Netdev : access Net_Device) return C.int
   is
      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev);

      Hw      : constant access E1000_HW      := Adapter.Hw'Access;
      Pdev    :          access PCI_Dev       := Adapter.Pdev;
      Err     :                 C.int;
      Unused  :                 C.int;

   begin
      -- Disallow open during test.
      --
      if Test_Bit (E1000_TESTING'enum_Rep, Adapter.State'Address)
      then
         return -EBUSY;
      end if;


      Unused := pm_runtime_get_sync (Pdev.Dev'Access);

      Netif_Carrier_Off (Netdev);
      Netif_Stop_Queue  (Netdev);

      -- Allocate transmit descriptors.
      --
      Err := E1000e_Setup_Tx_Resources (Adapter.Tx_Ring);

      if Err /= 0
      then
         goto Err_Setup_Tx;
      end if;


      -- Allocate receive descriptors.
      --
      Err := E1000e_Setup_Rx_Resources (Adapter.Rx_Ring);

      if Err /= 0
      then
         goto Err_Setup_Rx;
      end if;


      -- If AMT is enabled, let the firmware know that the network
      -- interface is now open and reset the part to a known state.
      --
      if (Adapter.Flags and C.unsigned (FLAG_HAS_AMT)) /= 0
      then
         E1000e_Get_Hw_Control (Adapter'Access);
         E1000e_Reset          (Adapter'Access);
      end if;

      E1000e_Power_Up_Phy (Adapter'Access);

      Adapter.Mng_Vlan_Id := E1000_MNG_VLAN_NONE;

      if (Adapter.Hw.Mng_Cookie.Status and Devices.e1000e.Manage.E1000_MNG_DHCP_COOKIE_STATUS_VLAN) /= 0
      then
         E1000_Update_Mng_Vlan (Adapter'Access);
      end if;

      -- DMA latency requirement to workaround jumbo issue.
      --
      cpu_latency_qos_add_request (Adapter.Pm_Qos_Req'Access, PM_QOS_DEFAULT_VALUE);

      -- Before we allocate an interrupt, we must be ready to handle it.
      -- Setting DEBUG_SHIRQ in the kernel makes it fire an interrupt
      -- as soon as we call pci_request_irq, so we have to setup our
      -- clean_rx handler before we do so.
      --
      E1000_Configure (Adapter'Access);

      Err := E1000_Request_Irq (Adapter'Access);

      if Err /= 0
      then
         goto Err_Req_Irq;
      end if;


      -- Work around PCIe errata with MSI interrupts causing some chipsets to
      -- ignore e1000e MSI messages, which means we need to test our MSI
      -- interrupt now.
      --
      if Adapter.Int_Mode /= E1000E_INT_MODE_LEGACY
      then
         Err := E1000_Test_Msi (Adapter'Access);

         if Err /= 0
         then
            e_err ("Interrupt allocation failed");
            goto Err_Req_Irq;
         end if;
      end if;


      -- From here on the code is the same as e1000e_up().
      --
      Clear_Bit (E1000_DOWN'enum_Rep, Adapter.State'Address);

      Napi_Enable (Adapter.Napi'Access);

      E1000_Irq_Enable (Adapter'Access);

      Adapter.Tx_Hang_Recheck := False;
      Hw.Mac.Get_Link_Status  := True;
      Unused                  := PM_Runtime_Put (Pdev.Dev'Access);

      E1000e_Trigger_Lsc (Adapter'Access);

      return 0;


      <<Err_Req_Irq>>

      cpu_latency_qos_remove_request (Adapter.Pm_Qos_Req'Access);
      E1000e_Release_Hw_Control      (Adapter'Access);
      E1000_Power_Down_Phy           (Adapter'Access);
      E1000e_Free_Rx_Resources       (Adapter.Rx_Ring);


      <<Err_Setup_Rx>>

      E1000e_Free_Tx_Resources (Adapter.Tx_Ring);


      <<Err_Setup_Tx>>

      E1000e_Reset (Adapter'Access);
      Unused := pm_runtime_put_sync (Pdev.Dev'Access);

      return Err;
   end E1000e_Open;




   ------------------
   -- E1000e_Close --
   ------------------

   --    Disables a network interface.
   --
   --  * @netdev: Network interface device structure.
   --  *
   --  * Returns 0, this is not allowed to fail.
   --  *
   --  * The close entry point is called when an interface is de-activated
   --  * by the OS.  The hardware is still under the drivers control, but
   --  * needs to be disabled.  A global MAC reset is issued to stop the
   --  * hardware, and all transmit and receive resources are freed.


   function E1000e_Close (Netdev : access net_device) return C.int
   is
      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev);

      Pdev    : access PCI_Dev       := Adapter.Pdev;
      Count   :        Integer       := E1000_CHECK_RESET_COUNT;
      Unused  :        C.int;
      Unused2 :        Integer;

   begin
      while      test_bit (E1000_RESETTING'enum_Rep, Adapter.State'Address)
        and then Count > 0
      loop
         delay 0.015;  -- Equivalent to usleep_range(10000, 11000)
         Count := Count - 1;
      end loop;

      WARN_ON (test_bit (E1000_RESETTING'enum_Rep, adapter.state'Address));

      Unused := PM_Runtime_Get_Sync (Pdev.Dev'Access);

      if Netif_Device_Present (Netdev)
      then
         E1000e_Down    (Adapter'Access, True);
         E1000_Free_IRQ (Adapter'Access);

         -- Link status message must follow this format.
         --
         netdev_info (netdev, "NIC Link is Down");
      end if;


      NAPI_Disable (Adapter.Napi'Access);

      E1000e_Free_TX_Resources (Adapter.Tx_Ring);
      E1000e_Free_RX_Resources (Adapter.Rx_Ring);

      -- Kill manageability vlan ID if supported, but not if a vlan with
      -- the same ID is registered on the host OS (let 8021q kill it).
      --
      if (Adapter.Hw.Mng_Cookie.Status and Devices.e1000e.Manage.E1000_MNG_DHCP_COOKIE_STATUS_VLAN) /= 0
      then
         Unused := E1000_VLAN_RX_Kill_VID (Netdev, htons (ETH_P_8021Q).Value, Adapter.Mng_VLAN_ID);
      end if;

      -- If AMT is enabled, let the firmware know that the network
      -- interface is now closed.
      --
      if            (Adapter.Flags and C.unsigned (FLAG_HAS_AMT)) /= 0
        and then not Test_Bit (E1000_TESTING'enum_Rep, Adapter.State'Address)
      then
         E1000e_Release_HW_Control (Adapter'Access);
      end if;

      CPU_Latency_QOS_Remove_Request (Adapter.PM_QOS_Req'Access);

      Unused := PM_Runtime_Put_Sync (Pdev.Dev'Access);

      return 0;
   end E1000e_Close;




   -------------------
   -- E1000_Set_Mac --
   -------------------

   --    Change the Ethernet Address of the NIC.
   --
   --  * @netdev: Network interface device structure.
   --  * @p:      Pointer to an address structure.
   --  *
   --  * Returns 0 on success, negative on failure.


   function E1000_Set_Mac
     (Netdev : access Net_Device;
      P      : in     void_ptr) return C.int
   is
      use system.Memory_Copy;

      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev);

      Hw      : constant access E1000_Hw := Adapter.Hw'Access;
      Unused  :                 C.int;
      Addr    : constant        sockaddr
        with
          Import,
          Address => P;

   begin
      if not Is_Valid_Ether_Addr (Addr.Sa_Data)
      then
         return -EADDRNOTAVAIL;
      end if;

      eth_hw_addr_set (Netdev, Addr.Sa_Data);
      memcpy (adapter.hw.mac.addr'Address,
              addr.sa_data.all   'Address,
              System.CRTL.size_t (netdev.addr_len));

      Unused := Hw.Mac.Ops.Rar_Set (Hw, Hw.Mac.Addr (0)'unchecked_Access, 0);

      if (Adapter.Flags and C.unsigned (FLAG_RESET_OVERWRITES_LAA)) /= 0
      then
         -- Activate the work around.
         --
         Devices.e1000e.an_82571.E1000e_Set_Laa_State_82571 (Hw, True);

         -- Hold a copy of the LAA in RAR[14] This is done so that
         -- between the time RAR[0] gets clobbered and the time it
         -- gets fixed (in e1000_watchdog), the actual LAA is in one
         -- of the RARs and no incoming packets directed to this port
         -- are dropped. Eventually the LAA will be in RAR[0] and RAR[14].
         --
         Unused := Hw.Mac.Ops.Rar_Set (Hw,
                                       Hw.Mac.Addr (0)'unchecked_Access,
                                       u32 (Hw.Mac.Rar_Entry_Count - 1));
      end if;

      return 0;
   end E1000_Set_Mac;




   ----------------------------
   -- E1000e_Update_Phy_Task --
   ----------------------------

   --    Work thread to update phy.
   --
   --  * @work: Pointer to our work struct.
   --  *
   --  * This worker thread exists because we must acquire a
   --  * semaphore to read the phy, which we could msleep while
   --  * waiting for it, and we can't msleep in a timer.


   procedure E1000e_Update_Phy_Task
     (Work : access Work_Struct)
   is
      Adapter  : E1000_Adapter.Pointer := E1000_Adapter.Pointer (E1000_Adapter_Conversions.to_Pointer (container_of (Work.all'Address)));
                                                                                                                 --  struct e1000_adapter,
                                                                                                                 --  update_phy_task);
      HW      : constant access E1000_HW      := Adapter.HW'Access;
      Unused  :                 s32;

   begin
      if test_bit (E1000_DOWN'enum_Rep, adapter.state'Address)
      then
         return;
      end if;


      Unused := E1000_Get_Phy_Info (HW);

      -- Enable EEE on 82579 after link up.
      --
      if HW.PHY.Phy_Type >= E1000_PHY_82579
      then
         Unused := Devices.e1000e.Ich8Lan.e1000_set_EEE_Pchlan (HW);
      end if;
   end E1000e_Update_Phy_Task;




   ---------------------------
   -- E1000_Update_Phy_Info --
   ---------------------------

   --    Timer call-back to update PHY info.
   --
   --  * @t: Pointer to timer_list containing private info adapter.
   --  *
   --  * Need to wait a few seconds after link up to get diagnostic information from the phy.


   procedure E1000_Update_Phy_Info
     (T : access timer_list)
   is
      Adapter : access E1000_Adapter.item;     -- TODO    := from_timer (adapter, t, phy_info_timer);

   begin
      if test_bit (E1000_DOWN'enum_Rep, adapter.state'Address)
      then
         return;
      end if;

      schedule_work (adapter.update_phy_task'Access);
   end E1000_Update_Phy_Info;




   -----------------------------
   -- E1000e_Update_Phy_Stats --
   -----------------------------

   --    Update the PHY statistics counters.
   --
   --  * @adapter: Board private structure.
   --  *
   --  * Read/clear the upper 16-bit PHY registers and read/accumulate lower.


   procedure E1000e_Update_Phy_Stats
     (Adapter : access E1000_Adapter.item)
   is
      HW       : constant access  E1000_HW := Adapter.HW'Access;
      Ret_Val  :                  s32;
      Phy_Data : aliased          Unsigned_16;
      Unused   :                  s32;

   begin
      Ret_Val := HW.Phy.Ops.Acquire (HW);

      if Ret_Val /= 0
      then
         return;
      end if;


      -- A page set is expensive so check if already on desired page.
      -- If not, set to the page with the PHY status registers.
      --
      HW.Phy.Addr := 1;
      Ret_Val     := Devices.e1000e.Physical_Layer.E1000e_Read_Phy_Reg_Mdic (HW,
                                                   Devices.e1000e.Physical_Layer.IGP01E1000_PHY_PAGE_SELECT,
                                                   Phy_Data'unchecked_Access);
      if Ret_Val /= 0
      then
         goto Release;
      end if;


      if Phy_Data /= shift_Left (Devices.e1000e.Ich8Lan.HV_STATS_PAGE, Devices.e1000e.Physical_Layer.IGP_PAGE_SHIFT)
      then
         Ret_Val := HW.Phy.Ops.Set_Page (HW,
                                         shift_Left (Devices.e1000e.Ich8Lan.HV_STATS_PAGE,
                                                     Devices.e1000e.Physical_Layer.IGP_PAGE_SHIFT));

         if Ret_Val /= 0
         then
            goto Release;
         end if;
      end if;


      -- Single Collision Count.
      --
      Unused  := HW.Phy.Ops.Read_Reg_Page (HW, Devices.e1000e.Ich8Lan.HV_SCC_UPPER, Phy_Data'unchecked_Access);
      Ret_Val := HW.Phy.Ops.Read_Reg_Page (HW, Devices.e1000e.Ich8Lan.HV_SCC_LOWER, Phy_Data'unchecked_Access);

      if Ret_Val = 0
      then
         Adapter.Stats.Scc := Adapter.Stats.Scc + u64 (Phy_Data);
      end if;

      -- Excessive Collision Count.
      --
      Unused  := HW.Phy.Ops.Read_Reg_Page (HW, Devices.e1000e.Ich8Lan.HV_ECOL_UPPER, Phy_Data'unchecked_Access);
      Ret_Val := HW.Phy.Ops.Read_Reg_Page (HW, Devices.e1000e.Ich8Lan.HV_ECOL_LOWER, Phy_Data'unchecked_Access);

      if Ret_Val = 0
      then
         Adapter.Stats.Ecol := Adapter.Stats.Ecol + u64 (Phy_Data);
      end if;

      -- Multiple Collision Count.
      --
      Unused  := HW.Phy.Ops.Read_Reg_Page (HW, Devices.e1000e.Ich8Lan.HV_MCC_UPPER, Phy_Data'unchecked_Access);
      Ret_Val := HW.Phy.Ops.Read_Reg_Page (HW, Devices.e1000e.Ich8Lan.HV_MCC_LOWER, Phy_Data'unchecked_Access);

      if Ret_Val = 0
      then
         Adapter.Stats.Mcc := Adapter.Stats.Mcc + u64 (Phy_Data);
      end if;

      -- Late Collision Count.
      --
      Unused  := HW.Phy.Ops.Read_Reg_Page (HW, Devices.e1000e.Ich8Lan.HV_LATECOL_UPPER, Phy_Data'unchecked_Access);
      Ret_Val := HW.Phy.Ops.Read_Reg_Page (HW, Devices.e1000e.Ich8Lan.HV_LATECOL_LOWER, Phy_Data'unchecked_Access);

      if Ret_Val = 0
      then
         Adapter.Stats.Latecol := Adapter.Stats.Latecol + u64 (Phy_Data);
      end if;

      -- Collision Count - also used for adaptive IFS.
      --
      Unused  := HW.Phy.Ops.Read_Reg_Page (HW, Devices.e1000e.Ich8Lan.HV_COLC_UPPER, Phy_Data'unchecked_Access);
      Ret_Val := HW.Phy.Ops.Read_Reg_Page (HW, Devices.e1000e.Ich8Lan.HV_COLC_LOWER, Phy_Data'unchecked_Access);

      if Ret_Val = 0
      then
         HW.Mac.Collision_Delta := Unsigned_32 (Phy_Data);
      end if;

      -- Defer Count.
      --
      Unused  := HW.Phy.Ops.Read_Reg_Page (HW, Devices.e1000e.Ich8Lan.HV_DC_UPPER, Phy_Data'unchecked_Access);
      Ret_Val := HW.Phy.Ops.Read_Reg_Page (HW, Devices.e1000e.Ich8Lan.HV_DC_LOWER, Phy_Data'unchecked_Access);

      if Ret_Val = 0
      then
         Adapter.Stats.Dc := Adapter.Stats.Dc + u64 (Phy_Data);
      end if;

      -- Transmit with no CRS.
      --
      Unused  := HW.Phy.Ops.Read_Reg_Page (HW, Devices.e1000e.Ich8Lan.HV_TNCRS_UPPER, Phy_Data'unchecked_Access);
      Ret_Val := HW.Phy.Ops.Read_Reg_Page (HW, Devices.e1000e.Ich8Lan.HV_TNCRS_LOWER, Phy_Data'unchecked_Access);

      if Ret_Val = 0
      then
         Adapter.Stats.Tncrs := Adapter.Stats.Tncrs + u64 (Phy_Data);
      end if;


      <<Release>>

      HW.Phy.Ops.Release (HW);
   end E1000e_Update_Phy_Stats;




   -------------------------
   -- E1000e_Update_Stats --
   -------------------------

   --  Update the board statistics counters.
   --
   --  * @adapter: Board private structure.


   procedure E1000e_Update_Stats
     (Adapter : access E1000_Adapter.item)
   is
      Netdev : constant access Net_Device := Adapter.Netdev;
      Hw     : constant access E1000_Hw   := Adapter.Hw'Access;
      Pdev   : constant access PCI_Dev    := Adapter.Pdev;

   begin
      -- Prevent stats update while adapter is being reset, or if the pci
      -- connection is down.
      --
      if Adapter.Link_Speed = 0
      then
         return;
      end if;


      if PCI_Channel_Offline (Pdev) /= 0
      then
         return;
      end if;


      Adapter.Stats.Crcerrs := Adapter.Stats.Crcerrs + u64 (Er32 (Hw.all, E1000_CRCERRS));
      Adapter.Stats.Gprc    := Adapter.Stats.Gprc    + u64 (Er32 (Hw.all, E1000_GPRC));
      Adapter.Stats.Gorc    := Adapter.Stats.Gorc    + u64 (Er32 (Hw.all, E1000_GORCL));

      declare
         Dummy : Unsigned_32 := Er32 (Hw.all, E1000_GORCH); -- Clear gorc
      begin
         null;
      end;

      Adapter.Stats.Bprc := Adapter.Stats.Bprc + u64 (Er32 (Hw.all, E1000_BPRC));
      Adapter.Stats.Mprc := Adapter.Stats.Mprc + u64 (Er32 (Hw.all, E1000_MPRC));
      Adapter.Stats.Roc  := Adapter.Stats.Roc  + u64 (Er32 (Hw.all, E1000_ROC));
      Adapter.Stats.Mpc  := Adapter.Stats.Mpc  + u64 (Er32 (Hw.all, E1000_MPC));

      -- Half-duplex statistics.
      --
      if Adapter.Link_Duplex = HALF_DUPLEX
      then
         if (Adapter.Flags2 and C.unsigned (FLAG2_HAS_PHY_STATS)) /= 0
         then
            E1000e_Update_Phy_Stats (Adapter);
         else
            Adapter.Stats.Scc     := Adapter.Stats.Scc     + u64 (Er32 (Hw.all, E1000_SCC));
            Adapter.Stats.Ecol    := Adapter.Stats.Ecol    + u64 (Er32 (Hw.all, E1000_ECOL));
            Adapter.Stats.Mcc     := Adapter.Stats.Mcc     + u64 (Er32 (Hw.all, E1000_MCC));
            Adapter.Stats.Latecol := Adapter.Stats.Latecol + u64 (Er32 (Hw.all, E1000_LATECOL));
            Adapter.Stats.Dc      := Adapter.Stats.Dc      + u64 (Er32 (Hw.all, E1000_DC));

            Hw.Mac.Collision_Delta := Er32 (Hw.all, E1000_COLC);

            if    Hw.Mac.Mac_Type /= e1000_82574
              and Hw.Mac.Mac_Type /= e1000_82583
            then
               Adapter.Stats.Tncrs := Adapter.Stats.Tncrs + u64 (Er32 (Hw.all, E1000_TNCRS));
            end if;
         end if;

         Adapter.Stats.Colc := Adapter.Stats.Colc + u64 (Hw.Mac.Collision_Delta);
      end if;


      Adapter.Stats.Xonrxc  := Adapter.Stats.Xonrxc  + u64 (Er32 (Hw.all, E1000_XONRXC));
      Adapter.Stats.Xontxc  := Adapter.Stats.Xontxc  + u64 (Er32 (Hw.all, E1000_XONTXC));
      Adapter.Stats.Xoffrxc := Adapter.Stats.Xoffrxc + u64 (Er32 (Hw.all, E1000_XOFFRXC));
      Adapter.Stats.Xofftxc := Adapter.Stats.Xofftxc + u64 (Er32 (Hw.all, E1000_XOFFTXC));
      Adapter.Stats.Gptc    := Adapter.Stats.Gptc    + u64 (Er32 (Hw.all, E1000_GPTC));
      Adapter.Stats.Gotc    := Adapter.Stats.Gotc    + u64 (Er32 (Hw.all, E1000_GOTCL));

      declare
         Dummy : Unsigned_32 := Er32 (Hw.all, E1000_GOTCH); -- Clear gotc.
      begin
         null;
      end;

      Adapter.Stats.Rnbc := Adapter.Stats.Rnbc + u64 (Er32 (Hw.all, E1000_RNBC));
      Adapter.Stats.Ruc  := Adapter.Stats.Ruc  + u64 (Er32 (Hw.all, E1000_RUC));

      Adapter.Stats.Mptc := Adapter.Stats.Mptc + u64 (Er32 (Hw.all, E1000_MPTC));
      Adapter.Stats.Bptc := Adapter.Stats.Bptc + u64 (Er32 (Hw.all, E1000_BPTC));

      -- Used for adaptive IFS.
      --
      Hw.Mac.Tx_Packet_Delta := Er32 (Hw.all, E1000_TPT);
      Adapter.Stats.Tpt      := Adapter.Stats.Tpt + u64 (Hw.Mac.Tx_Packet_Delta);

      Adapter.Stats.Algnerrc := Adapter.Stats.Algnerrc + u64 (Er32 (Hw.all, E1000_ALGNERRC));
      Adapter.Stats.Rxerrc   := Adapter.Stats.Rxerrc   + u64 (Er32 (Hw.all, E1000_RXERRC));
      Adapter.Stats.Cexterr  := Adapter.Stats.Cexterr  + u64 (Er32 (Hw.all, E1000_CEXTERR));
      Adapter.Stats.Tsctc    := Adapter.Stats.Tsctc    + u64 (Er32 (Hw.all, E1000_TSCTC));
      Adapter.Stats.Tsctfc   := Adapter.Stats.Tsctfc   + u64 (Er32 (Hw.all, E1000_TSCTFC));

      -- Fill out the OS statistics structure.
      --
      Netdev.Stats.Multicast  := C.unsigned_long (Adapter.Stats.Mprc);
      Netdev.Stats.Collisions := C.unsigned_long (Adapter.Stats.Colc);

      -- Rx Errors.
      --

      -- RLEC on some newer hardware can be incorrect so build
      -- our own version based on RUC and ROC.
      --
      Netdev.Stats.Rx_Errors := C.unsigned_long (  Adapter.Stats.Rxerrc
                                                 + Adapter.Stats.Crcerrs
                                                 + Adapter.Stats.Algnerrc
                                                 + Adapter.Stats.Ruc
                                                 + Adapter.Stats.Roc
                                                 + Adapter.Stats.Cexterr);

      Netdev.Stats.Rx_Length_Errors := C.unsigned_long (Adapter.Stats.Ruc + Adapter.Stats.Roc);
      Netdev.Stats.Rx_Crc_Errors    := C.unsigned_long (Adapter.Stats.Crcerrs);
      Netdev.Stats.Rx_Frame_Errors  := C.unsigned_long (Adapter.Stats.Algnerrc);
      Netdev.Stats.Rx_Missed_Errors := C.unsigned_long (Adapter.Stats.Mpc);

      -- Tx Errors.
      --
      Netdev.Stats.Tx_Errors         := C.unsigned_long (Adapter.Stats.Ecol + Adapter.Stats.Latecol);
      Netdev.Stats.Tx_Aborted_Errors := C.unsigned_long (Adapter.Stats.Ecol);
      Netdev.Stats.Tx_Window_Errors  := C.unsigned_long (Adapter.Stats.Latecol);
      Netdev.Stats.Tx_Carrier_Errors := C.unsigned_long (Adapter.Stats.Tncrs);

      -- Tx Dropped needs to be maintained elsewhere.
      --

      -- Management Stats.
      --
      Adapter.Stats.Mgptc := Adapter.Stats.Mgptc + u64 (Er32 (Hw.all, E1000_MGTPTC));
      Adapter.Stats.Mgprc := Adapter.Stats.Mgprc + u64 (Er32 (Hw.all, E1000_MGTPRC));
      Adapter.Stats.Mgpdc := Adapter.Stats.Mgpdc + u64 (Er32 (Hw.all, E1000_MGTPDC));

      -- Correctable ECC Errors.
      --
      if Hw.Mac.Mac_Type >= e1000_pch_lpt
      then
         declare
            Pbeccsts : constant Unsigned_32 := Er32 (Hw.all, E1000_PBECCSTS);
         begin
            Adapter.Corr_Errors   := Adapter.Corr_Errors   + C.unsigned ((Pbeccsts and E1000_PBECCSTS_CORR_ERR_CNT_MASK));
            Adapter.Uncorr_Errors := Adapter.Uncorr_Errors + C.unsigned (shift_Right (Pbeccsts and E1000_PBECCSTS_UNCORR_ERR_CNT_MASK,
                                                                                      E1000_PBECCSTS_UNCORR_ERR_CNT_SHIFT));
         end;
      end if;

   end E1000e_Update_Stats;




   ---------------------------
   -- E1000_Phy_Read_Status --
   ---------------------------

   --  Update the PHY register status snapshot.
   --
   --  * @adapter: Board private structure.


   procedure E1000_Phy_Read_Status
     (Adapter : access E1000_Adapter.item)
   is
      use e1000_adapter;

      HW      : constant access E1000_HW            := Adapter.HW'Access;
      PHY     :          access E1000_Phy_Regs.item := Adapter.Phy_Regs'Access;
      Ret_Val :                 C.unsigned          := 0;

   begin
      if         not PM_Runtime_Suspended (Adapter.Pdev.Dev.Parent)
        and then (ER32 (Hw.all, E1000_STATUS) and E1000_STATUS_LU) /= 0
        and then  Adapter.HW.Phy.Media_Type = E1000_Media_Type_Copper
      then
         Ret_Val := Ret_Val or C.unsigned (E1E_Rphy (HW, MII_BMCR,      PHY.Bmcr     'unchecked_Access));
         Ret_Val := Ret_Val or C.unsigned (E1E_Rphy (HW, MII_BMSR,      PHY.Bmsr     'unchecked_Access));
         Ret_Val := Ret_Val or C.unsigned (E1E_Rphy (HW, MII_ADVERTISE, PHY.Advertise'unchecked_Access));
         Ret_Val := Ret_Val or C.unsigned (E1E_Rphy (HW, MII_LPA,       PHY.Lpa      'unchecked_Access));
         Ret_Val := Ret_Val or C.unsigned (E1E_Rphy (HW, MII_EXPANSION, PHY.Expansion'unchecked_Access));
         Ret_Val := Ret_Val or C.unsigned (E1E_Rphy (HW, MII_CTRL1000,  PHY.Ctrl1000 'unchecked_Access));
         Ret_Val := Ret_Val or C.unsigned (E1E_Rphy (HW, MII_STAT1000,  PHY.Stat1000 'unchecked_Access));
         Ret_Val := Ret_Val or C.unsigned (E1E_Rphy (HW, MII_ESTATUS,   PHY.Estatus  'unchecked_Access));

         if Ret_Val /= 0
         then
            e_warn ("Error reading PHY register");
         end if;

      else
         -- Do not read PHY registers if link is not up
         -- Set values to typical power-on defaults.
         --
         PHY.Bmcr :=    BMCR_SPEED1000
                     or BMCR_ANENABLE
                     or BMCR_FULLDPLX;

         PHY.Bmsr :=    BMSR_100FULL
                     or BMSR_100HALF
                     or BMSR_10FULL
                     or BMSR_10HALF
                     or BMSR_ESTATEN
                     or BMSR_ANEGCAPABLE
                     or BMSR_ERCAP;

         PHY.Advertise :=    ADVERTISE_PAUSE_ASYM
                          or ADVERTISE_PAUSE_CAP
                          or ADVERTISE_ALL
                          or ADVERTISE_CSMA;

         PHY.Lpa       := 0;
         PHY.Expansion := EXPANSION_ENABLENPAGE;
         PHY.Ctrl1000  := ADVERTISE_1000FULL;
         PHY.Stat1000  := 0;
         PHY.Estatus   := ESTATUS_1000_TFULL or ESTATUS_1000_THALF;
      end if;
   end E1000_Phy_Read_Status;




   ---------------------------
   -- E1000_Print_Link_Info --
   ---------------------------

   procedure E1000_Print_Link_Info
     (Adapter : access E1000_Adapter.item)
   is
      HW     : constant access E1000_HW    := Adapter.HW'Access;
      Ctrl   : constant        Unsigned_32 := Er32 (Hw.all, E1000_CTRL);


      function Flow_Control_String return String
      is
      begin
         if (Ctrl and E1000_CTRL_TFCE) /= 0 and (Ctrl and E1000_CTRL_RFCE) /= 0
         then
            return "Rx/Tx";

         elsif (Ctrl and E1000_CTRL_RFCE) /= 0
         then
            return "Rx";

         elsif (Ctrl and E1000_CTRL_TFCE) /= 0
         then
            return "Tx";

         else
            return "None";
         end if;
      end Flow_Control_String;


   begin
      -- Link status message must follow this format for user tools.
      --
      netdev_info (adapter.netdev,
                   "NIC Link is Up"
                   & Adapter.Link_Speed'Image
                   & " Mbps "
                   & (if Adapter.Link_Duplex = FULL_DUPLEX then "Full" else "Half")
                   & " Duplex, "
                   & "Flow Control: " & Flow_Control_String);
   end E1000_Print_Link_Info;




   ---------------------
   -- E1000e_Has_Link --
   ---------------------

   function E1000e_Has_Link
     (Adapter : access E1000_Adapter.item) return Boolean
   is
      Hw          : E1000_Hw renames Adapter.Hw;
      Link_Active : Boolean := False;
      Ret_Val     : s32     := 0;

   begin
      -- 'get_link_status' is set on LSC (link status) interrupt or
      -- Rx sequence error interrupt.  get_link_status will stay
      -- true until the check_for_link establishes link
      -- for copper adapters ONLY.
      --
      case Hw.Phy.Media_Type
      is
         when E1000_Media_Type_Copper =>

            if Hw.Mac.Get_Link_Status
            then
               Ret_Val     := Hw.Mac.Ops.Check_For_Link (Hw'Access);
               Link_Active := not Hw.Mac.Get_Link_Status;
            else
               Link_Active := True;
            end if;


         when E1000_Media_Type_Fiber =>

            Ret_Val     := Hw.Mac.Ops.Check_For_Link (Hw'Access);
            Link_Active := (Er32 (Hw, E1000_STATUS) and E1000_STATUS_LU) /= 0;


         when E1000_Media_Type_Internal_Serdes =>

            Ret_Val     := Hw.Mac.Ops.Check_For_Link (Hw'Access);
            Link_Active := Hw.Mac.Serdes_Has_Link;


         when E1000_Media_Type_Unknown
            | E1000_num_media_types =>

            null;
      end case;


      if          Ret_Val         = -E1000_ERR_PHY
        and then  Hw.Phy.Phy_Type =  E1000_Phy_Igp_3
        and then (Er32 (Hw, E1000_CTRL) and E1000_PHY_CTRL_GBE_DISABLE) /= 0
      then
         -- See e1000_kmrn_lock_loss_workaround_ich8lan().
         --
         e_info ("Gigabit has been disabled, downgrading speed");
      end if;


      return Link_Active;
   end E1000e_Has_Link;




   ----------------------------
   -- E1000e_Enable_Receives --
   ----------------------------

   procedure E1000e_Enable_Receives
     (Adapter : access E1000_Adapter.item)
   is
      Hw   : constant access E1000_HW   := Adapter.Hw'Access;
      Rctl :                 Unsigned_32;

   begin
      -- Make sure the receive unit is started.
      --
      if         (Adapter.Flags and C.unsigned (FLAG_RX_NEEDS_RESTART)) /= 0
        and then (Adapter.Flags and C.unsigned (FLAG_RESTART_NOW))      /= 0
      then
         Rctl := Er32 (Hw.all, E1000_RCTL);

         Ew32 (Hw.all, E1000_RCTL, Rctl or E1000_RCTL_EN);
         Adapter.Flags := Adapter.Flags and not C.unsigned (FLAG_RESTART_NOW);
      end if;
   end E1000e_Enable_Receives;




   ---------------------------------------
   -- E1000e_Check_82574_Phy_Workaround --
   ---------------------------------------

   procedure E1000e_Check_82574_Phy_Workaround
     (Adapter : access E1000_Adapter.item)
   is
      Hw : constant access E1000_HW := Adapter.Hw'Access;

   begin
      -- With 82574 controllers, PHY needs to be checked periodically
      -- for hung state and reset, if two calls return true.
      --
      if Devices.e1000e.an_82571.e1000_check_phy_82574 (Hw)
      then
         Adapter.Phy_Hang_Count := Adapter.Phy_Hang_Count + 1;
      else
         Adapter.Phy_Hang_Count := 0;
      end if;

      if Adapter.Phy_Hang_Count > 1
      then
         Adapter.Phy_Hang_Count := 0;
         e_dbg ("PHY appears hung - resetting");
         schedule_work (adapter.reset_task'Access);
      end if;
   end E1000e_Check_82574_Phy_Workaround;




   --------------------
   -- E1000_Watchdog --
   --------------------

   --    Timer callback.
   --
   --  * @t: Pointer to timer_list containing private info adapter.


   procedure E1000_Watchdog
     (T : access timer_list)
   is
      Adapter : access E1000_Adapter.item;     -- TODO    := from_timer (adapter, t, watchdog_timer);
   begin
      -- Do the rest outside of interrupt context.
      --
      Schedule_Work (Adapter.Watchdog_Task'Access);

      -- TODO ~ from C code: 'make this use queue_delayed_work()'.
   end E1000_Watchdog;




   -------------------------
   -- E1000_Watchdog_Task --
   -------------------------

   procedure E1000_Watchdog_Task
     (Work : access Work_Struct)
   is
      use Devices.e1000e.Media_Access_Control;

      Adapter            :          E1000_Adapter.Pointer := E1000_Adapter.Pointer (E1000_Adapter_Conversions.to_Pointer (container_of (Work.all'Address)));
                                                                                                                               --  struct e1000_adapter,
                                                                                                                               --  watchdog_task);
      Netdev             : constant access Net_Device          := Adapter.Netdev;
      Mac                : constant access E1000_Mac_Info.item := Adapter.Hw.Mac'Access;
      Phy                : constant access E1000_Phy_Info.item := Adapter.Hw.Phy'Access;
      Tx_Ring            : constant access E1000_Ring.item     := Adapter.Tx_Ring;
      Hw                 : constant access E1000_Hw            := Adapter.Hw'Access;
      Dmoff_Exit_Timeout : constant        Natural             := 100;
      Tries              :                 Natural             := 0;
      Link               :                 Boolean;
      Tctl               :                 Unsigned_32;
      Pcim_State         :                 Unsigned_32;
      Unused             :                 C.int;
      Unused3            :                 Integer;

   begin
      if Test_Bit (E1000_DOWN'enum_Rep, Adapter.State'Address)
      then
         return;
      end if;


      Link := E1000e_Has_Link (Adapter);

      if Netif_Carrier_Ok (Netdev) and Link
      then
         -- Cancel scheduled suspend requests.
         --
         Unused := Pm_Runtime_Resume (Netdev.Dev.Parent);

         E1000e_Enable_Receives (Adapter);
         goto Link_Up;
      end if;


      if         Devices.e1000e.Manage.E1000e_Enable_Tx_Pkt_Filtering (Hw)
        and then Adapter.Mng_Vlan_Id /= Adapter.Hw.Mng_Cookie.Vlan_Id
      then
         E1000_Update_Mng_Vlan (Adapter);
      end if;

      if Link
      then
         if not Netif_Carrier_Ok (Netdev)
         then
            declare
               use standard.Devices.e1000e.Physical_Layer;
               use type Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.Item;

               Txb2b   : Boolean := True;
               Unused2 : s32;
            begin
               -- Cancel scheduled suspend requests.
               --
               Unused := Pm_Runtime_Resume (Netdev.Dev.Parent);

               -- Checking if MAC is in DMoff state.
               --
               if (Er32 (Hw.all, E1000_FWSM) and Devices.e1000e.Ich8Lan.E1000_ICH_FWSM_FW_VALID) /= 0
               then
                  Pcim_State := Er32 (Hw.all, E1000_STATUS);

                  while (Pcim_State and E1000_STATUS_PCIM_STATE) /= 0
                  loop
                     if Tries = Dmoff_Exit_Timeout
                     then
                        e_dbg ("Error in exiting dmoff");
                        exit;
                     end if;

                     delay 0.015;  -- Equivalent to usleep_range(10000, 20000)
                     Pcim_State := Er32 (Hw.all, E1000_STATUS);

                     -- Checking if MAC exited DMoff state.
                     --
                     if (Pcim_State and E1000_STATUS_PCIM_STATE) = 0
                     then
                        Unused2 := E1000_Phy_Hw_Reset (Adapter.Hw'Access);
                     end if;

                     Tries := Tries + 1;
                  end loop;
               end if;

               -- Update snapshot of PHY registers on LSC.
               --
               E1000_Phy_Read_Status (Adapter);
               Unused2 := Mac.Ops.Get_Link_Up_Info (Adapter.Hw'Access,
                                                    Adapter.Link_Speed'Access,
                                                    Adapter.Link_Duplex'Access);
               E1000_Print_Link_Info (Adapter);

               -- Check if SmartSpeed worked.
               --
               Unused2 := E1000e_Check_Downshift (Hw);

               if Phy.Speed_Downgraded
               then
                  netdev_warn (netdev, "Link Speed was downgraded by SmartSpeed");
               end if;

               -- On supported PHYs, check for duplex mismatch only
               -- if link has autonegotiated at 10/100 half.
               --
               if   (   Hw.Phy.phy_type = E1000_Phy_Igp_3
                     or Hw.Phy.phy_type = E1000_Phy_Bm)
                 and Hw.Mac.Autoneg
                 and (   Adapter.Link_Speed = SPEED_10
                      or Adapter.Link_Speed = SPEED_100)
                 and Adapter.Link_Duplex = HALF_DUPLEX
               then
                  declare
                     Autoneg_Exp : aliased Unsigned_16;
                  begin
                     Unused2 := E1e_Rphy (Hw, MII_EXPANSION, Autoneg_Exp'unchecked_Access);

                     if (Autoneg_Exp and EXPANSION_NWAY) = 0
                     then
                        e_info (  "Autonegotiated half duplex but link partner cannot autoneg. "
                                & "Try forcing full duplex if link gets many collisions.");
                     end if;
                  end;
               end if;

               -- Adjust timeout factor according to speed/duplex.
               --
               Adapter.Tx_Timeout_Factor := 1;

               case Adapter.Link_Speed
               is
                  when SPEED_10 =>
                     Txb2b                     := False;
                     Adapter.Tx_Timeout_Factor := 16;

                  when SPEED_100 =>
                     Txb2b                     := False;
                     Adapter.Tx_Timeout_Factor := 10;
                  when others => null;
               end case;

               -- Workaround: re-program speed mode bit after link-up event.
               --
               if   (Adapter.Flags and C.unsigned (FLAG_TARC_SPEED_MODE_BIT)) /= 0
                 and not Txb2b
               then
                  declare
                     Tarc0 : Unsigned_32;
                  begin
                     Tarc0 := Er32 (Hw.all, E1000_TARC (0));
                     Tarc0 := Tarc0 and not SPEED_MODE_BIT;
                     Ew32 (Hw.all, E1000_TARC (0), Tarc0);
                  end;
               end if;

               -- Enable transmits in the hardware, need to do this after setting TARC(0).
               --
               Tctl := Er32 (Hw.all, E1000_TCTL);
               Tctl := Tctl or E1000_TCTL_EN;
               Ew32 (Hw.all, E1000_TCTL, Tctl);

               -- Perform any post-link-up configuration before reporting link up.
               --
               if Phy.Ops.Cfg_On_Link_Up /= null
               then
                  Unused2 := Phy.Ops.Cfg_On_Link_Up (Hw);
               end if;

               Netif_Wake_Queue (Netdev);
               Netif_Carrier_On (Netdev);

               if not Test_Bit (E1000_DOWN'enum_Rep, Adapter.State'Address)
               then
                  Unused3 := Mod_Timer (Adapter.Phy_Info_Timer'Access,
                                        Round_Jiffies (Jiffies + 2 * HZ));
               end if;
            end;
         end if;

      else
         if Netif_Carrier_Ok (Netdev)
         then
            Adapter.Link_Speed  := 0;
            Adapter.Link_Duplex := 0;

            -- Link status message must follow this format.
            --
            netdev_info (netdev, "NIC Link is Down");
            Netif_Carrier_Off (Netdev);
            Netif_Stop_Queue  (Netdev);

            if not Test_Bit (E1000_DOWN'Enum_Rep, Adapter.State'Address)
            then
               Unused3 := Mod_Timer (Adapter.Phy_Info_Timer'Access,
                                     Round_Jiffies (Jiffies + 2 * HZ));
            end if;

            -- 8000ES2LAN requires a Rx packet buffer work-around
            -- on link down event; reset the controller to flush
            -- the Rx packet buffer.
            --
            if (Adapter.Flags and C.unsigned (FLAG_RX_NEEDS_RESTART)) /= 0
            then
               Adapter.Flags := Adapter.Flags or C.unsigned (FLAG_RESTART_NOW);
            else
               Unused := Pm_Schedule_Suspend (Netdev.Dev.Parent, LINK_TIMEOUT);
            end if;
         end if;
      end if;



      <<Link_Up>>

      Spin_Lock (Adapter.Stats64_Lock'Access);
      E1000e_Update_Stats (Adapter);

      Mac.Tx_Packet_Delta := u32 (Adapter.Stats.Tpt - Adapter.Tpt_Old);
      Adapter.Tpt_Old     :=      Adapter.Stats.Tpt;
      Mac.Collision_Delta := u32 (Adapter.Stats.Colc - Adapter.Colc_Old);
      Adapter.Colc_Old    :=      Adapter.Stats.Colc;

      Adapter.Gorc        := u32 (Adapter.Stats.Gorc - Adapter.Gorc_Old);
      Adapter.Gorc_Old    :=      Adapter.Stats.Gorc;
      Adapter.Gotc        := u32 (Adapter.Stats.Gotc - Adapter.Gotc_Old);
      Adapter.Gotc_Old    :=      Adapter.Stats.Gotc;

      Spin_Unlock (Adapter.Stats64_Lock'Access);

      -- If the link is lost the controller stops DMA, but
      -- if there is queued Tx work it cannot be done. So
      -- reset the controller to flush the Tx packet buffers.
      --
      if         not Netif_Carrier_Ok (Netdev)
        and then E1000_Desc_Unused (Tx_Ring) + 1 < u16 (Tx_Ring.Count)
      then
         Adapter.Flags := Adapter.Flags or C.unsigned (FLAG_RESTART_NOW);
      end if;

      -- If reset is necessary, do it outside of interrupt context.
      --
      if (Adapter.Flags and C.unsigned (FLAG_RESTART_NOW)) /= 0
      then
         Schedule_Work (Adapter.Reset_Task'Access);
         -- Return immediately since reset is imminent.
         return;
      end if;


      E1000e_Update_Adaptive (Adapter.Hw'Access);

      -- Simple mode for Interrupt Throttle Rate (ITR).
      --
      if Adapter.Itr_Setting = 4
      then
         declare
            -- Symmetric Tx/Rx gets a reduced ITR=2000;
            -- Total asymmetrical Tx or Rx gets ITR=8000;
            -- everyone else is between 2000-8000.
            --
            Goc : constant Unsigned_32 := (Adapter.Gotc + Adapter.Gorc) / 10000;
            Dif : constant Unsigned_32 := (if Adapter.Gotc > Adapter.Gorc then Adapter.Gotc - Adapter.Gorc
                                                                          else Adapter.Gorc - Adapter.Gotc) / 10000;
            Itr : constant Unsigned_32 := (if Goc > 0 then (Dif * 6000) / Goc + 2000
                                                      else 8000);
         begin
            E1000e_Write_Itr (Adapter, Itr);
         end;
      end if;


      -- Cause software interrupt to ensure Rx ring is cleaned.
      --
      if Adapter.Msix_Entries /= null
      then
         Ew32 (Hw.all, E1000_ICS, Adapter.Rx_Ring.Ims_Val);
      else
         Ew32 (Hw.all, E1000_ICS, E1000_ICS_RXDMT0);
      end if;

      -- Flush pending descriptors to memory before detecting Tx hang.
      --
      E1000e_Flush_Descriptors (Adapter);

      -- Force detection of hung controller every watchdog period.
      --
      Adapter.Detect_Tx_Hung := True;

      -- With 82571 controllers, LAA may be overwritten due to controller
      -- reset from the other port. Set the appropriate LAA in RAR[0].
      --
      if Devices.e1000e.an_82571.E1000e_Get_Laa_State_82571 (Hw)
      then
         Unused := Hw.Mac.Ops.Rar_Set (Hw, Adapter.Hw.Mac.Addr (0)'Access, 0);
      end if;

      if (Adapter.Flags2 and C.unsigned (FLAG2_CHECK_PHY_HANG)) /= 0
      then
         E1000e_Check_82574_Phy_Workaround (Adapter);
      end if;

      -- Clear valid timestamp stuck in RXSTMPL/H due to a Rx error.
      --
      if Adapter.Hwtstamp_Config.Rx_Filter /= HWTSTAMP_FILTER_NONE'enum_Rep
      then
         if    ((Adapter.Flags2 and C.unsigned (FLAG2_CHECK_RX_HWTSTAMP))    /= 0)
           and ((Er32 (Hw.all, E1000_TSYNCRXCTL) and E1000_TSYNCRXCTL_VALID) /= 0)
         then
            Er32 (Hw.all, E1000_RXSTMPH);
            Adapter.Rx_Hwtstamp_Cleared := Adapter.Rx_Hwtstamp_Cleared + 1;
         else
            Adapter.Flags2 := Adapter.Flags2 or C.unsigned (FLAG2_CHECK_RX_HWTSTAMP);
         end if;
      end if;

      -- Reset the timer.
      --
      if not Test_Bit (E1000_DOWN'enum_Rep, Adapter.State'Address)
      then
         Unused3 := Mod_Timer (Adapter.Watchdog_Timer'Access,
                               Round_Jiffies (Jiffies + 2 * HZ));
      end if;
   end E1000_Watchdog_Task;





   E1000_TX_FLAGS_CSUM       : constant := 16#00000001#;
   E1000_TX_FLAGS_VLAN       : constant := 16#00000002#;
   E1000_TX_FLAGS_TSO        : constant := 16#00000004#;
   E1000_TX_FLAGS_IPV4       : constant := 16#00000008#;
   E1000_TX_FLAGS_NO_FCS     : constant := 16#00000010#;
   E1000_TX_FLAGS_HWTSTAMP   : constant := 16#00000020#;
   E1000_TX_FLAGS_VLAN_MASK  : constant := 16#ffff0000#;
   E1000_TX_FLAGS_VLAN_SHIFT : constant := 16;




   ---------------
   -- E1000_TSO --
   ---------------

   function E1000_TSO
     (Tx_Ring  : access E1000_Ring.item;
      Skb      : access Sk_Buff;
      Protocol : in     be16) return C.int
   is
      Context_Desc : access E1000_Context_Desc.item;
      Buffer_Info  :        E1000_Buffer.Pointer;
      I            :        C.unsigned;
      Cmd_Length   :        u32       := 0;
      Ipcse        :        u16       := 0;
      Mss          :        u16;
      Ipcss,
      Ipcso,
      Tucss,
      Tucso,
      Hdr_Len      :        u8;
      Err          :        C.int;

   begin
      if not Skb_Is_Gso (Skb)
      then
         return 0;
      end if;


      Err := Skb_Cow_Head (Skb, 0);

      if Err < 0
      then
         return Err;
      end if;


      Hdr_Len := u8 (Skb_Tcp_All_Headers (Skb));
      Mss     := Skb_Shinfo (Skb).Gso_Size;

      if Protocol = Htons (ETH_P_IP)
      then
         declare
            Iph : constant access Iphdr := Ip_Hdr (Skb);
         begin
            Iph.Tot_Len := be16' (Value => 0);
            Iph.Check   := 0;

            Tcp_Hdr (Skb).Check := not Csum_Tcpudp_Magic (Iph.addrs.Saddr,
                                                          Iph.addrs.Daddr,
                                                          0,
                                                          IPPROTO_TCP'enum_Rep,
                                                          0);
            Cmd_Length := E1000_TXD_CMD_IP;
            Ipcse      := u16 (Skb_Transport_Offset (Skb) - 1);
         end;

      elsif Skb_Is_Gso_V6 (Skb)
      then
         Tcp_V6_Gso_Csum_Prep (Skb);
         Ipcse := 0;
      end if;


      -- TODO:
      raise Program_Error with "TODO";
      --  ipcss := skb_network_offset (skb);
      --  ipcso := (void *)&(ip_hdr(skb)->check) - (void *)skb->data;
      --  tucss := skb_transport_offset(skb);
      --  tucso := (void *)&(tcp_hdr(skb)->check) - (void *)skb->data;

      Cmd_Length := Cmd_Length or u32 (   E1000_TXD_CMD_DEXT
                                       or E1000_TXD_CMD_TSE
                                       or E1000_TXD_CMD_TCP
                                       or C.unsigned (Skb.Len - Natural (Hdr_Len)));

      I            := C.unsigned (Tx_Ring.Next_To_Use);
      Context_Desc := Utility.E1000_CONTEXT_DESC (Tx_Ring.all, Integer (I));
      Buffer_Info  := Tx_Ring.Buffer_Info + C.ptrdiff_t (I);

      Context_Desc.Lower_Setup.Ip_Fields.Ipcss  := Ipcss;
      Context_Desc.Lower_Setup.Ip_Fields.Ipcso  := Ipcso;
      Context_Desc.Lower_Setup.Ip_Fields.Ipcse  := Cpu_To_Le16 (Ipcse);
      Context_Desc.Upper_Setup.Tcp_Fields.Tucss := Tucss;
      Context_Desc.Upper_Setup.Tcp_Fields.Tucso := Tucso;
      Context_Desc.Upper_Setup.Tcp_Fields.Tucse := le16' (Value => 0);
      Context_Desc.Tcp_Seg_Setup.Fields.Mss     := Cpu_To_Le16 (Mss);
      Context_Desc.Tcp_Seg_Setup.Fields.Hdr_Len := Hdr_Len;
      Context_Desc.Cmd_And_Length               := Cpu_To_Le32 (Cmd_Length);

      Buffer_Info.Tx_Rx.Tx.Time_Stamp    := Jiffies;
      Buffer_Info.Tx_Rx.Tx.Next_To_Watch := u16 (I);

      I := I + 1;

      if I = Tx_Ring.Count
      then
         I := 0;
      end if;

      Tx_Ring.Next_To_Use := u16 (I);

      return 1;
   end E1000_TSO;




   -------------------
   -- E1000_Tx_Csum --
   -------------------

   function E1000_Tx_Csum
     (Tx_Ring  : access E1000_Ring.item;
      Skb      : access sk_buff;
      Protocol : in     be16) return Boolean
   is
      Context_Desc  :          access E1000_Context_Desc.item;
      Buffer_Info   :          access E1000_Buffer.item;
      I             :                 C.unsigned;
      Css           :                 u8;
      Cmd_Len       :                 u32 := E1000_TXD_CMD_DEXT;

   begin
      if Skb.Ip_Summed /= CHECKSUM_PARTIAL
      then
         return False;
      end if;


      case Protocol.Value
      is
         when ETH_P_IP =>
            if Ip_Hdr (Skb).Protocol = IPPROTO_TCP'enum_Rep
            then
               Cmd_Len := Cmd_Len or E1000_TXD_CMD_TCP;
            end if;

         when ETH_P_IPV6 =>
            -- XXX not handling all IPV6 headers.
            --
            if Ipv6_Hdr (Skb).Nexthdr = IPPROTO_TCP'enum_Rep
            then
               Cmd_Len := Cmd_Len or E1000_TXD_CMD_TCP;
            end if;

         when others =>
            if Net_Ratelimit /= 0
            then
               e_warn ("checksum_partial proto=" & be16_to_cpu (Protocol)'Image & "!");
            end if;
      end case;


      Css := u8 (Skb_Checksum_Start_Offset (Skb));

      I            := C.unsigned (Tx_Ring.Next_To_Use);
      Buffer_Info  := Tx_Ring.Buffer_Info + C.ptrdiff_t (I);
      Context_Desc := utility.E1000_CONTEXT_DESC (Tx_Ring.all, Integer (I));

      Context_Desc.Lower_Setup.Ip_Config        := le32' (Value => 0);
      Context_Desc.Upper_Setup.Tcp_Fields.Tucss := Css;
      Context_Desc.Upper_Setup.Tcp_Fields.Tucso := Css + Skb.Csum_Offset;
      Context_Desc.Upper_Setup.Tcp_Fields.Tucse := le16' (Value => 0);
      Context_Desc.Tcp_Seg_Setup.Data           := le32' (Value => 0);
      Context_Desc.Cmd_And_Length               := cpu_to_le32 (cmd_len);

      Buffer_Info.Tx_Rx.Tx.Time_Stamp    := jiffies;
      Buffer_Info.Tx_Rx.Tx.Next_To_Watch := u16 (I);

      I := I + 1;

      if I = Tx_Ring.Count
      then
         I := 0;
      end if;

      Tx_Ring.Next_To_Use := u16 (I);

      return True;
   end E1000_Tx_Csum;




   ------------------
   -- E1000_Tx_Map --
   ------------------

   function E1000_Tx_Map
     (Tx_Ring     : access E1000_Ring.item;
      Skb         : access Sk_Buff;
      First       : in     C.unsigned;
      Max_Per_Txd : in     C.unsigned;
      Nr_Frags    : in     C.unsigned) return C.int
   is
      use system.Storage_Elements;

      Adapter       : constant access E1000_Adapter.item := Tx_Ring.Adapter;
      Pdev          : constant access PCI_Dev            := Adapter.Pdev;
      Buffer_Info   :          access E1000_Buffer.item;
      Len           :                 C.unsigned         := C.unsigned (Skb_Headlen (Skb));
      Offset        :                 C.unsigned         := 0;
      Size          :                 C.unsigned;
      Count         :                 C.unsigned         := 0;
      I             :                 C.unsigned;
      F             :                 C.unsigned;
      Bytecount     :                 C.unsigned;
      Segs          :                 C.unsigned;
      Frag          : access          Skb_Frag_T;

   begin
      I := C.unsigned (Tx_Ring.Next_To_Use);

      while Len > 0
      loop
         Buffer_Info := Tx_Ring.Buffer_Info + C.ptrdiff_t (I);
         Size        := C.unsigned'Min (Len, Max_Per_Txd);

         Buffer_Info.Tx_Rx.Tx.Length        := u16 (Size);
         Buffer_Info.Tx_Rx.Tx.Time_Stamp    := Jiffies;
         Buffer_Info.Tx_Rx.Tx.Next_To_Watch := u16 (I);
         Buffer_Info.Dma                    := DMA_Map_Single (Dev    => Pdev.Dev'Access,
                                                               Data   => Skb.Data + Storage_Offset (Offset),
                                                               Size   => C.size_t (Size),
                                                               Dir    => DMA_To_Device);
         Buffer_Info.Tx_Rx.Tx.Mapped_As_Page := 0;

         if DMA_Mapping_Error (Pdev.Dev'Access, Buffer_Info.Dma) /= 0
         then
            goto DMA_Error;
         end if;


         Len    := Len - Size;
         Offset := Offset + Size;
         Count  := Count + 1;

         if Len > 0
         then
            I := I + 1;

            if I = Tx_Ring.Count
            then
               I := 0;
            end if;
         end if;

      end loop;


      for F in 0 .. C.size_t (Nr_Frags) - 1
      loop
         Frag   := Skb_Shinfo (Skb).Frags (F)'unchecked_Access;
         Len    := Skb_Frag_Size (Frag);
         Offset := 0;

         while Len > 0
         loop
            I := I + 1;

            if I = Tx_Ring.Count
            then
               I := 0;
            end if;

            Buffer_Info := Tx_Ring.Buffer_Info + C.ptrdiff_t (I);
            Size        := Interfaces.C.unsigned'Min (Len, Max_Per_Txd);

            Buffer_Info.Tx_Rx.Tx.Length        := u16 (Size);
            Buffer_Info.Tx_Rx.Tx.Time_Stamp    := Jiffies;
            Buffer_Info.Tx_Rx.Tx.Next_To_Watch := u16 (I);
            Buffer_Info.Dma                    := Skb_Frag_Dma_Map (Dev    => Pdev.Dev'Access,
                                                                    Frag   => Frag,
                                                                    Offset => C.size_t (Offset),
                                                                    Size   => C.size_t (Size),
                                                                    Dir    => DMA_To_Device);
            Buffer_Info.Tx_Rx.Tx.Mapped_As_Page := 1;

            if DMA_Mapping_Error (Pdev.Dev'Access, Buffer_Info.Dma) /= 0
            then
               goto DMA_Error;
            end if;


            Len    := Len - Size;
            Offset := Offset + Size;
            Count  := Count + 1;
         end loop;
      end loop;


      Segs      := (if Skb_Shinfo (Skb).Gso_Segs = 0 then 1
                                                     else C.unsigned (Skb_Shinfo (Skb).Gso_Segs));
      Bytecount :=   ((Segs - 1) * C.unsigned (Skb_Headlen (Skb)))
                   + C.unsigned (Skb.Len);

      declare
         buff_Info_i     : constant e1000_buffer.Pointer := Tx_Ring.Buffer_Info + C.ptrdiff_t (i);
         buff_Info_first : constant e1000_buffer.Pointer := Tx_Ring.Buffer_Info + C.ptrdiff_t (First);
      begin
         buff_Info_i.Skb                        := Skb;
         buff_Info_i.Tx_Rx.Tx.Segs              := Segs;
         buff_Info_i.Tx_Rx.Tx.Bytecount         := Bytecount;
         buff_Info_first.Tx_Rx.Tx.Next_To_Watch := u16 (i);
      end;

      return Interfaces.C.int (Count);


      <<DMA_Error>>

      dev_err (pdev.dev'Access, "Tx DMA map failed");

      Buffer_Info.Dma := 0;

      if Count > 0
      then
         Count := Count - 1;
      end if;

      while Count > 0
      loop
         if I = 0
         then
            I := I + Tx_Ring.Count;
         end if;

         I           := I - 1;
         Buffer_Info := Tx_Ring.Buffer_Info + C.ptrdiff_t (I);
         E1000_Put_Txbuf (Tx_Ring, Buffer_Info, True);
         Count       := Count - 1;
      end loop;

      return 0;
   end E1000_Tx_Map;




   --------------------
   -- E1000_Tx_Queue --
   --------------------

   procedure E1000_Tx_Queue
     (Tx_Ring  : access E1000_Ring.item;
      Tx_Flags : in     C.unsigned;
      Count    : in     C.int)
   is
      Adapter      : constant access E1000_Adapter.item := Tx_Ring.Adapter;
      Tx_Desc      :          access E1000_Tx_Desc.item := null;
      Buffer_Info  :          access E1000_Buffer.item;
      Txd_Upper    :                 Unsigned_32        := 0;
      Txd_Lower    :                 Unsigned_32        := E1000_TXD_CMD_IFCS;
      I            :                 C.unsigned;

   begin
      if (Tx_Flags and E1000_TX_FLAGS_TSO) /= 0
      then
         Txd_Lower := Txd_Lower or E1000_TXD_CMD_DEXT or E1000_TXD_DTYP_D or E1000_TXD_CMD_TSE;
         Txd_Upper := Txd_Upper or Interfaces.Shift_Left (E1000_TXD_POPTS_TXSM, 8);

         if (Tx_Flags and E1000_TX_FLAGS_IPV4) /= 0
         then
            Txd_Upper := Txd_Upper or Interfaces.Shift_Left (E1000_TXD_POPTS_IXSM, 8);
         end if;
      end if;

      if (Tx_Flags and E1000_TX_FLAGS_CSUM) /= 0
      then
         Txd_Lower := Txd_Lower or E1000_TXD_CMD_DEXT or E1000_TXD_DTYP_D;
         Txd_Upper := Txd_Upper or Interfaces.Shift_Left (E1000_TXD_POPTS_TXSM, 8);
      end if;

      if (Tx_Flags and E1000_TX_FLAGS_VLAN) /= 0
      then
         Txd_Lower := Txd_Lower or E1000_TXD_CMD_VLE;
         Txd_Upper := Txd_Upper or u32 (Tx_Flags and E1000_TX_FLAGS_VLAN_MASK);
      end if;

      if (Tx_Flags and E1000_TX_FLAGS_NO_FCS) /= 0
      then
         Txd_Lower := Txd_Lower and (not E1000_TXD_CMD_IFCS);
      end if;

      if (Tx_Flags and E1000_TX_FLAGS_HWTSTAMP) /= 0
      then
         Txd_Lower := Txd_Lower or E1000_TXD_CMD_DEXT or E1000_TXD_DTYP_D;
         Txd_Upper := Txd_Upper or E1000_TXD_EXTCMD_TSTAMP;
      end if;

      I := C.unsigned (Tx_Ring.Next_To_Use);


      for J in 1 .. Count
      loop
         Buffer_Info         := Tx_Ring.Buffer_Info + C.ptrdiff_t (I);
         Tx_Desc             := utility.E1000_TX_DESC (Tx_Ring.all, Integer (I));
         Tx_Desc.Buffer_Addr := le64' (Value => Buffer_Info.Dma);
         Tx_Desc.Lower.Data  := le32' (Value => Txd_Lower or u32 (Buffer_Info.Tx_Rx.Tx.Length));
         Tx_Desc.Upper.Data  := le32' (Value => Txd_Upper);

         I := I + 1;

         if I = Tx_Ring.Count
         then
            I := 0;
         end if;
      end loop;


      Tx_Desc.Lower.Data := le32' (Value => Tx_Desc.Lower.Data.Value or Adapter.Txd_Cmd);

      -- 'txd_cmd' re-enables FCS, so we'll re-disable it here as desired.
      --
      if unlikely ((Tx_Flags and E1000_TX_FLAGS_NO_FCS) /= 0)
      then
         Tx_Desc.Lower.Data := le32' (Value => Tx_Desc.Lower.Data.Value and (not E1000_TXD_CMD_IFCS));
      end if;

      -- Force memory writes to complete before letting h/w
      -- know there are new descriptors to fetch.  (Only
      -- applicable for weak-ordered memory model archs,
      -- such as IA-64).
      --
      wmb;

      Tx_Ring.Next_To_Use := u16 (I);
   end E1000_Tx_Queue;




   MINIMUM_DHCP_PACKET_SIZE : constant := 282;


   ------------------------------
   -- E1000_Transfer_DHCP_Info --
   ------------------------------

   function E1000_Transfer_DHCP_Info
     (Adapter : access E1000_Adapter.item;
      Skb     : access SK_Buff) return C.int
   is
      use Devices.e1000e.Core.Pointers,
          system.Storage_Elements;

      Hw     : constant access E1000_HW := Adapter.Hw'Access;
      Length :                 u16;
      Offset :                 u16;

   begin
      if         Skb_VLAN_Tag_Present (Skb)
        and then not ((    Skb_VLAN_Tag_Get (Skb) = Adapter.Hw.Mng_Cookie.VLAN_ID)
                      and (Adapter.Hw.Mng_Cookie.Status and Devices.e1000e.Manage.E1000_MNG_DHCP_COOKIE_STATUS_VLAN) /= 0)
      then
         return 0;
      end if;


      if Skb.Len <= MINIMUM_DHCP_PACKET_SIZE
      then
         return 0;
      end if;


      declare
         Eth_Hdr : EthHdr
           with
             Address => Skb.Data;
      begin
         if Eth_Hdr.H_Proto /= htons (ETH_P_IP)
         then
            return 0;
         end if;
      end;


      declare
         IP : IPHdr
           with
             Address => Skb.Data + 14;
      begin
         if IP.Protocol /= IPPROTO_UDP'enum_Rep
         then
            return 0;
         end if;

         declare
            use u8_Conversions;

            UDP : UDPHdr
              with
                Address => IP'Address + Storage_Offset (IP.ihl * 4);
         begin
            if ntohs (u16 (UDP.Dest.Value)) /= 67
            then
               return 0;
            end if;


            Offset := u16 (UDP'Address + 8 - Skb.Data'Address);
            Length := u16 (Skb.Len) - Offset;

            return C.int (Devices.e1000e.Manage.E1000e_Mng_Write_DHCP_Info (Hw,
                                                             u8_Pointer (to_Pointer (UDP'Address + 8)),
                                                             Length));
         end;
      end;
   end E1000_Transfer_DHCP_Info;




   -------------------
   -- Maybe_Stop_Tx --
   -------------------

   function Maybe_Stop_Tx
     (Tx_Ring : access E1000_Ring.item;
      Size    : in     C.int) return Integer
   is
      Adapter : constant access E1000_Adapter.item := Tx_Ring.Adapter;
      Netdev  : constant access Net_Device         := Adapter.Netdev;

   begin
      netif_stop_queue (Netdev);

      -- Herbert's original patch had:
      --  *  smp_mb__after_netif_stop_queue();
      --  * but since that doesn't exist yet, just open code it.
      --
      smp_mb;

      -- We need to check again in case another CPU has just made room available.
      --
      if E1000_Desc_Unused (Tx_Ring) < u16 (Size)
      then
         return -EBUSY;
      end if;

      -- A reprieve!
      --
      netif_start_queue (adapter.netdev);
      Adapter.Restart_Queue := Adapter.Restart_Queue + 1;

      return 0;
   end Maybe_Stop_Tx;




   -------------------------
   -- E1000_Maybe_Stop_Tx --
   -------------------------

   function E1000_Maybe_Stop_Tx
     (Tx_Ring : access E1000_Ring.item;
      Size    : in     C.int) return Integer
   is
   begin
      if C.unsigned (size) > tx_ring.count
      then
         raise Program_Error;
      end if;


      if E1000_Desc_Unused (Tx_Ring) >= u16 (Size)
      then
         return 0;
      end if;

      return Maybe_Stop_Tx (Tx_Ring, Size);
   end E1000_Maybe_Stop_Tx;




   ----------------------
   -- E1000_Xmit_Frame --
   ----------------------

   function E1000_Xmit_Frame
     (Skb    : access Sk_Buff;
      Netdev : access Net_Device) return Netdev_Tx_T
   is
      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev);

      Tx_Ring  : constant access E1000_Ring.item := Adapter.Tx_Ring;
      First    :                 C.unsigned;
      Tx_Flags :                 Unsigned_32     := 0;
      Len      :                 C.unsigned      := C.unsigned (Skb_Headlen (Skb));
      Nr_Frags :                 C.unsigned;
      Mss      :                 C.unsigned;
      Count    :                 C.int           := 0;
      Tso      :                 C.int;
      F        :                 Unsigned_32;
      Protocol : constant        be16            := vlan_get_protocol (skb);
      Unused   :                 C.int;
      Unused2  :                 Integer;

   begin
      if Test_Bit (E1000_Down'enum_Rep, Adapter.State'Address)
      then
         Dev_Kfree_Skb_Any (Skb);
         return NETDEV_TX_OK;
      end if;


      if Skb.Len <= 0
      then
         Dev_Kfree_Skb_Any (Skb);
         return NETDEV_TX_OK;
      end if;


      -- The minimum packet size with TCTL.PSP set is 17 bytes so
      -- pad skb in order to meet this minimum size requirement.
      --
      if Skb_Put_Padto (Skb, 17) /= 0
      then
         return NETDEV_TX_OK;
      end if;


      Mss := C.unsigned (Skb_Shinfo (Skb).Gso_Size);

      if Mss /= 0
      then
         declare
            Hdr_Len : Unsigned_8;
         begin
            -- TSO Workaround for 82571/2/3 Controllers -- if skb->data
            -- points to just header, pull a few bytes of payload from
            -- frags into skb->data.
            --
            Hdr_Len := u8 (Skb_Tcp_All_Headers (Skb));

            -- We do this workaround for ES2LAN, but it is unnecessary,
            -- avoiding it could save a lot of cycles.
            --
            if    Skb.Data_Len /= 0
              and Hdr_Len       = u8 (Len)
            then
               declare
                  use type system.Address;
                  Pull_Size : Unsigned_32;
               begin
                  Pull_Size := Unsigned_32'Min (4, Skb.Data_Len);

                  if Pskb_Pull_Tail (Skb, C.int (Pull_Size)) = system.Null_Address
                  then
                     e_err ("pskb_pull_tail failed.");
                     Dev_Kfree_Skb_Any (Skb);

                     return NETDEV_TX_OK;
                  end if;

                  Len := C.unsigned (Skb_Headlen (Skb));
               end;
            end if;
         end;
      end if;


      -- Reserve a descriptor for the offload context.
      --
      if Mss /= 0 or Skb.Ip_Summed = CHECKSUM_PARTIAL
      then
         Count := Count + 1;
      end if;

      Count := Count + 1;
      Count := Count + DIV_ROUND_UP (C.int (len),
                                     C.int (adapter.tx_fifo_limit));

      Nr_Frags := C.unsigned (Skb_Shinfo (Skb).Nr_Frags);

      for F in 0 .. C.size_t (Nr_Frags) - 1
      loop
         Count := Count + DIV_ROUND_UP (C.int (skb_frag_size (skb_shinfo (skb).frags (f)'Access)),
                                        C.int (adapter.tx_fifo_limit));
      end loop;

      if Adapter.Hw.Mac.Tx_Pkt_Filtering
      then
         Unused := E1000_Transfer_Dhcp_Info (Adapter'Access, Skb);
      end if;

      -- Need: count + 2 desc gap to keep tail from touching
      -- head, otherwise try next time.
      --
      if E1000_Maybe_Stop_Tx (Tx_Ring, Count + 2) /= 0
      then
         return NETDEV_TX_BUSY;
      end if;


      if Skb_Vlan_Tag_Present (Skb)
      then
         Tx_Flags := Tx_Flags or E1000_TX_FLAGS_VLAN;
         Tx_Flags := Tx_Flags or shift_Left (Unsigned_32 (Skb_Vlan_Tag_Get (Skb)),
                                             E1000_TX_FLAGS_VLAN_SHIFT);
      end if;

      First := C.unsigned (Tx_Ring.Next_To_Use);
      Tso   := E1000_Tso (Tx_Ring, Skb, Protocol);

      if Tso < 0
      then
         Dev_Kfree_Skb_Any (Skb);
         return NETDEV_TX_OK;
      end if;


      if Tso /= 0
      then
         Tx_Flags := Tx_Flags or E1000_TX_FLAGS_TSO;

      elsif E1000_Tx_Csum (Tx_Ring, Skb, Protocol)
      then
         Tx_Flags := Tx_Flags or E1000_TX_FLAGS_CSUM;
      end if;


      -- Old method was to assume IPv4 packet by default if TSO was enabled.
      -- 82571 hardware supports TSO capabilities for IPv6 as well ...
      -- no longer assume, we must.
      --
      if Protocol = htons (ETH_P_IP)
      then
         Tx_Flags := Tx_Flags or E1000_TX_FLAGS_IPV4;
      end if;

      if Skb.No_Fcs
      then
         Tx_Flags := Tx_Flags or E1000_TX_FLAGS_NO_FCS;
      end if;


      -- If count is 0 then mapping error has occurred.
      --
      Count := E1000_Tx_Map (Tx_Ring,
                             Skb,
                             First,
                             C.unsigned (Adapter.Tx_Fifo_Limit),
                             Nr_Frags);
      if Count /= 0
      then
         if    (Skb_Shinfo (Skb).Tx_Flags and SKBTX_HW_TSTAMP'enum_Rep) /= 0
           and (Adapter.Flags and C.unsigned (FLAG_HAS_HW_TIMESTAMP))   /= 0
         then
            if Adapter.Tx_Hwtstamp_Skb = null
            then
               Skb_Shinfo (Skb).Tx_Flags := Skb_Shinfo (Skb).Tx_Flags or SKBTX_IN_PROGRESS'enum_Rep;
               Tx_Flags                  := Tx_Flags or E1000_TX_FLAGS_HWTSTAMP;
               Adapter.Tx_Hwtstamp_Skb   := Skb_Get (Skb);
               Adapter.Tx_Hwtstamp_Start := Jiffies;

               Schedule_Work (Adapter.Tx_Hwtstamp_Work'Access);
            else
               Adapter.Tx_Hwtstamp_Skipped := Adapter.Tx_Hwtstamp_Skipped + 1;
            end if;
         end if;

         Skb_Tx_Timestamp (Skb);

         Netdev_Sent_Queue (Netdev, C.unsigned (Skb.Len));
         E1000_Tx_Queue (Tx_Ring,
                         C.unsigned (Tx_Flags),
                         Count);

         -- Make sure there is space in the ring for the next send.
         --
         Unused2 := E1000_Maybe_Stop_Tx (Tx_Ring,
                                         C.int ((  (MAX_SKB_FRAGS + 1)
                                                 *   ((PAGE_SIZE + Adapter.Tx_Fifo_Limit - 1)
                                                   / Adapter.Tx_Fifo_Limit)
                                                 + 4)));

         if        not Netdev_Xmit_More
           or else Netif_Xmit_Stopped (Netdev_Get_Tx_Queue (Netdev, 0))
         then
            if (Adapter.Flags2 and C.unsigned (FLAG2_PCIM2PCI_ARBITER_WA)) /= 0
            then
               E1000e_Update_Tdt_Wa (Tx_Ring, u32 (Tx_Ring.Next_To_Use));
            else
               Writel (u32 (Tx_Ring.Next_To_Use), Tx_Ring.Tail);
            end if;
         end if;

      else
         Dev_Kfree_Skb_Any (Skb);
         E1000_Buffer.Pointer' (Tx_Ring.Buffer_Info + C.ptrdiff_t (First)).Tx_Rx.Tx.Time_Stamp := 0;
         Tx_Ring.Next_To_Use := u16 (First);
      end if;


      return NETDEV_TX_OK;
   end E1000_Xmit_Frame;




   ----------------------
   -- E1000_Tx_Timeout --
   ----------------------

   --  Respond to a Tx Hang
   --  * @netdev:  Network interface device structure.
   --  * @txqueue: Index of the hung queue (unused).


   procedure E1000_Tx_Timeout
     (Netdev   : access Net_Device;
      Txqueue  : in     C.unsigned)
   is
      Adapter : E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev);
   begin
      -- Do the reset outside of interrupt context.
      --
      Adapter.Tx_Timeout_Count := Adapter.Tx_Timeout_Count + 1;
      Schedule_Work (Adapter.Reset_Task'Access);
   end E1000_Tx_Timeout;




   ----------------------
   -- E1000_Reset_Task --
   ----------------------

   procedure E1000_Reset_Task
     (Work : access Work_Struct)
   is
      Adapter  : constant E1000_Adapter.Pointer := E1000_Adapter.Pointer (E1000_Adapter_Conversions.to_Pointer (container_of (Work.all'Address)));
                                                                                                            --, struct e1000_adapter, reset_task);
   begin
      RTNL_Lock;

      -- Don't run the task if already down.
      --
      if test_bit (E1000_DOWN'enum_Rep, adapter.state'Address)
      then
         RTNL_Unlock;
         return;
      end if;


      if (Adapter.Flags and C.unsigned (FLAG_RESTART_NOW)) = 0
      then
         E1000e_Dump (Adapter);
         e_err ("Reset adapter unexpectedly");
      end if;

      E1000e_Reinit_Locked (Adapter);
      RTNL_Unlock;
   end E1000_Reset_Task;




   ------------------------
   -- E1000e_Get_Stats64 --
   ------------------------

   --    Get System Network Statistics.
   --
   --  * @netdev: Network interface device structure.
   --  * @stats:  Rtnl_link_stats64 pointer.
   --  *
   --  * Returns the address of the device statistics structure.


   procedure E1000e_Get_Stats64
     (Netdev : access Net_Device;
      Stats  : access RTNL_Link_Stats64)
   is
      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev);
   begin
      Spin_Lock (Adapter.Stats64_Lock'Access);
      E1000e_Update_Stats (Adapter'Access);

      -- Fill out the OS statistics structure.
      --
      Stats.Rx_Bytes   := Adapter.Stats.Gorc;
      Stats.Rx_Packets := Adapter.Stats.Gprc;
      Stats.Tx_Bytes   := Adapter.Stats.Gotc;
      Stats.Tx_Packets := Adapter.Stats.Gptc;
      Stats.Multicast  := Adapter.Stats.Mprc;
      Stats.Collisions := Adapter.Stats.Colc;

      -- Rx Errors.
      --

      -- RLEC on some newer hardware can be incorrect so build
      -- our own version based on RUC and ROC.
      --
      Stats.Rx_Errors :=   Adapter.Stats.Rxerrc
                         + Adapter.Stats.Crcerrs
                         + Adapter.Stats.Algnerrc
                         + Adapter.Stats.Ruc
                         + Adapter.Stats.Roc
                         + Adapter.Stats.Cexterr;

      Stats.Rx_Length_Errors := Adapter.Stats.Ruc + Adapter.Stats.Roc;
      Stats.Rx_Crc_Errors    := Adapter.Stats.Crcerrs;
      Stats.Rx_Frame_Errors  := Adapter.Stats.Algnerrc;
      Stats.Rx_Missed_Errors := Adapter.Stats.Mpc;

      -- Tx Errors.
      --
      Stats.Tx_Errors         := Adapter.Stats.Ecol + Adapter.Stats.Latecol;
      Stats.Tx_Aborted_Errors := Adapter.Stats.Ecol;
      Stats.Tx_Window_Errors  := Adapter.Stats.Latecol;
      Stats.Tx_Carrier_Errors := Adapter.Stats.Tncrs;

      -- Tx Dropped needs to be maintained elsewhere.
      --
      Spin_Unlock (Adapter.Stats64_Lock'Access);
   end E1000e_Get_Stats64;




   ----------------------
   -- E1000_Change_MTU --
   ----------------------

   --    Change the Maximum Transfer Unit.
   --
   --  * @netdev:  Network interface device structure.
   --  * @new_mtu: New value for maximum frame size.
   --  *
   --  * Returns 0 on success, negative on failure


   function E1000_Change_MTU
     (Netdev  : access Net_Device;
      New_MTU : in     C.int) return C.int
   is
      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev);

      Max_Frame : constant C.int := C.int (New_MTU + VLAN_ETH_HLEN + ETH_FCS_LEN);
      Unused    :          C.int;

   begin
      -- Jumbo frame support.
      --
      if          New_MTU > ETH_DATA_LEN
        and then (Adapter.Flags and C.unsigned (FLAG_HAS_JUMBO_FRAMES)) = 0
      then
         e_err ("Jumbo Frames not supported.");
         return -EINVAL;
      end if;


      -- Jumbo frame workaround on 82579 and newer requires CRC be stripped.
      --
      if          Adapter.Hw.Mac.Mac_Type >= E1000_PCH2LAN
        and then (Adapter.Flags2 and C.unsigned (FLAG2_CRC_STRIPPING)) = 0
        and then  New_MTU > ETH_DATA_LEN
      then
         e_dbg ("Jumbo Frames not supported on this device when CRC stripping is disabled.");
         return -EINVAL;
      end if;


      while Test_And_Set_Bit (E1000_RESETTING'enum_Rep, Adapter.State'Access)
      loop
         delay 1_050.0 * Microseconds;
      end loop;

      -- e1000e_down -> e1000e_reset dependent on max_frame_size & mtu.
      --
      Adapter.Max_Frame_Size := u32 (Max_Frame);
      netdev_dbg (netdev, "changing MTU from" & Netdev.MTU'Image & " to" & New_MTU'Image);
      WRITE_ONCE (netdev.mtu, C.unsigned (new_mtu));

      Unused := PM_Runtime_Get_Sync (Netdev.Dev.Parent);

      if Netif_Running (Netdev)
      then
         E1000e_Down (Adapter'Access, True);
      end if;

      -- NOTE: 'netdev_alloc_skb' reserves 16 bytes, and typically NET_IP_ALIGN
      -- means we reserve 2 more, this pushes us to allocate from the next
      -- larger slab size.
      -- i.e. RXBUFFER_2048 --> size-4096 slab
      -- However with the new *_jumbo_rx* routines, jumbo receives will use
      -- fragmented skbs.
      --

      if Max_Frame <= 2048
      then
         Adapter.Rx_Buffer_Len := 2048;
      else
         Adapter.Rx_Buffer_Len := 4096;
      end if;

      -- Adjust allocation if LPE protects us, and we aren't using SBP.
      --
      if Max_Frame <= (VLAN_ETH_FRAME_LEN + ETH_FCS_LEN)
      then
         Adapter.Rx_Buffer_Len := VLAN_ETH_FRAME_LEN + ETH_FCS_LEN;
      end if;

      if Netif_Running (Netdev)
      then
         E1000e_Up (Adapter'Access);
      else
         E1000e_Reset (Adapter'Access);
      end if;

      Unused := PM_Runtime_Put_Sync (Netdev.Dev.Parent);

      clear_bit (E1000_RESETTING'enum_Rep, Adapter.State'Address);

      return 0;
   end E1000_Change_MTU;




   ---------------------
   -- E1000_Mii_Ioctl --
   ---------------------

   function E1000_Mii_Ioctl
     (Netdev : access Net_Device;
      Ifr    : access Ifreq;
      Cmd    : in     Integer) return Integer
   is
      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev);

      Data : constant access Mii_Ioctl_Data := If_Mii (Ifr);

   begin
      if Adapter.Hw.Phy.Media_Type /= E1000_Media_Type_Copper
      then
         return -EOPNOTSUPP;
      end if;


      case Cmd
      is
      when SIOCGMIIPHY =>
         Data.Phy_Id := u16 (Adapter.Hw.Phy.Addr);

      when SIOCGMIIREG =>
         E1000_Phy_Read_Status (Adapter'Access);

         case Data.Reg_Num and 16#1F#
         is
            when MII_BMCR      =>   Data.Val_Out := Adapter.Phy_Regs.Bmcr;
            when MII_BMSR      =>   Data.Val_Out := Adapter.Phy_Regs.Bmsr;
            when MII_PHYSID1   =>   Data.Val_Out := u16 (shift_Right (Adapter.Hw.Phy.Id, 16));
            when MII_PHYSID2   =>   Data.Val_Out := u16 (Adapter.Hw.Phy.Id and 16#FFFF#);
            when MII_ADVERTISE =>   Data.Val_Out := Adapter.Phy_Regs.Advertise;
            when MII_LPA       =>   Data.Val_Out := Adapter.Phy_Regs.Lpa;
            when MII_EXPANSION =>   Data.Val_Out := Adapter.Phy_Regs.Expansion;
            when MII_CTRL1000  =>   Data.Val_Out := Adapter.Phy_Regs.Ctrl1000;
            when MII_STAT1000  =>   Data.Val_Out := Adapter.Phy_Regs.Stat1000;
            when MII_ESTATUS   =>   Data.Val_Out := Adapter.Phy_Regs.Estatus;
            when others        =>   return -EIO;
         end case;

      when SIOCSMIIREG =>
         return -EOPNOTSUPP;

      when others =>
         return -EOPNOTSUPP;
      end case;

      return 0;
   end E1000_Mii_Ioctl;




   -------------------------
   -- E1000e_Hwtstamp_Set --
   -------------------------

   --    Control hardware time stamping.
   --
   --  * @netdev: Network interface device structure.
   --  * @ifr:    Interface request.
   --  *
   --  * Outgoing time stamping can be enabled and disabled. Play nice and
   --  * disable it when requested, although it shouldn't cause any overhead
   --  * when no packet needs it. At most one packet in the queue may be
   --  * marked for time stamping, otherwise it would be impossible to tell
   --  * for sure to which packet the hardware time stamp belongs.
   --  *
   --  * Incoming time stamping has to be configured via the hardware filters.
   --  * Not all combinations are supported, in particular event type has to be
   --  * specified. Matching the kind of event packet is not supported, with the
   --  * exception of "all V2 events regardless of level 2 or 4".


   function E1000e_Hwtstamp_Set
     (Netdev : access Net_Device;
      Ifr    : access Ifreq) return C.int
   is
      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev);

      Config  : aliased Hwtstamp_Config;
      Ret_Val :         C.int;

   begin
      if copy_from_user (config'Address, ifr.ifr_data, config'Size / 8) /= 0
      then
         return -EFAULT;
      end if;


      Ret_Val := C.int (E1000e_Config_Hwtstamp (Adapter'Access, Config'Access));

      if Ret_Val /= 0
      then
         return Ret_Val;
      end if;


      case Config.Rx_Filter
      is
         when HWTSTAMP_FILTER_PTP_V2_L4_SYNC     'enum_Rep
            | HWTSTAMP_FILTER_PTP_V2_L2_SYNC     'enum_Rep
            | HWTSTAMP_FILTER_PTP_V2_SYNC        'enum_Rep
            | HWTSTAMP_FILTER_PTP_V2_L4_DELAY_REQ'enum_Rep
            | HWTSTAMP_FILTER_PTP_V2_L2_DELAY_REQ'enum_Rep
            | HWTSTAMP_FILTER_PTP_V2_DELAY_REQ   'enum_Rep =>

            -- With V2 type filters which specify a Sync or Delay Request,
            -- Path Delay Request/Response messages are also time stamped
            -- by hardware so notify the caller the requested packets plus
            -- some others are time stamped.
            --
            Config.Rx_Filter := HWTSTAMP_FILTER_SOME'enum_Rep;

         when others =>
            null;
      end case;


      if Copy_To_User (ifr.ifr_data,
                       adapter.hwtstamp_config'Address,
                       adapter.hwtstamp_config'Size / 8)
        /= 0
      then
         return -EFAULT;
      else
         return 0;
      end if;
   end E1000e_Hwtstamp_Set;




   -------------------------
   -- E1000e_Hwtstamp_Get --
   -------------------------

   function E1000e_Hwtstamp_Get
     (Netdev : access Net_Device;
      Ifr    : access Ifreq) return C.int
   is
      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev);

   begin
      if copy_to_user (ifr.ifr_data, adapter.hwtstamp_config'Address,
                       adapter.hwtstamp_config'Size / 8)
        /= 0
      then
         return -EFAULT;
      else
         return 0;
      end if;
   end E1000e_Hwtstamp_Get;




   -----------------
   -- E1000_Ioctl --
   -----------------

   function E1000_Ioctl
     (Netdev : access Net_Device;
      Ifr    : access Ifreq;
      Cmd    : in     C.int) return C.int
   is
   begin
      case Cmd
      is
         when SIOCGMIIPHY
            | SIOCGMIIREG
            | SIOCSMIIREG   => return C.int (E1000_Mii_Ioctl (Netdev, Ifr, Integer (Cmd)));

         when SIOCSHWTSTAMP => return E1000e_Hwtstamp_Set (Netdev, Ifr);

         when SIOCGHWTSTAMP => return E1000e_Hwtstamp_Get (Netdev, Ifr);

         when others        => return -EOPNOTSUPP;
      end case;
   end E1000_Ioctl;




   ---------------------------
   -- E1000_Init_Phy_Wakeup --
   ---------------------------

   function E1000_Init_Phy_Wakeup
     (Adapter : access E1000_Adapter.item;
      WUFC    : in     Unsigned_32) return C.int
   is
      use Devices.e1000e.Ich8Lan;

      HW         : constant access  E1000_HW   := Adapter.HW'Access;
      I          :                  Unsigned_32;
      Mac_Reg,
      WUC        :                 Unsigned_32;
      Phy_Reg,
      WUC_Enable : aliased         Unsigned_16;
      Retval     :                 C.int;
      Unused     :                 s32;

   begin
      -- Copy MAC RARs to PHY RARs.
      --
      Devices.e1000e.Ich8Lan.E1000_Copy_Rx_Addrs_To_Phy_Ich8lan (HW);

      Retval := C.int (HW.Phy.Ops.Acquire (HW));

      if Retval /= 0
      then
         e_err ("Could not acquire PHY");
         return Retval;
      end if;


      -- Enable access to wakeup registers on and set page to BM_WUC_PAGE.
      --
      Retval := C.int (Devices.e1000e.Physical_Layer.E1000_Enable_Phy_Wakeup_Reg_Access_Bm (HW, WUC_Enable'unchecked_Access));

      if Retval /= 0
      then
         goto Release;
      end if;


      -- Copy MAC MTA to PHY MTA - only needed for pchlan.
      --
      for I in 0 .. u32 (Adapter.HW.Mac.Mta_Reg_Count) - 1
      loop
         Mac_Reg := E1000_Read_Reg_Array (HW, E1000_MTA, I);

         Unused := HW.Phy.Ops.Write_Reg_Page (HW, BM_MTA (I),     Unsigned_16 (Mac_Reg                   and 16#FFFF#));
         Unused := HW.Phy.Ops.Write_Reg_Page (HW, BM_MTA (I) + 1, Unsigned_16 (shift_Right (Mac_Reg, 16) and 16#FFFF#));
      end loop;

      -- Configure PHY Rx Control register.
      --
      Unused := HW.Phy.Ops.Read_Reg_Page (Adapter.HW'Access, BM_RCTL, Phy_Reg'unchecked_Access);

      Mac_Reg := Er32 (Hw.all, E1000_RCTL);

      if (Mac_Reg and E1000_RCTL_UPE) /= 0
      then
         Phy_Reg := Phy_Reg or BM_RCTL_UPE;
      end if;

      if (Mac_Reg and E1000_RCTL_MPE) /= 0
      then
         Phy_Reg := Phy_Reg or BM_RCTL_MPE;
      end if;

      Phy_Reg := Phy_Reg and (not u16 (BM_RCTL_MO_MASK));

      if (Mac_Reg and E1000_RCTL_MO_3) /= 0
      then
         Phy_Reg := Phy_Reg or u16 (shift_Left (Field_Get (E1000_RCTL_MO_3, Mac_Reg),
                                                BM_RCTL_MO_SHIFT));
      end if;

      if (Mac_Reg and E1000_RCTL_BAM) /= 0
      then
         Phy_Reg := Phy_Reg or BM_RCTL_BAM;
      end if;

      if (Mac_Reg and E1000_RCTL_PMCF) /= 0
      then
         Phy_Reg := Phy_Reg or BM_RCTL_PMCF;
      end if;

      Mac_Reg := Er32 (Hw.all, E1000_CTRL);

      if (Mac_Reg and E1000_CTRL_RFCE) /= 0
      then
         Phy_Reg := Phy_Reg or BM_RCTL_RFCE;
      end if;

      Unused := HW.Phy.Ops.Write_Reg_Page (Adapter.HW'Access, BM_RCTL, Phy_Reg);

      WUC := E1000_WUC_PME_EN;

      if (WUFC and (E1000_WUFC_MAG or E1000_WUFC_LNKC)) /= 0
      then
         WUC := WUC or E1000_WUC_APME;
      end if;

      -- Enable PHY wakeup in MAC register.
      --
      Ew32 (Hw.all, E1000_WUFC, WUFC);
      Ew32 (Hw.all, E1000_WUC,    E1000_WUC_PHY_WAKE
                 or E1000_WUC_APMPME
                 or E1000_WUC_PME_STATUS
                 or WUC);

      -- Configure and enable PHY wakeup in PHY registers.
      --
      Unused := HW.Phy.Ops.Write_Reg_Page (Adapter.HW'Access, BM_WUFC, u16 (WUFC));
      Unused := HW.Phy.Ops.Write_Reg_Page (Adapter.HW'Access, BM_WUC,  u16 (WUC));

      -- Activate PHY wakeup.
      --
      WUC_Enable := WUC_Enable or Devices.e1000e.Physical_Layer.BM_WUC_ENABLE_BIT or Devices.e1000e.Physical_Layer.BM_WUC_HOST_WU_BIT;
      Retval     := C.int (Devices.e1000e.Physical_Layer.E1000_Disable_Phy_Wakeup_Reg_Access_Bm (HW, WUC_Enable'unchecked_Access));

      if Retval /= 0
      then
         e_err ("Could not set PHY Host Wakeup bit");
      end if;


      <<Release>>

      HW.Phy.Ops.Release (HW);
      return Retval;
   end E1000_Init_Phy_Wakeup;




   -----------------------
   -- E1000e_Flush_Lpic --
   -----------------------

   procedure E1000e_Flush_Lpic
     (Pdev : access PCI_Dev)
   is
      Netdev  : aliased Net_Device
        with
          Import,
          Address => PCI_Get_Drvdata (Pdev);

      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev'Access);

      Hw      : constant access E1000_HW           := Adapter.Hw'Access;
      Ret_Val :                 C.unsigned;
      Unused  :                 C.int;

   begin
      Unused  := PM_Runtime_Get_Sync (Netdev.Dev.Parent);
      Ret_Val := C.unsigned (Hw.Phy.Ops.Acquire (Hw));

      if Ret_Val /= 0
      then
         goto Fl_Out;
      end if;

      pr_info ("EEE TX LPI TIMER: " & u32'Image (Shift_Right (ER32 (Hw.all, E1000_LPIC),
                                                              E1000_LPIC_LPIET_SHIFT)));
      Hw.Phy.Ops.Release (Hw);


      <<Fl_Out>>

      Unused := PM_Runtime_Put_Sync (Netdev.Dev.Parent);
   end E1000e_Flush_Lpic;




   ----------------------------
   -- E1000e_S0ix_Entry_Flow --
   ----------------------------

   --  S0ix implementation.


   procedure E1000e_S0ix_Entry_Flow
     (Adapter : access E1000_Adapter.item)
   is
      use Devices.e1000e.Ich8Lan;

      Hw       : constant access E1000_Hw   := Adapter.Hw'Access;
      Mac_Data :                 Unsigned_32;
      Phy_Data : aliased         Unsigned_16;
      Unused   :                 s32;

   begin
      if        (Er32 (Hw.all, E1000_FWSM) and E1000_ICH_FWSM_FW_VALID) /= 0
        and then Hw.Mac.Mac_Type >= E1000_Pch_Adp
      then
         -- Request ME configure the device for S0ix.
         --
         Mac_Data := Er32 (Hw.all, E1000_H2ME);
         Mac_Data := Mac_Data or E1000_H2ME_START_DPG;
         Mac_Data := Mac_Data and (not E1000_H2ME_EXIT_DPG);

         -- TODO: Trace_E1000e_Trace_Mac_Register (Mac_Data);
         Ew32 (Hw.all, E1000_H2ME, Mac_Data);

      else
         -- Request driver configure the device to S0ix
         -- Disable the periodic inband message,
         -- don't request PCIe clock in K1 page770_17[10:9] = 10b.
         --
         Unused   := E1e_Rphy (Hw, HV_PM_CTRL, Phy_Data'unchecked_Access);
         Phy_Data := Phy_Data and (not HV_PM_CTRL_K1_CLK_REQ);
         Phy_Data := Phy_Data or BIT (10);
         E1e_Wphy (Hw, HV_PM_CTRL, Phy_Data);

         -- Make sure we don't exit K1 every time a new packet arrives
         -- 772_29[5] = 1 CS_Mode_Stay_In_K1.
         --
         Unused   := E1e_Rphy (Hw, I217_CGFREG, Phy_Data'unchecked_Access);
         Phy_Data := Phy_Data or BIT (5);
         E1e_Wphy (Hw, I217_CGFREG, Phy_Data);

         -- Change the MAC/PHY interface to SMBus.
         -- Force the SMBus in PHY page769_23[0] = 1.
         -- Force the SMBus in MAC CTRL_EXT[11] = 1.
         --
         Unused   := E1e_Rphy (Hw, CV_SMB_CTRL, Phy_Data'unchecked_Access);
         Phy_Data := Phy_Data or CV_SMB_CTRL_FORCE_SMBUS;
         E1e_Wphy (Hw, CV_SMB_CTRL, Phy_Data);
         Mac_Data := Er32 (Hw.all, E1000_CTRL_EXT);
         Mac_Data := Mac_Data or E1000_CTRL_EXT_FORCE_SMBUS;
         Ew32 (Hw.all, E1000_CTRL_EXT, Mac_Data);

         -- DFT control: PHY bit: page769_20[0] = 1
         -- page769_20[7] - PHY PLL stop
         -- page769_20[8] - PHY go to the electrical idle
         -- page769_20[9] - PHY serdes disable
         -- Gate PPW via EXTCNF_CTRL - set 0x0F00[7] = 1.
         --
         Unused   := E1e_Rphy (Hw, I82579_DFT_CTRL, Phy_Data'unchecked_Access);
         Phy_Data := Phy_Data or BIT (0);
         Phy_Data := Phy_Data or BIT (7);
         Phy_Data := Phy_Data or BIT (8);
         Phy_Data := Phy_Data or BIT (9);
         E1e_Wphy (Hw, I82579_DFT_CTRL, Phy_Data);

         Mac_Data := Er32 (Hw.all, E1000_EXTCNF_CTRL);
         Mac_Data := Mac_Data or E1000_EXTCNF_CTRL_GATE_PHY_CFG;
         Ew32 (Hw.all, E1000_EXTCNF_CTRL, Mac_Data);

         -- Disable disconnected cable conditioning for Power Gating.
         --
         Mac_Data := Er32 (Hw.all, E1000_DPGFR);
         Mac_Data := Mac_Data or BIT (2);
         Ew32 (Hw.all, E1000_DPGFR, Mac_Data);

         -- Enable the Dynamic Clock Gating in the DMA and MAC.
         --
         Mac_Data := Er32 (Hw.all, E1000_CTRL_EXT);
         Mac_Data := Mac_Data or E1000_CTRL_EXT_DMA_DYN_CLK_EN;
         Ew32 (Hw.all, E1000_CTRL_EXT, Mac_Data);
      end if;


      -- Enable the Dynamic Power Gating in the MAC.
      --
      Mac_Data := Er32 (Hw.all, E1000_FEXTNVM7);
      Mac_Data := Mac_Data or BIT (22);
      Ew32 (Hw.all, E1000_FEXTNVM7, Mac_Data);

      -- Don't wake from dynamic Power Gating with clock request.
      --
      Mac_Data := Er32 (Hw.all, E1000_FEXTNVM12);
      Mac_Data := Mac_Data or BIT (12);
      Ew32 (Hw.all, E1000_FEXTNVM12, Mac_Data);

      -- Ungate PGCB clock.
      --
      Mac_Data := Er32 (Hw.all, E1000_FEXTNVM9);
      Mac_Data := Mac_Data and (not BIT (28));
      Ew32 (Hw.all, E1000_FEXTNVM9, Mac_Data);

      -- Enable K1 off to enable mPHY Power Gating.
      --
      Mac_Data := Er32 (Hw.all, E1000_FEXTNVM6);
      Mac_Data := Mac_Data or BIT (31);
      Ew32 (Hw.all, E1000_FEXTNVM6, Mac_Data);

      -- Enable mPHY power gating for any link and speed.
      --
      Mac_Data := Er32 (Hw.all, E1000_FEXTNVM8);
      Mac_Data := Mac_Data or BIT (9);
      Ew32 (Hw.all, E1000_FEXTNVM8, Mac_Data);

      -- No MAC DPG gating SLP_S0 in modern standby
      -- Switch the logic of the lanphypc to use PMC counter.
      --
      Mac_Data := Er32 (Hw.all, E1000_FEXTNVM5);
      Mac_Data := Mac_Data or BIT (7);
      Ew32 (Hw.all, E1000_FEXTNVM5, Mac_Data);

      -- Disable the time synchronization clock.
      --
      Mac_Data := Er32 (Hw.all, E1000_FEXTNVM7);
      Mac_Data := Mac_Data or BIT (31);
      Mac_Data := Mac_Data and (not BIT (0));
      Ew32 (Hw.all, E1000_FEXTNVM7, Mac_Data);

      -- Dynamic Power Gating Enable.
      --
      Mac_Data := Er32 (Hw.all, E1000_CTRL_EXT);
      Mac_Data := Mac_Data or BIT (3);
      Ew32 (Hw.all, E1000_CTRL_EXT, Mac_Data);

      -- Check MAC Tx/Rx packet buffer pointers.
      -- Reset MAC Tx/Rx packet buffer pointers to suppress any
      -- pending traffic indication that would prevent power gating.
      --
      Mac_Data := Er32 (Hw.all, E1000_TDFH);

      if Mac_Data /= 0
      then
         Ew32 (Hw.all, E1000_TDFH, 0);
      end if;

      Mac_Data := Er32 (Hw.all, E1000_TDFT);

      if Mac_Data /= 0
      then
         Ew32 (Hw.all, E1000_TDFT, 0);
      end if;

      Mac_Data := Er32 (Hw.all, E1000_TDFHS);

      if Mac_Data /= 0
      then
         Ew32 (Hw.all, E1000_TDFHS, 0);
      end if;

      Mac_Data := Er32 (Hw.all, E1000_TDFTS);

      if Mac_Data /= 0
      then
         Ew32 (Hw.all, E1000_TDFTS, 0);
      end if;

      Mac_Data := Er32 (Hw.all, E1000_TDFPC);

      if Mac_Data /= 0
      then
         Ew32 (Hw.all, E1000_TDFPC, 0);
      end if;

      Mac_Data := Er32 (Hw.all, E1000_RDFH);

      if Mac_Data /= 0
      then
         Ew32 (Hw.all, E1000_RDFH, 0);
      end if;

      Mac_Data := Er32 (Hw.all, E1000_RDFT);

      if Mac_Data /= 0
      then
         Ew32 (Hw.all, E1000_RDFT, 0);
      end if;

      Mac_Data := Er32 (Hw.all, E1000_RDFHS);

      if Mac_Data /= 0
      then
         Ew32 (Hw.all, E1000_RDFHS, 0);
      end if;

      Mac_Data := Er32 (Hw.all, E1000_RDFTS);

      if Mac_Data /= 0
      then
         Ew32 (Hw.all, E1000_RDFTS, 0);
      end if;

      Mac_Data := Er32 (Hw.all, E1000_RDFPC);

      if Mac_Data /= 0
      then
         Ew32 (Hw.all, E1000_RDFPC, 0);
      end if;
   end E1000e_S0ix_Entry_Flow;




   ---------------------------
   -- E1000e_S0ix_Exit_Flow --
   ---------------------------

   procedure E1000e_S0ix_Exit_Flow
     (Adapter : access E1000_Adapter.item)
   is
      use Devices.e1000e.Ich8Lan;

      Hw           : constant access E1000_HW   := Adapter.Hw'Access;
      Firmware_Bug :                 Boolean    := False;
      Mac_Data     :                 Unsigned_32;
      Phy_Data     : aliased         Unsigned_16;
      I            :                 Natural    := 0;
      Unused       :                 s32;

   begin
      if        (Er32 (Hw.all, E1000_FWSM) and E1000_ICH_FWSM_FW_VALID) /= 0
        and then Hw.Mac.Mac_Type >= E1000_Pch_Adp
      then
         -- Keep the GPT clock enabled for CSME.
         --
         Mac_Data := Er32 (Hw.all, E1000_FEXTNVM);
         Mac_Data := Mac_Data or Shift_Left (1, 3);
         Ew32 (Hw.all, E1000_FEXTNVM, Mac_Data);

         -- Request ME unconfigure the device from S0ix.
         --
         Mac_Data := Er32 (Hw.all, E1000_H2ME);
         Mac_Data := Mac_Data and (not E1000_H2ME_START_DPG);
         Mac_Data := Mac_Data or E1000_H2ME_EXIT_DPG;
         -- TODO:   trace_e1000e_trace_mac_register (mac_data);
         Ew32 (Hw.all, E1000_H2ME, Mac_Data);

         -- Poll up to 2.5 seconds for ME to unconfigure DPG.
         -- If this takes more than 1 second, show a warning indicating a
         -- firmware bug.
         --
         while (Er32 (Hw.all, E1000_EXFWSM) and E1000_EXFWSM_DPG_EXIT_DONE) = 0
         loop
            if I > 100 and not Firmware_Bug
            then
               Firmware_Bug := True;
            end if;

            if I = 250
            then
               I := I + 1;     -- TODO: RAK added. Check.
               e_dbg ("Timeout (firmware bug):" & Natural'Image (I * 10) & " msec");
               exit;
            end if;

            delay 0.015; -- Equivalent to usleep_range(10000, 11000)
            I := I + 1;
         end loop;


         if Firmware_Bug
         then
            e_warn ("DPG_EXIT_DONE took" & Natural'Image (I * 10) & " msec. This is a firmware bug");
         else
            e_dbg ("DPG_EXIT_DONE cleared after" & Natural'Image (I * 10) & " msec");
         end if;

      else
         -- Request driver unconfigure the device from S0ix.
         --

         -- Cancel disable disconnected cable conditioning for Power Gating.
         --
         Mac_Data := Er32 (Hw.all, E1000_DPGFR);
         Mac_Data := Mac_Data and (not BIT (2));
         Ew32 (Hw.all, E1000_DPGFR, Mac_Data);

         -- Disable the Dynamic Clock Gating in the DMA and MAC.
         --
         Mac_Data := Er32 (Hw.all, E1000_CTRL_EXT);
         Mac_Data := Mac_Data and 16#FFF7FFFF#;
         Ew32 (Hw.all, E1000_CTRL_EXT, Mac_Data);

         -- Enable the periodic inband message,
         -- Request PCIe clock in K1 page770_17[10:9] =01b.
         --
         Unused   := E1e_Rphy (Hw, HV_PM_CTRL, Phy_Data'unchecked_Access);
         Phy_Data := Phy_Data and 16#FBFF#;
         Phy_Data := Phy_Data or HV_PM_CTRL_K1_CLK_REQ;
         E1e_Wphy (Hw, HV_PM_CTRL, Phy_Data);

         -- Return back configuration
         -- 772_29[5] = 0 CS_Mode_Stay_In_K1.
         --
         Unused   := E1e_Rphy (Hw, I217_CGFREG, Phy_Data'unchecked_Access);
         Phy_Data := Phy_Data and 16#FFDF#;
         E1e_Wphy (Hw, I217_CGFREG, Phy_Data);

         -- Change the MAC/PHY interface to Kumeran.
         -- Unforce the SMBus in PHY page769_23[0] = 0.
         -- Unforce the SMBus in MAC CTRL_EXT[11] = 0.
         --
         Unused   := E1e_Rphy (Hw, CV_SMB_CTRL, Phy_Data'unchecked_Access);
         Phy_Data := Phy_Data and (not CV_SMB_CTRL_FORCE_SMBUS);
         E1e_Wphy (Hw, CV_SMB_CTRL, Phy_Data);
         Mac_Data := Er32 (Hw.all, E1000_CTRL_EXT);
         Mac_Data := Mac_Data and (not E1000_CTRL_EXT_FORCE_SMBUS);
         Ew32 (Hw.all, E1000_CTRL_EXT, Mac_Data);
      end if;


      -- Disable Dynamic Power Gating.
      --
      Mac_Data := Er32 (Hw.all, E1000_CTRL_EXT);
      Mac_Data := Mac_Data and 16#FFFFFFF7#;
      Ew32 (Hw.all, E1000_CTRL_EXT, Mac_Data);

      -- Enable the time synchronization clock.
      --
      Mac_Data := Er32 (Hw.all, E1000_FEXTNVM7);
      Mac_Data := Mac_Data and (not BIT (31));
      Mac_Data := Mac_Data or BIT (0);
      Ew32 (Hw.all, E1000_FEXTNVM7, Mac_Data);

      -- Disable the Dynamic Power Gating in the MAC.
      --
      Mac_Data := Er32 (Hw.all, E1000_FEXTNVM7);
      Mac_Data := Mac_Data and 16#FFBFFFFF#;
      Ew32 (Hw.all, E1000_FEXTNVM7, Mac_Data);

      -- Disable mPHY power gating for any link and speed.
      --
      Mac_Data := Er32 (Hw.all, E1000_FEXTNVM8);
      Mac_Data := Mac_Data and (not BIT (9));
      Ew32 (Hw.all, E1000_FEXTNVM8, Mac_Data);

      -- Disable K1 off.
      --
      Mac_Data := Er32 (Hw.all, E1000_FEXTNVM6);
      Mac_Data := Mac_Data and (not BIT (31));
      Ew32 (Hw.all, E1000_FEXTNVM6, Mac_Data);

      -- Disable Ungate PGCB clock.
      --
      Mac_Data := Er32 (Hw.all, E1000_FEXTNVM9);
      Mac_Data := Mac_Data or BIT (28);
      Ew32 (Hw.all, E1000_FEXTNVM9, Mac_Data);

      -- Cancel not waking from dynamic
      -- Power Gating with clock request.
      --
      Mac_Data := Er32 (Hw.all, E1000_FEXTNVM12);
      Mac_Data := Mac_Data and (not BIT (12));
      Ew32 (Hw.all, E1000_FEXTNVM12, Mac_Data);

      -- Revert the lanphypc logic to use the internal Gbe counter
      -- and not the PMC counter.
      --
      Mac_Data := Er32 (Hw.all, E1000_FEXTNVM5);
      Mac_Data := Mac_Data and 16#FFFFFF7F#;
      Ew32 (Hw.all, E1000_FEXTNVM5, Mac_Data);
   end E1000e_S0ix_Exit_Flow;




   ----------------------
   -- E1000e_PM_Freeze --
   ----------------------

   function E1000e_PM_Freeze
     (Dev : access Device) return C.int
   is
       Netdev  : aliased Net_Device
        with
          Import,
          Address => dev_get_drvdata (Dev);

      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev'Access);

      Present : Boolean;
      Unused  : s32;

   begin
      RTNL_Lock;

      Present := Netif_Device_Present (Netdev'Access);
      Netif_Device_Detach (Netdev'Access);

      if Present and then Netif_Running (Netdev'Access)
      then
         declare
            Count : Integer := E1000_CHECK_RESET_COUNT;
         begin
            while      Test_Bit (E1000_RESETTING'enum_Rep, Adapter.State'Address)
              and then Count > 0
            loop
               delay 10_500 * Microseconds;
               Count := Count - 1;
            end loop;

            WARN_ON (test_bit (E1000_RESETTING'enum_Rep, adapter.state'Address));

            -- Quiesce the device without resetting the hardware.
            --
            E1000e_Down    (Adapter'Access, False);
            E1000_Free_IRQ (Adapter'Access);
         end;
      end if;

      RTNL_Unlock;

      E1000e_Reset_Interrupt_Capability (Adapter'Access);

      -- Allow time for pending master requests to run.
      --
      Unused := Devices.e1000e.Media_Access_Control.E1000e_Disable_PCIe_Master (Adapter.HW'Access);

      return 0;
   end E1000e_PM_Freeze;




   -----------------------------
   -- E1000_Shutdown_Internal --
   -----------------------------


   function E1000_Shutdown_Internal
     (Pdev    : access PCI_Dev;
      Runtime : in     Boolean) return C.int
   is
      use Devices.e1000e.Ich8Lan;

      Netdev  : aliased Net_Device
        with
          Import,
          Address => PCI_Get_Drvdata (Pdev);

      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev'Access);

      Hw       : constant access E1000_HW   := Adapter.Hw'Access;
      Ctrl     :                 Unsigned_32;
      Ctrl_Ext :                 Unsigned_32;
      Rctl     :                 Unsigned_32;
      Status   :                 Unsigned_32;
      Wufc     :                 Unsigned_32;
      Retval   :                 C.int      := 0;
      Unused   :                 C.int;

   begin
      -- Runtime suspend should only enable wakeup for link changes.
      --
      if Runtime
      then
         Wufc := E1000_WUFC_LNKC;

      elsif Device_May_Wakeup (Pdev.Dev'Access)
      then
         Wufc := Adapter.Wol;

      else
         Wufc := 0;
      end if;


      Status := Er32 (Hw.all, E1000_STATUS);

      if (Status and E1000_STATUS_LU) /= 0
      then
         Wufc := Wufc and (not E1000_WUFC_LNKC);
      end if;

      if Wufc /= 0
      then
         E1000_Setup_Rctl   (Adapter'Access);
         E1000e_Set_Rx_Mode (Netdev 'Access);

         -- Turn on all-multi mode if wake on multicast is enabled.
         --
         if (Wufc and E1000_WUFC_MC) /= 0
         then
            Rctl := Er32 (Hw.all, E1000_RCTL);
            Rctl := Rctl or E1000_RCTL_MPE;
            Ew32 (Hw.all, E1000_RCTL, Rctl);
         end if;

         Ctrl := Er32 (Hw.all, E1000_CTRL);
         Ctrl := Ctrl or E1000_CTRL_ADVD3WUC;

         if (Adapter.Flags2 and C.unsigned (FLAG2_HAS_PHY_WAKEUP)) = 0
         then
            Ctrl := Ctrl or E1000_CTRL_EN_PHY_PWR_MGMT;
         end if;

         Ew32 (Hw.all, E1000_CTRL, Ctrl);

         if   Hw.Phy.Media_Type = E1000_Media_Type_Fiber
           or Hw.Phy.Media_Type = E1000_Media_Type_Internal_Serdes
         then
            -- Keep the laser running in D3.
            --
            Ctrl_Ext := Er32 (Hw.all, E1000_CTRL_EXT);
            Ctrl_Ext := Ctrl_Ext or E1000_CTRL_EXT_SDP3_DATA;
            Ew32 (Hw.all, E1000_CTRL_EXT, Ctrl_Ext);
         end if;

         if not Runtime
         then
            E1000e_Power_Up_Phy (Adapter'Access);
         end if;

         if (Adapter.Flags and C.unsigned (FLAG_IS_ICH)) /= 0
         then
            E1000_Suspend_Workarounds_Ich8lan (Hw);
         end if;


         if (Adapter.Flags2 and C.unsigned (FLAG2_HAS_PHY_WAKEUP)) /= 0
         then
            -- Enable wakeup by the PHY.
            --
            Retval := E1000_Init_Phy_Wakeup (Adapter'Access, Wufc);

            if Retval /= 0
            then
               return Retval;
            end if;

         else
            -- Enable wakeup by the MAC.
            --
            Ew32 (Hw.all, E1000_WUFC, Wufc);
            Ew32 (Hw.all, E1000_WUC,  E1000_WUC_PME_EN);
         end if;

      else
         Ew32 (Hw.all, E1000_WUC,  0);
         Ew32 (Hw.all, E1000_WUFC, 0);

         E1000_Power_Down_Phy (Adapter'Access);
      end if;


      if Hw.Phy.Phy_Type = E1000_Phy_Igp_3
      then
         E1000e_Igp3_Phy_Powerdown_Workaround_Ich8lan (Hw);

      elsif Hw.Mac.Mac_Type >= E1000_Pch_Lpt
      then
         if     Wufc /= 0
           and (Wufc and (   E1000_WUFC_EX
                          or E1000_WUFC_MC
                          or E1000_WUFC_BC)) = 0
         then
            -- ULP does not support wake from unicast, multicast or broadcast.
            --
            Retval := C.int (E1000_Enable_Ulp_Lpt_Lp (Hw, not Runtime));

            if Retval /= 0
            then
               return Retval;
            end if;
         end if;
      end if;


      -- Ensure that the appropriate bits are set in LPI_CTRL for EEE in Sx.
      --
      if    Hw.Phy.phy_type >= E1000_Phy_I217
        and Adapter.Eee_Advert /= 0
        and Hw.Dev_Spec.Ich8lan.Eee_Lp_Ability /= 0
      then
         declare
            Lpi_Ctrl : aliased Unsigned_16 := 0;
         begin
            Retval := C.int (Hw.Phy.Ops.Acquire (Hw));

            if Retval = 0
            then
               Retval := C.int (E1e_Rphy_Locked (Hw, I82579_LPI_CTRL, Lpi_Ctrl'unchecked_Access));

               if Retval = 0
               then
                  if (    Adapter.Eee_Advert
                      and Hw.Dev_Spec.Ich8lan.Eee_Lp_Ability
                      and I82579_EEE_100_SUPPORTED) /= 0
                  then
                     Lpi_Ctrl := Lpi_Ctrl or I82579_LPI_CTRL_100_ENABLE;
                  end if;

                  if (    Adapter.Eee_Advert
                      and Hw.Dev_Spec.Ich8lan.Eee_Lp_Ability
                      and I82579_EEE_1000_SUPPORTED) /= 0
                  then
                     Lpi_Ctrl := Lpi_Ctrl or I82579_LPI_CTRL_1000_ENABLE;
                  end if;

                  Retval := C.int (E1e_Wphy_Locked (Hw, I82579_LPI_CTRL, Lpi_Ctrl));
               end if;
            end if;

            Hw.Phy.Ops.Release (Hw);
         end;
      end if;


      -- Release control of h/w to f/w.  If f/w is AMT enabled, this
      -- would have already happened in close and is redundant.
      --
      E1000e_Release_Hw_Control (Adapter'Access);
      PCI_Clear_Master (Pdev);

      -- The pci-e switch on some quad port adapters will report a
      -- correctable error when the MAC transitions from D0 to D3.  To
      -- prevent this we need to mask off the correctable errors on the
      -- downstream port of the pci-e switch.
      --
      -- We don't have the associated upstream bridge while assigning
      -- the PCI device into guest. For example, the KVM on power is
      -- one of the cases.
      --
      if (Adapter.Flags and C.unsigned (FLAG_IS_QUAD_PORT)) /= 0
      then
         declare
            Us_Dev : constant access PCI_Dev    := Pdev.Bus.Self;
            Devctl : aliased         Unsigned_16;
         begin
            if Us_Dev = null
            then
               return 0;
            end if;

            Unused := PCIe_Capability_Read_Word  (Us_Dev, PCI_EXP_DEVCTL, Devctl'Access);
            Unused := PCIe_Capability_Write_Word (Us_Dev, PCI_EXP_DEVCTL,
                                                  Devctl and (not PCI_EXP_DEVCTL_CERE));
            Unused := PCI_Save_State       (Pdev);
            Unused := PCI_Prepare_To_Sleep (Pdev);

            Unused := PCIe_Capability_Write_Word (Us_Dev, PCI_EXP_DEVCTL, Devctl);
         end;
      end if;


      return 0;
   end E1000_Shutdown_Internal;




   ----------------------------------
   -- e1000e_Disable_ASPM_internal --
   ----------------------------------

   --  Disable ASPM states.
   --
   --  * @pdev:   Pointer to PCI device struct.
   --  * @state:  Bit-mask of ASPM states to disable.
   --  * @locked: Indication if this context holds pci_bus_sem locked.
   --  *
   --  * Some devices *must* have certain ASPM states disabled per hardware errata.


   procedure e1000e_Disable_ASPM_internal
     (Pdev   : access PCI_Dev;
      State  : in     u16;
      Locked : in     Boolean)
   is
      Parent        : constant access  PCI_Dev := Pdev.Bus.Self;
      Aspm_Dis_Mask :                  u16     := 0;
      Pdev_Aspmc,
      Parent_Aspmc  : aliased          u16;
      Unused        :                  C.int;

   begin
      case State
      is
         when PCIE_LINK_STATE_L0S
            | PCIE_LINK_STATE_L0S or PCIE_LINK_STATE_L1 =>

            Aspm_Dis_Mask := Aspm_Dis_Mask or PCI_EXP_LNKCTL_ASPM_L0S;

         when PCIE_LINK_STATE_L1 =>
            Aspm_Dis_Mask := Aspm_Dis_Mask or PCI_EXP_LNKCTL_ASPM_L1;

         when others =>
            return;
      end case;


      Unused     := Pcie_Capability_Read_Word (Pdev, PCI_EXP_LNKCTL, Pdev_Aspmc'Access);
      Pdev_Aspmc := Pdev_Aspmc and PCI_EXP_LNKCTL_ASPMC;

      if Parent /= null
      then
         Unused       := Pcie_Capability_Read_Word (Parent, PCI_EXP_LNKCTL, Parent_Aspmc'Access);
         Parent_Aspmc := Parent_Aspmc and PCI_EXP_LNKCTL_ASPMC;
      end if;

      if    (Pdev_Aspmc and Aspm_Dis_Mask) = 0
        and (         Parent = null
             or else (Parent_Aspmc and Aspm_Dis_Mask) = 0)
      then
         return;
      end if;


      dev_info (pdev.dev'Access,
                "Disabling ASPM"
                & (if (Aspm_Dis_Mask and Pdev_Aspmc and PCI_EXP_LNKCTL_ASPM_L0S) /= 0 then " L0s" else "")
                & (if (Aspm_Dis_Mask and Pdev_Aspmc and PCI_EXP_LNKCTL_ASPM_L1)  /= 0 then " L1"  else ""));


      if CONFIG_PCIEASPM
      then
         if Locked
         then
            Unused := Pci_Disable_Link_State_Locked (Pdev, C.int (State));
         else
            Unused := Pci_Disable_Link_State (Pdev, C.int (State));
         end if;

         Unused     := Pcie_Capability_Read_Word (Pdev, PCI_EXP_LNKCTL, Pdev_Aspmc'Access);
         Pdev_Aspmc := Pdev_Aspmc and PCI_EXP_LNKCTL_ASPMC;

         if (Aspm_Dis_Mask and Pdev_Aspmc) = 0
         then
            return;
         end if;
      end if;


      Unused := Pcie_Capability_Clear_Word (Pdev, PCI_EXP_LNKCTL, Aspm_Dis_Mask);

      if Parent /= null
      then
         Unused := Pcie_Capability_Clear_Word (Parent, PCI_EXP_LNKCTL, Aspm_Dis_Mask);
      end if;
   end e1000e_Disable_ASPM_internal;




   -------------------------
   -- E1000e_Disable_ASPM --
   -------------------------

   --    Disable ASPM states.
   --
   --  * @pdev:  Pointer to PCI device struct.
   --  * @state: Bit-mask of ASPM states to disable.
   --  *
   --  * This function acquires the pci_bus_sem!
   --  * Some devices *must* have certain ASPM states disabled per hardware errata.


   procedure E1000e_Disable_ASPM
     (Pdev  : access PCI_Dev;
      State : in     Unsigned_16)
   is
   begin
      e1000e_Disable_ASPM_internal (Pdev, State, False);
   end E1000e_Disable_ASPM;




   --------------------------------
   -- E1000e_Disable_ASPM_Locked --
   --------------------------------

   --    Disable ASPM states.
   --
   --  * @pdev:  Pointer to PCI device struct.
   --  * @state: Bit-mask of ASPM states to disable.
   --  *
   --  * This function must be called with pci_bus_sem acquired!
   --  * Some devices *must* have certain ASPM states disabled per hardware errata.


   procedure E1000e_Disable_ASPM_Locked
     (PDev  : access PCI_Dev;
      State : in     Unsigned_16)
   is
   begin
      e1000e_Disable_ASPM_internal (PDev, State, True);
   end E1000e_Disable_ASPM_Locked;




   --------------------
   -- e1000e_pm_thaw --
   --------------------

   function e1000e_pm_thaw
     (Dev : access Device) return C.int
   is
      Netdev  : aliased Net_Device
        with
          Import,
          Address => dev_get_drvdata (Dev);

      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev'Access);

      RC      : C.int := 0;

   begin
      E1000E_Set_Interrupt_Capability (Adapter'Access);
      RTNL_Lock;

      if Netif_Running (Netdev'Access)
      then
         RC := E1000_Request_IRQ (Adapter'Access);

         if RC /= 0
         then
            goto Err_IRQ;
         end if;

         E1000E_Up (Adapter'Access);
      end if;

      Netif_Device_Attach (Netdev'Access);


      <<Err_IRQ>>

      RTNL_Unlock;

      return RC;
   end e1000e_pm_thaw;




   ---------------------------
   -- E1000_Resume_internal --
   ---------------------------

   function E1000_Resume_internal
     (Pdev : access PCI_Dev) return C.int
   is
       Netdev  : aliased Net_Device
        with
          Import,
          Address => pci_get_drvdata (PDev);

      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev'Access);

      Hw                : constant access E1000_HW    := Adapter.Hw'Access;
      ASPM_Disable_Flag :                 Unsigned_16 := 0;

   begin
      if (Adapter.Flags2 and C.unsigned (FLAG2_DISABLE_ASPM_L0S)) /= 0
      then
         ASPM_Disable_Flag := PCIE_LINK_STATE_L0S;
      end if;

      if (Adapter.Flags2 and C.unsigned (FLAG2_DISABLE_ASPM_L1)) /= 0
      then
         ASPM_Disable_Flag := ASPM_Disable_Flag or PCIE_LINK_STATE_L1;
      end if;

      if ASPM_Disable_Flag /= 0
      then
         E1000e_Disable_ASPM (Pdev, ASPM_Disable_Flag);
      end if;

      PCI_Set_Master (Pdev);

      if Hw.Mac.Mac_Type >= E1000_PCH2LAN
      then
         Devices.e1000e.Ich8Lan.E1000_Resume_Workarounds_Pchlan (Hw);
      end if;

      E1000e_Power_Up_Phy (Adapter'Access);


      -- Report the system wakeup cause from S3/S4.
      --
      if (Adapter.Flags2 and C.unsigned (FLAG2_HAS_PHY_WAKEUP)) /= 0
      then
         declare
            Phy_Data : aliased Unsigned_16;
            Unused   :         s32;
         begin
            Unused := E1e_Rphy (Hw, Devices.e1000e.Ich8Lan.BM_WUS, Phy_Data'unchecked_Access);

            if Phy_Data /= 0
            then
               e_info ("PHY Wakeup cause - "
                       & (if    (Phy_Data and E1000_WUS_EX)   /= 0 then "Unicast Packet"
                          elsif (Phy_Data and E1000_WUS_MC)   /= 0 then "Multicast Packet"
                          elsif (Phy_Data and E1000_WUS_BC)   /= 0 then "Broadcast Packet"
                          elsif (Phy_Data and E1000_WUS_MAG)  /= 0 then "Magic Packet"
                          elsif (Phy_Data and E1000_WUS_LNKC) /= 0 then "Link Status Change"
                                                                   else "other"));
            end if;

            E1e_Wphy (Hw, Devices.e1000e.Ich8Lan.BM_WUS, 16#FFFF#);
         end;

      else
         declare
            Wus : constant Unsigned_32 := Er32 (Hw.all, E1000_WUS);
         begin
            if Wus /= 0
            then
               e_info (  "MAC Wakeup cause - "
                       & (if    (Wus and E1000_WUS_EX)   /= 0 then "Unicast Packet"
                          elsif (Wus and E1000_WUS_MC)   /= 0 then "Multicast Packet"
                          elsif (Wus and E1000_WUS_BC)   /= 0 then "Broadcast Packet"
                          elsif (Wus and E1000_WUS_MAG)  /= 0 then "Magic Packet"
                          elsif (Wus and E1000_WUS_LNKC) /= 0 then "Link Status Change"
                                                              else "other"));
            end if;
            Ew32 (Hw.all, E1000_WUS, 16#FFFFFFFF#);
         end;
      end if;


      E1000e_Reset                (Adapter'Access);
      E1000_Init_Manageability_Pt (Adapter'Access);

      -- If the controller has AMT, do not set DRV_LOAD until the interface
      -- is up. For all other cases, let the f/w know that the h/w is now
      -- under the control of the driver.
      --
      if (Adapter.Flags and C.unsigned (FLAG_HAS_AMT)) = 0
      then
         E1000e_Get_Hw_Control (Adapter'Access);
      end if;

      return 0;
   end E1000_Resume_internal;





   -----------------------
   -- E1000e_PM_Prepare --
   -----------------------

   function E1000e_PM_Prepare
     (Dev : access Device) return Integer
   is
   begin
      return Boolean'Pos (         pm_runtime_suspended (Dev)
                          and then pm_suspend_via_firmware);
   end E1000e_PM_Prepare;




   -----------------------
   -- E1000e_PM_Suspend --
   -----------------------

   function E1000e_PM_Suspend
     (Dev : access Device) return C.int
   is
      Pdev    : constant access PCI_Dev := To_PCI_Dev (Dev);

      Netdev  : aliased Net_Device
        with
          Import,
          Address => pci_get_drvdata (PDev);

      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev'Access);

      RC      : C.int;
      Unused  : C.int;

   begin
      E1000e_Flush_LPIC (Pdev);
      Unused := E1000e_PM_Freeze (Dev);

      RC := E1000_Shutdown_Internal (Pdev, False);

      if RC /= 0
      then
         Unused := E1000e_PM_Thaw (Dev);

      else
         -- Introduce S0ix implementation.
         --
         if (Adapter.Flags2 and C.unsigned (FLAG2_ENABLE_S0IX_FLOWS)) /= 0
         then
            E1000e_S0ix_Entry_Flow (Adapter'Access);
         end if;
      end if;


      return RC;
   end E1000e_PM_Suspend;




   ----------------------
   -- E1000e_PM_Resume --
   ----------------------

   function E1000e_PM_Resume
     (Dev : access Device) return C.int
   is
      Pdev    : constant access PCI_Dev := To_PCI_Dev (Dev);

      Netdev  : aliased Net_Device
        with
          Import,
          Address => pci_get_drvdata (PDev);

      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev'Access);
      RC      :        C.int;

   begin
      -- Introduce S0ix implementation.
      --
      if (Adapter.Flags2 and C.unsigned (FLAG2_ENABLE_S0IX_FLOWS)) /= 0
      then
         E1000e_S0ix_Exit_Flow (Adapter'Access);
      end if;

      RC := E1000_Resume_internal (Pdev);

      if RC /= 0
      then
         return RC;
      end if;

      return E1000e_PM_Thaw (Dev);
   end E1000e_PM_Resume;




   ----------------------------
   -- E1000e_PM_Runtime_Idle --
   ----------------------------

   function E1000e_PM_Runtime_Idle
     (Dev : access Device) return C.int
   is
      Netdev  : aliased Net_Device
        with
          Import,
          Address => Dev_Get_Drvdata (Dev);

      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev'Access);

      EEE_LP  :         Unsigned_16;
      Unused  :         C.int;

   begin
      EEE_LP := Adapter.HW.Dev_Spec.ICH8LAN.EEE_LP_Ability;

      if not E1000e_Has_Link (Adapter'Access)
      then
         Adapter.HW.Dev_Spec.ICH8LAN.EEE_LP_Ability := EEE_LP;
         Unused := PM_Schedule_Suspend (Dev, 5 * MSEC_PER_SEC);
      end if;

      return -EBUSY;
   end E1000e_PM_Runtime_Idle;




   ------------------------------
   -- E1000e_PM_Runtime_Resume --
   ------------------------------

   function E1000e_PM_Runtime_Resume
     (Dev : access Device) return C.int
   is
      Pdev    : constant access PCI_Dev := To_PCI_Dev (Dev);

      Netdev  : aliased Net_Device
        with
          Import,
          Address => pci_get_drvdata (PDev);

      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev'Access);

      RC : C.int;

   begin
      Pdev.PME_Poll := True;

      RC := E1000_Resume_internal (Pdev);

      if RC /= 0
      then
         return RC;
      end if;

      if (Netdev.Flags and C.unsigned (IFF_UP)) /= 0
      then
         E1000e_Up (Adapter'Access);
      end if;

      return RC;
   end E1000e_PM_Runtime_Resume;





   -------------------------------
   -- E1000e_PM_Runtime_Suspend --
   -------------------------------

   function E1000e_PM_Runtime_Suspend
     (Dev : access Device) return Integer
   is
      Pdev    : constant access PCI_Dev := To_PCI_Dev (Dev);

      Netdev  : aliased Net_Device
        with
          Import,
          Address => pci_get_drvdata (PDev);

      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev'Access);

      Count   : Integer := E1000_CHECK_RESET_COUNT;
      Unused  : C.int;

   begin
      if (Netdev.Flags and C.unsigned (IFF_UP)) /= 0
      then
         while      Test_Bit (E1000_RESETTING'enum_Rep, Adapter.State'Address)
           and then Count > 0
         loop
            delay 10_500.0 * Microseconds;
            Count := Count - 1;
         end loop;

         WARN_ON (Test_Bit (E1000_RESETTING'enum_Rep, Adapter.State'Address));

         -- Down the device without resetting the hardware.
         --
         E1000e_Down (Adapter'Access, False);
      end if;


      if E1000_Shutdown_Internal (PDev, True) /= 0
      then
         Unused := E1000e_PM_Runtime_Resume (Dev);
         return -EBUSY;
      end if;


      return 0;
   end E1000e_PM_Runtime_Suspend;




   --------------------
   -- E1000_Shutdown --
   --------------------

   procedure E1000_Shutdown
     (PDev : access PCI_Dev)
   is
      Unused : C.int;
   begin
      E1000e_Flush_LPIC                 (PDev);
      Unused := E1000e_PM_Freeze        (PDev.Dev'Access);
      Unused := E1000_Shutdown_Internal (PDev, False);
   end E1000_Shutdown;




   -------------------------------------
   --  #ifdef CONFIG_NET_POLL_CONTROLLER     -- TODO
   --


   ---------------------
   -- E1000_Intr_Msix --
   ---------------------

   function E1000_Intr_Msix
     (Irq  : in Integer with Unreferenced;
      Data : in void_ptr                 ) return irqreturn_t
   is
      Netdev  : aliased Net_Device
        with
          Import,
          Address => Data;

      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev'Access);

   begin
      if Adapter.Msix_Entries /= null
      then
         declare
            use type C.ptrdiff_t;

            Vector   : C.ptrdiff_t := 0;
            Msix_Irq : C.int;
            Unused   : irqreturn_t;

         begin
            Msix_Irq := C.int (msix_entry_pointer' (Adapter.Msix_Entries + Vector).Vector);

            if disable_hardirq (Msix_Irq)
            then
               Unused := E1000_Intr_Msix_Rx (Msix_Irq, Netdev'Address);
            end if;

            enable_irq (C.unsigned (msix_irq));


            Vector   := Vector + 1;
            Msix_Irq := C.int (msix_entry_pointer' (Adapter.Msix_Entries + Vector).Vector);

            if disable_hardirq (Msix_Irq)
            then
               Unused := E1000_Intr_Msix_Tx (Msix_Irq, Netdev'Address);
            end if;

            enable_irq (C.unsigned (msix_irq));


            Vector   := Vector + 1;
            Msix_Irq := C.int (msix_entry_pointer' (Adapter.Msix_Entries + Vector).Vector);

            if disable_hardirq (Msix_Irq)
            then
               Unused := E1000_Msix_Other (Msix_Irq, Netdev'Address);
            end if;

            enable_irq (C.unsigned (msix_irq));
         end;

      end if;


      return IRQ_HANDLED;
   end E1000_Intr_Msix;




   -------------------
   -- E1000_Netpoll --
   -------------------

   --  e1000 netpoll.
   --
   --  * @netdev: Network interface device structure.
   --  *
   --  * Polling 'interrupt' - used by things like netconsole to send skbs
   --  * without having to re-enable interrupts. It's not called while
   --  * the interrupt routine is executing.


   procedure E1000_Netpoll
     (Netdev : access Net_Device)
   is
      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev);

      Unused : irqreturn_t;

   begin
      case Adapter.Int_Mode
      is
         when E1000E_INT_MODE_MSIX =>

            Unused := E1000_Intr_Msix (Integer (Adapter.Pdev.Irq),
                                       Netdev.all'Address);


         when E1000E_INT_MODE_MSI =>

            if Disable_Hardirq (C.int (Adapter.Pdev.Irq))
            then
               Unused := E1000_Intr_Msi (C.int (Adapter.Pdev.Irq), Netdev.all'Address);
            end if;

            Enable_Irq (Adapter.Pdev.Irq);


         when others =>  -- E1000E_INT_MODE_LEGACY

            if Disable_Hardirq (C.int (Adapter.Pdev.Irq))
            then
               Unused := E1000_Intr (C.int (Adapter.Pdev.Irq), Netdev.all'Address);
            end if;

            Enable_Irq (Adapter.Pdev.Irq);
      end case;
   end E1000_Netpoll;


   --
   --  #endif CONFIG_NET_POLL_CONTROLLER
   -------------------------------------




   -----------------------------
   -- E1000_IO_Error_Detected --
   -----------------------------

   --    Called when PCI error is detected.
   --
   --  * @pdev:  Pointer to PCI device.
   --  * @state: The current pci connection state.
   --  *
   --  * This function is called after a PCI bus error affecting
   --  * this device has been detected.


   function E1000_IO_Error_Detected
     (PDev  : access PCI_Dev;
      State : in     PCI_Channel_State_t) return PCI_ERS_Result_t
   is
      Unused : C.int;
   begin
      Unused := E1000e_PM_Freeze (PDev.Dev'Access);

      if State = PCI_Channel_IO_Perm_Failure
      then
         return PCI_ERS_Result_Disconnect;
      end if;


      PCI_Disable_Device (PDev);

      -- Request a slot reset.
      --
      return PCI_ERS_Result_Need_Reset;
   end E1000_IO_Error_Detected;




   -------------------------
   -- E1000_IO_Slot_Reset --
   -------------------------

   --    Called after the pci bus has been reset.
   --
   --  * @pdev: Pointer to PCI device.
   --  *
   --  * Restart the card from scratch, as if from a cold-boot. Implementation
   --  * resembles the first-half of the e1000e_pm_resume routine.


   function E1000_IO_Slot_Reset
     (PDev : access PCI_Dev) return PCI_ERS_Result_t
   is
      Netdev  : aliased Net_Device
        with
          Import,
          Address => pci_get_drvdata (PDev);

      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev'Access);

      HW                : constant access E1000_HW        := Adapter.HW'Access;
      ASPM_Disable_Flag :                 Unsigned_16     := 0;
      Err               :                 C.int;
      Result            :                 PCI_ERS_Result_t;
      Unused            :                 C.int;

   begin
      if (Adapter.Flags2 and C.unsigned (FLAG2_DISABLE_ASPM_L0S)) /= 0
      then
         ASPM_Disable_Flag := PCIE_LINK_STATE_L0S;
      end if;

      if (Adapter.Flags2 and C.unsigned (FLAG2_DISABLE_ASPM_L1)) /= 0
      then
         ASPM_Disable_Flag := ASPM_Disable_Flag or PCIE_LINK_STATE_L1;
      end if;

      if ASPM_Disable_Flag /= 0
      then
         E1000e_Disable_ASPM_Locked (PDev, ASPM_Disable_Flag);
      end if;


      Err := PCI_Enable_Device_Mem (PDev);

      if Err /= 0
      then
         dev_err (pdev.dev'Access, "Cannot re-enable PCI device after reset.");
         Result := PCI_ERS_RESULT_DISCONNECT;

      else
         PDev.State_Saved := True;
         PCI_Restore_State (PDev);
         PCI_Set_Master    (PDev);

         Unused := PCI_Enable_Wake (PDev, PCI_D3hot,  False);
         Unused := PCI_Enable_Wake (PDev, PCI_D3cold, False);

         E1000e_Reset (Adapter'Access);
         EW32 (Hw.all, E1000_WUS, not 0);
         Result := PCI_ERS_RESULT_RECOVERED;
      end if;


      return Result;
   end E1000_IO_Slot_Reset;




   ---------------------
   -- E1000_IO_Resume --
   ---------------------

   --    Called when traffic can start flowing again.
   --
   --  * @pdev: Pointer to PCI device.
   --  *
   --  * This callback is called when the error recovery driver tells us that
   --  * its OK to resume normal operation. Implementation resembles the
   --  * second-half of the e1000e_pm_resume routine.


   procedure E1000_IO_Resume
     (PDev : access PCI_Dev)
   is
      Netdev  : aliased Net_Device
        with
          Import,
          Address => pci_get_drvdata (PDev);

      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev'Access);

      Unused  :         C.int;

   begin
      e1000_init_manageability_pt (Adapter'Access);

      Unused := e1000e_pm_thaw (PDev.Dev'Access);

      -- If the controller has AMT, do not set DRV_LOAD until the interface
      -- is up. For all other cases, let the f/w know that the h/w is now
      -- under the control of the driver.
      --
      if (Adapter.Flags and C.unsigned (FLAG_HAS_AMT)) = 0
      then
         e1000e_get_hw_control (Adapter'Access);
      end if;
   end E1000_IO_Resume;




   -----------------------------
   -- E1000_Print_Device_Info --
   -----------------------------

   procedure E1000_Print_Device_Info
     (Adapter : access E1000_Adapter.item)
   is
      HW      : access E1000_HW   := Adapter.HW'Access;
      Netdev  : access Net_Device := Adapter.Netdev;
      Ret_Val :        Unsigned_32;
      PBA_Str :        String (1 .. E1000_PBANUM_LENGTH) := (others => ' ');


      --  function To_String
      --    (Mac_Addr : Mac_Address_Type) return String
      --  is
      --     Result : String (1 .. 17);
      --  begin
      --     for I in Mac_Addr'Range
      --     loop
      --        Result (3 * I - 2 .. 3 * I) := (if I = Mac_Addr'Last then Image (Mac_Addr (I))
      --                                                             else Image (Mac_Addr (I)) & ":");
      --     end loop;
      --
      --     return Result;
      --  end To_String;


   begin
      raise program_Error with "TODO";
      --  -- Print bus type/speed/width info.
      --  --
      --  e_info (  "(PCI Express:2.5GT/s:"
      --          & (if HW.Bus.Width = E1000_Bus_Width_Pcie_X4 then "Width x4"        -- Bus width.
      --                                                       else "Width x1")
      --          & ") "
      --          & To_String (Netdev.Dev_Addr));                                     -- MAC address.
      --
      --  e_info (  "Intel(R) PRO/"
      --          & (if HW.Phy.Typ = E1000_Phy_Ife then "10/100"
      --                                           else "1000")
      --          & " Network Connection");
      --
      --  Ret_Val := E1000_Read_PBA_String_Generic (HW, PBA_Str, E1000_PBANUM_LENGTH);
      --
      --  if Ret_Val /= 0
      --  then
      --     PBA_Str := "Unknown" & (PBA_Str'First + 7 .. PBA_Str'Last => ' ');
      --  end if;
      --
      --  e_info (  "MAC:"
      --          & HW.Mac.Typ'Image
      --          & ", PHY:"
      --          & HW.Phy.Typ'Image
      --          & ", PBA No: "
      --          & Trim (PBA_Str, Ada.Strings.Both));
   end E1000_Print_Device_Info;




   -------------------------
   -- E1000_EEPROM_Checks --
   -------------------------

   procedure E1000_EEPROM_Checks
     (Adapter : access E1000_Adapter.item)
   is
      HW      : constant access E1000_HW    := Adapter.HW'Access;
      Ret_Val :                 C.int;
      Buf     : aliased         Unsigned_16 := 0;

   begin
      if HW.Mac.mac_type /= E1000_82573
      then
         return;
      end if;


      Ret_Val := C.int (E1000_Read_NVM (HW, NVM_INIT_CONTROL2_REG, 1, Buf'unchecked_Access));
      le16_to_cpus (buf'Access);

      if          Ret_Val          = 0
        and then (Buf and BIT (0)) = 0
      then
         -- Deep Smart Power Down (DSPD).
         --
         dev_warn (adapter.pdev.dev'Access,
                   "Warning: detected DSPD enabled in EEPROM");
      end if;
   end E1000_EEPROM_Checks;




   ------------------------
   -- E1000_Fix_Features --
   ------------------------

   function E1000_Fix_Features
     (Netdev   : access Net_Device;
      Features : in     Netdev_Features_T) return Netdev_Features_T
   is
      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev);

      Hw      : constant access E1000_Hw          := Adapter.Hw'Access;
      Result  :                 Netdev_Features_T := Features;
   begin
      -- Jumbo frame workaround on 82579 and newer requires CRC be stripped.
      --
      if         Hw.Mac.Mac_Type >= E1000_Pch2lan
        and then Netdev.Mtu      > ETH_DATA_LEN
      then
         Result := Result and (not NETIF_F_RXFCS);
      end if;

      -- Since there is no support for separate Rx/Tx vlan accel
      -- enable/disable make sure Tx flag is always in same state as Rx.
      --
      if (Result and NETIF_F_HW_VLAN_CTAG_RX) /= 0
      then
         Result := Result or NETIF_F_HW_VLAN_CTAG_TX;
      else
         Result := Result and (not NETIF_F_HW_VLAN_CTAG_TX);
      end if;

      return Result;
   end E1000_Fix_Features;




   ------------------------
   -- E1000_Set_Features --
   ------------------------

   function E1000_Set_Features
     (Netdev   : access Net_Device;
      Features : in     Netdev_Features_T) return C.int
   is
      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev);

      Changed : constant Netdev_Features_T := Features xor Netdev.Features;

   begin
      if (     Changed
          and (NETIF_F_TSO or NETIF_F_TSO6)) /= 0
      then
         Adapter.Flags := Adapter.Flags or C.unsigned (FLAG_TSO_FORCE);
      end if;


      if (Changed and (   NETIF_F_HW_VLAN_CTAG_RX
                       or NETIF_F_HW_VLAN_CTAG_TX
                       or NETIF_F_RXCSUM
                       or NETIF_F_RXHASH
                       or NETIF_F_RXFCS
                       or NETIF_F_RXALL)) = 0
      then
         return 0;
      end if;


      if (Changed and NETIF_F_RXFCS) /= 0
      then
         if (Features and NETIF_F_RXFCS) /= 0
         then
            Adapter.Flags2 := Adapter.Flags2 and (not C.unsigned (FLAG2_CRC_STRIPPING));

         else
            -- We need to take it back to defaults, which might mean
            -- stripping is still disabled at the adapter level.
            --
            if (Adapter.Flags2 and C.unsigned (FLAG2_DFLT_CRC_STRIPPING)) /= 0
            then
               Adapter.Flags2 := Adapter.Flags2 or C.unsigned (FLAG2_CRC_STRIPPING);
            else
               Adapter.Flags2 := Adapter.Flags2 and (not C.unsigned (FLAG2_CRC_STRIPPING));
            end if;
         end if;
      end if;

      Netdev.Features := Features;

      if Netif_Running (Netdev)
      then
         E1000e_Reinit_Locked (Adapter'Access);
      else
         E1000e_Reset (Adapter'Access);
      end if;


      return 1;
   end E1000_Set_Features;




   E1000e_Netdev_Ops : aliased constant Net_Device_Ops := (Ndo_Open              => E1000e_Open            'Access,
                                                           Ndo_Stop              => E1000e_Close           'Access,
                                                           Ndo_Start_Xmit        => E1000_Xmit_Frame       'Access,
                                                           Ndo_Get_Stats64       => E1000e_Get_Stats64     'Access,
                                                           Ndo_Set_Rx_Mode       => E1000e_Set_Rx_Mode     'Access,
                                                           Ndo_Set_Mac_Address   => E1000_Set_Mac          'Access,
                                                           Ndo_Change_Mtu        => E1000_Change_Mtu       'Access,
                                                           Ndo_Eth_Ioctl         => E1000_Ioctl            'Access,
                                                           Ndo_Tx_Timeout        => E1000_Tx_Timeout       'Access,
                                                           Ndo_Validate_Addr     => Eth_Validate_Addr      'Access,
                                                           Ndo_Vlan_Rx_Add_Vid   => E1000_Vlan_Rx_Add_Vid  'Access,
                                                           Ndo_Vlan_Rx_Kill_Vid  => E1000_Vlan_Rx_Kill_Vid 'Access,
                                                           Ndo_Poll_Controller   => E1000_Netpoll          'Access,
                                                           Ndo_Set_Features      => E1000_Set_Features     'Access,
                                                           Ndo_Fix_Features      => E1000_Fix_Features     'Access,
                                                           Ndo_Features_Check    => Passthru_Features_Check'Access,
                                                           others => <>);




   -----------------
   -- E1000_Probe --
   -----------------

   --    Device Initialization Routine.
   --
   --  * @pdev: PCI device information struct.
   --  * @ent:  Entry in e1000_pci_tbl.
   --  *
   --  * Returns 0 on success, negative on failure
   --  *
   --  * e1000_probe initializes an adapter identified by a pci_dev structure.
   --  * The OS initialization, configuring of the adapter private structure,
   --  * and a hardware reset occur.


   Cards_Found : C.int := 0;


   function E1000_Probe
     (Pdev : access PCI_Dev;
      Ent  : access PCI_Device_ID) return C.int
   is
      use system.Memory_Copy;
      use type system.Address,
          Devices.e1000e.Hardware.func_arg1_e1000_hw_return_s32.item,
          C.unsigned_long_long;

      Netdev            : access          Net_Device;
      Adapter           : access          E1000_Adapter.item;
      HW                : access          E1000_HW;
      EI                : access constant E1000_Info.item   := E1000_Info_Tbl (e1000_boards'Val (Ent.Driver_Data));
      MMIO_Start        :                 Resource_Size_T;
      MMIO_Len          :                 Resource_Size_T;
      Flash_Start       :                 Resource_Size_T;
      Flash_Len         :                 Resource_Size_T;
      Aspm_Disable_Flag :                 U16               := 0;
      EEPROM_Data       : aliased         U16               := 0;
      EEPROM_APME_Mask  :                 U16               := E1000_EEPROM_APME;
      Bars,
      I,
      Err               :                 C.int;
      Ret_Val           :                 s32  := 0;
      Unused            :                 s32;
      Unused2           :                 C.int;

   begin
      if (EI.Flags2 and FLAG2_DISABLE_ASPM_L0S) /= 0
      then
         Aspm_Disable_Flag := PCIE_LINK_STATE_L0S;
      end if;

      if (EI.Flags2 and FLAG2_DISABLE_ASPM_L1) /= 0
      then
         Aspm_Disable_Flag := Aspm_Disable_Flag or PCIE_LINK_STATE_L1;
      end if;

      if Aspm_Disable_Flag /= 0
      then
         E1000e_Disable_ASPM (Pdev, Aspm_Disable_Flag);
      end if;

      Err := PCI_Enable_Device_Mem (Pdev);

      if Err /= 0
      then
         return Err;
      end if;

      Err := DMA_Set_Mask_And_Coherent (Pdev.Dev'Access, DMA_BIT_MASK (64));

      if Err /= 0
      then
         Dev_Err (Pdev.Dev'Access, "No usable DMA configuration, aborting\n");
         goto err_dma;
      end if;


      Bars := PCI_Select_Bars (Pdev, IORESOURCE_MEM);
      Err  := PCI_Request_Selected_Regions_Exclusive (Pdev, Bars, E1000e_Driver_Name);

      if Err /= 0
      then
         goto err_pci_reg;
      end if;


      PCI_Set_Master (Pdev);

      -- PCI config space info.
      --
      Err := PCI_Save_State (Pdev);

      if Err /= 0
      then
         goto err_alloc_etherdev;
      end if;


      Err    := -ENOMEM;
      Netdev := Alloc_Etherdev (E1000_Adapter.item'Size / 8);

      if Netdev = null
      then
         goto err_alloc_etherdev;
      end if;


      Set_Netdev_Dev (Netdev, Pdev.Dev'Access);

      Netdev.Irq := C.int (Pdev.Irq);

      PCI_Set_Drvdata (Pdev, Netdev.all'Address);
      Adapter                   := E1000_Adapter.Pointer (E1000_Adapter_Conversions.to_Pointer (Netdev_Priv (NetDev)));
      HW                        := Adapter.HW'unchecked_Access;
      Adapter.Netdev            := Netdev.all'unchecked_Access;
      Adapter.Pdev              := Pdev;
      Adapter.EI                := EI;
      Adapter.PBA               := EI.PBA;
      Adapter.Flags             := C.unsigned (EI.Flags);
      Adapter.Flags2            := C.unsigned (EI.Flags2);
      HW.Adapter                := Adapter;
      HW.MAC.Mac_Type           := EI.MAC;
      Adapter.Max_HW_Frame_Size := EI.Max_HW_Frame_Size;
      Adapter.Msg_Enable        := Netif_Msg_Init (Debug, C.int (DEFAULT_MSG_ENABLE));

      MMIO_Start := PCI_Resource_Start (Pdev, 0);
      MMIO_Len   := PCI_Resource_Len   (Pdev, 0);

      Err        := -EIO;
      HW.HW_Addr := Ioremap (MMIO_Start, C.size_t (MMIO_Len));

      if HW.HW_Addr = system.Null_Address
      then
         goto err_ioremap;
      end if;


      if    (Adapter.Flags and C.unsigned (FLAG_HAS_FLASH)) /= 0
        and (PCI_Resource_Flags (Pdev, 1) and IORESOURCE_MEM) /= 0
        and  HW.MAC.MAC_Type < E1000_PCH_SPT
      then
         Flash_Start      := PCI_Resource_Start (Pdev, 1);
         Flash_Len        := PCI_Resource_Len   (Pdev, 1);
         HW.Flash_Address := Ioremap (Flash_Start, C.size_t (Flash_Len));

         if HW.Flash_Address = system.null_Address
         then
            goto err_flashmap;
         end if;
      end if;


      -- Set default EEE advertisement.
      --
      if (Adapter.Flags2 and C.unsigned (FLAG2_HAS_EEE)) /= 0
      then
         Adapter.EEE_Advert := MDIO_EEE_100TX or MDIO_EEE_1000T;
      end if;

      -- Construct the net_device struct.
      --
      Netdev.Netdev_Ops     := E1000e_Netdev_Ops'Access;
      --  TODO: E1000e_Set_Ethtool_Ops (Netdev);
      Netdev.Watchdog_Timeo := 5 * HZ;
      Netif_Napi_Add (Netdev, Adapter.Napi'Access, E1000e_Poll'Access);

      -- TODO: Strscpy (Netdev.Name,
               --  PCI_Name (Pdev),
               --  Size_Of (Netdev.Name));

      Netdev.Mem_Start := C.unsigned_long (MMIO_Start);
      Netdev.Mem_End   := C.unsigned_long (MMIO_Start + MMIO_Len);

      Adapter.BD_Number := u32 (Cards_Found);
      Cards_Found       := Cards_Found + 1;

      -- TODO:   E1000e_Check_Options (Adapter);

      -- Setup adapter struct.
      --
      Err := E1000_SW_Init (Adapter);

      if Err /= 0
      then
         goto err_sw_init;
      end if;

      memcpy (hw.mac.ops'Address, ei.mac_ops'Address, hw.mac.ops'Size / 8);
      memcpy (hw.nvm.ops'Address, ei.nvm_ops'Address, hw.nvm.ops'Size / 8);
      memcpy (hw.phy.ops'Address, ei.phy_ops'Address, hw.phy.ops'Size / 8);

      Err := C.int (EI.Get_Variants (Adapter));

      if Err /= 0
      then
         goto err_hw_init;
      end if;

      if    (Adapter.Flags and C.unsigned (FLAG_IS_ICH))        /= 0
        and (Adapter.Flags and C.unsigned (FLAG_READ_ONLY_NVM)) /= 0
        and (HW.MAC.MAC_Type < E1000_PCH_SPT)
      then
         Devices.e1000e.Ich8Lan.E1000e_Write_Protect_NVM_ICH8LAN (HW);
      end if;

      Unused := HW.MAC.Ops.Get_Bus_Info (HW);
      HW.PHY.AutoNeg_Wait_To_Complete := False;

      -- Copper options.
      --
      if HW.PHY.Media_Type = E1000_Media_Type_Copper
      then
         HW.PHY.MDIX                        := AUTO_ALL_MODES;
         HW.PHY.Disable_Polarity_Correction := False;
         HW.PHY.MS_Type                     := E1000_MS_HW_Default;
      end if;

      if         HW.PHY.Ops.Check_Reset_Block /= null
        and then HW.PHY.Ops.Check_Reset_Block (HW) /= 0
      then
         Dev_Info (Pdev.Dev'Access,
                   "PHY reset is blocked due to SOL/IDER session.");
      end if;

      -- Set initial default active device features.
      --
      Netdev.Features :=    NETIF_F_SG
                         or NETIF_F_HW_VLAN_CTAG_RX
                         or NETIF_F_HW_VLAN_CTAG_TX
                         or NETIF_F_TSO
                         or NETIF_F_TSO6
                         or NETIF_F_RXHASH
                         or NETIF_F_RXCSUM
                         or NETIF_F_HW_CSUM;

      -- Disable TSO for pcie and 10/100 speeds to avoid
      -- some hardware issues and for i219 to fix transfer
      -- speed being capped at 60%.
      --
      if (Adapter.Flags and C.unsigned (FLAG_TSO_FORCE)) = 0
      then
         case Adapter.Link_Speed
         is
            when SPEED_10
               | SPEED_100 =>

               E_Info ("10/100 speed: disabling TSO");
               Netdev.Features := Netdev.Features and not NETIF_F_TSO;
               Netdev.Features := Netdev.Features and not NETIF_F_TSO6;

            when SPEED_1000 =>
               Netdev.Features := Netdev.Features or NETIF_F_TSO;
               Netdev.Features := Netdev.Features or NETIF_F_TSO6;

            when others =>
               null;     -- TODO: Raise an exception ? C does nothing.
         end case;

         if HW.MAC.MAC_Type = E1000_PCH_SPT
         then
            Netdev.Features := Netdev.Features and not NETIF_F_TSO;
            Netdev.Features := Netdev.Features and not NETIF_F_TSO6;
         end if;
      end if;


      -- Set user-changeable features (subset of all device features).
      --
      Netdev.HW_Features := Netdev.Features;
      Netdev.HW_Features := Netdev.HW_Features or NETIF_F_RXFCS;
      Netdev.Priv_Flags  := Netdev.Priv_Flags  or C.unsigned_long_long (IFF_SUPP_NOFCS);
      Netdev.HW_Features := Netdev.HW_Features or NETIF_F_RXALL;

      if (Adapter.Flags and C.unsigned (FLAG_HAS_HW_VLAN_FILTER)) /= 0
      then
         Netdev.Features := Netdev.Features or NETIF_F_HW_VLAN_CTAG_FILTER;
      end if;

      Netdev.VLAN_Features :=    NETIF_F_SG
                              or NETIF_F_TSO
                              or NETIF_F_TSO6
                              or NETIF_F_HW_CSUM;

      Netdev.Priv_Flags    := Netdev.Priv_Flags    or IFF_UNICAST_FLT'enum_Rep;
      Netdev.Features      := Netdev.Features      or NETIF_F_HIGHDMA;
      Netdev.VLAN_Features := Netdev.VLAN_Features or NETIF_F_HIGHDMA;

      -- MTU range: 68 - max_hw_frame_size.
      --
      Netdev.Min_MTU := ETH_MIN_MTU;
      Netdev.Max_MTU := C.unsigned (Adapter.Max_HW_Frame_Size - (VLAN_ETH_HLEN + ETH_FCS_LEN));

      if Devices.e1000e.Manage.E1000e_Enable_MNG_Pass_Thru (HW)
      then
         Adapter.Flags := Adapter.Flags or C.unsigned (FLAG_MNG_PT_ENABLED);
      end if;

      -- Before reading the NVM, reset the controller to
      -- put the device in a known good starting state.
      --
      Unused := HW.MAC.Ops.Reset_HW (HW);

      -- Validate NVM checksum with retries.
      --
      I := 0;

      loop
         if E1000_Validate_NVM_Checksum (HW) >= 0
         then
            exit;
         end if;

         if I = 2
         then
            Dev_Err (Pdev.Dev'Access, "The NVM Checksum Is Not Valid\n");
            err := -EIO;
            goto err_eeprom;
         end if;

         I := I + 1;
      end loop;


      E1000_EEPROM_Checks (Adapter);

      -- Copy the MAC address.
      --
      if E1000e_Read_MAC_Addr (HW) /= 0
      then
         Dev_Err (Pdev.Dev'Access, "NVM Read Error while reading MAC address\n");
      end if;

      Eth_HW_Addr_Set (Netdev, HW.MAC.Addr (0)'unchecked_Access);

      if not Is_Valid_Ether_Addr (Netdev.Dev_Addr)
      then
         Dev_Err (Pdev.Dev'Access, "Invalid MAC Address: " & Netdev.Dev_Addr'Image & "M");
         err := -EIO;
         goto err_eeprom;
      end if;

      Timer_Setup (Adapter.Watchdog_Timer'Access, E1000_Watchdog       'Access, 0);
      Timer_Setup (Adapter.PHY_Info_Timer'Access, E1000_Update_PHY_Info'Access, 0);

      Init_Work (Adapter.Reset_Task     'Access, E1000_Reset_Task           'Access);
      Init_Work (Adapter.Watchdog_Task  'Access, E1000_Watchdog_Task        'Access);
      Init_Work (Adapter.Downshift_Task 'Access, E1000e_Downshift_Workaround'Access);
      Init_Work (Adapter.Update_PHY_Task'Access, E1000e_Update_PHY_Task     'Access);
      Init_Work (Adapter.Print_Hang_Task'Access, E1000_Print_HW_Hang        'Access);

      -- Initialize link parameters. User can change them with ethtool.
      --
      HW.MAC.AutoNeg            := True;
      Adapter.FC_AutoNeg        := True;
      HW.FC.Requested_Mode      := E1000_FC_Default;
      HW.FC.Current_Mode        := E1000_FC_Default;
      HW.PHY.AutoNeg_Advertised := 16#2F#;

      -- Initial Wake on LAN setting - If APM wake is enabled in
      -- the EEPROM, enable the ACPI Magic Packet filter.
      --
      if (Adapter.Flags and C.unsigned (FLAG_APME_IN_WUC)) /= 0
      then
         EEPROM_Data      := u16 (ER32 (Hw.all, E1000_WUC));
         EEPROM_APME_Mask := E1000_WUC_APME;

         if    HW.MAC.MAC_Type > E1000_ICH10LAN
           and (EEPROM_Data and E1000_WUC_PHY_WAKE) /= 0
         then
            Adapter.Flags2 := Adapter.Flags2 or C.unsigned (FLAG2_HAS_PHY_WAKEUP);
         end if;

      elsif (Adapter.Flags and C.unsigned (FLAG_APME_IN_CTRL3)) /= 0
      then
         if    (Adapter.Flags and C.unsigned (FLAG_APME_CHECK_PORT_B)) /= 0
           and HW.Bus.Func = 1
         then
            Ret_Val := E1000_Read_NVM (HW, NVM_INIT_CONTROL3_PORT_B, 1, EEPROM_Data'unchecked_Access);
         else
            Ret_Val := E1000_Read_NVM (HW, NVM_INIT_CONTROL3_PORT_A, 1, EEPROM_Data'unchecked_Access);
         end if;
      end if;


      -- Fetch WoL from EEPROM.
      --
      if Ret_Val /= 0
      then
         E_Dbg ("NVM read error getting WoL initial values:" & Ret_Val'Image);

      elsif (EEPROM_Data and EEPROM_APME_Mask) /= 0
      then
         Adapter.EEPROM_WOL := Adapter.EEPROM_WOL or E1000_WUFC_MAG;
      end if;

      -- Now that we have the eeprom settings, apply the special cases
      -- where the eeprom may be wrong or the board simply won't support
      -- wake on lan on a particular port.
      --
      if (Adapter.Flags and C.unsigned (FLAG_HAS_WOL)) = 0
      then
         Adapter.WOL := 0;
      end if;

      -- Initialize the WOL settings based on the EEPROM settings.
      --
      Adapter.WOL := Adapter.EEPROM_WOL;

      -- Ensure adapter isn't asleep if manageability is enabled.
      --
      if    Adapter.WOL /= 0
        or (Adapter.Flags and C.unsigned (FLAG_MNG_PT_ENABLED)) /= 0
        or (HW.MAC.Ops.Check_MNG_Mode (HW))
      then
         Unused2 := Device_Wakeup_Enable (Pdev.Dev'Access);
      end if;

      -- Save off EEPROM version number.
      --
      Ret_Val := E1000_Read_NVM (HW, 5, 1, Adapter.EEPROM_Vers'unchecked_Access);

      if Ret_Val /= 0
      then
         E_Dbg ("NVM read error getting EEPROM version:" & Ret_Val'Image);
         Adapter.EEPROM_Vers := 0;
      end if;

      -- Initialize PTP hardware clock.
      --
      Devices.e1000e.Precision_Time_Protocol.E1000e_PTP_Init (Adapter);

      -- Reset the hardware with the new settings.
      --
      E1000e_Reset (Adapter);

      -- If the controller has AMT, do not set DRV_LOAD until the interface
      -- is up.  For all other cases, let the f/w know that the h/w is now
      -- under the control of the driver.
      --
      if (Adapter.Flags and C.unsigned (FLAG_HAS_AMT)) = 0
      then
         E1000e_Get_HW_Control (Adapter);
      end if;

      if HW.MAC.MAC_Type >= E1000_PCH_CNP
      then
         Adapter.Flags2 := Adapter.Flags2 or C.unsigned (FLAG2_ENABLE_S0IX_FLOWS);
      end if;

      Netdev.Name (1 .. 5) := "eth%d";     -- strscpy(netdev->name, "eth%d", sizeof(netdev->name));

      Err := Register_Netdev (Netdev);

      if Err /= 0
      then
         goto err_register;
      end if;


      -- Carrier off reporting is important to ethtool even BEFORE open.
      --
      Netif_Carrier_Off (Netdev);

      E1000_Print_Device_Info (Adapter);
      Dev_PM_Set_Driver_Flags (Pdev.Dev'Access, DPM_FLAG_SMART_PREPARE);

      if PCI_Dev_Run_Wake (Pdev)
      then
         PM_Runtime_Put_Noidle (Pdev.Dev'Access);
      end if;

      return 0;


      -- Error handling sections.
      --

      <<Err_Register>>

      if (Adapter.Flags and C.unsigned (FLAG_HAS_AMT)) = 0
      then
         E1000e_Release_HW_Control (Adapter);
      end if;


      <<Err_EEPROM>>

      if    HW.PHY.Ops.Check_Reset_Block /= null
        and HW.PHY.Ops.Check_Reset_Block (HW) = 0
      then
         Unused := E1000_PHY_HW_Reset (HW);
      end if;


      <<Err_HW_Init>>

      kFree (Adapter.Tx_Ring.all'Address);
      kFree (Adapter.Rx_Ring.all'Address);


      <<Err_SW_Init>>

      if    HW.Flash_Address /= system.Null_Address
        and HW.MAC.Mac_Type   < E1000_PCH_SPT
      then
         Iounmap (HW.Flash_Address);
      end if;

      E1000e_Reset_Interrupt_Capability (Adapter);


      <<Err_Flashmap>>

      Iounmap (HW.HW_Addr);


      <<Err_Ioremap>>

      Free_Netdev (Netdev);


      <<Err_Alloc_Etherdev>>

      PCI_Release_Mem_Regions (Pdev);


      <<Err_PCI_Reg>>
      <<Err_DMA>>

      PCI_Disable_Device (Pdev);

      return Err;
   end E1000_Probe;



   ------------------
   -- E1000_Remove --
   ------------------

   --    Device Removal Routine.
   --
   --  * @pdev: PCI device information struct
   --  *
   --  * e1000_remove is called by the PCI subsystem to alert the driver
   --  * that it should release a PCI device.  This could be caused by a
   --  * Hot-Plug event, or because the driver is going to be removed from
   --  * memory.


   procedure E1000_Remove
     (PDev : access PCI_Dev)
   is
      use type system.Address;

      Netdev  : aliased Net_Device
        with
          Import,
          Address => PCI_Get_Drvdata (Pdev);

      Adapter : aliased E1000_Adapter.item
        with
          Import,
          Address => Netdev_Priv (Netdev'Access);

      Unused  : C.int;
      Unused2 : Boolean;

   begin
      Devices.e1000e.Precision_Time_Protocol.E1000e_PTP_Remove (Adapter'Access);

      -- The timers may be rescheduled, so explicitly disable them
      -- from being rescheduled.
      --
      Set_Bit (E1000_DOWN'enum_Rep, Adapter.State'Address);
      Unused := Del_Timer_Sync (Adapter.Watchdog_Timer'Access);
      Unused := Del_Timer_Sync (Adapter.Phy_Info_Timer'Access);

      Unused2 := Cancel_Work_Sync (Adapter.Reset_Task     'Access);
      Unused2 := Cancel_Work_Sync (Adapter.Watchdog_Task  'Access);
      Unused2 := Cancel_Work_Sync (Adapter.Downshift_Task 'Access);
      Unused2 := Cancel_Work_Sync (Adapter.Update_Phy_Task'Access);
      Unused2 := Cancel_Work_Sync (Adapter.Print_Hang_Task'Access);

      if (Adapter.Flags and C.unsigned (FLAG_HAS_HW_TIMESTAMP)) /= 0
      then
         Unused2 := Cancel_Work_Sync (Adapter.Tx_Hwtstamp_Work'Access);

         if Adapter.Tx_Hwtstamp_Skb /= null
         then
            Dev_Consume_Skb_Any (Adapter.Tx_Hwtstamp_Skb);
            Adapter.Tx_Hwtstamp_Skb := null;
         end if;
      end if;

      Unregister_Netdev (Netdev'Access);

      if PCI_Dev_Run_Wake (PDev)
      then
         PM_Runtime_Get_Noresume (PDev.Dev'Access);
      end if;

      -- Release control of h/w to f/w.  If f/w is AMT enabled, this
      -- would have already happened in close and is redundant.
      --
      E1000e_Release_HW_Control         (Adapter'Access);
      E1000e_Reset_Interrupt_Capability (Adapter'Access);

      kFree (Adapter.Tx_Ring.all'Address);
      kFree (Adapter.Rx_Ring.all'Address);

      Iounmap (Adapter.HW.HW_Addr);

      if         Adapter.HW.Flash_Address /= system.null_Address
        and then Adapter.HW.Mac.mac_type   < E1000_Pch_Spt
      then
         Iounmap (Adapter.HW.Flash_Address);
      end if;

      PCI_Release_Mem_Regions (PDev);
      Free_Netdev (Netdev'Access);

      PCI_Disable_Device (PDev);
   end E1000_Remove;




   ------------------------------
   -- PCI Error Recovery (ERS) --
   ------------------------------

     --   E1000_Err_Handler : constant PCI_Error_Handlers :=
     --  (Error_Detected => E1000_Error_Handlers.E1000_IO_Error_Detected'Access,
     --   Slot_Reset     => E1000_Error_Handlers.E1000_IO_Slot_Reset'Access,
     --   Resume         => E1000_Error_Handlers.E1000_IO_Resume'Access);





   -------------------
   -- Pci_Device_Id --
   -------------------

   --     type Pci_Device_Id is record
   --     Vendor_Id : Integer;
   --     Device_Id : Integer;
   --     Subsystem_Id : Integer;
   --     Subsystem_Vendor_Id : Integer;
   --     Board : access Board_Type; -- Assuming Board_Type is defined elsewhere
   --  end record;
   --
   --  type Pci_Device_Id_Array is array (Natural range <>) of Pci_Device_Id;
   --
   --  E1000_PCI_TBL : constant Pci_Device_Id_Array(0 .. 255) := (
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_82571EB_COPPER), Board => Board_82571),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_82571EB_FIBER), Board => Board_82571),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_82571EB_QUAD_COPPER), Board => Board_82571),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_82571EB_QUAD_COPPER_LP), Board => Board_82571),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_82571EB_QUAD_FIBER), Board => Board_82571),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_82571EB_SERDES), Board => Board_82571),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_82571EB_SERDES_DUAL), Board => Board_82571),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_82571EB_SERDES_QUAD), Board => Board_82571),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_82571PT_QUAD_COPPER), Board => Board_82571),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_82572EI), Board => Board_82572),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_82572EI_COPPER), Board => Board_82572),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_82572EI_FIBER), Board => Board_82572),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_82572EI_SERDES), Board => Board_82572),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_82573E), Board => Board_82573),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_82573E_IAMT), Board => Board_82573),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_82573L), Board => Board_82573),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_82574L), Board => Board_82574),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_82574LA), Board => Board_82574),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_82583V), Board => Board_82583),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_80003ES2LAN_COPPER_DPT), Board => Board_80003es2lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_80003ES2LAN_COPPER_SPT), Board => Board_80003es2lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_80003ES2LAN_SERDES_DPT), Board => Board_80003es2lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_80003ES2LAN_SERDES_SPT), Board => Board_80003es2lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_ICH8_IFE), Board => Board_ich8lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_ICH8_IFE_G), Board => Board_ich8lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_ICH8_IFE_GT), Board => Board_ich8lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_ICH8_IGP_AMT), Board => Board_ich8lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_ICH8_IGP_C), Board => Board_ich8lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_ICH8_IGP_M), Board => Board_ich8lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_ICH8_IGP_M_AMT), Board => Board_ich8lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_ICH8_82567V_3), Board => Board_ich8lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_ICH9_IFE), Board => Board_ich9lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_ICH9_IFE_G), Board => Board_ich9lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_ICH9_IFE_GT), Board => Board_ich9lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_ICH9_IGP_AMT), Board => Board_ich9lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_ICH9_IGP_C), Board => Board_ich9lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_ICH9_BM), Board => Board_ich9lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_ICH9_IGP_M), Board => Board_ich9lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_ICH9_IGP_M_AMT), Board => Board_ich9lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_ICH10_R_BM_LM), Board => Board_ich9lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_ICH10_R_BM_LF), Board => Board_ich9lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_ICH10_R_BM_V), Board => Board_ich9lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_ICH10_D_BM_LM), Board => Board_ich10lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_ICH10_D_BM_LF), Board => Board_ich10lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_ICH10_D_BM_V), Board => Board_ich10lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_M_HV_LM), Board => Board_pchlan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_M_HV_LC), Board => Board_pchlan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_D_HV_DM), Board => Board_pchlan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_D_HV_DC), Board => Board_pchlan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH2_LV_LM), Board => Board_pch2lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH2_LV_V), Board => Board_pch2lan),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_LPT_I217_LM), Board => Board_pch_lpt),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_LPT_I217_V), Board => Board_pch_lpt),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_LPTLP_I218_LM), Board => Board_pch_lpt),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_LPTLP_I218_V), Board => Board_pch_lpt),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_I218_LM2), Board => Board_pch_lpt),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_I218_V2), Board => Board_pch_lpt),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_I218_LM3), Board => Board_pch_lpt),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_I218_V3), Board => Board_pch_lpt),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_SPT_I219_LM), Board => Board_pch_spt),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_SPT_I219_V), Board => Board_pch_spt),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_SPT_I219_LM2), Board => Board_pch_spt),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_SPT_I219_V2), Board => Board_pch_spt),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_LBG_I219_LM3), Board => Board_pch_spt),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_SPT_I219_LM4), Board => Board_pch_spt),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_SPT_I219_V4), Board => Board_pch_spt),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_SPT_I219_LM5), Board => Board_pch_spt),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_SPT_I219_V5), Board => Board_pch_spt),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_CNP_I219_LM6), Board => Board_pch_cnp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_CNP_I219_V6), Board => Board_pch_cnp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_CNP_I219_LM7), Board => Board_pch_cnp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_CNP_I219_V7), Board => Board_pch_cnp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_ICP_I219_LM8), Board => Board_pch_cnp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_ICP_I219_V8), Board => Board_pch_cnp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_ICP_I219_LM9), Board => Board_pch_cnp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_ICP_I219_V9), Board => Board_pch_cnp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_CMP_I219_LM10), Board => Board_pch_cnp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_CMP_I219_V10), Board => Board_pch_cnp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_CMP_I219_LM11), Board => Board_pch_cnp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_CMP_I219_V11), Board => Board_pch_cnp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_CMP_I219_LM12), Board => Board_pch_spt),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_CMP_I219_V12), Board => Board_pch_spt),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_TGP_I219_LM13), Board => Board_pch_tgp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_TGP_I219_V13), Board => Board_pch_tgp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_TGP_I219_LM14), Board => Board_pch_tgp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_TGP_I219_V14), Board => Board_pch_tgp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_TGP_I219_LM15), Board => Board_pch_tgp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_TGP_I219_V15), Board => Board_pch_tgp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_RPL_I219_LM23), Board => Board_pch_adp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_RPL_I219_V23), Board => Board_pch_adp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_ADP_I219_LM16), Board => Board_pch_adp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_ADP_I219_V16), Board => Board_pch_adp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_ADP_I219_LM17), Board => Board_pch_adp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_ADP_I219_V17), Board => Board_pch_adp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_RPL_I219_LM22), Board => Board_pch_adp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_RPL_I219_V22), Board => Board_pch_adp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_MTP_I219_LM18), Board => Board_pch_mtp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_MTP_I219_V18), Board => Board_pch_mtp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_MTP_I219_LM19), Board => Board_pch_mtp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_MTP_I219_V19), Board => Board_pch_mtp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_LNP_I219_LM20), Board => Board_pch_mtp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_LNP_I219_V20), Board => Board_pch_mtp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_LNP_I219_LM21), Board => Board_pch_mtp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_LNP_I219_V21), Board => Board_pch_mtp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_ARL_I219_LM24), Board => Board_pch_mtp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_ARL_I219_V24), Board => Board_pch_mtp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_PTP_I219_LM25), Board => Board_pch_mtp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_PTP_I219_V25), Board => Board_pch_mtp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_PTP_I219_LM26), Board => Board_pch_mtp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_PTP_I219_V26), Board => Board_pch_mtp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_PTP_I219_LM27), Board => Board_pch_mtp),
   --     (Vendor_Id => PCI_VDEVICE(INTEL, E1000_DEV_ID_PCH_PTP_I219_V27), Board => Board_pch_mtp),
   --     (Vendor_Id => 0, Device_Id => 0, Subsystem_Id => 0, Subsystem_Vendor_Id => 0, Board => null)     -- Terminate list.
   --  );


   --  MODULE_DEVICE_TABLE (pci, e1000_pci_tbl);




   ----------------
   -- Dev_PM_Ops --
   ----------------

   --     type Dev_PM_Ops is record
   --     Prepare   : access function (Device : System.Address) return Integer;
   --     Suspend   : access function (Device : System.Address) return Integer;
   --     Resume    : access function (Device : System.Address) return Integer;
   --     Freeze    : access function (Device : System.Address) return Integer;
   --     Thaw      : access function (Device : System.Address) return Integer;
   --     Poweroff  : access function (Device : System.Address) return Integer;
   --     Restore   : access function (Device : System.Address) return Integer;
   --     Runtime_Suspend : access function (Device : System.Address) return Integer;
   --     Runtime_Resume  : access function (Device : System.Address) return Integer;
   --     Runtime_Idle    : access function (Device : System.Address) return Integer;
   --  end record;
   --
   --  E1000e_PM_Ops : constant Dev_PM_Ops := (
   --     Prepare   => E1000e_PM_Prepare'Access,
   --     Suspend   => E1000e_PM_Suspend'Access,
   --     Resume    => E1000e_PM_Resume'Access,
   --     Freeze    => E1000e_PM_Freeze'Access,
   --     Thaw      => E1000e_PM_Thaw'Access,
   --     Poweroff  => E1000e_PM_Suspend'Access,
   --     Restore   => E1000e_PM_Resume'Access,
   --     Runtime_Suspend => E1000e_PM_Runtime_Suspend'Access,
   --     Runtime_Resume  => E1000e_PM_Runtime_Resume'Access,
   --     Runtime_Idle    => E1000e_PM_Runtime_Idle'Access
   --  );




   ------------------
   -- E1000_Driver --
   ------------------

   --     type E1000_PCI_Driver is new PCI.PCI_Driver with record
   --     Name         : String := "e1000e_driver";
   --     ID_Table     : PCI.PCI_Device_ID_Table := E1000_PCI_Tbl;
   --     Probe        : PCI.Probe_Function := E1000_Probe'Access;
   --     Remove       : PCI.Remove_Function := E1000_Remove'Access;
   --     PM_Ops       : PCI.PM_Operations := E1000e_PM_Ops'Access;
   --     Shutdown     : PCI.Shutdown_Function := E1000_Shutdown'Access;
   --     Error_Handler : PCI.Error_Handler := E1000_Err_Handler'Access;
   --  end record;
   --
   --  E1000_Driver : aliased E1000_PCI_Driver;     -- PCI Device API Driver.




   -----------------------
   -- E1000_Init_Module --
   -----------------------

   --    Driver Registration Routine.
   --
   --  * E1000_Init_Module is the first routine called when the driver is
   --  * loaded. All it does is register with the PCI subsystem.


   --  function E1000_Init_Module return C.int
   --  is
   --  begin
   --     pr_info ("Intel(R) PRO/1000 Network Driver");
   --     pr_info ("Copyright(c) 1999 - 2015 Intel Corporation.");
   --
   --     return PCI_Register_Driver (e1000_driver'Access);
   --  end E1000_Init_Module;


   --  module_init (e1000_init_module);




   --  procedure E1000_Exit_Module
   --  is
   --  begin
   --     PCI_Unregister_Driver (E1000_Driver'Access);
   --  end E1000_Exit_Module;


   --  module_exit (e1000_exit_module);




   --  MODULE_DESCRIPTION ("Intel(R) PRO/1000 Network Driver");
   --  MODULE_LICENSE ("GPL v2");


end Devices.e1000e.NetDev;
