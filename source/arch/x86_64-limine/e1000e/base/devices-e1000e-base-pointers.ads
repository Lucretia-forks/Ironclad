with
     Interfaces.C.Pointers,
     Linux;


package Devices.e1000e.Base.Pointers
is
   use Interfaces.C;


   -- net_device_Pointer
   --
   package C_net_device_Pointers is new Interfaces.C.Pointers (Index              => Interfaces.C.size_t,
                                                               Element            => linux.net_device,
                                                               Element_Array      => linux.net_device_array,
                                                               Default_Terminator => (others => <>));

   subtype net_device_Pointer is C_net_device_Pointers.Pointer;

   -- net_device_Pointer_Array
   --
   type net_device_Pointer_Array is
     array
       (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Base.Pointers.net_device_Pointer;




   -- rtnl_link_stats64_Pointer
   --
   package C_rtnl_link_stats64_Pointers is new Interfaces.C.Pointers (Index              => Interfaces.C.size_t,
                                                                      Element            => linux.rtnl_link_stats64,
                                                                      Element_Array      => linux.rtnl_link_stats64_array,
                                                                      Default_Terminator => (others => <>));

   subtype rtnl_link_stats64_Pointer is C_rtnl_link_stats64_Pointers.Pointer;


   -- rtnl_link_stats64_Pointer_Array
   --
   type rtnl_link_stats64_Pointer_Array is
     array
       (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Base.Pointers.rtnl_link_stats64_Pointer;




   -- ptp_system_timestamp_Pointer
   --
   package C_ptp_system_timestamp_Pointers is new Interfaces.C.Pointers (Index              => Interfaces.C.size_t,
                                                                         Element            => linux.ptp_system_timestamp,
                                                                         Element_Array      => linux.ptp_system_timestamp_array,
                                                                         Default_Terminator => (others => <>));

   subtype ptp_system_timestamp_Pointer is C_ptp_system_timestamp_Pointers.Pointer;


   -- ptp_system_timestamp_Pointer_Array
   --
   type ptp_system_timestamp_Pointer_Array is
     array
       (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Base.Pointers.ptp_system_timestamp_Pointer;


end Devices.e1000e.Base.Pointers;
