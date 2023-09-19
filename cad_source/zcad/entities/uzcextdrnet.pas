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
     gzctnrVectorSimple,gzctnrVectorTypes,uzeBaseExtender,uzgldrawcontext,
     uzegeometrytypes,uzcsysvars,
     uzctnrVectorDouble,gzctnrVector,garrayutils,
     uzcExtdrNetConnector,uzcEnitiesVariablesExtender;
const
  NetExtenderName='extdrNet';
  IntersectRadius=0.5;
  ConnectSize=1;
type
  TKnotType=(KTNormal,KTEmpty,KTArc,KTCircle,KTFilledCircle);
  TKnot=record
    t,HalfWidth:Double;
    &Type:TKnotType;
    constructor Create(const AT,AHW:Double;const AType:TKnotType);
  end;
  TKnots=GZVector<TKnot>;
  TKnotLess=class
    class function c(a,b:TKnot):boolean;
  end;
  TKnotsUtils=TOrderingArrayUtils<TKnots,TKnot,TKnotLess>;

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

TNetExtender=class(TBaseNetExtender)
    ConnectedWith,IntersectedWith:GDBObjOpenArrayOfPV;
    Connections:TConnectPoints;
    Knots:TKnots;
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
    procedure onEntityAfterConnect(pEntity:Pointer;const drawing:TDrawingDef;var DC:TDrawContext);override;
    procedure CopyExt2Ent(pSourceEntity,pDestEntity:pointer);override;
    procedure ReorganizeEnts(OldEnts2NewEntsMap:TMapPointerToPointer);override;
    procedure PostLoad(var context:TIODXFLoadContext);override;

    procedure onEntitySupportOldVersions(pEntity:pointer;const drawing:TDrawingDef);override;


    class function EntIOLoadNetExtender(_Name,_Value:String;ptu:PExtensionData;const drawing:TDrawingDef;PEnt:pointer):boolean;

    procedure SaveToDxfObjXData(var outhandle:TZctnrVectorBytes;PEnt:Pointer;var IODXFContext:TIODXFContext);override;

    //procedure TryConnectToEnts(var Objects:GDBObjOpenArrayOfPV;Position:TLineEnd;const drawing:TDrawingDef;var DC:TDrawContext);
    procedure TryConnectToEnts2(const p1,p2:GDBVertex;var Objects:GDBObjOpenArrayOfPV;const drawing:TDrawingDef;var DC:TDrawContext);
    procedure TryConnectToDeviceConnectors(const p1,p2:GDBVertex;var Device:GDBObjDevice;const drawing:TDrawingDef;var DC:TDrawContext);
    function NeedStandardDraw(pEntity:Pointer;const drawing:TDrawingDef;var DC:TDrawContext):Boolean;override;

    protected
      procedure AddToDWGPostProcs(pEntity:Pointer;const drawing:TDrawingDef);
  end;


function AddNetExtenderToEntity(PEnt:PGDBObjEntity):TNetExtender;

implementation
constructor TKnot.Create(const AT,AHW:Double;const AType:TKnotType);
begin
  t:=AT;
  HalfWidth:=AHW;
  &Type:=AType;
end;
class function TKnotLess.c(a,b:TKnot):boolean;
begin
  result:=a.t<b.t;
end;

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
  inherited;
  ConnectedWith.init(10);
  IntersectedWith.init(10);
  //Intersects.init(2);
  Connections.init(3);
  //Setters.init(2);
  //Pins.init(2);
  Knots.init(10);
  Net:=nil;
end;
destructor TNetExtender.Destroy;
begin
  inherited;
  ConnectedWith.destroy;
  IntersectedWith.destroy;
  //Intersects.destroy;
  Connections.destroy;
  //Setters.destroy;
  //Pins.destroy;
  Knots.destroy;
end;
procedure TNetExtender.Assign(Source:TBaseExtender);
begin
end;

procedure TNetExtender.AddToDWGPostProcs(pEntity:Pointer;const drawing:TDrawingDef);
var
  p:PGDBObjLine;
  ir:itrec;
begin
  if Assigned(Net) then
    Net.AddToDWGPostProcs(pEntity,drawing);

  {p:=ConnectedWith.beginiterate(ir);
  if p<>nil then
  repeat
    if p<>nil then
      PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjToConnectedArray.PushBackIfNotPresent(p);
      PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjCasheArray.PushBackIfNotPresent(p);
  p:=ConnectedWith.iterate(ir);
  until p=nil;
  ConnectedWith.Clear;}

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
var
  CNet:TNet;
