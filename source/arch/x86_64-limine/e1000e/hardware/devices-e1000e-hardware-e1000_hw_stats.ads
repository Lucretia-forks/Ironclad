with
     Devices.e1000e.Core;


package Devices.e1000e.Hardware.e1000_hw_stats
--
-- Statistics counters collected by the MAC.
--
is
   use Devices.e1000e.Core;


   -- Item
   --

   type Item is
      record
         crcerrs  : aliased u64;
         algnerrc : aliased u64;
         symerrs  : aliased u64;
         rxerrc   : aliased u64;
         mpc      : aliased u64;
         scc      : aliased u64;
         ecol     : aliased u64;
         mcc      : aliased u64;
         latecol  : aliased u64;
         colc     : aliased u64;
         dc       : aliased u64;
         tncrs    : aliased u64;
         sec      : aliased u64;
         cexterr  : aliased u64;
         rlec     : aliased u64;
         xonrxc   : aliased u64;
         xontxc   : aliased u64;
         xoffrxc  : aliased u64;
         xofftxc  : aliased u64;
         fcruc    : aliased u64;
         prc64    : aliased u64;
         prc127   : aliased u64;
         prc255   : aliased u64;
         prc511   : aliased u64;
         prc1023  : aliased u64;
         prc1522  : aliased u64;
         gprc     : aliased u64;
         bprc     : aliased u64;
         mprc     : aliased u64;
         gptc     : aliased u64;
         gorc     : aliased u64;
         gotc     : aliased u64;
         rnbc     : aliased u64;
         ruc      : aliased u64;
         rfc      : aliased u64;
         roc      : aliased u64;
         rjc      : aliased u64;
         mgprc    : aliased u64;
         mgpdc    : aliased u64;
         mgptc    : aliased u64;
         tor      : aliased u64;
         tot      : aliased u64;
         tpr      : aliased u64;
         tpt      : aliased u64;
         ptc64    : aliased u64;
         ptc127   : aliased u64;
         ptc255   : aliased u64;
         ptc511   : aliased u64;
         ptc1023  : aliased u64;
         ptc1522  : aliased u64;
         mptc     : aliased u64;
         bptc     : aliased u64;
         tsctc    : aliased u64;
         tsctfc   : aliased u64;
         iac      : aliased u64;
         icrxptc  : aliased u64;
         icrxatc  : aliased u64;
         ictxptc  : aliased u64;
         ictxatc  : aliased u64;
         ictxqec  : aliased u64;
         ictxqmtc : aliased u64;
         icrxdmtc : aliased u64;
         icrxoc   : aliased u64;
      end record;


   -- Item_Array
   --
   type Item_Array is
     array (Interfaces.C.size_t range <>) of aliased Devices.e1000e.Hardware.e1000_hw_stats.Item;


end Devices.e1000e.Hardware.e1000_hw_stats;
