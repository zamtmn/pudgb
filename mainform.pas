unit mainform;

{$mode delphi}{$H+}
{$DEFINE CHECKLOOPS}
{.$DEFINE GRAPHVIZUALIZER}

interface

uses
  LazUTF8,Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  ComCtrls, StdCtrls, ActnList, Menus, LCLIntf, Process,

  uzOIUI,uzObjectInspectorManager,uzOIDecorations,uzbUnits,uzObjectInspector,Varman,
  uzbUnitsUtils,UUnitManager,uzsbVarmanDef,uzOIEditors,UEnumDescriptor,

  XMLConf,XMLPropStorage,LazConfigStorage,

  {$IFDEF CHECKLOOPS}uchecker,{$ENDIF}
  {$IFDEF GRAPHVIZUALIZER}uvizualizer,{$ENDIF}uprojectoptions,uprogramoptions,
  uoptions,uscaner,uscanresult,uwriter,yEdWriter,ulpiimporter,udpropener,uexplorer;
  {$INCLUDE revision.inc}
  type

  { TForm1 }

  TForm1 = class(TForm)
    PrgOptsSave: TAction;
    PrgOptsLoad: TAction;
    PrjOptsSave: TAction;
    PrjOptsLoad: TAction;
    btnVizualize: TToolButton;
    MenuItem1: TMenuItem;
    MenuItem3: TMenuItem;
    mniSeparator01: TMenuItem;
    MenuItem2: TMenuItem;
    mniSeparator03: TMenuItem;
    MenuItem4: TMenuItem;
    Vizualize: TAction;
    Save: TAction;
    Check: TAction;
    Memo2: TMemo;
    Memo3: TMemo;
    Memo4: TMemo;
    OpenDPR: TAction;
    CodeExplorer: TAction;
    doExit: TAction;
    OpenWebGraphviz: TAction;
    PageControl1: TPageControl;
    SaveGML: TAction;
    ImportLPI: TAction;
    Scan: TAction;
    GenerateFullGraph: TAction;
    ActionList1: TActionList;
    GDBobjinsp1: TGDBobjinsp;
    MainMenu1: TMainMenu;
    Memo1: TMemo;
    mniFile: TMenuItem;
    mniScan: TMenuItem;
    mniGenerate: TMenuItem;
    mniSeparator02: TMenuItem;
    mniImportLPI: TMenuItem;
    mniSeparator04: TMenuItem;
    mniExit: TMenuItem;
    mniOpenDPR: TMenuItem;
    Splitter1: TSplitter;
    StatusBar1: TStatusBar;
    TabAll: TTabSheet;
    TabReport: TTabSheet;
    TabCircularGraph: TTabSheet;
    TabFullGraph: TTabSheet;
    ToolBar1: TToolBar;
    btnScan: TToolButton;
    btnGenerateFullGraph: TToolButton;
    btnImportLPI: TToolButton;
    btnGenerateGML: TToolButton;
    btnOpenWebGraViz: TToolButton;
    btnCodeExplorer: TToolButton;
    btnOpenDPR: TToolButton;
    btnCheckCircularDependecies: TToolButton;
    btnSave: TToolButton;
    procedure _CodeExplorer(Sender: TObject);
    procedure _Exit(Sender: TObject);
    procedure _PrgOptsLoad(Sender: TObject);
    procedure _PrgOptsSave(Sender: TObject);
    procedure _PrjOptsLoad(Sender: TObject);
    procedure _PrjOptsSave(Sender: TObject);
    procedure _SaveCurrentGraph(Sender: TObject);
    procedure _SaveGML(Sender: TObject);
    procedure _ImportLPI(Sender: TObject);
    procedure _OpenDPR(Sender: TObject);
    procedure _onClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure _onCreate(Sender: TObject);
    procedure _GenerateFullGraph(Sender: TObject);
    procedure _Scan(Sender: TObject);
    procedure _Check(Sender: TObject);
    procedure _OpenWebGraphviz(Sender: TObject);
    procedure _SetOptionFromUI(Sender: TObject);
    procedure _SetUIFromOption(Sender: TObject);
    procedure ActionUpdate(AAction: TBasicAction; var Handled: Boolean);
    procedure _Vizualize(Sender: TObject);
  private
    Options:TOptions;//Record with PProject and PProgram params, show in object inspector
    ScanResult:TScanResult;

    RunTimeUnit:ptunit;//Need for register types in object inspector
    UnitsFormat:TzeUnitsFormat;//Need for object inspector (number formats)
  public
    procedure DummyWriteToLog(msg:string; const LogOpt:TLogOpt);
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }
procedure TForm1._SetOptionFromUI(Sender: TObject);
begin
   //This procedure not need for object inspector
   //this need to old removed interface
   GDBobjinsp1.updateinsp;
