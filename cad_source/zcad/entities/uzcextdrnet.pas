{
*****************************************************************************
*                                                                           *
*  This file is part of the ZCAD                                            *
*                                                                           *
*  See the file COPYING.txt, included in this distribution,                 *
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
unit uzcExtdrNet;
{$INCLUDE zengineconfig.inc}

interface
uses sysutils,uzedrawingdef,uzeentityextender,
     UGDBOpenArrayOfPV,uzeentgenericsubentry,uzeentline,uzegeometry,
     uzeentdevice,TypeDescriptors,uzctnrVectorBytes,
     uzbtypes,uzeentsubordinated,uzeentity,uzeblockdef,
     //varmandef,Varman,UUnitManager,URecordDescriptor,UBaseTypeDescriptor,
     usimplegenerics,uzeffdxfsupport,//uzbpaths,uzcTranslations,
     gzctnrVectorTypes,uzeBaseExtender,uzgldrawcontext,
     uzegeometrytypes,uzcsysvars,
     uzctnrVectorDouble,gzctnrVector,garrayutils;
const
  NetExtenderName='extdrNet';
  IntersectSize=1;
  ConnectSize=1;
type
//TLineEnd=(LBegin,LEnd);
TNet=class
    Entities:GDBObjOpenArrayOfPV;
    constructor Create;
    destructor Destroy;override;
end;
TConnectPoint=record
  t:Double;
  count:Integer;
  constructor Create(AT:Double);
end;
TConnectPoints=GZVector<TConnectPoint>;
TIntersectPointsLess=class
  class function c(a,b:Double):boolean;
end;
TIntersectPointsUtil=TOrderingArrayUtils<TZctnrVectorDouble,Double,TIntersectPointsLess>;
TNetExtender=class(TBaseEntityExtender)
    pThisEntity:PGDBObjEntity;
    ConnectedWith,IntersectedWith:GDBObjOpenArrayOfPV;
    Intersects:TZctnrVectorDouble;
    Connections:TConnectPoints;
    class function getExtenderName:string;override;
    constructor Create(pEntity:Pointer);override;
    destructor Destroy;override;

    procedure Assign(Source:TBaseExtender);override;

    procedure onRemoveFromArray(pEntity:Pointer;const drawing:TDrawingDef);override;
    procedure onEntityClone(pSourceEntity,pDestEntity:pointer);override;
    procedure onEntityBuildVarGeometry(pEntity:pointer;const drawing:TDrawingDef);override;
    procedure onBeforeEntityFormat(pEntity:Pointer;const drawing:TDrawingDef;var DC:TDrawContext);override;
    procedure onAfterEntityFormat(pEntity:Pointer;const drawing:TDrawingDef;var DC:TDrawContext);override;
    procedure onEntityConnect(pEntity:Pointer;const drawing:TDrawingDef;var DC:TDrawContext);override;
    procedure CopyExt2Ent(pSourceEntity,pDestEntity:pointer);override;
    procedure ReorganizeEnts(OldEnts2NewEntsMap:TMapPointerToPointer);override;
    procedure PostLoad(var context:TIODXFLoadContext);override;

    procedure onEntitySupportOldVersions(pEntity:pointer;const drawing:TDrawingDef);override;


    class function EntIOLoadNetExtender(_Name,_Value:String;ptu:PExtensionData;const drawing:TDrawingDef;PEnt:pointer):boolean;

    procedure SaveToDxfObjXData(var outhandle:TZctnrVectorBytes;PEnt:Pointer;var IODXFContext:TIODXFContext);override;

    //procedure TryConnectToEnts(var Objects:GDBObjOpenArrayOfPV;Position:TLineEnd;const drawing:TDrawingDef;var DC:TDrawContext);
    procedure TryConnectToEnts2(const p1,p2:GDBVertex;var Objects:GDBObjOpenArrayOfPV;const drawing:TDrawingDef;var DC:TDrawContext);
    function NeedStandardDraw(pEntity:Pointer;const drawing:TDrawingDef;var DC:TDrawContext):Boolean;override;

    protected
      procedure AddToDWGPostProcs(pEntity:Pointer;const drawing:TDrawingDef);
  end;


function AddNetExtenderToEntity(PEnt:PGDBObjEntity):TNetExtender;

implementation
class function TIntersectPointsLess.c(a,b:Double):boolean;
begin
  result:=a<b;
end;

function IsConnectPointEqual(const a,b:TConnectPoint):Boolean;
begin
  result:=IsDoubleEqual(a.t,b.t,bigeps);
end;

constructor TConnectPoint.Create(AT:Double);
begin
  t:=AT;
  count:=1;
end;

constructor TNet.Create;
begin
  Entities.init(10);
end;

destructor TNet.Destroy;
begin
  Entities.done;
end;

function AddNetExtenderToEntity(PEnt:PGDBObjEntity):TNetExtender;
begin
  result:=TNetExtender.Create(PEnt);
  PEnt^.AddExtension(result);
end;
procedure TNetExtender.onEntitySupportOldVersions(pEntity:pointer;const drawing:TDrawingDef);
begin
end;
constructor TNetExtender.Create;
begin
  pThisEntity:=pEntity;
  ConnectedWith.init(10);
  IntersectedWith.init(10);
  Intersects.init(2);
  Connections.init(3);
end;
destructor TNetExtender.Destroy;
begin
  ConnectedWith.destroy;
  IntersectedWith.destroy;
  Intersects.destroy;
  Connections.destroy;
end;
procedure TNetExtender.Assign(Source:TBaseExtender);
begin
end;

procedure TNetExtender.AddToDWGPostProcs(pEntity:Pointer;const drawing:TDrawingDef);
var
  p:PGDBObjLine;
  ir:itrec;
begin
  p:=ConnectedWith.beginiterate(ir);
  if p<>nil then
  repeat
    if p<>nil then
      PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjToConnectedArray.PushBackIfNotPresent(p);
      PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjCasheArray.PushBackIfNotPresent(p);
  p:=ConnectedWith.iterate(ir);
  until p=nil;
  ConnectedWith.Clear;

  p:=IntersectedWith.beginiterate(ir);
  if p<>nil then
  repeat
    if p<>nil then
      PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjToConnectedArray.PushBackIfNotPresent(p);
      PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjCasheArray.PushBackIfNotPresent(p);
  p:=IntersectedWith.iterate(ir);
  until p=nil;
  IntersectedWith.Clear;
end;

procedure TNetExtender.onRemoveFromArray(pEntity:Pointer;const drawing:TDrawingDef);
begin
  AddToDWGPostProcs(pEntity,drawing);
end;
procedure TNetExtender.onEntityClone(pSourceEntity,pDestEntity:pointer);
begin
end;
procedure TNetExtender.onEntityBuildVarGeometry(pEntity:pointer;const drawing:TDrawingDef);
begin
end;
procedure TNetExtender.onBeforeEntityFormat(pEntity:Pointer;const drawing:TDrawingDef;var DC:TDrawContext);
begin
  if pThisEntity<>nil then begin
    if not (ESConstructProxy in pThisEntity^.State) then
      if IsIt(TypeOf(pThisEntity^),typeof(GDBObjLine)) then begin

        AddToDWGPostProcs(pThisEntity,drawing);

        pThisEntity^.addtoconnect2(pThisEntity,PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjToConnectedArray);
      end;
  end;
end;
procedure TNetExtender.onEntityConnect(pEntity:Pointer;const drawing:TDrawingDef;var DC:TDrawContext);
var
  Objects:GDBObjOpenArrayOfPV;
begin
  ConnectedWith.Clear;
  IntersectedWith.Clear;
  Intersects.Clear;
  Connections.Clear;
  if pThisEntity<>nil then begin
    if not (ESConstructProxy in pThisEntity^.State) then
      if IsIt(TypeOf(pThisEntity^),typeof(GDBObjLine)) then begin
        objects.init(10);
        if PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.FindObjectsInVolume(PGDBObjLine(pThisEntity)^.vp.BoundingBox,Objects)then
          TryConnectToEnts2(PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,Objects,drawing,dc);
        {if PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.FindObjectsInPoint(PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,Objects) then
          TryConnectToEnts(Objects,LBegin,drawing,dc);
        objects.Clear;
        if PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.FindObjectsInPoint(PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,Objects) then
          TryConnectToEnts(Objects,LEnd,drawing,dc);}
        objects.Clear;
        objects.done;
      end;
  end;
  if Intersects.Count>1 then
    TIntersectPointsUtil.Sort(Intersects,Intersects.Count);
end;
procedure TNetExtender.onAfterEntityFormat(pEntity:Pointer;const drawing:TDrawingDef;var DC:TDrawContext);
begin
end;

procedure TNetExtender.CopyExt2Ent(pSourceEntity,pDestEntity:pointer);
begin
end;
procedure TNetExtender.ReorganizeEnts(OldEnts2NewEntsMap:TMapPointerToPointer);
begin
end;

procedure TNetExtender.PostLoad(var context:TIODXFLoadContext);
begin
end;

class function TNetExtender.getExtenderName:string;
begin
  result:=NetExtenderName;
end;

class function TNetExtender.EntIOLoadNetExtender(_Name,_Value:String;ptu:PExtensionData;const drawing:TDrawingDef;PEnt:pointer):boolean;
var
  NetExtender:TNetExtender;
begin
  NetExtender:=PGDBObjEntity(PEnt)^.GetExtension<TNetExtender>;
  if NetExtender=nil then begin
    NetExtender:=AddNetExtenderToEntity(PEnt);
  end;
  result:=true;
end;

procedure TNetExtender.SaveToDxfObjXData(var outhandle:TZctnrVectorBytes;PEnt:Pointer;var IODXFContext:TIODXFContext);
begin
   dxfStringout(outhandle,1000,'NETEXTENDER=');
end;

procedure drawArrow(l1,l2:GDBVertex;pThisEntity:PGDBObjEntity;var DC:TDrawContext);
var
  onel,p1,p2:GDBVertex;
  tp2,tp3:GDBVertex;
  m,rotmatr:DMatrix4D;
begin
  onel:=l2-l1;
  if onel.SqrLength>sqreps then begin
    onel:=onel.NormalizeVertex;
    tp2:=GetXfFromZ(onel);
    tp3:=CrossVertex(tp2,onel);
    tp3:=NormalizeVertex(tp3);
    tp2:=NormalizeVertex(tp2);
    rotmatr:=onematrix;
    PGDBVertex(@rotmatr[0])^:=onel;
    PGDBVertex(@rotmatr[1])^:=tp2;
    PGDBVertex(@rotmatr[2])^:=tp3;
    m:=onematrix;
    PGDBVertex(@m[3])^:=l2;
    m:=MatrixMultiply(rotmatr,m);
    p1:=VectorTransform3D(uzegeometry.CreateVertex(-3*SysVar.DSGN.DSGN_HelpScale^,0.5*SysVar.DSGN.DSGN_HelpScale^,0),m);
    p2:=VectorTransform3D(uzegeometry.CreateVertex(-3*SysVar.DSGN.DSGN_HelpScale^,-0.5*SysVar.DSGN.DSGN_HelpScale^,0),m);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p1,l2);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p2,l2);
  end;
