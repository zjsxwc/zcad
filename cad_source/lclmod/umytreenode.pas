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

unit umytreenode;
{$INCLUDE def.inc}
interface

uses
  Themes,uinfoform,zcadinterface,commandlinedef,ExtCtrls,lclproc,Graphics,ActnList,ComCtrls,{StdCtrls,}Controls,Classes,menus,Forms,{$IFDEF FPC}lcltype,{$ENDIF}fileutil,{ButtonPanel,}Buttons,
  {strutils,}{$IFNDEF DELPHI}intftranslations,{$ENDIF}sysutils,strproc,varmandef,Varman,UBaseTypeDescriptor,gdbasetypes,shared,SysInfo,UGDBOpenArrayOfByte;
type
    TmyAction=class(TAction)
                   public
                   command,options,imgstr:string;
                   pfoundcommand:PCommandObjectDef;
                   function Execute: Boolean; override;
                   procedure SetCommand(_Caption,_Command,_Options:TTranslateString);
              end;
    TmyButtonAction=class(TAction)
                   public
                   button:TToolButton;
                   function Execute: Boolean; override;
              end;

    TmyActionList=class(TActionList)
                       procedure LoadFromACNFile(fname:string);
                       procedure SetImage(img,identifer:string;var action:TmyAction);
                       function LoadImage(imgfile:GDBString):Integer;
                       procedure AddMyAction(Action:TmyAction);
                       public
                       brocenicon:integer;
                  end;
    TmyPopupMenu = class (TPopupMenu)
                   end;
    {TmyToolButton=class(TToolButton)
                  protected
                                 procedure CalculatePreferredSize(
                                                  var PreferredWidth, PreferredHeight: integer;
                                                  WithThemeSpace: Boolean); override;
                  end;}
    TmyCommandToolButton=class({Tmy}TToolButton)
                  public
                  FCommand:String;{**<Command to manager commands}
                  protected procedure Click; override;
                  end;
    TmyVariableToolButton=class({Tmy}TToolButton)
                  public
                  FVariable:String;{**<Command to manager commands}
                  FBufer:DWord;
                  FMask:DWord;
                  procedure AssignToVar(varname:string;mask:DWord);
                  protected procedure Click; override;
                  end;
    {**Modified TMenuItem}
    TmyMenuItem = class (TMenuItem)
                       public
                       FCommand:String;{**<Command to manager commands}
                       FSilent:Boolean;
                       constructor create(TheOwner: TComponent;_Caption,_Command:TTranslateString);
                       procedure SetCommand(_Caption,_Command:TTranslateString);
                       protected
                       procedure Click; override;
                  end;
    TCreatedNode = class of TTreeNode;
    TmyTreeNode=class(TTreeNode)
               public
                    FCategory:String;
                    FPopupMenu:TmyPopupMenu;
                    procedure Select;virtual;
                    function GetParams:Pointer;virtual;
                    function ContextPopup(const X,Y: Integer):boolean;virtual;
               end;
    TmyTreeView=class(TTreeView)
               public
               NodeType:TCreatedNode;
               function CreateNode: TTreeNode; override;
               constructor Create(AnOwner: TComponent); override;

               procedure DoSelectionChanged; override;
               protected procedure DoContextPopup(MousePos: TPoint; var Handled: Boolean); override;

    end;
  PTFreedForm=^TFreedForm;
  TFreedForm = class(tform)
                         private
                         PVariable:PTFreedForm;
                         procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
                         public
                         constructor myCreate(TheOwner: TComponent; _var:Pointer);
                    end;
  TToolButtonForm = class(tform{tpanel})
                         procedure AfterConstruction; override;
                         //public
                         //procedure GetPreferredSize(var PreferredWidth, PreferredHeight: integer;
                         //                               Raw: boolean = false;
                         //                               WithThemeSpace: boolean = true); override;

                    end;
  TmyPageControl=class(TPageControl)
                 procedure ChangePage(NewPage:Integer);virtual;
                 protected
                 //procedure DoChange;override;
                 end;
  TMySpeedButton = class(TCustomSpeedButton)
  protected
    function GetDrawDetails: TThemedElementDetails; override;
    procedure CalculatePreferredSize(var PreferredWidth,
           PreferredHeight: integer; {%H-}WithThemeSpace: Boolean); override;
  end;

PIterateCmpareFunc=function(node:TmyTreeNode;PExpr:Pointer):Boolean;


