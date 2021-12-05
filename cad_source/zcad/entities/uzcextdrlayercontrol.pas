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
unit uzcExtdrLayerControl;
{$M+}

interface

uses SysUtils,uzedrawingdef,uzeentityextender,
     uzeentdevice,TypeDescriptors,uzetextpreprocessor,UGDBOpenArrayOfByte,
     uzbtypesbase,uzbtypes,uzeentsubordinated,uzeentity,uzeenttext,uzeblockdef,
     varmandef,Varman,UUnitManager,URecordDescriptor,UBaseTypeDescriptor,uzbmemman,
     uzeffdxfsupport,uzcvariablesutils,usimplegenerics,
     uzeBaseExtender,uzgldrawcontext,fpexprpars,LCLProc;
const
  LayerControlExtenderName='extdrLayerControl';
  //добавить это расширение к примитиву можно командой
  //extdrAdd(extdrLayerControl)
type
  ELayerControlExtender=class(Exception);
  TLayerControlExtender=class(TBaseEntityExtender)
    //private
    public
      FExpression:GDBString;
      FParser:TFPExpressionParser;
      pEnt:Pointer;
    public
      GoodLayer,BadLayer:GDBString;
      procedure SetExpression(const AExpression:String);
      function GetExpression:String;
      class function getExtenderName:string;override;
      constructor Create(pEntity:Pointer);override;
      procedure Assign(Source:TBaseExtender);override;
      procedure onEntityClone(pSourceEntity,pDestEntity:pointer);override;
      procedure CopyExt2Ent(pSourceEntity,pDestEntity:pointer);override;
      procedure CreateParser(pEntity:Pointer);
      function SetVariableType(pEntity:Pointer;ID:TFPExprIdentifierDef):Boolean;
      procedure GetVariableValue(Var Result : TFPExpressionResult; ConstRef AName : ShortString);
      procedure onBeforeEntityFormat(pEntity:Pointer;const drawing:TDrawingDef;var DC:TDrawContext);override;
      procedure onAfterEntityFormat(pEntity:Pointer;const drawing:TDrawingDef;var DC:TDrawContext);override;
      procedure SaveToDxf(var outhandle:GDBOpenArrayOfByte;PEnt:Pointer;var IODXFContext:TIODXFContext);override;
      procedure ReorganizeEnts(OldEnts2NewEntsMap:TMapPointerToPointer);override;
      procedure PostLoad(var context:TIODXFLoadContext);override;
      class function EntIOLoadGoodLayer(_Name,_Value:GDBString;ptu:PExtensionData;const drawing:TDrawingDef;PEnt:pointer):boolean;
      class function EntIOLoadBadLayer(_Name,_Value:GDBString;ptu:PExtensionData;const drawing:TDrawingDef;PEnt:pointer):boolean;
      class function EntIOLoadExpression(_Name,_Value:GDBString;ptu:PExtensionData;const drawing:TDrawingDef;PEnt:pointer):boolean;

      procedure onEntitySupportOldVersions(pEntity:pointer;const drawing:TDrawingDef);override;
      published
        property Expr:String read GetExpression write SetExpression;
    end;

implementation

procedure TLayerControlExtender.ReorganizeEnts(OldEnts2NewEntsMap:TMapPointerToPointer);
begin
end;

function AddLayerControlExtenderToEntity(PEnt:PGDBObjEntity):TLayerControlExtender;
begin
  result:=TLayerControlExtender.Create(PEnt);
  PEnt^.AddExtension(result);
end;

procedure TLayerControlExtender.onEntityClone(pSourceEntity,pDestEntity:pointer);
var
    pDestLayerControlExtender:TLayerControlExtender;
begin
     pDestLayerControlExtender:=PGDBObjEntity(pDestEntity)^.EntExtensions.GetExtension<TLayerControlExtender>;
     if pDestLayerControlExtender=nil then
                       pDestLayerControlExtender:=AddLayerControlExtenderToEntity(pDestEntity);
     pDestLayerControlExtender.Assign(self);