end;
procedure drawCross(p1:GDBVertex;pThisEntity:PGDBObjEntity;var DC:TDrawContext);
begin
  pThisEntity^.Representation.DrawLineWithoutLT(DC,p1-_XY_zVertex,p1+_XY_zVertex);
  pThisEntity^.Representation.DrawLineWithoutLT(DC,p1-_MinusXY_zVertex,p1+_MinusXY_zVertex);
end;
procedure drawFilledCircle(p0:GDBVertex;r:Double;pThisEntity:PGDBObjEntity;var DC:TDrawContext);
var
  p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12:GDBVertex;
begin
  if r>bigeps then begin
    p1:=CreateVertex(-1,0,0)*r+p0;
    p2:=CreateVertex(cos(5*pi/6),sin(5*pi/6),0)*r+p0;
    p3:=CreateVertex(cos(4*pi/6),sin(4*pi/6),0)*r+p0;
    p4:=CreateVertex(cos(3*pi/6),sin(3*pi/6),0)*r+p0;
    p5:=CreateVertex(cos(2*pi/6),sin(2*pi/6),0)*r+p0;
    p6:=CreateVertex(cos(1*pi/6),sin(1*pi/6),0)*r+p0;
    p7:=CreateVertex(1,0,0)*r+p0;
    p8:=CreateVertex(cos(-1*pi/6),sin(-1*pi/6),0)*r+p0;
    p9:=CreateVertex(cos(-2*pi/6),sin(-2*pi/6),0)*r+p0;
    p10:=CreateVertex(cos(-3*pi/6),sin(-3*pi/6),0)*r+p0;
    p11:=CreateVertex(cos(-4*pi/6),sin(-4*pi/6),0)*r+p0;
    p12:=CreateVertex(cos(-5*pi/6),sin(-5*pi/6),0)*r+p0;
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p1,p2);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p2,p3);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p3,p4);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p4,p5);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p5,p6);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p6,p7);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p7,p8);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p8,p9);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p9,p10);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p10,p11);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p11,p12);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p12,p1);

    pThisEntity^.Representation.DrawLineWithoutLT(DC,p0,p1);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p0,p2);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p0,p3);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p0,p4);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p0,p5);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p0,p6);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p0,p7);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p0,p8);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p0,p9);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p0,p10);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p0,p11);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p0,p12);
  end;
