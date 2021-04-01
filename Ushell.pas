program Ushell;

{$mode objfpc}{$H+}

{ Raspberry Pi Application                                                     }
{  Add your program code below, add additional units to the "uses" section if  }
{  required and create new units by selecting File, New Unit from the menu.    }
{                                                                              }
{  To compile your program select Run, Compile (or Run, Build) from the menu.  }

uses
  //QEMUVersatilePB,
  RaspberryPi,
  Devices,
  GlobalConfig,
  GlobalConst,
  GlobalTypes,
  GPIO,
  Platform,
  Threads,
  SysUtils,
  Classes,
  IniFiles,
  I2C,
  //HD44780,
  HTTP,
  Winsock2,
  WebStatus,
  Console,
  ConsoleShell,
  RemoteShell,
  ShellFilesystem,
  ShellUpdate,
  i2cset,
  i2cget,
  ioset,
  i2cdetect,
  Heapmanager,
  Ultibo,
  Logging

  { Add additional units here };




const
 //This value must not conflict with any of the HEAP_FLAG_ values in HeapManager
 HEAP_FLAG_CUSTOM  = $08000000;


var
 //INI: TINIFile;
 IPAddress:String;
 WindowHandle:TWindowHandle;
 WindowHandle2:TWindowHandle;
 Winsock2TCPClient:TWinsock2TCPClient;
 ConsoleDevice:PConsoleDevice;

 Listener:THTTPListener;

 I2CDevice:PI2CDevice;
 Address:Word;
 Numbytes:LongWord;
 Register:LongWord;
 Data:Word;
 DataStr:String;
 Hexadd:String;
 Hexdata:String;

 RequestAddress:PtrUInt;
 ActualAddress:PtrUInt;


 pinnum:Word;
 alt:Word;
 level:Word;


 procedure edge_callback(Data:Pointer;Pin,Trigger:LongWord);
var
   status:LongWord;
begin
    if (Trigger=GPIO_TRIGGER_EDGE) then
    begin
        status:=GPIOInputGet(Pin);
        GPIOOutputSet(GPIO_PIN_10, status);
        ConsoleWindowWriteLn(WindowHandle,'Triggered');
        GPIOInputEvent(GPIO_PIN_9, GPIO_TRIGGER_EDGE, INFINITE, @edge_callback, nil);
    end;

end;


