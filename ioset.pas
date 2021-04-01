unit ioset;

{$mode objfpc}{$H+}

interface

uses
  //BCM2708,
  Platform,
  Classes,
  GlobalConst,
  SysUtils,
  Devices,
  GPIO,
  Shell;

var

   Temp:Word;
   IOpin:LongWord;
   IOlevel:LongWord;
   Count:LongWord;
   Data:LongWord;


type
  //Create a class for our shell command, descended from TShellCommand
  TShellCommandioset = class(TShellCommand)
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

constructor TShellCommandioset.Create;
begin
 {}
 inherited Create;

 //In the Create() method we have to set the name of our command

 //Name is the name of the command, eg what the user has to type
 Name:='IOSET';

 //Flags tell the shell if this command provides help or info
 Flags:=SHELL_COMMAND_FLAG_INFO or SHELL_COMMAND_FLAG_HELP;
end;

function TShellCommandioset.DoHelp(AShell:TShell;ASession:TShellSession):Boolean;
begin
 //The DoHelp method is called when someone types HELP <COMMAND>
 Result:=False;

 AShell.DoOutput(ASession,'ioset GPIOnumber 0-low, 1-high');
 AShell.DoOutput(ASession,'ioset 22 1');

 {Return Result}
 Result:=True;

end;

function TShellCommandioset.DoInfo(AShell:TShell;ASession:TShellSession):Boolean;
begin
 //The DoInfo method is called when someone types INFO or INFO <COMMAND>
 Result:=False;

 if AShell = nil then Exit;

 Result:=AShell.DoOutput(ASession,'Sets and Clears GPIO pins');
end;

function TShellCommandioset.DoCommand(AShell:TShell;ASession:TShellSession;AParameters:TStrings):Boolean;
var
 Value1:String;
 Value2:String;
 Parameter:String;
begin
 //The DoCommand method is called when someone types our command in the shell
 //We also get any parameters they added in the AParameters object
 Result:=False;
 try
   if AShell = nil then Exit;

   Value1:=' ';
   Value2:=' ';

   //Get the parameter (if any)
   Parameter:=AShell.ParameterIndex(0,AParameters);
   if Length(Parameter) > 0 then
    begin
     Value1:= Parameter;
     IOpin:= StrToInt64(Value1);
    end;

   Parameter:=AShell.ParameterIndex(1,AParameters);
   if Length(Parameter) > 0 then
    begin
     Value2:= Parameter;
     IOlevel:= StrToInt64(Value2);
    end;
   GPIOFunctionSelect(IOpin,GPIO_FUNCTION_OUT);
   GPIOOutputSet(IOpin,IOlevel);

   //Output the result and we are done
   Result:=AShell.DoOutput(ASession, 'GPIO= ' + Value1 +  ' Level= ' + Value2);

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
 ShellRegisterCommand(TShellCommandioset.Create);

end.