begin
  if pThisEntity<>nil then begin
    if not PGDBObjEntity(pThisEntity)^.CheckState([ESConstructProxy,ESTemp]) then
   // if not (ESConstructProxy in pThisEntity^.State) then
      if IsIt(TypeOf(pThisEntity^),typeof(GDBObjLine)) then begin
        if Assigned(Net) then begin
          CNet:=Net;
          Net.RemoveConnection(Self);
          CNet.AddToDWGPostProcs(pEntity,drawing);
          if CNet.IsEmpty then
            CNet.Destroy;
        end;

        AddToDWGPostProcs(pThisEntity,drawing);

        pThisEntity^.addtoconnect2(pThisEntity,PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjToConnectedArray);
      end;
  end;
end;
procedure TNetExtender.onEntityAfterConnect(pEntity:Pointer;const drawing:TDrawingDef;var DC:TDrawContext);
var
  ppin:TBaseNetExtender;
  setter:TBaseNetExtender;
  ir,eir:itrec;
  SVExtdr,PVExtdr:TVariablesExtender;
  ConnectorExtender:TNetConnectorExtender;
begin
  if Assigned(Net) then begin
    setter:=Net.Setters.beginiterate(ir);
    if setter<>nil then
    repeat
      SVExtdr:=setter.pThisEntity^.GetExtension<TVariablesExtender>;

      ppin:=Net.Pins.beginiterate(eir);
      if ppin<>nil then
      repeat
        PVExtdr:=ppin.pThisEntity^.GetExtension<TVariablesExtender>;
        PVExtdr.EntityUnit.ConnectedUses.PushBackIfNotPresent(@SVExtdr.EntityUnit);
        ppin:=Net.Pins.iterate(eir);
      until ppin=nil;

      setter:=Net.Setters.iterate(ir);
    until setter=nil;
  end;
end;
procedure TNetExtender.onEntityConnect(pEntity:Pointer;const drawing:TDrawingDef;var DC:TDrawContext);
var
  Objects:GDBObjOpenArrayOfPV;
begin
  ConnectedWith.Clear;
  IntersectedWith.Clear;
  //Intersects.Clear;
  Connections.Clear;
  //Setters.Clear;
  //Pins.Clear;
  Knots.Clear;
  if pThisEntity<>nil then begin
    if not PGDBObjEntity(pThisEntity)^.CheckState([ESConstructProxy,ESTemp]) then
    //if not (ESConstructProxy in pThisEntity^.State) then
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
  if Knots.Count>1 then
    TKnotsUtils.Sort(Knots,Knots.Count);
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
  ConnectorExtender:TNetConnectorExtender;
  ip:Intercept3DProp;
  PTI:Pointer;
  dist:DistAndt;
  knot:TKnot;

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
    if pointer(p)<>pThisEntity then begin
      PTI:=TypeOf(p^);
      if IsIt(PTI,typeof(GDBObjLine)) then begin
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
              TNet.ConcatNets(self,NetExtender);
            end else if uzegeometry.IsDoubleEqual(ip.t1,1,bigeps)then begin
              addToConnections(1);
              //drawArrow(PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,pThisEntity,DC);
              p^.addtoconnect2(p,PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjToConnectedArray);
              p^.addtoconnect2(p,PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjCasheArray);
              ConnectedWith.PushBackIfNotPresent(p);
              TNet.ConcatNets(self,NetExtender);
            end else if (uzegeometry.IsDoubleEqual(ip.t2,0,bigeps))or(uzegeometry.IsDoubleEqual(ip.t2,1,bigeps))then begin
              addToConnections(ip.t1);
              //drawCross(ip.interceptcoord,pThisEntity,DC);
              p^.addtoconnect2(p,PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjToConnectedArray);
              p^.addtoconnect2(p,PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjCasheArray);
              ConnectedWith.PushBackIfNotPresent(p);
              TNet.ConcatNets(self,NetExtender);
            end else begin
              if SqrVertexlength(p1,p2)>SqrVertexlength(p^.CoordInWCS.lBegin,p^.CoordInWCS.lEnd)then
                Knots.PushBackData(TKnot.Create(ip.t1,IntersectRadius,KTArc));
                IntersectedWith.PushBackIfNotPresent(p);
              p^.addtoconnect2(p,PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjToConnectedArray);
              p^.addtoconnect2(p,PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjCasheArray);
            end;
          end;
        end;
      end else if IsIt(PTI,typeof(GDBObjDevice)) then begin
        ConnectorExtender:=p^.GetExtension<TNetConnectorExtender>;
        if ConnectorExtender=nil then
          TryConnectToDeviceConnectors(p1,p2,PGDBObjDevice(p)^,drawing,DC)
        else begin
          dist:=distance2ray(PGDBObjDevice(p).P_insert_in_WCS,p1,p2);
          if (abs(dist.d)<bigeps)and((dist.t>-bigeps)and((dist.t<1+bigeps))) then begin
            knot.Create(dist.t,abs(ConnectorExtender.FConnectorRadius)/2,KTNormal);
            if ConnectorExtender.FConnectorRadius<>0 then
              knot.&Type:=KTEmpty;
            Knots.PushBackData(knot);
            if not Assigned(Net) then begin
              Net:=TNet.Create;
              Net.AddConnection(Self);
            end;
            if ConnectorExtender.FSetter then
              Net.AddSetter(ConnectorExtender)
            else begin
              Net.AddPin(ConnectorExtender);
              PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjToConnectedArray.PushBackIfNotPresent(p);
              PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjCasheArray.PushBackIfNotPresent(p);
            end;
          end;
        end;
      end;
    end;
  p:=Objects.iterate(ir);
  until p=nil;
