with
     Devices.e1000e.Core,
     Devices.e1000e.Ich8Lan,
     System.Storage_Elements,
     Interfaces.C;


package Devices.e1000e.Registers with SPARK_Mode => On
is
   use Devices.e1000e.Core,
       Interfaces;

   use type C.unsigned_long;


   E1000_CTRL        : constant := 16#0#;              -- Device Control - RW.
   E1000_STATUS      : constant := 16#8#;              -- Device Status - RO.
   E1000_EECD        : constant := 16#10#;             -- EEPROM/Flash Control - RW.
   E1000_EERD        : constant := 16#14#;             -- EEPROM Read - RW.
   E1000_CTRL_EXT    : constant := 16#18#;             -- Extended Device Control - RW.
   E1000_FLA         : constant := 16#1c#;             -- Flash Access - RW.
   E1000_MDIC        : constant := 16#20#;             -- MDI Control - RW.
   E1000_SCTL        : constant := 16#24#;             -- SerDes Control - RW.
   E1000_FCAL        : constant := 16#28#;             -- Flow Control Address Low - RW.
   E1000_FCAH        : constant := 16#2c#;             -- Flow Control Address High - RW.
   E1000_FEXT        : constant := 16#2c#;             -- Future Extended - RW.
   E1000_FEXTNVM     : constant := 16#28#;             -- Future Extended NVM - RW.
   E1000_FEXTNVM3    : constant := 16#3c#;             -- Future Extended NVM 3 - RW.
   E1000_FEXTNVM4    : constant := 16#24#;             -- Future Extended NVM 4 - RW.
   E1000_FEXTNVM5    : constant := 16#14#;             -- Future Extended NVM 5 - RW.
   E1000_FEXTNVM6    : constant := 16#10#;             -- Future Extended NVM 6 - RW.
   E1000_FEXTNVM7    : constant := 16#e4#;             -- Future Extended NVM 7 - RW.
   E1000_FEXTNVM8    : constant := 16#5bb0#;           -- Future Extended NVM 8 - RW.
   E1000_FEXTNVM9    : constant := 16#5bb4#;           -- Future Extended NVM 9 - RW.
   E1000_FEXTNVM11   : constant := 16#5bbc#;           -- Future Extended NVM 11 - RW.
   E1000_FEXTNVM12   : constant := 16#5bc0#;           -- Future Extended NVM 12 - RW.
   E1000_PCIEANACFG  : constant := 16#f18#;            -- PCIE Analog Config.
   E1000_DPGFR       : constant := 16#fac#;            -- Dynamic Power Gate Force Control Register.
   E1000_FCT         : constant := 16#30#;             -- Flow Control Type - RW.
   E1000_VET         : constant := 16#38#;             -- VLAN Ether Type - RW.
   E1000_ICR         : constant := 16#c0#;             -- Interrupt Cause Read - R/clr.
   E1000_ITR         : constant := 16#c4#;             -- Interrupt Throttling Rate - RW.
   E1000_ICS         : constant := 16#c8#;             -- Interrupt Cause Set - WO.
   E1000_IMS         : constant := 16#d0#;             -- Interrupt Mask Set - RW.
   E1000_IMC         : constant := 16#d8#;             -- Interrupt Mask Clear - WO.
   E1000_IAM         : constant := 16#e0#;             -- Interrupt Acknowledge Auto Mask.
   E1000_IVAR        : constant := 16#e4#;             -- Interrupt Vector Allocation Register - RW.
   E1000_SVCR        : constant := 16#f0#;
   E1000_SVT         : constant := 16#f4#;
   E1000_LPIC        : constant := 16#fc#;             -- Low Power IDLE control.
   E1000_RCTL        : constant := 16#100#;            -- Rx Control - RW.
   E1000_FCTTV       : constant := 16#170#;            -- Flow Control Transmit Timer Value - RW.
   E1000_TXCW        : constant := 16#178#;            -- Tx Configuration Word - RW.
   E1000_RXCW        : constant := 16#180#;            -- Rx Configuration Word - RO.
   E1000_PBA_ECC     : constant := 16#1100#;           -- PBA ECC Register.
   E1000_TCTL        : constant := 16#400#;            -- Tx Control - RW.
   E1000_TCTL_EXT    : constant := 16#404#;            -- Extended Tx Control - RW.
   E1000_TIPG        : constant := 16#410#;            -- Tx Inter-packet gap -RW.
   E1000_AIT         : constant := 16#458#;            -- Adaptive Interframe Spacing Throttle - RW.
   E1000_LEDCTL      : constant := 16#e00#;            -- LED Control - RW.
   E1000_EXTCNF_CTRL : constant := 16#f00#;            -- Extended Configuration Control.
   E1000_EXTCNF_SIZE : constant := 16#f08#;            -- Extended Configuration Size.
   E1000_PHY_CTRL    : constant := 16#f10#;            -- PHY Control Register in CSR.
   E1000_POEMB       : constant := E1000_PHY_CTRL;     -- PHY OEM Bits.
   E1000_PBA         : constant := 16#1000#;           -- Packet Buffer Allocation - RW.
   E1000_PBS         : constant := 16#1008#;           -- Packet Buffer Size.
   E1000_PBECCSTS    : constant := 16#100c#;           -- Packet Buffer ECC Status - RW.
   E1000_IOSFPC      : constant := 16#f28#;            -- TX corrupted data.
   E1000_EEMNGCTL    : constant := 16#1010#;           -- MNG EEprom Control.
   E1000_EEWR        : constant := 16#102c#;           -- EEPROM Write Register - RW.
   E1000_FLOP        : constant := 16#103c#;           -- FLASH Opcode Register.
   E1000_ERT         : constant := 16#2008#;           -- Early Rx Threshold - RW.
   E1000_FCRTL       : constant := 16#2160#;           -- Flow Control Receive Threshold Low - RW.
   E1000_FCRTH       : constant := 16#2168#;           -- Flow Control Receive Threshold High - RW.
   E1000_PSRCTL      : constant := 16#2170#;           -- Packet Split Receive Control - RW.
   E1000_RDFH        : constant := 16#2410#;           -- Rx Data FIFO Head - RW.
   E1000_RDFT        : constant := 16#2418#;           -- Rx Data FIFO Tail - RW.
   E1000_RDFHS       : constant := 16#2420#;           -- Rx Data FIFO Head Saved - RW.
   E1000_RDFTS       : constant := 16#2428#;           -- Rx Data FIFO Tail Saved - RW.
   E1000_RDFPC       : constant := 16#2430#;           -- Rx Data FIFO Packet Count - RW.

   -- Split and Replication Rx Control - RW.
   --
   E1000_RDTR        : constant := 16#2820#;           -- Rx Delay Timer - RW.
   E1000_RADV        : constant := 16#282c#;           -- Rx Interrupt Absolute Delay Timer - RW.



   -- Convenience macros.
   --
   -- Note: "_n" is the queue number of the register to be written to.
   --
   -- Example usage:
   -- E1000_RDBAL_REG (current_rx_queue)
   --

   use System.Storage_Elements;
   use type C.size_t;


   function E1000_RDBAL (n : in Integer_Address) return u32
   is
     (u32 (if n < 4 then 16#02800# + n * 16#100#
                    else 16#0C000# + n * 16#40#));

   function E1000_RDBAH (n : in Integer_Address) return u32
   is
     (u32 (if n < 4 then 16#02804# + n * 16#100#
                    else 16#0C004# + n * 16#40#));

   function E1000_RDLEN (n : in Integer_Address) return u32
   is
     (u32 (if n < 4 then 16#02808# + n * 16#100#
                    else 16#0C008# + n * 16#40#));

   function E1000_RDH (n : in Integer_Address) return u32
   is
     (u32 (if n < 4 then 16#02810# + n * 16#100#
                    else 16#0C010# + n * 16#40#));

   function E1000_RDT (n : in Integer_Address) return u32
   is
     (u32 (if n < 4 then 16#02818# + n * 16#100#
                    else 16#0C018# + n * 16#40#));

   function E1000_RXDCTL (n : in C.size_t) return C.unsigned_Long
   is
     (C.unsigned_Long (if n < 4 then 16#02828# + n * 16#100#
                                else 16#0C028# + n * 16#40#));

   function E1000_TDBAL (n : in Integer_Address) return u32
   is
     (u32 (if n < 4 then 16#03800# + n * 16#100#
                    else 16#0E000# + n * 16#40#));

   function E1000_TDBAH (n : in Integer_Address) return u32
   is
     (u32 (if n < 4 then 16#03804# + n * 16#100#
                    else 16#0E004# + n * 16#40#));

   function E1000_TDLEN (n : in C.size_t) return C.unsigned_Long
   is
     (C.unsigned_Long (if n < 4 then 16#03808# + n * 16#100#
                                else 16#0E008# + n * 16#40#));

   function E1000_TDH (n : in Integer_Address) return u32
   is
     (u32 (if n < 4 then 16#03810# + n * 16#100#
                    else 16#0E010# + n * 16#40#));

   function E1000_TDT (n : in C.size_t) return C.unsigned_Long
   is
     (C.unsigned_Long (if n < 4 then 16#03818# + n * 16#100#
                                else 16#0E018# + n * 16#40#));

   function E1000_TXDCTL (n : in C.size_t) return C.unsigned_Long
   is
     (C.unsigned_long (if n < 4 then 16#03828# + n * 16#100#
                                else 16#0E028# + n * 16#40#));

   function E1000_TARC (n : in C.size_t) return C.unsigned_Long
   is
     (C.unsigned_Long (16#03840# + n * 16#100#));


   E1000_KABGTXD : constant := 16#3004#;     -- AFE Band Gap Transmit Ref Data


   function E1000_RAL (i : in u32) return C.unsigned_Long
   is
     (C.unsigned_Long (if i <= 15 then 16#05400# +        i * 8
                                  else 16#054E0# + (i - 16) * 8));

   function E1000_RAH (i : in u32) return C.unsigned_Long
   is
     (C.unsigned_Long (if i <= 15 then 16#05404# +        i * 8
                                  else 16#054E4# + (i - 16) * 8));

   function E1000_SHRAL (i : in Integer_Address) return C.unsigned_Long
   is
     (C.unsigned_Long (16#05438# + (i * 8)));


   function E1000_SHRAH (i : in Integer_Address) return C.unsigned_Long
   is
     (C.unsigned_Long (16#0543C# + (i * 8)));


   E1000_TDFH        : constant := 16#3410#;     -- Tx Data FIFO Head - RW.
   E1000_TDFT        : constant := 16#3418#;     -- Tx Data FIFO Tail - RW.
   E1000_TDFHS       : constant := 16#3420#;     -- Tx Data FIFO Head Saved - RW.
   E1000_TDFTS       : constant := 16#3428#;     -- Tx Data FIFO Tail Saved - RW.
   E1000_TDFPC       : constant := 16#3430#;     -- Tx Data FIFO Packet Count - RW.
   E1000_TIDV        : constant := 16#3820#;     -- Tx Interrupt Delay Value - RW.
   E1000_TADV        : constant := 16#382c#;     -- Tx Interrupt Absolute Delay Val - RW.
   E1000_CRCERRS     : constant := 16#4000#;     -- CRC Error Count - R/clr.
   E1000_ALGNERRC    : constant := 16#4004#;     -- Alignment Error Count - R/clr.
   E1000_SYMERRS     : constant := 16#4008#;     -- Symbol Error Count - R/clr.
   E1000_RXERRC      : constant := 16#400c#;     -- Receive Error Count - R/clr.
   E1000_MPC         : constant := 16#4010#;     -- Missed Packet Count - R/clr.
   E1000_SCC         : constant := 16#4014#;     -- Single Collision Count - R/clr.
   E1000_ECOL        : constant := 16#4018#;     -- Excessive Collision Count - R/clr.
   E1000_MCC         : constant := 16#401c#;     -- Multiple Collision Count - R/clr.
   E1000_LATECOL     : constant := 16#4020#;     -- Late Collision Count - R/clr.
   E1000_COLC        : constant := 16#4028#;     -- Collision Count - R/clr.
   E1000_DC          : constant := 16#4030#;     -- Defer Count - R/clr.
   E1000_TNCRS       : constant := 16#4034#;     -- Tx-No CRS - R/clr.
   E1000_SEC         : constant := 16#4038#;     -- Sequence Error Count - R/clr.
   E1000_CEXTERR     : constant := 16#403c#;     -- Carrier Extension Error Count - R/clr.
   E1000_RLEC        : constant := 16#4040#;     -- Receive Length Error Count - R/clr.
   E1000_XONRXC      : constant := 16#4048#;     -- XON Rx Count - R/clr.
   E1000_XONTXC      : constant := 16#404c#;     -- XON Tx Count - R/clr.
   E1000_XOFFRXC     : constant := 16#4050#;     -- XOFF Rx Count - R/clr.
   E1000_XOFFTXC     : constant := 16#4054#;     -- XOFF Tx Count - R/clr.
   E1000_FCRUC       : constant := 16#4058#;     -- Flow Control Rx Unsupported Count- R/clr.
   E1000_PRC64       : constant := 16#405c#;     -- Packets Rx (64 bytes) - R/clr.
   E1000_PRC127      : constant := 16#4060#;     -- Packets Rx (65-127 bytes) - R/clr.
   E1000_PRC255      : constant := 16#4064#;     -- Packets Rx (128-255 bytes) - R/clr.
   E1000_PRC511      : constant := 16#4068#;     -- Packets Rx (255-511 bytes) - R/clr.
   E1000_PRC1023     : constant := 16#406c#;     -- Packets Rx (512-1023 bytes) - R/clr.
   E1000_PRC1522     : constant := 16#4070#;     -- Packets Rx (1024-1522 bytes) - R/clr.
   E1000_GPRC        : constant := 16#4074#;     -- Good Packets Rx Count - R/clr.
   E1000_BPRC        : constant := 16#4078#;     -- Broadcast Packets Rx Count - R/clr.
   E1000_MPRC        : constant := 16#407c#;     -- Multicast Packets Rx Count - R/clr.
   E1000_GPTC        : constant := 16#4080#;     -- Good Packets Tx Count - R/clr.
   E1000_GORCL       : constant := 16#4088#;     -- Good Octets Rx Count Low - R/clr.
   E1000_GORCH       : constant := 16#408c#;     -- Good Octets Rx Count High - R/clr.
   E1000_GOTCL       : constant := 16#4090#;     -- Good Octets Tx Count Low - R/clr.
   E1000_GOTCH       : constant := 16#4094#;     -- Good Octets Tx Count High - R/clr.
   E1000_RNBC        : constant := 16#40a0#;     -- Rx No Buffers Count - R/clr.
   E1000_RUC         : constant := 16#40a4#;     -- Rx Undersize Count - R/clr.
   E1000_RFC         : constant := 16#40a8#;     -- Rx Fragment Count - R/clr.
   E1000_ROC         : constant := 16#40ac#;     -- Rx Oversize Count - R/clr.
   E1000_RJC         : constant := 16#40b0#;     -- Rx Jabber Count - R/clr.
   E1000_MGTPRC      : constant := 16#40b4#;     -- Management Packets Rx Count - R/clr.
   E1000_MGTPDC      : constant := 16#40b8#;     -- Management Packets Dropped Count - R/clr.
   E1000_MGTPTC      : constant := 16#40bc#;     -- Management Packets Tx Count - R/clr.
   E1000_TORL        : constant := 16#40c0#;     -- Total Octets Rx Low - R/clr.
   E1000_TORH        : constant := 16#40c4#;     -- Total Octets Rx High - R/clr.
   E1000_TOTL        : constant := 16#40c8#;     -- Total Octets Tx Low - R/clr.
   E1000_TOTH        : constant := 16#40cc#;     -- Total Octets Tx High - R/clr.
   E1000_TPR         : constant := 16#40d0#;     -- Total Packets Rx - R/clr.
   E1000_TPT         : constant := 16#40d4#;     -- Total Packets Tx - R/clr.
   E1000_PTC64       : constant := 16#40d8#;     -- Packets Tx (64 bytes) - R/clr.
   E1000_PTC127      : constant := 16#40dc#;     -- Packets Tx (65-127 bytes) - R/clr.
   E1000_PTC255      : constant := 16#40e0#;     -- Packets Tx (128-255 bytes) - R/clr.
   E1000_PTC511      : constant := 16#40e4#;     -- Packets Tx (256-511 bytes) - R/clr.
   E1000_PTC1023     : constant := 16#40e8#;     -- Packets Tx (512-1023 bytes) - R/clr.
   E1000_PTC1522     : constant := 16#40ec#;     -- Packets Tx (1024-1522 Bytes) - R/clr.
   E1000_MPTC        : constant := 16#40f0#;     -- Multicast Packets Tx Count - R/clr.
   E1000_BPTC        : constant := 16#40f4#;     -- Broadcast Packets Tx Count - R/clr.
   E1000_TSCTC       : constant := 16#40f8#;     -- TCP Segmentation Context Tx - R/clr.
   E1000_TSCTFC      : constant := 16#40fc#;     -- TCP Segmentation Context Tx Fail - R/clr.
   E1000_IAC         : constant := 16#4100#;     -- Interrupt Assertion Count.
   E1000_ICRXPTC     : constant := 16#4104#;     -- Interrupt Cause Rx Pkt Timer Expire Count.
   E1000_ICRXATC     : constant := 16#4108#;     -- Interrupt Cause Rx Abs Timer Expire Count.
   E1000_ICTXPTC     : constant := 16#410c#;     -- Interrupt Cause Tx Pkt Timer Expire Count.
   E1000_ICTXATC     : constant := 16#4110#;     -- Interrupt Cause Tx Abs Timer Expire Count.
   E1000_ICTXQEC     : constant := 16#4118#;     -- Interrupt Cause Tx Queue Empty Count.
   E1000_ICTXQMTC    : constant := 16#411c#;     -- Interrupt Cause Tx Queue Min Thresh Count.
   E1000_ICRXDMTC    : constant := 16#4120#;     -- Interrupt Cause Rx Desc Min Thresh Count.
   E1000_ICRXOC      : constant := 16#4124#;     -- Interrupt Cause Receiver Overrun Count.
   E1000_CRC_OFFSET  : constant := 16#5f50#;     -- CRC Offset register.

   E1000_PCS_LCTL    : constant := 16#4208#;     -- PCS Link Control - RW.
   E1000_PCS_LSTAT   : constant := 16#420c#;     -- PCS Link Status - RO.
   E1000_PCS_ANADV   : constant := 16#4218#;     -- AN advertisement - RW.
   E1000_PCS_LPAB    : constant := 16#421c#;     -- Link Partner Ability - RW.
   E1000_RXCSUM      : constant := 16#5000#;     -- Rx Checksum Control - RW.
   E1000_RFCTL       : constant := 16#5008#;     -- Receive Filter Control.
   E1000_MTA         : constant := 16#5200#;     -- Multicast Table Array - RW Array.
   E1000_RA          : constant := 16#5400#;     -- Receive Address - RW Array.
   E1000_VFTA        : constant := 16#5600#;     -- VLAN Filter Table Array - RW Array.
   E1000_WUC         : constant := 16#5800#;     -- Wakeup Control - RW.
   E1000_WUFC        : constant := 16#5808#;     -- Wakeup Filter Control - RW.
   E1000_WUS         : constant := 16#5810#;     -- Wakeup Status - RO.
   E1000_MANC        : constant := 16#5820#;     -- Management Control - RW.
   E1000_FFLT        : constant := 16#5f00#;     -- Flexible Filter Length Table - RW Array.
   E1000_HOST_IF     : constant := 16#8800#;     -- Host Interface.

   E1000_KMRNCTRLSTA : constant := 16#34#;       -- MAC-PHY interface - RW.
   E1000_MANC2H      : constant := 16#5860#;     -- Management Control To Host - RW.

   -- Management Decision Filters.
   --
   function E1000_MDEF (n : in C.unsigned_long) return C.unsigned_long
   is
     (16#05890# + 4 * n);


   E1000_SW_FW_SYNC  : constant := 16#5b5c#;     -- SW-FW Synchronization - RW.
   E1000_GCR         : constant := 16#5b00#;     -- PCI-Ex Control.
   E1000_GCR2        : constant := 16#5b64#;     -- PCI-Ex Control #2.
   E1000_FACTPS      : constant := 16#5b30#;     -- Function Active and Power State to MNG.
   E1000_SWSM        : constant := 16#5b50#;     -- SW Semaphore.
   E1000_FWSM        : constant := 16#5b54#;     -- FW Semaphore.
   E1000_EXFWSM      : constant := 16#5b58#;     -- Extended FW Semaphore.

   -- Driver-only SW semaphore (not used by BOOT agents).
   --
   E1000_SWSM2       : constant := 16#5b58#;
   E1000_FFLT_DBG    : constant := 16#5f04#;     -- Debug Register.
   E1000_HICR        : constant := 16#8f00#;     -- Host Interface Control.

   -- RSS registers.
   --
   E1000_MRQC        : constant := 16#5818#;     -- Multiple Receive Control - RW.

   function E1000_RETA (i : in Integer) return C.unsigned_long       -- Redirection Table - RW.
   is
     (C.unsigned_long (16#05C00# + i * 4));

   function E1000_RSSRK (i : in Integer) return C.unsigned_long     -- RSS Random Key - RW.
   is
     (C.unsigned_long (16#05C80# + i * 4));

   E1000_TSYNCRXCTL  : constant := 16#b620#;     -- Rx Time Sync Control register - RW.
   E1000_TSYNCTXCTL  : constant := 16#b614#;     -- Tx Time Sync Control register - RW.
   E1000_RXSTMPL     : constant := 16#b624#;     -- Rx timestamp Low - RO.
   E1000_RXSTMPH     : constant := 16#b628#;     -- Rx timestamp High - RO.
   E1000_TXSTMPL     : constant := 16#b618#;     -- Tx timestamp value Low - RO.
   E1000_TXSTMPH     : constant := 16#b61c#;     -- Tx timestamp value High - RO.
   E1000_SYSTIML     : constant := 16#b600#;     -- System time register Low - RO.
   E1000_SYSTIMH     : constant := 16#b604#;     -- System time register High - RO.
   E1000_TIMINCA     : constant := 16#b608#;     -- Increment attributes register - RW.
   E1000_SYSSTMPL    : constant := 16#b648#;     -- HH Timesync system stamp low register.
   E1000_SYSSTMPH    : constant := 16#b64c#;     -- HH Timesync system stamp hi register.
   E1000_PLTSTMPL    : constant := 16#b640#;     -- HH Timesync platform stamp low register.
   E1000_PLTSTMPH    : constant := 16#b644#;     -- HH Timesync platform stamp hi register.
   E1000_RXMTRL      : constant := 16#b634#;     -- Time sync Rx EtherType and Msg Type - RW.
   E1000_RXUDP       : constant := 16#b638#;     -- Time Sync Rx UDP Port - RW.

   -- PHY registers.
   --
   I82579_DFT_CTRL  : constant Devices.e1000e.Core.u32 := Devices.e1000e.Ich8Lan.PHY_REG (769, 20);


end Devices.e1000e.Registers;