end;
procedure TForm1._SetUIFromOption(Sender: TObject);
begin
   //This procedure not need for object inspector
   //this need to old removed interface
   GDBobjinsp1.updateinsp;
end;

procedure TForm1.ActionUpdate(AAction: TBasicAction; var Handled: Boolean);
begin
   Handled:=true;
   if AAction=Save then
     begin
       if (PageControl1.PageIndex=TabCircularGraph.TabIndex)or
          (PageControl1.PageIndex=TabFullGraph.TabIndex) then
                                                             TAction(AAction).Enabled:=true
                                                         else
                                                             TAction(AAction).Enabled:=false;
     end;
end;

procedure LoadPrgOpts(xmlfile:string;out Params:TProgramOptions);
var
  XMLConfig:TXMLConfig;
begin
  Params:=DefaultProgramOptions;
  XMLConfig:=TXMLConfig.Create(nil);
  XMLConfig.Filename:=xmlfile;

  XMLConfig.OpenKey('PUDGBProgramOptions');

    XMLConfig.OpenKey('Paths');
      Params.ProgPaths._PathToDot:=XMLConfig.GetValue('PathToDot',Params.ProgPaths._PathToDot);
      Params.ProgPaths._PathToLazarusConf:=XMLConfig.GetValue('PathToLazarusConf',Params.ProgPaths._PathToLazarusConf);
      Params.ProgPaths._Temp:=XMLConfig.GetValue('Temp',Params.ProgPaths._Temp);
    XMLConfig.CloseKey;

    XMLConfig.OpenKey('Behavior');
      Params.Behavior.AutoSelectPages:=XMLConfig.GetValue('AutoSelectPages',Params.Behavior.AutoSelectPages);
      Params.Behavior.AutoClearPages:=XMLConfig.GetValue('AutoClearPages',Params.Behavior.AutoClearPages);
    XMLConfig.CloseKey;

    XMLConfig.OpenKey('Logger');
      Params.Logger.ScanerMessages:=XMLConfig.GetValue('ScanerMessages',Params.Logger.ScanerMessages);
      Params.Logger.ParserMessages:=XMLConfig.GetValue('ParserMessages',Params.Logger.ParserMessages);
      Params.Logger.Timer:=XMLConfig.GetValue('Timer',Params.Logger.Timer);
      Params.Logger.Notfounded:=XMLConfig.GetValue('Notfounded',Params.Logger.Notfounded);
    XMLConfig.CloseKey;

  XMLConfig.CloseKey;
  FreeAndNil(XMLConfig);
end;

procedure LoadPrjOpts(xmlfile:string;out Params:TProjectOptions);
var
  XMLConfig:TXMLConfig;
