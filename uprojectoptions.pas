unit uprojectoptions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

const
  ETContinuousName='Continuous';
  ETDottedName='Dotted';
  ETUCDottedName='DOTTED';

type
  {$Z1}
  TPasPaths=packed record
    _File:String;
    _Paths:String;
  end;
  TParser=packed record
    _CompilerOptions:String;
    TargetOS,TargetCPU:String;
  end;
  TCircularGraphOptions=packed record
    CalcEdgesWeight:Boolean;
  end;
  TClustersOptions=packed record
    PathClusters:Boolean;
    CollapseClusters:string;
    ExpandClusters:string;
    LabelClustersEdges:Boolean;
  end;
  TFullGraphOptions=packed record
    ClustersOptions:TClustersOptions;
    IncludeNotFoundedUnits:Boolean;
    IncludeInterfaceUses:Boolean;
    IncludeImplementationUses:Boolean;
    IncludeOnlyCircularLoops:Boolean;
    IncludeToGraph:string;
    ExcludeFromGraph:string;
    OnlyDirectlyUses:Boolean;
    DstUnit:string;
    SrcUnit:string;
  end;
  TEdgeType=(ETContinuous,ETDotted);
  TGraphBulding=packed record
    CircularGraphOptions:TCircularGraphOptions;
    FullGraphOptions:TFullGraphOptions;
    InterfaceUsesEdgeType:TEdgeType;
    ImplementationUsesEdgeType:TEdgeType;
  end;
  PTProjectOptions=^TProjectOptions;
  TProjectOptions=packed record
    Paths:TPasPaths;
    ParserOptions:TParser;
    GraphBulding:TGraphBulding;
  end;

  TLogDir=(LD_Clear,LD_Report,LD_FullGraph,LD_CircGraph,LD_Explorer);
  TLogOpt=set of TLogDir;
  TLogWriter=procedure(msg:string; const LogOpt:TLogOpt) of object;

function DefaultProjectOptions:TProjectOptions;
function GetCompilerDefs:String;
function EdgeType2String(ET:TEdgeType):String;
function String2EdgeType(ETn:String):TEdgeType;

implementation
function EdgeType2String(ET:TEdgeType):String;
begin
 case ET of
   ETContinuous:result:=ETContinuousName;
   ETDotted:result:=ETDottedName;
 end;
end;

function String2EdgeType(ETn:String):TEdgeType;
begin
 if UpperCase(ETn)=ETUCDottedName then
   result:=ETDotted
 else
   result:=ETContinuous;
end;

function GetCompilerDefs:String;
procedure adddef(def:string);
begin
 if result='' then
                  result:=format('-d%s',[def])
              else
                  result:=result+format(' -d%s',[def]);
end;
begin
 result:='';
 {$ifdef LINUX}adddef('LINUX');{$endif}
 {$ifdef WINDOWS}adddef('WINDOWS');{$endif}
 {$ifdef MSWINDOWS}adddef('MSWINDOWS');{$endif}
 {$ifdef WIN32}adddef('WIN32');{$endif}
 {$ifdef LCLWIN32}adddef('LCLWIN32');{$endif}
 {$ifdef FPC}adddef('FPC');{$endif}
 {$ifdef CPU64}adddef('CPU64');{$endif}
 {$ifdef CPU32}adddef('CPU32');{$endif}

 {$ifdef LCLWIN32}adddef('LCLWIN32');{$endif}
 {$ifdef LCLQT}adddef('LCLQT');{$endif}
 {$ifdef LCLQT5}adddef('LCLQT5');{$endif}
 {$ifdef LCLGTK2}adddef('LCLGTK2');{$endif}
end;

function DefaultProjectOptions:TProjectOptions;
begin
  result.Paths._File:=ExtractFileDir(ParamStr(0))+pathdelim+'passrcerrors.pas';
  result.Paths._Paths:=ExtractFileDir(ParamStr(0));


  result.ParserOptions._CompilerOptions:='-Sc '+GetCompilerDefs;
  result.ParserOptions.TargetOS:={$I %FPCTARGETOS%};
  result.ParserOptions.TargetCPU:={$I %FPCTARGETCPU%};

  result.GraphBulding.FullGraphOptions.IncludeToGraph:='';
  result.GraphBulding.FullGraphOptions.ExcludeFromGraph:='';
  result.GraphBulding.FullGraphOptions.IncludeNotFoundedUnits:=false;
  result.GraphBulding.FullGraphOptions.IncludeInterfaceUses:=true;
  result.GraphBulding.InterfaceUsesEdgeType:=ETContinuous;
  result.GraphBulding.FullGraphOptions.IncludeImplementationUses:=true;
  result.GraphBulding.ImplementationUsesEdgeType:=ETDotted;
  result.GraphBulding.FullGraphOptions.ClustersOptions.PathClusters:=true;
  result.GraphBulding.FullGraphOptions.ClustersOptions.CollapseClusters:='';
  result.GraphBulding.FullGraphOptions.ClustersOptions.ExpandClusters:='';
  result.GraphBulding.FullGraphOptions.ClustersOptions.LabelClustersEdges:=false;
  result.GraphBulding.FullGraphOptions.IncludeOnlyCircularLoops:=false;
  result.GraphBulding.FullGraphOptions.OnlyDirectlyUses:=false;
  result.GraphBulding.CircularGraphOptions.CalcEdgesWeight:=false;
end;

end.

