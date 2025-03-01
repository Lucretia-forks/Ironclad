package body Devices.e1000e.Core
is

   protected body Mutex
   is

      entry acquire when Available
      is
      begin
         Available := False;
      end acquire;


      procedure release
      is
      begin
         Available := True;
      end release;

   end Mutex;


end Devices.e1000e.Core;