begin
  Params:=DefaultProjectOptions;
  XMLConfig:=TXMLConfig.Create(nil);
  XMLConfig.Filename:=xmlfile;

  XMLConfig.OpenKey('PUDGBProjectOptions');

    XMLConfig.OpenKey('Paths');
      Params.Paths._File:=XMLConfig.GetValue('File',Params.Paths._File);
      Params.Paths._Paths:=XMLConfig.GetValue('Paths',Params.Paths._Paths);
    XMLConfig.CloseKey;

    XMLConfig.OpenKey('ParserOptions');
      Params.ParserOptions._CompilerOptions:=XMLConfig.GetValue('CompilerOptions',Params.ParserOptions._CompilerOptions);
      Params.ParserOptions.TargetOS:=XMLConfig.GetValue('TargetOS',Params.ParserOptions.TargetOS);
      Params.ParserOptions.TargetCPU:=XMLConfig.GetValue('TargetCPU',Params.ParserOptions.TargetCPU);
    XMLConfig.CloseKey;

    XMLConfig.OpenKey('GraphBulding');
      XMLConfig.OpenKey('CircularGraphOptions');
        Params.GraphBulding.CircularGraphOptions.CalcEdgesWeight:=XMLConfig.GetValue('CalcEdgesWeightU',Params.GraphBulding.CircularGraphOptions.CalcEdgesWeight);
      XMLConfig.CloseKey;
      XMLConfig.OpenKey('FullGraphOptions');
        XMLConfig.OpenKey('Clusters');
          Params.GraphBulding.FullGraphOptions.ClustersOptions.PathClusters:=XMLConfig.GetValue('PathClusters',Params.GraphBulding.FullGraphOptions.ClustersOptions.PathClusters);
          Params.GraphBulding.FullGraphOptions.ClustersOptions.CollapseClusters:=XMLConfig.GetValue('CollapseClusters',Params.GraphBulding.FullGraphOptions.ClustersOptions.CollapseClusters);
          Params.GraphBulding.FullGraphOptions.ClustersOptions.ExpandClusters:=XMLConfig.GetValue('ExpandClusters',Params.GraphBulding.FullGraphOptions.ClustersOptions.ExpandClusters);
          Params.GraphBulding.FullGraphOptions.ClustersOptions.LabelClustersEdges:=XMLConfig.GetValue('LabelClustersEdges',Params.GraphBulding.FullGraphOptions.ClustersOptions.LabelClustersEdges);
        XMLConfig.CloseKey;
        Params.GraphBulding.FullGraphOptions.IncludeNotFoundedUnits:=XMLConfig.GetValue('IncludeNotFoundedUnits',Params.GraphBulding.FullGraphOptions.IncludeNotFoundedUnits);
        Params.GraphBulding.FullGraphOptions.IncludeInterfaceUses:=XMLConfig.GetValue('IncludeInterfaceUses',Params.GraphBulding.FullGraphOptions.IncludeInterfaceUses);
        Params.GraphBulding.FullGraphOptions.IncludeImplementationUses:=XMLConfig.GetValue('IncludeImplementationUses',Params.GraphBulding.FullGraphOptions.IncludeImplementationUses);
        Params.GraphBulding.FullGraphOptions.IncludeOnlyCircularLoops:=XMLConfig.GetValue('IncludeOnlyCircularLoops',Params.GraphBulding.FullGraphOptions.IncludeOnlyCircularLoops);
        Params.GraphBulding.FullGraphOptions.IncludeToGraph:=XMLConfig.GetValue('IncludeToGraph',Params.GraphBulding.FullGraphOptions.IncludeToGraph);
        Params.GraphBulding.FullGraphOptions.ExcludeFromGraph:=XMLConfig.GetValue('ExcludeFromGraph',Params.GraphBulding.FullGraphOptions.ExcludeFromGraph);
        Params.GraphBulding.FullGraphOptions.OnlyDirectlyUses:=XMLConfig.GetValue('OnlyDirectlyUses',Params.GraphBulding.FullGraphOptions.OnlyDirectlyUses);
        Params.GraphBulding.FullGraphOptions.DstUnit:=XMLConfig.GetValue('DstUnit',Params.GraphBulding.FullGraphOptions.DstUnit);
        Params.GraphBulding.FullGraphOptions.SrcUnit:=XMLConfig.GetValue('SrcUnit',Params.GraphBulding.FullGraphOptions.SrcUnit);
      XMLConfig.CloseKey;
      Params.GraphBulding.InterfaceUsesEdgeType:=String2EdgeType(XMLConfig.GetValue('InterfaceUsesEdgeType',EdgeType2String(Params.GraphBulding.InterfaceUsesEdgeType)));
      Params.GraphBulding.ImplementationUsesEdgeType:=String2EdgeType(XMLConfig.GetValue('ImplementationUsesEdgeType',EdgeType2String(Params.GraphBulding.ImplementationUsesEdgeType)));
    XMLConfig.CloseKey;

  XMLConfig.CloseKey;
  FreeAndNil(XMLConfig);
end;