end;

procedure drawIntersectArc(l1,l2:GDBVertex;pThisEntity:PGDBObjEntity;var DC:TDrawContext);
var
  v,onel,p1,p2:GDBVertex;
  tp2,tp3:GDBVertex;
  m,rotmatr:DMatrix4D;
  l,x,y,z:double;
  chg:boolean;
begin
  v:=l2-l1;
  chg:=false;
  if abs(v.x)<bigeps then begin
    if v.y<0 then
      chg:=true;
  end else begin
    if v.x<bigeps then
      chg:=true;
  end;
  if chg then begin
    v:=-v;
    p1:=l2;
    l2:=L1+v;
    l1:=p1+v;
  end;
  l:=v.Length;
  if l>bigeps then begin
    onel:=v;
    tp2:=GetXfFromZ(onel);
    tp3:=CrossVertex(tp2,onel);
    tp3:=NormalizeVertex(tp3);
    tp2:=NormalizeVertex(tp2);
    rotmatr:=onematrix;
    PGDBVertex(@rotmatr[0])^:=onel;
    PGDBVertex(@rotmatr[1])^:=tp2*l;
    PGDBVertex(@rotmatr[2])^:=tp3*l;
    m:=onematrix;
    PGDBVertex(@m[3])^:=l1;
    m:=MatrixMultiply(rotmatr,m);

    p1:=VectorTransform3D(uzegeometry.CreateVertex(-1,0,0),m);
    p2:=VectorTransform3D(uzegeometry.CreateVertex(cos(5*pi/6),sin(5*pi/6),0),m);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p1,p2);
    p1:=VectorTransform3D(uzegeometry.CreateVertex(cos(4*pi/6),sin(4*pi/6),0),m);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p2,p1);
    p2:=VectorTransform3D(uzegeometry.CreateVertex(cos(3*pi/6),sin(3*pi/6),0),m);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p1,p2);

    p1:=VectorTransform3D(uzegeometry.CreateVertex(cos(2*pi/6),sin(2*pi/6),0),m);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p2,p1);
    p2:=VectorTransform3D(uzegeometry.CreateVertex(cos(1*pi/6),sin(1*pi/6),0),m);
    pThisEntity^.Representation.DrawLineWithoutLT(DC,p1,p2);

    pThisEntity^.Representation.DrawLineWithoutLT(DC,p2,l2);
  end;
