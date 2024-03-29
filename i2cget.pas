unit i2cget;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  GlobalConst,
  SysUtils,
  Devices,
  I2C,
  Shell;

var
   I2CDevice:PI2CDevice;
   Temp:Word;
   i2caddress:Word;
   i2cregister:Byte;
   Count:LongWord;
   Data:LongWord;


type
  //Create a class for our shell command, descended from TShellCommand
  TShellCommandi2cget = class(TShellCommand)
  public
   constructor Create;
  private

  public
   //Override the DoHelp, DoInfo and DoCommand methods
   function DoHelp(AShell:TShell;ASession:TShellSession):Boolean; override;
   function DoInfo(AShell:TShell;ASession:TShellSession):Boolean; override;
   function DoCommand(AShell:TShell;ASession:TShellSession;AParameters:TStrings):Boolean; override;
  end;

implementation

constructor TShellCommandi2cget.Create;
begin
 {}
 inherited Create;

 //In the Create() method we have to set the name of our commmand

 //Name is the name of the command, eg what the user has to type
 Name:='I2CGET';

 //Flags tell the shell if this command provides help or info
 Flags:=SHELL_COMMAND_FLAG_INFO or SHELL_COMMAND_FLAG_HELP;
end;

function TShellCommandi2cget.DoHelp(AShell:TShell;ASession:TShellSession):Boolean;
begin
 //The DoHelp method is called when someone types HELP <COMMAND>
 Result:=False;

 if AShell = nil then Exit;

 AShell.DoOutput(ASession,'i2cget chipaddress registeraddress');
 AShell.DoOutput(ASession,'i2cget 0x00 0x00');

 {Return Result}
 Result:=True;

end;

function TShellCommandi2cget.DoInfo(AShell:TShell;ASession:TShellSession):Boolean;
begin
 //The DoInfo method is called when someone types INFO or INFO <COMMAND>
 Result:=False;

 if AShell = nil then Exit;

 Result:=AShell.DoOutput(ASession,'Gets i2c chip register byte values');
end;

function TShellCommandi2cget.DoCommand(AShell:TShell;ASession:TShellSession;AParameters:TStrings):Boolean;
var
 Value:String;
 Parameter:String;
begin
 //The DoCommand method is called when someone types our command in the shell
 //We also get any parameters they added in the AParameters object
 Result:=False;

 try
   if AShell = nil then Exit;

   Value:=' ';
   I2CDevice:=PI2CDevice(DeviceFindByDescription('BCM2835 BSC1 Master I2C'));
   //Get the parameter (if any)
   Parameter:=AShell.ParameterIndex(0,AParameters);
   if Length(Parameter) > 0 then
    begin
     Value:=' ' + Parameter + ' ';
     i2caddress:=StrToInt(Parameter);
    end;

   Parameter:=AShell.ParameterIndex(1,AParameters);
   if Length(Parameter) > 0 then
    begin
     Value:=' ' + Parameter + ' ';
     i2cregister:=StrToInt(Parameter);
    end;

   if I2CDeviceStart(I2CDevice,100000) <> ERROR_SUCCESS then
    begin
         //Error Occurred
         Value:='i2c error!!';
    end
   else
    begin
     //No  error, ready to use I2C
     Count:=1;

     if I2CDeviceWriteRead(I2CDevice,i2caddress,@i2cregister, 1, @Data,1, Count) = ERROR_SUCCESS then
        begin
              Value:= IntToStr(Data);
        end;

   end;
   //Output the result and we are done
   Result:=AShell.DoOutput(ASession, 'Address= ' + IntToStr(i2caddress)+ ' Register= ' + IntToStr(i2cregister) + ' Value= ' + Value);
 except
   //Inside the try..except we can add things we want to happen before the method exits, like logging or cleanup.
    //Let's log the exception so we can see it.
   on E: Exception do
    begin
     AShell.DoOutput(ASession, 'Error in command ' + E.Message);
    end;
 end;

end;

initialization
 //Register our new shell command so it is available in any shell
 ShellRegisterCommand(TShellCommandi2cget.Create);

end.
