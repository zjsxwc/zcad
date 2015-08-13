{
*****************************************************************************
*                                                                           *
*  This file is part of the ZCAD                                            *
*                                                                           *
*  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
*  for details about the copyright.                                         *
*                                                                           *
*  This program is distributed in the hope that it will be useful,          *
*  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
*                                                                           *
*****************************************************************************
}
{
@author(Andrey Zubarev <zamtmn@yandex.ru>) 
}

unit uzgprimitives;
{$INCLUDE def.inc}
interface
uses math,uzglgeomdata,gdbdrawcontext,uzgvertex3sarray,uzglabstractdrawer,gdbasetypes,UGDBOpenArrayOfData,sysutils,gdbase,memman,
geometry;
const
     LLAttrNothing=0;
     LLAttrNeedSolid=1;
     LLAttrNeedSimtlify=2;

     {LLLineId=1;
     LLPointId=2;
     LLSymbolId=3;
     LLSymbolEndId=4;
     LLPolyLineId=5;
     LLTriangleId=6;}
type
{Export+}
ZGLOptimizerData={$IFNDEF DELPHI}packed{$ENDIF}record
                                                     ignoretriangles:boolean;
                                                     ignorelines:boolean;
                                                     symplify:boolean;
                                               end;
TEntIndexesData={$IFNDEF DELPHI}packed{$ENDIF}record
                                                    GeomIndexMin,GeomIndexMax:GDBInteger;
                                                    IndexsIndexMin,IndexsIndexMax:GDBInteger;
                                              end;
TEntIndexesOffsetData={$IFNDEF DELPHI}packed{$ENDIF}record
                                                    GeomIndexOffset:GDBInteger;
                                                    IndexsIndexOffset:GDBInteger;
                                              end;
PTLLPrimitive=^TLLPrimitive;
TLLPrimitive={$IFNDEF DELPHI}packed{$ENDIF} object
                       function getPrimitiveSize:GDBInteger;virtual;
                       procedure getEntIndexs(var GeomData:ZGLGeomData;out eid:TEntIndexesData);virtual;
                       procedure CorrectIndexes(const offset:TEntIndexesOffsetData);virtual;
                       constructor init;
                       destructor done;
                       function draw(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData):GDBInteger;virtual;
                       function CalcTrueInFrustum(frustum:ClipArray;var GeomData:ZGLGeomData;var InRect:TInBoundingVolume):GDBInteger;virtual;
                   end;
PTLLLine=^TLLLine;
TLLLine={$IFNDEF DELPHI}packed{$ENDIF} object(TLLPrimitive)
              P1Index:TLLVertexIndex;{P2Index=P1Index+1}
              function draw(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData):GDBInteger;virtual;
              function CalcTrueInFrustum(frustum:ClipArray;var GeomData:ZGLGeomData;var InRect:TInBoundingVolume):GDBInteger;virtual;
              procedure getEntIndexs(var GeomData:ZGLGeomData;out eid:TEntIndexesData);virtual;
              procedure CorrectIndexes(const offset:TEntIndexesOffsetData);virtual;
        end;
PTLLTriangle=^TLLTriangle;
TLLTriangle={$IFNDEF DELPHI}packed{$ENDIF} object(TLLPrimitive)
              P1Index:TLLVertexIndex;
              function draw(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData):GDBInteger;virtual;
              procedure getEntIndexs(var GeomData:ZGLGeomData;out eid:TEntIndexesData);virtual;
              procedure CorrectIndexes(const offset:TEntIndexesOffsetData);virtual;
        end;
PTLLFreeTriangle=^TLLFreeTriangle;
TLLFreeTriangle={$IFNDEF DELPHI}packed{$ENDIF} object(TLLPrimitive)
              P1IndexInIndexesArray:TLLVertexIndex;
              function draw(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData):GDBInteger;virtual;
              procedure getEntIndexs(var GeomData:ZGLGeomData;out eid:TEntIndexesData);virtual;
              procedure CorrectIndexes(const offset:TEntIndexesOffsetData);virtual;
        end;
