with
     Devices.e1000e.Core,
     Devices.e1000e.Base.e1000_adapter,
     Linux,
     Interfaces;


package Devices.e1000e.NetDev
is
   use Devices.e1000e.Base,
       Interfaces;



   procedure dummy;



   function E1000e_Get_Base_Timinca
     (Adapter : access E1000_Adapter.item;
      Timinca : access Interfaces.Unsigned_32) return Devices.e1000e.Core.s32;


   function E1000e_Read_Systim
     (Adapter : access E1000_Adapter.item;
      Sts     : access linux.PTP_System_Timestamp) return Unsigned_64;


end Devices.e1000e.NetDev;