function IterateFind(Node:TmyTreeNode; CompareFunc:PIterateCmpareFunc;PExpr:Pointer;SubFind:Boolean):TmyTreeNode;
function IterateFindCategoryN (node:TmyTreeNode;PExpr:Pointer):Boolean;
function FindControlByType(_parent:TWinControl;_class:TClass):TControl;
procedure SetHeightControl(_parent:TWinControl;h:integer);
//var
//   ACN_ShowObjInsp:TmyAction=nil;
implementation
uses commandline,log,ugdbdescriptor;
function TMySpeedButton.GetDrawDetails: TThemedElementDetails;

  function WindowPart: TThemedScrollBar;
    begin
      // no check states available
      Result := tsArrowBtnDownNormal;
      if not IsEnabled then
        Result := tsArrowBtnDownDisabled
      else
      if FState in [bsDown, bsExclusive] then
        Result := tsArrowBtnDownPressed
      else
      if FState = bsHot then
        Result := tsArrowBtnDownHot
      else
        Result := tsArrowBtnDownNormal;
    end;

  begin
    Result := ThemeServices.GetElementDetails(WindowPart);
  end;

  procedure TMySpeedButton.CalculatePreferredSize(var PreferredWidth,
    PreferredHeight: integer; WithThemeSpace: Boolean);
  begin
    with ThemeServices.GetDetailSize(ThemeServices.GetElementDetails(tsArrowBtnDownNormal)) do
    begin
      PreferredWidth:=cx;
      PreferredHeight:=1;
    end;
  end;
procedure TmyAction.SetCommand(_Caption,_Command,_Options:TTranslateString);
begin
     command:=_Command;
     options:=_Options;
     caption:=(_Caption);
     if _Command=''then
                       self.Enabled:=false
                   else
                       self.Enabled:=true;
end;
function TmyButtonAction.Execute: Boolean;
begin
     result:=false;
     if assigned(button) then
       if button.enabled then
         begin
           //button.
           if (button.Style = tbsCheck) then
                                     button.Down := not button.Down;
           button.Click;
           result:=true;
         end;
end;

function TmyAction.Execute: Boolean;
var
    s:string;
begin
     //inherited;
     s:=command+'('+options+')';
     {if assigned(pfoundcommand)then

                               else}
                                   commandmanager.executecommand(@s[1],gdb.GetCurrentDWG,gdb.GetCurrentOGLWParam);
     result:=true;
end;
procedure TmyActionList.AddMyAction(Action:TmyAction);
begin
     self.AddAction(action);
end;

function TmyActionList.LoadImage(imgfile:GDBString):Integer;
var
    bmp:TBitmap;
begin
  if fileexists(utf8tosys(imgfile)) then
  begin
  bmp:=TBitmap.create;
  bmp.LoadFromFile(imgfile);
  bmp.Transparent:=true;
  if not assigned(Images) then
                              Images:=TImageList.Create(self);
  result:=Images.Add(bmp,nil);
  freeandnil(bmp);
  end
  else
      result:=-1;
end;

procedure TmyActionList.SetImage(img,identifer:string;var action:TmyAction);
//var
    //bmp:TBitmap;
begin
     if length(img)>1 then
     begin
          if img[1]<>'#' then
                              begin
                              action.imgstr:='';
                              action.ImageIndex:=LoadImage(sysparam.programpath+'menu/BMP/'+img);
                              if action.ImageIndex=-1 then
                                                  begin
                                                       action.ImageIndex:=self.brocenicon;
                                                  end;
                              if action.ImageIndex=-1 then
                                                  begin
                                                       action.imgstr:=img;
                                                  end;

                              {img:=sysparam.programpath+'menu/BMP/'+img;
                              if fileexists(img) then
                              begin
                              bmp:=TBitmap.create;
                              bmp.LoadFromFile(img);
                              bmp.Transparent:=true;
                              if not assigned(Images) then
                                                          Images:=TImageList.Create(self);
                              action.ImageIndex:=Images.Add(bmp,nil);
                              freeandnil(bmp);
                              action.imgstr:='';
                              end
                              else
                              begin
                              end;}
                              end
                          else
                              begin
                              //action.imgstr:=(system.copy(img,2,length(img)-1));
                              action.imgstr:=InterfaceTranslate(identifer,system.copy(img,2,length(img)-1));
                              end;
     end;
