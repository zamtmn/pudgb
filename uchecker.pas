unit uchecker;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  uprojectoptions,uscanresult,uwriter,
  MultiLst,
  Pointerv,
  Graphs;


procedure CheckGraph(Options:TProjectOptions;ScanResult:TScanResult;const LogWriter:TLogWriter);

implementation
procedure CheckGraph(Options:TProjectOptions;ScanResult:TScanResult;const LogWriter:TLogWriter);
var
  i,j,k,mmm:integer;
  TotalUnitsWithImplUses,
  TotalFoundedUnits,
  TotaEdgesWithLoops,CurrentEdgesWithLoops,
  TotaUnitsWithLoops,StrongEdgeWeight,StrongEdge:integer;
  ts:string;
  te:TEdge;
begin
  if assigned(ScanResult.G)then
                               ScanResult.G.Destroy;
  if assigned(ScanResult.M)then
                               ScanResult.M.Destroy;
  ScanResult.G:=TGraph.Create;
  ScanResult.G.Features:=[Directed,Weighted];
  ScanResult.M:=TMultiList.Create(TClassList);
  try
    ScanResult.G.AddVertices(ScanResult.UnitInfoArray.Size);

    TotalUnitsWithImplUses:=0;
    TotalFoundedUnits:=0;
    for i:=0 to ScanResult.UnitInfoArray.Size-1 do
    begin
       if ScanResult.UnitInfoArray[i].UnitPath<>'' then inc(TotalFoundedUnits);
       for j:=0 to ScanResult.UnitInfoArray[i].InterfaceUses.Size-1 do
       begin
         ScanResult.G.AddEdgeI(i,ScanResult.UnitInfoArray[i].InterfaceUses[j]).Weight:=4;
       end;
       if ScanResult.UnitInfoArray[i].ImplementationUses.Size>0 then
       begin
         inc(TotalUnitsWithImplUses);
         for j:=0 to ScanResult.UnitInfoArray[i].ImplementationUses.Size-1 do
         begin
           ScanResult.G.AddEdgeI(i,ScanResult.UnitInfoArray[i].ImplementationUses[j]).Weight:=2;
         end;
       end;
    end;
    (*LogWriter('Loop graph by units:');
    LogWriter('DiGraph Classes {');
    for i:=0 to ScanResult.UnitInfoArray.Size-1 do
    begin
       if ScanResult.UnitInfoArray[i].ImplementationUses.Size>0 then
       begin
         for j:=0 to ScanResult.UnitInfoArray[i].ImplementationUses.Size-1 do
         begin
           if G.FindMinPathsDirected(G.Vertices[ScanResult.UnitInfoArray[i].ImplementationUses[j]],G.Vertices[i],0,m)>0 then
           begin
           //LogWriter('Loop detected');
           include(ScanResult.UnitInfoArray.mutable[i]^.UnitFlags,UFLoop);
           include(ScanResult.UnitInfoArray.mutable[ScanResult.UnitInfoArray.mutable[i]^.ImplementationUses[j]]^.UnitFlags,UFLoop);
           //LogWriter(format('(%s, %s)',[ScanResult.UnitInfoArray[i].UnitName,ScanResult.UnitInfoArray[ScanResult.UnitInfoArray[i].ImplementationUses[j]].UnitName]));
           LogWriter(format(' %s -> %s',[ScanResult.UnitInfoArray[i].UnitName,ScanResult.UnitInfoArray[ScanResult.UnitInfoArray[i].ImplementationUses[j]].UnitName]));
           for k:=0 to M.Count - 1 do begin
             for mmm:=0 to M[k].Count - 1 do With TEdge(M[k][mmm]) do
               begin
                 include(ScanResult.UnitInfoArray.mutable[V1.Index]^.UnitFlags,UFLoop);
                 include(ScanResult.UnitInfoArray.mutable[V2.Index]^.UnitFlags,UFLoop);
                 //LogWriter(format('(%s, %s)',[ScanResult.UnitInfoArray[V1.Index].UnitName,ScanResult.UnitInfoArray[V2.Index].UnitName]));
                 LogWriter(format(' %s -> %s',[ScanResult.UnitInfoArray[V1.Index].UnitName,ScanResult.UnitInfoArray[V2.Index].UnitName]));
               end;
           end;
           end;

         end;
       end;
    end;
    LogWriter('}');*)

    TotaEdgesWithLoops:=0;
    StrongEdgeWeight:=maxint;
    for i:=0 to ScanResult.UnitInfoArray.Size-1 do
      ScanResult.UnitInfoArray.mutable[i]^.NodeState:=NSNotCheced;
    //LogWriter('Loop graph by edges:',[LD_CircGraph]);
    LogWriter('DiGraph Classes {',[LD_Clear,LD_CircGraph]);
    for i:=0 to ScanResult.G.EdgeCount - 1 do
    begin
      if ScanResult.G.Edges[i].RingEdge then
      begin
       inc(TotaEdgesWithLoops);
       include(ScanResult.UnitInfoArray.mutable[ScanResult.G.Edges[i].V1.Index]^.UnitFlags,UFLoop);
       include(ScanResult.UnitInfoArray.mutable[ScanResult.G.Edges[i].V2.Index]^.UnitFlags,UFLoop);
       ProcessNode(nil,nil,Options,ScanResult,ScanResult.UnitInfoArray.mutable[ScanResult.G.Edges[i].V1.Index]^,ScanResult.G.Edges[i].V1.Index,LogWriter,[LD_CircGraph],true);
       ProcessNode(nil,nil,Options,ScanResult,ScanResult.UnitInfoArray.mutable[ScanResult.G.Edges[i].V2.Index]^,ScanResult.G.Edges[i].V1.Index,LogWriter,[LD_CircGraph],true);
       if ScanResult.G.Edges[i].Weight<3 then
                                  LogWriter(' edge [style=dotted]',[LD_CircGraph])
                              else
                                  LogWriter(' edge [style=solid]',[LD_CircGraph]);
       if Options.GraphBulding.CircularGraphOptions.CalcEdgesWeight then
       begin
         te:=ScanResult.G.Edges[i];
         te.Hide;
         CurrentEdgesWithLoops:=0;
         begin
         for j:=0 to ScanResult.G.EdgeCount - 1 do
         if ScanResult.G.Edges[j].RingEdge then
           inc(CurrentEdgesWithLoops);
         end;
         if StrongEdgeWeight>CurrentEdgesWithLoops then
         begin
           StrongEdgeWeight:=CurrentEdgesWithLoops;
           StrongEdge:=i;
         end;
         te.Restore;
         LogWriter(format(' %s -> %s [label=%d]',[getDecoratedUnnitname(ScanResult.UnitInfoArray[ScanResult.G.Edges[i].V1.Index]),getDecoratedUnnitname(ScanResult.UnitInfoArray[ScanResult.G.Edges[i].V2.Index]),CurrentEdgesWithLoops]),[LD_CircGraph])
       end
          else
              LogWriter(format(' %s -> %s',[getDecoratedUnnitname(ScanResult.UnitInfoArray[ScanResult.G.Edges[i].V1.Index]),getDecoratedUnnitname(ScanResult.UnitInfoArray[ScanResult.G.Edges[i].V2.Index])]),[LD_CircGraph]);
      end;
    end;
    LogWriter('}',[LD_CircGraph]);

    TotaUnitsWithLoops:=0;
    for i:=0 to ScanResult.UnitInfoArray.Size-1 do
    begin
       if UFLoop in ScanResult.UnitInfoArray[i].UnitFlags then
                                                              inc(TotaUnitsWithLoops)
       else
         if ScanResult.UnitInfoArray[i].ImplementationUses.Size>0 then
         begin
          if ts<>'' then
                        ts:=ts+', '+ScanResult.UnitInfoArray[i].UnitName
                    else
                        ts:=ScanResult.UnitInfoArray[i].UnitName;
         end;
    end;
    if ts<>'' then ts:=ts+';';

    LogWriter(format('Total units: %d ',[ScanResult.UnitInfoArray.Size]),[LD_Report]);
    LogWriter(format('Total founded units: %d ',[TotalFoundedUnits]),[LD_Report]);
    LogWriter(format('Total units with Implimentation uses: %d ',[TotalUnitsWithImplUses]),[LD_Report]);
    LogWriter(format('Total units in loops: %d ',[TotaUnitsWithLoops]),[LD_Report]);

    LogWriter(format('Total dependencies: %d ',[ScanResult.G.EdgeCount]),[LD_Report]);
    LogWriter(format('Total dependencies in loops: %d ',[TotaEdgesWithLoops]),[LD_Report]);
    if StrongEdgeWeight<>maxint then
    begin
      LogWriter(format('The worst addiction from "%s" to "%s" with %d ',[ScanResult.UnitInfoArray[ScanResult.G.Edges[StrongEdge].V1.Index].UnitName,ScanResult.UnitInfoArray[ScanResult.G.Edges[StrongEdge].V2.Index].UnitName,StrongEdgeWeight]),[LD_Report]);
    StrongEdgeWeight:=CurrentEdgesWithLoops;
    StrongEdge:=i;
    end;


    if ts<>'' then LogWriter(format('Implementation uses can be move to interface in %s ',[ts]),[LD_Report]);
  finally
    //G.Free;
    //M.Free;
  end;

end;

end.