procedure TForm1._onCreate(Sender: TObject);
begin
  //setup default ProjectOptions
  //Options.ProjectOptions:=DefaultProjectOptions;
  LoadPrjOpts(ExtractFileDir(ParamStr(0))+pathdelim+'default.prjxml',Options.ProjectOptions);

  //setup default ProgramOptions
  //Options.ProgramOptions:=DefaultProgramOptions;
  LoadPrgOpts(ExtractFileDir(ParamStr(0))+pathdelim+'default.prgxml',Options.ProgramOptions);

   UnitsFormat:=CreateDefaultUnitsFormat;
   OIManager.INTFObjInspShowOnlyHotFastEditors:=false;

   with TComboBox.Create(NIL) do begin
     ParentWindow:=self.Handle;
     Hide;
     Application.ProcessMessages;
     OIManager.DefaultRowHeight:=Height;
   end;

   RunTimeUnit:=units.CreateUnit('',nil,'RunTimeUnit');//create empty zscript unit

   //register TProgramOptions in zscript unit
   RunTimeUnit^.RegisterType(TypeInfo(TProgramOptions));

   //register TProjectOptions in zscript unit
   RunTimeUnit^.RegisterType(TypeInfo(TProjectOptions));
   //Set params names
   RunTimeUnit^.SetTypeDesk(TypeInfo(TProgPaths),['PathToDot','PathToLazConfig','Temp']);
   RunTimeUnit^.SetTypeDesk(TypeInfo(TBehavior),['AutoSelectPages:','AutoClearPages']);

   RunTimeUnit^.SetTypeDesk(TypeInfo(TProjectOptions),['Paths','Parser options','Graph bulding','Log']);
   RunTimeUnit^.SetTypeDesk(TypeInfo(TPasPaths),['File','Paths']);
   RunTimeUnit^.SetTypeDesk(TypeInfo(TParser),['Compiler options','Target OS','Target CPU']);
   RunTimeUnit^.SetTypeDesk(TypeInfo(TGraphBulding),['Circular graph','Full graph','Interface uses edge type',
                                                     'Implementation uses edge type',{'Calc edges weight',}
                                                     'Path clusters',
                                                     'Collapse clusters mask',
                                                     'Expand clusters mask',
                                                     'Label clusters edges']);
   RunTimeUnit^.SetTypeDesk(TypeInfo(TClustersOptions),['Clusters','Collapse clusters mask','Expand clusters mask','Label clusters edges']);
   RunTimeUnit^.SetTypeDesk(TypeInfo(TCircularGraphOptions),['Calc edges weight']);
   RunTimeUnit^.SetTypeDesk(TypeInfo(TFullGraphOptions),['Clusters','Include not founded units','Include interface uses',
                                              'Include implementation uses','Only looped edges',
                                              'Include to graph','Exclude from graph',
                                              'Directly uses','Dest unit','Source unit']);

   RunTimeUnit^.SetTypeDesk(TypeInfo(TEdgeType),['Continuous','Dotted']);

   //Add standart and 'fast' editors for types showed in object inspector
   AddEditorToType(RunTimeUnit^.TypeName2PTD('Integer'),TBaseTypesEditors.BaseCreateEditor);//register standart editor to integer type
   AddEditorToType(RunTimeUnit^.TypeName2PTD('Double'),TBaseTypesEditors.BaseCreateEditor);//register standart editor to double type
   AddEditorToType(RunTimeUnit^.TypeName2PTD('AnsiString'),TBaseTypesEditors.BaseCreateEditor);//register standart editor to string type
   AddEditorToType(RunTimeUnit^.TypeName2PTD('String'),TBaseTypesEditors.BaseCreateEditor);//register standart editor to string type
   AddEditorToType(RunTimeUnit^.TypeName2PTD('Boolean'),TBaseTypesEditors.BooleanCreateEditor);//register standart editor to string type
   AddFastEditorToType(RunTimeUnit^.TypeName2PTD('Boolean'),@OIUI_FE_BooleanGetPrefferedSize,@OIUI_FE_BooleanDraw,@OIUI_FE_BooleanInverse);
   EnumGlobalEditor:=TBaseTypesEditors.EnumDescriptorCreateEditor;//register standart editor to all enum types

   //register TOptions in zscript unit
   RunTimeUnit^.RegisterType(TypeInfo(TOptions));
   RunTimeUnit^.SetTypeDesk(TypeInfo(TOptions),['Program options','Project options']);
   RunTimeUnit^.SetTypeDesk(TypeInfo(TLogger),['Scaner messages','Parser messages','Timer','Not founded units']);
   GDBobjinsp1.setptr(TDisplayedData.CreateRec(@Options,RunTimeUnit^.TypeName2PTD('TOptions'),nil,UnitsFormat));//show data variable in inspector
   caption:='pudgb v 0.99 rev:'+RevisionStr;
end;