end;

procedure TLayerControlExtender.CopyExt2Ent(pSourceEntity,pDestEntity:pointer);
begin
     onEntityClone(pSourceEntity,pDestEntity);
end;


procedure TLayerControlExtender.SetExpression(const AExpression:String);
begin
end;

function TLayerControlExtender.GetExpression:String;
begin
  result:=FExpression;
end;


procedure TLayerControlExtender.Assign(Source:TBaseExtender);
begin
  GoodLayer:=TLayerControlExtender(Source).GoodLayer;
  BadLayer:=TLayerControlExtender(Source).BadLayer;
  FExpression:=TLayerControlExtender(Source).FExpression;
end;

constructor TLayerControlExtender.Create(pEntity:Pointer);
begin
  GoodLayer:='EL_DEVICE_NAME';
  BadLayer:='SYS_METRIC';
  FExpression:='Test';
  FParser:=nil;
end;

procedure TLayerControlExtender.onAfterEntityFormat(pEntity:Pointer;const drawing:TDrawingDef;var DC:TDrawContext);
begin
end;

procedure Err(msg:string);
begin
  Raise EExprScanner.Create(Msg);
end;

function tryCalcFPExpressionParserResultType(ptd:PUserTypeDescriptor; var RT:TResultType):boolean;
var
  tRT:TResultType;
begin
  tRT:=rtAuto;
  if (ptd=@FundamentalDoubleDescriptorObj)or(ptd=@FundamentalSingleDescriptorObj) then
    tRT:=rtFloat
  else if (ptd=@FundamentalUnicodeStringDescriptorObj)or(ptd=@FundamentalStringDescriptorObj)or(ptd=@FundamentalAnsiStringDescriptorObj) then
    tRT:=rtString
  else if (ptd=@FundamentalWordDescriptorObj)or(ptd=@FundamentalLongIntDescriptorObj)or(ptd=@FundamentalByteDescriptorObj)
        or(ptd=@FundamentalSmallIntDescriptorObj)or(ptd=@FundamentalLongWordDescriptorObj)
        or(ptd=@FundamentalQWordDescriptorObj)or(ptd=@FundamentalInt64Descriptor)or(ptd=@FundamentalShortIntDescriptorObj) then
    tRT:=rtInteger
  else if (ptd=@FundamentalBooleanDescriptorOdj)then
    tRT:=rtBoolean;
  if tRT<>rtAuto then begin
    result:=true;
    RT:=tRT;
  end else
    Result:=False;
end;

procedure TLayerControlExtender.GetVariableValue(Var Result : TFPExpressionResult; ConstRef AName : ShortString);
var
  pvd:pvardesk;
  rt:TResultType;
  ptd:PUserTypeDescriptor;