PTLLTriangleStrip=^TLLTriangleStrip;
TLLTriangleStrip={$IFNDEF DELPHI}packed{$ENDIF} object(TLLPrimitive)
              P1IndexInIndexesArray:TLLVertexIndex;
              IndexInIndexesArraySize:TLLVertexIndex;
              function draw(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData):GDBInteger;virtual;
              procedure getEntIndexs(var GeomData:ZGLGeomData;out eid:TEntIndexesData);virtual;
              procedure CorrectIndexes(const offset:TEntIndexesOffsetData);virtual;
              procedure AddIndex(Index:TLLVertexIndex);virtual;
              constructor init;
        end;
PTLLTriangleFan=^TLLTriangleFan;
TLLTriangleFan={$IFNDEF DELPHI}packed{$ENDIF} object(TLLTriangleStrip)
              function draw(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData):GDBInteger;virtual;
        end;
PTLLPoint=^TLLPoint;
TLLPoint={$IFNDEF DELPHI}packed{$ENDIF} object(TLLPrimitive)
              PIndex:TLLVertexIndex;
              function draw(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData):GDBInteger;virtual;
              procedure getEntIndexs(var GeomData:ZGLGeomData;out eid:TEntIndexesData);virtual;
              procedure CorrectIndexes(const offset:TEntIndexesOffsetData);virtual;
        end;
PTLLSymbol=^TLLSymbol;
TLLSymbol={$IFNDEF DELPHI}packed{$ENDIF} object(TLLPrimitive)
              SymSize:GDBInteger;
              LineIndex:TArrayIndex;
              Attrib:TLLPrimitiveAttrib;
              OutBoundIndex:TLLVertexIndex;
              PExternalVectorObject:pointer;
              ExternalLLPOffset:TArrayIndex;
              ExternalLLPCount:TArrayIndex;
              SymMatr:DMatrix4F;
              function draw(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData):GDBInteger;virtual;
              procedure drawSymbol(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData);virtual;
              constructor init;
              function CalcTrueInFrustum(frustum:ClipArray;var GeomData:ZGLGeomData;var InRect:TInBoundingVolume):GDBInteger;virtual;
        end;
PTLLSymbolLine=^TLLSymbolLine;
TLLSymbolLine={$IFNDEF DELPHI}packed{$ENDIF} object(TLLPrimitive)
              SimplyDrawed:GDBBoolean;
              MaxSqrSymH:GDBFloat;
              FirstOutBoundIndex,LastOutBoundIndex:TLLVertexIndex;
              function draw(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData):GDBInteger;virtual;
              constructor init;
        end;
PTLLSymbolEnd=^TLLSymbolEnd;
TLLSymbolEnd={$IFNDEF DELPHI}packed{$ENDIF} object(TLLPrimitive)
              function draw(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData):GDBInteger;virtual;
                   end;
PTLLPolyLine=^TLLPolyLine;
TLLPolyLine={$IFNDEF DELPHI}packed{$ENDIF} object(TLLPrimitive)
              P1Index,Count,SimplifiedContourIndex,SimplifiedContourSize:TLLVertexIndex;
              Closed:GDBBoolean;
              function draw(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData):GDBInteger;virtual;
              function CalcTrueInFrustum(frustum:ClipArray;var GeomData:ZGLGeomData;var InRect:TInBoundingVolume):GDBInteger;virtual;
              procedure getEntIndexs(var GeomData:ZGLGeomData;out eid:TEntIndexesData);virtual;
              procedure AddSimplifiedIndex(Index:TLLVertexIndex);virtual;
              procedure CorrectIndexes(const offset:TEntIndexesOffsetData);virtual;
              constructor init;
        end;
{Export-}
implementation
uses log,uzglvectorobject;
function TLLPrimitive.getPrimitiveSize:GDBInteger;
begin
     result:=sizeof(self);
end;
constructor TLLPrimitive.init;
begin
end;
destructor TLLPrimitive.done;
begin
end;
procedure TLLPrimitive.getEntIndexs(var GeomData:ZGLGeomData;out eid:TEntIndexesData);
begin
     eid.GeomIndexMin:=-1;
     eid.GeomIndexMax:=-1;
     eid.IndexsIndexMax:=-1;
     eid.IndexsIndexMax:=-1;
end;
procedure TLLPrimitive.CorrectIndexes(const offset:TEntIndexesOffsetData);
begin
end;
function TLLPrimitive.draw(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData):GDBInteger;
begin
     result:=getPrimitiveSize;
end;
function TLLPrimitive.CalcTrueInFrustum(frustum:ClipArray;var GeomData:ZGLGeomData;var InRect:TInBoundingVolume):GDBInteger;
begin
     InRect:=IREmpty;
     result:=getPrimitiveSize;
