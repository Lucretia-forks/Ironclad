with
     Devices.e1000e.Core.Pointers,
     Interfaces.C.Strings,
     Interfaces.C.Pointers,
     Devices.e1000e.Hardware,
     System;

limited
with
     Devices.e1000e.Base.e1000_adapter;


package Linux
--
--  Surrogates for Linux kernel declarations.
--
is
   use Devices.e1000e.Core,
       Devices.e1000e.Core.Pointers,
       Interfaces;

   use type C.size_t,
       C.int,
       C.unsigned;




   ---------------
   -- Constants --
   ---------------
   MSEC_PER_SEC          : constant := 1_000;

   ENOMEM                : constant := 12;               -- Out of memory.

   MII_BMCR              : constant := 16#00#;           -- Basic mode control register.
   MII_BMSR              : constant := 16#01#;           -- Basic mode status register.
   MII_PHYSID1           : constant := 16#02#;           -- PHYS ID 1.
   MII_PHYSID2           : constant := 16#03#;           -- PHYS ID 2.
   MII_ADVERTISE         : constant := 16#04#;           -- Advertisement control reg.
   MII_LPA               : constant := 16#05#;           -- Link partner ability reg.
   MII_EXPANSION         : constant := 16#06#;           -- Expansion register.
   MII_CTRL1000          : constant := 16#09#;           -- 1000BASE-T control.
   MII_STAT1000          : constant := 16#0a#;           -- 1000BASE-T status.
   MII_ESTATUS           : constant := 16#0F#;           -- Extended Status.

   ADVERTISED_Pause      : constant := 16#0000#;         -- TODO: Should be      __ETHTOOL_LINK_MODE_LEGACY_MASK(Pause)
   ADVERTISED_Asym_Pause : constant := 16#0000#;         -- TODO: Should be      __ETHTOOL_LINK_MODE_LEGACY_MASK(Asym_Pause)

   ADVERTISE_PAUSE_CAP   : constant := 16#0400#;         -- Try for pause.
   ADVERTISE_PAUSE_ASYM  : constant := 16#0800#;         -- Try for asymetric pause.
   ADVERTISE_100FULL     : constant := 16#0100#;         -- Try for 100mbps full-duplex.
   ADVERTISE_100HALF     : constant := 16#0080#;         -- Try for 100mbps half-duplex.
   ADVERTISE_10FULL      : constant := 16#0040#;         -- Try for 10mbps full-duplex.
   ADVERTISE_10HALF      : constant := 16#0020#;         -- Try for 10mbps half-duplex.
   ADVERTISE_1000HALF    : constant := 16#0100#;         -- Advertise 1000BASE-T half duplex.
   ADVERTISE_1000FULL    : constant := 16#0200#;         -- Advertise 1000BASE-T full duplex.
   ADVERTISE_CSMA        : constant := 16#0001#;         -- Only selector supported.

   ADVERTISE_ALL         : constant Devices.e1000e.Core.u16 :=    ADVERTISE_10HALF
                                                or ADVERTISE_10FULL
                                                or ADVERTISE_100HALF
                                                or ADVERTISE_100FULL;

   EXPANSION_ENABLENPAGE : constant := 16#0004#;         -- This enables npage words.
   EXPANSION_NWAY        : constant := 16#0001#;         -- Can do N-way auto-nego.

   ESTATUS_1000_THALF    : constant := 16#1000#;         -- Can do 1000BT Half.
   ESTATUS_1000_TFULL    : constant := 16#2000#;         -- Can do 1000BT Full.

   LPA_100FULL           : constant := 16#0100#;         -- Can do 100mbps full-duplex.
   LPA_PAUSE_CAP         : constant := 16#0400#;         -- Can pause.
   LPA_PAUSE_ASYM        : constant := 16#0800#;         -- Can pause asymetrically.
   LPA_1000LOCALRXOK     : constant := 16#2000#;         -- Link partner local receiver status.
   LPA_1000REMRXOK       : constant := 16#1000#;         -- Link partner remote receiver status.

   PCI_LTR_VALUE_MASK    : constant := 16#000003ff#;
   PCI_LTR_SCALE_SHIFT   : constant := 10;

   SPEED_10              : constant :=    10;
   SPEED_100             : constant :=   100;
   SPEED_1000            : constant := 1_000;

   BMCR_RESET            : constant := 16#8000#;         -- Reset to default state.
   BMCR_ANENABLE         : constant := 16#1000#;         -- Enable auto negotiation.
   BMCR_ANRESTART        : constant := 16#0200#;         -- Auto negotiation restart.
   BMCR_FULLDPLX         : constant := 16#0100#;         -- Full duplex.
   BMCR_SPEED100         : constant := 16#2000#;         -- Select 100Mbps.
   BMCR_SPEED1000        : constant := 16#0040#;         -- MSB of Speed (1000).
   BMCR_PDOWN            : constant := 16#0800#;         -- Enable low power state.
   BMCR_LOOPBACK         : constant := 16#4000#;         -- TXD loopback bits.

   CTL1000_AS_MASTER     : constant := 16#0800#;
   CTL1000_ENABLE_MASTER : constant := 16#1000#;


   KERN_SOH              : constant String := "" & Character'Val (1);
   KERN_INFO             : constant String := KERN_SOH & "6";        -- Informational.

   PAGE_SIZE             : constant := 4096;
   PAGE_SHIFT            : constant := 12;

   CHECKSUM_UNNECESSARY  : constant := 1;
   CHECKSUM_PARTIAL      : constant := 3;

   IRQF_SHARED           : constant := 16#00000080#;


   ETH_DATA_LEN          : constant := 1500;             -- Max octets in payload.
   ETH_FRAME_LEN         : constant := 1514;             -- Max octets in frame sans FCS.
   ETH_P_1588            : constant := 16#88F7#;         -- IEEE 1588 Timesync.
   ETH_P_IP              : constant := 16#0800#;         -- Internet Protocol packet.
   ETH_P_IPV6            : constant := 16#86DD#;         -- IPv6 over bluebook.
   ETH_P_8021Q           : constant := 16#8100#;         -- 802.1Q VLAN Extended Header
   ETH_MIN_MTU           : constant := 68;               -- Min IPv4 MTU per RFC791

   PTP_EV_PORT           : constant := 319;

   VLAN_ETH_HLEN         : constant := 18;               -- Total octets in header.

   ETH_ZLEN              : constant := 60;               -- Min octets in frame sans FCS.

   PCI_COMMAND           : constant := 16#04#;           -- 16 bits.
   PCI_COMMAND_SERR      : constant := 16#100#;          -- Enable SERR.
   PCI_EXP_DEVCTL        : constant := 16#08#;           -- Device Control.
   PCI_EXP_DEVCTL_CERE   : constant := 16#0001#;         -- Correctable Error Reporting En.

   EADDRNOTAVAIL         : constant := 99;               -- Cannot assign requested address.

   SIOCGMIIPHY           : constant := 16#8947#;         -- Get address of MII PHY in use.
   SIOCGMIIREG           : constant := 16#8948#;         -- Read MII PHY register.
   SIOCGHWTSTAMP         : constant := 16#89B1#;         -- Get config.
   SIOCSMIIREG           : constant := 16#8949#;         -- Write MII PHY register.
   SIOCSHWTSTAMP         : constant := 16#89b0#;         -- Set and get config.

   -- Basic mode status register.
   --
   BMSR_ERCAP        : constant := 16#0001#;     -- Ext-reg capability.
   BMSR_JCD          : constant := 16#0002#;     -- Jabber detected.
   BMSR_LSTATUS      : constant := 16#0004#;     -- Link status.
   BMSR_ANEGCAPABLE  : constant := 16#0008#;     -- Able to do auto-negotiation.
   BMSR_RFAULT       : constant := 16#0010#;     -- Remote fault detected.
   BMSR_ANEGCOMPLETE : constant := 16#0020#;     -- Auto-negotiation complete.
   BMSR_RESV         : constant := 16#00C0#;     -- Unused ...
   BMSR_ESTATEN      : constant := 16#0100#;     -- Extended Status in R15.
   BMSR_100HALF2     : constant := 16#0200#;     -- Can do 100BASE-T2 HDX.
   BMSR_100FULL2     : constant := 16#0400#;     -- Can do 100BASE-T2 FDX.
   BMSR_10HALF       : constant := 16#0800#;     -- Can do 10mbps, half-duplex.
   BMSR_10FULL       : constant := 16#1000#;     -- Can do 10mbps, full-duplex.
   BMSR_100HALF      : constant := 16#2000#;     -- Can do 100mbps, half-duplex.
   BMSR_100FULL      : constant := 16#4000#;     -- Can do 100mbps, full-duplex.
   BMSR_100BASE4     : constant := 16#8000#;     -- Can do 100mbps, 4k packets.


   PCIE_LINK_STATE_L0S     : constant := 2#11#;        -- Upstr/dwnstr L0s.
   PCIE_LINK_STATE_L1      : constant := 2#100#;       -- L1 state.
   PCI_EXP_LNKCTL_ASPM_L0S : constant := 16#0001#;     -- L0s Enable.
   PCI_EXP_LNKCTL_ASPM_L1  : constant := 16#0002#;     -- L1 Enable.
   PCI_EXP_LNKCTL          : constant := 16;           -- Link Control.
   PCI_EXP_LNKCTL_ASPMC    : constant := 16#0003#;     -- ASPM Control.



   CONFIG_PCIEASPM : constant Boolean := True;     -- TODO: Generated by autoconf.

   IORESOURCE_MEM  : constant := 16#00000200#;


   MDIO_AN_EEE_ADV_100TX : constant := 16#0002#;   -- Advertise 100TX EEE cap.
   MDIO_AN_EEE_ADV_1000T : constant := 16#0004#;   -- Advertise 1000T EEE cap.
   --
   -- Note: the two defines above can be potentially used by the user-land
   -- and cannot remove them now.
   -- So, we define the new generic MDIO_EEE_100TX and MDIO_EEE_1000T macros
   -- using the previous ones (that can be considered obsolete).
   --
   MDIO_EEE_100TX : constant := MDIO_AN_EEE_ADV_100TX;   -- 100TX EEE cap.
   MDIO_EEE_1000T : constant := MDIO_AN_EEE_ADV_1000T;   -- 1000T EEE cap.

   DPM_FLAG_SMART_PREPARE : constant := 2#10#;




   -- C Errors
   --
   EINVAL                : constant :=  22;               -- C's Invalid argument.
   ERANGE                : constant :=  34;               -- C's Math result not representable.
   EAGAIN                : constant :=  11;               -- C's Try again.
   EFAULT                : constant :=  14;               -- Bad address.
   EBUSY                 : constant :=  16;               -- Device or resource busy.
   EOPNOTSUPP            : constant :=  95;               -- Operation not supported on transport endpoint.
   EIO                   : constant :=   5;               -- I/O error.
   ETIMEDOUT             : constant := 110;               -- Connection timed out.





   -- Variables
   --

   Jiffies : C.unsigned_long
     with
       Volatile;




   -- Netdev Features
   --
   subtype Netdev_Features_T is Unsigned_64;

   type Feature_Flag is (NETIF_F_SG_BIT,                    -- Scatter/gather IO.
                         NETIF_F_IP_CSUM_BIT,               -- Can checksum TCP/UDP over IPv4.
                         NETIF_F_HW_CSUM_BIT,               -- Can checksum all the packets.
                         NETIF_F_IPV6_CSUM_BIT,             -- Can checksum TCP/UDP over IPV6
                         NETIF_F_HIGHDMA_BIT,               -- Can DMA to high memory.
                         NETIF_F_FRAGLIST_BIT,              -- Scatter/gather IO.
                         NETIF_F_HW_VLAN_CTAG_TX_BIT,       -- Transmit VLAN CTAG HW acceleration
                         NETIF_F_HW_VLAN_CTAG_RX_BIT,       -- Receive VLAN CTAG HW acceleration
                         NETIF_F_HW_VLAN_CTAG_FILTER_BIT,   -- Receive filtering on VLAN CTAGs
                         NETIF_F_VLAN_CHALLENGED_BIT,       -- Device cannot handle VLAN packets
                         NETIF_F_GSO_BIT,                   -- Enable software GSO.
                         NETIF_F_LLTX_BIT,                  -- LockLess TX - deprecated.
                         NETIF_F_NETNS_LOCAL_BIT,           -- Does not change network namespaces
                         NETIF_F_GRO_BIT,                   -- Generic receive offload
                         NETIF_F_LRO_BIT,                   -- Large receive offload
                         NETIF_F_TSO_BIT,                   -- TCPv4 segmentation
                         NETIF_F_GSO_ROBUST_BIT,            -- SKB_GSO_DODGY
                         NETIF_F_TSO_ECN_BIT,               -- TCP ECN support
                         NETIF_F_TSO_MANGLEID_BIT,          -- IPV4 ID mangling allowed
                         NETIF_F_TSO6_BIT,                  -- TCPv6 segmentation
                         NETIF_F_FSO_BIT,                   -- FCoE segmentation
                         NETIF_F_GSO_GRE_BIT,               -- GRE with TSO
                         NETIF_F_GSO_GRE_CSUM_BIT,          -- GRE with csum with TSO
                         NETIF_F_GSO_IPXIP4_BIT,            -- IP4 or IP6 over IP4 with TSO
                         NETIF_F_GSO_IPXIP6_BIT,            -- IP4 or IP6 over IP6 with TSO
                         NETIF_F_GSO_UDP_TUNNEL_BIT,        -- UDP TUNNEL with TSO
                         NETIF_F_GSO_UDP_TUNNEL_CSUM_BIT,   -- UDP TUNNEL with TSO & CSUM
                         NETIF_F_GSO_PARTIAL_BIT,           -- Only segment inner-most L4 in hardware
                         NETIF_F_GSO_TUNNEL_REMCSUM_BIT,    -- TUNNEL with TSO & REMCSUM
                         NETIF_F_GSO_SCTP_BIT,              -- SCTP fragmentation
                         NETIF_F_GSO_ESP_BIT,               -- ESP with TSO
                         NETIF_F_GSO_UDP_BIT,               -- UFO, deprecated except tuntap
                         NETIF_F_GSO_UDP_L4_BIT,            -- UDP payload GSO (not UFO)
                         NETIF_F_GSO_FRAGLIST_BIT,          -- Fraglist GSO
                         NETIF_F_FCOE_CRC_BIT,              -- FCoE CRC32
                         NETIF_F_SCTP_CRC_BIT,              -- SCTP checksum offload
                         NETIF_F_FCOE_MTU_BIT,              -- Supports max FCoE MTU, 2158 bytes
                         NETIF_F_NTUPLE_BIT,                -- N-tuple filters supported
                         NETIF_F_RXHASH_BIT,                -- Receive hashing offload
                         NETIF_F_RXCSUM_BIT,                -- Receive checksumming offload
                         NETIF_F_NOCACHE_COPY_BIT,          -- Use no-cache copyfromuser
                         NETIF_F_LOOPBACK_BIT,              -- Enable loopback
                         NETIF_F_RXFCS_BIT,                 -- Append FCS to skb pkt data
                         NETIF_F_RXALL_BIT,                 -- Receive errored frames too
                         NETIF_F_HW_VLAN_STAG_TX_BIT,       -- Transmit VLAN STAG HW acceleration
                         NETIF_F_HW_VLAN_STAG_RX_BIT,       -- Receive VLAN STAG HW acceleration
                         NETIF_F_HW_VLAN_STAG_FILTER_BIT,   -- Receive filtering on VLAN STAGs
                         NETIF_F_HW_L2FW_DOFFLOAD_BIT,      -- Allow L2 Forwarding in Hardware
                         NETIF_F_HW_TC_BIT,                 -- Offload TC infrastructure
                         NETIF_F_HW_ESP_BIT,                -- Hardware ESP transformation offload
                         NETIF_F_HW_ESP_TX_CSUM_BIT,        -- ESP with TX checksum offload
                         NETIF_F_RX_UDP_TUNNEL_PORT_BIT,    -- Offload of RX port for UDP tunnels
                         NETIF_F_HW_TLS_TX_BIT,             -- Hardware TLS TX offload
                         NETIF_F_HW_TLS_RX_BIT,             -- Hardware TLS RX offload
                         NETIF_F_GRO_HW_BIT,                -- Hardware Generic receive offload
                         NETIF_F_HW_TLS_RECORD_BIT,         -- Offload TLS record
                         NETIF_F_GRO_FRAGLIST_BIT,          -- Fraglist GRO
                         NETIF_F_HW_MACSEC_BIT,             -- Offload MACsec operations
                         NETIF_F_GRO_UDP_FWD_BIT,           -- Allow UDP GRO for forwarding
                         NETIF_F_HW_HSR_TAG_INS_BIT,        -- Offload HSR tag insertion
                         NETIF_F_HW_HSR_TAG_RM_BIT,         -- Offload HSR tag removal
                         NETIF_F_HW_HSR_FWD_BIT,            -- Offload HSR forwarding
                         NETIF_F_HW_HSR_DUP_BIT);           -- Offload HSR duplication


   NETIF_F_SG              : constant Netdev_Features_T := BIT (NETIF_F_SG_BIT             'Enum_Rep);
   NETIF_F_HW_CSUM         : constant Netdev_Features_T := BIT (NETIF_F_HW_CSUM_BIT        'Enum_Rep);
   NETIF_F_RXCSUM          : constant Netdev_Features_T := BIT (NETIF_F_RXCSUM_BIT         'Enum_Rep);
   NETIF_F_RXHASH          : constant Netdev_Features_T := BIT (NETIF_F_RXHASH_BIT         'Enum_Rep);
   NETIF_F_RXALL           : constant Netdev_Features_T := BIT (NETIF_F_RXALL_BIT          'Enum_Rep);
   NETIF_F_RXFCS           : constant Netdev_Features_T := BIT (NETIF_F_RXFCS_BIT          'Enum_Rep);
   NETIF_F_HW_VLAN_CTAG_RX : constant Netdev_Features_T := BIT (NETIF_F_HW_VLAN_CTAG_RX_BIT'Enum_Rep);
   NETIF_F_HW_VLAN_CTAG_TX     : constant Netdev_Features_T := BIT (NETIF_F_HW_VLAN_CTAG_TX_BIT'Enum_Rep);
   NETIF_F_HW_VLAN_CTAG_FILTER : constant Netdev_Features_T := BIT (NETIF_F_HW_VLAN_CTAG_FILTER_BIT'Enum_Rep);
   NETIF_F_TSO             : constant Netdev_Features_T := BIT (NETIF_F_TSO_BIT            'Enum_Rep);
   NETIF_F_TSO6            : constant Netdev_Features_T := BIT (NETIF_F_TSO6_BIT           'Enum_Rep);
   NETIF_F_HIGHDMA            : constant Netdev_Features_T := BIT (NETIF_F_HIGHDMA_BIT           'Enum_Rep);



   VLAN_ETH_FRAME_LEN : constant := 1518;     -- Max octets in frame sans FCS.
   ETH_FCS_LEN        : constant :=    4;     -- Octets in the FCS.

   NET_IP_ALIGN       : constant := 2;



   type GFP_Bit_Position is (GFP_DMA_BIT,
                             GFP_HIGHMEM_BIT,
                             GFP_DMA32_BIT,
                             GFP_MOVABLE_BIT,
                             GFP_RECLAIMABLE_BIT,
                             GFP_HIGH_BIT,
                             GFP_IO_BIT,
                             GFP_FS_BIT,
                             GFP_ZERO_BIT,
                             GFP_UNUSED_BIT,         -- 0x200u unused
                             GFP_DIRECT_RECLAIM_BIT,
                             GFP_KSWAPD_RECLAIM_BIT,
                             GFP_WRITE_BIT,
                             GFP_NOWARN_BIT,
                             GFP_RETRY_MAYFAIL_BIT,
                             GFP_NOFAIL_BIT,
                             GFP_NORETRY_BIT,
                             GFP_MEMALLOC_BIT,
                             GFP_COMP_BIT,
                             GFP_NOMEMALLOC_BIT,
                             GFP_HARDWALL_BIT,
                             GFP_THISNODE_BIT,
                             GFP_ACCOUNT_BIT,
                             GFP_ZEROTAGS_BIT,
                             GFP_SKIP_ZERO_BIT,      -- Only if CONFIG_KASAN_HW_TAGS is defined
                             GFP_SKIP_KASAN_BIT,     -- Only if CONFIG_KASAN_HW_TAGS is defined
                             GFP_NOLOCKDEP_BIT,      -- Only if CONFIG_LOCKDEP is defined
                             GFP_NO_OBJ_EXT_BIT,     -- Only if CONFIG_SLAB_OBJ_EXT is defined
                             GFP_LAST_BIT);


   GFP_HIGH           : constant u32 := BIT (GFP_HIGH_BIT          'Enum_Rep);
   GFP_KSWAPD_RECLAIM : constant u32 := BIT (GFP_KSWAPD_RECLAIM_BIT'Enum_Rep);



   GFP_Atomic : constant Unsigned_32 := GFP_High or GFP_Kswapd_Reclaim;





   -----------
   -- Types --
   -----------


   type Dump_Prefix_Type is (DUMP_PREFIX_NONE,
                             DUMP_PREFIX_ADDRESS,
                             DUMP_PREFIX_OFFSET);



   -- sk_buff
   --
   type sk_buff is
      record
         Protocol    : be16;
         Ip_Summed   : u8;
         Data        : void_ptr;
         Len         : Natural;
         Data_Len    : u32;
         Truesize    : u32;
         Csum_Offset : u8;
         no_fcs      : Boolean;
      end record;

   type sk_buff_array is array (Interfaces.C.size_t range <>) of aliased sk_buff;



   -- ktime_t
   --
   subtype ktime_t is Integer_64;




   -- system_device_crosststamp
   --

   type system_device_crosststamp is
      record
         device      : ktime_t;
         sys_realtime: ktime_t;
         sys_monoraw  : ktime_t;
      end record;



   ------------------
   -- SKB_Shared_Info
   --

   type atomic_Counter is new u64
     with
       Atomic;     -- TODO: Check.


   subtype Netmem_Ref is system.Address;



   -- skb_shared_hwtstamps
   --
   type skb_shared_hwtstamps (Is_Hwtstamp : Boolean := True) is
      record
         case Is_Hwtstamp is
            when True  =>   Hwtstamp    : Ktime_T;
            when False =>   Netdev_Data : System.Address;
         end case;
      end record
     with
       unchecked_Union;




   type Xsk_Tx_Metadata_Compl is
      record
      Tx_Timestamp : access Interfaces.Unsigned_64;
   end record;


   type HW_or_XSK_union (is_HW : Boolean := False) is
      record
         case is_HW
         is
            when True  =>   HWTimestamps : SKB_Shared_HWTstamps;
            when False =>   XSK_Meta     : XSK_TX_Metadata_Compl;
         end case;
      end record;


   type Skb_Frag_T is
      record
         Netmem  : Netmem_Ref;
         Len     : C.unsigned;
         Offset  : C.unsigned;
      end record;


   type SKB_Frag_array is array (C.size_t range <>) of aliased Skb_Frag_T;


   Config_Max_Skb_Frags : constant := 17;
   Max_Skb_Frags        : constant := Config_Max_Skb_Frags;


   type SKB_Shared_Info is
      record
         Flags      : Unsigned_8;
         Meta_Len   : Unsigned_8;
         Nr_Frags   : Unsigned_8;
         Tx_Flags   : Unsigned_8;
         GSO_Size   : Unsigned_16;

         -- Warning: this field is not always filled in (UFO)!
         --
         GSO_Segs   : Unsigned_16;
         Frag_List  : access SK_Buff;

         HW_or_XSK  : HW_or_XSK_union;
         GSO_Type   : Unsigned_32;
         TSKey      : Unsigned_32;

         -- Warning : all fields before dataref are cleared in Alloc_SKB.
         --
         Dataref        : Atomic_Counter;
         XDP_Frags_Size : Unsigned_32;

         -- Intermediate layers must ensure that Destructor_Arg
         -- remains valid until skb destructor.
         --
         Destructor_Arg : System.Address;

         -- Must be last field, see pskb_expand_head().
         --
         Frags : SKB_Frag_Array (0 .. MAX_SKB_FRAGS - 1);
      end record;



   -- page
   --
   type Page is
      record
         Page : System.Address;
      end record;

   type page_array is array (Interfaces.C.size_t range <>) of aliased page;


   -- timer_list
   --
   type timer_list is null record;

   type timer_list_array is array (Interfaces.C.size_t range <>) of aliased timer_list;


   -- napi_struct
   --
   type napi_struct is null record;

   type napi_struct_array is array (Interfaces.C.size_t range <>) of aliased napi_struct;


   -- dma_addr_t
   --
   subtype dma_addr_t is u64;

   type dma_addr_t_array is array (Interfaces.C.size_t range <>) of aliased dma_addr_t;


   -- gfp_t
   --
   subtype gfp_t is u32;

   type gfp_t_array is array (Interfaces.C.size_t range <>) of aliased gfp_t;



   type sockaddr is
      record
         sa_Data : u8_Pointer;
      end record;



   -- device
   --

   type Device;

   type Device is
      record
         Parent : access Device;
      end record;



   -- net_device_stats
   --

   type net_device_stats is
      record
         rx_packets          : C.unsigned_long;
         tx_packets          : C.unsigned_long;
         rx_bytes            : C.unsigned_long;
         tx_bytes            : C.unsigned_long;
         rx_errors           : C.unsigned_long;
         tx_errors           : C.unsigned_long;
         rx_dropped          : C.unsigned_long;
         tx_dropped          : C.unsigned_long;
         multicast           : C.unsigned_long;
         collisions          : C.unsigned_long;
         rx_length_errors    : C.unsigned_long;
         rx_over_errors      : C.unsigned_long;
         rx_crc_errors       : C.unsigned_long;
         rx_frame_errors     : C.unsigned_long;
         rx_fifo_errors      : C.unsigned_long;
         rx_missed_errors    : C.unsigned_long;
         tx_aborted_errors   : C.unsigned_long;
         tx_carrier_errors   : C.unsigned_long;
         tx_fifo_errors      : C.unsigned_long;
         tx_heartbeat_errors : C.unsigned_long;
         tx_window_errors    : C.unsigned_long;
         rx_compressed       : C.unsigned_long;
         tx_compressed       : C.unsigned_long;
      end record;




   -- pci_bus
   --

   type pci_dev;

   type pci_bus is
      record
         Self     : access pci_dev;
      end record;




   -- net_device
   --

   type net_device_ops;

   MAX_ADDR_LEN : constant := 32;     -- Largest hardware address length.

   type perm_address_t is array (0 .. MAX_ADDR_LEN - 1) of C.unsigned_char;

   type net_device is
      record
         Name       : access String;
         State      :        Integer;
         Flags      :        C.unsigned;
         Features   :        Netdev_Features_T;
         MTU        :        C.unsigned;
         Dev        :        device;
         Addr_Len   :        C.unsigned_char;
         Stats      :        net_device_stats;
         Irq        :        C.int;
         Netdev_Ops : access constant net_device_ops;
         Watchdog_Timeo : C.unsigned;
         mem_end        : C.unsigned_long;
         mem_start      : C.unsigned_long;
         hw_features    : netdev_features_t;
         vlan_features  : netdev_features_t;
         priv_flags     : C.unsigned_long_long;
         Min_MTU        : C.unsigned;
         Max_MTU        : C.unsigned;
         Dev_Addr       : u8_Pointer;
         perm_addr      : perm_address_t;
      end record;

   type net_device_array is array (Interfaces.C.size_t range <>) of aliased net_device;



   -- pci_dev
   --
   type pci_dev is
      record
         Dev         : aliased device;
         Device      :         u16;
         Irq         :         C.unsigned;
         Bus         : access  pci_bus;
         PME_Poll    :         Boolean;
         State_Saved :        Boolean;
      end record;

   type pci_dev_array is array (Interfaces.C.size_t range <>) of aliased pci_dev;


   -- spinlock_t
   --
   type spinlock_t is null record;

   type spinlock_t_array is array (Interfaces.C.size_t range <>) of aliased spinlock_t;


   procedure spin_lock_irqsave      (lock : access spinlock_t;
                                     flags: in     C.unsigned_long);     -- TODO

   procedure spin_unlock_irqrestore (lock : access spinlock_t;
                                     flags: in     C.unsigned_long);     -- TODO


   -- msix_entry
   --
   type msix_entry is
      record
      vector    : Interfaces.Unsigned_32;     -- Kernel uses to write allocated vector.
      the_Entry : Interfaces.Unsigned_16;     -- Driver uses to specify entry, OS writes.
   end record;

   type msix_entry_array is array (Interfaces.C.size_t range <>) of aliased msix_entry;


   package msix_entry_Pointers is new Interfaces.C.Pointers (Index              => C.size_t,
                                                             Element            => msix_entry,
                                                             Element_Array      => msix_entry_array,
                                                             Default_Terminator => (others => <>));
   subtype msix_entry_pointer is msix_entry_Pointers.Pointer;


   -- hwtstamp_config
   --
   type hwtstamp_config is
      record
         flags     : C.int;
         tx_type   : C.int;
         rx_filter : C.int;
      end record;

   type hwtstamp_config_array is array (Interfaces.C.size_t range <>) of aliased hwtstamp_config;



   type HWTSTAMP_TX_TYPE is (HWTSTAMP_TX_OFF,
                             HWTSTAMP_TX_ON,
                             HWTSTAMP_TX_ONESTEP_SYNC,
                             HWTSTAMP_TX_ONESTEP_P2P,
                             HWTSTAMP_TX_CNT);



   -- delayed_work
   --
   type delayed_work is null record;

   type delayed_work_array is array (Interfaces.C.size_t range <>) of aliased delayed_work;



   -- cyclecounter
   --
   type cyclecounter;

   type cyclecounter_read_type is access function (cc : access cyclecounter) return Unsigned_64;

   type cyclecounter is
      record
         read  : cyclecounter_read_type;
         mask  : Unsigned_64;
         mult  : Unsigned_32;
         shift : Unsigned_32;
      end record;

   type cyclecounter_array is array (Interfaces.C.size_t range <>) of aliased cyclecounter;



   -- timecounter
   --
   type timecounter is null record;

   type timecounter_array is array (Interfaces.C.size_t range <>) of aliased timecounter;


   function Timecounter_Cyc2time
     (TC           : access constant Timecounter;
      Cycle_Tstamp : in              Unsigned_64) return Unsigned_64
   is
     (raise Program_Error with "TODO");




   -- ptp_clock_info
   --
   type ptp_clock_info;

   --  type ptp_clock_info is
   --     record
   --        adjfine : access function (ptp        : access ptp_clock_info;
   --                                   scaled_ppm : in     C.long) return C.int;
   --     end record;
   --
   --  type ptp_clock_info_array is array (Interfaces.C.size_t range <>) of aliased ptp_clock_info;




   -- Pointer type for ptp_clock_info, similar to a C pointer to struct
   type ptp_clock_info_Ptr is access all ptp_clock_info;

   -- Definition of function pointer type equivalent to:
   -- int (*adjfine)(struct ptp_clock_info *ptp, long scaled_ppm);
   type AdjFine_Func is access function (ptp : access ptp_clock_info; scaled_ppm: C.long) return C.int;

   -- Declaration of the function pointer variable 'adjfine'
   adjfine : AdjFine_Func;
   type ptp_clock is null record;

   type ptp_clock_array is array (Interfaces.C.size_t range <>) of aliased ptp_clock;



   -- pm_qos_request
   --
   type pm_qos_request is null record;

   type pm_qos_request_array is array (Interfaces.C.size_t range <>) of aliased pm_qos_request;




   -- rtnl_link_stats64
   --

   type rtnl_link_stats64 is
      record
         rx_packets           : Unsigned_64;
         tx_packets           : Unsigned_64;
         rx_bytes             : Unsigned_64;
         tx_bytes             : Unsigned_64;
         rx_errors            : Unsigned_64;
         tx_errors            : Unsigned_64;
         rx_dropped           : Unsigned_64;
         tx_dropped           : Unsigned_64;
         multicast            : Unsigned_64;
         collisions           : Unsigned_64;

         -- Detailed rx_errors.
         --
         rx_length_errors     : Unsigned_64;
         rx_over_errors       : Unsigned_64;
         rx_crc_errors        : Unsigned_64;
         rx_frame_errors      : Unsigned_64;
         rx_fifo_errors       : Unsigned_64;
         rx_missed_errors     : Unsigned_64;

         -- Detailed tx_errors.
         --
         tx_aborted_errors    : Unsigned_64;
         tx_carrier_errors    : Unsigned_64;
         tx_fifo_errors       : Unsigned_64;
         tx_heartbeat_errors  : Unsigned_64;
         tx_window_errors     : Unsigned_64;

         -- For cslip etc.
         --
         rx_compressed        : Unsigned_64;
         tx_compressed        : Unsigned_64;
         rx_nohandler         : Unsigned_64;

         rx_otherhost_dropped : Unsigned_64;
      end record;

   type rtnl_link_stats64_array is array (Interfaces.C.size_t range <>) of aliased rtnl_link_stats64;



   -- ptp_system_timestamp
   --
   type ptp_system_timestamp is null record;

   type ptp_system_timestamp_array is array (Interfaces.C.size_t range <>) of aliased ptp_system_timestamp;

   -- work_struct
   --
   type work_struct is null record;

   type work_struct_array is array (Interfaces.C.size_t range <>) of aliased work_struct;




   -- IrqReturn
   --
   type IrqReturn_t is (IRQ_NONE,
                        IRQ_HANDLED,
                        IRQ_WAKE_THREAD);

   -- Irq_Handler_t
   --
   type Irq_Handler_t is access function (Irq  : in C.int;
                                          Data : in void_ptr) return irqreturn_t;


   -------------------------
   --- I/O access functions.
   --

   function readw
     (Addr : in System.Address with Unreferenced) return u16
   is
     (raise Program_Error with "TODO")
       with
         Inline;


   function readl
     (Addr : in System.Address with Unreferenced) return u32
   is
     (raise Program_Error with "TODO")
       with
         Inline;


   procedure writew
     (Value : in u16;
      Addr  : in System.Address);     -- TODO


   procedure writel
     (Value : in u32;
      Addr  : in System.Address);     -- TODO




   --------------------------------
   --- PCI functions and constants.
   --

   PCI_EXP_LNKSTA     : constant := 16#12#;       -- Link Status.
   PCI_EXP_LNKSTA_NLW : constant := 16#03f0#;     -- Negotiated Link Width


   function PCI_Read_Config_Word
     (Dev   : access constant PCI_Dev;
      Where : in              C.int;
      Val   : access          Unsigned_16) return C.int
   is
     (raise Program_Error with "TODO");



   function PCI_PCIe_Cap
     (Dev : access PCI_Dev) return C.int
   is
     (raise Program_Error with "TODO");



   function PCIe_Capability_Read_Word
     (Dev : access PCI_Dev;
      Pos : in     C.int;
      Val : access unsigned_16) return C.int
   is
        (raise Program_Error with "TODO");




   ----------------------------
   --- Miscellaneous functions.
   --

   function FIELD_GET
     (Mask : in u16;
      Reg  : in u16) return u16
   is
     (raise Program_Error with "TODO");



   function FIELD_GET
     (Mask : in u32;
      Reg  : in u32) return u32
   is
     (raise Program_Error with "TODO");



   function Test_And_Set_Bit
     (Nr   : in     Long_Integer;
      Addr : access Unsigned_64) return Boolean
   is
     (raise Program_Error with "TODO");


   function Test_And_Set_Bit
     (Nr   : in     Long_Integer;
      Addr : access C.unsigned_long) return Boolean
   is
     (raise Program_Error with "TODO");



   procedure Clear_Bit
     (Nr   : in     C.long;
      Addr : in system.Address);     -- TODO


   function ether_crc_le
     (length : in u8;
      data   : in u8_array) return Unsigned_64
   is
     (raise Program_Error with "TODO");



   function FIELD_PREP
     (mask : in Unsigned_32;
      val  : in Unsigned_32) return Unsigned_32
   is
      (raise Program_Error with "TODO");



   function Is_Multicast_Ether_Addr
     (Addr : in u8_Pointer) return Boolean
   is
     (raise Program_Error with "TODO");



   procedure Print_Hex_Dump
     (Level       : String;
      Prefix_Str  : String;
      Prefix_Type : Dump_Prefix_Type;
      Rowsize     : Integer;
      Groupsize   : Integer;
      Buf         : System.Address;
      Len         : Interfaces.C.size_t;
      Ascii       : Boolean);              -- TODO



   function Page_Address
     (Page : access constant linux.Page) return System.Address
   is
     (raise Program_Error with "TODO");




   type Message_Type is (NETIF_MSG_DRV_BIT,
                         NETIF_MSG_PROBE_BIT,
                         NETIF_MSG_LINK_BIT,
                         NETIF_MSG_TIMER_BIT,
                         NETIF_MSG_IFDOWN_BIT,
                         NETIF_MSG_IFUP_BIT,
                         NETIF_MSG_RX_ERR_BIT,
                         NETIF_MSG_TX_ERR_BIT,
                         NETIF_MSG_TX_QUEUED_BIT,
                         NETIF_MSG_INTR_BIT,
                         NETIF_MSG_TX_DONE_BIT,
                         NETIF_MSG_RX_STATUS_BIT,
                         NETIF_MSG_PKTDATA_BIT,
                         NETIF_MSG_HW_BIT,
                         NETIF_MSG_WOL_BIT);

   NETIF_MSG_DRV         : constant u32 := BIT (NETIF_MSG_DRV_BIT  'Enum_Rep);
   NETIF_MSG_PROBE       : constant u32 := BIT (NETIF_MSG_PROBE_BIT'Enum_Rep);
   NETIF_MSG_LINK        : constant u32 := BIT (NETIF_MSG_LINK_BIT 'Enum_Rep);
   NETIF_MSG_CLASS_COUNT : constant := Message_Type'Pos (Message_Type'Last) + 1;


   function Netif_Msg_Hw
     (P : access Devices.e1000e.Base.e1000_adapter.item) return Boolean;




   procedure Dev_Info
     (Dev     : access Device;
      Message : in     String);     -- TODO


   procedure Pr_Info
     (Message : in String);      -- TODO



   function Dev_Trans_Start
     (Netdev : access net_device) return C.unsigned_long         -- TODO
   is
     (raise Program_Error with "TODO");





   type Net_Device_Flag is mod 2**32;

   IFF_UP          : constant Net_Device_Flag := 2**0;  -- sysfs
   IFF_BROADCAST   : constant Net_Device_Flag := 2**1;  -- volatile
   IFF_DEBUG       : constant Net_Device_Flag := 2**2;  -- sysfs
   IFF_LOOPBACK    : constant Net_Device_Flag := 2**3;  -- volatile
   IFF_POINTOPOINT : constant Net_Device_Flag := 2**4;  -- volatile
   IFF_NOTRAILERS  : constant Net_Device_Flag := 2**5;  -- sysfs
   IFF_RUNNING     : constant Net_Device_Flag := 2**6;  -- volatile
   IFF_NOARP       : constant Net_Device_Flag := 2**7;  -- sysfs
   IFF_PROMISC     : constant Net_Device_Flag := 2**8;  -- sysfs
   IFF_ALLMULTI    : constant Net_Device_Flag := 2**9;  -- sysfs
   IFF_MASTER      : constant Net_Device_Flag := 2**10; -- volatile
   IFF_SLAVE       : constant Net_Device_Flag := 2**11; -- volatile
   IFF_MULTICAST   : constant Net_Device_Flag := 2**12; -- sysfs
   IFF_PORTSEL     : constant Net_Device_Flag := 2**13; -- sysfs
   IFF_AUTOMEDIA   : constant Net_Device_Flag := 2**14; -- sysfs
   IFF_DYNAMIC     : constant Net_Device_Flag := 2**15; -- sysfs
   IFF_LOWER_UP    : constant Net_Device_Flag := 2**16; -- volatile
   IFF_DORMANT     : constant Net_Device_Flag := 2**17; -- volatile
   IFF_ECHO        : constant Net_Device_Flag := 2**18; -- volatile
   IFF_SUPP_NOFCS  : constant Net_Device_Flag := 2**14; -- 1 << 14
   IFF_UNICAST_FLT : constant Net_Device_Flag := 2**12; -- 1 << 12,


   use type C.unsigned;

   function Netif_Running
     (Dev : access constant Net_Device) return Boolean
   is
     ((Dev.Flags and C.unsigned (IFF_RUNNING)) /= 0);



   function NS_To_KTime
     (NS : Unsigned_64) return ktime_t
   is
     (raise Program_Error with "TODO");



   function Skb_Hwtstamps
     (Skb : access Sk_Buff) return access Skb_Shared_Hwtstamps
   is
     (raise Program_Error with "TODO");



   function CPU_To_Le16
     (From : in u16) return le16
   is
     (raise Program_Error with "TODO");


   function CPU_To_Le32
     (From : in u32) return le32
   is
     (raise Program_Error with "TODO");


   function CPU_To_Le64
     (From : in u64) return le64
   is
     (raise Program_Error with "TODO");


   procedure CPU_To_Be16s
     (From : in out u16)
  ;                                            -- TODO



   function Le16_to_CPU
     (From : in le16) return u16
   is
     (raise Program_Error with "TODO");




   function Le32_to_CPU
     (From : in le32) return u32
   is
     (raise Program_Error with "TODO");




   function Be16_to_CPU
     (From : in be16) return u16
   is
     (raise Program_Error with "TODO");



   procedure le16_to_cpus
     (x : access u16);      -- TODO



   function Eth_Type_Trans
     (Skb : access Sk_Buff;
      Dev : access Net_Device) return be16
   is
     (raise Program_Error with "TODO");




   procedure VLAN_Hwaccel_Put_Tag
     (Skb         : access SK_Buff;
      Vlan_Proto  : in     be16;
      Vlan_Tci    : in     Unsigned_16);                  -- TODO



   function HtoNS
     (From : in u16) return be16
   is
     (raise Program_Error with "TODO");



   type Gro_Result_t is (GRO_MERGED,
                         GRO_MERGED_FREE,
                         GRO_HELD,
                         GRO_NORMAL,
                         GRO_CONSUMED);


   function Napi_GRO_Receive
     (Napi : access NAPI_Struct;
      Skb  : access sk_buff) return GRO_Result_T
   is
     (raise Program_Error with "TODO");



   procedure Skb_Checksum_None_Assert                            -- TODO
     (Skb : access constant Sk_Buff);



   function unlikely (Condition : in Boolean) return Boolean
   is
     (raise Program_Error with "TODO");



   procedure schedule_Work (Work : access work_struct);     -- TODO



   procedure Skb_Trim (Skb : access Sk_Buff;
                       Len : in     C.unsigned);          -- TODO



   function Skb_Tailroom (Skb : access Sk_Buff) return Integer
   is
     (raise Program_Error with "TODO");



   ETH_HLEN : constant := 14;     -- Total octets in header.


   function PSKb_May_Pull
     (Skb : access SK_Buff;
      Len : in     u32) return Boolean
   is
     (raise Program_Error with "TODO");



   function Pskb_Trim
   (Buffer : access sk_buff;
    Length : in     Unsigned_32) return C.unsigned
   is
     (raise Program_Error with "TODO");




   function Netdev_Alloc_Skb_Ip_Align
     (Netdev  : access Net_Device;
      Length  : in     C.unsigned;
      gfp     : in     gfp_t) return access Sk_Buff
   is
     (raise Program_Error with "TODO");




   -- DMA
   --

   type Dma_Data_Direction is (DMA_BIDIRECTIONAL,
                               DMA_TO_DEVICE,
                               DMA_FROM_DEVICE,
                               DMA_NONE);

   function DMA_Map_Single_Attrs
     (Dev   : access Device;
      Data  : in     System.Address;
      Size  : in     C.size_t;
      Dir   : in     DMA_Data_Direction;
      Attrs : in     C.unsigned_long) return DMA_Addr_T
   is
     (raise Program_Error with "TODO");


   function DMA_Map_Single
     (Dev   : access Device;
      Data  : in     System.Address;
      Size  : in     C.size_t;
      Dir   : in     DMA_Data_Direction) return DMA_Addr_T
   is
     (raise Program_Error with "TODO");



   function DMA_Mapping_Error
     (Dev       : access Device;
      DMA_Addr  : in     DMA_Addr_T) return C.int
   is
     (raise Program_Error with "TODO");






   procedure dev_err (Dev     : access device;
                      Message : in     String);     -- TODO


   procedure prefetch (Data : in void_ptr);         -- TODO


   procedure wmb    ;         -- Write memory barrier.        -- TODO
   procedure rmb    ;         -- Read  memory barrier.        -- TODO
   procedure dma_rmb;         -- DMA read memory barrier.     -- TODO


   function Alloc_Page (gfp_mask : gfp_t) return access Page
   is
     (raise Program_Error with "TODO");



   procedure DMA_Sync_Single_For_Device
     (Dev  : access Device;
      Addr : in     DMA_Addr_T;
      Size : in     C.Size_T;
      Dir  : in     DMA_Data_Direction);     -- TODO



   function DMA_Map_Page_Attrs
     (Dev    : access Device;
      Page   : access linux.Page;
      Offset : in     C.Size_T;
      Size   : in     C.Size_T;
      Dir    : in     DMA_Data_Direction;
      Attrs  : in     C.Unsigned_Long) return DMA_Addr_T
   is
     (raise Program_Error with "TODO");



   function DMA_Map_Page
     (Dev    : access Device;
      Page   : access linux.Page;
      Offset : in     C.Size_T;
      Size   : in     C.Size_T;
      Dir    : in     DMA_Data_Direction) return DMA_Addr_T
   is
     (raise Program_Error with "TODO");




   procedure dma_unmap_single
     (Dev    : access Device;
      Dma    : in     dma_addr_t;
      Length : in     u32;
      Dir    : in     Dma_Data_Direction);                 -- TODO



   procedure DMA_Unmap_Page
     (Dev   : access Device;
      Addr  : in     DMA_Addr_T;
      Size  : in     C.Size_t;
      Dir   : in     DMA_Data_Direction);                  -- TODO


   procedure Dev_Kfree_Skb_Any (Skb : access Sk_Buff);     -- TODO

   procedure Dev_Kfree_Skb_Irq (Skb : access Sk_Buff);     -- TODO


   function Skb_Tail_Pointer (Skb : access Sk_Buff) return System.Address
   is
     (raise Program_Error with "TODO");



   procedure DMA_Sync_Single_For_CPU
     (Dev  : access Device;
      Addr : in     DMA_Addr_T;
      Size : in     C.Size_T;
      Dir  : in     DMA_Data_Direction);     -- TODO


   type pkt_hash_types is (PKT_HASH_TYPE_NONE,     -- Undefined type.
                           PKT_HASH_TYPE_L2,       -- Input: src_MAC, dest_MAC.
                           PKT_HASH_TYPE_L3,       -- Input: src_IP, dst_IP .
                           PKT_HASH_TYPE_L4);      -- Input: src_IP, dst_IP, src_port, dst_port.


   procedure skb_set_hash
     (skb       : access sk_buff;
      hash      : in     u32;
      hask_type : in     pkt_hash_types);     -- TODO



   function Napi_Alloc_Skb
     (Napi   : access Napi_Struct;
      Length : in     C.unsigned) return access Sk_Buff
   is
     (raise Program_Error with "TODO");



   procedure Skb_Copy_To_Linear_Data_Offset
   (Skb    : access Sk_Buff;
    Offset : in     Integer;
    From   : in     void_ptr;
    Len    : in     C.Unsigned);     -- TODO



   function Skb_Put
     (Skb    : access Sk_Buff;
      Len    : in     C.unsigned) return void_ptr
   is
     (raise Program_Error with "TODO");




   function Skb_Shinfo (SKB : access linux.sk_buff) return access skb_shared_Info
   is
     (raise Program_Error with "TODO");



   procedure Dev_Consume_Skb_Any
     (Skb : access Sk_Buff);     -- TODO



   procedure Skb_Fill_Page_Desc
     (Skb  : access Sk_Buff;
      I    : in     Integer;
      Page : access linux.Page;
      Off  : in     Integer;
      Size : in     Integer);     -- TODO


   function Container_of                 -- TODO: Use a generic ?
     (Ptr : in system.Address
      --  Container_Type;
      --  Member_Name
     ) return system.Address
   is
     (raise Program_Error with "TODO");



   function test_bit
     (Number : in Natural;
      Addr   : in system.Address) return Boolean
   is
     (raise Program_Error with "TODO");



   procedure set_bit
     (Number : in Natural;
      Addr   : in system.Address);     -- TODO



   procedure Netif_Stop_Queue
     (Dev : access Net_Device);     -- TODO



   procedure Skb_Tstamp_Tx
     (Orig_Skb    : access Sk_Buff;
      Hwtstamps   : access Skb_Shared_Hwtstamps);     -- TODO




   function time_after
     (Time_a,
      Time_b : C.unsigned_long) return Boolean
   is
     (raise Program_Error with "TODO");




   procedure Netdev_Completed_Queue
     (Dev   : access Net_Device;
      Pkts  : in     Unsigned_32;
      Bytes : in     Unsigned_32);      -- TODO



   procedure Netif_Wake_Queue
     (Dev   : access Net_Device);       -- TODO



   function Netif_Queue_Stopped
     (Dev   : access Net_Device) return Boolean
   is
     (raise Program_Error with "TODO");



   function Netif_Carrier_Ok
     (Dev : access Net_Device) return Boolean
   is
     (raise Program_Error with "TODO");



   procedure smp_mb;     -- TODO



   function Put_Page
     (Page : access linux.Page) return Integer
   is
     (raise Program_Error with "TODO")
       with
         Inline;



   procedure Dev_Kfree_Skb
     (Skb : access Sk_Buff);     -- TODO



   procedure memset
     (Address : in system.Address;
      Value   : in u8;
      Length  : in C.unsigned);         -- TODO




   function Netdev_Priv
     (Dev : access Net_Device) return void_ptr
   is
     (raise Program_Error with "TODO");



   function Mod_Timer
     (Timer   : access Timer_List;
      Expires : in     C.Unsigned_Long) return Integer
   is
     (raise Program_Error with "TODO");



   function NAPI_Schedule_Prep
     (N : access NAPI_Struct) return Boolean
   is
     (raise Program_Error with "TODO");



   function NAPI_Schedule
     (N : access NAPI_Struct) return Boolean
   is
        (raise Program_Error with "TODO");



   function vzalloc
     (size : in C.int) return void_ptr
   is
     (raise Program_Error with "TODO");



   --  procedure vFree (Bufffer : in out e1000_buffer.Pointer);     -- TODO

   procedure vfree (Addr : System.Address);      -- TODO



   function DMA_Alloc_Coherent
     (Dev         : access Device;
      Size        : in     C.size_t;
      DMA_Handle  : access dma_addr_t;
      GFP         : in     gfp_t) return void_ptr
   is
     (raise Program_Error with "TODO");



   function KCalloc
     (N     : in Integer;
      Size  : in Integer;
      Flags : in u32) return system.Address
   is
     (raise Program_Error with "TODO");


   procedure kfree (Object : in system.Address);     -- TODO




   function kzalloc (Size : in Integer;
                     GFP  : in Gfp_T) return system.Address
   is
     (raise Program_Error with "TODO");



   -- Basic memory allocation flags
   IO_Flag          : constant Gfp_T := 16#00000040#;  -- ___GFP_IO
   FS_Flag          : constant Gfp_T := 16#00000080#;  -- ___GFP_FS
   Direct_Reclaim   : constant Gfp_T := 16#00000400#;  -- ___GFP_DIRECT_RECLAIM
   Kswapd_Reclaim   : constant Gfp_T := 16#00000800#;  -- ___GFP_KSWAPD_RECLAIM

   -- Combined flags
   Reclaim_Flags    : constant Gfp_T := Direct_Reclaim or Kswapd_Reclaim;
   GFP_Kernel       : constant Gfp_T := Reclaim_Flags or IO_Flag or FS_Flag;



   function ALIGN (x : in C.unsigned;
                   a : in C.unsigned) return C.unsigned
   is
     (raise Program_Error with "TODO");



   procedure Netdev_Reset_Queue
     (Dev_Queue : access Net_Device);     -- TODO



   procedure DMA_Free_Coherent
     (Dev        : access Device;
      Size       : in     C.size_t;
      CPU_Addr   : in     System.Address;
      DMA_Handle : in     DMA_Addr_T);     -- TODO



   function NAPI_Complete_Done
     (N         : access NAPI_Struct;
      Work_Done : in     Integer) return Boolean
   is
     (raise Program_Error with "TODO");



   function For_Each_Set_Bit
     (Bit  :    out Unsigned_16;
      Addr : in     System.Address;
      Size : in     Unsigned_16) return Unsigned_16
   is
     (raise Program_Error with "TODO");




   subtype Netdev_Tx_T is Integer;

   Netdev_Tx_Min  : constant Netdev_Tx_T := Integer'First;  -- Make sure enum is signed.
   Netdev_Tx_OK   : constant Netdev_Tx_T := 16#00#;         -- Driver took care of packet.
   Netdev_Tx_BUSY : constant Netdev_Tx_T := 16#10#;         -- Driver tx path was busy.





   type Hwtstamp_Rx_Filters is
     (  -- Time stamp no incoming packet at all.
        Hwtstamp_Filter_None,

        -- Time stamp any incoming packet
        Hwtstamp_Filter_All,

        -- Return value: time stamp all packets requested plus some others
        Hwtstamp_Filter_Some,

        -- PTP v1, UDP, any kind of event packet
        Hwtstamp_Filter_PTP_V1_L4_Event,

        -- PTP v1, UDP, Sync packet
        Hwtstamp_Filter_PTP_V1_L4_Sync,

        -- PTP v1, UDP, Delay_req packet
        Hwtstamp_Filter_PTP_V1_L4_Delay_Req,

        -- PTP v2, UDP, any kind of event packet
        Hwtstamp_Filter_PTP_V2_L4_Event,

        -- PTP v2, UDP, Sync packet
        Hwtstamp_Filter_PTP_V2_L4_Sync,

        -- PTP v2, UDP, Delay_req packet
        Hwtstamp_Filter_PTP_V2_L4_Delay_Req,

        -- 802.AS1, Ethernet, any kind of event packet
        Hwtstamp_Filter_PTP_V2_L2_Event,

        -- 802.AS1, Ethernet, Sync packet
        Hwtstamp_Filter_PTP_V2_L2_Sync,

        -- 802.AS1, Ethernet, Delay_req packet
        Hwtstamp_Filter_PTP_V2_L2_Delay_Req,

        -- PTP v2/802.AS1, any layer, any kind of event packet
        Hwtstamp_Filter_PTP_V2_Event,

        -- PTP v2/802.AS1, any layer, Sync packet
        Hwtstamp_Filter_PTP_V2_Sync,

        -- PTP v2/802.AS1, any layer, Delay_req packet
        Hwtstamp_Filter_PTP_V2_Delay_Req,

        -- NTP, UDP, all versions and packet modes
        Hwtstamp_Filter_NTP_All);

   HWTSTAMP_FILTER_CNT : constant := Hwtstamp_Rx_Filters'Pos (Hwtstamp_Rx_Filters'Last) + 1;





   type ifreq is
      record
         ifr_data : void_ptr;
      end record;



   subtype PCI_Channel_State_t is C.unsigned;
   subtype pci_ers_result_t    is C.unsigned;


   subtype kernel_ulong_t  is C.unsigned_long;
   subtype phys_addr_t     is Unsigned_64;
   subtype resource_size_t is phys_addr_t;


   --- pci_device_id
   --
   type pci_device_id is
      record
      vendor        : Unsigned_32;        -- Vendor and device ID or PCI_ANY_ID.
      device        : Unsigned_32;        -- Vendor and device ID or PCI_ANY_ID.
      subvendor     : Unsigned_32;        -- Subsystem ID's or PCI_ANY_ID .
      subdevice     : Unsigned_32;        -- Subsystem ID's or PCI_ANY_ID.
      class         : Unsigned_32;        -- (class,subclass,prog-if) triplet.
      class_mask    : Unsigned_32;        -- (class,subclass,prog-if) triplet.
      driver_data   : kernel_ulong_t;     -- Data private to the driver.
      override_only : Unsigned_32;
   end record;




   procedure pci_disable_msi
     (dev : access pci_dev);     -- TODO

   procedure pci_disable_msix
     (dev : access pci_dev);     -- TODO

   function  pci_enable_msi
     (dev : access pci_dev) return C.int
   is
     (raise Program_Error with "TODO");


   function pci_enable_msix_range
     (dev     : access pci_dev;
      entries : access msix_entry;
      minvec  : in     Integer;
      maxvec  : in     Integer) return Integer
   is
     (raise Program_Error with "TODO");



   procedure snprintf
     (Target : in out C.char_array;
      Size   : in     Integer;
      Source : in     String);     -- TODO




   function request_irq
     (irq     : in C.unsigned;
      handler : in irq_handler_t;
      flags   : in C.unsigned_Long;
      name    : in C.Strings.chars_ptr;
      dev     : in void_ptr) return C.int
   is
     (raise Program_Error with "TODO");


   function free_irq
     (irq    : in C.unsigned;
      dev_id : in void_ptr) return void_ptr
   is
     (raise Program_Error with "TODO");



   procedure synchronize_irq
     (Irq : in C.Unsigned);      -- TODO



   PM_QOS_DEFAULT_VALUE : constant := -1;

   procedure cpu_latency_qos_update_request
     (req       : access pm_qos_request;
      new_value : in     s32);     -- TODO



   function Netdev_Mc_Empty
     (Netdev : access net_device) return Boolean
   is
     (raise Program_Error with "TODO");


   function netdev_mc_count
     (Netdev : access net_device) return Integer
   is
     (raise Program_Error with "TODO");


   function Netdev_Uc_Empty
     (Netdev : access net_device) return Boolean
   is
     (raise Program_Error with "TODO");


   function netdev_uc_count
     (Netdev : access net_device) return u32
   is
     (raise Program_Error with "TODO");



   function pm_runtime_suspended
     (dev : access device) return Boolean
   is
     (raise Program_Error with "TODO");



   procedure netdev_rss_key_fill
     (buffer : in void_ptr;
      len    : in C.size_t);        -- TODO


   procedure dev_warn
     (dev     : access Device;
      Message : in     String);     -- TODO


   procedure timecounter_init
     (tc           : access          timecounter;
      cc           : access constant cyclecounter;
      start_tstamp : in              u64);       -- TODO



   function ktime_get_real return ktime_t
   is
     (raise Program_Error with "TODO");



   function ktime_to_ns
     (kt : in ktime_t) return interfaces.Integer_64
   is
     (raise Program_Error with "TODO");



   procedure netif_carrier_off
     (dev : access net_device);     -- TODO



   procedure napi_synchronize
     (n : access napi_struct);      -- TODO



   function del_timer_sync
     (timer : access timer_list) return C.int
   is
     (raise Program_Error with "TODO");



   procedure spin_lock_init
     (lock : access spinlock_t);     -- TODO


   procedure spin_lock
     (lock : access spinlock_t);     -- TODO



   procedure spin_unlock
     (lock : access spinlock_t);     -- TODO




   function pci_channel_offline
     (pdev : access pci_dev) return C.int
   is
     (raise Program_Error with "TODO");



   procedure might_sleep;     -- TODO




   procedure ptp_read_system_prets
     (sts : access ptp_system_timestamp);     -- TODO


   procedure Ptp_Read_System_Postts
     (sts : access ptp_system_timestamp);     -- TODO



   function CYCLECOUNTER_MASK
     (bits : C.int) return Unsigned_64
   is
     (if bits < 64 then shift_left (Unsigned_64 (1),
                                    Natural (bits)) - Unsigned_64 (1)
                   else not Unsigned_64(0));


   --  function CYCLECOUNTER_MASK(bits : C.int) return Unsigned_64 is
   --  begin
   --     if bits < 64 then
   --        return shift_left(Unsigned_64(1), Natural(bits)) - Unsigned_64(1);
   --     else
   --        return not Unsigned_64(0);
   --     end if;
   --  end CYCLECOUNTER_MASK;


   procedure INIT_WORK (work : access work_struct;
                        func : access procedure (Work : access Work_Struct));     -- TODO



   function pci_write_config_word
     (dev   : access pci_dev;
      where : in     C.int;
      val   : in     Unsigned_16) return C.int
   is
     (raise Program_Error with "TODO");




   function pm_runtime_get_sync
     (dev : access device) return C.int
   is
     (raise Program_Error with "TODO");



   function pm_runtime_put
     (dev : access device) return C.int
   is
     (raise Program_Error with "TODO");



   procedure cpu_latency_qos_add_request
     (req   : access pm_qos_request;
      value : in     Devices.e1000e.Core.s32);     -- TODO



   procedure napi_enable
     (n : access napi_struct);      -- TODO



   procedure cpu_latency_qos_remove_request
     (req : access pm_qos_request);     -- TODO



   function pm_runtime_put_sync
     (dev : access device) return C.int
   is
     (raise Program_Error with "TODO");



   function pm_runtime_resume
     (dev: access device) return C.int
   is
     (raise Program_Error with "TODO");



   function pm_schedule_suspend
     (dev       : access device;
      for_delay : in     C.unsigned) return C.int
   is
     (raise Program_Error with "TODO");



   procedure WARN_ON
     (Condition : in Boolean);     -- TODO




   function netif_device_present
     (dev : access constant net_device) return Boolean
   is
     (raise Program_Error with "TODO");



   procedure netif_carrier_on
     (dev : access net_device);       -- TODO



   procedure netdev_info
     (dev     : access constant net_device;
      Message : in              String);       -- TODO




   procedure napi_disable
     (n : access napi_struct);     -- TODO




   function is_valid_ether_addr
     (addr : in u8_Pointer) return Boolean
   is
     (raise Program_Error with "TODO");



   procedure eth_hw_addr_set
     (dev  : access net_device;
      addr : in     u8_Pointer);     -- TODO



   procedure netdev_warn
     (dev    : access net_device;
      Message: in     String);     -- TODO



   procedure netdev_dbg
     (dev    : access net_device;
      Message: in     String);     -- TODO



   function round_jiffies
     (j : C.unsigned_long) return C.unsigned_long
   is
     (raise Program_Error with "TODO");



   function skb_is_gso
     (skb : access sk_buff) return Boolean
   is
     (raise Program_Error with "TODO");



   function skb_cow_head
     (skb      : access sk_buff;
      headroom : in     C.unsigned) return C.int
   is
     (raise Program_Error with "TODO");



   function skb_tcp_all_headers
     (skb : access constant sk_buff) return C.int
   is
     (raise Program_Error with "TODO");




   --------
   -- iphdr
   --

   subtype sum16 is u16;
   subtype wsum  is u32;


   -- Definition of the nested struct group "addrs".

   type iphdr_addrs is
      record
         a_be32 : be32;  -- __be32 saddr;
         saddr  : be32;
         daddr  : be32;
      end record;
   --
   -- Since the original code uses __struct_group without a tag,
   -- we translate it into a record type named iphdr_addrs.
   -- We preserve the field names saddr and daddr exactly.
   -- The extra label "__be32" is not part of the field names;
   -- hence, we omit it here and only include saddr and daddr.
   -- (The original intent was to declare two __be32 fields.)

   -- Definition of the iphdr structure exactly as in the original C code.
   --
   type iphdr is
      record
         -- The first byte is a bit field containing two 4-bit values.
         --
         ihl      : u8 range 0 .. 15;    -- 4-bit field: ihl
         version  : u8 range 0 .. 15;    -- 4-bit field: version
         tos      : u8;
         tot_len  : be16;
         id       : be16;
         frag_off : be16;
         ttl      : u8;
         protocol : u8;
         check    : sum16;
         addrs    : iphdr_addrs;
         --The options start here.
      end record;

   -- Representation clauses to pack the bit-fields and other fields.
   --
   for iphdr use
      record
         ihl         at 0  range 0  .. 3;
         version     at 0  range 4  .. 7;
         tos         at 1  range 0  .. 7;
         tot_len     at 2  range 0  .. 15;
         id          at 4  range 0  .. 15;
         frag_off    at 6  range 0  .. 15;
         ttl         at 8  range 0  .. 7;
         protocol    at 9  range 0  .. 7;
         check       at 10 range 0  .. 15;
         --  addrs       at 12 range 0  .. 63;
      end record;



   function ip_hdr
     (skb : access sk_buff) return access iphdr
   is
     (raise Program_Error with "TODO");




   function csum_tcpudp_magic (saddr : in be32;
                               daddr : in be32;
                               len   : in u32;
                               proto : in u8;
                               sum   : in wsum) return sum16
   is
     (raise Program_Error with "TODO");




   ---------
   -- tcphdr
   --

   type tcphdr is
      record
         source   : be16;                 -- __be16 source;
         dest     : be16;                 -- __be16 dest;
         seq      : be32;                 -- __be32 seq;
         ack_seq  : be32;                 -- __be32 ack_seq;
         res1     : u16 range 0 .. 15;    -- __u16  res1:4,
         doff     : u16 range 0 .. 15;    --         doff:4,
         fin      : Boolean;              --         fin:1,
         syn      : Boolean;              --         syn:1,
         rst      : Boolean;              --         rst:1,
         psh      : Boolean;              --         psh:1,
         ack      : Boolean;              --         ack:1,
         urg      : Boolean;              --         urg:1,
         ece      : Boolean;              --         ece:1,
         cwr      : Boolean;              --         cwr:1;
         window   : be16;                 -- __be16 window;
         check    : sum16;                -- __sum16  check;
         urg_ptr  : be16;                 -- __be16 urg_ptr;
      end record;

   pragma Convention (C, tcphdr);

   for tcphdr use
      record
         source    at 0  range 0  .. 15;
         dest      at 2  range 0  .. 15;
         seq       at 4  range 0  .. 31;
         ack_seq   at 8  range 0  .. 31;
         -- Bit-field group in a 16-bit word starting at offset 12:
         res1      at 12 range 0  .. 3;
         doff      at 12 range 4  .. 7;
         fin       at 12 range 8  .. 8;
         syn       at 12 range 9  .. 9;
         rst       at 12 range 10 .. 10;
         psh       at 12 range 11 .. 11;
         ack       at 12 range 12 .. 12;
         urg       at 12 range 13 .. 13;
         ece       at 12 range 14 .. 14;
         cwr       at 12 range 15 .. 15;
         window    at 14 range 0  .. 15;
         check     at 16 range 0  .. 15;
         urg_ptr   at 18 range 0  .. 15;
      end record;

   for tcphdr'Size use 20 * 8;  -- 20 bytes total




   function tcp_hdr
     (skb : access sk_buff) return access tcphdr
   is
     (raise Program_Error with "TODO");



   -- Standard well-defined IP protocols.
   --
   type IP_Protocol is (IPPROTO_IP,      -- Dummy protocol for TCP.
                        IPPROTO_ICMP,    -- Internet Control Message Protocol.
                        IPPROTO_IGMP,    -- Internet Group Management Protocol.
                        IPPROTO_IPIP,    -- IPIP tunnels (older KA9Q tunnels use 94).
                        IPPROTO_TCP,     -- Transmission Control Protocol.
                        IPPROTO_EGP,     -- Exterior Gateway Protocol.
                        IPPROTO_PUP,     -- PUP protocol.
                        IPPROTO_UDP,     -- User Datagram Protocol.
                        IPPROTO_IDP,     -- XNS IDP protocol.
                        IPPROTO_TP,      -- SO Transport Protocol Class 4.
                        IPPROTO_DCCP,    -- Datagram Congestion Control Protocol.
                        IPPROTO_IPV6,    -- IPv6-in-IPv4 tunnelling.
                        IPPROTO_RSVP,    -- RSVP Protocol.
                        IPPROTO_GRE,     -- Cisco GRE tunnels (rfc 1701,1702).
                        IPPROTO_ESP,     -- Encapsulation Security Payload protocol.
                        IPPROTO_AH,      -- Authentication Header protocol.
                        IPPROTO_MTP,     -- Multicast Transport Protocol.
                        IPPROTO_BEETPH,  -- IP option pseudo header for BEET.
                        IPPROTO_ENCAP,   -- Encapsulation Header.
                        IPPROTO_PIM,     -- Protocol Independent Multicast.
                        IPPROTO_COMP,    -- Compression Header Protocol.
                        IPPROTO_L2TP,    -- Layer 2 Tunnelling Protocol.
                        IPPROTO_SCTP,    -- Stream Control Transport Protocol.
                        IPPROTO_UDPLITE, -- UDP-Lite (RFC 3828).
                        IPPROTO_MPLS,    -- MPLS in IP (RFC 4023).
                        IPPROTO_ETHERNET, -- Ethernet-within-IPv6 Encapsulation.
                        IPPROTO_RAW,     -- Raw IP packets.
                        IPPROTO_SMC,     -- Shared Memory Communications.
                        IPPROTO_MPTCP,   -- Multipath TCP connection.
                        IPPROTO_MAX      -- Implicitly one greater than IPPROTO_MPTCP.
                       );

   for IP_Protocol use (0, 1, 2, 4, 6, 8, 12, 17, 22, 29, 33, 41, 46, 47, 50, 51, 92, 94, 98, 103, 108, 115, 132, 136, 137, 143, 255, 256, 262, 263);






   function skb_transport_offset
     (skb : access sk_buff) return C.int
   is
     (raise Program_Error with "TODO");



   function skb_is_gso_v6
     (skb : access sk_buff) return Boolean
   is
     (raise Program_Error with "TODO");



   procedure tcp_v6_gso_csum_prep
     (skb : access sk_buff);     -- TODO





   ----------
   -- ipv6hdr
   --

   type in6_Variants is (addr8, addr16, addr32);

   type in6_union (Variant : in6_Variants := in6_Variants'First) is
      record
         case Variant
         is
            when addr8  =>   u6_addr8  : u8_array   (0 .. 15);
            when addr16 =>   u6_addr16 : be16_array (0 ..  7);
            when addr32 =>   u6_addr32 : be32_array (0 ..  3);
         end case;
      end record;

   -- Definition of the in6_addr structure with the union member in6_union.
   type in6_addr is
      record
         in6_u : in6_union;
      end record;

   -- Translate the __struct_group from C:
   -- __struct_group(/* no tag */, addrs, /* no attrs */,
   --    struct   in6_addr saddr;
   --    struct   in6_addr daddr;
   -- );
   type ipv6_addrs is
      record
         saddr : in6_addr;
         daddr : in6_addr;
      end record;


   -- Translate the C structure:
   --
   -- struct ipv6hdr {
   -- __u8        priority:4,
   --             version:4;
   -- __u8        flow_lbl[3];
   --
   -- __be16      payload_len;
   -- __u8        nexthdr;
   -- __u8        hop_limit;
   --
   -- __struct_group(/* no tag */, addrs, /* no attrs */,
   --                   struct in6_addr   saddr;
   --                   struct in6_addr   daddr;
   --               );
   -- };
   type ipv6hdr is
      record
         -- __u8 priority:4, version:4;
         priority    : u8 range 0 .. 15;
         version     : u8 range 0 .. 15;
         -- __u8 flow_lbl[3];
         flow_lbl    : u8_array (0 .. 2);
         -- __be16 payload_len;
         payload_len : be16;
         -- __u8 nexthdr;
         nexthdr     : u8;
         -- __u8 hop_limit;
         hop_limit   : u8;
         -- __struct_group addrs with in6_addr saddr and daddr;
         addrs       : ipv6_addrs;
      end record;

   for ipv6hdr use
      record
         -- The first byte: priority occupies bits 0..3 and version bits 4..7
         priority     at 0 range 0 .. 3;
         version      at 0 range 4 .. 7;
         -- flow_lbl occupies the next 3 bytes (bytes 1 to 3, i.e. 24 bits)
         flow_lbl     at 8*1 range 0 .. 23;
         -- payload_len occupies 2 bytes starting at byte 4 (16 bits)
         payload_len  at 8*4 range 0 .. 15;
         -- nexthdr is at byte 6 (8 bits)
         nexthdr      at 8*6 range 0 .. 7;
         -- hop_limit is at byte 7 (8 bits)
         hop_limit    at 8*7 range 0 .. 7;
         -- addrs starts at byte 8
         --  addrs        at 8*8;
      end record;

   pragma Pack(ipv6hdr);
   pragma Convention(C, ipv6hdr);



   function ipv6_hdr
     (skb : access sk_buff) return access ipv6hdr
   is
     (raise Program_Error with "TODO");





   function net_ratelimit return C.int
   is
     (raise Program_Error with "TODO");



   function skb_checksum_start_offset
     (skb : access sk_buff) return C.int
   is
     (raise Program_Error with "TODO");



   function skb_headlen
     (skb : access sk_buff) return C.int
   is
     (raise Program_Error with "TODO");



   function skb_frag_size
     (frag : access constant skb_frag_t) return C.unsigned
   is
     (raise Program_Error with "TODO");



   function skb_frag_dma_map
     (dev    : access          device;
      frag   : access constant skb_frag_t;
      offset : in              C.size_t;
      size   : in              C.size_t;
      dir    : in              dma_data_direction) return dma_addr_t
   is
     (raise Program_Error with "TODO");



   function Skb_VLAN_Tag_Present
     (Skb : access SK_Buff) return Boolean
   is
     (raise Program_Error with "TODO");



   function Skb_VLAN_Tag_Get
     (Skb : access SK_Buff) return u16
   is
     (raise Program_Error with "TODO");




   type ethhdr is
      record
         h_dest   : u8_array (0 .. Devices.e1000e.Hardware.ETH_ALEN - 1);     -- Destination ether addr.
         h_source : u8_array (0 .. Devices.e1000e.Hardware.ETH_ALEN - 1);     -- Source ether addr.
         h_proto  : be16;                                      -- Packet type ID field.
      end record;

   --  pragma Pack (ethhdr);



   type udphdr is
      record
         source : be16;
         dest   : be16;
         len    : be16;
         check  : sum16;
      end record;



   function ntohs
     (netshort : in u16) return u16
   is
     (raise Program_Error with "TODO");





   procedure netif_start_queue
     (dev : access net_device);     -- TODO




   function vlan_get_protocol
     (skb : access sk_buff) return be16
   is
     (raise Program_Error with "TODO");



   function skb_put_padto
     (skb : access sk_buff;
      len : in     C.unsigned) return C.int
   is
     (raise Program_Error with "TODO");




   function pskb_pull_tail
     (skb       : access sk_buff;
      the_delta : in     C.int) return void_ptr
   is
     (raise Program_Error with "TODO");



   function DIV_ROUND_UP
     (n : in C.int;
      d : in C.int) return C.int
   is
     (raise Program_Error with "TODO");





   type SKBTX_Flags is (SKBTX_HW_TSTAMP,
                        SKBTX_SW_TSTAMP,
                        SKBTX_IN_PROGRESS,
                        SKBTX_HW_TSTAMP_USE_CYCLES,
                        SKBTX_WIFI_STATUS,
                        SKBTX_HW_TSTAMP_NETDEV,
                        SKBTX_SCHED_TSTAMP);

   for SKBTX_Flags use (SKBTX_HW_TSTAMP            => 2 ** 0,
                        SKBTX_SW_TSTAMP            => 2 ** 1,
                        SKBTX_IN_PROGRESS          => 2 ** 2,
                        SKBTX_HW_TSTAMP_USE_CYCLES => 2 ** 3,
                        SKBTX_WIFI_STATUS          => 2 ** 4,
                        SKBTX_HW_TSTAMP_NETDEV     => 2 ** 5,
                        SKBTX_SCHED_TSTAMP         => 2 ** 6);



   function skb_get
     (skb : access sk_buff) return access sk_buff
   is
     (raise Program_Error with "TODO");



   procedure skb_tx_timestamp
     (skb : access sk_buff);     -- TODO



   procedure netdev_sent_queue
     (dev   : access net_device;
      bytes : in     C.unsigned);     -- TODO




   function netdev_xmit_more return Boolean
   is
     (raise Program_Error with "TODO");




   type netdev_queue is null record;


   function netif_xmit_stopped
     (dev_queue : not null access constant netdev_queue) return Boolean
   is
     (raise Program_Error with "TODO");




   function netdev_get_tx_queue
     (dev   : access net_device;
      index : in     C.unsigned) return access netdev_queue
   is
     (raise Program_Error with "TODO");


   procedure rtnl_lock  ;     -- TODO
   procedure rtnl_unlock;     -- TODO



   procedure WRITE_ONCE
     (x   : in out C.unsigned;
      val : in     C.unsigned);     -- TODO





   type mii_ioctl_data is
      record
         phy_id  : u16;
         reg_num : u16;
         val_in  : u16;
         val_out : u16;
      end record;



   function if_mii
     (rq : access ifreq) return access mii_ioctl_data
   is
     (raise Program_Error with "TODO");





   function copy_from_user
     (to   : in void_ptr;
      from : in void_ptr;
      n    : C.unsigned_long) return C.unsigned_long
   is
     (raise Program_Error with "TODO");



   function copy_to_user
     (to   : in void_ptr;
      from : in void_ptr;
      n    : in C.unsigned_long) return C.unsigned_long
   is
     (raise Program_Error with "TODO");



   function pci_get_drvdata
     (pdev : access pci_dev) return void_ptr
   is
     (raise Program_Error with "TODO");


   function dev_get_drvdata
     (dev : access device) return void_ptr
   is
     (raise Program_Error with "TODO");



   procedure netif_device_detach
     (dev : access net_device);     -- TODO



   function device_may_wakeup
     (dev : access device) return Boolean
   is
     (raise Program_Error with "TODO");



   procedure pci_clear_master
     (dev : access pci_dev);     -- TODO



   function pcie_capability_write_word
     (dev : access pci_dev;
      pos : in     C.int;
      val : in     Unsigned_16) return C.int
   is
     (raise Program_Error with "TODO");




   function pci_save_state
     (dev : access pci_dev) return C.int
   is
     (raise Program_Error with "TODO");



   function PCI_Prepare_To_Sleep
     (dev : access pci_dev) return C.int
   is
     (raise Program_Error with "TODO");



   function pci_disable_link_state_locked
     (pdev  : access pci_dev;
      state : in     C.int) return C.int
   is
     (raise Program_Error with "TODO");


   function pci_disable_link_state
     (pdev  : access pci_dev;
      state : in     C.int) return C.int
   is
     (raise Program_Error with "TODO");



   function pcie_capability_clear_word
     (dev   : access pci_dev;
      pos   : in     C.int;
      clear : in     u16) return C.int
   is
     (raise Program_Error with "TODO");



   procedure netif_device_attach
     (dev : access net_device);     -- TODO



   procedure pci_set_master
     (dev : access pci_dev);     -- TODO



   function pm_suspend_via_firmware return Boolean
   is
     (raise Program_Error with "TODO");



   --  #define to_pci_dev(n) container_of(n, struct pci_dev, dev)

   function to_pci_dev
     (n : access Device) return access pci_dev
   is
     (raise Program_Error with "TODO");



   function disable_hardirq
     (irq : in C.int) return Boolean
   is
     (raise Program_Error with "TODO");



   procedure enable_irq
     (irq : in C.unsigned);     -- TODO



   procedure pci_disable_device
     (dev : access pci_dev);     -- TODO



   function pci_enable_device_mem
     (dev : access pci_dev) return C.int
   is
     (raise Program_Error with "TODO");



   procedure pci_restore_state
     (dev : access pci_dev);     -- TODO




   type pci_power_t is new C.int;

   PCI_D0          : constant pci_power_t :=  0;
   PCI_D1          : constant pci_power_t :=  1;
   PCI_D2          : constant pci_power_t :=  2;
   PCI_D3hot       : constant pci_power_t :=  3;
   PCI_D3cold      : constant pci_power_t :=  4;
   PCI_UNKNOWN     : constant pci_power_t :=  5;
   PCI_POWER_ERROR : constant pci_power_t := -1;



   function pci_enable_wake
     (dev   : access pci_dev;
      state : in     pci_power_t;
      enable: in     Boolean) return C.int
   is
     (raise Program_Error with "TODO");




   pci_channel_io_normal       : constant pci_channel_state_t := 1;     -- I/O channel is in normal state.
   pci_channel_io_frozen       : constant pci_channel_state_t := 2;     -- I/O to channel is blocked.
   pci_channel_io_perm_failure : constant pci_channel_state_t := 3;     -- PCI card is dead.





   PCI_ERS_RESULT_NONE          : constant pci_ers_result_t := 1;     -- No result/none/not supported in device driver.
   PCI_ERS_RESULT_CAN_RECOVER   : constant pci_ers_result_t := 2;     -- Device driver can recover without slot reset.
   PCI_ERS_RESULT_NEED_RESET    : constant pci_ers_result_t := 3;     -- Device driver wants slot to be reset.
   PCI_ERS_RESULT_DISCONNECT    : constant pci_ers_result_t := 4;     -- Device has completely failed, is unrecoverable.
   PCI_ERS_RESULT_RECOVERED     : constant pci_ers_result_t := 5;     -- Device driver is fully recovered and operational.
   PCI_ERS_RESULT_NO_AER_DRIVER : constant pci_ers_result_t := 6;     -- No AER capabilities registered for the driver.




   function dma_set_mask_and_coherent
     (dev  : access device;
      mask : in     u64) return C.int
   is
     (raise Program_Error with "TODO");



   function DMA_BIT_MASK (n : in Integer) return u64
   is
     (raise Program_Error with "TODO");



   function pci_select_bars
     (dev   : access pci_dev;
      flags : in     C.unsigned_long) return C.int
   is
     (raise Program_Error with "TODO");



   function pci_request_selected_regions_exclusive
     (dev  : access pci_dev;
      arg  : in     C.int;
      name : in     String) return C.int
   is
     (raise Program_Error with "TODO");



   function alloc_etherdev
     (sizeof_priv : in Integer) return access net_device
   is
     (raise Program_Error with "TODO");



   procedure SET_NETDEV_DEV
     (net  : access net_device;
      pdev : access device);     -- TODO



   procedure pci_set_drvdata
     (pdev : access pci_dev;
      data : in     void_ptr);     -- TODO




   function netif_msg_init
     (Debug_Value             : in C.int;
      Default_Msg_Enable_Bits : in C.int) return Interfaces.Unsigned_32
   is
     (raise Program_Error with "TODO");



   function pci_resource_start
     (dev : access PCI_Dev;
      bar : in     C.int) return resource_size_t
   is
     (raise Program_Error with "TODO");



   function pci_resource_len
     (dev : access PCI_Dev;
      bar : in     C.int) return resource_size_t
   is
     (raise Program_Error with "TODO");




   function ioremap
     (offset : in phys_addr_t;
      size   : in C.size_t) return void_ptr
   is
     (raise Program_Error with "TODO");



   function pci_resource_flags
     (Dev : access PCI_Dev;
      Bar : in     C.int) return C.unsigned
   is
     (raise Program_Error with "TODO");






   type poll_type is access function (napi  : access napi_struct;
                                      count : in     C.int) return C.int;

   procedure netif_napi_add(dev  : access net_device;
                            napi : access napi_struct;
                            poll : in     poll_type);     -- TODO



   procedure timer_setup
     (timer    : access timer_list;
      callback : access procedure (T : access timer_list);
      flags    : in C.int);     -- TODO




   function device_wakeup_enable
     (dev : access device) return C.int
   is
     (raise Program_Error with "TODO");





   function register_netdev
     (dev : access net_device) return C.int
   is
     (raise Program_Error with "TODO");



   procedure dev_pm_set_driver_flags
     (dev   : access device;
      flags : in     u32);



   function pci_dev_run_wake
     (dev : access pci_dev) return Boolean
   is
     (raise Program_Error with "TODO");



   procedure pm_runtime_put_noidle
     (dev: access device);     -- TODO




   procedure iounmap
     (addr : in void_ptr);     -- TODO



   procedure free_netdev
     (dev : access net_device);     -- TODO


   procedure pci_release_mem_regions
     (pdev : access pci_dev);     -- TODO



   function cancel_work_sync
     (work : access work_struct) return Boolean
    is
     (raise Program_Error with "TODO");




   procedure unregister_netdev
     (dev : access net_device);     -- TODO



   procedure pm_runtime_get_noresume
     (dev : access device);     -- TODO




   type pci_driver is null record;


   function pci_register_driver
     (drv : access pci_driver) return C.int
    is
     (raise Program_Error with "TODO");



   function pci_unregister_driver
     (drv : access pci_driver) return C.int
    is
     (raise Program_Error with "TODO");



   function eth_validate_addr
     (dev : access net_device) return C.int
    is
     (raise Program_Error with "TODO");



   function passthru_features_check
     (skb      : access sk_buff;
      dev      : access net_device;
      features : in     netdev_features_t) return netdev_features_t
    is
     (raise Program_Error with "TODO");




   function adjust_by_scaled_ppm
     (base       : in u64;
      scaled_ppm : in C.long) return u64
    is
     (raise Program_Error with "TODO");



   procedure timecounter_adjtime
     (tc        : access timecounter;
      the_delta : in     Interfaces.Integer_64);     -- TODO




   type clocksource_ids is (CSID_GENERIC,
                            CSID_ARM_ARCH_COUNTER,
                            CSID_X86_TSC_EARLY,
                            CSID_X86_TSC,
                            CSID_X86_KVM_CLK,
                            CSID_X86_ART,
                            CSID_MAX);


   type system_counterval_t is
      record
         cycles    : u64;
         cs_id     : clocksource_ids;
         use_nsecs : Boolean;
      end record;




   type time_fn_ptr is access function (device_time      : access ktime_t;
                                        system_counterval: access system_counterval_t;
                                        ctx              : in     void_ptr) return C.int;

   type system_time_snapshot is null record;

   function get_device_system_crosststamp
     (get_time_fn : in     time_fn_ptr;
      ctx         : in     void_ptr;
      history     : access system_time_snapshot;
      xtstamp     : access system_device_crosststamp) return C.int
   is
     (raise Program_Error with "TODO");



   subtype time64_t is Integer_64;

   type timespec64 is
      record
         tv_sec  : time64_t;      -- Seconds.
         tv_nsec : C.long;        -- Nanoseconds.
      end record;



   function ns_to_timespec64
     (nsec : in Integer_64) return timespec64
   is
     (raise Program_Error with "TODO");



   function timespec64_to_ns
     (ts : access constant timespec64) return Integer_64
   is
     (raise Program_Error with "TODO");



   type PTP_Clock_Request is null record;





   function timecounter_read
     (tc : access timecounter) return u64
   is
     (raise Program_Error with "TODO");





   function schedule_delayed_work
     (dwork     : access delayed_work;
      the_delay : C.unsigned_long) return Boolean
   is
     (raise Program_Error with "TODO");





















   ------------------
   --- net_device_ops
   --


   -- For representing "const unsigned char *" in fdb functions.
   type unsigned_char is mod 2**8;


   --------------- Function Pointer Type Declarations ---------------
   type ndo_init_func is access function(dev: access net_device) return C.int;
   type ndo_uninit_proc is access procedure(dev: access net_device);
   type ndo_open_func is access function(dev: access net_device) return C.int;
   type ndo_stop_func is access function(dev: access net_device) return C.int;
   type ndo_start_xmit_func is access function(skb: access sk_buff; dev: access net_device) return netdev_tx_t;
   type ndo_features_check_func is access function(skb: access sk_buff; dev: access net_device; features: netdev_features_t) return netdev_features_t;
   type ndo_select_queue_func is access function(dev: access net_device; skb: access sk_buff; sb_dev: access net_device) return u16;
   type ndo_change_rx_flags_proc is access procedure(dev: access net_device; flags: C.int);
   type ndo_set_rx_mode_proc is access procedure(dev: access net_device);
   type ndo_set_mac_address_func is access function(dev: access net_device; addr: void_ptr) return C.int;
   type ndo_validate_addr_func is access function(dev: access net_device) return C.int;
   type ndo_do_ioctl_func is access function(dev: access net_device; ifr: access ifreq; cmd: C.int) return C.int;
   type ndo_eth_ioctl_func is access function(dev: access net_device; ifr: access ifreq; cmd: C.int) return C.int;
   type ndo_siocbond_func is access function(dev: access net_device; ifr: access ifreq; cmd: C.int) return C.int;
   --  type ndo_siocwandev_func is access function(dev: access net_device; ifs: access if_settings) return C.int;
   type ndo_siocdevprivate_func is access function(dev: access net_device; ifr: access ifreq; data: void_ptr; cmd: C.int) return C.int;
   --  type ndo_set_config_func is access function(dev: access net_device; map: access ifmap) return C.int;
   type ndo_change_mtu_func is access function(dev: access net_device; new_mtu: C.int) return C.int;
   --  type ndo_neigh_setup_func is access function(dev: access net_device; np: access neigh_parms) return C.int;
   type ndo_tx_timeout_proc is access procedure(dev: access net_device; txqueue: C.unsigned);
   type ndo_get_stats64_proc is access procedure(dev: access net_device; storage: access rtnl_link_stats64);
   type ndo_has_offload_stats_func is access function(dev: access net_device; attr_id: C.int) return Boolean;
   type ndo_get_offload_stats_func is access function(attr_id: C.int; dev: access net_device; attr_data: void_ptr) return C.int;
   type ndo_get_stats_func is access function(dev: access net_device) return access net_device_stats;
   type ndo_vlan_rx_add_vid_func is access function(dev: access net_device; proto: u16; vid: u16) return C.int;
   type ndo_vlan_rx_kill_vid_func is access function(dev: access net_device; proto: u16; vid: u16) return C.int;

   -- #ifdef CONFIG_NET_POLL_CONTROLLER
   type ndo_poll_controller_proc is access procedure(dev: access net_device);
   --  type ndo_netpoll_setup_func is access function(dev: access net_device; info: access netpoll_info) return C.int;
   type ndo_netpoll_cleanup_proc is access procedure(dev: access net_device);
   -- #endif

   type ndo_set_vf_mac_func is access function(dev: access net_device; queue: C.int; mac: access u8) return C.int;
   type ndo_set_vf_vlan_func is access function(dev: access net_device; queue: C.int; vlan: u16; qos: u8; proto: u16) return C.int;
   type ndo_set_vf_rate_func is access function(dev: access net_device; vf: C.int; min_tx_rate: C.int; max_tx_rate: C.int) return C.int;
   type ndo_set_vf_spoofchk_func is access function(dev: access net_device; vf: C.int; setting: Boolean) return C.int;
   type ndo_set_vf_trust_func is access function(dev: access net_device; vf: C.int; setting: Boolean) return C.int;
   --  type ndo_get_vf_config_func is access function(dev: access net_device; vf: C.int; ivf: access ifla_vf_info) return C.int;
   type ndo_set_vf_link_state_func is access function(dev: access net_device; vf: C.int; link_state: C.int) return C.int;
   --  type ndo_get_vf_stats_func is access function(dev: access net_device; vf: C.int; vf_stats: access ifla_vf_stats) return C.int;
   -- For function pointer taking an array of pointers: using an unconstrained array of access nlattr.
   --  type nlattr_Ptr is access nlattr;
   --  type nlattr_array is array (Positive range <>) of nlattr_Ptr;
   --  type ndo_set_vf_port_func is access function(dev: access net_device; vf: C.int; port: nlattr_array) return C.int;
   type ndo_get_vf_port_func is access function(dev: access net_device; vf: C.int; skb: access sk_buff) return C.int;
   --  type ndo_get_vf_guid_func is access function(dev: access net_device; vf: C.int; node_guid: access ifla_vf_guid; port_guid: access ifla_vf_guid) return C.int;
   type ndo_set_vf_guid_func is access function(dev: access net_device; vf: C.int; guid: u64; guid_type: C.int) return C.int;
   type ndo_set_vf_rss_query_en_func is access function(dev: access net_device; vf: C.int; setting: Boolean) return C.int;
   type tc_setup_type is (TC_SETUP_TYPE_UNKNOWN);
   type ndo_setup_tc_func is access function(dev: access net_device; type_val: tc_setup_type; type_data: void_ptr) return C.int;
   -- #if IS_ENABLED(CONFIG_FCOE)
   type ndo_fcoe_enable_func is access function(dev: access net_device) return C.int;
   type ndo_fcoe_disable_func is access function(dev: access net_device) return C.int;
   --  type ndo_fcoe_ddp_setup_func is access function(dev: access net_device; xid: u16; sgl: access scatterlist; sgc: C.int) return C.int;
   type ndo_fcoe_ddp_done_func is access function(dev: access net_device; xid: u16) return C.int;
   --  type ndo_fcoe_ddp_target_func is access function(dev: access net_device; xid: u16; sgl: access scatterlist; sgc: C.int) return C.int;
   --  type ndo_fcoe_get_hbainfo_func is access function(dev: access net_device; hbainfo: access netdev_fcoe_hbainfo) return C.int;
   -- #endif
   -- #if IS_ENABLED(CONFIG_LIBFCOE)
   -- Macros:
   -- #define NETDEV_FCOE_WWNN 0
   -- #define NETDEV_FCOE_WWPN 1
   type ndo_fcoe_get_wwn_func is access function(dev: access net_device; wwn: access u64; type_val: C.int) return C.int;
   -- #endif
   -- #ifdef CONFIG_RFS_ACCEL
   type ndo_rx_flow_steer_func is access function(dev: access net_device; skb: access sk_buff; rxq_index: u16; flow_id: u32) return C.int;
   -- #endif
   --  type ndo_add_slave_func is access function(dev: access net_device; slave_dev: access net_device; extack: access netlink_ext_ack) return C.int;
   type ndo_del_slave_func is access function(dev: access net_device; slave_dev: access net_device) return C.int;
   type ndo_get_xmit_slave_func is access function(dev: access net_device; skb: access sk_buff; all_slaves: Boolean) return access net_device;
   --  type ndo_sk_get_lower_dev_func is access function(dev: access net_device; sk: access sock) return access net_device;
   type ndo_fix_features_func is access function(dev: access net_device; features: netdev_features_t) return netdev_features_t;
   type ndo_set_features_func is access function(dev: access net_device; features: netdev_features_t) return C.int;
   --  type ndo_neigh_construct_func is access function(dev: access net_device; n: access neighbour) return C.int;
   --  type ndo_neigh_destroy_proc is access procedure(dev: access net_device; n: access neighbour);
   --  type ndo_fdb_add_func is access function(ndm: access ndmsg; tb: access nlattr_array; dev: access net_device; addr: access unsigned_char; vid: u16; flags: u16; extack: access netlink_ext_ack) return C.int;
   --  type ndo_fdb_del_func is access function(ndm: access ndmsg; tb: access nlattr_array; dev: access net_device; addr: access unsigned_char; vid: u16; extack: access netlink_ext_ack) return C.int;
   --  type ndo_fdb_del_bulk_func is access function(nlh: access nlmsghdr; dev: access net_device; extack: access netlink_ext_ack) return C.int;
   --  type ndo_fdb_dump_func is access function(skb: access sk_buff; cb: access netlink_callback; dev: access net_device; filter_dev: access net_device; idx: access C.int) return C.int;
   --  type ndo_fdb_get_func is access function(skb: access sk_buff; tb: access nlattr_array; dev: access net_device; addr: access unsigned_char; vid: u16; portid: u32; seq: u32; extack: access netlink_ext_ack) return C.int;
   --  type ndo_mdb_add_func is access function(dev: access net_device; tb: access nlattr_array; nlmsg_flags: u16; extack: access netlink_ext_ack) return C.int;
   --  type ndo_mdb_del_func is access function(dev: access net_device; tb: access nlattr_array; extack: access netlink_ext_ack) return C.int;
   --  type ndo_mdb_del_bulk_func is access function(dev: access net_device; tb: access nlattr_array; extack: access netlink_ext_ack) return C.int;
   --  type ndo_mdb_dump_func is access function(dev: access net_device; skb: access sk_buff; cb: access netlink_callback) return C.int;
   --  type ndo_mdb_get_func is access function(dev: access net_device; tb: access nlattr_array; portid: u32; seq: u32; extack: access netlink_ext_ack) return C.int;
   --  type ndo_bridge_setlink_func is access function(dev: access net_device; nlh: access nlmsghdr; flags: u16; extack: access netlink_ext_ack) return C.int;
   type ndo_bridge_getlink_func is access function(skb: access sk_buff; pid: u32; seq: u32; dev: access net_device; filter_mask: u32; nlflags: C.int) return C.int;
   --  type ndo_bridge_dellink_func is access function(dev: access net_device; nlh: access nlmsghdr; flags: u16) return C.int;
   type ndo_change_carrier_func is access function(dev: access net_device; new_carrier: Boolean) return C.int;
   --  type ndo_get_phys_port_id_func is access function(dev: access net_device; ppid: access netdev_phys_item_id) return C.int;
   --  type ndo_get_port_parent_id_func is access function(dev: access net_device; ppid: access netdev_phys_item_id) return C.int;
   type char_array is array (Positive range <>) of Character;
   --  type ndo_get_phys_port_name_func is access function(dev: access net_device; name: access char_array; len: size_t) return C.int;
   type ndo_dfwd_add_station_func is access function(pdev: access net_device; dev: access net_device) return void_ptr;
   type ndo_dfwd_del_station_proc is access procedure(pdev: access net_device; priv: void_ptr);
   type ndo_set_tx_maxrate_func is access function(dev: access net_device; queue_index: C.int; maxrate: u32) return C.int;
   type ndo_get_iflink_func is access function(dev: access net_device) return C.int;
   type ndo_fill_metadata_dst_func is access function(dev: access net_device; skb: access sk_buff) return C.int;
   type ndo_set_rx_headroom_proc is access procedure(dev: access net_device; needed_headroom: C.int);
   --  type ndo_bpf_func is access function(dev: access net_device; bpf: access netdev_bpf) return C.int;
   --  type xdp_frame_Ptr is access xdp_frame;
   --  type xdp_frame_Array is array (Positive range <>) of xdp_frame_Ptr;
   --  type ndo_xdp_xmit_func is access function(dev: access net_device; n: C.int; xdp: access xdp_frame_Array; flags: u32) return C.int;
   --  type ndo_xdp_get_xmit_slave_func is access function(dev: access net_device; xdp: access xdp_buff) return access net_device;
   type ndo_xsk_wakeup_func is access function(dev: access net_device; queue_id: u32; flags: u32) return C.int;
   --  type ndo_tunnel_ctl_func is access function(dev: access net_device; p: access ip_tunnel_parm_kern; cmd: C.int) return C.int;
   type ndo_get_peer_dev_func is access function(dev: access net_device) return access net_device;
   --  type ndo_fill_forward_path_func is access function(ctx: access net_device_path_ctx; path: access net_device_path) return C.int;
   type ndo_get_tstamp_func is access function(dev: access net_device; hwtstamps: access skb_shared_hwtstamps; cycles: Boolean) return ktime_t;
   --  type ndo_hwtstamp_get_func is access function(dev: access net_device; kernel_config: access kernel_hwtstamp_config) return C.int;
   --  type ndo_hwtstamp_set_func is access function(dev: access net_device; kernel_config: access kernel_hwtstamp_config; extack: access netlink_ext_ack) return C.int;

   type net_device_ops is
      record
         ndo_init                    : ndo_init_func;
         ndo_uninit                  : ndo_uninit_proc;
         ndo_open                    : ndo_open_func;
         ndo_stop                    : ndo_stop_func;
         ndo_start_xmit              : ndo_start_xmit_func;
         ndo_features_check          : ndo_features_check_func;
         ndo_select_queue            : ndo_select_queue_func;
         ndo_change_rx_flags         : ndo_change_rx_flags_proc;
         ndo_set_rx_mode             : ndo_set_rx_mode_proc;
         ndo_set_mac_address         : ndo_set_mac_address_func;
         ndo_validate_addr           : ndo_validate_addr_func;
         ndo_do_ioctl                : ndo_do_ioctl_func;
         ndo_eth_ioctl               : ndo_eth_ioctl_func;
         ndo_siocbond                : ndo_siocbond_func;
         --  ndo_siocwandev              : ndo_siocwandev_func;
         ndo_siocdevprivate          : ndo_siocdevprivate_func;
         --  ndo_set_config              : ndo_set_config_func;
         ndo_change_mtu              : ndo_change_mtu_func;
         --  ndo_neigh_setup             : ndo_neigh_setup_func;
         ndo_tx_timeout              : ndo_tx_timeout_proc;
         ndo_get_stats64             : ndo_get_stats64_proc;
         ndo_has_offload_stats       : ndo_has_offload_stats_func;
         ndo_get_offload_stats       : ndo_get_offload_stats_func;
         ndo_get_stats               : ndo_get_stats_func;
         ndo_vlan_rx_add_vid         : ndo_vlan_rx_add_vid_func;
         ndo_vlan_rx_kill_vid        : ndo_vlan_rx_kill_vid_func;
         -- #ifdef CONFIG_NET_POLL_CONTROLLER
         ndo_poll_controller         : ndo_poll_controller_proc;
         --  ndo_netpoll_setup           : ndo_netpoll_setup_func;
         ndo_netpoll_cleanup         : ndo_netpoll_cleanup_proc;
         -- #endif
         ndo_set_vf_mac              : ndo_set_vf_mac_func;
         ndo_set_vf_vlan             : ndo_set_vf_vlan_func;
         ndo_set_vf_rate             : ndo_set_vf_rate_func;
         ndo_set_vf_spoofchk         : ndo_set_vf_spoofchk_func;
         ndo_set_vf_trust            : ndo_set_vf_trust_func;
         --  ndo_get_vf_config           : ndo_get_vf_config_func;
         ndo_set_vf_link_state       : ndo_set_vf_link_state_func;
         --  ndo_get_vf_stats            : ndo_get_vf_stats_func;
         --  ndo_set_vf_port             : ndo_set_vf_port_func;
         ndo_get_vf_port             : ndo_get_vf_port_func;
         --  ndo_get_vf_guid             : ndo_get_vf_guid_func;
         ndo_set_vf_guid             : ndo_set_vf_guid_func;
         ndo_set_vf_rss_query_en     : ndo_set_vf_rss_query_en_func;
         ndo_setup_tc                : ndo_setup_tc_func;
         -- #if IS_ENABLED(CONFIG_FCOE)
         ndo_fcoe_enable             : ndo_fcoe_enable_func;
         ndo_fcoe_disable            : ndo_fcoe_disable_func;
         --  ndo_fcoe_ddp_setup          : ndo_fcoe_ddp_setup_func;
         ndo_fcoe_ddp_done           : ndo_fcoe_ddp_done_func;
         --  ndo_fcoe_ddp_target         : ndo_fcoe_ddp_target_func;
         --  ndo_fcoe_get_hbainfo        : ndo_fcoe_get_hbainfo_func;
         -- #endif
         -- #if IS_ENABLED(CONFIG_LIBFCOE)
         ndo_fcoe_get_wwn            : ndo_fcoe_get_wwn_func;
         -- #endif
         -- #ifdef CONFIG_RFS_ACCEL
         ndo_rx_flow_steer           : ndo_rx_flow_steer_func;
         -- #endif
         --  ndo_add_slave               : ndo_add_slave_func;
         ndo_del_slave               : ndo_del_slave_func;
         ndo_get_xmit_slave          : ndo_get_xmit_slave_func;
         --  ndo_sk_get_lower_dev        : ndo_sk_get_lower_dev_func;
         ndo_fix_features            : ndo_fix_features_func;
         ndo_set_features            : ndo_set_features_func;
         --  ndo_neigh_construct         : ndo_neigh_construct_func;
         --  ndo_neigh_destroy           : ndo_neigh_destroy_proc;
         --  ndo_fdb_add                 : ndo_fdb_add_func;
         --  ndo_fdb_del                 : ndo_fdb_del_func;
         --  ndo_fdb_del_bulk            : ndo_fdb_del_bulk_func;
         --  ndo_fdb_dump                : ndo_fdb_dump_func;
         --  ndo_fdb_get                 : ndo_fdb_get_func;
         --  ndo_mdb_add                 : ndo_mdb_add_func;
         --  ndo_mdb_del                 : ndo_mdb_del_func;
         --  ndo_mdb_del_bulk            : ndo_mdb_del_bulk_func;
         --  ndo_mdb_dump                : ndo_mdb_dump_func;
         --  ndo_mdb_get                 : ndo_mdb_get_func;
         --  ndo_bridge_setlink          : ndo_bridge_setlink_func;
         ndo_bridge_getlink          : ndo_bridge_getlink_func;
         --  ndo_bridge_dellink          : ndo_bridge_dellink_func;
         ndo_change_carrier          : ndo_change_carrier_func;
         --  ndo_get_phys_port_id        : ndo_get_phys_port_id_func;
         --  ndo_get_port_parent_id      : ndo_get_port_parent_id_func;
         --  ndo_get_phys_port_name      : ndo_get_phys_port_name_func;
         ndo_dfwd_add_station        : ndo_dfwd_add_station_func;
         ndo_dfwd_del_station        : ndo_dfwd_del_station_proc;
         ndo_set_tx_maxrate          : ndo_set_tx_maxrate_func;
         ndo_get_iflink              : ndo_get_iflink_func;
         ndo_fill_metadata_dst       : ndo_fill_metadata_dst_func;
         ndo_set_rx_headroom         : ndo_set_rx_headroom_proc;
         --  ndo_bpf                   : ndo_bpf_func;
         --  ndo_xdp_xmit              : ndo_xdp_xmit_func;
         --  ndo_xdp_get_xmit_slave    : ndo_xdp_get_xmit_slave_func;
         ndo_xsk_wakeup            : ndo_xsk_wakeup_func;
         --  ndo_tunnel_ctl            : ndo_tunnel_ctl_func;
         ndo_get_peer_dev          : ndo_get_peer_dev_func;
         --  ndo_fill_forward_path     : ndo_fill_forward_path_func;
         ndo_get_tstamp            : ndo_get_tstamp_func;
         --  ndo_hwtstamp_get          : ndo_hwtstamp_get_func;
         --  ndo_hwtstamp_set          : ndo_hwtstamp_set_func;
      end record;






   ------------------
   --- ptp_clock_info
   --


   PTP_CLOCK_NAME_LEN : constant := 32;


   -----------------------------------------------------------------------------
   -- Dummy definitions for external types required by ptp_clock_info.
   -----------------------------------------------------------------------------
   type module is null record;
   type module_ptr is access all module;

   type ptp_pin_desc is null record;
   type ptp_pin_desc_Ptr is access all ptp_pin_desc;


   -----------------------------------------------------------------------------
   -- Definition for the enumerated type ptp_pin_function.
   -- As the original code uses an enum, a minimal equivalent is provided.
   -----------------------------------------------------------------------------
   type ptp_pin_function is (PTP_PIN_FUNCTION_DEFAULT);

   -----------------------------------------------------------------------------
   -- Function pointer type declarations corresponding to the function members
   -- of the original C structure.
   -----------------------------------------------------------------------------
   type Adjphase_Func is access function (ptp: ptp_clock_info_Ptr;
                                          phase: Interfaces.Integer_32)
                                          return Interfaces.C.int;
   type Getmaxphase_Func is access function (ptp: ptp_clock_info_Ptr)
                                             return Interfaces.Integer_32;
   type Adjtime_Func is access function (ptp       : access ptp_clock_info;
                                         the_delta : in     Interfaces.Integer_64)     return Interfaces.C.int;
   type Gettime64_Func is access function (ptp: ptp_clock_info_Ptr;
                                           ts: access timespec64)
                                           return Interfaces.C.int;
   type Gettimex64_Func is access function (ptp : access ptp_clock_info;
                                            ts  : access timespec64;
                                            sts : access ptp_system_timestamp)         return Interfaces.C.int;
   type Getcrosststamp_Func is access function (ptp: access ptp_clock_info;
                                                cts: access system_device_crosststamp) return Interfaces.C.int;
   type Settime64_Func is access function (p  : access          ptp_clock_info;
                                           ts : access constant timespec64)            return Interfaces.C.int;
   type Getcycles64_Func is access function (ptp: ptp_clock_info_Ptr;
                                             ts: access timespec64)
                                             return Interfaces.C.int;
   type Getcyclesx64_Func is access function (ptp: ptp_clock_info_Ptr;
                                              ts: access timespec64;
                                              sts: access ptp_system_timestamp)
                                              return Interfaces.C.int;
   type Getcrosscycles_Func is access function (ptp: ptp_clock_info_Ptr;
                                                cts: access system_device_crosststamp)
                                                return Interfaces.C.int;
   type Enable_Func is access function (ptp     : access ptp_clock_info;
                                        request : access ptp_clock_request;
                                        on      : in      Interfaces.C.int)            return Interfaces.C.int;
   type Verify_Func is access function (ptp: ptp_clock_info_Ptr;
                                        pin: Interfaces.C.unsigned;
                                        func: ptp_pin_function;
                                        chan: Interfaces.C.unsigned)
                                        return Interfaces.C.int;
   type Do_aux_work_Func is access function (ptp: ptp_clock_info_Ptr)
                                             return Interfaces.C.long;

   -----------------------------------------------------------------------------
   -- Translation of the struct ptp_clock_info from C.
   -- Each member is translated line-by-line to preserve the exact structure,
   -- types, and order as in the original code.
   -----------------------------------------------------------------------------
   type ptp_clock_info is
      record
         owner           : module_ptr;
         name            : String (1 .. PTP_CLOCK_NAME_LEN);
         max_adj         : Interfaces.Integer_32;
         n_alarm         : Interfaces.C.int;
         n_ext_ts        : Interfaces.C.int;
         n_per_out       : Interfaces.C.int;
         n_pins          : Interfaces.C.int;
         pps             : Interfaces.C.int;
         pin_config      : ptp_pin_desc_Ptr;
         adjfine         : Adjfine_Func;
         adjphase        : Adjphase_Func;
         getmaxphase     : Getmaxphase_Func;
         adjtime         : Adjtime_Func;
         gettime64       : Gettime64_Func;
         gettimex64      : Gettimex64_Func;
         getcrosststamp  : Getcrosststamp_Func;
         settime64       : Settime64_Func;
         getcycles64     : Getcycles64_Func;
         getcyclesx64    : Getcyclesx64_Func;
         getcrosscycles  : Getcrosscycles_Func;
         enable          : Enable_Func;
         verify          : Verify_Func;
         do_aux_work     : Do_aux_work_Func;
      end record;




   type delayed_work_func is access procedure (Work : access Work_Struct);


   procedure INIT_DELAYED_WORK
     (work : in delayed_Work;
      func : in delayed_work_func);     -- TODO


   function ptp_clock_register
     (info   : access ptp_clock_info;
      parent : access device) return access ptp_clock
   is
     (raise Program_Error with "TODO");



   function cancel_delayed_work_sync
     (dwork : access delayed_work) return Boolean
   is
     (raise Program_Error with "TODO");



   function ptp_clock_unregister
     (ptp : access ptp_clock) return C.int
   is
     (raise Program_Error with "TODO");



end Linux;
