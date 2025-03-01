package body Devices.e1000e.Base.Utility
is

   ----------------------
   -- E1000_RX_DESC_PS --
   ----------------------

   --  #define E1000_RX_DESC_PS(R, i)
   --    ( &( ( (union e1000_rx_desc_packet_split*) ((R).desc)) [i]
   --       )
   --    )


   function E1000_RX_DESC_PS
     (R : in Devices.e1000e.Base.e1000_ring.item;
      i : in Integer) return access Devices.e1000e.Hardware.E1000_Rx_Desc_Packet_Split.item
   is
      Index         : constant C.size_t := C.size_t (i);
      packet_Splits :          Devices.e1000e.Hardware.E1000_Rx_Desc_Packet_Split.item_array (0 .. Index)
        with
          Address => R.desc;
   begin
      return packet_Splits (Index)'unchecked_Access;     -- TODO: Check this !
   end E1000_RX_DESC_PS;




   -----------------------
   -- E1000_RX_DESC_EXT --
   -----------------------

   --  #define E1000_RX_DESC_EXT(R, i)
   --       (&(((union e1000_rx_desc_extended *)((R).desc))[i]))


   function E1000_RX_DESC_EXT
     (R : in Devices.e1000e.Base.e1000_ring.item;
      i : in Integer) return access Devices.e1000e.Hardware.E1000_Rx_Desc_Extended.item
   is
      Index : constant C.size_t := C.size_t (i);
      Descs :          Devices.e1000e.Hardware.E1000_Rx_Desc_Extended.item_array (0 .. Index)
        with
          Address => R.desc;
   begin
      return Descs (Index)'unchecked_Access;     -- TODO: Check this !
   end E1000_RX_DESC_EXT;




   --------------------
   -- E1000_GET_DESC --
   --------------------

   --  #define E1000_GET_DESC(R, i, type)
   --     ( &( ((struct type*) ((R).desc)) [i])
   --     )

   --  function E1000_GET_DESC
   --    (R      : in e1000.e1000_ring.item;
   --     i      : in Integer;
   --     a_type : in system.Address) return system.Address
   --  is
   --  begin
   --     pragma Compile_Time_Warning
   --       (Standard.True, "E1000_GET_DESC unimplemented");
   --     return raise Program_Error with "Unimplemented function E1000_GET_DESC";
   --  end E1000_GET_DESC;




   -------------------
   -- E1000_TX_DESC --
   -------------------

   --  #define E1000_TX_DESC(R, i)
   --      E1000_GET_DESC (R, i, e1000_tx_desc)


   function E1000_TX_DESC
     (R : in Devices.e1000e.Base.e1000_ring.item;
      i : in Integer) return access Devices.e1000e.Hardware.E1000_Tx_Desc.item
   is
      Index : constant C.size_t := C.size_t (i);
      Descs :          Devices.e1000e.Hardware.e1000_tx_desc.item_array (0 .. Index)
        with
          Address => R.desc;
   begin
      return Descs (Index)'unchecked_Access;     -- TODO: Check this !
   end E1000_TX_DESC;




   ------------------------
   -- E1000_CONTEXT_DESC --
   ------------------------

   --  #define E1000_CONTEXT_DESC(R, i)   E1000_GET_DESC(R, i, e1000_context_desc)


   function E1000_CONTEXT_DESC
     (R : in Devices.e1000e.Base.e1000_ring.item;
      i : in Integer) return access Devices.e1000e.Hardware.e1000_context_desc.item
   is
      Index : constant C.size_t := C.size_t (i);
      Descs :          Devices.e1000e.Hardware.e1000_context_desc.item_array (0 .. Index)
        with
          Address => R.desc;
   begin
      return Descs (Index)'unchecked_Access;     -- TODO: Check this !
   end E1000_CONTEXT_DESC;


end Devices.e1000e.Base.Utility;