procedure TForm1._onClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  //clean last scan result
  if assigned(ScanResult)then FreeAndNil(ScanResult);
end;

procedure TForm1._ImportLPI(Sender: TObject);
var
  od:TOpenDialog;
begin
   //Show open lpi file dialog
   od:=TOpenDialog.Create(nil);
   od.Title:='Import Lazarus project file';
   od.Filter:='Lazarus project files (*.lpi)|*.lpi|All files (*.*)|*.*';
   od.DefaultExt:='lpi';
   od.FilterIndex := 1;
   if od.Execute then
   begin
     LPIImport(Options,od.FileName,DummyWriteToLog);
   end;
   od.Free;
   _SetUIFromOption(nil);
end;

procedure TForm1._OpenDPR(Sender: TObject);
var
  od:TOpenDialog;
begin
   //Show open dpr file dialog
   od:=TOpenDialog.Create(nil);
   od.Title:='Open Dlphi project file';
   od.Filter:='Dlphi project files (*.dpr)|*.dpr|All files (*.*)|*.*';
   od.DefaultExt:='dpr';
   od.FilterIndex := 1;
   if od.Execute then
   begin
     DPROpen(Options.ProjectOptions,od.FileName,DummyWriteToLog);
   end;
   od.Free;
   _SetUIFromOption(nil);
end;
procedure TForm1._SaveGML(Sender: TObject);
begin
    //this not implemed yet
    WriteGML(Options.ProjectOptions,ScanResult,DummyWriteToLog);
end;

procedure TForm1._Vizualize(Sender: TObject);
var
  gvp:tprocess;
  AStringList:TStringList;
  infilename,outfilename:string;
begin
   {$IFDEF GRAPHVIZUALIZER}
   infilename:=options.ProgramOptions.ProgPaths._Temp+'pudgb.dot';
   outfilename:=options.ProgramOptions.ProgPaths._Temp+'pudgb.svg';
   memo3.Lines.SaveToFile(infilename);

   gvp:=TProcess.Create(nil);
   gvp.Executable:=Options.ProgramOptions.ProgPaths._PathToDot;
   gvp.Parameters.Add('-Tsvg');
   gvp.Parameters.Add('-o'+outfilename);
   gvp.Parameters.Add(infilename);
   gvp.Options := gvp.Options + [poUsePipes,poStderrToOutPut,poNoConsole,poWaitOnExit];
   gvp.Execute;
   gvp.Free;

   VizualiserForm:=TVizualiserForm(TVizualiserForm.NewInstance);
   VizualiserForm.InFile:=TMemoryStream.Create;
   VizualiserForm.InFile.LoadFromFile(outfilename);
   VizualiserForm.VisBackend:=Options.ProgramOptions.Visualizer.VisBackend;
   VizualiserForm.Create(nil);
   VizualiserForm.ShowModal;
   VizualiserForm.Free;
   {$ELSE}
   Application.MessageBox('Please set "GRAPHVIZUALIZER" conditional def in mainform.pas','');
   {$ENDIF}
end;

procedure TForm1._Exit(Sender: TObject);
begin
 close;
end;

procedure TForm1._PrgOptsLoad(Sender: TObject);
var
  od:TOpenDialog;
begin
   od:=TOpenDialog.Create(nil);
   od.Title:='Load program options';
   od.Filter:='Program options files (*.prgxml)|*.prgxml|All files (*.*)|*.*';
   od.DefaultExt:='prgxml';
   od.FilterIndex := 1;
   if od.Execute then begin
     LoadPrgOpts(od.FileName,Options.ProgramOptions);
     GDBobjinsp1.UpdateObjectInInsp;
   end;
   od.Free;
end;

