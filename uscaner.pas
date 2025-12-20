unit uscaner;

{$mode objfpc}{$H+}

interface
uses
  LazUTF8,Classes, SysUtils,
  uoptions,uprojectoptions,uscanresult,ufileutils,
  PScanner, PParser, PasTree, Masks;

type
  TRawByteStringArray = Array of RawByteString;
    TSimpleEngine = class(TPasTreeContainer)
    private
    uname:string;
    public
    LogWriter:TLogWriter;

    constructor Create(const Options:TOptions;const _LogWriter:TLogWriter);
    destructor Destroy;override;
    Procedure Log(Sender : TObject; Const Msg : String);

    function CreateElement(AClass: TPTreeElement; const AName: String;
      AParent: TPasElement; AVisibility: TPasMemberVisibility;
      const ASourceFilename: String; ASourceLinenumber: Integer): TPasElement;
      override;
    function FindElement(const AName: String): TPasElement; override;
    end;
    TPrepareMode = (PMProgram,PMInterface,PMImplementation);

procedure GetDecls(PM:TPrepareMode;Decl:TPasDeclarations;Options:TOptions;ScanResult:TScanResult;UnitIndex:TUnitIndex;const LogWriter:TLogWriter);
procedure ScanModule(mn:String;Options:TOptions;ScanResult:TScanResult;const LogWriter:TLogWriter);
procedure ScanDirectory(mn:String;Options:TOptions;ScanResult:TScanResult;const LogWriter:TLogWriter);

implementation

destructor TSimpleEngine.Destroy;
begin
  LogWriter(format('unit(%s).Destroy',[uname]),[]);
  if uname='other/uniqueinstance/uniqueinstancebase.pas'{'zengine\core\uzeentityfactory.pas'}{'zengine\core\objects\uzeentitiestree.pas'} then
    uname:=uname;
  if assigned(FPackage) then
    FPackage.Destroy;
  inherited;
end;

function TSimpleEngine.CreateElement(AClass: TPTreeElement; const AName: String;
  AParent: TPasElement; AVisibility: TPasMemberVisibility;
  const ASourceFilename: String; ASourceLinenumber: Integer): TPasElement;
begin
  Result := AClass.Create(AName, AParent);
  Result.Visibility := AVisibility;
  Result.SourceFilename := ASourceFilename;
  Result.SourceLinenumber := ASourceLinenumber;
end;
constructor TSimpleEngine.Create(const Options:TOptions;const _LogWriter:TLogWriter);
begin
  if Options.ProgramOptions.Logger.ScanerMessages then
    ScannerLogEvents:=[sleFile,sleLineNumber,sleConditionals,sleDirective];
  if Options.ProgramOptions.Logger.ParserMessages then
    ParserLogEvents:=[pleInterface,pleImplementation];
  OnLog:=@Log;
  FPackage:=TPasPackage.Create('',nil);
  LogWriter:=_LogWriter;
end;
procedure TSimpleEngine.Log(Sender : TObject; Const Msg : String);
begin
  LogWriter(Msg,[LD_Report]);
end;
function TSimpleEngine.FindElement(const AName: String): TPasElement;
begin
  { dummy implementation, see TFPDocEngine.FindElement for a real example }
  Result := nil;
end;
procedure PrepareModule(var M:TPasModule;var E:TPasTreeContainer;Options:TOptions;ScanResult:TScanResult;const LogWriter:TLogWriter);
var
   UnitIndex:TUnitIndex;
   s:string;