end;
function TLLLine.draw(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData):GDBInteger;
begin
     if not OptData.ignorelines then
                                    Drawer.DrawLine(@geomdata.Vertex3S,P1Index,P1Index+1);
     result:=inherited;
end;
function TLLLine.CalcTrueInFrustum(frustum:ClipArray;var GeomData:ZGLGeomData;var InRect:TInBoundingVolume):GDBInteger;
begin
     InRect:=geometry.CalcTrueInFrustum(PGDBvertex3S(geomdata.Vertex3S.getelement(self.P1Index))^,PGDBvertex3S(geomdata.Vertex3S.getelement(self.P1Index+1))^,frustum);
     result:=getPrimitiveSize;
end;
procedure TLLLine.getEntIndexs(var GeomData:ZGLGeomData;out eid:TEntIndexesData);
begin
     eid.GeomIndexMin:=P1Index;
     eid.GeomIndexMax:=P1Index+1;
     eid.IndexsIndexMax:=-1;
     eid.IndexsIndexMin:=-1;
end;
procedure TLLLine.CorrectIndexes(const offset:TEntIndexesOffsetData);
begin
     P1Index:=P1Index+offset.GeomIndexOffset;
end;
function TLLPoint.draw(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData):GDBInteger;
begin
     Drawer.DrawPoint(@geomdata.Vertex3S,PIndex);
     result:=inherited;
end;
procedure TLLPoint.getEntIndexs(var GeomData:ZGLGeomData;out eid:TEntIndexesData);
begin
     eid.GeomIndexMin:=PIndex;
     eid.GeomIndexMax:=PIndex;
     eid.IndexsIndexMax:=-1;
     eid.IndexsIndexMin:=-1
end;
procedure TLLPoint.CorrectIndexes(const offset:TEntIndexesOffsetData);
begin
     PIndex:=PIndex+offset.GeomIndexOffset;
end;
function TLLTriangle.draw(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData):GDBInteger;
begin
     if not OptData.ignoretriangles then
                                        Drawer.DrawTriangle(@geomdata.Vertex3S,P1Index,P1Index+1,P1Index+2);
     result:=inherited;
end;
procedure TLLTriangle.getEntIndexs(var GeomData:ZGLGeomData;out eid:TEntIndexesData);
begin
     eid.GeomIndexMin:=P1Index;
     eid.GeomIndexMax:=P1Index+2;
     eid.IndexsIndexMax:=-1;
     eid.IndexsIndexMin:=-1
end;
procedure TLLTriangle.CorrectIndexes(const offset:TEntIndexesOffsetData);
begin
     P1Index:=P1Index+offset.GeomIndexOffset;
end;
function TLLFreeTriangle.draw(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData):GDBInteger;
var
   P1Index,P2Index,P3Index:pinteger;
begin
     if not OptData.ignoretriangles then
                                        begin
                                             P1Index:=GeomData.Indexes.getelement(P1IndexInIndexesArray);
                                             P2Index:=GeomData.Indexes.getelement(P1IndexInIndexesArray+1);
                                             P3Index:=GeomData.Indexes.getelement(P1IndexInIndexesArray+2);
                                             Drawer.DrawTriangle(@geomdata.Vertex3S,P1Index^,P2Index^,P3Index^);
                                        end;
     result:=inherited;
end;
procedure TLLFreeTriangle.getEntIndexs(var GeomData:ZGLGeomData;out eid:TEntIndexesData);
var
   P1Index,P2Index,P3Index:pinteger;
begin
     P1Index:=GeomData.Indexes.getelement(P1IndexInIndexesArray);
     P2Index:=GeomData.Indexes.getelement(P1IndexInIndexesArray+1);
     P3Index:=GeomData.Indexes.getelement(P1IndexInIndexesArray+2);
     eid.GeomIndexMin:=min(min(P1Index^,P2Index^),P3Index^);
     eid.GeomIndexMax:=max(max(P1Index^,P2Index^),P3Index^);
     eid.IndexsIndexMin:=P1IndexInIndexesArray;
     eid.IndexsIndexMax:=P1IndexInIndexesArray+2;
