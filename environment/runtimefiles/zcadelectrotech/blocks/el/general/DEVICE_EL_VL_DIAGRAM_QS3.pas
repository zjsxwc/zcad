unit DEVICE_EL_VL_DIAGRAM_DIAGRAM_QS3;

interface

uses system,devices;
usescopy blocktype;
usescopy objname;

var

T1:GDBString;(*'Обозначение'*)
T2:GDBString;(*'Марка'*)
T3:GDBString;(*'Параметры'*)

T11:Integer;(*'123'*)

implementation

begin

BTY_TreeCoord:='PLAN_EM_Аппаратура';
Device_Type:=TDT_SilaPotr;
Device_Class:=TDC_Shell;

NMO_Name:='А0';
NMO_BaseName:='А';
NMO_Suffix:='??';
NMO_Affix:='.2';

T1:='??';
T2:='??';
T3:='??';

T11:=3;

end.