with
     Devices.e1000e.Base.e1000_ring,
     Devices.e1000e.Hardware.E1000_Tx_Desc,
     Devices.e1000e.Hardware.E1000_Rx_Desc_Extended,
     Devices.e1000e.Hardware.e1000_context_desc,
     Devices.e1000e.Hardware.E1000_Rx_Desc_Packet_Split,
     System;


package Devices.e1000e.Base.Utility
is

   --  #define E1000_RX_DESC_PS(R, i)      \
   --    (&(((union e1000_rx_desc_packet_split *)((R).desc))[i]))

   function E1000_RX_DESC_PS
     (R : in Devices.e1000e.Base.e1000_ring.item;
      i : in Integer) return access Devices.e1000e.Hardware.E1000_Rx_Desc_Packet_Split.item;



   --  #define E1000_RX_DESC_EXT(R, i)     \
   --       (&(((union e1000_rx_desc_extended *)((R).desc))[i]))

   function E1000_RX_DESC_EXT
     (R : in Devices.e1000e.Base.e1000_ring.item;
      i : in Integer) return access Devices.e1000e.Hardware.E1000_Rx_Desc_Extended.item;



   --  #define E1000_GET_DESC(R, i, type) (&(((struct type *)((R).desc))[i]))

   --  function E1000_GET_DESC
   --    (R      : in e1000.e1000_ring.item;
   --     i      : in Integer;
   --     a_type : in system.Address) return system.Address;



   --  #define E1000_TX_DESC(R, i)     E1000_GET_DESC(R, i, e1000_tx_desc)

   function E1000_TX_DESC
     (R : in Devices.e1000e.Base.e1000_ring.item;
      i : in Integer) return access Devices.e1000e.Hardware.E1000_Tx_Desc.item;



   --  #define E1000_CONTEXT_DESC(R, i)   E1000_GET_DESC(R, i, e1000_context_desc)

   function E1000_CONTEXT_DESC
     (R : in Devices.e1000e.Base.e1000_ring.item;
      i : in Integer) return access Devices.e1000e.Hardware.e1000_context_desc.item;


end Devices.e1000e.Base.Utility;