begin
   if ScanResult.TryCreateNewUnitInfo(M.Name,UnitIndex)then
   begin
   if M is TPasProgram then
    begin
     ScanResult.UnitInfoArray.Mutable[UnitIndex]^.UnitType:=TUnitType.UTProgram;
     ScanResult.UnitInfoArray.Mutable[UnitIndex]^.UnitPath:=extractfilepath(M.SourceFilename);
     GetDecls(PMProgram,(M as TPasProgram).ProgramSection as TPasDeclarations,Options,ScanResult,UnitIndex,LogWriter);
     if assigned(M.ImplementationSection) then
       begin
        GetDecls(PMProgram,M.ImplementationSection as TPasDeclarations,Options,ScanResult,UnitIndex,LogWriter);
       end;
    end
   else
    begin
      ScanResult.UnitInfoArray.Mutable[UnitIndex]^.UnitType:=TUnitType.UTUnit;
      ScanResult.UnitInfoArray.Mutable[UnitIndex]^.UnitPath:=extractfilepath(M.SourceFilename);
      GetDecls(PMInterface,M.InterfaceSection as TPasDeclarations,Options,ScanResult,UnitIndex,LogWriter);
      if assigned(M.ImplementationSection) then
       begin
        //if assigned(LogWriter) then LogWriter('Implementation');
        GetDecls(PMImplementation,M.ImplementationSection as TPasDeclarations,Options,ScanResult,UnitIndex,LogWriter);
       end;
    end;
   ScanResult.UnitInfoArray.Mutable[UnitIndex]^.PasModule:=M;
   ScanResult.UnitInfoArray.Mutable[UnitIndex]^.PasTreeContainer:=E;
   M:=nil;
   E:=nil;
   end;
   s:=ScanResult.UnitInfoArray.Mutable[UnitIndex]^.UnitPath;
end;
function MemoryUsed: Cardinal;
 begin
   Result := GetFPCHeapStatus.CurrHeapUsed;
end;

//копипаста из PParser
//сделана из-за отсутствия возможности
//установить po_IgnoreUnknownResource для сканера
function myParseSource(AEngine: TPasTreeContainer;
                     const FPCCommandLine : Array of String;
                     OSTarget, CPUTarget: String;
                     Options : TParseSourceOptions): TPasModule;

var
  FileResolver: TBaseFileResolver;
  Parser: TPasParser;
  Filename: String;
  Scanner: TPascalScanner;

  procedure ProcessCmdLinePart(S : String);
  var
    l,Len: Integer;

  begin
    if (S='') then
      exit;
    Len:=Length(S);
    if (s[1] = '-') and (len>1) then
    begin
      case s[2] of
        'd': // -d define
          Scanner.AddDefine(UpperCase(Copy(s, 3, Len)));
        'u': // -u undefine
          Scanner.RemoveDefine(UpperCase(Copy(s, 3, Len)));
        'F': // -F
          if (len>2) and (s[3] = 'i') then // -Fi include path
            FileResolver.AddIncludePath(Copy(s, 4, Len));
        'I': // -I include path
          FileResolver.AddIncludePath(Copy(s, 3, Len));
        'S': // -S mode
          if  (len>2) then
            begin
            l:=3;
            While L<=Len do
              begin
              case S[l] of
                'c' : Scanner.Options:=Scanner.Options+[po_cassignments];
                'd' : Scanner.SetCompilerMode('DELPHI');
                '2' : Scanner.SetCompilerMode('OBJFPC');
                'h' : ; // do nothing
              end;
              inc(l);
              end;
            end;
        'M' :
           begin
           delete(S,1,2);
           Scanner.SetCompilerMode(S);
           end;
      end;
    end else
      if Filename <> '' then
        raise ENotSupportedException.Create(SErrMultipleSourceFiles)
      else
        Filename := s;
  end;

var
  S: String;