begin
 { Add your program code here }
  {Override some default values}
 WINDOW_DEFAULT_FORECOLOR:=COLOR_WHITE;
 WINDOW_DEFAULT_BACKCOLOR:=COLOR_BLACK;

 WindowHandle:=ConsoleWindowCreate(ConsoleDeviceGetDefault,CONSOLE_POSITION_TOPLEFT,True);
 WindowHandle2:=ConsoleWindowCreate(ConsoleDeviceGetDefault,CONSOLE_POSITION_BOTTOMLEFT,True);

 //Request the heap manager to reserve a 64KB block of memory starting at 0x10000000
  //The size can be any amount that is a power of 2 (must be more than 32 bytes)
  //The address must be a multiple of HEAP_REQUEST_ALIGNMENT which is normally 4KB
  RequestAddress:=$10000000;

  //Call RequestHeapBlock to reserve the memory, if it returns the same address we requested then it was successful
  ActualAddress:=PtrUInt(RequestHeapBlock(Pointer(RequestAddress), SIZE_1M, HEAP_FLAG_CUSTOM, CPU_AFFINITY_NONE));

  if ActualAddress <> RequestAddress then
   begin
     //Error, block could not be reserved
     ConsoleWindowWriteLn(WindowHandle,'Error, block could not be reserved');
   end
  else
   begin
     //Success, the block can be used. You MUST NOT use the first 32 bytes!
     //Each of the pages can now be marked as PAGE_TABLE_FLAG_EXECUTABLE
      ConsoleWindowWriteLn(WindowHandle,'Memory block reserved');
   end;

  Data := 566;
  DataStr:= IntToStr(Data);
  ConsoleWindowWriteLn(WindowHandle,'GPIO pin levels = ' + DataStr);

 {To prove that worked let's output some text on the console window}
 ConsoleWindowWriteLn(WindowHandle,'Ultibo Shell for Testing');

  {Update our second window console}
 ConsoleWindowWriteLn(WindowHandle,'Shell commands');



 {Get our default console device}
 ConsoleDevice:=ConsoleDeviceGetDefault;
 CONSOLE_SHELL_POSITION:=CONSOLE_POSITION_LEFT;
  {Force creation of a new shell window}
 ConsoleShellDeviceAdd(ConsoleDevice,True);

 {Create a Winsock2TCPClient so that we can get some local information}
 Winsock2TCPClient:=TWinsock2TCPClient.Create;

 {Print our host name on the screen}
 ConsoleWindowWriteLn(WindowHandle,'Host name is ' + Winsock2TCPClient.LocalHost);

 {Get our local IP address which may be invalid at this point}
 IPAddress:=Winsock2TCPClient.LocalAddress;

 {Check the local IP address}
 if (IPAddress = '') or (IPAddress = '0.0.0.0') or (IPAddress = '255.255.255.255') then
  begin
   ConsoleWindowWriteLn(WindowHandle,'IP address is ' + IPAddress);
   ConsoleWindowWriteLn(WindowHandle,'Waiting for a valid IP address, make sure the network is connected');

   {Wait until we have an IP address}
   while (IPAddress = '') or (IPAddress = '0.0.0.0') or (IPAddress = '255.255.255.255') do
    begin
     {Sleep a bit}
     Sleep(1000);

     {Get the address again}
     IPAddress:=Winsock2TCPClient.LocalAddress;
    end;
  end;

 {Print our IP address on the screen}
 ConsoleWindowWriteLn(WindowHandle,'IP address is ' + IPAddress);
 ConsoleWindowWriteLn(WindowHandle,'');

 {Create our web interface}
 {An instance of the THTTPListener class}
 Listener:=THTTPListener.Create;
 Listener.BoundPort:=12345;      //Set the port for the HTTP server
 Listener.Active:=True;
 {Register the web status unit with our listener}
 WebStatusRegister(Listener,'','',True);

 ConsoleWindowWriteLn(WindowHandle,'');

 {We may need to wait a couple of seconds for any drive to be ready}
 ConsoleWindowWriteLn(WindowHandle,'Waiting for drive C:\');
 while not DirectoryExists('C:\') do
  begin
   {Sleep for a second}
   Sleep(1000);
  end;
 ConsoleWindowWriteLn(WindowHandle,'C:\ drive is ready');
 ConsoleWindowWriteLn(WindowHandle,'');

 GPIOFunctionSelect(GPIO_PIN_9, GPIO_FUNCTION_IN);
 GPIOFunctionSelect(GPIO_PIN_10, GPIO_FUNCTION_OUT);
 GPIODeviceInputEvent(GPIODeviceGetDefault, GPIO_PIN_9, GPIO_TRIGGER_EDGE, GPIO_EVENT_FLAG_REPEAT, INFINITE, @edge_callback, nil);



 I2CDevice:=PI2CDevice(DeviceFindByDescription('BCM2835 BSC1 Master I2C'));

 while True do
  begin
  if I2CDeviceStart(I2CDevice,100000) <> ERROR_SUCCESS then
       begin
            //Error Occurred
           ConsoleWindowWriteLn(WindowHandle,'i2c error!!');
       end
  else
      ConsoleWindowWriteLn(WindowHandle,'i2c device found!!');
      for Address:=$01 to $7f do
          begin
              Numbytes:=1;
              Register:=0;
              if I2CDeviceWriteRead(I2CDevice,Address,@Register, Numbytes, @Data,SizeOf(Byte),Numbytes) = ERROR_SUCCESS then
                 begin
                     Hexadd:=IntToHex(Address, 2);
                     //ConsoleWindowWrite(WindowHandle, ' 0x' + Hexadd);
                     Hexdata:=IntToHex(Data, 2);
                     ConsoleWindowWrite(WindowHandle, ' 0x' + Hexadd + ' 0x' + Hexdata );
                     ConsoleWindowWriteLn(WindowHandle,'');
                 end;
              end;
         Sleep(3000);
      end;
 //   ConsoleWindowWriteLn(WindowHandle, ' ');
 //   ConsoleWindowWriteLn(WindowHandle, ' ');
   Sleep(3000);
   //while True do
   //begin


   //   for pinnum:= 0 to 10 do
   //       begin
   //            alt:=GPIOFunctionGet(pinnum);
   //            level:=GPIOInputGet(pinnum);
   //            ConsoleWindowWriteLn(WindowHandle, 'gpio pin=' + IntToStr(pinnum) + ' level=' + IntToStr(level) + ' alt=' + IntToStr(alt));
   //       end;
   // ConsoleWindowWriteLn(WindowHandle, ' ');
   // ConsoleWindowWriteLn(WindowHandle, ' ');
  // Sleep(20000);
 //end;

 {Halt the thread, the web server will still be available}
 ThreadHalt(0);

end.


