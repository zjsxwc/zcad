﻿{
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

unit GDBSubordinated;
{$INCLUDE def.inc}

interface
uses ugdbdrawingdef,gdbobjectsconstdef,strproc{$IFNDEF DELPHI},LCLProc{$ENDIF},UGDBOpenArrayOfByte,devices,gdbase,gdbasetypes,varman,varmandef,
     dxflow,UBaseTypeDescriptor,sysutils,UGDBLayerArray{,strutils};
type
//Owner:PGDBObjGenericWithSubordinated;(*'Владелец'*)
//PSelfInOwnerArray:TArrayIndex;(*'Индекс у владельца'*)

{EXPORT+}
PGDBObjSubordinated=^GDBObjSubordinated;
PGDBObjGenericWithSubordinated=^GDBObjGenericWithSubordinated;
GDBObjGenericWithSubordinated={$IFNDEF DELPHI}packed{$ENDIF} object(GDBaseObject)
                                    OU:TObjectUnit;(*'Variables'*)
                                    function ImEdited(pobj:PGDBObjSubordinated;pobjinarray:GDBInteger;const drawing:TDrawingDef):GDBInteger;virtual;
                                    function ImSelected(pobj:PGDBObjSubordinated;pobjinarray:GDBInteger):GDBInteger;virtual;
                                    procedure DelSelectedSubitem(const drawing:TDrawingDef);virtual;
                                    //function AddMi(pobj:PGDBObjSubordinated):PGDBpointer;virtual;abstract;
                                    //procedure RemoveInArray(pobjinarray:GDBInteger);virtual;abstract;
                                    function CreateOU:GDBInteger;virtual;
                                    procedure createfield;virtual;
                                    function FindVariable(varname:GDBString):pvardesk;virtual;
                                    function ProcessFromDXFObjXData(_Name,_Value:GDBString;ptu:PTUnit):GDBBoolean;virtual;
                                    destructor done;virtual;
                                    function GetMatrix:PDMatrix4D;virtual;abstract;
                                    //function GetLineWeight:GDBSmallint;virtual;abstract;
                                    function GetLayer:PGDBLayerProp;virtual;abstract;
                                    function GetHandle:GDBPlatformint;virtual;
                                    function GetType:GDBPlatformint;virtual;
                                    function IsSelected:GDBBoolean;virtual;abstract;
                                    procedure FormatAfterDXFLoad(const drawing:TDrawingDef);virtual;
                                    procedure CalcGeometry;virtual;

                                    procedure Build(const drawing:TDrawingDef);virtual;


end;
TEntityAdress=packed record
                          Owner:PGDBObjGenericWithSubordinated;(*'Adress'*)
                          SelfIndex:TArrayIndex;(*'Position'*)
              end;
TTreeAdress=packed record
                          Owner:GDBPointer;(*'Adress'*)
                          SelfIndex:TArrayIndex;(*'Position'*)
              end;
GDBObjBaseProp=packed record
                      ListPos:TEntityAdress;(*'List'*)
                      TreePos:TTreeAdress;(*'Tree'*)
                 end;
GDBObjSubordinated={$IFNDEF DELPHI}packed{$ENDIF} object(GDBObjGenericWithSubordinated)
                         bp:GDBObjBaseProp;(*'Owner'*)(*oi_readonly*)(*hidden_in_objinsp*)
                         function GetOwner:PGDBObjSubordinated;virtual;abstract;
                         procedure createfield;virtual;
                         function FindVariable(varname:GDBString):pvardesk;virtual;
                         procedure SaveToDXFObjXData(var outhandle:{GDBInteger}GDBOpenArrayOfByte);virtual;
                         function FindShellByClass(_type:TDeviceClass):PGDBObjSubordinated;virtual;
                         destructor done;virtual;

         end;
{EXPORT-}
procedure CreateDeviceNameProcess(pEntity:PGDBObjGenericWithSubordinated;const drawing:TDrawingDef);
procedure CreateDBLinkProcess(pEntity:PGDBObjGenericWithSubordinated;const drawing:TDrawingDef);
procedure CreateDeviceNameSubProcess(pvn:pvardesk; const formatstr:GDBString;pEntity:PGDBObjGenericWithSubordinated);
function GetEntName(pu:PGDBObjGenericWithSubordinated):GDBString;
implementation
uses {UGDBDescriptor,}UUnitManager,URecordDescriptor,shared,log,GDBAbstractText,devicebaseabstract;
destructor GDBObjSubordinated.done;
begin
     inherited;
end;

function GDBObjSubordinated.FindShellByClass(_type:TDeviceClass):PGDBObjSubordinated;
var
   pvd:pvardesk;
begin
     result:=nil;
     pvd:=ou.FindVariable('Device_Class');
     if pvd<>nil then
     if PTDeviceClass(pvd^.data.Instance)^=_type then
                                                      result:=@self;
     if result=nil then
                       if bp.ListPos.owner<>nil then
                                             result:=PGDBObjSubordinated(bp.ListPos.owner).FindShellByClass(_type);
                                                                      
end;
procedure CreateDeviceNameSubProcess(pvn:pvardesk; const formatstr:GDBString; pEntity:PGDBObjGenericWithSubordinated);
begin
     if (pvn<>nil) then
     begin
     if (formatstr<>'') then
                                      begin
                                           if pEntity<>nil then
                                                               pstring(pvn^.data.Instance)^:=textformat(formatstr,pEntity)
                                                            else
                                                               pstring(pvn^.data.Instance)^:='!!ERR(pEnttity=nil)';
                                           pvn^.attrib:=pvn^.attrib or vda_RO;
                                      end
                                         else
                                             pvn^.attrib:=pvn^.attrib and (not vda_RO);
     end;

end;
procedure CreateDBLinkProcess(pEntity:PGDBObjGenericWithSubordinated;const drawing:TDrawingDef);
var
   pvn,pvnt,pdbv:pvardesk;
   pdbu:ptunit;
begin
     pvn:=pEntity^.OU.FindVariable('DB_link');
     pvnt:=pEntity^.OU.FindVariable('DB_MatName');
     if pvnt<>nil then
     pvnt^.attrib:=pvnt^.attrib or (vda_RO);
     if (pvn<>nil)and(pvnt<>nil) then
     begin
          pdbu:={gdb.GetCurrentDWG}drawing.GetDWGUnits^.findunit(DrawingDeviceBaseUnitName);
          pdbv:=pdbu^.FindVariable(pstring(pvn.data.Instance)^);
          if pdbv<>nil then
                           pstring(pvnt.data.Instance)^:=PDbBaseObject(pdbv.data.Instance)^.Name
                       else
                           pstring(pvnt.data.Instance)^:='Error!!!'
     end;
end;
procedure CreateDeviceNameProcess(pEntity:PGDBObjGenericWithSubordinated;const drawing:TDrawingDef);
var
   pvn,pvnt{,pdbv}:pvardesk;
   //pdbu:ptunit;
begin
     pvn:=pEntity^.OU.FindVariable('NMO_Name');
     pvnt:=pEntity^.OU.FindVariable('NMO_Template');

     if (pvnt<>nil) then
     CreateDeviceNameSubProcess(pvn,pstring(pvnt^.data.Instance)^,pEntity);

     CreateDBLinkProcess(pentity,drawing);
end;
function GetEntName(pu:PGDBObjGenericWithSubordinated):GDBString;
var
   pvn{,pvnt}:pvardesk;
begin
     result:='';
     pvn:=pu^.OU.FindVariable('NMO_Name');
     if (pvn<>nil) then
                                      begin
                                           result:=pstring(pvn^.data.Instance)^;
                                      end;
end;
procedure GDBObjSubordinated.SaveToDXFObjXData(var outhandle:{GDBInteger}GDBOpenArrayOfByte);
begin
     dxfGDBStringout(outhandle,1000,'_OWNERHANDLE='+inttohex(bp.ListPos.owner.GetHandle,10));
end;
function GDBObjGenericWithSubordinated.GetType:GDBPlatformint;
begin
     result:=0;
end;
function GDBObjGenericWithSubordinated.GetHandle:GDBPlatformint;
begin
     result:=GDBPlatformint(@self);
end;
destructor GDBObjGenericWithSubordinated.done;
begin
     ou.done;
end;
procedure GDBObjGenericWithSubordinated.FormatAfterDXFLoad;
begin
     //format;
     //CalcObjMatrix;
     //calcbb;
end;
procedure GDBObjGenericWithSubordinated.CalcGeometry;
begin

end;

procedure extractvarfromdxfstring(_Value:GDBString;out vn,vt,vv,vun:GDBString);
var i:integer;
begin
    i:=pos('|',_value);
    vn:=copy(_value,1,i-1);
    _Value:=copy(_value,i+1,length(_value)-i);
    i:=pos('|',_value);
    vt:=copy(_value,1,i-1);
    _Value:=copy(_value,i+1,length(_value)-i);
    i:=pos('|',_value);
    vv:=copy(_value,1,i-1);
    vun:=copy(_value,i+1,length(_value)-i);
end;
procedure extractvarfromdxfstring2(_Value:GDBString;out vn,vt,vun:GDBString);
var i:integer;
begin
    i:=pos('|',_value);
    vn:=copy(_value,1,i-1);
    _Value:=copy(_value,i+1,length(_value)-i);
    i:=pos('|',_value);
    vt:=copy(_value,1,i-1);
    vun:=copy(_value,i+1,length(_value)-i);
end;
function ansitoutf8ifneed(var s:GDBString):boolean;
begin
     {$IFNDEF DELPHI}
     if FindInvalidUTF8Character(@s[1],length(s),false)<>-1
        then
            begin
             s:=Tria_AnsiToUtf8(s);
             //HistoryOutStr('ANSI->UTF8 '+s);
             result:=true;
            end
        else
        {$ENDIF}
            result:=false;
end;
procedure OldVersVarRename(var vn,vt,vv,vun:GDBString);
var
   nevname{,nvv}:GDBString;
begin
     {ansitoutf8ifneed(vn);
     ansitoutf8ifneed(vt);}
     ansitoutf8ifneed(vv);
     ansitoutf8ifneed(vun);
     nevname:='';
     if vn='Name' then
                      begin
                           nevname:='NMO_Name';
                      end;
     if vn='ShortName' then
                      begin
                           nevname:='NMO_BaseName';
                      end;
     if vn='Name_Template' then
                      begin
                           nevname:='NMO_Template';
                      end;
     if vn='Material' then
                      begin
                           nevname:='DB_link';
                      end;
     if vn='HeadDevice' then
                      begin
                           nevname:='GC_HeadDevice';
                           vun:='Обозначение головного устройства'
                      end;
     if vn='HeadDShortName' then
                      begin
                           nevname:='GC_HDShortName';
                           vun:='Короткое Обозначение головного устройства'
                      end;
     if vn='GroupInHDevice' then
                      begin
                           nevname:='GC_HDGroup';
                           vun:='Группа'
                      end;
     if vn='NumberInSleif' then
                      begin
                           nevname:='GC_NumberInGroup';
                           vun:='Номер в группе'
                      end;
     if vn='RoundTo' then
                      begin
                           nevname:='LENGTH_RoundTo';
                      end;
     if vn='Cable_AddLength' then
                      begin
                           nevname:='LENGTH_Add';
                      end;
     if vn='Cable_Scale' then
                      begin
                           nevname:='LENGTH_Scale';
                      end;
     if vn='TotalConnectedDevice' then
                      begin
                           nevname:='CABLE_TotalCD';
                      end;
     if vn='Segment' then
                      begin
                           nevname:='CABLE_Segment';
                      end;
     if vn='Cable_Type' then
                      begin
                           nevname:='CABLE_Type';
                      end;
     if  (vn='GC_HDGroup')
     and (vt<>'GDBString')  then
                           begin
                                vt:='GDBString';
                                //vv:=''''+vv+'''';
                           end;

     OldVersTextReplace(vv);
     if nevname<>'' then
                        begin
                             //shared.HistoryOutStr('Старая переменная '+vn+' обновлена до '+nevname);
                             vn:=nevname;
                        end;

end;
procedure GDBObjGenericWithSubordinated.Build;
begin

end;
function GDBObjGenericWithSubordinated.ProcessFromDXFObjXData;
var //APP_NAME:GDBString;
    //XGroup:GDBInteger;
//    XValue:GDBString;
    svn,vn,vt,vv,vun:GDBString;
//    i:integer;
    vd: vardesk;
    pvd:pvardesk;
    uou:PTObjectUnit;
    offset:GDBInteger;
    tc:PUserTypeDescriptor;
begin
     result:=false;
     if length(_name)>1 then
     begin
           if _Name[1]='#' then
                             begin
                                  extractvarfromdxfstring(_Value,vn,vt,vv,vun);
                                  if vv='3.1' then
                                                  vv:=vv;
                                  
                                  OldVersVarRename(vn,vt,vv,vun);
                                  ou.setvardesc(vd,vn,vun,vt);
                                  ou.InterfaceVariables.createvariable(vd.name,vd);
                                  PBaseTypeDescriptor(vd.data.PTD)^.SetValueFromString(vd.data.Instance,vv);
                                  result:=true;
                             end
      else if _Name[1]='%' then
                             begin
                                  extractvarfromdxfstring(_Value,vn,vt,vv,vun);

                                  ptu.setvardesc(vd,vn,vun,vt);
                                  ptu.InterfaceVariables.createvariable(vd.name,vd);
                                  PBaseTypeDescriptor(vd.data.PTD)^.SetValueFromString(vd.data.Instance,vv);
                                  result:=true;
                             end
      else if _Name[1]='&' then
                             begin
                                  extractvarfromdxfstring2(_Value,vn,vt,vun);

                                  ou.setvardesc(vd,vn,vun,vt);
                                  ou.InterfaceVariables.createvariable(vd.name,vd);
                                  result:=true;
                             end
      else if _Name[1]='$' then
                             begin
                                  extractvarfromdxfstring2(_Value,vn,svn,vv);
                                  pvd:=ou.InterfaceVariables.findvardesc(vn);
                                  offset:=GDBPlatformint(pvd.data.Instance);
                                  if pvd<>nil then
                                  begin
                                       PRecordDescriptor(pvd^.data.PTD)^.ApplyOperator('.',svn,offset,tc);
                                  end;
                                  PBaseTypeDescriptor(tc)^.SetValueFromString(pointer(offset),vv);
                                  result:=true;
                             end
      else if _Name='USES' then
                             begin
                                  uou:=pointer(units.findunit(_Value));
                                  ou.InterfaceUses.addnodouble(@uou);
                                  result:=true;
                             end;
     end;

end;
procedure GDBObjSubordinated.createfield;
begin
     inherited;
     bp.ListPos.owner:={gdb.GetCurrentROOT}nil;
     bp.ListPos.SelfIndex:=-1{nil};
end;
procedure GDBObjGenericWithSubordinated.createfield;
begin
     inherited;
     OU.init('Entity');
     ou.InterfaceUses.add(@SysUnit);
end;
function GDBObjGenericWithSubordinated.FindVariable;
begin
     result:=ou.FindVariable(varname);
end;
function GDBObjSubordinated.FindVariable;
begin
     result:=ou.FindVariable(varname);
     if result=nil then
                       if self.bp.ListPos.Owner<>nil then
                                                 result:=self.bp.ListPos.Owner.FindVariable(varname);

end;
function GDBObjGenericWithSubordinated.CreateOU;
begin
end;
function GDBObjGenericWithSubordinated.ImEdited;
begin
end;
function GDBObjGenericWithSubordinated.ImSelected;
begin
end;
procedure GDBObjGenericWithSubordinated.DelSelectedSubitem;
begin
end;
begin
  {$IFDEF DEBUGINITSECTION}LogOut('GDBSubordinated.initialization');{$ENDIF}
end.