end;
procedure TLLFreeTriangle.CorrectIndexes(const offset:TEntIndexesOffsetData);
begin
     P1IndexInIndexesArray:=P1IndexInIndexesArray+offset.IndexsIndexOffset;
end;
function TLLTriangleFan.draw(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData):GDBInteger;
begin
     if not OptData.ignoretriangles then
                                        Drawer.DrawTrianglesFan(@geomdata.Vertex3S,@geomdata.Indexes,P1IndexInIndexesArray,IndexInIndexesArraySize);
     result:=getPrimitiveSize;
end;

function TLLTriangleStrip.draw(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData):GDBInteger;
begin
     if not OptData.ignoretriangles then
                                        Drawer.DrawTrianglesStrip(@geomdata.Vertex3S,@geomdata.Indexes,P1IndexInIndexesArray,IndexInIndexesArraySize);
     result:=getPrimitiveSize;
end;
procedure TLLTriangleStrip.getEntIndexs(var GeomData:ZGLGeomData;out eid:TEntIndexesData);
var
   PIndex:pinteger;
   index:TLLVertexIndex;
   i:integer;
begin
     if P1IndexInIndexesArray<>-1 then
     begin
       index:=P1IndexInIndexesArray;
       PIndex:=GeomData.Indexes.getelement(index);
       eid.GeomIndexMin:=PIndex^;
       eid.GeomIndexMax:=PIndex^;
       inc(index);
       for i:=2 to IndexInIndexesArraySize do
       begin
         PIndex:=GeomData.Indexes.getelement(index);
         eid.GeomIndexMin:=min(eid.GeomIndexMin,PIndex^);
         eid.GeomIndexMax:=max(eid.GeomIndexMax,PIndex^);
         inc(index);
       end;
       eid.IndexsIndexMin:=P1IndexInIndexesArray;
       eid.IndexsIndexMax:=P1IndexInIndexesArray+IndexInIndexesArraySize-1;
     end
     else
     begin
       eid.GeomIndexMin:=-1;
       eid.GeomIndexMax:=-1;
       eid.IndexsIndexMin:=-1;
       eid.IndexsIndexMax:=-1;
     end;
end;
procedure TLLTriangleStrip.CorrectIndexes(const offset:TEntIndexesOffsetData);
begin
     P1IndexInIndexesArray:=P1IndexInIndexesArray+offset.IndexsIndexOffset;
end;
procedure TLLTriangleStrip.AddIndex(Index:TLLVertexIndex);
begin
     if P1IndexInIndexesArray=-1 then
                                     P1IndexInIndexesArray:=Index;
     inc(IndexInIndexesArraySize);
end;
constructor TLLTriangleStrip.init;
begin
     P1IndexInIndexesArray:=-1;
     IndexInIndexesArraySize:=0;
end;

procedure TLLPolyLine.AddSimplifiedIndex(Index:TLLVertexIndex);
begin
     if SimplifiedContourIndex=-1 then
                                      SimplifiedContourIndex:=Index;
     inc(SimplifiedContourSize);
end;
constructor TLLPolyLine.init;
begin
     P1Index:=-1;
     Count:=0;
     SimplifiedContourIndex:=-1;
     SimplifiedContourSize:=0;
     Closed:=false;
end;

function TLLPolyLine.draw(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData):GDBInteger;
var
   i,index,oldindex,sindex:integer;
begin
  if not OptData.ignorelines then
  begin
    if (OptData.symplify)and(SimplifiedContourIndex<>-1) then
    begin
      sindex:=SimplifiedContourIndex;
      if sindex<0 then sindex:=0;
      oldindex:=PTArrayIndex(GeomData.Indexes.getelement(sindex))^;
      inc(sindex);
      for i:=1 to SimplifiedContourSize-1 do
      begin
         index:=PTArrayIndex(GeomData.Indexes.getelement(sindex))^;
         Drawer.DrawLine(@geomdata.Vertex3S,oldindex,index);
         oldindex:=index;
         inc(sindex);
      end;
    end
    else
    begin
       index:=P1Index+1;
       oldindex:=P1Index;
         for i:=1 to Count-1 do
         begin
            Drawer.DrawLine(@geomdata.Vertex3S,oldindex,index);
            oldindex:=index;
            inc(index);
         end;
    end;
  if closed then
                       Drawer.DrawLine(@geomdata.Vertex3S,oldindex,P1Index);
  end;
  result:=inherited;
