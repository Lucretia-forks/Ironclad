with
     Devices.e1000e.Hardware.e1000_phy_operations,
     Devices.e1000e.Core;


package Devices.e1000e.Hardware.e1000_phy_info
is
   use Devices.e1000e.Core;


   -- Item
   --
   type Item is
      record
         ops                         : aliased Devices.e1000e.Hardware.e1000_phy_operations.Item;
         phy_type                    : aliased Devices.e1000e.Hardware.e1000_phy_type;
         local_rx                    : aliased Devices.e1000e.Hardware.e1000_1000t_rx_status;
         remote_rx                   : aliased Devices.e1000e.Hardware.e1000_1000t_rx_status;
         ms_type                     : aliased Devices.e1000e.Hardware.e1000_ms_type;
         original_ms_type            : aliased Devices.e1000e.Hardware.e1000_ms_type;
         cable_polarity              : aliased Devices.e1000e.Hardware.e1000_rev_polarity;
         smart_speed                 : aliased Devices.e1000e.Hardware.e1000_smart_speed;
         addr                        : aliased u32;
         id                          : aliased u32;
         reset_delay_us              : aliased u32;                 -- In uSec.
         revision                    : aliased u32;
         retry_count                 : aliased u32;
         media_type                  : aliased Devices.e1000e.Hardware.e1000_media_type;
         autoneg_advertised          : aliased u16;
         autoneg_mask                : aliased u16;
         cable_length                : aliased u16;
         max_cable_length            : aliased u16;
         min_cable_length            : aliased u16;
         mdix                        : aliased u8;
         disable_polarity_correction : aliased Boolean;
         is_mdix                     : aliased Boolean;
         polarity_correction         : aliased Boolean;
         speed_downgraded            : aliased Boolean;
         autoneg_wait_to_complete    : aliased Boolean;
         retry_enabled               : aliased Boolean;
      end record;


   -- Item_Array
   --
   type Item_Array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_phy_info.Item;


end Devices.e1000e.Hardware.e1000_phy_info;
