with
     Devices.e1000e.Hardware.e1000_hw_stats,
     Devices.e1000e.Hardware.e1000_phy_info,
     Devices.e1000e.Hardware.e1000_phy_stats,
     Devices.e1000e.Base.alloc_rx_buf_proc,
     Devices.e1000e.Base.clean_rx_func,
     Devices.e1000e.Base.e1000_phy_regs,
     Devices.e1000e.Base.e1000_ring,
     Devices.e1000e.Hardware.e1000_hw,
     Interfaces.C.Pointers,
     Devices.e1000e.Core,
     Devices.e1000e.Hardware,
     Linux;

limited
with
     Devices.e1000e.Base.e1000_info;


package Devices.e1000e.Base.e1000_adapter
--
--  Board specific private data structure.
--
is
   use Devices.e1000e.Hardware,
       Interfaces.C;


   BITS_PER_TYPE_long : constant := Interfaces.c.long'Size;


   --  #define __KERNEL_DIV_ROUND_UP(n, d) (((n) + (d) - 1) / (d))

   function KERNEL_DIV_ROUND_UP (n : in Integer;
                                 d : in Integer) return Integer
   is
      ((n + d - 1) / d);


   --  #define BITS_TO_LONGS(nr) __KERNEL_DIV_ROUND_UP(nr, BITS_PER_TYPE(long))

   function BITS_TO_LONGS (nr : in Integer) return interfaces.C.size_t
   is
     (interfaces.C.size_t (KERNEL_DIV_ROUND_UP (n => nr,
                                                d => BITS_PER_TYPE_long)));


   -- Item
   --

   type Item is
      record
         watchdog_timer       : aliased linux.timer_list;
         phy_info_timer       : aliased linux.timer_list;
         blink_timer          : aliased linux.timer_list;

         reset_task           : aliased linux.work_struct;
         watchdog_task        : aliased linux.work_struct;

         ei                   : access constant Devices.e1000e.Base.e1000_info.Item;

         active_vlans         : aliased Devices.e1000e.Core.unsigned_long_Array (0 .. BITS_TO_LONGS (VLAN_N_VID) - 1);
         bd_number            : aliased Devices.e1000e.Core.u32;
         rx_buffer_len        : aliased Devices.e1000e.Core.u32;
         mng_vlan_id          : aliased Devices.e1000e.Core.u16;
         link_speed           : aliased Devices.e1000e.Core.u16;
         link_duplex          : aliased Devices.e1000e.Core.u16;
         eeprom_vers          : aliased Devices.e1000e.Core.u16;

         state                : aliased Interfaces.C.unsigned_long;     -- Track device up/down/testing state.

         -- Interrupt Throttle Rate.
         itr                  : aliased Devices.e1000e.Core.u32;
         itr_setting          : aliased Devices.e1000e.Core.u32;
         tx_itr               : aliased Devices.e1000e.Core.u16;
         rx_itr               : aliased Devices.e1000e.Core.u16;

         -- Tx - one ring per active queue.
         tx_ring              :         Devices.e1000e.Base.e1000_ring.Pointer;          -- TODO:  '____cacheline_aligned_in_smp' is used in the C header.
         tx_fifo_limit        : aliased Devices.e1000e.Core.u32;

         napi                 : aliased linux.napi_struct;

         uncorr_errors        : aliased Interfaces.C.unsigned;          -- Uncorrectable ECC errors.
         corr_errors          : aliased Interfaces.C.unsigned;          -- Correctable   ECC errors.
         restart_queue        : aliased Interfaces.C.unsigned;
         txd_cmd              : aliased Devices.e1000e.Core.u32;

         detect_tx_hung       : aliased Boolean;
         tx_hang_recheck      : aliased Boolean;
         tx_timeout_factor    : aliased Devices.e1000e.Core.u8;

         tx_int_delay         : aliased Devices.e1000e.Core.u32;
         tx_abs_int_delay     : aliased Devices.e1000e.Core.u32;

         total_tx_bytes       : aliased Interfaces.C.unsigned;
         total_tx_packets     : aliased Interfaces.C.unsigned;
         total_rx_bytes       : aliased Interfaces.C.unsigned;
         total_rx_packets     : aliased Interfaces.C.unsigned;

         -- Tx stats.
         tpt_old              : aliased Devices.e1000e.Core.u64;
         colc_old             : aliased Devices.e1000e.Core.u64;
         gotc                 : aliased Devices.e1000e.Core.u32;
         gotc_old             : aliased Devices.e1000e.Core.u64;
         tx_timeout_count     : aliased Devices.e1000e.Core.u32;
         tx_fifo_head         : aliased Devices.e1000e.Core.u32;
         tx_head_addr         : aliased Devices.e1000e.Core.u32;
         tx_fifo_size         : aliased Devices.e1000e.Core.u32;
         tx_dma_failed        : aliased Devices.e1000e.Core.u32;
         tx_hwtstamp_timeouts : aliased Devices.e1000e.Core.u32;
         tx_hwtstamp_skipped  : aliased Devices.e1000e.Core.u32;

         -- Rx
         clean_rx             : aliased Devices.e1000e.Base.clean_rx_func.Item;
         alloc_rx_buf         : aliased Devices.e1000e.Base.alloc_rx_buf_proc.Item;

         rx_ring              : access  Devices.e1000e.Base.e1000_ring.Item;

         rx_int_delay         : aliased Devices.e1000e.Core.u32;
         rx_abs_int_delay     : aliased Devices.e1000e.Core.u32;

         -- Rx - stats.
         hw_csum_err          : aliased Devices.e1000e.Core.u64;
         hw_csum_good         : aliased Devices.e1000e.Core.u64;
         rx_hdr_split         : aliased Devices.e1000e.Core.u64;
         gorc                 : aliased Devices.e1000e.Core.u32;
         gorc_old             : aliased Devices.e1000e.Core.u64;
         alloc_rx_buff_failed : aliased Devices.e1000e.Core.u32;
         rx_dma_failed        : aliased Devices.e1000e.Core.u32;
         rx_hwtstamp_cleared  : aliased Devices.e1000e.Core.u32;

         rx_ps_pages          : aliased Interfaces.C.unsigned;
         rx_ps_bsize0         : aliased Devices.e1000e.Core.u16;
         max_frame_size       : aliased Devices.e1000e.Core.u32;
         min_frame_size       : aliased Devices.e1000e.Core.u32;

         -- OS defined structs.
         netdev               : access  linux.net_device;
         pdev                 : access  linux.pci_dev;

         -- Structs defined in e1000_hw spec.
         hw                   : aliased e1000_hw.item;

         stats64_lock         : aliased linux.spinlock_t;                    -- Protects statistics counters.
         stats                : aliased standard.Devices.e1000e.Hardware.e1000_hw_stats.item;
         phy_info             : aliased standard.Devices.e1000e.Hardware.e1000_phy_info.item;
         phy_stats            : aliased standard.Devices.e1000e.Hardware.e1000_phy_stats.item;

         phy_regs             : aliased Devices.e1000e.Base.e1000_phy_regs.Item;           -- Snapshot of PHY registers.

         test_tx_ring         : aliased Devices.e1000e.Base.e1000_ring.Item;
         test_rx_ring         : aliased Devices.e1000e.Base.e1000_ring.Item;
         test_icr             : aliased Devices.e1000e.Core.u32;

         msg_enable           : aliased Devices.e1000e.Core.u32;
         num_vectors          : aliased Interfaces.C.unsigned;
         msix_entries         :         linux.msix_entry_pointer;
         int_mode             : aliased Interfaces.C.int;
         eiac_mask            : aliased Devices.e1000e.Core.u32;

         eeprom_wol           : aliased Devices.e1000e.Core.u32;
         wol                  : aliased Devices.e1000e.Core.u32;
         pba                  : aliased Devices.e1000e.Core.u32;
         max_hw_frame_size    : aliased Devices.e1000e.Core.u32;

         fc_autoneg           : aliased Boolean;

         flags                : aliased Interfaces.C.unsigned;
         flags2               : aliased Interfaces.C.unsigned;

         downshift_task       : aliased linux.work_struct;
         update_phy_task      : aliased linux.work_struct;
         print_hang_task      : aliased linux.work_struct;

         phy_hang_count       : aliased Interfaces.C.int;

         tx_ring_count        : aliased Devices.e1000e.Core.u16;
         rx_ring_count        : aliased Devices.e1000e.Core.u16;

         hwtstamp_config      : aliased linux.hwtstamp_config;
         systim_overflow_work : aliased linux.delayed_work;
         tx_hwtstamp_skb      : access  linux.sk_buff;
         tx_hwtstamp_start    : aliased Interfaces.C.unsigned_long;
         tx_hwtstamp_work     : aliased linux.work_struct;
         systim_lock          : aliased linux.spinlock_t;               -- Protects SYSTIML/H regsters.
         cc                   : aliased linux.cyclecounter;
         tc                   : aliased linux.timecounter;
         ptp_clock            : access  linux.ptp_clock;
         ptp_clock_info       : aliased linux.ptp_clock_info;
         pm_qos_req           : aliased linux.pm_qos_request;
         ptp_delta            : aliased Interfaces.C.long;

         eee_advert           : aliased Devices.e1000e.Core.u16;
      end record;


   -- Item_Array
   --
   type Item_Array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Base.e1000_adapter.Item;


   -- Pointer
   --
   package C_Pointers is new Interfaces.C.Pointers (Index              => Interfaces.C.size_t,
                                                    Element            => Devices.e1000e.Base.e1000_adapter.Item,
                                                    Element_Array      => Devices.e1000e.Base.e1000_adapter.Item_Array,
                                                    Default_Terminator => (others => <>));

   subtype Pointer is C_Pointers.Pointer;


end Devices.e1000e.Base.e1000_adapter;