begin
  if DefaultFileResolverClass=Nil then
    raise ENotImplemented.Create(SErrFileSystemNotSupported);
  Result := nil;
  FileResolver := nil;
  Scanner := nil;
  Parser := nil;
  try
    FileResolver := DefaultFileResolverClass.Create;
    {$ifdef HasStreams}
    if FileResolver is TFileResolver then
      TFileResolver(FileResolver).UseStreams:=poUseStreams in Options;
    {$endif}
    Scanner := TPascalScanner.Create(FileResolver);
    Scanner.LogEvents:=AEngine.ScannerLogEvents;
    Scanner.OnLog:=AEngine.OnLog;
    if not (poSkipDefaultDefs in Options) then
      begin
      Scanner.AddDefine('FPK');
      Scanner.AddDefine('FPC');
      // TargetOS
      s := UpperCase(OSTarget);
      Scanner.AddDefine(s);
      Case s of
        'LINUX' : Scanner.AddDefine('UNIX');
        'FREEBSD' :
          begin
          Scanner.AddDefine('BSD');
          Scanner.AddDefine('UNIX');
          end;
        'NETBSD' :
          begin
          Scanner.AddDefine('BSD');
          Scanner.AddDefine('UNIX');
          end;
        'SUNOS' :
          begin
          Scanner.AddDefine('SOLARIS');
          Scanner.AddDefine('UNIX');
          end;
        'GO32V2' : Scanner.AddDefine('DPMI');
        'BEOS' : Scanner.AddDefine('UNIX');
        'QNX' : Scanner.AddDefine('UNIX');
        'AROS' : Scanner.AddDefine('HASAMIGA');
        'MORPHOS' : Scanner.AddDefine('HASAMIGA');
        'AMIGA' : Scanner.AddDefine('HASAMIGA');
      end;
      // TargetCPU
      s := UpperCase(CPUTarget);
      Scanner.AddDefine('CPU'+s);
      if (s='X86_64') then
        Scanner.AddDefine('CPU64')
      else
        Scanner.AddDefine('CPU32');
      end;
    Scanner.Options:=Scanner.Options+[po_IgnoreUnknownResource];
    Parser := TPasParser.Create(Scanner, FileResolver, AEngine);
    if (poSkipDefaultDefs in Options) then
      Parser.ImplicitUses.Clear;
    Filename := '';
    Parser.LogEvents:=AEngine.ParserLogEvents;
    Parser.OnLog:=AEngine.OnLog;

    For S in FPCCommandLine do
      ProcessCmdLinePart(S);
    if Filename = '' then
      raise Exception.Create(SErrNoSourceGiven);
{$IFDEF HASFS}
    FileResolver.AddIncludePath(ExtractFilePath(FileName));
{$ENDIF}
    Scanner.OpenFile(Filename);
    Parser.ParseMain(Result);
  finally
    Parser.Free;
    Scanner.Free;
    FileResolver.Free;
  end;
end;