procedure SaveProgramOptionsToConfig(Config:TConfigStorage;const Params,Defaults:TProgramOptions);
begin
  Config.AppendBasePath('PUDGBProgramOptions/');

    Config.AppendBasePath('Paths/');
      Config.SetDeleteValue('PathToDot',Params.ProgPaths._PathToDot,Defaults.ProgPaths._PathToDot);
      Config.SetDeleteValue('PathToLazarusConf',Params.ProgPaths._PathToLazarusConf,Defaults.ProgPaths._PathToLazarusConf);
      Config.SetDeleteValue('Temp',Params.ProgPaths._Temp,Defaults.ProgPaths._Temp);
    Config.UndoAppendBasePath;

    Config.AppendBasePath('Behavior/');
      Config.SetDeleteValue('AutoSelectPages',Params.Behavior.AutoSelectPages,Defaults.Behavior.AutoSelectPages);
      Config.SetDeleteValue('AutoClearPages',Params.Behavior.AutoClearPages,Defaults.Behavior.AutoClearPages);
    Config.UndoAppendBasePath;

    //Config.AppendBasePath('Visualizer/');
    //Config.UndoAppendBasePath;

    Config.AppendBasePath('Logger/');
      Config.SetDeleteValue('ScanerMessages',Params.Logger.ScanerMessages,Defaults.Logger.ScanerMessages);
      Config.SetDeleteValue('ParserMessages',Params.Logger.ParserMessages,Defaults.Logger.ParserMessages);
      Config.SetDeleteValue('Timer',Params.Logger.Timer,Defaults.Logger.Timer);
      Config.SetDeleteValue('Notfounded',Params.Logger.Notfounded,Defaults.Logger.Notfounded);
    Config.UndoAppendBasePath;

  Config.UndoAppendBasePath;
end;


procedure SavePrgOpts(xmlfile:string;const Params:TProgramOptions);
var
  XMLConfig: TXMLConfig;
  Config: TXMLConfigStorage;
begin
  If FileExists(xmlfile) then
    DeleteFile(xmlfile);
  XMLConfig:=TXMLConfig.Create(nil);
  try
    XMLConfig.StartEmpty:=true;
    XMLConfig.Filename:=xmlfile;
    Config:=TXMLConfigStorage.Create(XMLConfig);
    try
      SaveProgramOptionsToConfig(Config,Params,DefaultProgramOptions);
    finally
      Config.Free;
    end;
    //XMLConfig.Flush;
    if (XMLConfig.FileName<>'') then
      XMLConfig.SaveToFile(XMLConfig.Filename);
  finally
    XMLConfig.Free;
  end;
end;


procedure TForm1._PrgOptsSave(Sender: TObject);
var
  sd:TSaveDialog;
begin
   sd:=TSaveDialog.Create(nil);
   sd.Title:='Save program options';
   sd.Filter:='Program options files (*.prgxml)|*.prgxml|All files (*.*)|*.*';
   sd.DefaultExt:='prgxml';
   sd.FilterIndex := 1;
   if sd.Execute then
     SavePrgOpts(sd.FileName,Options.ProgramOptions);
   sd.Free;
end;

procedure TForm1._PrjOptsLoad(Sender: TObject);
var
  od:TOpenDialog;
begin
   od:=TOpenDialog.Create(nil);
   od.Title:='Load project options';
   od.Filter:='Project options files (*.prjxml)|*.prjxml|All files (*.*)|*.*';
   od.DefaultExt:='prjxml';
   od.FilterIndex := 1;
   if od.Execute then begin
     LoadPrjOpts(od.FileName,Options.ProjectOptions);
     GDBobjinsp1.UpdateObjectInInsp;
   end;
   od.Free;
end;

