with
     Devices.e1000e.Base.e1000_adapter;


package Devices.e1000e.Precision_Time_Protocol
is
   use Devices.e1000e.Base;



   procedure e1000e_ptp_init
     (Adapter : access e1000_adapter.item);


   procedure E1000e_Ptp_Remove
     (Adapter : access e1000_adapter.item);


end Devices.e1000e.Precision_Time_Protocol;