end;
procedure TLLPolyLine.getEntIndexs(var GeomData:ZGLGeomData;out eid:TEntIndexesData);
begin
     eid.GeomIndexMin:=P1Index;
     eid.GeomIndexMax:=P1Index+Count-1;
     if self.SimplifiedContourIndex=-1 then
     begin
     eid.IndexsIndexMin:=-1;
     eid.IndexsIndexMax:=-1;
     end
     else
     begin
     eid.IndexsIndexMin:=SimplifiedContourIndex;
     eid.IndexsIndexMax:=SimplifiedContourIndex+SimplifiedContourSize-1;
     end

end;
procedure TLLPolyLine.CorrectIndexes(const offset:TEntIndexesOffsetData);
begin
     P1Index:=P1Index+offset.GeomIndexOffset;
     SimplifiedContourIndex:=SimplifiedContourIndex+offset.IndexsIndexOffset;
end;
function TLLPolyLine.CalcTrueInFrustum(frustum:ClipArray;var GeomData:ZGLGeomData;var InRect:TInBoundingVolume):GDBInteger;
var
   i,index:integer;
   SubRect:TInBoundingVolume;
begin
     InRect:=geometry.CalcTrueInFrustum(PGDBvertex3S(geomdata.Vertex3S.getelement(P1Index))^,PGDBvertex3S(geomdata.Vertex3S.getelement(P1Index+1))^,frustum);
     result:=getPrimitiveSize;
     if InRect=IRPartially then
                               exit;
     index:=P1Index+1;
     for i:=2 to Count do
     begin
        SubRect:=geometry.CalcTrueInFrustum(PGDBvertex3S(geomdata.Vertex3S.getelement(index))^,PGDBvertex3S(geomdata.Vertex3S.getelement(index+1))^,frustum);
        case SubRect of
          IREmpty:if InRect=IRFully then
                                         InRect:=IRPartially;
          IRFully:if InRect<>IRFully then
                                         InRect:=IRPartially;
          IRPartially:
                      InRect:=IRPartially;
        end;
        if InRect=IRPartially then
                                  exit;
        inc(index);
     end;
end;
function TLLSymbolEnd.draw(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData):GDBInteger;
begin
     OptData.ignoretriangles:=false;
     OptData.ignorelines:=false;
     OptData.symplify:=false;
     result:=inherited;
end;
constructor TLLSymbolLine.init;
begin
     MaxSqrSymH:=0;
     inherited;
end;

function TLLSymbolLine.draw(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData):GDBInteger;
begin
  if (MaxSqrSymH/(rc.zoom*rc.zoom)<3)and(not rc.maxdetail) then
                                                begin
                                                  Drawer.DrawLine(@geomdata.Vertex3S,FirstOutBoundIndex,LastOutBoundIndex+3);
                                                  //Drawer.DrawLine(FirstOutBoundIndex+1,LastOutBoundIndex+2);
                                                  {Drawer.DrawQuad(FirstOutBoundIndex,FirstOutBoundIndex+1,LastOutBoundIndex+2,LastOutBoundIndex+3);
                                                  Drawer.DrawLine(FirstOutBoundIndex,FirstOutBoundIndex+1);
                                                  Drawer.DrawLine(FirstOutBoundIndex+1,LastOutBoundIndex+2);
                                                  Drawer.DrawLine(FirstOutBoundIndex+2,LastOutBoundIndex+3);
                                                  Drawer.DrawLine(FirstOutBoundIndex+3,FirstOutBoundIndex);}
                                                  self.SimplyDrawed:=true;
                                                end
                                            else
                                                self.SimplyDrawed:=false;
  result:=inherited;
end;
constructor TLLSymbol.init;
begin
  SymSize:=-1;
  LineIndex:=-1;
  Attrib:=0;
  OutBoundIndex:=-1;
  PExternalVectorObject:=nil;
  ExternalLLPOffset:=-1;
  ExternalLLPCount:=-1;
end;
function TLLSymbol.CalcTrueInFrustum(frustum:ClipArray;var GeomData:ZGLGeomData;var InRect:TInBoundingVolume):GDBInteger;
var
   ir1,ir2,ir3,ir4:TInBoundingVolume;
   myfrustum:ClipArray;
   OutBound:OutBound4V;
   p:PGDBvertex3S;