procedure SaveProjectOptionsToConfig(Config:TConfigStorage;const Params,Defaults:TProjectOptions);
begin
  Config.AppendBasePath('PUDGBProjectOptions/');

    Config.AppendBasePath('Paths/');
      Config.SetDeleteValue('File',Params.Paths._File,Defaults.Paths._File);
      Config.SetDeleteValue('Paths',Params.Paths._Paths,Defaults.Paths._Paths);
    Config.UndoAppendBasePath;

    Config.AppendBasePath('ParserOptions/');
      Config.SetDeleteValue('CompilerOptions',Params.ParserOptions._CompilerOptions,Defaults.ParserOptions._CompilerOptions);
      Config.SetDeleteValue('TargetOS',Params.ParserOptions.TargetOS,Defaults.ParserOptions.TargetOS);
      Config.SetDeleteValue('TargetCPU',Params.ParserOptions.TargetCPU,Defaults.ParserOptions.TargetCPU);
    Config.UndoAppendBasePath;

    Config.AppendBasePath('GraphBulding/');
      Config.AppendBasePath('CircularGraphOptions/');
        Config.SetDeleteValue('CalcEdgesWeight',Params.GraphBulding.CircularGraphOptions.CalcEdgesWeight,Defaults.GraphBulding.CircularGraphOptions.CalcEdgesWeight);
      Config.UndoAppendBasePath;

      Config.AppendBasePath('FullGraphOptions/');
        Config.AppendBasePath('Clusters/');
          Config.SetDeleteValue('PathClusters',Params.GraphBulding.FullGraphOptions.ClustersOptions.PathClusters,Defaults.GraphBulding.FullGraphOptions.ClustersOptions.PathClusters);
          Config.SetDeleteValue('CollapseClusters',Params.GraphBulding.FullGraphOptions.ClustersOptions.CollapseClusters,Defaults.GraphBulding.FullGraphOptions.ClustersOptions.CollapseClusters);
          Config.SetDeleteValue('ExpandClusters',Params.GraphBulding.FullGraphOptions.ClustersOptions.ExpandClusters,Defaults.GraphBulding.FullGraphOptions.ClustersOptions.ExpandClusters);
          Config.SetDeleteValue('LabelClustersEdges',Params.GraphBulding.FullGraphOptions.ClustersOptions.LabelClustersEdges,Defaults.GraphBulding.FullGraphOptions.ClustersOptions.LabelClustersEdges);
        Config.UndoAppendBasePath;
        Config.SetDeleteValue('IncludeNotFoundedUnits',Params.GraphBulding.FullGraphOptions.IncludeNotFoundedUnits,Defaults.GraphBulding.FullGraphOptions.IncludeNotFoundedUnits);
        Config.SetDeleteValue('IncludeInterfaceUses',Params.GraphBulding.FullGraphOptions.IncludeInterfaceUses,Defaults.GraphBulding.FullGraphOptions.IncludeInterfaceUses);
        Config.SetDeleteValue('IncludeImplementationUses',Params.GraphBulding.FullGraphOptions.IncludeImplementationUses,Defaults.GraphBulding.FullGraphOptions.IncludeImplementationUses);
        Config.SetDeleteValue('IncludeOnlyCircularLoops',Params.GraphBulding.FullGraphOptions.IncludeOnlyCircularLoops,Defaults.GraphBulding.FullGraphOptions.IncludeOnlyCircularLoops);
        Config.SetDeleteValue('IncludeToGraph',Params.GraphBulding.FullGraphOptions.IncludeToGraph,Defaults.GraphBulding.FullGraphOptions.IncludeToGraph);
        Config.SetDeleteValue('ExcludeFromGraph',Params.GraphBulding.FullGraphOptions.ExcludeFromGraph,Defaults.GraphBulding.FullGraphOptions.ExcludeFromGraph);
        Config.SetDeleteValue('OnlyDirectlyUses',Params.GraphBulding.FullGraphOptions.OnlyDirectlyUses,Defaults.GraphBulding.FullGraphOptions.OnlyDirectlyUses);
        Config.SetDeleteValue('DstUnit',Params.GraphBulding.FullGraphOptions.DstUnit,Defaults.GraphBulding.FullGraphOptions.DstUnit);
        Config.SetDeleteValue('SrcUnit',Params.GraphBulding.FullGraphOptions.SrcUnit,Defaults.GraphBulding.FullGraphOptions.SrcUnit);
      Config.UndoAppendBasePath;

      Config.SetDeleteValue('InterfaceUsesEdgeType',EdgeType2String(Params.GraphBulding.InterfaceUsesEdgeType),EdgeType2String(Defaults.GraphBulding.InterfaceUsesEdgeType));
      Config.SetDeleteValue('ImplementationUsesEdgeType',EdgeType2String(Params.GraphBulding.ImplementationUsesEdgeType),EdgeType2String(Defaults.GraphBulding.ImplementationUsesEdgeType));
    Config.UndoAppendBasePath;

  Config.UndoAppendBasePath;
end;

procedure SavePrjOpts(xmlfile:string;const Params:TProjectOptions);
var
  XMLConfig: TXMLConfig;
  Config: TXMLConfigStorage;
begin
  If FileExists(xmlfile) then
    DeleteFile(xmlfile);
  XMLConfig:=TXMLConfig.Create(nil);
  try
    XMLConfig.StartEmpty:=true;
    XMLConfig.Filename:=xmlfile;
    Config:=TXMLConfigStorage.Create(XMLConfig);
    try
      SaveProjectOptionsToConfig(Config,Params,DefaultProjectOptions);
    finally
      Config.Free;
    end;
    //XMLConfig.Flush;
    if (XMLConfig.FileName<>'') then
      XMLConfig.SaveToFile(XMLConfig.Filename);
  finally
    XMLConfig.Free;
  end;
