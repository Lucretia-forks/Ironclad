with
     Devices.e1000e.Core;


package Devices.e1000e.Hardware.e1000_fc_info
is
   -- Item
   --

   type Item is
      record
         high_water     : aliased Devices.e1000e.Core.u32;             -- Flow control high-water mark.
         low_water      : aliased Devices.e1000e.Core.u32;             -- Flow control low-water mark.
         pause_time     : aliased Devices.e1000e.Core.u16;             -- Flow control pause timer.
         refresh_time   : aliased Devices.e1000e.Core.u16;             -- Flow control refresh timer.
         send_xon       : aliased Boolean;              -- Flow control send XON.
         strict_ieee    : aliased Boolean;              -- Strict IEEE mode.
         current_mode   : aliased Devices.e1000e.Hardware.e1000_fc_mode;     -- FC mode in effect.
         requested_mode : aliased Devices.e1000e.Hardware.e1000_fc_mode;     -- FC mode requested by caller.
      end record;


   -- Item_Array
   --
   type Item_Array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_fc_info.Item;


end Devices.e1000e.Hardware.e1000_fc_info;