end;
procedure TmyActionList.LoadFromACNFile(fname:string);
var
    f:GDBOpenArrayOfByte;
    line{,ts,}{bn,}{bc}{,bh}:GDBString;
    actionname,actioncommand,actionpic,actioncaption,actionhint,actionshortcut:string;
    //buttonpos:GDBInteger;
    //ppanel:TToolBar;
    //b:TToolButton;
    //i:longint;
    //y,xx,yy,w,code:GDBInteger;
    //bmp:TBitmap;
    action:TmyAction;
//const bsize=24;
begin
  f.InitFromFile(fname);
  while f.notEOF do
  begin
    line := f.readstring(' ',#$D#$A);
    if (line <> '') and (line[1] <> ';') then
    begin
      if uppercase(line) = 'ACTION' then
           begin
               actionname:=UPPERCASE(f.readstring(',',''));
            actioncommand:=f.readstring(',','');
                actionpic:=f.readstring(',','');
            actioncaption:=f.readstring(',','');
            actioncaption:=InterfaceTranslate(actionname+'~caption',actioncaption);
               actionhint:=f.readstring(',','');
               if actionhint<>'' then
                                     actionhint:=InterfaceTranslate(actionname+'~hint',actionhint)
                                 else
                                     actionhint:=actioncaption;
               actionshortcut:=f.readstring(#$A,#$D);
              { if actionname='ACN_SAVEQS' then
                                         actionname:=actionname;}

               action:=TmyAction.Create(self);
               //if actionname='ACN_SHOWOBJINSP'
               //                               then ACN_ShowObjInsp:=action;
               if actionshortcut<>'' then
                                         action.ShortCut:=TextToShortCut(actionshortcut);
               action.Name:=uppercase(actionname);
               action.Caption:=actioncaption;
               ParseCommand(@actioncommand[1],action.command,action.options);
               //action.command:=actioncommand;
               action.Hint:=actionhint;
               action.DisableIfNoHandler:=false;
               SetImage(actionpic,actionname+'~textimage',action);
               self.AddAction(action);
               action.pfoundcommand:=commandmanager.FindCommand(uppercase(action.command));
           end;
    end;
  end;
  f.done;
end;

function FindControlByType(_parent:TWinControl;_class:TClass):TControl;
var
    i:integer;
begin
     if assigned(_parent)then
     for i := 0 to _parent.ControlCount - 1 do
      if TClass(typeof(_parent.Controls[i])) = _class then
                              begin
                                   result:=_parent.Controls[i];
                                   exit;
                              end;
     result:=nil;
end;
procedure SetHeightControl(_parent:TWinControl;h:integer);
var
    i:integer;
begin
     for i := 0 to _parent.ControlCount - 1 do
      if TClass(typeof(_parent.Controls[i])) = TBitBtn then
                              begin
                                   _parent.Controls[i].Height:=h;
                              end;
end;
procedure TToolButtonForm.AfterConstruction;

begin
    inherited;
    //Include(FControlFlags,cfPreferredSizeValid);
    autosize:=true;
end;

(*procedure TToolButtonForm.GetPreferredSize(var PreferredWidth, PreferredHeight: integer;
                               Raw: boolean = false;
                               WithThemeSpace: boolean = true);
begin
     //inherited;
     controls[0].GetPreferredSize(PreferredWidth, PreferredHeight,
                               Raw,
                               WithThemeSpace);
     {PreferredWidth:=18;
     PreferredHeight:=18}
end;*)
procedure TmyPageControl.ChangePage(NewPage:Integer);
begin
end;
{procedure TmyPageControl.DoChange;
begin
     inherited;
     ChangePage(ActivePageIndex);
end;}
{procedure TmyToolButton.CalculatePreferredSize(
                 var PreferredWidth, PreferredHeight: integer;
                 WithThemeSpace: Boolean);
var
    temp:integer;
begin
  if assigned(parent)then
  if parent is TToolbar then
                            begin
                                 if (style=tbsSeparator)
                                 or (style=tbsDivider) then
                                 if TToolbar(parent).Height>TToolbar(parent).Width then
                                 temp:=-14;

                            end;
     inherited;
     if assigned(parent)then
     if parent is TToolbar then
                               begin
                                    if (style=tbsSeparator)
                                    or (style=tbsDivider) then
                                    if TToolbar(parent).Height>TToolbar(parent).Width then
                                    begin
                                         temp:=PreferredWidth;
                                         PreferredWidth:=PreferredHeight;
                                         PreferredHeight:=temp;
                                    end;
                               end;
end;}

procedure TmyVariableToolButton.AssignToVar(varname:string;mask:DWord);
var
   pvd:pvardesk;
   accum:byte;
   pv,pm:pbyte;
   i:integer;
   tBufer:DWord;
begin
     if varname='DWG_DrawMode' then
                                     varname:=varname;
     FVariable:=varname;
     Fmask:=mask;
     pvd:=nil;
     if DWGUnit<>nil then
     pvd:=DWGUnit^.InterfaceVariables.findvardesc(FVariable);
     if pvd=nil then
     pvd:=SysVarUnit^.InterfaceVariables.findvardesc(FVariable);
     if pvd<>nil then
     begin
          enabled:=true;
          if pvd^.data.PTD=@GDBBooleanDescriptorOdj then
                                                        begin
                                                             self.Down:=PGDBBoolean(pvd^.data.Instance)^;
                                                        end
          else if fmask<>0 then
                               begin
                                    pv:=pvd^.data.Instance;
                                    pm:=@Fmask;
                                    accum:=0;
                                    for i:=1 to pvd^.data.PTD^.SizeInGDBBytes do
                                     begin
                                          accum:=accum or(pv^ and pm^);
                                          inc(pv);
                                          inc(pm);
                                     end;
                                    if accum<>0 then
                                                    self.Down:=true
                                                else
                                                    self.Down:=false;
                               end
          else if sizeof(FBufer)>=pvd^.data.PTD^.SizeInGDBBytes then
                                                                    begin
                                                                         TBufer:=0;
                                                                         Move(pvd^.data.Instance^, TBufer,pvd^.data.PTD^.SizeInGDBBytes);
                                                                         if TBufer<>0 then
                                                                                         self.Down:=true
                                                                                      else
                                                                                          self.Down:=false;
                                                                    end;
     end
        else
            enabled:=false;
end;
procedure TmyVariableToolButton.Click;
var
   pvd:pvardesk;
   accum:byte;
   pv,pm:pbyte;
   i:integer;
begin
  pvd:=nil;
  if DWGUnit<>nil then
  pvd:=DWGUnit^.InterfaceVariables.findvardesc(FVariable);
  if pvd=nil then
  pvd:=SysVarUnit^.InterfaceVariables.findvardesc(FVariable);
     if pvd<>nil then
     begin
          if pvd^.data.PTD=@GDBBooleanDescriptorOdj then
                                                        begin
                                                             PGDBBoolean(pvd^.data.Instance)^:=not PGDBBoolean(pvd^.data.Instance)^;
                                                             self.Down:=PGDBBoolean(pvd^.data.Instance)^;
                                                        end
          else if fmask<>0 then
                               begin
                                    pv:=pvd^.data.Instance;
                                    pm:=@Fmask;
                                    accum:=0;
                                    for i:=1 to pvd^.data.PTD^.SizeInGDBBytes do
                                     begin
                                          pv^:=pv^ xor pm^;
                                          accum:=accum or(pv^ and pm^);
                                          inc(pv);
                                          inc(pm);
                                     end;
                                    if accum<>0 then
                                                    self.Down:=true
                                                else
                                                    self.Down:=false;
                               end
     else if sizeof(FBufer)>=pvd^.data.PTD^.SizeInGDBBytes then
                                                               begin
                                                                    if not self.Down then
                                                                    begin
                                                                    fbufer:=0;
                                                                    Move(pvd^.data.Instance^, FBufer,pvd^.data.PTD^.SizeInGDBBytes);
                                                                    fillchar(pvd^.data.Instance^,pvd^.data.PTD^.SizeInGDBBytes,0);
                                                                    if fbufer<>0 then
                                                                                    self.Down:=false;
                                                                    end
                                                                    else
                                                                    begin
                                                                      if fbufer=0 then
                                                                                      fbufer:=1;
                                                                      begin
                                                                      Move( FBufer,pvd^.data.Instance^,pvd^.data.PTD^.SizeInGDBBytes);
                                                                      fbufer:=0;
                                                                      Move(pvd^.data.Instance^, FBufer,pvd^.data.PTD^.SizeInGDBBytes);

                                                                      if fbufer<>0 then
                                                                                      self.Down:=true;
                                                                      end;
                                                                    end;
                                                               end;
     end;
     if assigned(redrawoglwndproc) then redrawoglwndproc;
     if assigned(UpdateVisibleProc) then UpdateVisibleProc;
end;
procedure TmyCommandToolButton.click;
begin
     if action=nil then
                       commandmanager.executecommand(@Fcommand[1],gdb.GetCurrentDWG,gdb.GetCurrentOGLWParam);
     inherited;
end;

procedure TmyMenuItem.Click;
begin
     if fsilent then
                    commandmanager.executecommandsilent(@Fcommand[1],gdb.GetCurrentDWG,gdb.GetCurrentOGLWParam)
                else
                    commandmanager.executecommand(@Fcommand[1],gdb.GetCurrentDWG,gdb.GetCurrentOGLWParam);
     inherited;
end;
procedure TmyMenuItem.SetCommand(_Caption,_Command:TTranslateString);
begin
     FCommand:=_Command;
     caption:=(_Caption);
     if _Command=''then
                       self.Enabled:=false
                   else
                       self.Enabled:=true;
end;

constructor TmyMenuItem.create(TheOwner: TComponent;_Caption,_Command:TTranslateString);
begin
     inherited create(TheOwner);
     FSilent:=false;
     SetCommand(_Caption,_Command);
end;


constructor TFreedForm.myCreate(TheOwner: TComponent; _var:Pointer);
begin
     inherited create(TheOwner);
     PVariable:=_var;
     self.FormStyle:=fsStayOnTop;
     self.onclose:=self.FormClose;
end;

procedure TFreedForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
     CloseAction:=caFree;
     if CloseAction=caFree then
                               if assigned(PVariable) then
                                                          PVariable^:=nil;
end;

function TmyTreeNode.ContextPopup(const X,Y: Integer):boolean;
begin
     if assigned(FPopupMenu) then
                                 begin
                                      CommandManager.ContextCommandParams:=GetParams;
                                      FPopupMenu.popup(X, Y);
                                      result:=true;
                                 end
                             else
                                 result:=false;
end;
procedure TmyTreeView.DoContextPopup(MousePos: TPoint; var Handled: Boolean);
var
   treenode:TmyTreeNode;
   ScrMousePos: TPoint;
begin
     inherited;
     if not handled then
     begin
          TTreeNode(treeNode) := GetNodeAt(MousePos.X, MousePos.Y);
          if assigned(treeNode) then
          begin
               ScrMousePos:=ClientToScreen(MousePos);
               Handled:=treenode.ContextPopup(ScrMousePos.X,ScrMousePos.Y);
          end;
     end;
end;
function IterateFindCategoryN (node:TmyTreeNode;PExpr:Pointer):Boolean;
begin
     if TmyTreeNode(node).FCategory=pstring(PExpr)^ then
                                            result:=true
                                        else
                                            result:=false;

end;
function IterateFind(Node:TmyTreeNode; CompareFunc:PIterateCmpareFunc;PExpr:Pointer;SubFind:Boolean):TmyTreeNode;
var
   q:boolean;
begin

  Result:=TmyTreeNode(Node.GetFirstChild);
  if result<>nil then
  repeat
        q:=CompareFunc(result,pexpr);

        if q then
                  exit;
        if subfind then
                       begin
                            result:=iterateFind(result,CompareFunc,pexpr,subfind);
                            if result<>nil then
                                               exit;
                       end;

        Result:=TmyTreeNode(Result.GetNextSibling);
  until result=nil;
end;
procedure TmyTreeNode.Select;
begin

end;
function TmyTreeNode.GetParams:Pointer;
begin
     result:=nil;
end;


constructor TmyTreeView.Create(AnOwner: TComponent);
begin
     inherited;
     NodeType:=TmyTreeNode;
end;
procedure TmyTreeView.DoSelectionChanged;
begin
     inherited;

     if selected<>nil then
                          TmyTreeNode(Selected).Select;
end;

function TmyTreeView.CreateNode: TTreeNode;
begin
  Result := nil;
  if Assigned(OnCustomCreateItem) then
    OnCustomCreateItem(Self, Result);
  if Result = nil then
    Result := NodeType.Create(Items);
end;
initialization
{$IFDEF DEBUGINITSECTION}LogOut('umytreenode.initialization');{$ENDIF}
finalization
end.

