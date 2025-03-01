with
     Devices.e1000e.Core.Pointers,
     Devices.e1000e.Manage,
     Devices.e1000e.Media_Access_Control,
     Devices.e1000e.Physical_Layer,
     Devices.e1000e.Non_Volatile_Memory,
     Devices.e1000e.Hardware.e1000_hw,
     Devices.e1000e.Hardware.e1000_mac_operations,
     Devices.e1000e.Hardware.e1000_phy_operations,
     Devices.e1000e.Hardware.e1000_nvm_operations,
     Devices.e1000e.Base.e1000_info,
     Devices.e1000e.Base.e1000_adapter,
     Interfaces;


package Devices.e1000e.an_80003es2lan
--
-- 80003ES2LAN Gigabit Ethernet Controller (Copper)
-- 80003ES2LAN Gigabit Ethernet Controller (Serdes)
--
is
   use Devices.e1000e.Core;

   subtype e1000_hw is Devices.e1000e.Hardware.e1000_hw.item;


   E1000_KMRNCTRLSTA_OFFSET_FIFO_CTRL       : constant := 16#0#;
   E1000_KMRNCTRLSTA_OFFSET_INB_CTRL        : constant := 16#2#;
   E1000_KMRNCTRLSTA_OFFSET_HD_CTRL         : constant := 16#10#;
   E1000_KMRNCTRLSTA_OFFSET_MAC2PHY_OPMODE  : constant := 16#1f#;


   E1000_KMRNCTRLSTA_FIFO_CTRL_RX_BYPASS    : constant := 16#8#;
   E1000_KMRNCTRLSTA_FIFO_CTRL_TX_BYPASS    : constant := 16#800#;
   E1000_KMRNCTRLSTA_INB_CTRL_DIS_PADDING   : constant := 16#10#;


   E1000_KMRNCTRLSTA_HD_CTRL_10_100_DEFAULT : constant := 16#4#;
   E1000_KMRNCTRLSTA_HD_CTRL_1000_DEFAULT   : constant := 16#0#;
   E1000_KMRNCTRLSTA_OPMODE_E_IDLE          : constant := 16#2000#;


   E1000_KMRNCTRLSTA_OPMODE_MASK            : constant := 16#c#;
   E1000_KMRNCTRLSTA_OPMODE_INBAND_MDIO     : constant := 16#4#;


   E1000_TCTL_EXT_GCEX_MASK                 : constant := 16#f_fc00#;     -- Gig Carry Extend Padding.
   DEFAULT_TCTL_EXT_GCEX_80003ES2LAN        : constant := 16#1_0000#;



   DEFAULT_TIPG_IPGT_1000_80003ES2LAN       : constant := 16#8#;
   DEFAULT_TIPG_IPGT_10_100_80003ES2LAN     : constant := 16#9#;


   -- GG82563 PHY Specific Status Register (Page 0, Register 16).
   --
   GG82563_PSCR_POLARITY_REVERSAL_DISABLE   : constant := 16#2#;          -- 1=Reversal Dis.
   GG82563_PSCR_CROSSOVER_MODE_MASK         : constant := 16#60#;
   GG82563_PSCR_CROSSOVER_MODE_MDI          : constant := 16#0#;          -- 00=Manual MDI.
   GG82563_PSCR_CROSSOVER_MODE_MDIX         : constant := 16#20#;         -- 01=Manual MDIX.
   GG82563_PSCR_CROSSOVER_MODE_AUTO         : constant := 16#60#;         -- 11=Auto crossover.


   -- PHY Specific Control Register 2 (Page 0, Register 26).
   --
   GG82563_PSCR2_REVERSE_AUTO_NEG           : constant := 16#2000#;       -- 1=Reverse Auto-Neg.


   -- MAC Specific Control Register (Page 2, Register 21)
   -- Tx clock speed for Link Down and 1000BASE-T for the following speeds:
   --
   GG82563_MSCR_TX_CLK_MASK                 : constant := 16#7#;
   GG82563_MSCR_TX_CLK_10MBPS_2_5           : constant := 16#4#;
   GG82563_MSCR_TX_CLK_100MBPS_25           : constant := 16#5#;
   GG82563_MSCR_TX_CLK_1000MBPS_25          : constant := 16#7#;


   GG82563_MSCR_ASSERT_CRS_ON_TX            : constant := 16#10#;         -- 1=Assert.


   -- DSP Distance Register (Page 5, Register 26).
   --
   -- 0 = <50M
   -- 1 = 50-80M
   -- 2 = 80-100M
   -- 3 = 110-140M
   -- 4 = >140M
   --
   GG82563_DSPD_CABLE_LENGTH                : constant := 16#7#;


   -- Kumeran Mode Control Register (Page 193, Register 16).
   --
   GG82563_KMCR_PASS_FALSE_CARRIER          : constant := 16#800#;


   -- Max number of times Kumeran read/write should be validated.
   --
   GG82563_MAX_KMRN_RETRY                   : constant := 16#5#;


   -- Power Management Control Register (Page 193, Register 20).
   -- 1=Enable SERDES Electrical Idle
   --
   GG82563_PMCR_ENABLE_ELECTRICAL_IDLE      : constant := 16#1#;


   -- In-Band Control Register (Page 194, Register 18).
   --
   GG82563_ICR_DIS_PADDING                  : constant := 16#10#;         -- Disable Padding




   --------
   --- Info
   --

   e1000_es2_info : aliased constant Devices.e1000e.Base.e1000_info.item;





