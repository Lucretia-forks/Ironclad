with
     Interfaces;


package Devices.e1000e.Defines with SPARK_Mode => On
is
   use type interfaces.Unsigned_8,
            interfaces.Unsigned_16,
            interfaces.Unsigned_32;


   -- Number of Transmit and Receive Descriptors must be a multiple of 8.
   --
   REQ_TX_DESCRIPTOR_MULTIPLE              : constant := 8;
   REQ_RX_DESCRIPTOR_MULTIPLE              : constant := 8;

   -- Definitions for power management and wakeup registers.
   --

   -- Wake Up Control.
   --
   E1000_WUC_APME                          : constant := 16#1#;     -- APM Enable.
   E1000_WUC_PME_EN                        : constant := 16#2#;     -- PME Enable.
   E1000_WUC_PME_STATUS                    : constant := 16#4#;     -- PME Status.
   E1000_WUC_APMPME                        : constant := 16#8#;     -- Assert PME on APM Wakeup.
   E1000_WUC_PHY_WAKE                      : constant := 16#100#;   -- If PHY supports wakeup.

   -- Wake Up Filter Control.
   --
   E1000_WUFC_LNKC                         : constant := 16#1#;     -- If PHY supports wakeup.
   E1000_WUFC_MAG                          : constant := 16#2#;     -- Magic Packet Wakeup Enable.
   E1000_WUFC_EX                           : constant := 16#4#;     -- Directed Exact Wakeup Enable.
   E1000_WUFC_MC                           : constant := 16#8#;     -- Directed Multicast Wakeup Enable.
   E1000_WUFC_BC                           : constant := 16#10#;    -- Broadcast Wakeup Enable.
   E1000_WUFC_ARP                          : constant := 16#20#;    -- ARP Request Packet Wakeup Enable.

   -- Wake Up Status.
   --
   E1000_WUS_LNKC                          : constant := 16#1#;
   E1000_WUS_MAG                           : constant := 16#2#;
   E1000_WUS_EX                            : constant := 16#4#;
   E1000_WUS_MC                            : constant := 16#8#;
   E1000_WUS_BC                            : constant := 16#10#;

   -- Extended Device Control.
   --
   E1000_CTRL_EXT_LPCD                     : constant := 16#4#;             -- LCD Power Cycle Done.
   E1000_CTRL_EXT_SDP3_DATA                : constant := 16#80#;            -- Value of SW Definable Pin 3.
   E1000_CTRL_EXT_FORCE_SMBUS              : constant := 16#800#;           -- Force SMBus mode.
   E1000_CTRL_EXT_EE_RST                   : constant := 16#2000#;          -- Reinitialize from EEPROM.
   E1000_CTRL_EXT_SPD_BYPS                 : constant := 16#8000#;          -- Speed Select Bypass.
   E1000_CTRL_EXT_RO_DIS                   : constant := 16#2_0000#;        -- Relaxed Ordering disable.
   E1000_CTRL_EXT_DMA_DYN_CLK_EN           : constant := 16#8_0000#;        -- DMA Dynamic Clock Gating.
   E1000_CTRL_EXT_LINK_MODE_MASK           : constant := 16#c0_0000#;
   E1000_CTRL_EXT_LINK_MODE_PCIE_SERDES    : constant := 16#c0_0000#;
   E1000_CTRL_EXT_EIAME                    : constant := 16#100_0000#;
   E1000_CTRL_EXT_DRV_LOAD                 : constant := 16#1000_0000#;     -- Driver loaded bit for FW.
   E1000_CTRL_EXT_IAME                     : constant := 16#800_0000#;      -- Int ACK Auto-mask.
   E1000_CTRL_EXT_PBA_CLR                  : constant := 16#8000_0000#;     -- PBA Clear.
   E1000_CTRL_EXT_LSECCK                   : constant := 16#1000#;
   E1000_CTRL_EXT_PHYPDEN                  : constant := 16#10_0000#;

   -- Receive Descriptor bit definitions.
   --
   E1000_RXD_STAT_DD                       : constant := 16#1#;      -- Descriptor Done.
   E1000_RXD_STAT_EOP                      : constant := 16#2#;      -- End of Packet.
   E1000_RXD_STAT_IXSM                     : constant := 16#4#;      -- Ignore checksum.
   E1000_RXD_STAT_VP                       : constant := 16#8#;      -- IEEE VLAN Packet.
   E1000_RXD_STAT_UDPCS                    : constant := 16#10#;     -- UDP xsum calculated.
   E1000_RXD_STAT_TCPCS                    : constant := 16#20#;     -- TCP xsum calculated.
   E1000_RXD_ERR_CE                        : constant := 16#1#;      -- CRC Error.
   E1000_RXD_ERR_SE                        : constant := 16#2#;      -- Symbol Error.
   E1000_RXD_ERR_SEQ                       : constant := 16#4#;      -- Sequence Error.
   E1000_RXD_ERR_CXE                       : constant := 16#10#;     -- Carrier Extension Error.
   E1000_RXD_ERR_TCPE                      : constant := 16#20#;     -- TCP/UDP Checksum Error.
   E1000_RXD_ERR_IPE                       : constant := 16#40#;     -- IP Checksum Error.
   E1000_RXD_ERR_RXE                       : constant := 16#80#;     -- Rx Data Error.
   E1000_RXD_SPC_VLAN_MASK                 : constant := 16#fff#;    -- VLAN ID is in lower 12 bits.

   E1000_RXDEXT_STATERR_TST                : constant := 16#100#;    -- Time Stamp taken.
   E1000_RXDEXT_STATERR_CE                 : constant := 16#100_0000#;
   E1000_RXDEXT_STATERR_SE                 : constant := 16#200_0000#;
   E1000_RXDEXT_STATERR_SEQ                : constant := 16#400_0000#;
   E1000_RXDEXT_STATERR_CXE                : constant := 16#1000_0000#;
   E1000_RXDEXT_STATERR_RXE                : constant := 16#8000_0000#;

   -- Mask to determine if packets should be dropped due to frame errors.
   --
   E1000_RXD_ERR_FRAME_ERR_MASK            : constant interfaces.Unsigned_8  :=    E1000_RXD_ERR_CE
                                                                                or E1000_RXD_ERR_SE
                                                                                or E1000_RXD_ERR_SEQ
                                                                                or E1000_RXD_ERR_CXE
                                                                                or E1000_RXD_ERR_RXE;
   -- Same mask, but for extended and packet split descriptors.
   --
   E1000_RXDEXT_ERR_FRAME_ERR_MASK         : constant interfaces.Unsigned_32 :=    E1000_RXDEXT_STATERR_CE
                                                                                or E1000_RXDEXT_STATERR_SE
                                                                                or E1000_RXDEXT_STATERR_SEQ
                                                                                or E1000_RXDEXT_STATERR_CXE
                                                                                or E1000_RXDEXT_STATERR_RXE;
   E1000_MRQC_RSS_FIELD_MASK               : constant := 16#ffff_0000#;
   E1000_MRQC_RSS_FIELD_IPV4_TCP           : constant := 16#1_0000#;
   E1000_MRQC_RSS_FIELD_IPV4               : constant := 16#2_0000#;
   E1000_MRQC_RSS_FIELD_IPV6_TCP_EX        : constant := 16#4_0000#;
   E1000_MRQC_RSS_FIELD_IPV6               : constant := 16#10_0000#;
   E1000_MRQC_RSS_FIELD_IPV6_TCP           : constant := 16#20_0000#;

   E1000_RXDPS_HDRSTAT_HDRSP               : constant := 16#8000#;

   -- Management Control.
   --
   E1000_MANC_SMBUS_EN                     : constant := 16#1#;          -- SMBus Enabled - RO.
   E1000_MANC_ASF_EN                       : constant := 16#2#;          -- ASF Enabled   - RO.
   E1000_MANC_ARP_EN                       : constant := 16#2000#;       -- Enable ARP Request Filtering.
   E1000_MANC_RCV_TCO_EN                   : constant := 16#2_0000#;     -- Receive TCO Packets Enabled.
   E1000_MANC_BLK_PHY_RST_ON_IDE           : constant := 16#4_0000#;     -- Block phy resets.

   -- Enable MAC address filtering.
   --
   E1000_MANC_EN_MAC_ADDR_FILTER           : constant := 16#10_0000#;

   -- Enable MNG packets to host memory.
   --
   E1000_MANC_EN_MNG2HOST                  : constant := 16#20_0000#;

   E1000_MANC2H_PORT_623                   : constant := 16#20#;      -- Port 0x26f.
   E1000_MANC2H_PORT_664                   : constant := 16#40#;      -- Port 0x298.
   E1000_MDEF_PORT_623                     : constant := 16#800#;     -- Port 0x26f.
   E1000_MDEF_PORT_664                     : constant := 16#400#;     -- Port 0x298.

   -- Receive Control.
   --
   E1000_RCTL_EN                           : constant := 16#2#;       -- Enable.
   E1000_RCTL_SBP                          : constant := 16#4#;       -- Store bad packet.
   E1000_RCTL_UPE                          : constant := 16#8#;       -- Unicast   promiscuous enable.
   E1000_RCTL_MPE                          : constant := 16#10#;      -- Multicast promiscuous enable.
   E1000_RCTL_LPE                          : constant := 16#20#;      -- Long packet enable.
   E1000_RCTL_LBM_NO                       : constant := 16#0#;       -- No   loopback mode.
   E1000_RCTL_LBM_MAC                      : constant := 16#40#;      -- MAC  loopback mode.
   E1000_RCTL_LBM_TCVR                     : constant := 16#c0#;      -- TCVR loopback mode.
   E1000_RCTL_DTYP_PS                      : constant := 16#400#;     -- Packet Split descriptor.
   E1000_RCTL_RDMTS_HALF                   : constant := 16#0#;       -- Rx desc min threshold size.
   E1000_RCTL_RDMTS_HEX                    : constant := 16#1_0000#;
   E1000_RCTL_MO_SHIFT                     : constant := 12;          -- Multicast offset shift.
   E1000_RCTL_MO_3                         : constant := 16#3000#;    -- Multicast offset '15:4'.
   E1000_RCTL_BAM                          : constant := 16#8000#;    -- Broadcast enable.

   -- These buffer sizes are valid if E1000_RCTL_BSEX is 0.
   E1000_RCTL_SZ_2048                      : constant := 16#0#;        -- Rx buffer size 2048.
   E1000_RCTL_SZ_1024                      : constant := 16#1_0000#;   -- Rx buffer size 1024.
   E1000_RCTL_SZ_512                       : constant := 16#2_0000#;   -- Rx buffer size 512.
   E1000_RCTL_SZ_256                       : constant := 16#3_0000#;   -- Rx buffer size 256.

   -- These buffer sizes are valid if E1000_RCTL_BSEX is 1.
   E1000_RCTL_SZ_16384                     : constant := 16#1_0000#;      -- Rx buffer size 16384.
   E1000_RCTL_SZ_8192                      : constant := 16#2_0000#;      -- Rx buffer size 8192.
   E1000_RCTL_SZ_4096                      : constant := 16#3_0000#;      -- Rx buffer size 4096.
   E1000_RCTL_VFE                          : constant := 16#4_0000#;      -- VLAN filter enable.
   E1000_RCTL_CFIEN                        : constant := 16#8_0000#;      -- Canonical form enable.
   E1000_RCTL_CFI                          : constant := 16#10_0000#;     -- Canonical form indicator.
   E1000_RCTL_DPF                          : constant := 16#40_0000#;     -- Discard Pause Frames.
   E1000_RCTL_PMCF                         : constant := 16#80_0000#;     -- Pass MAC control frames.
   E1000_RCTL_BSEX                         : constant := 16#200_0000#;    -- Buffer size extension.
   E1000_RCTL_SECRC                        : constant := 16#400_0000#;    -- Strip Ethernet CRC.

   -- Use byte values for the following shift parameters.
   --
   -- Usage:
   --     psrctl |= (((ROUNDUP (value0, 128)  >> E1000_PSRCTL_BSIZE0_SHIFT) &
   --                  E1000_PSRCTL_BSIZE0_MASK) |
   --                ((ROUNDUP (value1, 1024) >> E1000_PSRCTL_BSIZE1_SHIFT) &
   --                  E1000_PSRCTL_BSIZE1_MASK) |
   --                ((ROUNDUP (value2, 1024) << E1000_PSRCTL_BSIZE2_SHIFT) &
   --                  E1000_PSRCTL_BSIZE2_MASK) |
   --                ((ROUNDUP (value3, 1024) << E1000_PSRCTL_BSIZE3_SHIFT) |;
   --                  E1000_PSRCTL_BSIZE3_MASK))
   --
   -- where value0 = [ 128..16256],  default= 256
   --       value1 = [1024..64512],  default=4096
   --       value2 = [   0..64512],  default=4096
   --       value3 = [   0..64512],  default=   0
   --
   E1000_PSRCTL_BSIZE0_MASK                : constant := 16#7f#;
   E1000_PSRCTL_BSIZE1_MASK                : constant := 16#3f00#;
   E1000_PSRCTL_BSIZE2_MASK                : constant := 16#3f_0000#;
   E1000_PSRCTL_BSIZE3_MASK                : constant := 16#3f00_0000#;

   E1000_PSRCTL_BSIZE0_SHIFT               : constant :=  7;                -- Shift _right_ 7.
   E1000_PSRCTL_BSIZE1_SHIFT               : constant :=  2;                -- Shift _right_ 2.
   E1000_PSRCTL_BSIZE2_SHIFT               : constant :=  6;                -- Shift _left_  6.
   E1000_PSRCTL_BSIZE3_SHIFT               : constant := 14;                -- Shift _left_ 14.

   -- SWFW_SYNC Definitions.
   --
   E1000_SWFW_EEP_SM                       : constant := 16#1#;
   E1000_SWFW_PHY0_SM                      : constant := 16#2#;
   E1000_SWFW_PHY1_SM                      : constant := 16#4#;
   E1000_SWFW_CSR_SM                       : constant := 16#8#;

   -- Device Control.
   --
   E1000_CTRL_FD                           : constant := 16#1#;             -- Full duplex.0=half; 1=full.
   E1000_CTRL_GIO_MASTER_DISABLE           : constant := 16#4#;             -- Blocks new Master requests.
   E1000_CTRL_LRST                         : constant := 16#8#;             -- Link reset. 0=normal,1=reset.
   E1000_CTRL_ASDE                         : constant := 16#20#;            -- Auto-speed detect enable.
   E1000_CTRL_SLU                          : constant := 16#40#;            -- Set link up (Force Link).
   E1000_CTRL_ILOS                         : constant := 16#80#;            -- Invert Loss-Of Signal.
   E1000_CTRL_SPD_SEL                      : constant := 16#300#;           -- Speed Select Mask.
   E1000_CTRL_SPD_10                       : constant := 16#0#;             -- Force 10Mb.
   E1000_CTRL_SPD_100                      : constant := 16#100#;           -- Force 100Mb.
   E1000_CTRL_SPD_1000                     : constant := 16#200#;           -- Force 1Gb.
   E1000_CTRL_FRCSPD                       : constant := 16#800#;           -- Force Speed.
   E1000_CTRL_FRCDPX                       : constant := 16#1000#;          -- Force Duplex.
   E1000_CTRL_LANPHYPC_OVERRIDE            : constant := 16#1_0000#;        -- SW control of LANPHYPC.
   E1000_CTRL_LANPHYPC_VALUE               : constant := 16#2_0000#;        -- SW value of LANPHYPC.
   E1000_CTRL_MEHE                         : constant := 16#8_0000#;        -- Memory Error Handling Enable.
   E1000_CTRL_SWDPIN0                      : constant := 16#4_0000#;        -- SWDPIN 0 value.
   E1000_CTRL_SWDPIN1                      : constant := 16#8_0000#;        -- SWDPIN 1 value.
   E1000_CTRL_ADVD3WUC                     : constant := 16#10_0000#;       -- D3 WUC.
   E1000_CTRL_EN_PHY_PWR_MGMT              : constant := 16#20_0000#;       -- PHY PM enable.
   E1000_CTRL_SWDPIO0                      : constant := 16#40_0000#;       -- SWDPIN 0 Input or output.
   E1000_CTRL_RST                          : constant := 16#400_0000#;      -- Global reset.
   E1000_CTRL_RFCE                         : constant := 16#800_0000#;      -- Receive Flow Control enable.
   E1000_CTRL_TFCE                         : constant := 16#1000_0000#;     -- Transmit flow control enable.
   E1000_CTRL_VME                          : constant := 16#4000_0000#;     -- IEEE VLAN mode enable.
   E1000_CTRL_PHY_RST                      : constant := 16#8000_0000#;     -- PHY Reset.

   E1000_PCS_LCTL_FORCE_FCTRL              : constant := 16#80#;

   E1000_PCS_LSTS_AN_COMPLETE              : constant := 16#1_0000#;

   -- Device Status.
   --
   E1000_STATUS_FD                         : constant := 16#1#;             -- Full duplex.0=half,1=full.
   E1000_STATUS_LU                         : constant := 16#2#;             -- Link up.0=no,1=link.
   E1000_STATUS_FUNC_MASK                  : constant := 16#c#;             -- PCI Function Mask.
   E1000_STATUS_FUNC_SHIFT                 : constant := 2;
   E1000_STATUS_FUNC_1                     : constant := 16#4#;             -- Function 1.
   E1000_STATUS_TXOFF                      : constant := 16#10#;            -- Transmission paused.
   E1000_STATUS_SPEED_MASK                 : constant := 16#c0#;
   E1000_STATUS_SPEED_10                   : constant := 16#0#;             -- Speed 10Mb/s.
   E1000_STATUS_SPEED_100                  : constant := 16#40#;            -- Speed 100Mb/s.
   E1000_STATUS_SPEED_1000                 : constant := 16#80#;            -- Speed 1000Mb/s.
   E1000_STATUS_LAN_INIT_DONE              : constant := 16#200#;           -- LAN Init Completion by NVM.
   E1000_STATUS_PHYRA                      : constant := 16#400#;           -- PHY Reset Asserted.
   E1000_STATUS_GIO_MASTER_ENABLE          : constant := 16#8_0000#;        -- Master Req status.

   -- PCIm function state.
   --
   E1000_STATUS_PCIM_STATE                 : constant := 16#4000_0000#;

   HALF_DUPLEX                             : constant := 1;
   FULL_DUPLEX                             : constant := 2;

   ADVERTISE_10_HALF                       : constant := 16#1#;
   ADVERTISE_10_FULL                       : constant := 16#2#;
   ADVERTISE_100_HALF                      : constant := 16#4#;
   ADVERTISE_100_FULL                      : constant := 16#8#;             -- Not used, just FYI.
   ADVERTISE_1000_HALF                     : constant := 16#10#;
   ADVERTISE_1000_FULL                     : constant := 16#20#;

   -- 1000/H is not supported, nor spec-compliant.
   --
   E1000_ALL_SPEED_DUPLEX                  : constant interfaces.Unsigned_8 :=    ADVERTISE_10_HALF
                                                                               or ADVERTISE_10_FULL
                                                                               or ADVERTISE_100_HALF
                                                                               or ADVERTISE_100_FULL
                                                                               or ADVERTISE_1000_FULL;

   E1000_ALL_NOT_GIG                       : constant interfaces.Unsigned_8 :=    ADVERTISE_10_HALF
                                                                               or ADVERTISE_10_FULL
                                                                               or ADVERTISE_100_HALF
                                                                               or ADVERTISE_100_FULL;

   E1000_ALL_100_SPEED                     : constant interfaces.Unsigned_8 := ADVERTISE_100_HALF or ADVERTISE_100_FULL;
   E1000_ALL_10_SPEED                      : constant interfaces.Unsigned_8 := ADVERTISE_10_HALF  or ADVERTISE_10_FULL;
   E1000_ALL_HALF_DUPLEX                   : constant interfaces.Unsigned_8 := ADVERTISE_10_HALF  or ADVERTISE_100_HALF;

   AUTONEG_ADVERTISE_SPEED_DEFAULT         : constant := E1000_ALL_SPEED_DUPLEX;

   -- LED Control.
   --
   E1000_PHY_LED0_MODE_MASK                : constant := 16#7#;
   E1000_PHY_LED0_IVRT                     : constant := 16#8#;
   E1000_PHY_LED0_MASK                     : constant := 16#1f#;

   E1000_LEDCTL_LED0_MODE_MASK             : constant := 16#f#;
   E1000_LEDCTL_LED0_MODE_SHIFT            : constant := 0;
   E1000_LEDCTL_LED0_IVRT                  : constant := 16#40#;
   E1000_LEDCTL_LED0_BLINK                 : constant := 16#80#;

   E1000_LEDCTL_MODE_LINK_UP               : constant := 16#2#;
   E1000_LEDCTL_MODE_LED_ON                : constant := 16#e#;
   E1000_LEDCTL_MODE_LED_OFF               : constant := 16#f#;

   -- Transmit Descriptor bit definitions.
   --
   E1000_TXD_DTYP_D                        : constant := 16#10_0000#;       -- Data Descriptor.
   E1000_TXD_POPTS_IXSM                    : constant := 16#1#;             -- Insert IP checksum.
   E1000_TXD_POPTS_TXSM                    : constant := 16#2#;             -- Insert TCP/UDP checksum.
   E1000_TXD_CMD_EOP                       : constant := 16#100_0000#;      -- End of Packet.
   E1000_TXD_CMD_IFCS                      : constant := 16#200_0000#;      -- Insert FCS (Ethernet CRC).
   E1000_TXD_CMD_IC                        : constant := 16#400_0000#;      -- Insert Checksum.
   E1000_TXD_CMD_RS                        : constant := 16#800_0000#;      -- Report Status.
   E1000_TXD_CMD_RPS                       : constant := 16#1000_0000#;     -- Report Packet Sent.
   E1000_TXD_CMD_DEXT                      : constant := 16#2000_0000#;     -- Descriptor extension (0 = legacy).
   E1000_TXD_CMD_VLE                       : constant := 16#4000_0000#;     -- Add VLAN tag.
   E1000_TXD_CMD_IDE                       : constant := 16#8000_0000#;     -- Enable Tidv register.
   E1000_TXD_STAT_DD                       : constant := 16#1#;             -- Descriptor Done.
   E1000_TXD_STAT_EC                       : constant := 16#2#;             -- Excess Collisions.
   E1000_TXD_STAT_LC                       : constant := 16#4#;             -- Late Collisions.
   E1000_TXD_STAT_TU                       : constant := 16#8#;             -- Transmit underrun.
   E1000_TXD_CMD_TCP                       : constant := 16#100_0000#;      -- TCP packet.
   E1000_TXD_CMD_IP                        : constant := 16#200_0000#;      -- IP packet.
   E1000_TXD_CMD_TSE                       : constant := 16#400_0000#;      -- TCP Seg enable.
   E1000_TXD_STAT_TC                       : constant := 16#4#;             -- Tx Underrun.
   E1000_TXD_EXTCMD_TSTAMP                 : constant := 16#10#;            -- IEEE1588 Timestamp packet.

   -- Transmit Control.
   --
   E1000_TCTL_EN                           : constant := 16#2#;             -- Enable Tx.
   E1000_TCTL_PSP                          : constant := 16#8#;             -- Pad short packets.
   E1000_TCTL_CT                           : constant := 16#ff0#;           -- Collision threshold.
   E1000_TCTL_COLD                         : constant := 16#3f_f000#;       -- Collision distance.
   E1000_TCTL_RTLC                         : constant := 16#100_0000#;      -- Re-transmit on late collision.
   E1000_TCTL_MULR                         : constant := 16#1000_0000#;     -- Multiple request support.

   -- SerDes Control.
   --
   E1000_SCTL_DISABLE_SERDES_LOOPBACK      : constant := 16#400#;
   E1000_SCTL_ENABLE_SERDES_LOOPBACK       : constant := 16#410#;

   -- Receive Checksum Control.
   --
   E1000_RXCSUM_TUOFL                      : constant := 16#200#;           -- TCP / UDP checksum offload.
   E1000_RXCSUM_IPPCSE                     : constant := 16#1000#;          -- IP payload checksum enable.
   E1000_RXCSUM_PCSD                       : constant := 16#2000#;          -- Packet checksum disabled.

   -- Header split receive.
   --
   E1000_RFCTL_NFSW_DIS                    : constant := 16#40#;
   E1000_RFCTL_NFSR_DIS                    : constant := 16#80#;
   E1000_RFCTL_ACK_DIS                     : constant := 16#1000#;
   E1000_RFCTL_EXTEN                       : constant := 16#8000#;
   E1000_RFCTL_IPV6_EX_DIS                 : constant := 16#1_0000#;
   E1000_RFCTL_NEW_IPV6_EXT_DIS            : constant := 16#2_0000#;

   -- Collision related configuration parameters.
   --
   E1000_COLLISION_THRESHOLD               : constant := 15;
   E1000_CT_SHIFT                          : constant := 4;
   E1000_COLLISION_DISTANCE                : constant := 63;
   E1000_COLD_SHIFT                        : constant := 12;

   -- Default values for the transmit IPG register.
   --
   DEFAULT_82543_TIPG_IPGT_COPPER          : constant := 8;

   E1000_TIPG_IPGT_MASK                    : constant := 16#3ff#;

   DEFAULT_82543_TIPG_IPGR1                : constant := 8;
   E1000_TIPG_IPGR1_SHIFT                  : constant := 10;

   DEFAULT_82543_TIPG_IPGR2                : constant := 6;
   DEFAULT_80003ES2LAN_TIPG_IPGR2          : constant := 7;
   E1000_TIPG_IPGR2_SHIFT                  : constant := 20;

   MAX_JUMBO_FRAME_SIZE                    : constant := 16#3f00#;
   E1000_TX_PTR_GAP                        : constant := 16#1f#;

   -- Extended Configuration Control and Size.
   --
   E1000_EXTCNF_CTRL_MDIO_SW_OWNERSHIP     : constant := 16#20#;
   E1000_EXTCNF_CTRL_LCD_WRITE_ENABLE      : constant := 16#1#;
   E1000_EXTCNF_CTRL_OEM_WRITE_ENABLE      : constant := 16#8#;
   E1000_EXTCNF_CTRL_SWFLAG                : constant := 16#20#;
   E1000_EXTCNF_CTRL_GATE_PHY_CFG          : constant := 16#80#;
   E1000_EXTCNF_SIZE_EXT_PCIE_LENGTH_MASK  : constant := 16#ff_0000#;
   E1000_EXTCNF_SIZE_EXT_PCIE_LENGTH_SHIFT : constant := 16;
   E1000_EXTCNF_CTRL_EXT_CNF_POINTER_MASK  : constant := 16#fff_0000#;
   E1000_EXTCNF_CTRL_EXT_CNF_POINTER_SHIFT : constant := 16;

   E1000_PHY_CTRL_D0A_LPLU                 : constant := 16#2#;
   E1000_PHY_CTRL_NOND0A_LPLU              : constant := 16#4#;
   E1000_PHY_CTRL_NOND0A_GBE_DISABLE       : constant := 16#8#;
   E1000_PHY_CTRL_GBE_DISABLE              : constant := 16#40#;

   E1000_KABGTXD_BGSQLBIAS                 : constant := 16#5_0000#;

   -- Low Power IDLE Control.
   --
   E1000_LPIC_LPIET_SHIFT                  : constant := 24;         -- Low Power Idle Entry Time.

   -- PBA constants.
   --
   E1000_PBA_8K                            : constant := 16#8#;      -- 8KB.
   E1000_PBA_16K                           : constant := 16#10#;     -- 16KB.
   E1000_PBA_RXA_MASK                      : constant := 16#ffff#;

   E1000_PBS_16K                           : constant := E1000_PBA_16K;

   -- Uncorrectable/correctable ECC Error counts and enable bits.
   --
   E1000_PBECCSTS_CORR_ERR_CNT_MASK        : constant := 16#ff#;
   E1000_PBECCSTS_UNCORR_ERR_CNT_MASK      : constant := 16#ff00#;
   E1000_PBECCSTS_UNCORR_ERR_CNT_SHIFT     : constant := 8;
   E1000_PBECCSTS_ECC_ENABLE               : constant := 16#1_0000#;

   IFS_MAX                                 : constant := 80;
   IFS_MIN                                 : constant := 40;
   IFS_RATIO                               : constant := 4;
   IFS_STEP                                : constant := 10;
   MIN_NUM_XMITS                           : constant := 1_000;

   -- SW Semaphore Register.
   --
   E1000_SWSM_SMBI                         : constant := 16#1#;             -- Driver Semaphore bit.
   E1000_SWSM_SWESMBI                      : constant := 16#2#;             -- FW Semaphore bit.
   E1000_SWSM_DRV_LOAD                     : constant := 16#8#;             -- Driver Loaded Bit.

   E1000_SWSM2_LOCK                        : constant := 16#2#;             -- Secondary driver semaphore bit.

   -- Interrupt Cause Read.
   --
   E1000_ICR_TXDW                          : constant := 16#1#;             -- Transmit desc written back.
   E1000_ICR_LSC                           : constant := 16#4#;             -- Link Status Change.
   E1000_ICR_RXSEQ                         : constant := 16#8#;             -- Rx sequence error.
   E1000_ICR_RXDMT0                        : constant := 16#10#;            -- Rx desc min threshold (0).
   E1000_ICR_RXO                           : constant := 16#40#;            -- Receiver Overrun.
   E1000_ICR_RXT0                          : constant := 16#80#;            -- Rx timer intr (ring 0).
   E1000_ICR_MDAC                          : constant := 16#200#;           -- MDIO Access Complete.
   E1000_ICR_SRPD                          : constant := 16#1_0000#;        -- Small Receive Packet Detected.
   E1000_ICR_ACK                           : constant := 16#2_0000#;        -- Receive ACK Frame Detected.
   E1000_ICR_MNG                           : constant := 16#4_0000#;        -- Manageability Event Detected.
   E1000_ICR_ECCER                         : constant := 16#40_0000#;       -- Uncorrectable ECC Error.
   E1000_ICR_INT_ASSERTED                  : constant := 16#8000_0000#;     -- If this bit asserted, the driver should claim the interrupt.
   E1000_ICR_RXQ0                          : constant := 16#10_0000#;       -- Rx Queue 0 Interrupt.
   E1000_ICR_RXQ1                          : constant := 16#20_0000#;       -- Rx Queue 1 Interrupt.
   E1000_ICR_TXQ0                          : constant := 16#40_0000#;       -- Tx Queue 0 Interrupt.
   E1000_ICR_TXQ1                          : constant := 16#80_0000#;       -- Tx Queue 1 Interrupt.
   E1000_ICR_OTHER                         : constant := 16#100_0000#;      -- Other Interrupt.

   -- PBA ECC Register.
   --
   E1000_PBA_ECC_COUNTER_MASK              : constant := 16#fff0_0000#;     -- ECC counter mask.
   E1000_PBA_ECC_COUNTER_SHIFT             : constant := 20;                -- ECC counter shift value.
   E1000_PBA_ECC_CORR_EN                   : constant := 16#1#;             -- ECC correction enable.
   E1000_PBA_ECC_STAT_CLR                  : constant := 16#2#;             -- Clear ECC error counter.
   E1000_PBA_ECC_INT_EN                    : constant := 16#4#;             -- Enable ICR bit 5 for ECC.

   -- Interrupt Mask Set.
   --
   E1000_IMS_TXDW                          : constant := E1000_ICR_TXDW;    -- Transmit desc written back.
   E1000_IMS_LSC                           : constant := E1000_ICR_LSC;     -- Link Status Change.
   E1000_IMS_RXSEQ                         : constant := E1000_ICR_RXSEQ;   -- Rx sequence error.
   E1000_IMS_RXDMT0                        : constant := E1000_ICR_RXDMT0;  -- Rx desc min. threshold.
   E1000_IMS_RXO                           : constant := E1000_ICR_RXO;     -- Receiver Overrun.
   E1000_IMS_RXT0                          : constant := E1000_ICR_RXT0;    -- Rx timer intr.
   E1000_IMS_MDAC                          : constant := E1000_ICR_MDAC;    -- MDIO Access Complete.
   E1000_IMS_SRPD                          : constant := E1000_ICR_SRPD;    -- Small Receive Packet.
   E1000_IMS_ACK                           : constant := E1000_ICR_ACK;     -- Receive ACK Frame Detected.
   E1000_IMS_MNG                           : constant := E1000_ICR_MNG;     -- Manageability Event.
   E1000_IMS_ECCER                         : constant := E1000_ICR_ECCER;   -- Uncorrectable ECC Error.
   E1000_IMS_RXQ0                          : constant := E1000_ICR_RXQ0;    -- Rx Queue 0 Interrupt.
   E1000_IMS_RXQ1                          : constant := E1000_ICR_RXQ1;    -- Rx Queue 1 Interrupt.
   E1000_IMS_TXQ0                          : constant := E1000_ICR_TXQ0;    -- Tx Queue 0 Interrupt.
   E1000_IMS_TXQ1                          : constant := E1000_ICR_TXQ1;    -- Tx Queue 1 Interrupt.
   E1000_IMS_OTHER                         : constant := E1000_ICR_OTHER;   -- Other Interrupt.

   -- This defines the bits that are set in the Interrupt Mask
   -- Set/Read Register.  Each bit is documented below:
   --
   --   o RXT0   = Receiver Timer Interrupt (ring 0)
   --   o TXDW   = Transmit Descriptor Written Back
   --   o RXDMT0 = Receive Descriptor Minimum Threshold hit (ring 0)
   --   o RXSEQ  = Receive Sequence Error
   --   o LSC    = Link Status Change
   --
   IMS_ENABLE_MASK                         : constant interfaces.Unsigned_8  :=    E1000_IMS_RXT0
                                                                                or E1000_IMS_TXDW
                                                                                or E1000_IMS_RXDMT0
                                                                                or E1000_IMS_RXSEQ
                                                                                or E1000_IMS_LSC;
   -- These are all of the events related to the OTHER interrupt.
   --
   IMS_OTHER_MASK                          : constant interfaces.Unsigned_32 :=    E1000_IMS_LSC
                                                                                or E1000_IMS_RXO
                                                                                or E1000_IMS_MDAC
                                                                                or E1000_IMS_SRPD
                                                                                or E1000_IMS_ACK
                                                                                or E1000_IMS_MNG;

   -- Interrupt Cause Set.
   --
   E1000_ICS_LSC                           : constant := 16#4#;            -- Link Status Change.
   E1000_ICS_RXSEQ                         : constant := 16#8#;            -- Rx sequence error.
   E1000_ICS_RXDMT0                        : constant := 16#10#;           -- Rx desc min threshold.
   E1000_ICS_OTHER                         : constant := 16#100_0000#;     -- Other Interrupt.

   -- Transmit Descriptor Control.
   --
   E1000_TXDCTL_PTHRESH                    : constant := 16#3f#;           -- TXDCTL Prefetch Threshold.
   E1000_TXDCTL_HTHRESH                    : constant := 16#3f00#;         -- TXDCTL Host Threshold.
   E1000_TXDCTL_WTHRESH                    : constant := 16#3f_0000#;      -- TXDCTL Writeback Threshold.
   E1000_TXDCTL_GRAN                       : constant := 16#100_0000#;     -- TXDCTL Granularity.
   E1000_TXDCTL_FULL_TX_DESC_WB            : constant := 16#101_0000#;     -- GRAN=1, WTHRESH=1.
   E1000_TXDCTL_MAX_TX_DESC_PREFETCH       : constant := 16#100_001f#;     -- GRAN=1, PTHRESH=31.
   E1000_TXDCTL_COUNT_DESC                 : constant := 16#40_0000#;      -- Enable the counting of 'desc' still to be processed.

   -- Flow Control Constants.
   --
   FLOW_CONTROL_ADDRESS_LOW                : constant := 16#c2_8001#;
   FLOW_CONTROL_ADDRESS_HIGH               : constant := 16#100#;
   FLOW_CONTROL_TYPE                       : constant := 16#8808#;

   -- 802.1q VLAN Packet Size.
   --
   E1000_VLAN_FILTER_TBL_SIZE              : constant := 128;              -- VLAN Filter Table (4096 bits).

   -- Receive Address
   --
   -- Number of high/low register pairs in the RAR. The RAR (Receive Address
   -- Registers) holds the directed and multicast addresses that we monitor.
   -- Technically, we have 16 spots.  However, we reserve one of these spots
   -- (RAR[15]) for our directed address used by controllers with
   -- manageability enabled, allowing us room for 15 multicast addresses.
   --
   E1000_RAR_ENTRIES                       : constant := 15;
   E1000_RAH_AV                            : constant := 16#8000_0000#;    -- Receive descriptor valid.
   E1000_RAL_MAC_ADDR_LEN                  : constant := 4;
   E1000_RAH_MAC_ADDR_LEN                  : constant := 2;

   -- Error Codes.
   --
   E1000_ERR_NVM                           : constant := 1;
   E1000_ERR_PHY                           : constant := 2;
   E1000_ERR_CONFIG                        : constant := 3;
   E1000_ERR_PARAM                         : constant := 4;
   E1000_ERR_MAC_INIT                      : constant := 5;
   E1000_ERR_PHY_TYPE                      : constant := 6;
   E1000_ERR_RESET                         : constant := 9;
   E1000_ERR_MASTER_REQUESTS_PENDING       : constant := 10;
   E1000_ERR_HOST_INTERFACE_COMMAND        : constant := 11;
   E1000_BLK_PHY_RESET                     : constant := 12;
   E1000_ERR_SWFW_SYNC                     : constant := 13;
   E1000_NOT_IMPLEMENTED                   : constant := 14;
   E1000_ERR_INVALID_ARGUMENT              : constant := 16;
   E1000_ERR_NO_SPACE                      : constant := 17;
   E1000_ERR_NVM_PBA_SECTION               : constant := 18;

   -- Loop limit on how long we wait for auto-negotiation to complete.
   --
   FIBER_LINK_UP_LIMIT                     : constant := 50;
   COPPER_LINK_UP_LIMIT                    : constant := 10;
   PHY_AUTO_NEG_LIMIT                      : constant := 45;
   PHY_FORCE_LIMIT                         : constant := 20;
   MASTER_DISABLE_TIMEOUT                  : constant := 800;     -- Number of 100 microseconds we wait for PCI Express master disable.
   PHY_CFG_TIMEOUT                         : constant := 100;     -- Number of milliseconds we wait for PHY configuration done after MAC reset.
   MDIO_OWNERSHIP_TIMEOUT                  : constant := 10;      -- Number of 2 milliseconds we wait for acquiring MDIO ownership.
   AUTO_READ_DONE_TIMEOUT                  : constant := 10;      -- Number of milliseconds for NVM auto read done after MAC reset.

   -- Flow Control.
   --
   E1000_FCRTH_RTH                         : constant := 16#fff8#;          -- Mask Bits[15:3] for RTH.
   E1000_FCRTL_RTL                         : constant := 16#fff8#;          -- Mask Bits[15:3] for RTL.
   E1000_FCRTL_XONE                        : constant := 16#8000_0000#;     -- Enable XON frame transmission.

   -- Transmit Configuration Word.
   --
   E1000_TXCW_FD                           : constant := 16#20#;            -- TXCW full duplex.
   E1000_TXCW_PAUSE                        : constant := 16#80#;            -- TXCW sym pause request.
   E1000_TXCW_ASM_DIR                      : constant := 16#100#;           -- TXCW astm pause direction.
   E1000_TXCW_PAUSE_MASK                   : constant := 16#180#;           -- TXCW pause request mask.
   E1000_TXCW_ANE                          : constant := 16#8000_0000#;     -- Auto-neg enable.

   -- Receive Configuration Word.
   --
   E1000_RXCW_CW                           : constant := 16#ffff#;          -- RxConfigWord mask.
   E1000_RXCW_IV                           : constant := 16#800_0000#;      -- Receive config invalid.
   E1000_RXCW_C                            : constant := 16#2000_0000#;     -- Receive config.
   E1000_RXCW_SYNCH                        : constant := 16#4000_0000#;     -- Receive config synch.

   -- HH Time Sync.
   --
   E1000_TSYNCTXCTL_MAX_ALLOWED_DLY_MASK   : constant := 16#f000#;          -- Max delay.
   E1000_TSYNCTXCTL_SYNC_COMP              : constant := 16#4000_0000#;     -- Sync complete.
   E1000_TSYNCTXCTL_START_SYNC             : constant := 16#8000_0000#;     -- Initiate sync.

   E1000_TSYNCTXCTL_VALID                  : constant := 16#1#;             -- Tx timestamp valid.
   E1000_TSYNCTXCTL_ENABLED                : constant := 16#10#;            -- Enable Tx timestamping.

   E1000_TSYNCRXCTL_VALID                  : constant := 16#1#;             -- Rx timestamp valid.
   E1000_TSYNCRXCTL_TYPE_MASK              : constant := 16#e#;             -- Rx type mask.
   E1000_TSYNCRXCTL_TYPE_L2_V2             : constant := 16#0#;
   E1000_TSYNCRXCTL_TYPE_L4_V1             : constant := 16#2#;
   E1000_TSYNCRXCTL_TYPE_L2_L4_V2          : constant := 16#4#;
   E1000_TSYNCRXCTL_TYPE_ALL               : constant := 16#8#;
   E1000_TSYNCRXCTL_TYPE_EVENT_V2          : constant := 16#a#;
   E1000_TSYNCRXCTL_ENABLED                : constant := 16#10#;            -- Enable Rx timestamping.
   E1000_TSYNCRXCTL_SYSCFI                 : constant := 16#20#;            -- Sys clock frequency.

   E1000_RXMTRL_PTP_V1_SYNC_MESSAGE        : constant := 16#0#;
   E1000_RXMTRL_PTP_V1_DELAY_REQ_MESSAGE   : constant := 16#1_0000#;

   E1000_RXMTRL_PTP_V2_SYNC_MESSAGE        : constant := 16#0#;
   E1000_RXMTRL_PTP_V2_DELAY_REQ_MESSAGE   : constant := 16#100_0000#;

   E1000_TIMINCA_INCPERIOD_SHIFT           : constant := 24;
   E1000_TIMINCA_INCVALUE_MASK             : constant := 16#ff_ffff#;

   -- PCI Express Control.
   --
   E1000_GCR_RXD_NO_SNOOP                  : constant := 16#1#;
   E1000_GCR_RXDSCW_NO_SNOOP               : constant := 16#2#;
   E1000_GCR_RXDSCR_NO_SNOOP               : constant := 16#4#;
   E1000_GCR_TXD_NO_SNOOP                  : constant := 16#8#;
   E1000_GCR_TXDSCW_NO_SNOOP               : constant := 16#10#;
   E1000_GCR_TXDSCR_NO_SNOOP               : constant := 16#20#;

   PCIE_NO_SNOOP_ALL                       : constant interfaces.Unsigned_32 :=    E1000_GCR_RXD_NO_SNOOP
                                                                                or E1000_GCR_RXDSCW_NO_SNOOP
                                                                                or E1000_GCR_RXDSCR_NO_SNOOP
                                                                                or E1000_GCR_TXD_NO_SNOOP
                                                                                or E1000_GCR_TXDSCW_NO_SNOOP
                                                                                or E1000_GCR_TXDSCR_NO_SNOOP;
   -- NVM Control.
   --
   E1000_EECD_SK                           : constant := 16#1#;           -- NVM Clock.
   E1000_EECD_CS                           : constant := 16#2#;           -- NVM Chip Select.
   E1000_EECD_DI                           : constant := 16#4#;           -- NVM Data In.
   E1000_EECD_DO                           : constant := 16#8#;           -- NVM Data Out.
   E1000_EECD_REQ                          : constant := 16#40#;          -- NVM Access Request.
   E1000_EECD_GNT                          : constant := 16#80#;          -- NVM Access Grant.
   E1000_EECD_PRES                         : constant := 16#100#;         -- NVM Present.
   E1000_EECD_SIZE                         : constant := 16#200#;         -- NVM Size (0=64 word 1=256 word).
   E1000_EECD_ADDR_BITS                    : constant := 16#400#;         -- NVM Addressing bits based on type (0-small, 1-large).
   E1000_NVM_GRANT_ATTEMPTS                : constant := 1_000;           -- NVM Number of attempts to gain grant.
   E1000_EECD_AUTO_RD                      : constant := 16#200#;         -- NVM Auto Read done.
   E1000_EECD_SIZE_EX_MASK                 : constant := 16#7800#;        -- NVM Size.
   E1000_EECD_SIZE_EX_SHIFT                : constant := 11;
   E1000_EECD_FLUPD                        : constant := 16#8_0000#;      -- Update FLASH.
   E1000_EECD_AUPDEN                       : constant := 16#10_0000#;     -- Enable Autonomous FLASH update.
   E1000_EECD_SEC1VAL                      : constant := 16#40_0000#;     -- Sector One Valid.
   E1000_EECD_SEC1VAL_VALID_MASK           : constant interfaces.Unsigned_32
                                                      := E1000_EECD_AUTO_RD or E1000_EECD_PRES;

   E1000_NVM_RW_REG_DATA                   : constant := 16;              -- Offset to data in NVM r/w regs.
   E1000_NVM_RW_REG_DONE                   : constant := 2;               -- Offset to READ/WRITE done bit.
   E1000_NVM_RW_REG_START                  : constant := 1;               -- Start operation.
   E1000_NVM_RW_ADDR_SHIFT                 : constant := 2;               -- Shift to the address bits.
   E1000_NVM_POLL_WRITE                    : constant := 1;               -- Flag for polling write complete.
   E1000_NVM_POLL_READ                     : constant := 0;               -- Flag for polling read complete.
   E1000_FLASH_UPDATES                     : constant := 2_000;

   -- NVM Word Offsets.
   --
   NVM_COMPAT                              : constant := 16#3#;
   NVM_ID_LED_SETTINGS                     : constant := 16#4#;
   NVM_FUTURE_INIT_WORD1                   : constant := 16#19#;
   NVM_COMPAT_VALID_CSUM                   : constant := 16#1#;
   NVM_FUTURE_INIT_WORD1_VALID_CSUM        : constant := 16#40#;

   NVM_INIT_CONTROL2_REG                   : constant := 16#f#;
   NVM_INIT_CONTROL3_PORT_B                : constant := 16#14#;
   NVM_INIT_3GIO_3                         : constant := 16#1a#;
   NVM_INIT_CONTROL3_PORT_A                : constant := 16#24#;
   NVM_CFG                                 : constant := 16#12#;
   NVM_ALT_MAC_ADDR_PTR                    : constant := 16#37#;
   NVM_CHECKSUM_REG                        : constant := 16#3f#;

   E1000_NVM_CFG_DONE_PORT_0               : constant := 16#4_0000#;     -- MNG config cycle done,
   E1000_NVM_CFG_DONE_PORT_1               : constant := 16#8_0000#;     -- ... for second port.

   -- Mask bits for fields in Word 0x0f of the NVM.
   --
   NVM_WORD0F_PAUSE_MASK                   : constant := 16#3000#;
   NVM_WORD0F_PAUSE                        : constant := 16#1000#;
   NVM_WORD0F_ASM_DIR                      : constant := 16#2000#;

   -- Mask bits for fields in Word 0x1a of the NVM.
   --
   NVM_WORD1A_ASPM_MASK                    : constant := 16#c#;

   -- Mask bits for fields in Word 0x03 of the EEPROM.
   --
   NVM_COMPAT_LOM                          : constant := 16#800#;

   -- Length of string needed to store PBA number.
   --
   E1000_PBANUM_LENGTH                     : constant := 11;

   -- For checksumming, the sum of all words in the NVM should equal 0xBABA.
   --
   NVM_SUM                                 : constant := 16#baba#;

   -- PBA (printed board assembly) number words.
   --
   NVM_PBA_OFFSET_0                        : constant := 8;
   NVM_PBA_OFFSET_1                        : constant := 9;
   NVM_PBA_PTR_GUARD                       : constant := 16#fafa#;
   NVM_WORD_SIZE_BASE_SHIFT                : constant := 6;

   -- NVM Commands - SPI.
   --
   NVM_MAX_RETRY_SPI                       : constant := 5_000;     -- Max wait of 5ms, for RDY signal.
   NVM_READ_OPCODE_SPI                     : constant := 16#3#;     -- NVM read opcode.
   NVM_WRITE_OPCODE_SPI                    : constant := 16#2#;     -- NVM write opcode.
   NVM_A8_OPCODE_SPI                       : constant := 16#8#;     -- Opcode bit-3 = address bit-8.
   NVM_WREN_OPCODE_SPI                     : constant := 16#6#;     -- NVM set Write Enable latch.
   NVM_RDSR_OPCODE_SPI                     : constant := 16#5#;     -- NVM read Status register.

   -- SPI NVM Status Register.
   --
   NVM_STATUS_RDY_SPI                      : constant := 16#1#;

   -- Word definitions for ID LED Settings.
   --
   ID_LED_RESERVED_0000                    : constant := 16#0#;
   ID_LED_RESERVED_FFFF                    : constant := 16#ffff#;
   ID_LED_DEF1_DEF2                        : constant := 16#1#;
   ID_LED_DEF1_ON2                         : constant := 16#2#;
   ID_LED_DEF1_OFF2                        : constant := 16#3#;
   ID_LED_ON1_DEF2                         : constant := 16#4#;
   ID_LED_ON1_ON2                          : constant := 16#5#;
   ID_LED_ON1_OFF2                         : constant := 16#6#;
   ID_LED_OFF1_DEF2                        : constant := 16#7#;
   ID_LED_OFF1_ON2                         : constant := 16#8#;
   ID_LED_OFF1_OFF2                        : constant := 16#9#;

   ID_LED_DEFAULT                          : constant interfaces.Unsigned_8 :=    interfaces.shift_Left (ID_LED_OFF1_ON2, 12)
                                                                               or interfaces.shift_Left (ID_LED_OFF1_OFF2, 8)
                                                                               or interfaces.shift_Left (ID_LED_DEF1_DEF2, 4)
                                                                               or                        ID_LED_DEF1_DEF2;

   IGP_ACTIVITY_LED_MASK                   : constant := 16#ffff_f0ff#;
   IGP_ACTIVITY_LED_ENABLE                 : constant := 16#300#;
   IGP_LED3_MODE                           : constant := 16#700_0000#;

   -- PCI/PCI-X/PCI-EX Config space.
   --
   PCI_HEADER_TYPE_REGISTER                : constant := 16#e#;

   PHY_REVISION_MASK                       : constant := 16#ffff_fff0#;
   MAX_PHY_REG_ADDRESS                     : constant := 16#1f#;            -- 5 bit address bus (0-0x1F).
   MAX_PHY_MULTI_PAGE_REG                  : constant := 16#f#;

   -- Bit definitions for valid PHY IDs.
   --
   -- I = Integrated
   -- E = External
   --
   M88E1000_E_PHY_ID                       : constant := 16#141_0c50#;
   M88E1000_I_PHY_ID                       : constant := 16#141_0c30#;
   M88E1011_I_PHY_ID                       : constant := 16#141_0c20#;
   IGP01E1000_I_PHY_ID                     : constant := 16#2a8_0380#;
   M88E1111_I_PHY_ID                       : constant := 16#141_0cc0#;
   GG82563_E_PHY_ID                        : constant := 16#141_0ca0#;
   IGP03E1000_E_PHY_ID                     : constant := 16#2a8_0390#;
   IFE_E_PHY_ID                            : constant := 16#2a8_0330#;
   IFE_PLUS_E_PHY_ID                       : constant := 16#2a8_0320#;
   IFE_C_E_PHY_ID                          : constant := 16#2a8_0310#;
   BME1000_E_PHY_ID                        : constant := 16#141_0cb0#;
   BME1000_E_PHY_ID_R2                     : constant := 16#141_0cb1#;
   I82577_E_PHY_ID                         : constant := 16#154_0050#;
   I82578_E_PHY_ID                         : constant := 16#4d_d040#;
   I82579_E_PHY_ID                         : constant := 16#154_0090#;
   I217_E_PHY_ID                           : constant := 16#154_00a0#;

   -- M88E1000 Specific Registers.
   --
   M88E1000_PHY_SPEC_CTRL                  : constant := 16#10#;       -- PHY Specific Control Register.
   M88E1000_PHY_SPEC_STATUS                : constant := 16#11#;       -- PHY Specific Status Register.
   M88E1000_EXT_PHY_SPEC_CTRL              : constant := 16#14#;       -- Extended PHY Specific Control.

   M88E1000_PHY_PAGE_SELECT                : constant := 16#1d#;       -- Reg 29 for page number setting.
   M88E1000_PHY_GEN_CONTROL                : constant := 16#1e#;       -- Meaning depends on reg 29.

   -- M88E1000 PHY Specific Control Register.
   --
   M88E1000_PSCR_POLARITY_REVERSAL         : constant := 16#2#;        -- 1=Polarity Reversal enabled.
   M88E1000_PSCR_MDI_MANUAL_MODE           : constant := 16#0#;        -- MDI Crossover Mode bits 6:5. Manual MDI configuration.
   M88E1000_PSCR_MDIX_MANUAL_MODE          : constant := 16#20#;       -- Manual MDIX configuration.

   M88E1000_PSCR_AUTO_X_1000T              : constant := 16#40#;       -- 1000BASE-T: Auto crossover, 100BASE-TX/10BASE-T: MDI Mode.
   M88E1000_PSCR_AUTO_X_MODE               : constant := 16#60#;       -- Auto crossover enabled all speeds.
   M88E1000_PSCR_ASSERT_CRS_ON_TX          : constant := 16#800#;      -- 1=Assert CRS on Transmit.

   -- M88E1000 PHY Specific Status Register.
   --
   M88E1000_PSSR_REV_POLARITY              : constant := 16#2#;        -- 1=Polarity reversed.
   M88E1000_PSSR_DOWNSHIFT                 : constant := 16#20#;       -- 1=Downshifted.
   M88E1000_PSSR_MDIX                      : constant := 16#40#;       -- 1=MDIX; 0=MDI.
   M88E1000_PSSR_CABLE_LENGTH              : constant := 16#380#;      -- 0=<50M; 1=50-80M; 2=80-110M; 3=110-140M; 4=>140M.
   M88E1000_PSSR_SPEED                     : constant := 16#c000#;     -- Speed, bits 14:15.
   M88E1000_PSSR_1000MBS                   : constant := 16#8000#;     -- 10=1000Mbs.

   M88E1000_PSSR_CABLE_LENGTH_SHIFT        : constant := 7;

   -- Number of times we will attempt to autonegotiate before downshifting if we are the master.
   --
   M88E1000_EPSCR_MASTER_DOWNSHIFT_MASK    : constant := 16#c00#;
   M88E1000_EPSCR_MASTER_DOWNSHIFT_1X      : constant := 16#0#;

   -- Number of times we will attempt to autonegotiate before downshifting if we are the slave.
   --
   M88E1000_EPSCR_SLAVE_DOWNSHIFT_MASK     : constant := 16#300#;
   M88E1000_EPSCR_SLAVE_DOWNSHIFT_1X       : constant := 16#100#;
   M88E1000_EPSCR_TX_CLK_25                : constant := 16#70#;      -- 25 MHz TX_CLK.

   -- M88EC018 Rev 2 specific DownShift settings.
   --
   M88EC018_EPSCR_DOWNSHIFT_COUNTER_MASK   : constant := 16#e00#;
   M88EC018_EPSCR_DOWNSHIFT_COUNTER_5X     : constant := 16#800#;

   I82578_EPSCR_DOWNSHIFT_ENABLE           : constant := 16#20#;
   I82578_EPSCR_DOWNSHIFT_COUNTER_MASK     : constant := 16#1c#;

   -- BME1000 PHY Specific Control Register.
   --
   BME1000_PSCR_ENABLE_DOWNSHIFT           : constant := 16#800#;     -- 1 = Enable downshift.


   -- Bits ...
   --
   -- 15-5: page
   --  4-0: register offset
   --
   GG82563_PAGE_SHIFT                      : constant :=  5;
   GG82563_MIN_ALT_REG                     : constant := 30;

   function GG82563_REG (page : in interfaces.Unsigned_16;
                         reg  : in interfaces.Unsigned_16) return interfaces.Unsigned_16
   is
     (   interfaces.shift_Left (page, GG82563_PAGE_SHIFT)
      or (reg and MAX_PHY_REG_ADDRESS));

   GG82563_PHY_SPEC_CTRL                   : constant interfaces.Unsigned_16 := GG82563_REG (  0, 16);     -- PHY Specific Control.
   GG82563_PHY_PAGE_SELECT                 : constant interfaces.Unsigned_16 := GG82563_REG (  0, 22);     -- Page Select.
   GG82563_PHY_SPEC_CTRL_2                 : constant interfaces.Unsigned_16 := GG82563_REG (  0, 26);     -- PHY Specific Control 2.
   GG82563_PHY_PAGE_SELECT_ALT             : constant interfaces.Unsigned_16 := GG82563_REG (  0, 29);     -- Alternate Page Select.
   GG82563_PHY_MAC_SPEC_CTRL               : constant interfaces.Unsigned_16 := GG82563_REG (  2, 21);     -- MAC Specific Control Register.
   GG82563_PHY_DSP_DISTANCE                : constant interfaces.Unsigned_16 := GG82563_REG (  5, 26);     -- DSP Distance.

   -- Page 193 - Port Control Registers.
   --
   GG82563_PHY_KMRN_MODE_CTRL              : constant interfaces.Unsigned_16 := GG82563_REG (193, 16);     -- Kumeran Mode Control.
   GG82563_PHY_PWR_MGMT_CTRL               : constant interfaces.Unsigned_16 := GG82563_REG (193, 20);     -- Power Management Control.

   -- Page 194 - KMRN Registers.
   --
   GG82563_PHY_INBAND_CTRL                 : constant interfaces.Unsigned_16 := GG82563_REG (194, 18);     -- Inband Control.


   -- MDI Control.
   --
   E1000_MDIC_REG_MASK                     : constant := 16#1f_0000#;
   E1000_MDIC_REG_SHIFT                    : constant := 16;
   E1000_MDIC_PHY_SHIFT                    : constant := 21;
   E1000_MDIC_OP_WRITE                     : constant := 16#400_0000#;
   E1000_MDIC_OP_READ                      : constant := 16#800_0000#;
   E1000_MDIC_READY                        : constant := 16#1000_0000#;
   E1000_MDIC_ERROR                        : constant := 16#4000_0000#;

   -- SerDes Control.
   --
   E1000_GEN_POLL_TIMEOUT                  : constant := 640;

end Devices.e1000e.Defines;