Function mySplitCommandLine(S : RawByteString) : TRawByteStringArray;

  Function GetNextWord : RawByteString;

  Const
    WhiteSpace = [' ',#9,#10,#13];
    Literals = ['"',''''];

  Var
    Wstart,wend : Integer;
    InLiteral : Boolean;
    LastLiteral : AnsiChar;

    Procedure AppendToResult;

    begin
      Result:=Result+Copy(S,WStart,WEnd-WStart);
      WStart:=Wend+1;
    end;

  begin
    Result:='';
    WStart:=1;
    While (WStart<=Length(S)) and charinset(S[WStart],WhiteSpace) do
      Inc(WStart);
    WEnd:=WStart;
    InLiteral:=False;
    LastLiteral:=#0;
    While (Wend<=Length(S)) and (Not charinset(S[Wend],WhiteSpace) or InLiteral) do
      begin
      if charinset(S[Wend],Literals) then
        If InLiteral then
          begin
          InLiteral:=Not (S[Wend]=LastLiteral);
          if not InLiteral then
            AppendToResult;
          end
        else
          begin
          InLiteral:=True;
          LastLiteral:=S[Wend];
          AppendToResult;
          end;
       inc(wend);
       end;
     AppendToResult;
     While (WEnd<=Length(S)) and (S[Wend] in WhiteSpace) do
       inc(Wend);
     Delete(S,1,WEnd-1);
  end;

Var
  W : RawByteString;
  len : Integer;

begin
  Len:=0;
  Result:=Default(TRawByteStringArray);
  SetLength(Result,(Length(S) div 2)+1);
  While Length(S)>0 do
    begin
    W:=GetNextWord;
    If (W<>'') then
      begin
      Result[Len]:=W;
      Inc(Len);
      end;
    end;
  SetLength(Result,Len);
end;


function myParseSource(AEngine: TPasTreeContainer;
  const FPCCommandLine, OSTarget, CPUTarget: String;
  Options : TParseSourceOptions): TPasModule;

Var
  Args : TStringArray;

begin
  Args:=mySplitCommandLine(FPCCommandLine);
  Result:=myParseSource(aEngine,Args,OSTarget,CPUTarget,Options);
end;


procedure ScanModule(mn:String;Options:TOptions;ScanResult:TScanResult;const LogWriter:TLogWriter);
var
  M:TPasModule;
  E:TSimpleEngine;
  myTime:TDateTime;
  memused:Cardinal;
begin
   E := TSimpleEngine.Create(Options,LogWriter);
   E.uname:=mn;
   //if assigned(LogWriter) then LogWriter(format('Process file: "%s"',[mn]));
   try
     if Options.ProgramOptions.Logger.Timer then
      begin
       myTime:=now;
       memused:=MemoryUsed;
      end;
     if E.uname='/media/zamtmn/apps/zcad/other/pudgb//uchecker.pas' then
       E.uname:=E.uname;
     M := myParseSource(E,mn+' '+Options.ProjectOptions.ParserOptions._CompilerOptions,Options.ProjectOptions.ParserOptions.TargetOS,Options.ProjectOptions.ParserOptions.TargetCPU,[poSkipDefaultDefs]);
     if Options.ProgramOptions.Logger.Timer then
      begin
       LogWriter(format('Parse "%s" %fsec, %db',[mn,(now-myTime)*10e4,(MemoryUsed-memused)]),[LD_Report]);
      end;
     if E.uname='zengine\geomlib\uzgeomproxy.pas' then
       E.uname:=E.uname;
     if E.uname='zengine\core\uzeentityfactory.pas' then
       E.uname:=E.uname;
     E.LogWriter:=LogWriter;
     PrepareModule(M,TPasTreeContainer(E),Options,ScanResult,LogWriter);
     if assigned(M) then M.Destroy;
     if assigned(E) then E.Free;
   except
     on excep:EParserError do
       begin
         if assigned(LogWriter) then LogWriter(format('Parser error: "%s" line:%d column:%d  file:%s',[excep.message,excep.row,excep.column,excep.filename]),[LD_Report]);
         //raise;
       end;
     on excep:Exception do
       begin
         if assigned(LogWriter) then LogWriter(format('Exception: "%s" in file "%s"',[excep.message,mn]),[LD_Report]);
         //raise;
       end;
     else
      begin
        if assigned(LogWriter) then LogWriter(format('Error in file "%s"',[mn]),[LD_Report]);
      end;
   end;
    //if assigned(LogWriter) then LogWriter(format('Done file: "%s"',[mn]));
end;
procedure ScanDirectory(mn:String;Options:TOptions;ScanResult:TScanResult;const LogWriter:TLogWriter);
var
  path,mask,s:string;
  i:integer;
  sr: TSearchRec;
begin
   path:=ExtractFileDir(mn)+PathDelim;
   i:=length(path)+1;
   while (i<=(length(mn)))and((mn[i] in AllowDirectorySeparators))do
    inc(i);
   mask:=copy(mn,i,length(mn)-i+1);
   if mask='' then
                  mask:='*.pas;*.pp';

   if FindFirst(path + '*', faDirectory, sr) = 0 then
   begin
     repeat
       if (sr.Name <> '.') and (sr.Name <> '..') then
       begin
         if DirectoryExists(path + sr.Name) then
                                                ScanDirectory(path+sr.Name+PathDelim+mask,Options,ScanResult,LogWriter)
         else
         begin
           //s:=lowercase(sr.Name);
           if MatchesMaskList(sr.Name,mask) then
           begin
             if not ScanResult.isUnitInfoPresent(ExtractFileName(sr.Name),i) then
             ScanModule(path+PathDelim+sr.Name,Options,ScanResult,LogWriter);
           end;
         end;
       end;
     until FindNext(sr) <> 0;
     FindClose(sr);
   end;

end;
procedure GetDecls(PM:TPrepareMode;Decl:TPasDeclarations;Options:TOptions;ScanResult:TScanResult;UnitIndex:TUnitIndex;const LogWriter:TLogWriter);
 var i,j:integer;
     pe:TPasElement;
     pp:TPasProcedure;
     ps:TPasSection;
     l:TStringList;
     ss,s:string;
     uarr:TUsesArray;
     t:boolean;
begin
 if assigned(Decl)then
  begin
   case pm of
     PMProgram:uarr:=ScanResult.UnitInfoArray[UnitIndex].InterfaceUses;
     PMInterface:uarr:=ScanResult.UnitInfoArray[UnitIndex].InterfaceUses;
     PMImplementation:uarr:=ScanResult.UnitInfoArray[UnitIndex].ImplementationUses;
   end;
   l:=TStringList.Create;
   pe:=TPasElement(Decl);
   if pe is TPasSection then
    begin
     ps:=TPasSection(pe);
     if ps.UsesList.Count >0 then
      begin
       //if assigned(LogWriter) then LogWriter('uses');
       ps:=TPasSection(Decl);
       for i:=0 to ps.UsesList.Count-2 do
        begin
        if UpCase(TPasElement(ps.UsesList[i]).Name) = 'SYSTEM' then continue
         else s:=s+(TPasElement(ps.UsesList[i]).Name+',');
        l.Add(TPasElement(ps.UsesList[i]).Name);
        end;
       s:=s+(TPasElement(ps.UsesList[ps.UsesList.Count-1]).Name+';');
       l.Add(TPasElement(ps.UsesList[ps.UsesList.Count-1]).Name);
       //if assigned(LogWriter) then LogWriter(s);
      end;
    end;
   for i:=0 to l.Count-1 do
    begin
    s:=l.Strings[i];
    if lowercase(s)='ucodeparser' then
                      s:=s;
    if not ScanResult.isUnitInfoPresent(l.Strings[i],j)then
    begin
      //s:='/'+l.Strings[i]+'.pas';
      s:=FindInSupportPath(Options.ProjectOptions.Paths._Paths,PathDelim+l.Strings[i]+'.pas');
      if s=''then
        s:=FindInSupportPath(Options.ProjectOptions.Paths._Paths,PathDelim+l.Strings[i]+'.pp');
      if s=''then
        s:=FindInSupportPath(Options.ProjectOptions.Paths._Paths,PathDelim+l.Strings[i]+'.PP');
      if s=''then
        s:=FindInSupportPath(Options.ProjectOptions.Paths._Paths,PathDelim+lowercase(l.Strings[i])+'.pas');
      if s=''then
        s:=FindInSupportPath(Options.ProjectOptions.Paths._Paths,PathDelim+lowercase(l.Strings[i])+'.pp');
      if s<>''then
                  begin
                    ScanModule(s,Options,ScanResult,LogWriter);
                    if ScanResult.UnitName2IndexMap.GetValue(lowercase(l.Strings[i]),j) then
                    begin
                      //ScanResult.UnitInfoArray.Mutable[j]^.UnitPath:='s';
                      uarr.PushBack(j);
                    end;
                  end
              else
                  begin
                       if Options.ProgramOptions.Logger.Notfounded then
                         if assigned(LogWriter) then LogWriter(format('Unit not found: "%s"',[l.Strings[i]]),[LD_Report]);
                       ScanResult.TryCreateNewUnitInfo(l.Strings[i],j);
                       ScanResult.UnitInfoArray.Mutable[j]^.UnitPath:='';
                       uarr.PushBack(j);
                  end;
    end
    else
    begin
       s:=l.Strings[i];
       if lowercase(s)='fpdpansi' then
                      s:=s;
       uarr.PushBack(j);
    end;
    end;
   l.Free;
  end;
end;
end.