end;

{procedure TNetExtender.TryConnectToEnts(var Objects:GDBObjOpenArrayOfPV;Position:TLineEnd;const drawing:TDrawingDef;var DC:TDrawContext);
var
  p:PGDBObjLine;
  ir:itrec;
  NetExtender:TNetExtender;
begin
  p:=Objects.beginiterate(ir);
  if p<>nil then
  repeat
    if (pointer(p)<>pThisEntity)and(IsIt(TypeOf(p^),typeof(GDBObjLine))) then begin
      NetExtender:=p^.GetExtension<TNetExtender>;
      if NetExtender<>nil then begin
        case Position of
          LBegin:begin
            if uzegeometry.IsPointEqual(PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,p^.CoordInWCS.lBegin) then begin
              drawArrow(PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,pThisEntity,DC);
              p^.addtoconnect2(p,PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjToConnectedArray);
              ConnectedWith.PushBackIfNotPresent(p);
            end;
            if uzegeometry.IsPointEqual(PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,p^.CoordInWCS.lEnd) then begin
              drawArrow(PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,pThisEntity,DC);
              p^.addtoconnect2(p,PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjToConnectedArray);
              ConnectedWith.PushBackIfNotPresent(p);
            end;
          end;
          LEnd:begin
            if uzegeometry.IsPointEqual(PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,p^.CoordInWCS.lBegin) then begin
              drawArrow(PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,pThisEntity,DC);
              p^.addtoconnect2(p,PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjToConnectedArray);
              ConnectedWith.PushBackIfNotPresent(p);
            end;
            if uzegeometry.IsPointEqual(PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,p^.CoordInWCS.lEnd) then begin
              drawArrow(PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,pThisEntity,DC);
              p^.addtoconnect2(p,PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjToConnectedArray);
              ConnectedWith.PushBackIfNotPresent(p);
            end;
          end;
        end;
      end;
    end;
  p:=Objects.iterate(ir);
  until p=nil;
end;}