private

   use Devices.e1000e.Base,
       Devices.e1000e.Hardware,
       Devices.e1000e.Core.Pointers;


   ------------------
   --- e1000_es2_info
   --

   function  e1000_get_variants_80003es2lan   (adapter : access e1000_adapter.item) return s32;
   function  e1000_read_mac_addr_80003es2lan  (hw : access e1000_hw) return s32;
   function  e1000_reset_hw_80003es2lan       (hw : access e1000_hw) return s32;
   function  e1000_init_hw_80003es2lan        (hw : access e1000_hw) return s32;

   procedure e1000_clear_hw_cntrs_80003es2lan (hw : access e1000_hw);

   function  e1000_get_link_up_info_80003es2lan (hw     : access e1000_hw;
                                                 speed  : in     u16_Pointer;
                                                 duplex : in     u16_Pointer) return s32;


   es2_mac_ops : aliased constant e1000_mac_operations.item := (read_mac_addr            => e1000_read_mac_addr_80003es2lan         'Access,
                                                                id_led_init              => Devices.e1000e.Media_Access_Control.e1000e_id_led_init_generic          'Access,
                                                                blink_led                => Devices.e1000e.Media_Access_Control.e1000e_blink_led_generic            'Access,
                                                                check_mng_mode           => Devices.e1000e.Manage.e1000e_check_mng_mode_generic    'Access,
                                                                check_for_link           => <>,     -- Dependent on media type.
                                                                cleanup_led              => Devices.e1000e.Media_Access_Control.e1000e_cleanup_led_generic          'Access,
                                                                clear_hw_cntrs           => e1000_clear_hw_cntrs_80003es2lan        'Access,
                                                                get_bus_info             => Devices.e1000e.Media_Access_Control.e1000e_get_bus_info_pcie            'Access,
                                                                set_lan_id               => Devices.e1000e.Media_Access_Control.e1000_set_lan_id_multi_port_pcie    'Access,
                                                                get_link_up_info         => e1000_get_link_up_info_80003es2lan      'Access,
                                                                led_on                   => Devices.e1000e.Media_Access_Control.e1000e_led_on_generic               'Access,
                                                                led_off                  => Devices.e1000e.Media_Access_Control.e1000e_led_off_generic              'Access,
                                                                update_mc_addr_list      => Devices.e1000e.Media_Access_Control.e1000e_update_mc_addr_list_generic  'Access,
                                                                write_vfta               => Devices.e1000e.Media_Access_Control.e1000_write_vfta_generic            'Access,
                                                                clear_vfta               => Devices.e1000e.Media_Access_Control.e1000_clear_vfta_generic            'Access,
                                                                reset_hw                 => e1000_reset_hw_80003es2lan              'Access,
                                                                init_hw                  => e1000_init_hw_80003es2lan               'Access,
                                                                setup_link               => Devices.e1000e.Media_Access_Control.e1000e_setup_link_generic           'Access,
                                                                setup_physical_interface => <>,     -- Dependent on media type.
                                                                setup_led                => Devices.e1000e.Media_Access_Control.e1000e_setup_led_generic            'Access,
                                                                config_collision_dist    => Devices.e1000e.Media_Access_Control.e1000e_config_collision_dist_generic'Access,
                                                                rar_set                  => Devices.e1000e.Media_Access_Control.e1000e_rar_set_generic              'Access,
                                                                rar_get_count            => Devices.e1000e.Media_Access_Control.e1000e_rar_get_count_generic        'Access
                                                               );


   function  e1000_acquire_phy_80003es2lan            (hw : access e1000_hw) return s32;
   function  e1000_phy_force_speed_duplex_80003es2lan (hw : access e1000_hw) return s32;
   function  e1000_get_cfg_done_80003es2lan           (hw : access e1000_hw) return s32;
   function  e1000_get_cable_length_80003es2lan       (hw : access e1000_hw) return s32;

   function  e1000_read_phy_reg_gg82563_80003es2lan   (hw     : access e1000_hw;
                                                       offset : in     u32;
                                                       data   : in     u16_Pointer) return s32;

   procedure e1000_release_phy_80003es2lan            (hw : access e1000_hw);


   function  e1000_write_phy_reg_gg82563_80003es2lan  (hw     : access e1000_hw;
                                                       offset : in     u32;
                                                       data   : in     u16)      return s32;
   function  e1000_cfg_on_link_up_80003es2lan         (hw     : access e1000_hw) return s32;


   es2_phy_ops : aliased constant e1000_phy_operations.item := (acquire            => e1000_acquire_phy_80003es2lan           'Access,
                                                                check_polarity     => Devices.e1000e.Physical_Layer.e1000_check_polarity_m88                'Access,
                                                                check_reset_block  => Devices.e1000e.Physical_Layer.e1000e_check_reset_block_generic        'Access,
                                                                commit             => Devices.e1000e.Physical_Layer.e1000e_phy_sw_reset                     'Access,
                                                                force_speed_duplex => e1000_phy_force_speed_duplex_80003es2lan'Access,
                                                                get_cfg_done       => e1000_get_cfg_done_80003es2lan          'Access,
                                                                get_cable_length   => e1000_get_cable_length_80003es2lan      'Access,
                                                                get_info           => Devices.e1000e.Physical_Layer.e1000e_get_phy_info_m88                 'Access,
                                                                read_reg           => e1000_read_phy_reg_gg82563_80003es2lan  'Access,
                                                                release            => e1000_release_phy_80003es2lan           'Access,
                                                                reset              => Devices.e1000e.Physical_Layer.e1000e_phy_hw_reset_generic             'Access,
                                                                set_d0_lplu_state  => null,
                                                                set_d3_lplu_state  => Devices.e1000e.Physical_Layer.e1000e_set_d3_lplu_state                'Access,
                                                                write_reg          => e1000_write_phy_reg_gg82563_80003es2lan 'Access,
                                                                cfg_on_link_up     => e1000_cfg_on_link_up_80003es2lan        'Access,
                                                                set_page           => null,
                                                                read_reg_locked    => null,
                                                                read_reg_page      => null,
                                                                write_reg_locked   => null,
                                                                write_reg_page     => null,
                                                                power_up           => null,
                                                                power_down         => null);


   function  e1000_acquire_nvm_80003es2lan (hw     : access e1000_hw) return s32;
   function  e1000_write_nvm_80003es2lan   (hw     : access e1000_hw;
                                            offset : in     u16;
                                            words  : in     u16;
                                            data   : in     u16_Pointer) return s32;

   procedure e1000_release_nvm_80003es2lan (hw : access e1000_hw);


   es2_nvm_ops : aliased constant e1000_nvm_operations.item := (acquire           => e1000_acquire_nvm_80003es2lan       'Access,
                                                                read              => Devices.e1000e.Non_Volatile_Memory.e1000e_read_nvm_eerd                'Access,
                                                                release           => e1000_release_nvm_80003es2lan       'Access,
                                                                reload            => Devices.e1000e.Non_Volatile_Memory.e1000e_reload_nvm_generic           'Access,
                                                                update            => Devices.e1000e.Non_Volatile_Memory.e1000e_update_nvm_checksum_generic  'Access,
                                                                valid_led_default => Devices.e1000e.Non_Volatile_Memory.e1000e_valid_led_default            'Access,
                                                                validate          => Devices.e1000e.Non_Volatile_Memory.e1000e_validate_nvm_checksum_generic'Access,
                                                                write             => e1000_write_nvm_80003es2lan         'Access);

   use type Interfaces.Unsigned_32;


   e1000_es2_info : aliased constant Devices.e1000e.Base.e1000_info.Item := (mac               => e1000_80003es2lan,
                                                               flags             =>    FLAG_HAS_HW_VLAN_FILTER
                                                                                    or FLAG_HAS_JUMBO_FRAMES
                                                                                    or FLAG_HAS_WOL
                                                                                    or FLAG_APME_IN_CTRL3
                                                                                    or FLAG_HAS_CTRLEXT_ON_LOAD
                                                                                    or FLAG_RX_NEEDS_RESTART           -- errata
                                                                                    or FLAG_TARC_SET_BIT_ZERO          -- errata
                                                                                    or FLAG_APME_CHECK_PORT_B
                                                                                    or FLAG_DISABLE_FC_PAUSE_TIME,     -- errata
                                                               flags2            =>    FLAG2_DMA_BURST,
                                                               pba               => 38,
                                                               max_hw_frame_size => DEFAULT_JUMBO,
                                                               get_variants      => e1000_get_variants_80003es2lan'Access,
                                                               mac_ops           => es2_mac_ops                   'Access,
                                                               phy_ops           => es2_phy_ops                   'Access,
                                                               nvm_ops           => es2_nvm_ops                   'Access);

end Devices.e1000e.an_80003es2lan;