begin
     p:=geomdata.Vertex3S.getelement(OutBoundIndex);
     OutBound[0].x:=p^.x;
     OutBound[0].y:=p^.y;
     OutBound[0].z:=p^.z;
     p:=geomdata.Vertex3S.getelement(OutBoundIndex+1);
     OutBound[1].x:=p^.x;
     OutBound[1].y:=p^.y;
     OutBound[1].z:=p^.z;
     p:=geomdata.Vertex3S.getelement(OutBoundIndex+2);
     OutBound[2].x:=p^.x;
     OutBound[2].y:=p^.y;
     OutBound[2].z:=p^.z;
     p:=geomdata.Vertex3S.getelement(OutBoundIndex+3);
     OutBound[3].x:=p^.x;
     OutBound[3].y:=p^.y;
     OutBound[3].z:=p^.z;

     InRect:=CalcOutBound4VInFrustum(OutBound,frustum);

     result:=getPrimitiveSize;

     if InRect<>IRPartially then
                                exit;

     myfrustum:=FrustumTransform(frustum,SymMatr);
     InRect:=PZGLVectorObject(PExternalVectorObject).CalcCountedTrueInFrustum(myfrustum,true,ExternalLLPOffset,ExternalLLPCount);
end;

function TLLSymbol.draw(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData):GDBInteger;
{TODO: this need rewrite}
var
   i,index,minsymbolsize:integer;
   sqrparamsize:gdbdouble;
begin
  result:=0;
  if self.LineIndex<>-1 then
  if PTLLSymbolLine(LLPArray.getelement(self.LineIndex))^.SimplyDrawed then
                                                                           begin
                                                                             result:=SymSize;
                                                                             exit;
                                                                           end;
  index:=OutBoundIndex;
  result:=inherited;
  if not drawer.CheckOutboundInDisplay(@geomdata.Vertex3S,index) then
                                                  begin
                                                    result:=SymSize;
                                                  end

else if (Attrib and LLAttrNeedSimtlify)>0 then
  begin
    if (Attrib and LLAttrNeedSolid)>0 then
                                                                  begin
                                                                   minsymbolsize:=30;
                                                                   OptData.ignorelines:=true;
                                                                  end
                                                              else
                                                                  minsymbolsize:=30;
    sqrparamsize:=GeomData.Vertex3S.GetLength(index)/(rc.zoom*rc.zoom);
    if (sqrparamsize<minsymbolsize)and(not rc.maxdetail) then
    begin
      //if (PTLLSymbol(PPrimitive)^.Attrib and LLAttrNeedSolid)>0 then
                                                                    Drawer.DrawQuad(@GeomData.Vertex3S,index,index+1,index+2,index+3);
                                                                {else
                                                                    for i:=1 to 3 do
                                                                    begin
                                                                       Drawer.DrawLine(index);
                                                                       inc(index);
                                                                    end;}
      result:=SymSize;
      exit;
    end
    else
   {if (sqrparamsize<(300))and(not rc.maxdetail) then
   begin
     OptData.ignoretriangles:=true;
     OptData.ignorelines:=false;
     if (Attrib and LLAttrNeedSolid)>0 then
                                           OptData.symplify:=true;
   end
     else}
    if (sqrparamsize<{(minsymbolsize+1000)}400)and(not rc.maxdetail) then
    begin
      OptData.ignoretriangles:=true;
      OptData.ignorelines:=false;
      if (Attrib and LLAttrNeedSolid)>0 then
                                           OptData.symplify:=true;
    end;
    //if result<>SymSize then
    begin
      result:=SymSize;
      drawSymbol(drawer,rc,GeomData,LLPArray,OptData);
    end;
  end
   else
     begin
       drawSymbol(drawer,rc,GeomData,LLPArray,OptData);
     end;

end;

procedure TLLSymbol.drawSymbol(drawer:TZGLAbstractDrawer;var rc:TDrawContext;var GeomData:ZGLGeomData;var LLPArray:GDBOpenArrayOfData;var OptData:ZGLOptimizerData);
begin
     drawer.pushMatrixAndSetTransform(SymMatr);
     PZGLVectorObject(PExternalVectorObject).DrawCountedLLPrimitives(rc,drawer,OptData,ExternalLLPOffset,ExternalLLPCount);
     drawer.popMatrix;
end;

begin
  {$IFDEF DEBUGINITSECTION}LogOut('uzgprimitives.initialization');{$ENDIF}
end.

