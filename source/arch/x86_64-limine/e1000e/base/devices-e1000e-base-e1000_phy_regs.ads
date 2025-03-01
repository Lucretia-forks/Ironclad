with
     Devices.e1000e.Core;


package Devices.e1000e.Base.e1000_phy_regs
--
-- PHY register snapshot values.
--
is
   -- Item
   --

   type Item is record
      bmcr      : aliased Devices.e1000e.Core.u16;     -- Basic mode control register.
      bmsr      : aliased Devices.e1000e.Core.u16;     -- Basic mode status register.
      advertise : aliased Devices.e1000e.Core.u16;     -- Auto-negotiation advertisement.
      lpa       : aliased Devices.e1000e.Core.u16;     -- Link partner ability register.
      expansion : aliased Devices.e1000e.Core.u16;     -- Auto-negotiation expansion reg.
      ctrl1000  : aliased Devices.e1000e.Core.u16;     -- 1000BASE-T control register.
      stat1000  : aliased Devices.e1000e.Core.u16;     -- 1000BASE-T status register.
      estatus   : aliased Devices.e1000e.Core.u16;     -- Extended status register.
   end record;

   -- Item_Array
   --
   type Item_Array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Base.e1000_phy_regs.Item;


end Devices.e1000e.Base.e1000_phy_regs;
