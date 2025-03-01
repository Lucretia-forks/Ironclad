with
     Devices.e1000e.Base.e1000_adapter;


package body Linux
is

   procedure spin_lock_irqsave
     (lock : access spinlock_t; flags : in C.unsigned_long)
   is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "spin_lock_irqsave unimplemented");
      raise Program_Error with "Unimplemented procedure spin_lock_irqsave";
   end spin_lock_irqsave;

   procedure spin_unlock_irqrestore
     (lock : access spinlock_t; flags : in C.unsigned_long)
   is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "spin_unlock_irqrestore unimplemented");
      raise Program_Error
        with "Unimplemented procedure spin_unlock_irqrestore";
   end spin_unlock_irqrestore;

   procedure writew (Value : in u16; Addr : in System.Address) is
   begin
      pragma Compile_Time_Warning (Standard.True, "writew unimplemented");
      raise Program_Error with "Unimplemented procedure writew";
   end writew;

   procedure writel (Value : in u32; Addr : in System.Address) is
   begin
      pragma Compile_Time_Warning (Standard.True, "writel unimplemented");
      raise Program_Error with "Unimplemented procedure writel";
   end writel;

   procedure Clear_Bit (Nr : in C.long; Addr : in system.Address) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Clear_Bit unimplemented");
      raise Program_Error with "Unimplemented procedure Clear_Bit";
   end Clear_Bit;

   procedure Print_Hex_Dump
     (Level   : String; Prefix_Str : String; Prefix_Type : Dump_Prefix_Type;
      Rowsize : Integer; Groupsize : Integer; Buf : System.Address;
      Len     : Interfaces.C.size_t; Ascii : Boolean)
   is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Print_Hex_Dump unimplemented");
      raise Program_Error with "Unimplemented procedure Print_Hex_Dump";
   end Print_Hex_Dump;




   function Netif_Msg_Hw (P : access Devices.e1000e.Base.e1000_adapter.item) return Boolean
   is
     ((P.Msg_Enable and BIT (NETIF_MSG_HW_BIT'Enum_Rep)) /= 0);




   procedure Dev_Info (Dev : access Device; Message : in String) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Dev_Info unimplemented");
      raise Program_Error with "Unimplemented procedure Dev_Info";
   end Dev_Info;

   procedure Pr_Info (Message : in String) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Pr_Info unimplemented");
      raise Program_Error with "Unimplemented procedure Pr_Info";
   end Pr_Info;

   procedure CPU_To_Be16s (From : in out u16) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "CPU_To_Be16s unimplemented");
      raise Program_Error with "Unimplemented procedure CPU_To_Be16s";
   end CPU_To_Be16s;

   procedure le16_to_cpus (x : access u16) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "le16_to_cpus unimplemented");
      raise Program_Error with "Unimplemented procedure le16_to_cpus";
   end le16_to_cpus;

   procedure VLAN_Hwaccel_Put_Tag
     (Skb : access SK_Buff; Vlan_Proto : in be16; Vlan_Tci : in Unsigned_16)
   is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "VLAN_Hwaccel_Put_Tag unimplemented");
      raise Program_Error with "Unimplemented procedure VLAN_Hwaccel_Put_Tag";
   end VLAN_Hwaccel_Put_Tag;

   procedure Skb_Checksum_None_Assert (Skb : access constant Sk_Buff) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Skb_Checksum_None_Assert unimplemented");
      raise Program_Error
        with "Unimplemented procedure Skb_Checksum_None_Assert";
   end Skb_Checksum_None_Assert;

   procedure schedule_Work (Work : access work_struct) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "schedule_Work unimplemented");
      raise Program_Error with "Unimplemented procedure schedule_Work";
   end schedule_Work;

   procedure Skb_Trim (Skb : access Sk_Buff; Len : in C.unsigned) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Skb_Trim unimplemented");
      raise Program_Error with "Unimplemented procedure Skb_Trim";
   end Skb_Trim;

   procedure dev_err (Dev : access device; Message : in String) is
   begin
      pragma Compile_Time_Warning (Standard.True, "dev_err unimplemented");
      raise Program_Error with "Unimplemented procedure dev_err";
   end dev_err;

   procedure prefetch (Data : in void_ptr) is
   begin
      pragma Compile_Time_Warning (Standard.True, "prefetch unimplemented");
      raise Program_Error with "Unimplemented procedure prefetch";
   end prefetch;

   procedure wmb is
   begin
      pragma Compile_Time_Warning (Standard.True, "wmb unimplemented");
      raise Program_Error with "Unimplemented procedure wmb";
   end wmb;

   procedure rmb is
   begin
      pragma Compile_Time_Warning (Standard.True, "rmb unimplemented");
      raise Program_Error with "Unimplemented procedure rmb";
   end rmb;

   procedure dma_rmb is
   begin
      pragma Compile_Time_Warning (Standard.True, "dma_rmb unimplemented");
      raise Program_Error with "Unimplemented procedure dma_rmb";
   end dma_rmb;

   procedure DMA_Sync_Single_For_Device
     (Dev :    access Device; Addr : in DMA_Addr_T; Size : in C.Size_T;
      Dir : in DMA_Data_Direction)
   is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "DMA_Sync_Single_For_Device unimplemented");
      raise Program_Error
        with "Unimplemented procedure DMA_Sync_Single_For_Device";
   end DMA_Sync_Single_For_Device;

   procedure dma_unmap_single
     (Dev :    access Device; Dma : in dma_addr_t; Length : in u32;
      Dir : in Dma_Data_Direction)
   is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "dma_unmap_single unimplemented");
      raise Program_Error with "Unimplemented procedure dma_unmap_single";
   end dma_unmap_single;

   procedure DMA_Unmap_Page
     (Dev :    access Device; Addr : in DMA_Addr_T; Size : in C.Size_t;
      Dir : in DMA_Data_Direction)
   is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "DMA_Unmap_Page unimplemented");
      raise Program_Error with "Unimplemented procedure DMA_Unmap_Page";
   end DMA_Unmap_Page;

   procedure Dev_Kfree_Skb_Any (Skb : access Sk_Buff) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Dev_Kfree_Skb_Any unimplemented");
      raise Program_Error with "Unimplemented procedure Dev_Kfree_Skb_Any";
   end Dev_Kfree_Skb_Any;

   procedure Dev_Kfree_Skb_Irq (Skb : access Sk_Buff) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Dev_Kfree_Skb_Irq unimplemented");
      raise Program_Error with "Unimplemented procedure Dev_Kfree_Skb_Irq";
   end Dev_Kfree_Skb_Irq;

   procedure DMA_Sync_Single_For_CPU
     (Dev :    access Device; Addr : in DMA_Addr_T; Size : in C.Size_T;
      Dir : in DMA_Data_Direction)
   is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "DMA_Sync_Single_For_CPU unimplemented");
      raise Program_Error
        with "Unimplemented procedure DMA_Sync_Single_For_CPU";
   end DMA_Sync_Single_For_CPU;

   procedure skb_set_hash
     (skb : access sk_buff; hash : in u32; hask_type : in pkt_hash_types)
   is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "skb_set_hash unimplemented");
      raise Program_Error with "Unimplemented procedure skb_set_hash";
   end skb_set_hash;

   procedure Skb_Copy_To_Linear_Data_Offset
     (Skb :    access Sk_Buff; Offset : in Integer; From : in void_ptr;
      Len : in C.Unsigned)
   is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Skb_Copy_To_Linear_Data_Offset unimplemented");
      raise Program_Error
        with "Unimplemented procedure Skb_Copy_To_Linear_Data_Offset";
   end Skb_Copy_To_Linear_Data_Offset;

   procedure Dev_Consume_Skb_Any (Skb : access Sk_Buff) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Dev_Consume_Skb_Any unimplemented");
      raise Program_Error with "Unimplemented procedure Dev_Consume_Skb_Any";
   end Dev_Consume_Skb_Any;

   procedure Skb_Fill_Page_Desc
     (Skb :    access Sk_Buff; I : in Integer; Page : access linux.Page;
      Off : in Integer; Size : in Integer)
   is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Skb_Fill_Page_Desc unimplemented");
      raise Program_Error with "Unimplemented procedure Skb_Fill_Page_Desc";
   end Skb_Fill_Page_Desc;

   procedure set_bit (Number : in Natural; Addr : in system.Address) is
   begin
      pragma Compile_Time_Warning (Standard.True, "set_bit unimplemented");
      raise Program_Error with "Unimplemented procedure set_bit";
   end set_bit;

   procedure Netif_Stop_Queue (Dev : access Net_Device) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Netif_Stop_Queue unimplemented");
      raise Program_Error with "Unimplemented procedure Netif_Stop_Queue";
   end Netif_Stop_Queue;

   procedure Skb_Tstamp_Tx
     (Orig_Skb : access Sk_Buff; Hwtstamps : access Skb_Shared_Hwtstamps)
   is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Skb_Tstamp_Tx unimplemented");
      raise Program_Error with "Unimplemented procedure Skb_Tstamp_Tx";
   end Skb_Tstamp_Tx;

   procedure Netdev_Completed_Queue
     (Dev : access Net_Device; Pkts : in Unsigned_32; Bytes : in Unsigned_32)
   is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Netdev_Completed_Queue unimplemented");
      raise Program_Error
        with "Unimplemented procedure Netdev_Completed_Queue";
   end Netdev_Completed_Queue;

   procedure Netif_Wake_Queue (Dev : access Net_Device) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Netif_Wake_Queue unimplemented");
      raise Program_Error with "Unimplemented procedure Netif_Wake_Queue";
   end Netif_Wake_Queue;

   procedure smp_mb is
   begin
      pragma Compile_Time_Warning (Standard.True, "smp_mb unimplemented");
      raise Program_Error with "Unimplemented procedure smp_mb";
   end smp_mb;

   procedure Dev_Kfree_Skb (Skb : access Sk_Buff) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Dev_Kfree_Skb unimplemented");
      raise Program_Error with "Unimplemented procedure Dev_Kfree_Skb";
   end Dev_Kfree_Skb;

   procedure memset
     (Address : in system.Address; Value : in u8; Length : in C.unsigned)
   is
   begin
      pragma Compile_Time_Warning (Standard.True, "memset unimplemented");
      raise Program_Error with "Unimplemented procedure memset";
   end memset;

   procedure vfree (Addr : System.Address) is
   begin
      pragma Compile_Time_Warning (Standard.True, "vfree unimplemented");
      raise Program_Error with "Unimplemented procedure vfree";
   end vfree;

   procedure kfree (Object : in system.Address) is
   begin
      pragma Compile_Time_Warning (Standard.True, "kfree unimplemented");
      raise Program_Error with "Unimplemented procedure kfree";
   end kfree;

   procedure Netdev_Reset_Queue (Dev_Queue : access Net_Device) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Netdev_Reset_Queue unimplemented");
      raise Program_Error with "Unimplemented procedure Netdev_Reset_Queue";
   end Netdev_Reset_Queue;

   procedure DMA_Free_Coherent
     (Dev :    access Device; Size : in C.size_t; CPU_Addr : in System.Address;
      DMA_Handle : in DMA_Addr_T)
   is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "DMA_Free_Coherent unimplemented");
      raise Program_Error with "Unimplemented procedure DMA_Free_Coherent";
   end DMA_Free_Coherent;

   procedure pci_disable_msi (dev : access pci_dev) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "pci_disable_msi unimplemented");
      raise Program_Error with "Unimplemented procedure pci_disable_msi";
   end pci_disable_msi;

   procedure pci_disable_msix (dev : access pci_dev) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "pci_disable_msix unimplemented");
      raise Program_Error with "Unimplemented procedure pci_disable_msix";
   end pci_disable_msix;

   procedure snprintf
     (Target : in out C.char_array; Size : in Integer; Source : in String)
   is
   begin
      pragma Compile_Time_Warning (Standard.True, "snprintf unimplemented");
      raise Program_Error with "Unimplemented procedure snprintf";
   end snprintf;

   procedure synchronize_irq (Irq : in C.Unsigned) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "synchronize_irq unimplemented");
      raise Program_Error with "Unimplemented procedure synchronize_irq";
   end synchronize_irq;

   procedure cpu_latency_qos_update_request
     (req : access pm_qos_request; new_value : in s32)
   is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "cpu_latency_qos_update_request unimplemented");
      raise Program_Error
        with "Unimplemented procedure cpu_latency_qos_update_request";
   end cpu_latency_qos_update_request;

   procedure netdev_rss_key_fill (buffer : in void_ptr; len : in C.size_t) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "netdev_rss_key_fill unimplemented");
      raise Program_Error with "Unimplemented procedure netdev_rss_key_fill";
   end netdev_rss_key_fill;

   procedure dev_warn (dev : access Device; Message : in String) is
   begin
      pragma Compile_Time_Warning (Standard.True, "dev_warn unimplemented");
      raise Program_Error with "Unimplemented procedure dev_warn";
   end dev_warn;

   procedure timecounter_init
     (tc           :    access timecounter; cc : access constant cyclecounter;
      start_tstamp : in u64)
   is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "timecounter_init unimplemented");
      raise Program_Error with "Unimplemented procedure timecounter_init";
   end timecounter_init;

   procedure netif_carrier_off (dev : access net_device) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "netif_carrier_off unimplemented");
      raise Program_Error with "Unimplemented procedure netif_carrier_off";
   end netif_carrier_off;

   procedure napi_synchronize (n : access napi_struct) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "napi_synchronize unimplemented");
      raise Program_Error with "Unimplemented procedure napi_synchronize";
   end napi_synchronize;

   procedure spin_lock_init (lock : access spinlock_t) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "spin_lock_init unimplemented");
      raise Program_Error with "Unimplemented procedure spin_lock_init";
   end spin_lock_init;

   procedure spin_lock (lock : access spinlock_t) is
   begin
      pragma Compile_Time_Warning (Standard.True, "spin_lock unimplemented");
      raise Program_Error with "Unimplemented procedure spin_lock";
   end spin_lock;

   procedure spin_unlock (lock : access spinlock_t) is
   begin
      pragma Compile_Time_Warning (Standard.True, "spin_unlock unimplemented");
      raise Program_Error with "Unimplemented procedure spin_unlock";
   end spin_unlock;

   procedure might_sleep is
   begin
      pragma Compile_Time_Warning (Standard.True, "might_sleep unimplemented");
      raise Program_Error with "Unimplemented procedure might_sleep";
   end might_sleep;

   procedure ptp_read_system_prets (sts : access ptp_system_timestamp) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "ptp_read_system_prets unimplemented");
      raise Program_Error with "Unimplemented procedure ptp_read_system_prets";
   end ptp_read_system_prets;

   procedure Ptp_Read_System_Postts (sts : access ptp_system_timestamp) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Ptp_Read_System_Postts unimplemented");
      raise Program_Error
        with "Unimplemented procedure Ptp_Read_System_Postts";
   end Ptp_Read_System_Postts;

   procedure INIT_WORK
     (work : access work_struct;
      func : access procedure (Work : access Work_Struct))
   is
   begin
      pragma Compile_Time_Warning (Standard.True, "INIT_WORK unimplemented");
      raise Program_Error with "Unimplemented procedure INIT_WORK";
   end INIT_WORK;

   procedure cpu_latency_qos_add_request
     (req : access pm_qos_request; value : in Devices.e1000e.Core.s32)
   is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "cpu_latency_qos_add_request unimplemented");
      raise Program_Error
        with "Unimplemented procedure cpu_latency_qos_add_request";
   end cpu_latency_qos_add_request;

   procedure napi_enable (n : access napi_struct) is
   begin
      pragma Compile_Time_Warning (Standard.True, "napi_enable unimplemented");
      raise Program_Error with "Unimplemented procedure napi_enable";
   end napi_enable;

   procedure cpu_latency_qos_remove_request (req : access pm_qos_request) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "cpu_latency_qos_remove_request unimplemented");
      raise Program_Error
        with "Unimplemented procedure cpu_latency_qos_remove_request";
   end cpu_latency_qos_remove_request;

   procedure WARN_ON (Condition : in Boolean) is
   begin
      pragma Compile_Time_Warning (Standard.True, "WARN_ON unimplemented");
      raise Program_Error with "Unimplemented procedure WARN_ON";
   end WARN_ON;

   procedure netif_carrier_on (dev : access net_device) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "netif_carrier_on unimplemented");
      raise Program_Error with "Unimplemented procedure netif_carrier_on";
   end netif_carrier_on;

   procedure netdev_info
     (dev : access constant net_device; Message : in String)
   is
   begin
      pragma Compile_Time_Warning (Standard.True, "netdev_info unimplemented");
      raise Program_Error with "Unimplemented procedure netdev_info";
   end netdev_info;

   procedure napi_disable (n : access napi_struct) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "napi_disable unimplemented");
      raise Program_Error with "Unimplemented procedure napi_disable";
   end napi_disable;

   procedure eth_hw_addr_set (dev : access net_device; addr : in u8_Pointer) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "eth_hw_addr_set unimplemented");
      raise Program_Error with "Unimplemented procedure eth_hw_addr_set";
   end eth_hw_addr_set;

   procedure netdev_warn (dev : access net_device; Message : in String) is
   begin
      pragma Compile_Time_Warning (Standard.True, "netdev_warn unimplemented");
      raise Program_Error with "Unimplemented procedure netdev_warn";
   end netdev_warn;

   procedure netdev_dbg (dev : access net_device; Message : in String) is
   begin
      pragma Compile_Time_Warning (Standard.True, "netdev_dbg unimplemented");
      raise Program_Error with "Unimplemented procedure netdev_dbg";
   end netdev_dbg;

   procedure tcp_v6_gso_csum_prep (skb : access sk_buff) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "tcp_v6_gso_csum_prep unimplemented");
      raise Program_Error with "Unimplemented procedure tcp_v6_gso_csum_prep";
   end tcp_v6_gso_csum_prep;

   procedure netif_start_queue (dev : access net_device) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "netif_start_queue unimplemented");
      raise Program_Error with "Unimplemented procedure netif_start_queue";
   end netif_start_queue;

   procedure skb_tx_timestamp (skb : access sk_buff) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "skb_tx_timestamp unimplemented");
      raise Program_Error with "Unimplemented procedure skb_tx_timestamp";
   end skb_tx_timestamp;

   procedure netdev_sent_queue (dev : access net_device; bytes : in C.unsigned)
   is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "netdev_sent_queue unimplemented");
      raise Program_Error with "Unimplemented procedure netdev_sent_queue";
   end netdev_sent_queue;

   procedure rtnl_lock is
   begin
      pragma Compile_Time_Warning (Standard.True, "rtnl_lock unimplemented");
      raise Program_Error with "Unimplemented procedure rtnl_lock";
   end rtnl_lock;

   procedure rtnl_unlock is
   begin
      pragma Compile_Time_Warning (Standard.True, "rtnl_unlock unimplemented");
      raise Program_Error with "Unimplemented procedure rtnl_unlock";
   end rtnl_unlock;

   procedure WRITE_ONCE (x : in out C.unsigned; val : in C.unsigned) is
   begin
      pragma Compile_Time_Warning (Standard.True, "WRITE_ONCE unimplemented");
      raise Program_Error with "Unimplemented procedure WRITE_ONCE";
   end WRITE_ONCE;

   procedure netif_device_detach (dev : access net_device) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "netif_device_detach unimplemented");
      raise Program_Error with "Unimplemented procedure netif_device_detach";
   end netif_device_detach;

   procedure pci_clear_master (dev : access pci_dev) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "pci_clear_master unimplemented");
      raise Program_Error with "Unimplemented procedure pci_clear_master";
   end pci_clear_master;

   procedure netif_device_attach (dev : access net_device) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "netif_device_attach unimplemented");
      raise Program_Error with "Unimplemented procedure netif_device_attach";
   end netif_device_attach;

   procedure pci_set_master (dev : access pci_dev) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "pci_set_master unimplemented");
      raise Program_Error with "Unimplemented procedure pci_set_master";
   end pci_set_master;

   procedure enable_irq (irq : in C.unsigned) is
   begin
      pragma Compile_Time_Warning (Standard.True, "enable_irq unimplemented");
      raise Program_Error with "Unimplemented procedure enable_irq";
   end enable_irq;

   procedure pci_disable_device (dev : access pci_dev) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "pci_disable_device unimplemented");
      raise Program_Error with "Unimplemented procedure pci_disable_device";
   end pci_disable_device;

   procedure pci_restore_state (dev : access pci_dev) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "pci_restore_state unimplemented");
      raise Program_Error with "Unimplemented procedure pci_restore_state";
   end pci_restore_state;

   procedure SET_NETDEV_DEV (net : access net_device; pdev : access device) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "SET_NETDEV_DEV unimplemented");
      raise Program_Error with "Unimplemented procedure SET_NETDEV_DEV";
   end SET_NETDEV_DEV;

   procedure pci_set_drvdata (pdev : access pci_dev; data : in void_ptr) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "pci_set_drvdata unimplemented");
      raise Program_Error with "Unimplemented procedure pci_set_drvdata";
   end pci_set_drvdata;

   procedure netif_napi_add
     (dev : access net_device; napi : access napi_struct; poll : in poll_type)
   is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "netif_napi_add unimplemented");
      raise Program_Error with "Unimplemented procedure netif_napi_add";
   end netif_napi_add;

   procedure timer_setup
     (timer    : access timer_list;
      callback : access procedure (T : access timer_list); flags : in C.int)
   is
   begin
      pragma Compile_Time_Warning (Standard.True, "timer_setup unimplemented");
      raise Program_Error with "Unimplemented procedure timer_setup";
   end timer_setup;

   procedure dev_pm_set_driver_flags (dev : access device; flags : in u32) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "dev_pm_set_driver_flags unimplemented");
      raise Program_Error
        with "Unimplemented procedure dev_pm_set_driver_flags";
   end dev_pm_set_driver_flags;

   procedure pm_runtime_put_noidle (dev : access device) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "pm_runtime_put_noidle unimplemented");
      raise Program_Error with "Unimplemented procedure pm_runtime_put_noidle";
   end pm_runtime_put_noidle;

   procedure iounmap (addr : in void_ptr) is
   begin
      pragma Compile_Time_Warning (Standard.True, "iounmap unimplemented");
      raise Program_Error with "Unimplemented procedure iounmap";
   end iounmap;

   procedure free_netdev (dev : access net_device) is
   begin
      pragma Compile_Time_Warning (Standard.True, "free_netdev unimplemented");
      raise Program_Error with "Unimplemented procedure free_netdev";
   end free_netdev;

   procedure pci_release_mem_regions (pdev : access pci_dev) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "pci_release_mem_regions unimplemented");
      raise Program_Error
        with "Unimplemented procedure pci_release_mem_regions";
   end pci_release_mem_regions;

   procedure unregister_netdev (dev : access net_device) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "unregister_netdev unimplemented");
      raise Program_Error with "Unimplemented procedure unregister_netdev";
   end unregister_netdev;

   procedure pm_runtime_get_noresume (dev : access device) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "pm_runtime_get_noresume unimplemented");
      raise Program_Error
        with "Unimplemented procedure pm_runtime_get_noresume";
   end pm_runtime_get_noresume;

   procedure timecounter_adjtime
     (tc : access timecounter; the_delta : in Interfaces.Integer_64)
   is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "timecounter_adjtime unimplemented");
      raise Program_Error with "Unimplemented procedure timecounter_adjtime";
   end timecounter_adjtime;

   procedure INIT_DELAYED_WORK
     (work : in delayed_Work; func : in delayed_work_func)
   is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "INIT_DELAYED_WORK unimplemented");
      raise Program_Error with "Unimplemented procedure INIT_DELAYED_WORK";
   end INIT_DELAYED_WORK;

end Linux;