end;


procedure TForm1._PrjOptsSave(Sender: TObject);
var
  sd:TSaveDialog;
begin
   sd:=TSaveDialog.Create(nil);
   sd.Title:='Save project options';
   sd.Filter:='Project options files (*.prjxml)|*.prjxml|All files (*.*)|*.*';
   sd.DefaultExt:='prjxml';
   sd.FilterIndex := 1;
   if sd.Execute then
     SavePrjOpts(sd.FileName,Options.ProjectOptions);
   sd.Free;
end;

procedure TForm1._SaveCurrentGraph(Sender: TObject);
var
  sd:TSaveDialog;
begin
   //Show save current graph dialog
   sd:=TSaveDialog.Create(nil);
   sd.Title:='Save *.dot graph file';
   sd.Filter:='Dot files (*.dot)|*.dot|All files (*.*)|*.*';
   sd.DefaultExt:='dot';
   sd.FilterIndex := 1;
   if sd.Execute then
   begin
     if PageControl1.PageIndex=TabCircularGraph.TabIndex then
       Memo3.Lines.SaveToFile(sd.FileName)
else if PageControl1.PageIndex=TabFullGraph.TabIndex then
       Memo4.Lines.SaveToFile(sd.FileName);
   end;
   sd.Free;
end;

procedure TForm1._CodeExplorer(Sender: TObject);
begin
 //this not implemed yet
 ExploreCode(Options.ProjectOptions,ScanResult,DummyWriteToLog);
end;

procedure TForm1._GenerateFullGraph(Sender: TObject);
begin
   //write full graph to memo
   if not assigned(ScanResult) then begin
     _Scan(nil);
     _Check(nil);
   end else
     if (not assigned(ScanResult.G))or(not assigned(ScanResult.M))then
       _Check(nil);
   if Options.ProgramOptions.Behavior.AutoSelectPages then
     Memo4.Show;
   WriteGraph(Options.ProjectOptions,ScanResult,DummyWriteToLog);
end;
procedure TForm1._Scan(Sender: TObject);
var
  cd:ansistring;
begin
   cd:=GetCurrentDir;
   SetCurrentDir(ExtractFileDir(Options.ProjectOptions.Paths._File));

   if assigned(ScanResult)then FreeAndNil(ScanResult);//clean last scan result
   ScanResult:=TScanResult.Create;//create new scan result
   DummyWriteToLog('Start scan sources!',[LD_Clear,LD_Report]);
   if FileExists(Options.ProjectOptions.Paths._File)then
    ScanModule(Options.ProjectOptions.Paths._File,Options,ScanResult,DummyWriteToLog)//try parse main sources file
   else
    ScanDirectory(Options.ProjectOptions.Paths._File,Options,ScanResult,DummyWriteToLog);//try parse sources folder

   SetCurrentDir(cd);
end;
procedure TForm1._Check(Sender: TObject);
begin
   {$IFDEF CHECKLOOPS}
   if not assigned(ScanResult) then
     _Scan(nil);
   if Options.ProgramOptions.Behavior.AutoSelectPages then
     Memo3.Show;
   CheckGraph(Options.ProjectOptions,ScanResult,DummyWriteToLog);
   {$ENDIF}
end;
procedure TForm1._OpenWebGraphviz(Sender: TObject);
begin
  OpenURL('http://www.webgraphviz.com');
end;
procedure TForm1.DummyWriteToLog(msg:string; const LogOpt:TLogOpt);
var
  NeedClear:boolean;
begin
   //remap log messages to memo`s
   if (LD_Clear in LogOpt)and(Options.ProgramOptions.Behavior.AutoClearPages) then
    NeedClear:=true
   else
    NeedClear:=false;

   Memo1.Append(msg);
   if LD_Report in LogOpt then
     begin
       if NeedClear then
         Memo2.Lines.Clear;
       Memo2.Append(msg);
     end;
   if LD_FullGraph in LogOpt then
     begin
       if NeedClear then
         Memo4.Lines.Clear;
       Memo4.Append(msg);
     end;
   if LD_CircGraph in LogOpt then
     begin
       if NeedClear then
         Memo3.Lines.Clear;
       Memo3.Append(msg);
     end;
end;
end.

