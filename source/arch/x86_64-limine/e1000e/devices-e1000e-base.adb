with
     ada.Text_IO;


package body Devices.e1000e.Base
is
   use ada.Text_IO;


   -----------
   -- e_dbg --
   -----------

   procedure e_dbg (Message : in String)
   is
   begin
      put_Line ("DEBUG ~ " & Message);
   end e_dbg;



   -----------
   -- e_err --
   -----------

   procedure e_err (Message : in String) is
   begin
      put_Line ("ERROR ~ " & Message);
   end e_err;



   ------------
   -- e_info --
   ------------

   procedure e_info (Message : in String) is
   begin
      put_Line ("INFO ~ " & Message);
   end e_info;



   ------------
   -- e_warn --
   ------------

   procedure e_warn (Message : in String) is
   begin
      put_Line ("WARNING ~ " & Message);
   end e_warn;



   --------------
   -- e_notice --
   --------------

   procedure e_notice (Message : in String) is
   begin
      put_Line ("NOTICE ~ " & Message);
   end e_notice;


end Devices.e1000e.Base;
