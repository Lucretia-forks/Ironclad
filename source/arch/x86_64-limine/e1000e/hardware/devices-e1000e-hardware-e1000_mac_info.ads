with
     Devices.e1000e.Hardware.e1000_mac_operations,
     Devices.e1000e.Core;


package Devices.e1000e.Hardware.e1000_mac_info
is
   use Interfaces.C,
       Devices.e1000e.Core;


   MAX_MTA_REG : constant := 128;     -- Maximum size of the MTA register table in all supported adapters.


   -- Item
   --

   type Item is
      record
         ops                 : aliased Devices.e1000e.Hardware.e1000_mac_operations.Item;
         addr                : aliased u8_array (0 .. 5);
         perm_addr           : aliased u8_array (0 .. 5);
         mac_type            : aliased Devices.e1000e.Hardware.e1000_mac_type;
         collision_delta     : aliased u32;
         ledctl_default      : aliased u32;
         ledctl_mode1        : aliased u32;
         ledctl_mode2        : aliased u32;
         mc_filter_type      : aliased u32;
         tx_packet_delta     : aliased u32;
         txcw                : aliased u32;
         current_ifs_val     : aliased u16;
         ifs_max_val         : aliased u16;
         ifs_min_val         : aliased u16;
         ifs_ratio           : aliased u16;
         ifs_step_size       : aliased u16;
         mta_reg_count       : aliased u16;
         mta_shadow          : aliased u32_array (0 .. MAX_MTA_REG - 1);
         rar_entry_count     : aliased u16;
         forced_speed_duplex : aliased u8;
         adaptive_ifs        : aliased Boolean;
         has_fwsm            : aliased Boolean;
         arc_subsystem_valid : aliased Boolean;
         autoneg             : aliased Boolean;
         autoneg_failed      : aliased Boolean;
         get_link_status     : aliased Boolean;
         in_ifs_mode         : aliased Boolean;
         serdes_has_link     : aliased Boolean;
         tx_pkt_filtering    : aliased Boolean;
         serdes_link_state   : aliased Devices.e1000e.Hardware.e1000_serdes_link_state;
      end record;


   -- Item_Array
   --
   type Item_Array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_mac_info.Item;


end Devices.e1000e.Hardware.e1000_mac_info;