begin
  if pEnt=nil then
    Err('call TLayerControlExtender.GetVariableValue with pEnt=nil');
  pvd:=FindVariableInEnt(PGDBObjEntity(pEnt),AName);

  if pvd=nil then
    Err('TLayerControlExtender.GetVariableValue variable "'+AName+'" not found');

  ptd:=pvd^.data.PTD.GetFactTypedef;
  if not tryCalcFPExpressionParserResultType(ptd,rt)then
    Err('TLayerControlExtender.GetVariableValue not found TResultType for "'+AName+'" variable');

  if rt<>Result.ResultType then
    Err('TLayerControlExtender.GetVariableValue wrong TResultType for "'+AName+'" variable');

  if ptd=@FundamentalDoubleDescriptorObj then
    result.ResFloat := PDouble(pvd^.data.Instance)^
  else if ptd=@FundamentalSingleDescriptorObj then
    result.ResFloat := PSingle(pvd^.data.Instance)^
  else if (ptd=@FundamentalUnicodeStringDescriptorObj)or(ptd=@FundamentalStringDescriptorObj)or(ptd=@FundamentalAnsiStringDescriptorObj) then
    result.ResString:=ptd.GetValueAsString(pvd^.data.Instance)
  else if ptd=@FundamentalWordDescriptorObj then
    result.ResInteger := PWord(pvd^.data.Instance)^
  else if ptd=@FundamentalLongIntDescriptorObj then
    result.ResInteger := PLongint(pvd^.data.Instance)^
  else if ptd=@FundamentalByteDescriptorObj then
    result.ResInteger := PByte(pvd^.data.Instance)^
  else if ptd=@FundamentalSmallIntDescriptorObj then
    result.ResInteger := PSmallInt(pvd^.data.Instance)^
  else if ptd=@FundamentalLongWordDescriptorObj then
    result.ResInteger := PLongWord(pvd^.data.Instance)^
  else if ptd=@FundamentalQWordDescriptorObj then
    result.ResInteger := PQWord(pvd^.data.Instance)^
  else if ptd=@FundamentalInt64Descriptor then
    result.ResInteger := PInt64(pvd^.data.Instance)^
  else if ptd=@FundamentalShortIntDescriptorObj then
    result.ResInteger := PShortInt(pvd^.data.Instance)^
  else if ptd=@FundamentalBooleanDescriptorOdj then
    result.ResBoolean := PBoolean(pvd^.data.Instance)^
  else
    Err('TLayerControlExtender.GetVariableValue wrong PTD for "'+AName+'" variable');

end;

function TLayerControlExtender.SetVariableType(pEntity:Pointer;ID:TFPExprIdentifierDef):Boolean;
var
  pvd:pvardesk;
  ptd:PUserTypeDescriptor;
  rt:TResultType;
begin
  result:=false;
  if pEnt<>nil then begin
    pvd:=FindVariableInEnt(PGDBObjEntity(pEnt),ID.Name);
    if pvd<>nil then begin
      ptd:=pvd^.data.PTD.GetFactTypedef;
      if tryCalcFPExpressionParserResultType(ptd,rt)then begin
        ID.ResultType:=rt;
        result:=true;
        ID.OnGetVariableValue:=GetVariableValue;
      end;
    end;
  end;
end;

procedure TLayerControlExtender.CreateParser(pEntity:Pointer);
var
  i:Integer;
  allOk:Boolean;
begin
  FParser := TFPExpressionParser.Create(nil);
  FParser.BuiltIns:=[bcMath];
  FParser.CheckVariables:=True;
  FParser.Expression:=Expr;

  allOk:=True;

  for i:=0 to FParser.Identifiers.Count-1 do
    if FParser.Identifiers[i].IsAutoGeneratedVar then begin
      allOk:=allOk and SetVariableType(pEntity,FParser.Identifiers[i]);
      if not allOk then
        system.break;
    end;

  if allOk then
    FParser.CheckVariables:=False;

  if not allOk then
    FreeAndNil(FParser);
end;

procedure TLayerControlExtender.onBeforeEntityFormat(pEntity:Pointer;const drawing:TDrawingDef;var DC:TDrawContext);
var
  pl:pointer;
  ExpressionResult:TFPExpressionResult;
begin
  pEnt:=pEntity;
  if FParser<>nil then
    FreeAndNil(FParser);
  try
    try
      if FParser=nil then
        CreateParser(pEntity);
      if FParser<>nil then begin
        ExpressionResult:=FParser.Evaluate;
        case ExpressionResult.ResultType of
          rtBoolean:begin
                      if ExpressionResult.ResBoolean then
                        pl:=drawing.GetLayerTable^.getAddres(GoodLayer)
                      else
                        pl:=drawing.GetLayerTable^.getAddres(BadLayer);
                      if pl<>nil then
                        PGDBObjEntity(pEntity)^.vp.Layer:=pl;
                    end
          else
            PGDBObjEntity(pEntity)^.vp.Layer:=PGDBObjEntity(pEntity)^.vp.Layer;
        end;
      end;
    except
       on E:Exception do
            DbgOut('{EM}Entity"%p".TLayerControlExtender.Expr="%s" raise "%s"',[pEntity,Expr,E.Message]);
         //raise ELayerControlExtender.CreateFmt('TLayerControlExtender error for expression "%s": %s',[Expr,E.Message]);
    end;
  finally
    FreeAndNil(FParser);
  end;
  pEnt:=Nil;
