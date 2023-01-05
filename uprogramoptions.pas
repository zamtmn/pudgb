unit uprogramoptions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  {$Z1}
  TProgPaths=packed record
    _PathToDot:String;
    _PathToLazarusConf:String;
    _Temp:String;
  end;
  TVisBackend=(VB_GDI,VB_Opengl);
  TVisualizer=packed record
    VisBackend:TVisBackend;
  end;
  TLogger=packed record
    ScanerMessages:Boolean;
    ParserMessages:Boolean;
    Timer:Boolean;
    Notfounded:Boolean;
  end;
  TBehavior=packed record
    AutoSelectPages:Boolean;
    AutoClearPages:Boolean;
  end;
  PTProgramOptions=^TProgramOptions;
  TProgramOptions=packed record
    ProgPaths:TProgPaths;
    Behavior:TBehavior;
    Visualizer:TVisualizer;
    Logger:TLogger;
  end;
function DefaultProgramOptions:TProgramOptions;
implementation
function DefaultProgramOptions:TProgramOptions;
begin
  //setup default ProgramOptions
  Result.ProgPaths._PathToDot:='E:\Program Files (x86)\Graphviz2.38\bin\dot.exe';
{$ifdef windows}
  Result.ProgPaths._PathToLazarusConf:=GetEnvironmentVariable('LOCALAPPDATA')+'\lazarus';
{$elseif}
  Result.ProgPaths._PathToLazarusConf:='~/.lazarus';
{$endif}
  Result.ProgPaths._Temp:=GetTempDir;
  Result.Behavior.AutoClearPages:=true;
  Result.Behavior.AutoSelectPages:=true;
  Result.Visualizer.VisBackend:=VB_GDI;
  Result.Logger.ScanerMessages:=false;
  Result.Logger.ParserMessages:=false;
  Result.Logger.Timer:=true;
  Result.Logger.Notfounded:=false;
end;
end.

