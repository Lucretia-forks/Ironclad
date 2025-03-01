with
     Devices.e1000e.Defines,
     Devices.e1000e.Core,
     Devices.e1000e.Core.Pointers,
     Devices.e1000e.Hardware.e1000_hw,
     Devices.e1000e.Hardware.e1000_mac_operations,
     Devices.e1000e.Hardware.e1000_phy_operations,
     Devices.e1000e.Hardware.e1000_nvm_operations,
     Devices.e1000e.Media_Access_Control,
     Devices.e1000e.Physical_Layer,
     Devices.e1000e.Non_Volatile_Memory,
     Devices.e1000e.Base.e1000_info,
     Devices.e1000e.Base.e1000_adapter,
     Linux,
     Interfaces;


package Devices.e1000e.an_82571
is
   use Devices.e1000e.Defines,
       Devices.e1000e.Core,
       Devices.e1000e.Base,
       Interfaces;


   subtype e1000_hw is Devices.e1000e.Hardware.e1000_hw.item;




   ID_LED_RESERVED_F746            : constant             := 16#f746#;
   ID_LED_DEFAULT_82573            : constant Unsigned_32 :=    shift_Left (ID_LED_DEF1_DEF2, 12)
                                                             or shift_Left (ID_LED_OFF1_ON2,   8)
                                                             or shift_Left (ID_LED_DEF1_DEF2,  4)
                                                             or             ID_LED_DEF1_DEF2;

   E1000_GCR_L1_ACT_WITHOUT_L0S_RX : constant := 16#800_0000#;
   AN_RETRY_COUNT                  : constant := 5;                -- Autoneg Retry Count value.

   -- Intr Throttling - RW.
   --
   function E1000_EITR_82574 (n : in Integer) return Integer
   is
     (16#000E8# + 16#4# * n);


   E1000_EIAC_82574                : constant := 16#dc#;           -- Ext. Interrupt Auto Clear - RW.
   E1000_EIAC_MASK_82574           : constant := 16#1f0_0000#;


   E1000_IVAR_INT_ALLOC_VALID      : constant := 16#8#;


   -- Manageability Operation Mode mask.
   --
   E1000_NVM_INIT_CTRL2_MNGM       : constant := 16#6000#;


   E1000_BASE1000T_STATUS          : constant := 10;
   E1000_IDLE_ERROR_COUNT_MASK     : constant := 16#ff#;
   E1000_RECEIVE_ERROR_COUNTER     : constant := 21;
   E1000_RECEIVE_ERROR_MAX         : constant := 16#ffff#;



   ---------------
   --- Subprograms
   --

   use Devices.e1000e.Hardware;

   function e1000_check_phy_82574
     (hw    : access e1000_hw) return Boolean;

   function e1000e_get_laa_state_82571
     (hw    : access e1000_hw) return Boolean;

   procedure e1000e_set_laa_state_82571
     (hw    : access e1000_hw;
      state : in     Boolean);



   --------
   --- Info
   --

   e1000_82571_info   : aliased constant Devices.e1000e.Base.e1000_info.item;
   e1000_82572_info   : aliased constant Devices.e1000e.Base.e1000_info.item;
   e1000_82573_info   : aliased constant Devices.e1000e.Base.e1000_info.item;
   e1000_82574_info   : aliased constant Devices.e1000e.Base.e1000_info.item;
   e1000_82583_info   : aliased constant Devices.e1000e.Base.e1000_info.item;





private

   ------------------
   --- e82571_mac_ops
   --

   --  function e1000_get_variants_82571
   --    (adapter : access e1000.e1000_adapter.Item) return core.s32;

   procedure e1000_clear_hw_cntrs_82571
     (hw : access e1000_hw);

   procedure e1000_clear_vfta_82571
     (hw : access e1000_hw);

   function e1000_reset_hw_82571
     (hw : access e1000_hw) return s32;

   function e1000_init_hw_82571
     (hw : access e1000_hw) return s32;

   function e1000_setup_link_82571
     (hw : access e1000_hw) return s32;

   function e1000_read_mac_addr_82571
     (hw : access e1000_hw) return s32;


   e82571_mac_ops :  aliased constant Devices.e1000e.Hardware.e1000_mac_operations.item := (id_led_init              => Devices.e1000e.Media_Access_Control.e1000e_id_led_init_generic          'Access,
                                                                             blink_led                => null,
                                                                             check_mng_mode           => null,                                   -- Mac type dependent.
                                                                             check_for_link           => null,                                   -- Media type dependent.
                                                                             cleanup_led              => Devices.e1000e.Media_Access_Control.e1000e_cleanup_led_generic          'Access,
                                                                             clear_hw_cntrs           => e1000_clear_hw_cntrs_82571              'Access,
                                                                             clear_vfta               => e1000_clear_vfta_82571                  'Access,
                                                                             get_bus_info             => Devices.e1000e.Media_Access_Control.e1000e_get_bus_info_pcie            'Access,
                                                                             set_lan_id               => Devices.e1000e.Media_Access_Control.e1000_set_lan_id_multi_port_pcie    'Access,
                                                                             get_link_up_info         => null,                                   -- Media type dependent.
                                                                             led_on                   => null,                                   -- Mac type dependent.
                                                                             led_off                  => Devices.e1000e.Media_Access_Control.e1000e_led_off_generic              'Access,
                                                                             update_mc_addr_list      => Devices.e1000e.Media_Access_Control.e1000e_update_mc_addr_list_generic  'Access,
                                                                             reset_hw                 => e1000_reset_hw_82571                    'Access,
                                                                             init_hw                  => e1000_init_hw_82571                     'Access,
                                                                             setup_link               => e1000_setup_link_82571                  'Access,
                                                                             setup_physical_interface => null,                                   -- Media type dependent.
                                                                             setup_led                => Devices.e1000e.Media_Access_Control.e1000e_setup_led_generic            'Access,
                                                                             write_vfta               => Devices.e1000e.Media_Access_Control.e1000_write_vfta_generic            'Access,
                                                                             config_collision_dist    => Devices.e1000e.Media_Access_Control.e1000e_config_collision_dist_generic'Access,
                                                                             rar_set                  => Devices.e1000e.Media_Access_Control.e1000e_rar_set_generic              'Access,
                                                                             read_mac_addr            => e1000_read_mac_addr_82571               'Access,
                                                                             rar_get_count            => Devices.e1000e.Media_Access_Control.e1000e_rar_get_count_generic        'Access);
   -------------------
   --- e82_phy_ops_igp
   --

   function e1000_get_hw_semaphore_82571
     (hw : access e1000_hw) return s32;

   function e1000_get_cfg_done_82571
     (hw : access e1000_hw) return s32;

   procedure e1000_put_hw_semaphore_82571
     (hw : access e1000_hw);

   function e1000_set_d0_lplu_state_82571
     (hw     : access e1000_hw;
      active : in     Boolean) return s32;


   e82_phy_ops_igp : aliased constant Devices.e1000e.Hardware.e1000_phy_operations.item := (acquire            => e1000_get_hw_semaphore_82571         'Access,
                                                                             check_polarity     => Devices.e1000e.Physical_Layer.e1000_check_polarity_igp         'Access,
                                                                             check_reset_block  => Devices.e1000e.Physical_Layer.e1000e_check_reset_block_generic 'Access,
                                                                             commit             => null,
                                                                             force_speed_duplex => Devices.e1000e.Physical_Layer.e1000e_phy_force_speed_duplex_igp'Access,
                                                                             get_cfg_done       => e1000_get_cfg_done_82571             'Access,
                                                                             get_cable_length   => Devices.e1000e.Physical_Layer.e1000e_get_cable_length_igp_2    'Access,
                                                                             get_info           => Devices.e1000e.Physical_Layer.e1000e_get_phy_info_igp          'Access,
                                                                             set_page           => null,
                                                                             read_reg           => Devices.e1000e.Physical_Layer.e1000e_read_phy_reg_igp          'Access,
                                                                             read_reg_locked    => null,
                                                                             read_reg_page      => null,
                                                                             release            => e1000_put_hw_semaphore_82571   'Access,
                                                                             reset              => Devices.e1000e.Physical_Layer.e1000e_phy_hw_reset_generic'Access,
                                                                             set_d0_lplu_state  => e1000_set_d0_lplu_state_82571  'Access,
                                                                             set_d3_lplu_state  => Devices.e1000e.Physical_Layer.e1000e_set_d3_lplu_state   'Access,
                                                                             write_reg          => Devices.e1000e.Physical_Layer.e1000e_write_phy_reg_igp   'Access,
                                                                             write_reg_locked   => null,
                                                                             write_reg_page     => null,
                                                                             cfg_on_link_up     => null,
                                                                             power_up           => null,
                                                                             power_down         => null);
   ------------------
   --- e82571_nvm_ops
   --

   function e1000_acquire_nvm_82571
     (hw : access e1000_hw) return s32;

   procedure e1000_release_nvm_82571
     (hw : access e1000_hw);

   function e1000_update_nvm_checksum_82571
     (hw : access e1000_hw) return s32;

   function e1000_valid_led_default_82571
     (hw   : access e1000_hw;
      data : in     Devices.e1000e.Core.Pointers.u16_Pointer) return s32;

   function e1000_validate_nvm_checksum_82571
     (hw : access e1000_hw) return s32;

   function e1000_write_nvm_82571
     (hw     : access e1000_hw;
      offset : in     u16;
      words  : in     u16;
      data   : in     Devices.e1000e.Core.Pointers.u16_Pointer) return s32;


   e82571_nvm_ops : aliased constant Devices.e1000e.Hardware.e1000_nvm_operations.item := (acquire           => e1000_acquire_nvm_82571          'Access,
                                                                      read              => Devices.e1000e.Non_Volatile_Memory.e1000e_read_nvm_eerd         'Access,
                                                                      release           => e1000_release_nvm_82571          'Access,
                                                                      reload            => Devices.e1000e.Non_Volatile_Memory.e1000e_reload_nvm_generic        'Access,
                                                                      update            => e1000_update_nvm_checksum_82571  'Access,
                                                                      valid_led_default => e1000_valid_led_default_82571    'Access,
                                                                      validate          => e1000_validate_nvm_checksum_82571'Access,
                                                                      write             => e1000_write_nvm_82571            'Access);

   --------------------
   --- e1000_82571_info
   --

   function E1000_Get_Variants_82571
     (Adapter : access E1000_Adapter.item) return s32;


   e1000_82571_info   : aliased constant Devices.e1000e.Base.e1000_info.item := (mac               => e1000_82571,
                                                                   flags             =>    FLAG_HAS_HW_VLAN_FILTER
                                                                                        or FLAG_HAS_JUMBO_FRAMES
                                                                                        or FLAG_HAS_WOL
                                                                                        or FLAG_APME_IN_CTRL3
                                                                                        or FLAG_HAS_CTRLEXT_ON_LOAD
                                                                                        or FLAG_HAS_SMART_POWER_DOWN
                                                                                        or FLAG_RESET_OVERWRITES_LAA      -- errata
                                                                                        or FLAG_TARC_SPEED_MODE_BIT       -- errata
                                                                                        or FLAG_APME_CHECK_PORT_B,
                                                                   flags2            =>    FLAG2_DISABLE_ASPM_L1          -- errata 13
                                                                                        or FLAG2_DMA_BURST,
                                                                   pba               => 38,
                                                                   max_hw_frame_size => DEFAULT_JUMBO,
                                                                   get_variants      => e1000_get_variants_82571'Access,
                                                                   mac_ops           => e82571_mac_ops          'Access,
                                                                   phy_ops           => e82_phy_ops_igp         'Access,
                                                                   nvm_ops           => e82571_nvm_ops          'Access);
   --------------------
   --- e1000_82572_info
   --

   e1000_82572_info   : aliased constant Devices.e1000e.Base.e1000_info.item := (mac               => e1000_82572,
                                                                   flags             =>    FLAG_HAS_HW_VLAN_FILTER
                                                                                        or FLAG_HAS_JUMBO_FRAMES
                                                                                        or FLAG_HAS_WOL
                                                                                        or FLAG_APME_IN_CTRL3
                                                                                        or FLAG_HAS_CTRLEXT_ON_LOAD
                                                                                        or FLAG_TARC_SPEED_MODE_BIT,       -- errata
                                                                   flags2            =>    FLAG2_DISABLE_ASPM_L1          -- errata 13
                                                                                        or FLAG2_DMA_BURST,
                                                                   pba               => 38,
                                                                   max_hw_frame_size => DEFAULT_JUMBO,
                                                                   get_variants      => e1000_get_variants_82571'Access,
                                                                   mac_ops           => e82571_mac_ops          'Access,
                                                                   phy_ops           => e82_phy_ops_igp         'Access,
                                                                   nvm_ops           => e82571_nvm_ops          'Access);
   --------------------
   --- e1000_82573_info
   --

   e82_phy_ops_m88 : aliased constant e1000_phy_operations.item  := (acquire            => e1000_get_hw_semaphore_82571         'Access,
                                                                     check_polarity     => Devices.e1000e.Physical_Layer.e1000_check_polarity_m88         'Access,
                                                                     check_reset_block  => Devices.e1000e.Physical_Layer.e1000e_check_reset_block_generic 'Access,
                                                                     commit             => Devices.e1000e.Physical_Layer.e1000e_phy_sw_reset              'Access,
                                                                     force_speed_duplex => Devices.e1000e.Physical_Layer.e1000e_phy_force_speed_duplex_m88'Access,
                                                                     get_cfg_done       => Devices.e1000e.Physical_Layer.e1000e_get_cfg_done_generic      'Access,
                                                                     get_cable_length   => Devices.e1000e.Physical_Layer.e1000e_get_cable_length_m88      'Access,
                                                                     get_info           => Devices.e1000e.Physical_Layer.e1000e_get_phy_info_m88          'Access,
                                                                     read_reg           => Devices.e1000e.Physical_Layer.e1000e_read_phy_reg_m88          'Access,
                                                                     release            => e1000_put_hw_semaphore_82571         'Access,
                                                                     reset              => Devices.e1000e.Physical_Layer.e1000e_phy_hw_reset_generic      'Access,
                                                                     set_d0_lplu_state  => e1000_set_d0_lplu_state_82571        'Access,
                                                                     set_d3_lplu_state  => Devices.e1000e.Physical_Layer.e1000e_set_d3_lplu_state         'Access,
                                                                     write_reg          => Devices.e1000e.Physical_Layer.e1000e_write_phy_reg_m88         'Access,
                                                                     cfg_on_link_up     => null,
                                                                     set_page           => null,
                                                                     read_reg_locked    => null,
                                                                     read_reg_page      => null,
                                                                     write_reg_locked   => null,
                                                                     write_reg_page     => null,
                                                                     power_up           => null,
                                                                     power_down         => null);


      e1000_82573_info   : aliased constant Devices.e1000e.Base.e1000_info.item := (mac               => e1000_82573,
                                                                      flags             =>    FLAG_HAS_HW_VLAN_FILTER
                                                                                           or FLAG_HAS_WOL
                                                                                           or FLAG_APME_IN_CTRL3
                                                                                           or FLAG_HAS_SMART_POWER_DOWN
                                                                                           or FLAG_HAS_AMT
                                                                                           or FLAG_HAS_SWSM_ON_LOAD,
                                                                      flags2            =>    FLAG2_DISABLE_ASPM_L1
                                                                                           or FLAG2_DISABLE_ASPM_L0S,
                                                                      pba               => 20,
                                                                      max_hw_frame_size =>   linux.VLAN_ETH_FRAME_LEN
                                                                                           + linux.ETH_FCS_LEN,
                                                                      get_variants      => e1000_get_variants_82571'Access,
                                                                      mac_ops           => e82571_mac_ops          'Access,
                                                                      phy_ops           => e82_phy_ops_m88         'Access,
                                                                      nvm_ops           => e82571_nvm_ops          'Access);
   --------------------
   --- e1000_82574_info
   --

   e82_phy_ops_bm : aliased constant e1000_phy_operations.item := (acquire            => e1000_get_hw_semaphore_82571         'Access,
                                                                   check_polarity     => Devices.e1000e.Physical_Layer.e1000_check_polarity_m88         'Access,
                                                                   check_reset_block  => Devices.e1000e.Physical_Layer.e1000e_check_reset_block_generic 'Access,
                                                                   commit             => Devices.e1000e.Physical_Layer.e1000e_phy_sw_reset              'Access,
                                                                   force_speed_duplex => Devices.e1000e.Physical_Layer.e1000e_phy_force_speed_duplex_m88'Access,
                                                                   get_cfg_done       => Devices.e1000e.Physical_Layer.e1000e_get_cfg_done_generic      'Access,
                                                                   get_cable_length   => Devices.e1000e.Physical_Layer.e1000e_get_cable_length_m88      'Access,
                                                                   get_info           => Devices.e1000e.Physical_Layer.e1000e_get_phy_info_m88          'Access,
                                                                   read_reg           => Devices.e1000e.Physical_Layer.e1000e_read_phy_reg_bm2          'Access,
                                                                   release            => e1000_put_hw_semaphore_82571         'Access,
                                                                   reset              => Devices.e1000e.Physical_Layer.e1000e_phy_hw_reset_generic      'Access,
                                                                   set_d0_lplu_state  => e1000_set_d0_lplu_state_82571        'Access,
                                                                   set_d3_lplu_state  => Devices.e1000e.Physical_Layer.e1000e_set_d3_lplu_state         'Access,
                                                                   write_reg          => Devices.e1000e.Physical_Layer.e1000e_write_phy_reg_bm2         'Access,
                                                                   cfg_on_link_up     => null,
                                                                   set_page           => null,
                                                                   read_reg_locked    => null,
                                                                   read_reg_page      => null,
                                                                   write_reg_locked   => null,
                                                                   write_reg_page     => null,
                                                                   power_up           => null,
                                                                   power_down         => null);


   e1000_82574_info : aliased constant Devices.e1000e.Base.e1000_info.item := (mac                 => e1000_82574,
                                                                 flags               =>    FLAG_HAS_HW_VLAN_FILTER
                                                                                        or FLAG_HAS_MSIX
                                                                                        or FLAG_HAS_JUMBO_FRAMES
                                                                                        or FLAG_HAS_WOL
                                                                                        or FLAG_HAS_HW_TIMESTAMP
                                                                                        or FLAG_APME_IN_CTRL3
                                                                                        or FLAG_HAS_SMART_POWER_DOWN
                                                                                        or FLAG_HAS_AMT
                                                                                        or FLAG_HAS_CTRLEXT_ON_LOAD,
                                                                 flags2              =>    FLAG2_CHECK_PHY_HANG
                                                                                        or FLAG2_DISABLE_ASPM_L0S
                                                                                        or FLAG2_DISABLE_ASPM_L1
                                                                                        or FLAG2_NO_DISABLE_RX
                                                                                        or FLAG2_DMA_BURST
                                                                                        or FLAG2_CHECK_SYSTIM_OVERFLOW,
                                                                   pba               => 32,
                                                                   max_hw_frame_size => DEFAULT_JUMBO,
                                                                   get_variants      => e1000_get_variants_82571'Access,
                                                                   mac_ops           => e82571_mac_ops          'Access,
                                                                   phy_ops           => e82_phy_ops_bm          'Access,
                                                                   nvm_ops           => e82571_nvm_ops          'Access);
   --------------------
   --- e1000_82583_info
   --

   e1000_82583_info   : aliased constant Devices.e1000e.Base.e1000_info.item := (mac               => e1000_82583,
                                                                   flags             =>    FLAG_HAS_HW_VLAN_FILTER
                                                                                        or FLAG_HAS_WOL
                                                                                        or FLAG_HAS_HW_TIMESTAMP
                                                                                        or FLAG_APME_IN_CTRL3
                                                                                        or FLAG_HAS_SMART_POWER_DOWN
                                                                                        or FLAG_HAS_AMT
                                                                                        or FLAG_HAS_JUMBO_FRAMES
                                                                                        or FLAG_HAS_CTRLEXT_ON_LOAD,
                                                                   flags2            =>    FLAG2_DISABLE_ASPM_L0S
                                                                                        or FLAG2_DISABLE_ASPM_L1
                                                                                        or FLAG2_NO_DISABLE_RX
                                                                                        or FLAG2_CHECK_SYSTIM_OVERFLOW,
                                                                   pba               => 32,
                                                                   max_hw_frame_size => DEFAULT_JUMBO,
                                                                   get_variants      => e1000_get_variants_82571'Access,
                                                                   mac_ops           => e82571_mac_ops          'Access,
                                                                   phy_ops           => e82_phy_ops_bm          'Access,
                                                                   nvm_ops           => e82571_nvm_ops          'Access);
end Devices.e1000e.an_82571;