end;

class function TLayerControlExtender.getExtenderName:string;
begin
  result:=LayerControlExtenderName;
end;

procedure TLayerControlExtender.SaveToDxf(var outhandle:GDBOpenArrayOfByte;PEnt:Pointer;var IODXFContext:TIODXFContext);
begin
  dxfGDBStringout(outhandle,1000,'LCGoodLayer='+GoodLayer);
  dxfGDBStringout(outhandle,1000,'LCBadLayer='+BadLayer);
  dxfGDBStringout(outhandle,1000,'LCExpression='+FExpression);
end;

procedure TLayerControlExtender.PostLoad(var context:TIODXFLoadContext);
begin
end;

class function TLayerControlExtender.EntIOLoadGoodLayer(_Name,_Value:GDBString;ptu:PExtensionData;const drawing:TDrawingDef;PEnt:pointer):boolean;
var
  LCExtdr:TLayerControlExtender;
begin
  LCExtdr:=PGDBObjEntity(PEnt)^.GetExtension<TLayerControlExtender>;
  if LCExtdr=nil then
    LCExtdr:=AddLayerControlExtenderToEntity(PEnt);
  LCExtdr.GoodLayer:=_Value;
  result:=true;
end;

class function TLayerControlExtender.EntIOLoadBadLayer(_Name,_Value:GDBString;ptu:PExtensionData;const drawing:TDrawingDef;PEnt:pointer):boolean;
var
  LCExtdr:TLayerControlExtender;
begin
  LCExtdr:=PGDBObjEntity(PEnt)^.GetExtension<TLayerControlExtender>;
  if LCExtdr=nil then
    LCExtdr:=AddLayerControlExtenderToEntity(PEnt);
  LCExtdr.BadLayer:=_Value;
  result:=true;
end;

class function TLayerControlExtender.EntIOLoadExpression(_Name,_Value:GDBString;ptu:PExtensionData;const drawing:TDrawingDef;PEnt:pointer):boolean;
var
  LCExtdr:TLayerControlExtender;
begin
  LCExtdr:=PGDBObjEntity(PEnt)^.GetExtension<TLayerControlExtender>;
  if LCExtdr=nil then
    LCExtdr:=AddLayerControlExtenderToEntity(PEnt);
  LCExtdr.FExpression:=_Value;
  result:=true;
end;

procedure TLayerControlExtender.onEntitySupportOldVersions(pEntity:pointer;const drawing:TDrawingDef);
begin
end;

initialization
  EntityExtenders.RegisterKey(uppercase(LayerControlExtenderName),TLayerControlExtender);
  GDBObjEntity.GetDXFIOFeatures.RegisterNamedLoadFeature('LCGoodLayer',TLayerControlExtender.EntIOLoadGoodLayer);
  GDBObjEntity.GetDXFIOFeatures.RegisterNamedLoadFeature('LCBadLayer',TLayerControlExtender.EntIOLoadBadLayer);
  {Для совместимолти, потом убрать}GDBObjEntity.GetDXFIOFeatures.RegisterNamedLoadFeature('LCVariableName',TLayerControlExtender.EntIOLoadExpression);
  GDBObjEntity.GetDXFIOFeatures.RegisterNamedLoadFeature('LCExpression',TLayerControlExtender.EntIOLoadExpression);
finalization
end.