end;

procedure TNetExtender.TryConnectToDeviceConnectors(const p1,p2:GDBVertex;var Device:GDBObjDevice;const drawing:TDrawingDef;var DC:TDrawContext);
var
  p:PGDBObjDevice;
  ir:itrec;
  ConnectorExtender:TNetConnectorExtender;
  knot:TKnot;
  t:Double;
  isConnected:boolean;
begin
  p:=Device.VarObjArray.beginiterate(ir);
  if p<>nil then
  repeat

    if IsIt(TypeOf(p^),typeof(GDBObjDevice)) then begin
      ConnectorExtender:=p^.GetExtension<TNetConnectorExtender>;
      if ConnectorExtender=nil then
        TryConnectToDeviceConnectors(p1,p2,PGDBObjDevice(p)^,drawing,DC)
      else begin
        isConnected:=true;
        if IsPointEqual(p1,p^.P_insert_in_WCS) then
          t:=0
        else if IsPointEqual(p2,p^.P_insert_in_WCS) then
          t:=1
        else
          isConnected:=false;
        if isConnected then begin
          knot.Create(t,abs(ConnectorExtender.FConnectorRadius)/2,KTNormal);
          if ConnectorExtender.FConnectorRadius<>0 then
            knot.&Type:=KTEmpty;
          Knots.PushBackData(knot);
          if not Assigned(Net) then begin
            Net:=TNet.Create;
            Net.AddConnection(Self);
          end;
          if ConnectorExtender.FSetter then
            Net.AddSetter(ConnectorExtender)
          else begin
            Net.AddPin(ConnectorExtender);
            PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjToConnectedArray.PushBackIfNotPresent(p);
            PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.ObjCasheArray.PushBackIfNotPresent(p);
          end;
        end;
      end;
    end;
    p:=Device.VarObjArray.iterate(ir);
  until p=nil;
end;

function TNetExtender.NeedStandardDraw(pEntity:Pointer;const drawing:TDrawingDef;var DC:TDrawContext):Boolean;
var
  i:integer;
  pc:TConnectPoints.PT;
  linelen,l:double;
  knot:TKnot;
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
  if Knots.Count>0 then begin
    linelen:=Vertexlength(PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd);
    for i:=0 to Knots.Count-1 do begin
      knot:=Knots.getData(i);
      l:=knot.HalfWidth/linelen;
      case knot.&Type of
        KTArc:begin
          P:=Vertexmorph(PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,knot.t-l);
          pThisEntity^.Representation.DrawLineWithLT(DC,oldP,P,pThisEntity.vp);
          oldP:=Vertexmorph(PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,knot.t+l);
          P:=Vertexmorph(PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,knot.t);
          drawIntersectArc(P,oldP,pThisEntity,DC);
        end;
        KTEmpty:begin
          if knot.t>bigeps then begin
            P:=Vertexmorph(PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,knot.t-l);
            pThisEntity^.Representation.DrawLineWithLT(DC,oldP,P,pThisEntity.vp);
          end;
          oldP:=Vertexmorph(PGDBObjLine(pThisEntity)^.CoordInWCS.lBegin,PGDBObjLine(pThisEntity)^.CoordInWCS.lEnd,knot.t+l);
        end;
      end;
    end;
    if IsDoubleNotEqual(knot.t,1,bigeps) then
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