procedure TNetExtender.TryConnectToEnts2(const p1,p2:GDBVertex;var Objects:GDBObjOpenArrayOfPV;const drawing:TDrawingDef;var DC:TDrawContext);
var
  p:PGDBObjLine;
  ir:itrec;
  NetExtender:TNetExtender;
  ip:Intercept3DProp;
  procedure addToConnections(t:double);
  var
    ci:integer;
    cp:TConnectPoint;
  begin
    cp:=TConnectPoint.Create(t);
    ci:=Connections.IsDataExistWithCompareProc(cp,IsConnectPointEqual);
    if ci=-1 then
      Connections.PushBackData(cp)
    else
      inc(Connections.getDataMutable(ci)^.count);
  end;
begin
  p:=Objects.beginiterate(ir);
  if p<>nil then
  repeat
    if (pointer(p)<>pThisEntity)and(IsIt(TypeOf(p^),typeof(GDBObjLine))) then begin
      NetExtender:=p^.GetExtension<TNetExtender>;
      if NetExtender<>nil then begin
        ip:=uzegeometry.intercept3d(p1,p2,p^.CoordInWCS.lBegin,p^.CoordInWCS.lEnd);
        if ip.isintercept then begin
          if uzegeometry.IsDoubleEqual(ip.t1,0,bigeps)then begin
            addToConnections(0);
            //drawArrow(PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,pThisEntity,DC);
            p^.addtoconnect2(p,PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjToConnectedArray);
            p^.addtoconnect2(p,PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjCasheArray);
            ConnectedWith.PushBackIfNotPresent(p);
          end else if uzegeometry.IsDoubleEqual(ip.t1,1,bigeps)then begin
            addToConnections(1);
            //drawArrow(PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,pThisEntity,DC);
            p^.addtoconnect2(p,PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjToConnectedArray);
            p^.addtoconnect2(p,PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjCasheArray);
            ConnectedWith.PushBackIfNotPresent(p);
          end else if (uzegeometry.IsDoubleEqual(ip.t2,0,bigeps))or(uzegeometry.IsDoubleEqual(ip.t2,1,bigeps))then begin
            addToConnections(ip.t1);
            //drawCross(ip.interceptcoord,pThisEntity,DC);
            p^.addtoconnect2(p,PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjToConnectedArray);
            p^.addtoconnect2(p,PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjCasheArray);
            ConnectedWith.PushBackIfNotPresent(p);
          end else begin
            if SqrVertexlength(p1,p2)>SqrVertexlength(p^.CoordInWCS.lBegin,p^.CoordInWCS.lEnd)then
              Intersects.PushBackData(ip.t1);
              IntersectedWith.PushBackIfNotPresent(p);
            p^.addtoconnect2(p,PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjToConnectedArray);
            p^.addtoconnect2(p,PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjCasheArray);
          end;
        end;
      end;
    end;
  p:=Objects.iterate(ir);
  until p=nil;
end;

function TNetExtender.NeedStandardDraw(pEntity:Pointer;const drawing:TDrawingDef;var DC:TDrawContext):Boolean;
var
  i:integer;
  pc:TConnectPoints.PT;
  d,l:double;
  oldP,P:GDBvertex;
begin
  result:=true;
  for i:=0 to Connections.Count-1 do begin
    pc:=Connections.getDataMutable(i);
    if SysVar.DISP.DISP_SystmGeometryDraw^ then begin
      if pc^.t=0 then
        drawArrow(PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,pThisEntity,DC)
      else if pc^.t=1 then
        drawArrow(PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,pThisEntity,DC)
      else
        drawCross(Vertexmorph(PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,pc^.t),pThisEntity,DC);
    end;
    if (pc^.count>2)or((pc^.t>bigeps)and(pc^.t<(1-bigeps))) then
      drawFilledCircle(Vertexmorph(PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,pc^.t),ConnectSize/2,pThisEntity,DC);
  end;
  oldP:=PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin;
  if Intersects.Count>0 then begin
    l:=0.5*IntersectSize/Vertexlength(PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd);
    for i:=0 to Intersects.Count-1 do begin
      d:=Intersects.getData(i);
      P:=Vertexmorph(PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,d-l);
      pThisEntity^.Representation.DrawLineWithLT(DC,oldP,P,pThisEntity.vp);
      oldP:=Vertexmorph(PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,d+l);
      P:=Vertexmorph(PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,d);
      drawIntersectArc(P,oldP,pThisEntity,DC);
    end;
    pThisEntity^.Representation.DrawLineWithLT(DC,oldP,PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,pThisEntity.vp);
    result:=false;
  end;
end;

initialization
  //extdrAdd(extdrNet)
  EntityExtenders.RegisterKey(uppercase(NetExtenderName),TNetExtender);
  GDBObjEntity.GetDXFIOFeatures.RegisterNamedLoadFeature('NETEXTENDER',TNetExtender.EntIOLoadNetExtender);
finalization
end.

