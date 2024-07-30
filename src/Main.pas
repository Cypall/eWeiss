unit 	 Main; 

interface

uses
	Windows, MMSystem, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
	Dialogs, ScktComp, StdCtrls, ExtCtrls, IniFiles, WinSock, ComCtrls,
	List32, Login, CharaSel, Script, Game, Path, Database, Common;

type
	TfrmMain = class(TForm)
		sv1          :TServerSocket;
		sv2          :TServerSocket;
		sv3          :TServerSocket;
		cmdStart     :TButton;
		cmdStop      :TButton;
		lbl00        :TLabel;
		txtDebug     :TMemo;
		lbl01        :TLabel;
		cbxPriority  :TComboBox;
		DBsaveTimer  :TTimer;
		procedure DBsaveTimerTimer(Sender: TObject);
{U0x003b�R�R�܂�}
		procedure FormCreate(Sender: TObject);
		procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
		procedure FormResize(Sender: TObject);
		procedure MonsterSpawn(tm:TMap; ts:TMob; Tick:cardinal);
		procedure MonsterDie(tm:TMap; tc:TChara; ts:TMob; Tick:cardinal);
{�ǉ�}
		procedure StatCalc1(tc:TChara; ts:TMob; Tick:cardinal);
		function	CharaMoving(tc:TChara;Tick:cardinal) : boolean;
		procedure CharaSplash(tc:TChara;Tick:cardinal);
		procedure CharaAttack(tc:TChara;Tick:cardinal);
		procedure CharaPassive(tc:TChara;Tick:cardinal);
		function	NPCAction(tm:TMap;tn:TNPC;Tick:cardinal) : Integer;
		procedure MobAI(tm:TMap;ts:TMob;Tick:cardinal);
		procedure MobMoveL(tm:TMap;Tick:cardinal);
		function	MobMoving(tm:TMap;ts:TMob;Tick:cardinal) : Integer;
		procedure MobAttack(tm:TMap;ts:TMob;Tick:cardinal);
		procedure StatEffect(tm:TMap; ts:TMob; Tick:Cardinal);

		procedure CreateField(tc:TChara; Tick:Cardinal);
		procedure SkillEffect(tc:TChara; Tick:Cardinal);
{�ǉ��R�R�܂�}
{�L���[�y�b�g}
                procedure PetMoving( tc:TChara; _Tick:cardinal );
{�L���[�y�b�g�����܂�}
		procedure DamageCalc1(tm:TMap; tc:TChara; ts:TMob; Tick:cardinal; Arms:byte = 0; SkillPer:integer = 0; AElement:byte = 0; HITFix:integer = 0);
		procedure DamageCalc2(tm:TMap; tc:TChara; ts:TMob; Tick:cardinal; SkillPer:integer = 0; AElement:byte = 255; HITFix:integer = 0);
		function  DamageProcess1(tm:TMap; tc:TChara; ts:TMob; Dmg:integer; Tick:cardinal;isBreak:Boolean = True) : Boolean;
		procedure sv1ClientConnect(Sender: TObject; Socket: TCustomWinSocket);
		procedure sv1ClientDisconnect(Sender: TObject; Socket: TCustomWinSocket);
		procedure sv1ClientError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
		procedure sv1ClientRead(Sender: TObject; Socket: TCustomWinSocket);
		procedure sv2ClientConnect(Sender: TObject; Socket: TCustomWinSocket);
		procedure sv2ClientDisconnect(Sender: TObject; Socket: TCustomWinSocket);
		procedure sv2ClientRead(Sender: TObject; Socket: TCustomWinSocket);
		procedure sv2ClientError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
		procedure sv3ClientConnect(Sender: TObject; Socket: TCustomWinSocket);
		procedure sv3ClientDisconnect(Sender: TObject; Socket: TCustomWinSocket);
		procedure sv3ClientRead(Sender: TObject; Socket: TCustomWinSocket);
		procedure sv3ClientError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
		procedure cmdStartClick(Sender: TObject);
		procedure cmdStopClick(Sender: TObject);
		procedure cbxPriorityClick(Sender: TObject);
	private
		{ Private �錾 }
	public
		{ Public �錾 }
	end;

const
	REALTIME_PRIORITY_CLASS = $100;
	HIGH_PRIORITY_CLASS = $80;
	ABOVE_NORMAL_PRIORITY_CLASS = $8000;
	NORMAL_PRIORITY_CLASS = $20;
	BELOW_NORMAL_PRIORITY_CLASS = $4000;
	IDLE_PRIORITY_CLASS = $40;

var
	frmMain       :TfrmMain;

	Priority      :cardinal;
	TickCheckCnt  :byte;
	TickCheck     :array[0..9] of cardinal;
	dmg           :array[0..7] of integer;





implementation

{$R *.dfm}

//==============================================================================
procedure TfrmMain.FormCreate(Sender: TObject);
var
	sl  :TStringList;
	sl1 :TStringList;
	ini :TIniFile;
begin
	Randomize;
	timeBeginPeriod(1);
	timeEndPeriod(1);
	SetLength(TrueBoolStrs, 4);
	TrueBoolStrs[0] := '1';
	TrueBoolStrs[1] := '-1';
	TrueBoolStrs[2] := 'true';
	TrueBoolStrs[3] := 'True';
	SetLength(FalseBoolStrs, 3);
	FalseBoolStrs[0] := '0';
	FalseBoolStrs[1] := 'false';
	FalseBoolStrs[2] := 'False';

	//NowAccountID := 0;
	NowUsers := 0;
	NowLoginID := 0;
	NowItemID := 10000;
	NowMobID := 1000000;
	NowCharaID := 0;
	//NowNPCID := 50000;
{�L���[�y�b�g}
        NowPetID := 0;
{�L���[�y�b�g�����܂�}
	AppPath := ExtractFilePath(ParamStr(0));

	DebugOut := txtDebug;

	Caption := ExtractFileName(ChangeFileExt(ParamStr(0), ''));

	ScriptList := TStringList.Create;

	ItemDB := TIntList32.Create;
	ItemDB.Sorted := true;
	ItemDBName := TStringList.Create;
	ItemDBName.CaseSensitive := True;
{�A�C�e�������ǉ�}
	MaterialDB := TIntList32.Create;
	MaterialDB.Sorted := true;
{�A�C�e�������ǉ��R�R�܂�}
	MobDB := TIntList32.Create;
	MobDB.Sorted := true;
	MobDBName := TStringList.Create;
	MobDBName.CaseSensitive := True;
	SkillDB := TIntList32.Create;
	PlayerName := TStringList.Create;
	PlayerName.CaseSensitive := True;
	Player := TIntList32.Create;
	CharaName := TStringList.Create;
	CharaName.CaseSensitive := True;
	Chara := TIntList32.Create;
	CharaPID := TIntList32.Create;
{�p�[�e�B�[�@�\�ǉ�}
	PartyNameList := TStringList.Create;
	PartyNameList.CaseSensitive := True;
{�p�[�e�B�[�@�\�ǉ��R�R�܂�}
{�`���b�g���[���@�\�ǉ�}
	ChatRoomList := TIntList32.Create;
{�`���b�g���[���@�\�ǉ��R�R�܂�}
{�I�X�X�L���ǉ�}
	VenderList := TIntList32.Create;
{�I�X�X�L���ǉ��R�R�܂�}
{����@�\�ǉ�}
	DealingList := TIntList32.Create;
{����@�\�ǉ��R�R�܂�}
{�L���[�y�b�g}
	PetDB  := TIntList32.Create;
        PetList := TIntList32.Create;
{�L���[�y�b�g�����܂�}
{��{���ǉ�}
	SummonMobList := TIntList32.Create;
	SummonIOBList := TIntList32.Create;
	SummonIOVList := TIntList32.Create;
	SummonICAList := TIntList32.Create;
	SummonIGBList := TIntList32.Create;
{��{���ǉ��R�R�܂�}
{NPC�C�x���g�ǉ�}
	ServerFlag := TStringList.Create;
	MapInfo    := TStringList.Create;
{NPC�C�x���g�ǉ��R�R�܂�}
{�M���h�@�\�ǉ�}
	GuildList := TIntList32.Create;
	GSkillDB := TIntList32.Create;
{�M���h�@�\�ǉ��R�R�܂�}
	Map := TStringList.Create;
	MapList := TStringList.Create;
	sl := TStringList.Create;
	sl.QuoteChar := '"';
	sl.Delimiter := ',';

	ini := TIniFile.Create(ChangeFileExt(ParamStr(0), '.ini'));
	sl.Clear;
	ini.ReadSectionValues('Server', sl);

	sl1 := TStringList.Create;
	sl1.Delimiter := '.';
	sl1.DelimitedText := sl.Values['IP'];
	if sl1.Count = 4 then begin
		ServerIP := cardinal(inet_addr(PChar(sl.Values['IP'])));
	end else begin
		ServerIP := cardinal(inet_addr('127.0.0.1'));
		//ServerIP := $0100007f;
	end;
	sl1.Free;
	if sl.IndexOfName('Name') <> -1 then begin
		ServerName := sl.Values['Name'];
	end else begin
		ServerName := 'weiss';
	end;
	if sl.IndexOfName('NPCID') <> -1 then begin
		DefaultNPCID := StrToInt(sl.Values['NPCID']);
	end else begin
		DefaultNPCID := 50000;
	end;
	NowNPCID := DefaultNPCID;
	if sl.IndexOfName('sv1port') <> -1 then begin
		sv1port := StrToInt(sl.Values['sv1port']);
	end else begin
		sv1port := 6900;
	end;
	sv1.Port := sv1port;
	if sl.IndexOfName('sv2port') <> -1 then begin
		sv2port := StrToInt(sl.Values['sv2port']);
	end else begin
		sv2port := 6121;
	end;
	sv2.Port := sv2port;
	if sl.IndexOfName('sv3port') <> -1 then begin
		sv3port := StrToInt(sl.Values['sv3port']);
	end else begin
		sv3port := 5121;
	end;
	sv3.Port := sv3port;
	if sl.IndexOfName('WarpDebug') <> -1 then begin
		WarpDebugFlag := StrToBool(sl.Values['WarpDebug']);
	end else begin
		WarpDebugFlag := false;
	end;
	if sl.IndexOfName('BaseExpMultiplier') <> -1 then begin
		BaseExpMultiplier := StrToInt(sl.Values['BaseExpMultiplier']);
	end else begin
		BaseExpMultiplier := 1;
	end;
	if sl.IndexOfName('JobExpMultiplier') <> -1 then begin
		JobExpMultiplier := StrToInt(sl.Values['JobExpMultiplier']);
	end else begin
		JobExpMultiplier := 1;
	end;
	if sl.IndexOfName('DisableMonsterActive') <> -1 then begin
		DisableMonsterActive := StrToBool(sl.Values['DisableMonsterActive']);
	end else begin
		DisableMonsterActive := false;
	end;
	if sl.IndexOfName('AutoStart') <> -1 then begin
		AutoStart := StrToBool(sl.Values['AutoStart']);
	end else begin
		AutoStart := false;
	end;
	if sl.IndexOfName('DisableLevelLimit') <> -1 then begin
		DisableLevelLimit := StrToBool(sl.Values['DisableLevelLimit']);
	end else begin
		DisableLevelLimit := false;
	end;
	if sl.IndexOfName('EnableMonsterKnockBack') <> -1 then begin
		EnableMonsterKnockBack := StrToBool(sl.Values['EnableMonsterKnockBack']);
	end else begin
		EnableMonsterKnockBack := false;
	end;
	if sl.IndexOfName('DisableEquipLimit') <> -1 then begin
		DisableEquipLimit := StrToBool(sl.Values['DisableEquipLimit']);
	end else begin
		DisableEquipLimit := false;
	end;
	if sl.IndexOfName('ItemDropType') <> -1 then begin
		ItemDropType := StrToBool(sl.Values['ItemDropType']);
	end else begin
		ItemDropType := false;
	end;
	if sl.IndexOfName('ItemDropDenominator') <> -1 then begin
		ItemDropDenominator := StrToInt(sl.Values['ItemDropDenominator']);
	end else begin
		ItemDropDenominator := 10000;
	end;
	if sl.IndexOfName('ItemDropPer') <> -1 then begin
		ItemDropPer := StrToInt(sl.Values['ItemDropPer']);
	end else begin
		ItemDropPer := 10000;
	end;
	if sl.IndexOfName('DisableFleeDown') <> -1 then begin
		DisableFleeDown := StrToBool(sl.Values['DisableFleeDown']);
	end else begin
		DisableFleeDown := false;
	end;
	if sl.IndexOfName('DisableSkillLimit') <> -1 then begin
		DisableSkillLimit := StrToBool(sl.Values['DisableSkillLimit']);
	end else begin
		DisableSkillLimit := false;
	end;
{U0x008a_fix}
	if sl.IndexOfName('DefaultZeny') <> -1 then begin
		DefaultZeny := StrToInt(sl.Values['DefaultZeny']);
	end else begin
		DefaultZeny := 300;
	end;
	if sl.IndexOfName('DefaultMap') <> -1 then begin
		DefaultMap := sl.Values['DefaultMap'];
	end else begin
		DefaultMap := 'new_zone01';
	end;
	if sl.IndexOfName('DefaultPoint_X') <> -1 then begin
		DefaultPoint_X := StrToInt(sl.Values['DefaultPoint_X']);
	end else begin
		DefaultPoint_X := 50;
	end;
	if sl.IndexOfName('DefaultPoint_Y') <> -1 then begin
		DefaultPoint_Y := StrToInt(sl.Values['DefaultPoint_Y']);
	end else begin
		DefaultPoint_Y := 100;
	end;
	if sl.IndexOfName('GMCheck') <> -1 then begin
		GMCheck := StrToIntDef(sl.Values['GMCheck'],0);
	end else begin
		GMCheck := $FF;
	end;
	if sl.IndexOfName('DebugCMD') <> -1 then begin
		DebugCMD := StrToIntDef(sl.Values['DebugCMD'],0);
	end else begin
		DebugCMD := $FFFF;
	end;
{U0x008a_fix_end}
	sl.Clear;
	ini.ReadSectionValues('Option', sl);

	if sl.IndexOfName('Left') <> -1 then begin
		FormLeft := StrToInt(sl.Values['Left']);
	end else begin
		FormLeft := 0;
	end;
	Left := FormLeft;
	if sl.IndexOfName('Top') <> -1 then begin
		FormTop := StrToInt(sl.Values['Top']);
	end else begin
		FormTop := 0;
	end;
	Top := FormTop;
	if sl.IndexOfName('Width') <> -1 then begin
		FormWidth := StrToInt(sl.Values['Width']);
	end else begin
		FormWidth := 500;
	end;
	Width := FormWidth;
	if sl.IndexOfName('Height') <> -1 then begin
		FormHeight := StrToInt(sl.Values['Height']);
	end else begin
		FormHeight := 460;
	end;
	Height := FormHeight;
	if sl.IndexOfName('Priority') <> -1 then begin
		Priority := StrToInt(sl.Values['Priority']);
		if Priority > 5 then Priority := 3;
	end else begin
		Priority := 3;
	end;
	cbxPriority.ItemIndex := Priority;

	ini.Free;
	sl.Free;

	Show;
	//�f�[�^�ǂݍ���
	DatabaseLoad(Handle);
	DataLoad();
	DebugOut.Lines.Add('');

	//MapLoad('moc_vilg00');
	//MapLoad('moc_vilg01');
	//DebugOut.Lines.Add('');

	DebugOut.Lines.Add('"eWeiss" English Weiss U0x009e + Skill + Guild .// Tsukasa Compile');
	DebugOut.Lines.Add('Startup Success.');
	DebugOut.Lines.Add('');
	cmdStart.Enabled := true;

	cbxPriorityClick(Sender);
	if AutoStart then PostMessage(cmdStart.Handle, BM_CLICK, 0, 0);
{U0x003b}
	DBsaveTimer.Enabled := True;
{U0x003b�R�R�܂�}
end;
//------------------------------------------------------------------------------
procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
	ini :TIniFile;
begin
	if ServerRunning then begin
		cmdStop.Enabled := false;
		CancelFlag := true;
		repeat
			Application.ProcessMessages;
		until ServerRunning;
	end;

	if WindowState = wsNormal then begin
		FormLeft := Left;
		FormTop := Top;
		FormWidth := Width;
		FormHeight := Height;
	end;

	ini := TIniFile.Create(ChangeFileExt(ParamStr(0), '.ini'));
	ini.WriteString('Server', 'IP', inet_ntoa(in_addr(ServerIP)));
	ini.WriteString('Server', 'Name', ServerName);
	ini.WriteString('Server', 'NPCID', IntToStr(DefaultNPCID));
	ini.WriteString('Server', 'sv1port', IntToStr(sv1port));
	ini.WriteString('Server', 'sv2port', IntToStr(sv2port));
	ini.WriteString('Server', 'sv3port', IntToStr(sv3port));
	ini.WriteString('Server', 'WarpDebug', BoolToStr(WarpDebugFlag, true));
	ini.WriteString('Server', 'BaseExpMultiplier', IntToStr(BaseExpMultiplier));
	ini.WriteString('Server', 'JobExpMultiplier', IntToStr(JobExpMultiplier));
	ini.WriteString('Server', 'DisableMonsterActive', BoolToStr(DisableMonsterActive, true));
	ini.WriteString('Server', 'AutoStart', BoolToStr(AutoStart, true));
	ini.WriteString('Server', 'DisableLevelLimit', BoolToStr(DisableLevelLimit, true));
	ini.WriteString('Server', 'EnableMonsterKnockBack', BoolToStr(EnableMonsterKnockBack, true));
	ini.WriteString('Server', 'DisableEquipLimit', BoolToStr(DisableEquipLimit, true));
	ini.WriteString('Server', 'ItemDropType', BoolToStr(ItemDropType, true));
	ini.WriteString('Server', 'ItemDropDenominator', IntToStr(ItemDropDenominator));
	ini.WriteString('Server', 'ItemDropPer', IntToStr(ItemDropPer));
	ini.WriteString('Server', 'DisableFleeDown', BoolToStr(DisableFleeDown, true));
	ini.WriteString('Server', 'DisableSkillLimit', BoolToStr(DisableSkillLimit, true));
	ini.WriteString('Option', 'Left', IntToStr(FormLeft));
	ini.WriteString('Option', 'Top', IntToStr(FormTop));
	ini.WriteString('Option', 'Width', IntToStr(FormWidth));
	ini.WriteString('Option', 'Height', IntToStr(FormHeight));
	ini.WriteString('Option', 'Priority', IntToStr(Priority));
	ini.Free;

	DataSave();

	ScriptList.Free;

	ItemDB.Free;
{�A�C�e�������ǉ�}
	MaterialDB.Free;
{�A�C�e�������ǉ��R�R�܂�}
	MobDB.Free;
	SkillDB.Free;
	PlayerName.Free;
	Player.Free;
	CharaName.Free;
	Chara.Free;
	CharaPID.Free;
{�`���b�g���[���@�\�ǉ�}
	ChatRoomList.Free;
{�`���b�g���[���@�\�ǉ��R�R�܂�}
{�p�[�e�B�[�@�\�ǉ�}
	PartyNameList.Free;
{�p�[�e�B�[�@�\�ǉ��R�R�܂�}
{�L���[�y�b�g}
				PetDB.Free;
				PetList.Free;
{�L���[�y�b�g�����܂�}
{�I�X�X�L���ǉ�}
	VenderList.Free;
{�I�X�X�L���ǉ��R�R�܂�}
{����@�\�ǉ�}
	DealingList.Free;
{����@�\�ǉ��R�R�܂�}
{��{���ǉ�}
	SummonMobList.Free;
	SummonIOBList.Free;
	SummonIOVList.Free;
	SummonICAList.Free;
	SummonIGBList.Free;
{��{���ǉ��R�R�܂�}
{NPC�C�x���g�ǉ�}
	ServerFlag.Free;
	MapInfo.Free;
{NPC�C�x���g�ǉ��R�R�܂�}
{�M���h�@�\�ǉ�}
	GuildList.Free;
	GSkillDB.Free;
{�M���h�@�\�ǉ��R�R�܂�}
	Map.Free;
end;
//------------------------------------------------------------------------------
procedure TfrmMain.FormResize(Sender: TObject);
begin
	if WindowState = wsNormal then begin
		FormLeft := Left;
		FormTop := Top;
		FormWidth := Width;
		FormHeight := Height;
	end;
end;
//------------------------------------------------------------------------------
procedure TfrmMain.cbxPriorityClick(Sender: TObject);
var
	PriorityClass	:cardinal;
begin
	Priority := cbxPriority.ItemIndex;
	case Priority of
	0: 		PriorityClass := REALTIME_PRIORITY_CLASS;
	1: 		PriorityClass := HIGH_PRIORITY_CLASS;
	2: 		PriorityClass := ABOVE_NORMAL_PRIORITY_CLASS;
	3: 		PriorityClass := NORMAL_PRIORITY_CLASS;
	4: 		PriorityClass := BELOW_NORMAL_PRIORITY_CLASS;
	5: 		PriorityClass := IDLE_PRIORITY_CLASS;
	else
		begin
			cbxPriority.ItemIndex := 3;
			Priority := 3;
			PriorityClass := NORMAL_PRIORITY_CLASS;
		end;
	end;

	SetPriorityClass(GetCurrentProcess(), PriorityClass);
end;
//==============================================================================





//==============================================================================
// ****************************************************************************
// * SERVER 1 : LOGIN SERVER (Port 6900)                                      *
// ****************************************************************************
//==============================================================================
procedure TfrmMain.sv1ClientConnect(Sender: TObject;
	Socket: TCustomWinSocket);
begin
	DebugOut.Lines.Add('1:Connect from ' + Socket.RemoteAddress);
end;
//------------------------------------------------------------------------------
procedure TfrmMain.sv1ClientDisconnect(Sender: TObject;
	Socket: TCustomWinSocket);
begin
	DebugOut.Lines.Add('1:Disconnect from ' + Socket.RemoteAddress);
end;
//------------------------------------------------------------------------------
procedure TfrmMain.sv1ClientError(Sender: TObject;
	Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
	var ErrorCode: Integer);
begin
	DebugOut.Lines.Add('1:Error ' + IntToStr(ErrorCode));
	if ErrorCode = 10053 then Socket.Close;
	ErrorCode := 0;
end;
//------------------------------------------------------------------------------
procedure TfrmMain.sv1ClientRead(Sender: TObject; Socket: TCustomWinSocket);
begin
	sv1PacketProcess(Socket);
end;
//==============================================================================










//==============================================================================
// ****************************************************************************
// * SERVER 2 : CHARA SERVER (Port 6121)                                      *
// ****************************************************************************
//==============================================================================
procedure TfrmMain.sv2ClientConnect(Sender: TObject;
	Socket: TCustomWinSocket);
begin
	DebugOut.Lines.Add('2:Connect from ' + Socket.RemoteAddress);
end;
//------------------------------------------------------------------------------
procedure TfrmMain.sv2ClientDisconnect(Sender: TObject;
	Socket: TCustomWinSocket);
begin
	DebugOut.Lines.Add('2:Disconnect from ' + Socket.RemoteAddress);
end;
//------------------------------------------------------------------------------
procedure TfrmMain.sv2ClientError(Sender: TObject;
	Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
	var ErrorCode: Integer);
begin
	DebugOut.Lines.Add('2:Error ' + IntToStr(ErrorCode));
	if ErrorCode = 10053 then Socket.Close;
	ErrorCode := 0;
end;
//------------------------------------------------------------------------------
procedure TfrmMain.sv2ClientRead(Sender: TObject;
	Socket: TCustomWinSocket);
begin
	sv2PacketProcess(Socket);
end;
//==============================================================================










//==============================================================================
// ****************************************************************************
// * SERVER 3 : GAME SERVER (Port 5121)                                       *
// ****************************************************************************
//==============================================================================
procedure TfrmMain.sv3ClientConnect(Sender: TObject;
	Socket: TCustomWinSocket);
begin
	DebugOut.Lines.Add('3:Connect from ' + Socket.RemoteAddress);
	NowUsers := sv3.Socket.ActiveConnections;
end;
//------------------------------------------------------------------------------
procedure TfrmMain.sv3ClientDisconnect(Sender: TObject;
	Socket: TCustomWinSocket);
var
	tc  :TChara;
	tp  :TPlayer;
{NPC�C�x���g�ǉ�}
	i,j :integer;
	mi  :MapTbl;
{NPC�C�x���g�ǉ��R�R�܂�}
begin
	tc := Socket.Data;
	SendCLeave(tc, 2);
{NPC�C�x���g�ǉ�}
	i := MapInfo.IndexOf(tc.Map);
	j := -1;
	if (i <> -1) then begin
		mi := MapInfo.Objects[i] as MapTbl;
		if (mi.noSave = true) then j := 0;
	end;
	if (tc.Sit = 1) or (j = 0) then begin
{NPC�C�x���g�ǉ��R�R�܂�}
		tc.Map := tc.SaveMap;
		tc.Point.X := tc.SavePoint.X;
		tc.Point.Y := tc.SavePoint.Y;
	end;
	tc.Login := 0;
	tp := tc.PData;
	tp.Login := 0;
	DebugOut.Lines.Add('3:Disconnect from ' + Socket.RemoteAddress);
	NowUsers := sv3.Socket.ActiveConnections;
	if NowUsers > 0 then Dec(NowUsers);
end;
//------------------------------------------------------------------------------
procedure TfrmMain.sv3ClientError(Sender: TObject;
	Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
	var ErrorCode: Integer);
begin
	DebugOut.Lines.Add('3:Error ' + IntToStr(ErrorCode));
	if ErrorCode = 10053 then Socket.Close;
	if ErrorCode = 10054 then Socket.Close;
	ErrorCode := 0;
	NowUsers := sv3.Socket.ActiveConnections;
end;
//------------------------------------------------------------------------------
procedure TfrmMain.sv3ClientRead(Sender: TObject;
	Socket: TCustomWinSocket);
begin
	sv3PacketProcess(Socket);
end;
//==============================================================================










//==============================================================================
procedure TFrmMain.MonsterSpawn(tm:TMap; ts:TMob; Tick:cardinal);
var
	i, j, k :integer;
	tc      :TChara;
begin
	//Spawn
	repeat
		ts.Point.X := ts.Point1.X + Random(ts.Point2.X + 1) - (ts.Point2.X div 2);
		ts.Point.Y := ts.Point1.Y + Random(ts.Point2.Y + 1) - (ts.Point2.Y div 2);
		if (ts.Point.X < 0) or (ts.Point.X > tm.Size.X - 2) or (ts.Point.Y < 0) or (ts.Point.Y > tm.Size.Y - 2) then begin
			if ts.Point.X < 0 then ts.Point.X := 0;
			if ts.Point.X > tm.Size.X - 2 then ts.Point.X := tm.Size.X - 2;
			if ts.Point.Y < 0 then ts.Point.Y := 0;
			if ts.Point.Y > tm.Size.Y - 2 then ts.Point.Y := tm.Size.Y - 2;
		end;
//	until (tm.gat[ts.Point.X][ts.Point.Y] and 1) <> 0;
	until (tm.gat[ts.Point.X, ts.Point.Y] and 1 <> 0);
	ts.Dir := Random(8);
	ts.HP := ts.Data.HP;
	if ts.Data.isDontMove then
		ts.MoveWait := $FFFFFFFF
	else
		ts.MoveWait := Tick + 5000 + Cardinal(Random(10000));
	ts.Speed := ts.Data.Speed;
	ts.ATarget := 0;
	ts.ARangeFlag := false;
	ts.ATKPer := 100;
	ts.DEFPer := 100;
	ts.DmgTick := 0;
	for j := 0 to 31 do begin
		ts.EXPDist[j].CData := nil;
		ts.EXPDist[j].Dmg := 0;
	end;
	if ts.Data.MEXP <> 0 then begin
		for j := 0 to 31 do begin
			ts.MVPDist[j].CData := nil;
			ts.MVPDist[j].Dmg := 0;
		end;
		ts.MVPDist[0].Dmg := ts.Data.HP * 30 div 100; //FA��30%���Z
	end;

	tm.Block[ts.Point.X div 8][ts.Point.Y div 8].Mob.AddObject(ts.ID, ts);

	for j := ts.Point.Y div 8 - 2 to ts.Point.Y div 8 + 2 do begin
		for i := ts.Point.X div 8 - 2 to ts.Point.X div 8 + 2 do begin
			//����̐l�ɒʒm
			for k := 0 to tm.Block[i][j].CList.Count - 1 do begin
				tc := tm.Block[i][j].CList.Objects[k] as TChara;
				if tc = nil then continue;
				if (abs(ts.Point.X - tc.Point.X) < 16) and (abs(ts.Point.Y - tc.Point.Y) < 16) then begin
					SendMData(tc.Socket, ts);
				end;
			end;
		end;
	end;
end;
//------------------------------------------------------------------------------
procedure TFrmMain.MonsterDie(tm:TMap; tc:TChara; ts:TMob; Tick:cardinal);
var
	k,i,j,m,n:integer;
	total:cardinal;
	mvpid:integer;
	mvpitem:boolean;
	mvpcheck:integer;
	i1,j1,k1:integer;
	l,w:cardinal;
	tc1:TChara;
	tn:TNPC;
	td:TItemDB;
	TgtFlag:boolean;
	DropFlag:boolean;
{�p�[�e�B�[�@�\�ǉ�}
	tpaDB:TStringList;
	tpa:TParty;
{�p�[�e�B�[�@�\�ǉ��R�R�܂�}
{�M���h�@�\�ǉ�}
	tg  :TGuild;
	ge  :cardinal;
{�M���h�@�\�ǉ��R�R�܂�}

begin
	WFIFOW( 0, $0080);
	WFIFOL( 2, ts.ID);
	WFIFOB( 6, 1);
	SendBCmd(tm, ts.Point, 7);

	ts.HP := 0;
	ts.pcnt := 0;
{�ǉ�}
	ts.Stat1 :=0;
	ts.Stat2 :=0;
	ts.nStat := 0;
  ts.Element := ts.Data.Element;
	ts.BodyTick := 0;
	for i := 0 to 4 do
		ts.HealthTick[i] := 0;
	ts.isLooting := False;
	ts.LeaderID := 0;
{�ǉ��R�R�܂�}
	ts.SpawnTick := Tick;

	i := tm.Block[ts.Point.X div 8][ts.Point.Y div 8].Mob.IndexOf(ts.ID);
	if i = -1 then exit;
	tm.Block[ts.Point.X div 8][ts.Point.Y div 8].Mob.Delete(i);

	//�^�[�Q�b�g����
	for j1 := ts.Point.Y div 8 - 2 to ts.Point.Y div 8 + 2 do begin
		for i1 := ts.Point.X div 8 - 2 to ts.Point.X div 8 + 2 do begin
			for k1 := 0 to tm.Block[i1][j1].CList.Count - 1 do begin
				tc1 := tm.Block[i1][j1].CList.Objects[k1] as TChara;
				if ((tc1.AMode = 1) or (tc1.AMode = 2)) and (tc1.ATarget = ts.ID) then begin
					tc1.AMode := 0;
					tc1.ATarget := 0;
				end;
				if (tc1.MMode <> 0) and (tc1.MTarget = ts.ID) then begin
						tc1.MMode := 0;
						tc1.MTarget := 0;
				end;
			end;
		end;
	end;

	//�o���l���z����
	n := 32;
	total := 0;
	for i := 0 to 31 do begin
		if ts.EXPDist[i].CData = nil then begin
			n := i;
			break;
		end;
		tc1 := ts.EXPDist[i].CData;
		if (tc1.Login = 2) and (tc1.Sit <> 1) and (tc1.Map = tm.Name) then begin
			//���O�A�E�g���Ă���A����ł���A�ʂ̃}�b�v�ɂ���A�����ꂩ�̏ꍇ�o���l�͓���Ȃ�
			Inc(total, ts.EXPDist[i].Dmg);
		end;
	end;

	//MVP����
	mvpid := -1;
	if ts.Data.MEXP <> 0 then begin
		mvpcheck := 0;
		for i := 0 to 31 do begin
			if ts.MVPDist[i].CData = nil then break;
			tc1 := ts.MVPDist[i].CData;
			if (tc1.Login = 2) and (tc1.Sit <> 1) and (tc1.Map = tm.Name) then begin
				//���O�A�E�g���Ă���A����ł���A�ʂ̃}�b�v�ɂ���A�����ꂩ�̏ꍇMVP�ΏۂɂȂ�Ȃ�
				if mvpcheck < ts.MVPDist[i].Dmg then begin
					mvpid := i;
					mvpcheck := ts.MVPDist[i].Dmg;
				end;
			end;
		end;

		if mvpid <> -1 then begin
			tc1 := ts.MVPDist[mvpid].CData;
			//MVP�\��
			WFIFOW(0, $010c);
			WFIFOL(2, tc1.ID);
			SendBCmd(tm, tc1.Point, 6);
			//MVP�`�F�b�N
			mvpitem := false;
			if ts.Data.MEXPPer <= Random(10000) then begin
				for i := 0 to 2 do begin
					if ts.Data.MVPItem[i].Per > cardinal(Random(10000)) then begin
						//MVP�A�C�e���l��
						td := ItemDB.IndexOfObject(ts.Data.MVPItem[i].ID) as TItemDB;
						//�d�ʃI�[�o�[��A�C�e����ސ��I�[�o�[�̎��́A�K���o���l�ɂȂ�@�ׂ��������}���h�N�Z('A�M)�m
						if tc1.MaxWeight >= tc1.Weight + td.Weight then begin
							j := SearchCInventory(tc1, td.ID, td.IEquip);
							if j <> 0 then begin
								//MVP�A�C�e���Q�b�g�ʒm
								WFIFOW( 0, $010a);
								WFIFOW( 2, td.ID);
								tc1.Socket.SendBuf(buf, 4);

								//�A�C�e���ǉ�
								tc1.Item[j].ID := td.ID;
								tc1.Item[j].Amount := tc1.Item[j].Amount + 1;
								tc1.Item[j].Equip := 0;
								tc1.Item[j].Identify := 1 - byte(td.IEquip);
								tc1.Item[j].Refine := 0;
								tc1.Item[j].Attr := 0;
								tc1.Item[j].Card[0] := 0;
								tc1.Item[j].Card[1] := 0;
								tc1.Item[j].Card[2] := 0;
								tc1.Item[j].Card[3] := 0;
								tc1.Item[j].Data := td;
								//�d�ʒǉ�
								tc1.Weight := tc1.Weight + td.Weight;
								WFIFOW( 0, $00b0);
								WFIFOW( 2, $0018);
								WFIFOL( 4, tc1.Weight);
								tc1.Socket.SendBuf(buf, 8);

								//�A�C�e���Q�b�g�ʒm
								SendCGetItem(tc1, j, 1);
								mvpitem := true;
							end;
						end;
						break;
					end;
				end;
			end;
			if not mvpitem then begin
				//MVP�o���l�l���\�� ���ۂ̉��Z�͌�ł܂Ƃ߂�
				WFIFOW( 0, $010b);
				WFIFOL( 2, ts.Data.MEXP * BaseExpMultiplier);
				tc1.Socket.SendBuf(buf, 6);
			end;
		end;
	end;

{�p�[�e�B�[�@�\�ǉ�}
	tpaDB := TStringList.Create;
	for i := 0 to n - 1 do begin
		tc1 := ts.EXPDist[i].CData;
		//���O�A�E�g���Ă���A����ł���A�ʂ̃}�b�v�ɂ���A�����ꂩ�̏ꍇ�o���l�͓���Ȃ�
		if (tc1.Login <> 2) or (tc1.Sit = 1) or (tc1.Map <> tm.Name) then
			Continue;
		//�x�[�X�o���l
		l := 100 * Cardinal(ts.EXPDist[i].Dmg) div total;
		l := ts.Data.EXP * l div 100;
		if n <> 1 then Inc(l);
		if i = mvpid then l := l + ts.Data.MEXP; //MVP
		l := l * BaseExpMultiplier;

		//�W���u�o���l
                {�o�O�� 617}
                w := ts.Data.JEXP * (cardinal(ts.EXPDist[i].Dmg) div total);
                {�o�O�� 617}
		if n <> 1 then Inc(w);
		if i = mvpid then w := w + ts.Data.MEXP; //MVP
		w := w * JobExpMultiplier;

{�M���h�@�\�ǉ�}
		j := GuildList.IndexOf(tc.GuildID);
		if (j <> -1) then begin
			tg := GuildList.Objects[j] as TGuild;
			ge := l * tg.PosEXP[tc1.GuildPos] div 100;
			if (ge > l) then ge := l;
			if (ge > 0) then begin
				l := l - ge;
				CalcGuildLvUP(tg, tc1, ge);
			end;
		end;
{�M���h�@�\�ǉ��R�R�܂�}

		//�o�[�e�B�[�@�\
		j := PartyNameList.IndexOf(tc.PartyName);
		if j <> -1 then begin
			tpa := PartyNameList.Objects[j] as TParty;
			if tpa.EXPShare = 1 then begin
				Inc(tpa.EXP,l);
				Inc(tpa.JEXP,w);
				j := tpaDB.IndexOf(tpa.Name);
				if j = -1 then begin
					tpaDB.AddObject(tpa.Name,tpa);
				 end;
			end else begin
			 	CalcLvUP(tc1,l,w);
			end;
		end else begin
				CalcLvUP(tc1,l,w);
		end;
	end;
	//���̃}�b�v�ŏ��������Ȃ��Ɖ���
	for i := 0 to tpaDB.Count -1 do begin
		tpa := tpaDB.Objects[i] as TParty;
		PartyDistribution(ts.Map,tpa);
	end;
	tpaDB.Free;
{�p�[�e�B�[�@�\�ǉ��R�R�܂�}
	//�A�C�e���h���b�v
	for k := 0 to 7 do begin
		DropFlag := false;
		i := (ItemDropDenominator - ((ItemDropDenominator - ts.Data.Drop[k].Per) * 10000 div ItemDropPer));
		if ItemDropType then begin
			if Random(ItemDropDenominator) <= i then DropFlag := true; //�d�͎d�l�B�����S�𗎂Ƃ��B
		end else begin
			if Random(ItemDropDenominator) < i then DropFlag := true; //�{����(?)�d�l�B�����S�͗��Ƃ��Ȃ��B
		end;
		if DropFlag then begin
			tn := TNPC.Create;
			tn.ID := NowItemID;
			Inc(NowItemID);
			tn.Name := 'item';
			tn.JID := ts.Data.Drop[k].ID;
			tn.Map := ts.Map;
			tn.Point.X := ts.Point.X - 1 + Random(3);
			tn.Point.Y := ts.Point.Y - 1 + Random(3);
			tn.CType := 3;
			tn.Item := TItem.Create;
			tn.Item.ID := ts.Data.Drop[k].ID;
			tn.Item.Amount := 1;
			tn.Item.Identify := 1 - byte(ts.Data.Drop[k].Data.IEquip);
			tn.Item.Refine := 0;
			tn.Item.Attr := 0;
			tn.Item.Card[0] := 0;
			tn.Item.Card[1] := 0;
			tn.Item.Card[2] := 0;
			tn.Item.Card[3] := 0;
			tn.Item.Data := ts.Data.Drop[k].Data;
			tn.SubX := Random(8);
			tn.SubY := Random(8);
			tn.Tick := Tick + 60000;
			tm.NPC.AddObject(tn.ID, tn);
			tm.Block[tn.Point.X div 8][tn.Point.Y div 8].NPC.AddObject(tn.ID, tn);

			//����ɒʒm
			WFIFOW( 0, $009e);
			WFIFOL( 2, tn.ID);
			WFIFOW( 6, tn.JID);
			WFIFOB( 8, tn.Item.Identify);
			WFIFOW( 9, tn.Point.X);
			WFIFOW(11, tn.Point.Y);
			WFIFOB(13, tn.SubX);
			WFIFOB(14, tn.SubY);
			WFIFOW(15, tn.Item.Amount);
			SendBCmd(tm, tn.Point, 17);
		end;
	end;
	//���ߍ��񂾃A�C�e��
	for k := 1 to 10 do begin
		if ts.Item[k].Amount = 0 then Break;
		tn := TNPC.Create;
		tn.ID := NowItemID;
		Inc(NowItemID);
		tn.Name := 'item';
		tn.JID := ts.Item[k].ID;
		tn.Map := ts.Map;
		tn.Point.X := ts.Point.X - 1 + Random(3);
		tn.Point.Y := ts.Point.Y - 1 + Random(3);
		tn.CType := 3;
		tn.Item := TItem.Create;
		tn.Item.ID := ts.Item[k].ID;
		tn.Item.Amount := 1;
		tn.Item.Identify := ts.Item[k].Identify;
		tn.Item.Refine := ts.Item[k].Refine;
		tn.Item.Attr := ts.Item[k].Attr;
		tn.Item.Card[0] := ts.Item[k].Card[0];
		tn.Item.Card[1] := ts.Item[k].Card[1];
		tn.Item.Card[2] := ts.Item[k].Card[2];
		tn.Item.Card[3] := ts.Item[k].Card[3];
		tn.Item.Data := ts.Item[k].Data;
		tn.SubX := Random(8);
		tn.SubY := Random(8);
		tn.Tick := Tick + 60000;
		tm.NPC.AddObject(tn.ID, tn);
		tm.Block[tn.Point.X div 8][tn.Point.Y div 8].NPC.AddObject(tn.ID, tn);

		ts.Item[k].ID := 0;
		ts.Item[k].Amount := 0;
		ts.Item[k].Equip := 0;
		ts.Item[k].Identify := 0;
		ts.Item[k].Refine := 0;
		ts.Item[k].Attr := 0;
		ts.Item[k].Card[0] := 0;
		ts.Item[k].Card[1] := 0;
		ts.Item[k].Card[2] := 0;
		ts.Item[k].Card[3] := 0;
    ts.Item[k].Data := nil;

		//����ɒʒm
		WFIFOW( 0, $009e);
		WFIFOL( 2, tn.ID);
		WFIFOW( 6, tn.JID);
		WFIFOB( 8, tn.Item.Identify);
		WFIFOW( 9, tn.Point.X);
		WFIFOW(11, tn.Point.Y);
		WFIFOB(13, tn.SubX);
		WFIFOB(14, tn.SubY);
		WFIFOW(15, tn.Item.Amount);
		SendBCmd(tm, tn.Point, 17);
	end;
{�ǉ�}
	if ts.isSummon then begin
		//���҃����X�͏���
		i := tm.Mob.IndexOf(ts.ID);
		if i = -1 then Exit;
		tm.Mob.Delete(i);
{NPC�C�x���g�ǉ�}
		if (ts.Event <> 0) then begin
			tn := tm.NPC.IndexOfObject(ts.Event) as TNPC;
			tc1 := TChara.Create;
			tc1.TalkNPCID := tn.ID;
			tc1.ScriptStep := 0;
			tc1.AMode := 3;
			tc1.AData := tn;
			tc1.Login := 0;
			NPCScript(tc1,0,1);
			tc1.Free;
		end;
{NPC�C�x���g�ǉ��R�R�܂�}
		ts.Free;
	end;
{�ǉ��R�R�܂�}
end;
//------------------------------------------------------------------------------
{�ǉ�}
// �΃����X�^�[��ԕω��v�Z
procedure TFrmMain.StatCalc1(tc:TChara; ts:TMob; Tick:cardinal);
var
	i:Integer;
	k:Cardinal;
begin
	with tc do begin
		k := 0;
		for i :=0 to 4 do begin
			if Random(100) < SFixPer1[0][i] then begin
				k := i + 1;
			end;
		end;
		if (k <> 0) then begin
			if (k <> ts.Stat1) then begin
				ts.BodyTick := Tick + tc.aMotion + ts.Data.dMotion;
				ts.nStat := k;
			end else begin
				ts.BodyTick := ts.BodyTick + 30000; //����
			end;
		end;
		for i :=0 to 4 do begin
			k := 1 shl i;
			if Random(100) < SFixPer2[0][i] then begin
				if Boolean(k and ts.Stat2) then begin
					ts.HealthTick[i] := ts.HealthTick[i] + 30000; //����
				end else begin
					ts.HealthTick[i] := Tick + tc.aMotion + ts.Data.dMotion;
				end;
			end;
		end;
	end;
end;
{�ǉ��R�R�܂�}
//------------------------------------------------------------------------------
// �΃����X�^�[�_���[�W�v�Z
procedure TFrmMain.DamageCalc1(tm:TMap; tc:TChara; ts:TMob; Tick:cardinal; Arms:byte = 0; SkillPer:integer = 0; AElement:byte = 0; HITFix:integer = 0);
var
	i,j,m :integer;
	k     :Cardinal;
	miss  :boolean;
	crit  :boolean;
	datk  :boolean;
begin
	with tc do begin
		i := HIT + HITFix - ts.Data.FLEE + 80;
		if i < 5 then i := 5;
		if i > 100 then i := 100;
		dmg[6] := i;
		if Arms = 0 then begin
			crit := boolean((SkillPer = 0) and (Random(100) < Critical - ts.Data.LUK * 0.2));
		end else begin //�񓁗��E��
			crit := boolean(dmg[5] = 10);
		end;
		miss := boolean((Random(100) >= i) and (not crit));
		//DA�`�F�b�N
		if (miss = false) and (Arms = 0) and (SkillPer = 0) and (Random(100) < DAPer) then begin
			datk := true;
			crit := false;
		end else begin
			datk := false;
		end;

		if not miss then begin
			//�U������
			if Arms = 0 then if crit then dmg[5] := 10 else dmg[5] := 0; //�N���e�B�J���`�F�b�N
			if WeaponType[Arms] = 0 then begin
				//�f��
				dmg[0] := ATK[Arms][2];
			end else if Weapon = 11 then begin
				//�|
				if dmg[5] = 10 then begin
					dmg[0] := ATK[0][2] + ATK[1][2] + ATK[0][1] * ATKFix[Arms][ts.Data.Scale] div 100;
				end else begin
					dmg[2] := ATK[0][1];
{�C��}
					case WeaponLv[0] of
						2: dmg[1] := Param[4] * 120 div 100;
						3: dmg[1] := Param[4] * 140 div 100;
						4: dmg[1] := Param[4] * 160 div 100;
						else dmg[1] := Param[4];
					end;
					if dmg[1] >= ATK[0][1] then begin
						dmg[1] := ATK[0][1] * ATK[0][1] div 100;
					end else begin
						dmg[1] := dmg[1] * ATK[0][1] div 100;
					end;
					if dmg[1] > dmg[2] then dmg[2] := dmg[1];
					dmg[0] := dmg[1] + Random(dmg[2] - dmg[1] + 1) + Random(ATK[1][2]);
					dmg[0] := ATK[0][2] + dmg[0] * ATKFix[Arms][ts.Data.Scale] div 100;
				end;
{�C���R�R�܂�}
			end else begin
				//�f��ȊO
				if dmg[5] = 10 then begin
					dmg[0] := ATK[Arms][2] + ATK[Arms][1] * ATKFix[Arms][ts.Data.Scale] div 100;
				end else begin
{�C��}
					case WeaponLv[Arms] of
						2: dmg[1] := Param[4] * 120 div 100;
						3: dmg[1] := Param[4] * 140 div 100;
						4: dmg[1] := Param[4] * 160 div 100;
						else dmg[1] := Param[4];
					end;
{�C���R�R�܂�}
					dmg[2] := ATK[Arms][1];
					if dmg[2] < dmg[1] then dmg[1] := dmg[2]; //DEX>ATK�̏ꍇ�AATK�D��
					dmg[0] := dmg[1] + Random(dmg[2] - dmg[1] + 1);
					dmg[0] := ATK[Arms][2] + dmg[0] * ATKFix[Arms][ts.Data.Scale] div 100;
				end;
			end;
			if ts.Data.Race = 1 then dmg[0] := dmg[0] + ATK[0][5]; //�f�[�����x�C��
			if SkillPer <> 0 then dmg[0] := dmg[0] * SkillPer div 100; //Skill%
{�ύX}
			if (dmg[5] = 0) or (dmg[5] = 8) then begin
				if (ts.Stat2 and 1) = 1 then begin //�łɂ��␳
					dmg[3] := ts.Data.Param[2] * 75 div 100;
					m := ts.Data.DEF * 75 div 100;
				end else begin
					dmg[3] := ts.Data.Param[2];
					m := ts.Data.DEF;
				end;
				dmg[3] := dmg[3] + Random((dmg[3] div 20) * (dmg[3] div 20)); //Def+DefBonus
				if (AMode <> 8) then begin //AC
					//�I�[�g_�o�[�T�[�N
					if (tc.Skill[146].Lv <> 0) and (tc.HP * 100 / tc.MAXHP <= 25) then dmg[0] := (dmg[0] * (100 - (m * ts.DEFPer div 100)) div 100) * word(tc.Skill[6].Data.Data1[10]) div 100 - dmg[3]
					else dmg[0] := dmg[0] * (100 - (m * ts.DEFPer div 100)) div 100 - dmg[3]; //�v���{�b�N�C���͂���
				end;
			end;
{�ύX�R�R�܂�}
			dmg[0] := dmg[0] + ATK[Arms][3]; //���B�␳
			if dmg[0] < 1 then dmg[0] := 1;
			dmg[0] := dmg[0] + ATK[0][4]; //�C���␳
{�ύX}
			//�J�[�h�␳
			if Arms = 0then begin //����ɂ̓J�[�h�␳�Ȃ�
				dmg[0] := dmg[0] * DamageFixS[ts.Data.scale] div 100;
				dmg[0] := dmg[0] * DamageFixR[0][ts.Data.Race] div 100;
				dmg[0] := dmg[0] * DamageFixE[0][ts.Element mod 20] div 100;
			end;
			//�����ݒ�
			if AElement = 0 then begin
				if Weapon = 11 then begin
					AElement := WElement[1];
				end else begin
					AElement := WElement[Arms];
				end;
			end;
			if ts.Stat1 = 2 then i := 21 //��������
			else i := ts.Element;
			dmg[0] := dmg[0] * ElementTable[AElement][i] div 100; //���������␳
			if ts.Stat1 = 5 then dmg[0] := dmg[0] * 2; //���b�N�X_�G�[�e���i
		end else begin
			//�U���~�X
			dmg[0] := 0;
		end;
			//HP�z��
			if (dmg[0] > 0) and (random(100) < DrainPer[0]) then begin
				HP := HP + (dmg[0] * DrainFix[0] div 100);
				if HP > MAXHP then HP := MAXHP;
				SendCStat1(tc, 0, 5, HP);
			end;
			//SP�z��
			if (dmg[0] > 0) and (random(100) < DrainPer[1]) then begin
				SP := SP + (dmg[0] * DrainFix[1] div 100);
				if SP > MAXSP then SP := MAXSP;
				SendCStat1(tc, 0, 7, SP);
			end;
{�ύX�R�R�܂�}
		//�A�T�V���񓁗��C��
		if dmg[0] > 0 then begin
			dmg[0] := dmg[0] * ArmsFix[Arms] div 100;
			if dmg[0] = 0 then dmg[0] := 1;
		end;
		//�����Ő��̂�������ʂ�����(������)

		if Arms = 1 then exit;
		//�_�u���A�^�b�N
		if datk then begin
			dmg[0] := dmg[0] * DAFix div 100 * 2;
			dmg[4] := 2;
			dmg[5] := 8;
		end else begin
			dmg[4] := 1;
		end;
	end;
	//��ԂP�͉���Ǝ���
	if ts.Stat1 <> 0 then begin
		ts.BodyTick := Tick + tc.aMotion;
	end;
	//DebugOut.Lines.Add(Format('DMG %d%% %d(%d-%d)', [dmg[6], dmg[0], dmg[1], dmg[2]]));
end;
//------------------------------------------------------------------------------
// �����X�^�[�����_���[�W�v�Z
procedure TFrmMain.DamageCalc2(tm:TMap; tc:TChara; ts:TMob; Tick:cardinal; SkillPer:integer = 0; AElement:byte = 255; HITFix:integer = 0);
var
	i,j,k     :integer;
	miss      :boolean;
	crit      :boolean;
	avoid     :boolean; //���S���
	i1,j1,k1  :integer;
	xy        :TPoint;
	ts1       :TMob;
	tn        :TNPC;
begin
	if tc.TargetedTick <> Tick then begin
		if DisableFleeDown then begin
			tc.TargetedFix := 10;
			tc.TargetedTick := Tick;
		end else begin
			i := 0;
			xy := tc.Point;
			for j1 := xy.Y div 8 - 2 to xy.Y div 8 + 2 do begin
				for i1 := xy.X div 8 - 2 to xy.X div 8 + 2 do begin
					for k1 := 0 to tm.Block[i1][j1].Mob.Count - 1 do begin
						ts1 := tm.Block[i1][j1].Mob.Objects[k1] as TMob;
						if (tc.ID = ts1.ATarget) and (abs(ts1.Point.X - tc.Point.X) <= ts1.Data.Range1) and
							 (abs(ts1.Point.Y - tc.Point.Y) <= ts1.Data.Range1) then Inc(i);
					end;
				end;
			end;
			//debugout.Lines.Add('Targeted: ' + inttostr(i));
			if i > 12 then i := 12;
			if i < 2 then i := 2;
			tc.TargetedFix := 12 - i;
			tc.TargetedTick := Tick;
		end;
	end;

	with ts.Data do begin
{�C��}
		i := HIT + HITFix - (tc.FLEE1 * tc.TargetedFix div 10) + 80;
		i := i - tc.FLEE2;
		if i < 5 then i := 5
		else if i > 95 then i := 95;
{�C���R�R�܂�}
		dmg[6] := i;
		//crit := boolean((SkillPer = 0) and (Random(100) < Critical));
		crit := false;
		avoid := boolean((SkillPer = 0) and (Random(100) < tc.Lucky));
		miss := boolean((Random(100) >= i) and (not crit));

		i1 := 0;
		while (i1 >= 0) and (i1 < tm.Block[tc.Point.X div 8][tc.Point.Y div 8].NPC.Count) do begin
			tn := tm.Block[tc.Point.X div 8][tc.Point.Y div 8].NPC.Objects[i1] as TNPC;
			if tn = nil then begin
				Inc(i1);
				continue;
			end;
			if (tc.Point.X = tn.Point.X) and (tc.Point.Y = tn.Point.Y) then begin
				case tn.JID of
				$7e: //�Z�C�t�e�B�E�H�[��
					begin
						miss := true;
						if not avoid then Dec(tn.Count);
						if tn.Count = 0 then begin
							DelSkillUnit(tm, tn);
							Dec(i1);
						end;
						DebugOut.Lines.Add('Safety Wall OK >>' + IntToStr(tn.Count));
						dmg[6] := 0;
					end;
				$85: //�j���[�}
					begin
						if ts.Data.Range1 >= 4 then miss := true;
						DebugOut.Lines.Add('Pneuma OK');
						dmg[6] := 0;
					end;
				end;
			end;
			Inc(i1);
		end;

		if crit then dmg[5] := 10 else dmg[5] := 0; //�N���e�B�J���`�F�b�N
		//VIT�{�[�i�X�Ƃ��v�Z
		j := ((tc.Param[2] div 2) + (tc.Param[2] * 3 div 10));
		k := ((tc.Param[2] div 2) + (tc.Param[2] * tc.Param[2] div 150 - 1));
		if j > k then k := j;
		if tc.Skill[33].Tick > Tick then begin //�G���W�F���X
			k := k * tc.Skill[33].Effect1 div 100;
		end;
{�C��}
		dmg[1] := ATK1 + Random(ATK2 - ATK1 + 1);
		if (ts.Stat2 and 1) = 1 then dmg[1] := dmg[1] * 75 div 100;
		//�I�[�g_�o�[�T�[�N
		if (tc.Skill[146].Lv <> 0) and (tc.HP * 100 / tc.MAXHP <= 25) then dmg[0] := (dmg[1] * (100 - (tc.DEF1 * word(tc.Skill[6].Data.Data2[10]) div 100)) div 100 - k) * ts.ATKPer div 100
		else dmg[0] := (dmg[1] * (100 - tc.DEF1) div 100 - k) * ts.ATKPer div 100;
		if Race = 1 then dmg[0] := dmg[0] - tc.DEF3; //DP
		if dmg[0] < 0 then dmg[0] := 1;
{�C���R�R�܂�}
		if SkillPer <> 0 then dmg[0] := dmg[0] * SkillPer div 100; //Skill%
		//dmg[0] := dmg[0] * ElementTable[AElement][ts.Data.Element] div 100; //���������␳
{�ύX}
		//�J�[�h�␳
		dmg[0] := dmg[0] * (100 - tc.DamageFixR[1][ts.Data.Race] )div 100;
		//dmg[0] := dmg[0] * tc.DEFFixE[ts.Data.Element mod 20] div 100;
{�ύX�R�R�܂�}
                if tc.Skill[61].Tick > Tick then begin //AC
                        tc.AMode := 8;
                        tc.ATarget := ts.ID;
                        DamageCalc1(tm, tc, ts, Tick, 0, 0, 0, 20);
                        if dmg[0] < 0 then dmg[0] := 0; //�����U���ł̉񕜂͖�����
                        //�p�P���M
                        WFIFOW( 0, $008a);
                        WFIFOL( 2, tc.ID);
                        WFIFOL( 6, tc.ATarget);
                        WFIFOL(10, timeGetTime());
                        WFIFOL(14, tc.aMotion);
                        WFIFOL(18, ts.Data.dMotion);
                        WFIFOW(22, dmg[0]); //�_���[�W
                        WFIFOW(24, 1); //������
                        WFIFOB(26, 0); //0=�P�U�� 8=���� 10=�N���e�B�J��
                        WFIFOW(27, 0); //�t��
                        SendBCmd(tm, ts.Point, 29);
                        DamageProcess1(tm, tc, ts, dmg[0], Tick);
                        StatCalc1(tc, ts, Tick);
                        tc.Skill[61].Tick := Tick;
                        tc.AMode := 0;
                        dmg[0] := 0;
                        dmg[5] := 11;
                end else if avoid then begin
                        dmg[0] := 0;
			dmg[5] := 11;
		end else if not miss then begin
			//�U������
			if dmg[0] <> 0 then begin
				if tc.Skill[157].Tick > Tick then begin //�G�l���M�[�R�[�g
					if (tc.SP * 100 / tc.MAXSP) < 1 then tc.SP := 0;
				   	if tc.SP > 0 then begin
						i := 1;
						if (tc.SP * 100 / tc.MAXSP) > 20 then i := 2;
						if (tc.SP * 100 / tc.MAXSP) > 40 then i := 3;
						if (tc.SP * 100 / tc.MAXSP) > 60 then i := 4;
						if (tc.SP * 100 / tc.MAXSP) > 80 then i := 5;
						dmg[0] := dmg[0] - ((dmg[0] * i * 6) div 100);
						tc.SP := tc.SP - (tc.MAXSP * (i + 1) * 5) div 1000;
				    end else tc.Skill[157].Tick := Tick;
				    	SendCStat1(tc, 0, 7, tc.SP);
                                    end;
				end;
				tc.MMode := 0;
				tc.MTick := Tick;
				tc.MTarget := 0;
				tc.MPoint.X := 0;
				tc.MPoint.Y := 0;
		end else begin
			//�U���~�X
			dmg[0] := 0;
		end;
		//�����Ő��̂�������ʂ�����(������)

		dmg[4] := 1;
	end;
	//DebugOut.Lines.Add(Format('REV %d%% %d(%d-%d)', [dmg[6], dmg[0], dmg[1], dmg[2]]));
end;
//------------------------------------------------------------------------------
// �����X�^�[�_���[�W����
function TfrmMain.DamageProcess1(tm:TMap; tc:TChara; ts:TMob; Dmg:integer; Tick:cardinal; isBreak:Boolean = True) : Boolean;
var
	i :integer;
  w :Cardinal;
begin
	if ts.HP < Dmg then Dmg := ts.HP;
	if Dmg = 0 then begin
		Result := False;
		Exit;
	end;
	if (ts.Stat1 <> 0) and isBreak then begin
		ts.BodyTick := Tick + tc.aMotion;
	end;

	WFIFOW(0, $0088);
	WFIFOL(2, ts.ID);
	WFIFOW(6, ts.Point.X);
	WFIFOW(8, ts.Point.Y);
	SendBCmd(tm, ts.Point, 10);

	ts.HP := ts.HP - Dmg;
	for i := 0 to 31 do begin
		if (ts.EXPDist[i].CData = nil) or (ts.EXPDist[i].CData = tc) then begin
			ts.EXPDist[i].CData := tc;
			Inc(ts.EXPDist[i].Dmg, Dmg);
			break;
		end;
	end;
	if ts.Data.MEXP <> 0 then begin
		for i := 0 to 31 do begin
			if (ts.MVPDist[i].CData = nil) or (ts.MVPDist[i].CData = tc) then begin
				ts.MVPDist[i].CData := tc;
				Inc(ts.MVPDist[i].Dmg, Dmg);
				break;
			end;
		end;
	end;
	if ts.HP > 0 then begin
		//�^�[�Q�b�g�ݒ�
		if EnableMonsterKnockBack then begin
			ts.pcnt := 0;
			if ts.ATarget = 0 then begin
				w := Tick + ts.Data.dMotion + tc.aMotion;
				ts.ATick := Tick + ts.Data.dMotion + tc.aMotion;
			end else begin
				w := Tick + ts.Data.dMotion div 2;
			end;
			if w > ts.DmgTick then ts.DmgTick := w;
		end else begin
			if ts.ATarget = 0 then ts.ATick := Tick;
			if ts.ATarget <> tc.ID then
				ts.pcnt := 0
			else if ts.pcnt <> 0 then begin
				DebugOut.Lines.Add('Monster Knockback!');
				SendMMove(tc.Socket, ts, ts.Point, ts.tgtPoint,tc.ver2);
				SendBCmd(tm, ts.Point, 58, tc,True);
			end;
			ts.DmgTick := 0;
		end;
		ts.ATarget := tc.ID;
		ts.AData := tc;
		ts.isLooting := False;

		Result := False;
	end else begin
		//�����X�^�[���S
		MonsterDie(tm, tc, ts, Tick);
		Result := True;
	end;
end;

//------------------------------------------------------------------------------
{�ǉ�}
procedure PickUp(tm:TMap; ts:TMob; Tick:Cardinal);
var
	tn:TNPC;
	i,j:Integer;
begin
	with ts do begin
		if tm.NPC.IndexOf(ts.ATarget) <> -1 then begin
			tn := tm.NPC.IndexOfObject(ts.Atarget) as TNPC;
			if (abs(ts.Point.X - tn.Point.X) <= 1) and (abs(ts.Point.Y - tn.Point.Y) <= 1) then begin
				j := 0;
				for i := 1 to 10 do begin
					//��index��T��
					if ts.Item[i].ID = 0 then begin
						ts.Item[i].Amount := 0;
						j := i;
						break;
					end;
				end;
				if j <> 0 then begin
					//�A�C�e���ǉ�
					ts.Item[j].ID := tn.Item.ID;
					ts.Item[j].Amount := ts.Item[j].Amount + tn.Item.Amount;
					ts.Item[j].Equip := 0;
					ts.Item[j].Identify := tn.Item.Identify;
					ts.Item[j].Refine := tn.Item.Refine;
					ts.Item[j].Attr := tn.Item.Attr;
					ts.Item[j].Card[0] := tn.Item.Card[0];
					ts.Item[j].Card[1] := tn.Item.Card[1];
					ts.Item[j].Card[2] := tn.Item.Card[2];
					ts.Item[j].Card[3] := tn.Item.Card[3];
					ts.Item[j].Data := tn.Item.Data;
				end;
				//�A�C�e���P��
				WFIFOW(0, $00a1);
				WFIFOL(2, tn.ID);
				SendBCmd(tm, tn.Point, 6);
				//�A�C�e���폜
				tm.NPC.Delete(tm.NPC.IndexOf(tn.ID));
				with tm.Block[tn.Point.X div 8][tn.Point.Y div 8].NPC do
					Delete(IndexOf(tn.ID));
				tn.Free;

			end else begin
				//�A�C�e���͈ړ����Ȃ��̂ł��̂܂�
				WFIFOW(0, $0088);
				WFIFOL(2, ts.ID);
				WFIFOW(6, ts.Point.X);
				WFIFOW(8, ts.Point.Y);
				SendBCmd(tm, ts.Point, 10);
				Exit;
			end;
		end;
		WFIFOW(0, $0088);
		WFIFOL(2, ts.ID);
		WFIFOW(6, ts.Point.X);
		WFIFOW(8, ts.Point.Y);
		SendBCmd(tm, ts.Point, 10);
		ts.pcnt := 0;
		ts.MoveWait := Tick + ts.Data.aMotion;
		ts.ATarget := 0;
		ts.ATick := Tick + ts.Data.ADelay;
		ts.isLooting := False;
	end;
end;
{�ǉ��R�R�܂�}
//==============================================================================


{�L���[�y�b�g}
procedure TfrmMain.PetMoving( tc:TChara; _Tick:cardinal );
var
	j,k,m,n :Integer;
        spd:cardinal;
	xy:TPoint;
	dx,dy:integer;
	tm:TMap;
	tn:TNPC;
        tc1:TChara;
begin
        if ( tc.PetData = nil ) or ( tc.PetNPC = nil ) then exit;

        tm := tc.MData;
        tn := tc.PetNPC;

	with tn do begin

                if (Path[ppos] and 1) = 0 then begin
			spd := tc.Speed;
		end else begin
			spd := tc.Speed * 140 div 100;
		end;

                for j := 1 to ( _Tick - MoveTick ) div spd do begin

                xy := Point;
                Dir := Path[ppos];
                case Path[ppos] of
                        0: begin              Inc(Point.Y); dx :=  0; dy :=  1; end;
			1: begin Dec(Point.X);Inc(Point.Y); dx := -1; dy :=  1; end;
			2: begin Dec(Point.X);              dx := -1; dy :=  0; end;
			3: begin Dec(Point.X);Dec(Point.Y); dx := -1; dy := -1; end;
			4: begin              Dec(Point.Y); dx :=  0; dy := -1; end;
			5: begin Inc(Point.X);Dec(Point.Y); dx :=  1; dy := -1; end;
			6: begin Inc(Point.X);              dx :=  1; dy :=  0; end;
			7: begin Inc(Point.X);Inc(Point.Y); dx :=  1; dy :=  1; end;
			else begin                          dx :=  0; dy :=  0; end; //�{���͋N����͂����Ȃ�
                end;
                Inc(ppos);

                //�u���b�N����1
                for n := xy.Y div 8 - 2 to xy.Y div 8 + 2 do begin
                        for m := xy.X div 8 - 2 to xy.X div 8 + 2 do begin //�����̋���u���b�N�͏�������K�v�͂Ȃ�(��)
                                for k := 0 to tm.Block[m][n].CList.Count - 1 do begin
                                        tc1 := tm.Block[m][n].CList.Objects[k] as TChara;
                                        if tc <> tc1 then begin //�������m�ł͒ʒm���Ȃ��悤�ɁB
                                                if ((dx <> 0) and (abs(xy.Y - tc1.Point.Y) < 16) and (xy.X = tc1.Point.X + dx * 15)) or
                                                ((dy <> 0) and (abs(xy.X - tc1.Point.X) < 16) and (xy.Y = tc1.Point.Y + dy * 15)) then begin
                                                        //���Œʒm
                                                        //DebugOut.Lines.Add(Format('		Chara %s Delete', [tc1.Name]));
                                                        WFIFOW(0, $0080);
                                                        WFIFOL(2, ID);
                                                        WFIFOB(6, 0);
                                                        tc1.Socket.SendBuf(buf, 7);
                                                end;
                                                if ((dx <> 0) and (abs(Point.Y - tc1.Point.Y) < 16) and (Point.X = tc1.Point.X - dx * 15)) or
                                                ((dy <> 0) and (abs(Point.X - tc1.Point.X) < 16) and (Point.Y = tc1.Point.Y - dy * 15)) then begin
                                                        //�o���ʒm
                                                        //DebugOut.Lines.Add(Format('		Chara %s Add', [tc1.Name]));
                                                        SendNData( tc1.Socket, tn, tc1.ver2 );
                                                        //�ړ��ʒm
                                                        if (abs(Point.X - tc1.Point.X) < 16) and (abs(Point.Y - tc1.Point.Y) < 16) then begin
                                                                //DebugOut.Lines.Add(Format('		Chara %s Move (%d,%d)-(%d,%d)', [Name, xy.X, xy.Y, Point.X, Point.Y]));
                                                                SendPetMove(tc1.Socket, tc, NextPoint );
                                                        end;
                                                end;
                                        end;
                                end;
			end;
                end;

                //�u���b�N�ړ�
                if (xy.X div 8 <> Point.X div 8) or (xy.Y div 8 <> Point.Y div 8) then begin
                        //�ȑO�̃u���b�N�̃f�[�^����
                        with tm.Block[xy.X div 8][xy.Y div 8].NPC do begin
                                Delete(IndexOf(ID));
                        end;
                        //�V�����u���b�N�Ƀf�[�^�ǉ�
                        tm.Block[Point.X div 8][Point.Y div 8].NPC.AddObject(ID, tn);
                end;

                if ppos = pcnt then begin
                        //�ړ�����
                        pcnt := 0;
                        break;
                end;
                MoveTick := MoveTick + spd;

                end;
	end;
end;
{�L���[�y�b�g�����܂�}


//==============================================================================
//�����P ���[�v�|�C���g�ɓ�������Ture
function  TfrmMain.CharaMoving(tc:TChara;Tick:cardinal) : boolean;
var
	j,k,m,n :Integer;
	spd:cardinal;
	xy:TPoint;
	dx,dy:integer;
	tm:TMap;
	tn:TNPC;
	tc1:TChara;
	ts:TMob;
{NPC�C�x���g�ǉ�}
	i :Integer;
	w :word;
	tcr :TChatRoom;
{NPC�C�x���g�ǉ��R�R�܂�}
begin
	with tc do begin
		tm := MData;
		if (Path[ppos] and 1) = 0 then begin
			spd := Speed;
		end else begin
			spd := Speed * 140 div 100;
		end;
		for j := 1 to (Tick - MoveTick) div spd do begin
			xy := Point;
			Dir := Path[ppos];
			HeadDir := 0;
			case Path[ppos] of
				0: begin              Inc(Point.Y); dx :=  0; dy :=  1; end;
				1: begin Dec(Point.X);Inc(Point.Y); dx := -1; dy :=  1; end;
				2: begin Dec(Point.X);              dx := -1; dy :=  0; end;
				3: begin Dec(Point.X);Dec(Point.Y); dx := -1; dy := -1; end;
				4: begin              Dec(Point.Y); dx :=  0; dy := -1; end;
				5: begin Inc(Point.X);Dec(Point.Y); dx :=  1; dy := -1; end;
				6: begin Inc(Point.X);              dx :=  1; dy :=  0; end;
				7: begin Inc(Point.X);Inc(Point.Y); dx :=  1; dy :=  1; end;
				else
					 begin              HeadDir := 0; dx :=  0; dy :=	0; end; //�{���͋N����͂����Ȃ�
			end;
			Inc(ppos);
			//DebugOut.Lines.Add(Format('		Move %d/%d (%d,%d) %d %d %d', [ppos, pcnt, Point.X, Point.Y, Path[ppos-1], spd, Tick]));

			//�u���b�N����1
			for n := xy.Y div 8 - 2 to xy.Y div 8 + 2 do begin
				for m := xy.X div 8 - 2 to xy.X div 8 + 2 do begin //�����̋���u���b�N�͏�������K�v�͂Ȃ�(��)
					//NPC�ʒm
					for k := 0 to tm.Block[m][n].NPC.Count - 1 do begin
						tn := tm.Block[m][n].NPC.Objects[k] as TNPC;
						if ((dx <> 0) and (abs(xy.Y - tn.Point.Y) < 16) and (xy.X = tn.Point.X + dx * 15)) or
						((dy <> 0) and (abs(xy.X - tn.Point.X) < 16) and (xy.Y = tn.Point.Y + dy * 15)) then begin
							//���Œʒm
							//DebugOut.Lines.Add(Format('		NPC %s Delete', [tn.Name]));
							if tn.CType = 3 then begin
								WFIFOW(0, $00a1);
								WFIFOL(2, tn.ID);
								Socket.SendBuf(buf, 6);
							end else if tn.CType = 4 then begin
								WFIFOW(0, $0120);
								WFIFOL(2, tn.ID);
								Socket.SendBuf(buf, 6);
							end else begin
								WFIFOW(0, $0080);
								WFIFOL(2, tn.ID);
								WFIFOB(6, 0);
								Socket.SendBuf(buf, 7);
							end;
						end;
						if ((dx <> 0) and (abs(Point.Y - tn.Point.Y) < 16) and (Point.X = tn.Point.X - dx * 15)) or
						((dy <> 0) and (abs(Point.X - tn.Point.X) < 16) and (Point.Y = tn.Point.Y - dy * 15)) then begin
							//�o���ʒm
							//DebugOut.Lines.Add(Format('		NPC %s Add', [tn.Name]));
{NPC�C�x���g�ǉ�}
							if (tn.Enable = true) then begin
								SendNData(Socket, tn, ver2);
								if (tn.ScriptInitS <> -1) and (tn.ScriptInitD = false) then begin
									//OnInit���x�������s
									DebugOut.Lines.Add(Format('OnInit Event(%d)', [tn.ID]));
									tc1 := TChara.Create;
									tc1.TalkNPCID := tn.ID;
									tc1.ScriptStep := tn.ScriptInitS;
									tc1.AMode := 3;
									tc1.AData := tn;
									tc1.Login := 0;
									NPCScript(tc1,0,1);
									tn.ScriptInitD := true;
									tc1.Free;
								end;
								if (tn.ChatRoomID <> 0) then begin
									//�`���b�g���[����\������
									i := ChatRoomList.IndexOf(tn.ChatRoomID);
									if (i <> -1) then begin
										tcr := ChatRoomList.Objects[i] as TChatRoom;
										if (tn.ID = tcr.MemberID[0]) then begin
											w := Length(tcr.Title);
											WFIFOW(0, $00d7);
											WFIFOW(2, w + 17);
											WFIFOL(4, tcr.MemberID[0]);
											WFIFOL(8, tcr.ID);
											WFIFOW(12, tcr.Limit);
											WFIFOW(14, tcr.Users);
											WFIFOB(16, tcr.Pub);
											WFIFOS(17, tcr.Title, w);
											if tc.Socket <> nil then begin
												tc.Socket.SendBuf(buf, w + 17);
											end;
										end;
									end;
								end;
							end;
{NPC�C�x���g�ǉ��R�R�܂�}
						end;
					end;
					//�v���C���[�Ԓʒm
					for k := 0 to tm.Block[m][n].CList.Count - 1 do begin
						tc1 := tm.Block[m][n].CList.Objects[k] as TChara;
						if tc <> tc1 then begin //�������m�ł͒ʒm���Ȃ��悤�ɁB
						if ((dx <> 0) and (abs(xy.Y - tc1.Point.Y) < 16) and (xy.X = tc1.Point.X + dx * 15)) or
						((dy <> 0) and (abs(xy.X - tc1.Point.X) < 16) and (xy.Y = tc1.Point.Y + dy * 15)) then begin
							//���Œʒm
							//DebugOut.Lines.Add(Format('		Chara %s Delete', [tc1.Name]));
							WFIFOW(0, $0080);
							WFIFOL(2, ID);
							WFIFOB(6, 0);
							tc1.Socket.SendBuf(buf, 7);
							WFIFOL(2, tc1.ID);
							Socket.SendBuf(buf, 7);
						end;
						if ((dx <> 0) and (abs(Point.Y - tc1.Point.Y) < 16) and (Point.X = tc1.Point.X - dx * 15)) or
						((dy <> 0) and (abs(Point.X - tc1.Point.X) < 16) and (Point.Y = tc1.Point.Y - dy * 15)) then begin
							//�o���ʒm
							//DebugOut.Lines.Add(Format('		Chara %s Add', [tc1.Name]));
							SendCData(Socket, tc1);
							SendCData(tc1.Socket, tc);



							//�ړ��ʒm
							if (abs(Point.X - tc1.Point.X) < 16) and (abs(Point.Y - tc1.Point.Y) < 16) then begin
								DebugOut.Lines.Add(Format('		Chara %s Move (%d,%d)-(%d,%d)', [Name, xy.X, xy.Y, Point.X, Point.Y]));
								SendCMove(tc1.Socket, tc, Point, tgtPoint);
							end;
						end;
					end;
				end;
				//�����X�^�[�ʒm
				for k := 0 to tm.Block[m][n].Mob.Count - 1 do begin
					ts := tm.Block[m][n].Mob.Objects[k] as TMob;
					if ((dx <> 0) and (abs(xy.Y - ts.Point.Y) < 16) and (xy.X = ts.Point.X + dx * 15)) or
					((dy <> 0) and (abs(xy.X - ts.Point.X) < 16) and (xy.Y = ts.Point.Y + dy * 15)) then begin
						//���Œʒm
						//DebugOut.Lines.Add(Format('		Mob %s Delete', [ts.Name]));
						WFIFOW(0, $0080);
						WFIFOL(2, ts.ID);
						WFIFOB(6, 0);
						Socket.SendBuf(buf, 7);
					end;
					if ((dx <> 0) and (abs(Point.Y - ts.Point.Y) < 16) and (Point.X = ts.Point.X - dx * 15)) or
					((dy <> 0) and (abs(Point.X - ts.Point.X) < 16) and (Point.Y = ts.Point.Y - dy * 15)) then begin
						//�o���ʒm
						//DebugOut.Lines.Add(Format('		Mob %s Add', [ts.Name]));
						SendMData(Socket, ts);
						//�ړ��ʒm
						if (ts.pcnt <> 0) and (abs(Point.X - ts.Point.X) < 16) and (abs(Point.Y - ts.Point.Y) < 16) then begin
{�C��}				SendMMove(Socket, ts, ts.Point, ts.tgtPoint,ver2);
						end;
					end;
				end;
			end;
		end;

		//�u���b�N�ړ�
		if (xy.X div 8 <> Point.X div 8) or (xy.Y div 8 <> Point.Y div 8) then begin
			//DebugOut.Lines.Add(Format('		BlockMove (%d,%d)-(%d,%d)', [xy.X div 8, xy.Y div 8, Point.X div 8, Point.Y div 8]));
			//�ȑO�̃u���b�N�̃f�[�^����
			with tm.Block[xy.X div 8][xy.Y div 8].CList do begin
				//DebugOut.Lines.Add('BlockDelete ' + inttostr(IndexOf(IntToStr(ID))));
				Delete(IndexOf(ID));
			end;
			//�V�����u���b�N�Ƀf�[�^�ǉ�
			tm.Block[Point.X div 8][Point.Y div 8].CList.AddObject(ID, tc);
			//DebugOut.Lines.Add('		BlockMove OK');
	end;

	if (tm.gat[Point.X][Point.Y] and $4) <> 0 then begin
			//���[�v�|�C���g�ɓ�����
			for n := Point.Y div 8 - 2 to Point.Y div 8 + 2 do begin
				for m := Point.X div 8 - 2 to Point.X div 8 + 2 do begin
					for k := 0 to tm.Block[m][n].NPC.Count - 1 do begin
						tn := tm.Block[m][n].NPC.Objects[k] as TNPC;
{NPC�C�x���g�ǉ�}
						if (tn.CType = 0) and (tn.Enable = true) then begin
{NPC�C�x���g�ǉ��R�R�܂�}
							if (abs(Point.X - tn.Point.X) <= tn.WarpSize.X) and
							(abs(Point.Y - tn.Point.Y) <= tn.WarpSize.Y) then begin
								HPTick := Tick;
								HPRTick := Tick - 500;
								SPRTick := Tick;
								pcnt := 0;
								SendCLeave(tc, 0);
								Map := tn.WarpMap;
								Point := tn.WarpPoint;
								MapMove(Socket, Map, Point);
{�C��}
								NextPoint := Point;
								Result := True;
								Exit;
{�C���R�R�܂�}
								end;
							end;
						end;
					end;
				end;
			end;

			if ppos = pcnt then begin
				//�ړ�����
				Sit := 3;
				HPTick := Tick;
				HPRTick := Tick - 500;
				SPRTick := Tick;
				pcnt := 0;
				//�U�����������ꍇ�A�˒��`�F�b�N
				{
				if (AMode = 1) or (AMode = 2) then begin
					ts := AData;
					if (abs(Point.X - ts.Point.X) > Range) or (abs(Point.Y - ts.Point.Y) > Range) then begin
						//�˒��O�Ȃ�A����̈ړ��ڕW�n�ֈړ�����
						NextFlag := true;
						NextPoint := ts.tgtPoint;
					end;
				end;
				}
				//DebugOut.Lines.Add(Format('		Move OK', [ID]));
				break;
			end;
			MoveTick := MoveTick + spd;
		end;
	end;
{�ǉ�}
	Result := False;
{�ǉ��R�R�܂�}
end;
//------------------------------------------------------------------------------
//�����Q
procedure TfrmMain.CharaAttack(tc:TChara;Tick:cardinal);
var
	i1,j1,k1,k:integer;
	tm:TMap;
	ts:TMob;
	ts1:TMob;
	xy:TPoint;
	sl:TStringList;
  tl:TSkillDB;
begin
	with tc do begin
		ts := AData;
		tm := MData;
		if ts.HP <= 0 then begin
		//�G������ł�Ƃ��͍U���L�����Z��
			ts.HP := 0;
			AMode := 0;
			Exit;
		end;
		if (pcnt <> 0) and (abs(Point.X - ts.Point.X) <= Range) and (abs(Point.Y - ts.Point.Y) <= Range) then begin
			//�ړ����̎��͈ړ���~
			Sit := 3;
			HPTick := timeGetTime();
			HPRTick := timeGetTime() - 500;
			SPRTick := timeGetTime();
			pcnt := 0;
			WFIFOW(0, $0088);
			WFIFOL(2, ID);
			WFIFOW(6, Point.X);
			WFIFOW(8, Point.Y);
			SendBCmd(tm, Point, 10);
			if ATick + ADelay - 200 < Tick then ATick := Tick - ADelay + 200;
		end;
		if (abs(Point.X - ts.Point.X) <= Range) and (abs(Point.Y - ts.Point.Y) <= Range) then begin
			//�U��
			if ts = nil then begin
				AMode := 0;
				Exit;
			end;
			if Weapon = 11 then begin
			//�|�U��
				if (Arrow = 0) or (Item[Arrow].Amount = 0) then begin
					//���������Ă��܂���
					WFIFOW(0, $013b);
					WFIFOW(2, 0);
					Socket.SendBuf(buf, 4);
					//AMode := 0;
					ATick := ATick + ADelay;
					Exit;
				end;
				//��������
				Dec(Item[Arrow].Amount);
				//�A�C�e��������
				WFIFOW( 0, $00af);
				WFIFOW( 2, Arrow);
				WFIFOW( 4, 1);
				Socket.SendBuf(buf, 6);
				if Item[Arrow].Amount = 0 then begin
					Item[Arrow].ID := 0;
					Arrow := 0;
				end;
			end;
			if Weight * 100 div MaxWeight >= 90 then begin
				//�d�ʃI�[�o�[
				WFIFOW(0, $013b);
				WFIFOW(2, 1);
				Socket.SendBuf(buf, 4);
				AMode := 0;
				Exit;
			end;
			// + �� �� �� �� �� �� +
			if (Option and 16 <> 0) and (Skill[129].Lv <> 0) and (Random(1000) < Param[5] * 10 div 3) then begin //�m���`�F�b�N
				if (JobLV + 9) div 10 < Skill[129].Lv then begin
					dmg[4] := (JobLV + 9) div 10;
				end else begin
					dmg[4] := Skill[129].lv;
				end;
				//dmg[4]��i���ϐ��Ɏg�p
				//�_���[�W�Z�o
				if Skill[128].Lv <> 0 then begin
					dmg[1] := Skill[128].Data.Data1[Skill[128].Lv] * 2;
				end else begin
					dmg[1] := 0;
				end;
				dmg[1] := dmg[1] + (Param[4] div 10 + Param[3] div 2) * 2 + 80;
				dmg[1] := dmg[1] * dmg[4];
				MMode := 0;
				MSkill := 129;
				MUseLV := $FFFF;
{�ύX}
				xy := ts.Point;
				//�_���[�W�Z�o
				sl := TStringList.Create;
				tl := Skill[129].Data;
				for j1 := (xy.Y - tl.Range2) div 8 to (xy.Y + tl.Range2) div 8 do begin
					for i1 := (xy.X - tl.Range2) div 8 to (xy.X + tl.Range2) div 8 do begin
						for k1 := 0 to tm.Block[i1][j1].Mob.Count - 1 do begin
							ts1 := tm.Block[i1][j1].Mob.Objects[k1] as TMob;
							if (abs(ts1.Point.X - xy.X) <= tl.Range2) and (abs(ts1.Point.Y - xy.Y) <= tl.Range2) then
								sl.AddObject(IntToStr(ts1.ID),ts1);
					 	end;
					end;
				end;
				if sl.Count <> 0 then begin
					for k1 := 0 to sl.Count - 1 do begin
						ts1 := sl.Objects[k1] as TMob;
						dmg[0] := dmg[1] * ElementTable[0][ts1.Element] div 100; //���������␳
						if dmg[0] < 0 then dmg[0] := 0; //���@�U���ł̉񕜂͖�����
						//�p�P���M
						SendCSkillAtk1(tm, tc, ts1, Tick, dmg[0], dmg[4]);
						//�_���[�W����
						if ts = ts1 then
							dmg[7] := dmg[0]
						else
							DamageProcess1(tm, tc, ts1, dmg[0], Tick);
					end;
				end;
				sl.Free;
{�ύX�R�R�܂�}
			end else begin
				dmg[7] := 0;
			end;
			//������I���

			//�_���[�W�Z�o
			DamageCalc1(tm, tc, ts, Tick);
			if dmg[0] < 0 then dmg[0] := 0; //�����U���ł̉񕜂͖�����
			if Weapon = 16 then begin
				//�J�^�[���ǌ�
				dmg[1] := dmg[0] * (1 + Skill[48].Lv * 2) div 100;
			end else if WeaponType[1] <> 0 then begin
				//�񓁗�����
				k := dmg[0];
				DamageCalc1(tm, tc, ts, Tick, 1);
				if dmg[0] < 0 then dmg[0] := 0; //�����U���ł̉񕜂͖�����
				dmg[1] := dmg[0];
				dmg[0] := k;
			end else begin
				dmg[1] := 0;
			end;
			WFIFOW( 0, $008a);
			WFIFOL( 2, ID);
			WFIFOL( 6, ATarget);
			WFIFOL(10, timeGetTime());
			WFIFOL(14, aMotion);
			WFIFOL(18, ts.Data.dMotion);
			WFIFOW(22, dmg[0]); //�_���[�W
			WFIFOW(24, dmg[4]); //������
			WFIFOB(26, dmg[5]); //0=�P�U�� 8=���� 10=�N���e�B�J��
			WFIFOW(27, dmg[1]); //�t��
			SendBCmd(tm, ts.Point, 29);
			//�X�v���b�V���U����t���ꍲ��(߁��)
			if SplashAttack then begin
{�ǉ�}  CharaSplash(tc,Tick);
			end;
			//�_���[�W����
			if not DamageProcess1(tm, tc, ts, dmg[0] + dmg[1] + dmg[7], Tick) then
{�ǉ�}	StatCalc1(tc, ts, Tick);
			//�C���@�@�[���@�M�B�[(;�L�D`)

			//Tick���Z
			ATick := ATick + ADelay;
		end;
	end;
end;
//------------------------------------------------------------------------------
procedure TfrmMain.CharaSplash(tc:TChara;Tick:cardinal);
var
	i1,j1,k1,k:integer;
	tm:TMap;
	ts:TMob;
	ts1:TMob;
	xy:TPoint;
  sl:TStringList;
begin
	with tc do begin
		ts := AData;
		tm := MData;
		xy := ts.Point;
		sl := TStringList.Create;
		for j1 := (xy.Y - 1) div 8 to (xy.Y + 1) div 8 do begin
			for i1 := (xy.X - 1) div 8 to (xy.X + 1) div 8 do begin
				for k1 := 0 to tm.Block[i1][j1].Mob.Count -1 do begin
					ts1 := tm.Block[i1][j1].Mob.Objects[k1] as TMob;
					if ts1 = ts then Continue;
					if (abs(ts1.Point.X - xy.X) <= 1) and (abs(ts1.Point.Y - xy.Y) <= 1) then
						sl.AddObject(IntToStr(ts1.ID),ts1);
				end;
			end;
		end;
		if sl.Count <> 0 then begin
			for k1 := 0 to sl.Count -1 do begin
				ts1 := sl.Objects[k1] as TMob;
				DamageCalc1(tm, tc, ts1, Tick);
				if dmg[0] < 0 then dmg[0] := 0; //�����U���ł̉񕜂͖�����
				if WeaponType[0] = 16 then begin
				//�J�^�[���ǌ�
					dmg[1] := dmg[0] * (1 + Skill[48].Lv * 2) div 100;
				end else if WeaponType[1] <> 0 then begin
					//�񓁗��E��
					k := dmg[0];
					DamageCalc1(tm, tc, ts, Tick, 1);
					dmg[1] := dmg[0];
					dmg[0] := k;
				end else begin
					dmg[1] := 0;
				end;
				WFIFOW( 0, $008a);
				WFIFOL( 2, ID);
				WFIFOL( 6, ts1.ID);
				WFIFOL(10, timeGetTime());
				WFIFOL(14, aMotion);
				WFIFOL(18, ts1.Data.dMotion);
				WFIFOW(22, dmg[0]); //�_���[�W
				WFIFOW(24, dmg[4]); //������
				WFIFOB(26, dmg[5]); //0=�P�U�� 8=���� 10=�N���e�B�J��
				WFIFOW(27, dmg[1]); //�t��
				SendBCmd(tm, ts1.Point, 29);
				//�_���[�W����
				if not DamageProcess1(tm, tc, ts1, dmg[0] + dmg[1], Tick) then
				StatCalc1(tc, ts1, Tick);
			end;
		end;
	end;
end;
//------------------------------------------------------------------------------
{�ǉ�}
procedure TfrmMain.CreateField(tc:TChara; Tick:Cardinal);
var
	j,k,m,b:Integer;
	i1,j1,k1:integer;
	tm  :TMap;
	tn  :TNPC;
	ts1 :TMob;
	tl  :TSkillDB;
	xy  :TPoint;
	bb  :array of byte;
  sl  :TStringList;
begin
	sl := TStringList.Create;
  tm := tc.MData;
	tl := tc.Skill[tc.MSkill].Data;
	with tc do begin
			case MSkill of
				21,91: //TS,HD (FB�Ƃقړ���)
					begin
						xy.X := MPoint.X;
						xy.Y := MPoint.Y;
						sl.Clear;
						for j1 := (xy.Y - tl.Range2) div 8 to (xy.Y + tl.Range2) div 8 do begin
							for i1 := (xy.X - tl.Range2) div 8 to (xy.X + tl.Range2) div 8 do begin
								for k1 := 0 to tm.Block[i1][j1].Mob.Count -1 do begin
									ts1 := tm.Block[i1][j1].Mob.Objects[k1] as TMob;
									if (abs(ts1.Point.X - xy.X) > tl.Range2) or (abs(ts1.Point.Y - xy.Y) > tl.Range2) then
										Continue;
									sl.AddObject(IntToStr(ts1.ID),ts1)
								end;
							end;
						end;
						if sl.Count <> 0 then begin
							for k1 := 0 to sl.Count -1 do begin
								ts1 := sl.Objects[k1] as TMob;
								//�_���[�W�Z�o
								dmg[0] := MATK1 + Random(MATK2 - MATK1 + 1) * MATKFix div 100 * tl.Data1[MUseLV] div 100;
								dmg[0] := dmg[0] * (100 - ts1.Data.MDEF) div 100; //MDEF%
								dmg[0] := dmg[0] - ts1.Data.Param[3]; //MDEF-
								if dmg[0] < 1 then dmg[0] := 1;
								dmg[0] := dmg[0] * ElementTable[tl.Element][ts1.Element] div 100;
								dmg[0] := dmg[0] * tl.Data2[MUseLV];
								if dmg[0] < 0 then dmg[0] := 0; //���@�U���ł̉񕜂͖�����
								SendCSkillAtk1(tm, tc, ts1, Tick, dmg[0], tl.Data2[MUseLV]);
								//�_���[�W����
								DamageProcess1(tm, tc, ts1, dmg[0], Tick);
							end;
						end;
						tc.MTick := Tick + 1000;
						if MSkill = 21 then Inc(tc.MTick,1000);
					end;
				12: //�Z�C�t�e�B�E�H�[��
					begin
						j := SearchCInventory(tc, 717, false);
						if (j <> 0) and (tc.Item[j].Amount >= 1) then begin
							//�A�C�e��������
							Dec(tc.Item[j].Amount, 1);
							if tc.Item[j].Amount = 0 then tc.Item[j].ID := 0;
							WFIFOW( 0, $00af);
							WFIFOW( 2, j);
							WFIFOW( 4, 1);
							tc.Socket.SendBuf(buf, 6);
							//�d�ʕύX
							tc.Weight := tc.Weight - tc.Item[j].Data.Weight * cardinal(1);
							WFIFOW( 0, $00b0);
							WFIFOW( 2, $0018);
							WFIFOL( 4, tc.Weight);
							tc.Socket.SendBuf(buf, 8);
							xy.X := MPoint.X;
							xy.Y := MPoint.Y;
							tn := SetSkillUnit(tm, ID, xy, Tick, $7e, tl.Data2[MUseLV], tl.Data1[MUseLV] * 1000);
							tn.MSkill := MSkill;
						end else begin
							tc.MMode := 4;
							tc.MPoint.X := 0;
							tc.MPoint.Y := 0;
							Exit;
						end;
					end;
				18: //�t�@�C�A�[�E�H�[��
					begin
						xy.X := MPoint.X - Point.X;
						xy.Y := MPoint.Y - Point.Y;
						if abs(xy.X) > abs(xy.Y) * 3 then begin
							//������
							if xy.X > 0 then b := 6 else b := 2;
						end else if abs(xy.Y) > abs(xy.X) * 3 then begin
							//�c����
							if xy.Y > 0 then b := 0 else b := 4;
						end else begin
							if xy.X > 0 then begin
								if xy.Y > 0 then b := 7 else b := 5;
							end else begin
								if xy.Y > 0 then b := 1 else b := 3;
							end;
						end;
						DebugOut.Lines.Add(Format('FireWall: (%d,%d) %d', [xy.X, xy.Y, b]));
						//�c����
						xy.X := MPoint.X;
						xy.Y := MPoint.Y;
						tn := SetSkillUnit(tm, ID, xy, Tick, $7f, tl.Data2[MUseLV], tl.Data2[MUseLV] * 1000);
						tn.CData := tc;
{�ǉ�}			tn.MSkill := MSkill;
						tn.MUseLV := MUseLV;
						SetLength(bb, 1);
						bb[0] := 2;
						DirMove(tm, xy, b, bb);
						tn := SetSkillUnit(tm, ID, xy, Tick, $7f, tl.Data2[MUseLV], tl.Data2[MUseLV] * 1000);
						tn.CData := tc;
{�ǉ�}			tn.MSkill := MSkill;
						tn.MUseLV := MUseLV;
						xy.X := MPoint.X;
						xy.Y := MPoint.Y;
						bb[0] := 6;
						DirMove(tm, xy, b, bb);
						tn := SetSkillUnit(tm, ID, xy, Tick, $7f, tl.Data2[MUseLV], tl.Data2[MUseLV] * 1000);
						tn.CData := tc;
{�ǉ�}			tn.MSkill := MSkill;
						tn.MUseLV := MUseLV;
						if (b mod 2) <> 0 then begin
							//�΂ߌ���
							xy.X := MPoint.X;
							xy.Y := MPoint.Y;
							bb[0] := 3;
							DirMove(tm, xy, b, bb);
							tn := SetSkillUnit(tm, ID, xy, Tick, $7f, tl.Data2[MUseLV], tl.Data2[MUseLV] * 1000);
							tn.CData := tc;
{�ǉ�}				tn.MSkill := MSkill;
							tn.MUseLV := MUseLV;
							xy.X := MPoint.X;
							xy.Y := MPoint.Y;
							bb[0] := 5;
							DirMove(tm, xy, b, bb);
							tn := SetSkillUnit(tm, ID, xy, Tick, $7f, tl.Data2[MUseLV], tl.Data2[MUseLV] * 1000);
							tn.CData := tc;
{�ǉ�}				tn.MSkill := MSkill;
							tn.MUseLV := MUseLV;
						end;
					end;
				25: //�j���[�}
					begin
						xy.X := MPoint.X;
						xy.Y := MPoint.Y;
						tn := SetSkillUnit(tm, ID, xy, Tick, $85, 0, tl.Data1[1] * 1000);
{�ǉ�}			tn.MSkill := MSkill;
					end;
				27: //���[�v�|�[�^��
					begin
						//�I��
						ZeroMemory(@buf[0], 68);
						WFIFOW( 0, $011c);
						WFIFOW( 2, 27);
						WFIFOS( 4, SaveMap + '.gat', 16);
						for j := 0 to tl.Data1[Skill[27].Lv] - 1 do begin
							if MemoMap[j] <> '' then WFIFOS(20+j*16, MemoMap[j] + '.gat', 16);
						end;
						Socket.SendBuf(buf, 68);
						MMode := 4;
						Exit;
					end;
				79: //�}�O�k�X
					begin
						for j1 := 1 to 7 do begin
							for i1 := 1 to 7 do begin
								if ((i1 < 3) or (i1 > 5)) and ((j1 < 3) or (j1 > 5)) then Continue;
								xy.X := (MPoint.X) -4 + i1;
								xy.Y := (MPoint.Y) -4 + j1;
								if (xy.X < 0) or (xy.X >= tm.Size.X) or (xy.Y < 0) or (xy.Y >= tm.Size.Y) then Continue;
								tn := SetSkillUnit(tm, ID, xy, Tick, $84, tl.Data2[MUseLV], tl.Data1[MUseLV] * 1600);
								tn.CData := tc;
{�ǉ�}					tn.MSkill := MSkill;
								tn.MUseLV := MUseLV;
							end;
						end;
					end;
				80: //FP
					begin
						xy.X := MPoint.X;
						xy.Y := MPoint.Y;
						tn := SetSkillUnit(tm, ID, xy, Tick, $87, MUseLV, 30000, tc);
{�ǉ�}			tn.MSkill := MSkill;
					end;
				85: //LoV
					begin
						xy.X := MPoint.X;
						xy.Y := MPoint.Y;
						tn := SetSkillUnit(tm, ID, xy, Tick, $86, 0, 3000, tc);
{�ǉ�}			tn.MSkill := MSkill;
{�ǉ�}			tn.MUseLV := MUseLV;
					end;
{:119}
				87: //�A�C�X�E�H�[��
					begin
						xy.X := MPoint.X - Point.X;
						xy.Y := MPoint.Y - Point.Y;
						if abs(xy.X) > abs(xy.Y) * 3 then begin
							//������
							if xy.X > 0 then b := 6 else b := 2;
						end else if abs(xy.Y) > abs(xy.X) * 3 then begin
							//�c����
							if xy.Y > 0 then b := 0 else b := 4;
						end else begin
							if xy.X > 0 then begin
								if xy.Y > 0 then b := 7 else b := 5;
							end else begin
								if xy.Y > 0 then b := 1 else b := 3;
							end;
						end;
						DebugOut.Lines.Add(Format('IceWall: (%d,%d) %d', [xy.X, xy.Y, b]));
						//�c����
						xy.X := MPoint.X;
						xy.Y := MPoint.Y;
						tn := SetSkillUnit(tm, ID, xy, Tick, $8d, tl.Data2[MUseLV], tl.Data2[MUseLV] * 1000);
						tn.CData := tc;
						tn.MSkill := MSkill;
						tn.MUseLV := MUseLV;
						SetLength(bb, 1);
						bb[0] := 2;
						DirMove(tm, xy, b, bb);
						tn := SetSkillUnit(tm, ID, xy, Tick, $8d, tl.Data2[MUseLV], tl.Data2[MUseLV] * 1000);
						tn.CData := tc;
						tn.MSkill := MSkill;
						tn.MUseLV := MUseLV;
						xy.X := MPoint.X;
						xy.Y := MPoint.Y;
						bb[0] := 6;
						DirMove(tm, xy, b, bb);
						tn := SetSkillUnit(tm, ID, xy, Tick, $8d, tl.Data2[MUseLV], tl.Data2[MUseLV] * 1000);
						tn.CData := tc;
						tn.MSkill := MSkill;
						tn.MUseLV := MUseLV;
						if (b mod 2) <> 0 then begin
							//�΂ߌ���
							xy.X := MPoint.X;
							xy.Y := MPoint.Y;
							bb[0] := 3;
							DirMove(tm, xy, b, bb);
							tn := SetSkillUnit(tm, ID, xy, Tick, $8d, tl.Data2[MUseLV], tl.Data2[MUseLV] * 1000);
							tn.CData := tc;
							tn.MSkill := MSkill;
							tn.MUseLV := MUseLV;
							xy.X := MPoint.X;
							xy.Y := MPoint.Y;
							bb[0] := 5;
							DirMove(tm, xy, b, bb);
							tn := SetSkillUnit(tm, ID, xy, Tick, $8d, tl.Data2[MUseLV], tl.Data2[MUseLV] * 1000);
							tn.CData := tc;
							tn.MSkill := MSkill;
							tn.MUseLV := MUseLV;
						end;
					end;
{:119}

				115: //SkdT
					begin
						xy.X := MPoint.X;
						xy.Y := MPoint.Y;
						tn := SetSkillUnit(tm, ID, xy, Tick, $90, MUseLV, tl.Data2[MUseLV] * 1000, tc);
{�ǉ�}			tn.MSkill := MSkill;
					end;
				116: //LM
					begin
						xy.X := MPoint.X;
						xy.Y := MPoint.Y;
						tn := SetSkillUnit(tm, ID, xy, Tick, $93, MUseLV, tl.Data2[MUseLV] * 1000, tc);
{�ǉ�}			tn.MSkill := MSkill;
					end;
				117: //AS
					begin
						xy.X := MPoint.X;
						xy.Y := MPoint.Y;
						tn := SetSkillUnit(tm, ID, xy, Tick, $91, MUseLV, tl.Data2[MUseLV] * 1000, tc);
{�ǉ�}			tn.MSkill := MSkill;
						tn.MUseLV := MUseLV;
					end;
{�ǉ�:119}
				119: //SM
					begin
						xy.X := MPoint.X;
						xy.Y := MPoint.Y;
						tn := SetSkillUnit(tm, ID, xy, Tick, $95, MUseLV, tl.Data2[MUseLV] * 1000, tc);
						tn.MSkill := MSkill;
					end;
				120: //�t���b�V���[
					begin
						xy.X := MPoint.X;
						xy.Y := MPoint.Y;
						tn := SetSkillUnit(tm, ID, xy, Tick, $96, MUseLV, tl.Data2[MUseLV] * 1000, tc);
						tn.MSkill := MSkill;
					end;
				121: //FT
					begin
						xy.X := MPoint.X;
						xy.Y := MPoint.Y;
						tn := SetSkillUnit(tm, ID, xy, Tick, $97, MUseLV, tl.Data2[MUseLV] * 1000, tc);
						tn.MSkill := MSkill;
					end;
				122: //BM
					begin
						xy.X := MPoint.X;
						xy.Y := MPoint.Y;
						tn := SetSkillUnit(tm, ID, xy, Tick, $8f, MUseLV, tl.Data2[MUseLV] * 1000, tc);
						tn.MSkill := MSkill;
					end;
				123: //CT
					begin
						xy.X := MPoint.X;
						xy.Y := MPoint.Y;
						tn := SetSkillUnit(tm, ID, xy, Tick, $98, MUseLV, tl.Data2[MUseLV] * 1000, tc);
						tn.MSkill := MSkill;
					end;
				else
					begin
						tc.MMode := 4;
						tc.MPoint.X := 0;
						tc.MPoint.Y := 0;
						Exit;
					end;

{�ǉ�:119�����܂�}
			end;
			WFIFOW( 0, $0117);
			WFIFOW( 2, MSkill);
			WFIFOL( 4, ID);
			WFIFOW( 8, MUseLV);
			WFIFOW(10, MPoint.X);
			WFIFOW(12, MPoint.Y);
			WFIFOL(14, 1);
			SendBCmd(tm, xy, 18);
	end;
	sl.Free;
	tc.MPoint.X := 0;
	tc.MPoint.Y := 0;
end;
//------------------------------------------------------------------------------
procedure TfrmMain.SkillEffect(tc:TChara; Tick:Cardinal);
var
	j,k,m,b:Integer;
	i1,j1,k1:integer;
	tm  :TMap;
	tc1 :TChara;
	ts  :TMob;
	ts1 :TMob;
	tl  :TSkillDB;
	xy  :TPoint;
	bb  :array of byte;
	tpa :TParty;
	sl  :TStringList;
	ProcessType :Byte;

begin
	sl := TStringList.Create;
	ProcessType := 0;
	with tc do begin
		tm := MData;
		tl := Skill[MSkill].Data;

		if MTargetType = 0 then begin
			ts := tc.AData;
			if (ts = nil) or (ts.HP = 0) then begin
				MSkill := 0;
				MUseLv := 0;
				MMode := 0;
				MTarget := 0;
				Exit;
			end;
			//�˒��`�F�b�N
			if (abs(Point.X - ts.Point.X) <= tl.Range) and (abs(Point.Y - ts.Point.Y) <= tl.Range) then begin
			end else begin
				if MTick + 500 < Tick then begin
					MMode := 4;
					Exit;
				end;
			end;
			case MSkill of
				5,42,46,56,136: //�o�b�V���A���}�[�ADS�A�s�A�[�X�ASB
					begin
						//�_���[�W�Z�o
						if MSkill = 5 then begin
							DamageCalc1(tm, tc, ts, Tick, 0, tl.Data1[MUseLV], tl.Element, tl.Data2[MUseLV]);
						end else begin
							DamageCalc1(tm, tc, ts, Tick, 0, tl.Data1[MUseLV], tl.Element, 0);
						end;
						if          MSkill = 46 then begin //DS��2�A��
							dmg[0] := dmg[0] * 2;
							j := 2;
						end else if MSkill = 56 then begin //�s�A�[�X��ts.Data.Scale + 1��hit
							j := ts.Data.Scale + 1;
							dmg[0] := dmg[0] * j;
						end else if MSkill = 136 then begin //SB�͘A��
							j := 8;
						end else begin
							j := 1;
						end;
						//���}�[��Zeny����
						if          MSkill = 42 then begin
							Dec(Zeny, tl.Data2[MUseLV]);
							//�������X�V
							WFIFOW(0, $00b1);
							WFIFOW(2, $0014);
							WFIFOL(4, Zeny);
							Socket.SendBuf(buf, 8);
						end;
						if dmg[0] < 0 then dmg[0] := 0; //�����U���ł̉񕜂͖�����
						//�p�P���M
						SendCSkillAtk1(tm, tc, ts, Tick, dmg[0], j);
						if (Skill[145].Lv <> 0) and (MSkill = 5) and (MUseLV >5) then begin //�}���˂�
							if Random(1000) < Skill[145].Data.Data1[MUseLV] * 10 then begin
								if (ts.Stat1 <> 3) then begin
									ts.nStat := 3;
									ts.BodyTick := Tick + tc.aMotion;
								end else ts.BodyTick := ts.BodyTick + 30000;
							end;
						end;
						if not DamageProcess1(tm, tc, ts, dmg[0], Tick) then
							StatCalc1(tc, ts, Tick);
					end;
				6: //�v���{�b�N
					begin
						ts.ATarget := tc.ID;
						ts.ARangeFlag := false;
						ts.AData := tc;
						//�p�P���M
						WFIFOW( 0, $011a);
						WFIFOW( 2, MSkill);
						WFIFOW( 4, MUseLV);
						WFIFOL( 6, MTarget);
						WFIFOL(10, ID);
						if ts.Data.Race <> 1 then begin
							WFIFOB(14, 1);
							ts.ATKPer := word(tl.Data1[MUseLV]);
							ts.DEFPer := word(tl.Data2[MUseLV]);
						end else begin
							WFIFOB(14, 0);
						end;
						SendBCmd(tm, ts.Point, 15);
					end;
				7,47,137: //MB�A�A���[�V�����[�A�O����
					begin
						//�_���[�W�Z�o1
						DamageCalc1(tm, tc, ts, Tick, 0, tl.Data1[MUseLV], tl.Element, tl.Data1[MUseLV]);
						if dmg[0] < 0 then dmg[0] := 0; //�����U���ł̉񕜂͖�����
						//�p�P���M
						SendCSkillAtk1(tm, tc, ts, Tick, dmg[0], 1, 6);
						if not DamageProcess1(tm, tc, ts, dmg[0], Tick) then
							StatCalc1(tc, ts, Tick);
						xy := ts.Point;
						//�_���[�W�Z�o2
						sl.Clear;
						for j1 := (xy.Y - tl.Range2) div 8 to (xy.Y + tl.Range2) div 8 do begin
							for i1 := (xy.X - tl.Range2) div 8 to (xy.X + tl.Range2) div 8 do begin
								for k1 := 0 to tm.Block[i1][j1].Mob.Count - 1 do begin
									ts1 := tm.Block[i1][j1].Mob.Objects[k1] as TMob;
									if ts = ts1 then Continue;
									if (abs(ts1.Point.X - xy.X) <= tl.Range2) and (abs(ts1.Point.Y - xy.Y) <= tl.Range2) then
										sl.AddObject(IntToStr(ts1.ID),ts1);
								end;
							end;
						end;
						if sl.Count <> 0 then begin
							for k1 := 0 to sl.Count - 1 do begin
								ts1 := sl.Objects[k1] as TMob;
								DamageCalc1(tm, tc, ts1, Tick, 0, tl.Data1[MUseLV], tl.Element, tl.Data2[MUseLV]);
								if dmg[0] < 0 then dmg[0] := 0; //�����U���ł̉񕜂͖�����
								//�p�P���M
								SendCSkillAtk1(tm, tc, ts1, Tick, dmg[0], 1, 5);
								//�_���[�W����
								if not DamageProcess1(tm, tc, ts1, dmg[0], Tick) then
{�ǉ�}						StatCalc1(tc, ts1, Tick);
							end;
						end;
					end;
				11,13,14,19,20,90,156: //BOLT,NB,SS,ES,HL
					begin
						//�_���[�W�Z�o
						dmg[0] := MATK1 + Random(MATK2 - MATK1 + 1) * MATKFix div 100 * tl.Data1[MUseLV] div 100;
						dmg[0] := dmg[0] * (100 - ts.Data.MDEF) div 100; //MDEF%
						dmg[0] := dmg[0] - ts.Data.Param[3]; //MDEF-
						if dmg[0] < 1 then dmg[0] := 1;
						dmg[0] := dmg[0] * ElementTable[tl.Element][ts.Element] div 100;
						dmg[0] := dmg[0] * tl.Data2[MUseLV];
						if dmg[0] < 0 then dmg[0] := 0; //���@�U���ł̉񕜂͖�����
						//�p�P���M
						SendCSkillAtk1(tm, tc, ts, Tick, dmg[0], tl.Data2[MUseLV]);
						DamageProcess1(tm, tc, ts, dmg[0], Tick);
						case MSkill of
							11,90:     tc.MTick := Tick + 1000;
							13:        tc.MTick := Tick +  800 + 400 * ((MUseLV + 1) div 2) - 300 * (MUseLV div 10);
							14,19,20 : tc.MTick := Tick +  800 + 200 * MUseLV;
							else       tc.MTick := Tick + 1000;
						end;
					end;
{�ǉ�}
				15: //FD
					begin
						//�_���[�W�Z�o
						dmg[0] := MATK1 + Random(MATK2 - MATK1 + 1) * MATKFix div 100 * ( MUseLV + 100 ) div 100;
						dmg[0] := dmg[0] * (100 - ts.Data.MDEF) div 100; //MDEF%
						dmg[0] := dmg[0] - ts.Data.Param[3]; //MDEF-
						if dmg[0] < 1 then dmg[0] := 1;
						dmg[0] := dmg[0] * ElementTable[tl.Element][ts.Element] div 100;
						if dmg[0] < 0 then dmg[0] := 0; //���@�U���ł̉񕜂͖�����
						//�p�P���M
						SendCSkillAtk1(tm, tc, ts, Tick, dmg[0], 1);
                                                if (ts.Data.race <> 1) and (ts.Data.MEXP = 0) and (dmg[0] <> 0)then begin
                                                        if Random(1000) < tl.Data1[MUseLV] * 10 then begin
                                                                ts.nStat := 2;
                                                                ts.BodyTick := Tick + tc.aMotion;
                                                        end;
                                                end;
						DamageProcess1(tm, tc, ts, dmg[0], Tick, False);
						tc.MTick := Tick + 1500;
					end;

{�ǉ��R�R�܂�}
{:119}
				16: //SC
					begin
						//�_���[�W�Z�o
						//�p�P���M
						WFIFOW( 0, $011a);
						WFIFOW( 2, MSkill);
						WFIFOW( 4, dmg[0]);
						WFIFOL( 6, MTarget);
						WFIFOL(10, ID);
						WFIFOB(14, 1);
						SendBCmd(tm, ts.Point, 15);
						if Random(1000) < tl.Data1[MUseLV] * 10 then begin
							if (ts.Stat1 <> 1) then begin
								ts.nStat := 1;
								ts.BodyTick := Tick + tc.aMotion;
							end;
						end;
					end;
{:119}
				17: //FB (HD�Ƃقړ���)
					begin
						xy := ts.Point;
						sl.Clear;
						for j1 := (xy.Y - tl.Range2) div 8 to (xy.Y + tl.Range2) div 8 do begin
							for i1 := (xy.X - tl.Range2) div 8 to (xy.X + tl.Range2) div 8 do begin
								for k1 := 0 to tm.Block[i1][j1].Mob.Count - 1 do begin
									ts1 := tm.Block[i1][j1].Mob.Objects[k1] as TMob;
									if ts = ts1 then Continue;
									if (abs(ts1.Point.X - xy.X) <= tl.Range2) and (abs(ts1.Point.Y - xy.Y) <= tl.Range2) then
										sl.AddObject(IntToStr(ts1.ID),ts1);
								end;
						 end;
						end;
						if sl.Count <> 0 then begin
							for k1 := 0 to sl.Count - 1 do begin
								ts1 := sl.Objects[k1] as TMob;
								dmg[0] := MATK1 + Random(MATK2 - MATK1 + 1) * MATKFix div 100 * tl.Data1[MUseLV] div 100;
								dmg[0] := dmg[0] * (100 - ts1.Data.MDEF) div 100; //MDEF%
								dmg[0] := dmg[0] - ts1.Data.Param[3]; //MDEF-
								if dmg[0] < 1 then dmg[0] := 1;
								dmg[0] := dmg[0] * ElementTable[tl.Element][ts1.Element] div 100;
								dmg[0] := dmg[0] * tl.Data2[MUseLV];
								if dmg[0] < 0 then dmg[0] := 0; //���@�U���ł̉񕜂͖�����
								if ts = ts1 then k := 0 else k := 5;
								SendCSkillAtk1(tm, tc, ts1, Tick, dmg[0], tl.Data2[MUseLV], k);
								//�_���[�W����
								DamageProcess1(tm, tc, ts1, dmg[0], Tick);
							end;
						end;
						tc.MTick := Tick + 1600;
					end;
				28: //�q�[��
					begin
						//�΃����X�^�[
						if (ts.Data.Race = 1) or (ts.Element mod 20 = 9) then begin
							//�΃A���f�b�h
							//�_���[�W�Z�o
							dmg[0] := ((BaseLV + Param[3]) div 8) * tl.Data1[MUseLV] * ElementTable[6][ts.Element] div 200;
							if dmg[0] < 0 then dmg[0] := 0; //���@�U���ł̉񕜂͖�����
							SendCSkillAtk1(tm, tc, ts, Tick, dmg[0], 1);
							DamageProcess1(tm, tc, ts, dmg[0], Tick);
						end else begin
							//�񕜗� = (( BaseLv + INT) / 8�̒[���؎̂� ) * ( �q�[��Lv x 8 + 4 )
							dmg[0] := ((BaseLV + Param[3]) div 8) * tl.Data1[MUseLV];
							ts.HP := ts.HP + dmg[0];
							if ts.HP > Integer(ts.Data.HP) then ts.HP := ts.Data.HP;
							//�p�P���M
							WFIFOW( 0, $011a);
							WFIFOW( 2, MSkill);
							WFIFOW( 4, dmg[0]);
							WFIFOL( 6, MTarget);
							WFIFOL(10, ID);
							WFIFOB(14, 1);
							SendBCmd(tm, ts.Point, 15);
						end;
						//�f�B���C
						tc.MTick := Tick + 1000;
					end;
				30: //���x����
					begin
						//�p�P���M
						WFIFOW( 0, $011a);
						WFIFOW( 2, MSkill);
						WFIFOW( 4, MUseLV);
						WFIFOL( 6, ts.ID);
						WFIFOL(10, ID);
						WFIFOB(14, 1);
						SendBCmd(tm, ts.Point, 15);
						ts.Speed := ts.Data.Speed * 2;
						tc.MTick := Tick + 1000;
					end;
{
				32: //�V�O�i��_�N���V�X
					begin
						ProcessType := 3;
						WFIFOW( 0, $011a);
						WFIFOW( 2, MSkill);
						WFIFOW( 4, dmg[0]);
						WFIFOL( 6, MTarget);
						WFIFOL(10, ID);
						WFIFOB(14, 1);
						SendBCmd(tm, ts.Point, 15);
					end;
}
				52: //�C���x
					begin
						DamageCalc1(tm, tc, ts, Tick, 0, 100, tl.Element);
						dmg[0] := dmg[0] + 15 * MUseLV;
						dmg[0] := dmg[0] * ElementTable[tl.Element][ts.Element] div 100;
						if dmg[0] < 0 then dmg[0] := 0; //�����U���ł̉񕜂͖�����
						SendCSkillAtk1(tm, tc, ts, Tick, dmg[0], 1);
						k1 := (BaseLV * 2 + MUseLV * 3 + 10) - (ts.Data.LV * 2 + ts.Data.Param[2]);
						k1 := k1 * 10;
						if Random(1000) < k1 then begin
							if not Boolean(ts.Stat2 and 1) then
								ts.HealthTick[0] := Tick + tc.aMotion
							else ts.HealthTick[0] := ts.HealthTick[0] + 30000;
						end;
						DamageProcess1(tm, tc, ts, dmg[0], Tick);
					end;
{�ǉ�:119}
				54: //���U���N�V����
					begin
						if (ts.Data.Race = 1) or (ts.Element mod 20 = 9) then begin
								//�΃A���f�b�h
							if (Random(1000) < MUseLV * 20 + Param[3] + Param[5] + BaseLV + Trunc((1 - HP / MAXHP) * 200)) and (ts.Data.MEXP = 0) then begin
								dmg[0] := ts.HP;
							end else begin
								dmg[0] := (BaseLV + Param[3] + (MUseLV * 10)) * ElementTable[6][ts.Element] div 100;
								if dmg[0] < 0 then dmg[0] := 0; //���@�U���ł̉񕜂͖�����
							end;
							if (dmg[0] div $010000) <> 0 then dmg[0] := $07FFF; //�ی�
							SendCSkillAtk1(tm, tc, ts, Tick, dmg[0], 1);
							DamageProcess1(tm, tc, ts, dmg[0], Tick);
							tc.MTick := Tick + 3000;
						end else begin
							tc.MMode := 4;
							Exit;
						end;
					end;
{�ǉ�:119�R�R�܂�}
				62: //BB
					begin
						//�Ƃ΂��������菈��
						//FW����̃p�N��
						xy.X := ts.Point.X - Point.X;
						xy.Y := ts.Point.Y - Point.Y;
						if abs(xy.X) > abs(xy.Y) * 3 then begin
							//������
							if xy.X > 0 then b := 6 else b := 2;
						end else if abs(xy.Y) > abs(xy.X) * 3 then begin
							//�c����
							if xy.Y > 0 then b := 0 else b := 4;
						end else begin
							if xy.X > 0 then begin
								if xy.Y > 0 then b := 7 else b := 5;
							end else begin
								if xy.Y > 0 then b := 1 else b := 3;
							end;
						end;

						//�e����΂��Ώۂɑ΂���_���[�W�̌v�Z
						DamageCalc1(tm, tc, ts, Tick, 0, tl.Data1[MUseLV], tl.Element, tl.Data1[MUseLV]);
						if dmg[0] < 0 then dmg[0] := 0; //�����U���ł̉񕜂͖�����
						//�p�P���M
						SendCSkillAtk1(tm, tc, ts, Tick, dmg[0], 1, 6);

						//�m�b�N�o�b�N����
						if (dmg[0] > 0) then begin
							SetLength(bb, 3);
							bb[0] := 4;
							xy := ts.Point;
							DirMove(tm, ts.Point, b, bb);
							//�u���b�N�ړ�
							if (xy.X div 8 <> ts.Point.X div 8) or (xy.Y div 8 <> ts.Point.Y div 8) then begin
								with tm.Block[xy.X div 8][xy.Y div 8].Mob do begin
									assert(IndexOf(ts.ID) <> -1, 'MobBlockDelete Error');
									Delete(IndexOf(ts.ID));
								end;
								tm.Block[ts.Point.X div 8][ts.Point.Y div 8].Mob.AddObject(ts.ID, ts);
							end;
							ts.pcnt := 0;
							//�p�P���M
							WFIFOW(0, $0088);
							WFIFOL(2, ts.ID);
							WFIFOW(6, ts.Point.X);
							WFIFOW(8, ts.Point.Y);
							SendBCmd(tm, ts.Point, 10);
							xy := ts.Point;
							//�������ݔ͈͍U��
							sl.Clear;
							for j1 := (xy.Y - tl.Range2) div 8 to (xy.Y + tl.Range2) div 8 do begin
								for i1 := (xy.X - tl.Range2) div 8 to (xy.X + tl.Range2) div 8 do begin
									for k1 := 0 to tm.Block[i1][j1].Mob.Count - 1 do begin
										ts1 := tm.Block[i1][j1].Mob.Objects[k1] as TMob;
										if ts = ts1 then Continue;
										if (abs(ts1.Point.X - xy.X) <= tl.Range2) and (abs(ts1.Point.Y - xy.Y) <= tl.Range2) then
											sl.AddObject(IntToStr(ts1.ID),ts1);
									end;
								end;
							end;
							if sl.Count <> 0 then begin
								for k1 := 0 to sl.Count - 1 do begin
									ts1 := sl.Objects[k1] as TMob;
									DamageCalc1(tm, tc, ts1, Tick, 0, tl.Data1[MUseLV], tl.Element, tl.Data2[MUseLV]);
									if dmg[0] < 0 then dmg[0] := 0; //�����U���ł̉񕜂͖�����
									//�p�P���M
									SendCSkillAtk1(tm, tc, ts1, Tick, dmg[0], 1, 5);
									//�_���[�W����
									if not DamageProcess1(tm, tc, ts1, dmg[0], Tick) then
{�ǉ�}							StatCalc1(tc, ts1, Tick);
								end;
							end;
						end;
						if not DamageProcess1(tm, tc, ts, dmg[0], Tick) then
{�ǉ�}				StatCalc1(tc, ts, Tick);
					end;
{:119}
				72: //���J�o���[
					begin
						ts.ATarget := 0;
						if ts.Element mod 20 = 9 then begin
							//�p�P���M
							WFIFOW( 0, $011a);
							WFIFOW( 2, MSkill);
							WFIFOW( 4, MUseLV);
							WFIFOL( 6, MTarget);
							WFIFOL(10, ID);
							WFIFOB(14, 1);
							SendBCmd(tm, ts.Point, 15);
							//�΃A���f�b�h
							if Boolean((1 shl 4) and ts.Stat2) then begin
								ts.HealthTick[4] := ts.HealthTick[4] + 30000; //����
							end else begin
								ts.HealthTick[4] := Tick + tc.aMotion;
							end;
						end;
					end;
				76: //���b�N�X�f�r�[�i
					begin
						//�p�P���M
						WFIFOW( 0, $011a);
						WFIFOW( 2, MSkill);
						WFIFOW( 4, MUseLV);
						WFIFOL( 6, MTarget);
						WFIFOL(10, ID);
						WFIFOB(14, 1);
						SendBCmd(tm, ts.Point, 15);
						//�΃A���f�b�h
						if Boolean((1 shl 2) and ts.Stat2) then begin
							ts.HealthTick[2] := ts.HealthTick[2] + 30000; //����
						end else begin
							ts.HealthTick[2] := Tick + tc.aMotion;
						end;
					end;
{:119}
				77: //�^�[���A���f�b�g
					begin
						if (ts.Data.Race = 1) or (ts.Element mod 20 = 9) then begin
							m := MUseLV * 20 + Param[3] + Param[5] + BaseLV + (200 - 200 * Cardinal(ts.HP) div ts.Data.HP) div 200;
							if (Random(1000) < m) and (ts.Data.MEXP = 0) then begin
								dmg[0] := ts.HP;
							end else begin
{�ύX}					dmg[0] := (BaseLV + Param[3] + (MUseLV * 10)) * ElementTable[6][ts.Element] div 100;
								if dmg[0] < 0 then dmg[0] := 0; //���@�U���ł̉񕜂͖�����
							end;
							//�΃A���f�b�h
							if (dmg[0] div $010000) <> 0 then dmg[0] := $07FFF; //�ی�
							SendCSkillAtk1(tm, tc, ts, Tick, dmg[0], 1);
							DamageProcess1(tm, tc, ts, dmg[0], Tick);
							tc.MTick := Tick + 3000;
						end else begin
							tc.MMode := 4;
							Exit;
						end;
					end;
				78: //���b�N�X_�G�[�e���i
					begin
						//�p�P���M
						WFIFOW( 0, $011a);
						WFIFOW( 2, MSkill);
						WFIFOW( 4, MUseLV);
						WFIFOL( 6, MTarget);
						WFIFOL(10, ID);
						WFIFOB(14, 1);
						SendBCmd(tm, ts.Point, 15);
						if (ts.Stat1 = 0) or (ts.Stat1 = 3) or (ts.Stat1 = 4) then begin
							ts.nStat := 5;
							ts.BodyTick := Tick + tc.aMotion;
						end else if (ts.Stat1 = 5) then ts.BodyTick := ts.BodyTick + 30000;
						end;
				84: //JT
					begin

						xy.X := ts.Point.X - Point.X;
						xy.Y := ts.Point.Y - Point.Y;
						if abs(xy.X) > abs(xy.Y) * 3 then begin
							//������
							if xy.X > 0 then   b := 6 else b := 2;
						end else if abs(xy.Y) > abs(xy.X) * 3 then begin
							//�c����
							if xy.Y > 0 then   b := 0 else b := 4;
						end else begin
							if xy.X > 0 then begin
								if xy.Y > 0 then b := 7 else b := 5;
							end else begin
								if xy.Y > 0 then b := 1 else b := 3;
							end;
						end;

						//�_���[�W�Z�o
						dmg[0] := MATK1 + Random(MATK2 - MATK1 + 1) * MATKFix div 100 * tl.Data1[MUseLV] div 100;
						dmg[0] := dmg[0] * (100 - ts.Data.MDEF) div 100; //MDEF%
						dmg[0] := dmg[0] - ts.Data.Param[3]; //MDEF-
						if dmg[0] < 1 then dmg[0] := 1;
						dmg[0] := dmg[0] * ElementTable[tl.Element][ts.Element] div 100;
						dmg[0] := dmg[0] * tl.Data2[MUseLV];
						if dmg[0] < 0 then dmg[0] := 0; //���@�U���ł̉񕜂͖�����
						//�p�P���M
						SendCSkillAtk1(tm, tc, ts, Tick, dmg[0], tl.Data2[MUseLV]);
						//�m�b�N�o�b�N����
						if (dmg[0] > 0) then begin
							SetLength(bb, tl.Data2[MUseLV] div 2);
							bb[0] := 4;
							xy.X := ts.Point.X;
							xy.Y := ts.Point.Y;
							DirMove(tm, ts.Point, b, bb);
							//�u���b�N�ړ�
							if (xy.X div 8 <> ts.Point.X div 8) or (xy.Y div 8 <> ts.Point.Y div 8) then begin
								with tm.Block[xy.X div 8][xy.Y div 8].Mob do begin
									assert(IndexOf(ts.ID) <> -1, 'MobBlockDelete Error');
									Delete(IndexOf(ts.ID));
								end;
								tm.Block[ts.Point.X div 8][ts.Point.Y div 8].Mob.AddObject(ts.ID, ts);
							end;
							ts.pcnt := 0;
						//�p�P���M
						WFIFOW(0, $0088);
						WFIFOL(2, ts.ID);
						WFIFOW(6, ts.Point.X);
						WFIFOW(8, ts.Point.Y);
						SendBCmd(tm, ts.Point, 10);
						end;
						DamageProcess1(tm, tc, ts, dmg[0], Tick);
					end;
				88: //�t���X�g�m���@
					begin
                                                SendCSkillAtk1(tm, tc, ts, 15, 35000, 1, 6);
						xy := ts.Point;
						sl.Clear;
						for j1 := (xy.Y - tl.Range2) div 8 to (xy.Y + tl.Range2) div 8 do begin
							for i1 := (xy.X - tl.Range2) div 8 to (xy.X + tl.Range2) div 8 do begin
								for k1 := 0 to tm.Block[i1][j1].Mob.Count - 1 do begin
									ts1 := tm.Block[i1][j1].Mob.Objects[k1] as TMob;
									if ts = ts1 then Continue;
									if (abs(ts1.Point.X - xy.X) <= tl.Range2) and (abs(ts1.Point.Y - xy.Y) <= tl.Range2) then
										sl.AddObject(IntToStr(ts1.ID),ts1);
                                                                end;
                                                        end;
						end;
						if sl.Count <> 0 then begin
							for k1 := 0 to sl.Count - 1 do begin
								ts1 := sl.Objects[k1] as TMob;
								dmg[0] := MATK1 + Random(MATK2 - MATK1 + 1) * MATKFix div 100;
								dmg[0] := dmg[0] * (100 - ts1.Data.MDEF) div 100; //MDEF%
								dmg[0] := dmg[0] - ts1.Data.Param[3]; //MDEF-
								if dmg[0] < 1 then dmg[0] := 1;
								dmg[0] := dmg[0] * ElementTable[tl.Element][ts1.Element] div 100;
								if dmg[0] < 0 then dmg[0] := 0; //���@�U���ł̉񕜂͖�����
								SendCSkillAtk1(tm, tc, ts1, Tick, dmg[0], 1 , 5);
                                                                if (ts1.Data.race <> 1) and (ts1.Data.MEXP = 0) and (dmg[0] <> 0)then begin
                                                                        if Random(1000) < tl.Data1[MUseLV] * 10 then begin
								                ts1.nStat := 2;
								                ts1.BodyTick := Tick + tc.aMotion;
                                                                        end;
						                end;
								//�_���[�W����
								DamageProcess1(tm, tc, ts1, dmg[0], Tick);
							end;
						end;
                                                tc.MTick := Tick + 1000;
					end;
				86: //�E�H�[�^�[�{�[��
					begin
                                                k := tl.Data1[MUseLV];
                                                for m := 0 to k - 1 do begin
                                                if dmg[1] <> 0 then begin
                                                        dmg[0] := MATK1 + Random(MATK2 - MATK1 + 1) * MATKFix div 100;
                                                        dmg[0] := dmg[0] * (100 - ts.Data.MDEF) div 100; //MDEF%
                                                        dmg[0] := dmg[0] - ts.Data.Param[3]; //MDEF-
                                                        if dmg[0] < 1 then dmg[0] := 1;
                                                        dmg[0] := dmg[0] * ElementTable[tl.Element][ts.Element] div 100;
                                                        if dmg[0] < 0 then dmg[0] := 0; //���@�U���ł̉񕜂͖�����
                                                        SendCSkillAtk1(tm, tc, ts, Tick, dmg[0], 1);
                                                        //�_���[�W����
                                                        DamageProcess1(tm, tc, ts, dmg[0], Tick);
                				        xy := ts.Point;
						        sl.Clear;
						        for j1 := (xy.Y - tl.Data2[MUseLV]) div 8 to (xy.Y + tl.Data2[MUseLV]) div 8 do begin
							        for i1 := (xy.X - tl.Data2[MUseLV]) div 8 to (xy.X + tl.Data2[MUseLV]) div 8 do begin
								        for k1 := 0 to tm.Block[i1][j1].Mob.Count - 1 do begin
									        ts1 := tm.Block[i1][j1].Mob.Objects[k1] as TMob;
									        if ts = ts1 then Continue;
									        if (abs(ts1.Point.X - xy.X) <= tl.Data2[MUseLV]) and (abs(ts1.Point.Y - xy.Y) <= tl.Data2[MUseLV]) then
										        sl.AddObject(IntToStr(ts1.ID),ts1);
								        end;
                                                                end;
						        end;
						        if sl.Count <> 0 then begin
							        for k1 := 0 to sl.Count - 1 do begin
                                                                        ts1 := sl.Objects[k1] as TMob;
                                                                        dmg[0] := MATK1 + Random(MATK2 - MATK1 + 1) * MATKFix div 100;
                                                                        dmg[0] := dmg[0] * (100 - ts1.Data.MDEF) div 100; //MDEF%
                                                                        dmg[0] := dmg[0] - ts1.Data.Param[3]; //MDEF-
                                                                        if dmg[0] < 1 then dmg[0] := 1;
                                                                        dmg[0] := dmg[0] * ElementTable[tl.Element][ts1.Element] div 100;
                                                                        if dmg[0] < 0 then dmg[0] := 0; //���@�U���ł̉񕜂͖�����
                                                                        SendCSkillAtk1(tm, tc, ts1, Tick, dmg[0], 1);
                                                                        //�_���[�W����
                                                                        DamageProcess1(tm, tc, ts1, dmg[0], Tick)
                                                                end;
                                                        end;
                                                        end;
                                                        end;
					end;
				93: //�����X�^�[���
					begin
						ts := AData;
						WFIFOW(0, $018c);
						WFIFOW(2, ts.Data.ID);//ID
						WFIFOW(4, ts.Data.LV);//���x��
						WFIFOW(6, ts.Data.Scale);//�T�C�Y
						WFIFOL(8, ts.HP);//HP
						//WFIFOW(10, 0);//
						WFIFOW(12, ts.Data.DEF);//DEF
						WFIFOW(14, ts.Data.Race);//�푰
						WFIFOW(16, ts.Data.MDEF);//MDEF
						WFIFOW(18, ts.Element);//����
						for j := 0 to 8 do begin
							if (ElementTable[j+1][ts.Element] < 0) then begin
								WFIFOB(20+j, 0);//�}�C�i�X���Ɣ͈̓G���[�o���̂�0�ɂ���
							end else begin
								WFIFOB(20+j, ElementTable[j+1][ts.Element]);//���@��������
							end;
						end;
						Socket.SendBuf(buf,29);//�d�l�Ƃ��Ă͂������̕����ނ��낢���̂ł́H�{�l�݂̂Ɍ�����
						WFIFOW( 0, $011a);
						WFIFOW( 2, MSkill);
						WFIFOW( 4, dmg[0]);
						WFIFOL( 6, MTarget);
						WFIFOL(10, ID);
						WFIFOB(14, 1);
						SendBCmd(tm, ts.Point, 15);
					end;
				129://Blitz beat
					begin
						xy := ts.Point;
						//�_���[�W�Z�o
						sl.Clear;
						for j1 := (xy.Y - tl.Range2) div 8 to (xy.Y + tl.Range2) div 8 do begin
							for i1 := (xy.X - tl.Range2) div 8 to (xy.X + tl.Range2) div 8 do begin
								for k1 := 0 to tm.Block[i1][j1].Mob.Count - 1 do begin
									ts1 := tm.Block[i1][j1].Mob.Objects[k1] as TMob;
									if ts = ts1 then Continue;
									if (abs(ts1.Point.X - xy.X) <= tl.Range2) and (abs(ts1.Point.Y - xy.Y) <= tl.Range2) then
										sl.AddObject(IntToStr(ts1.ID),ts1);
							 	end;
							end;
						end;
						if sl.Count <> 0 then begin
							if Skill[128].Lv <> 0 then begin
								dmg[1] := Skill[128].Data.Data1[Skill[128].Lv] * 2;
							end else begin
								dmg[1] := 0
							end;
							dmg[1] := dmg[1] + (Param[4] div 10 + Param[3] div 2) * 2 + 80;
							dmg[1] := dmg[1] * MUseLV;
							for k1 := 0 to sl.Count - 1 do begin
								ts1 := sl.Objects[k1] as TMob;
								dmg[0] := dmg[1] * ElementTable[tl.Element][ts1.Element] div 100;
								if dmg[0] < 0 then dmg[0] := 0; //���@�U���ł̉񕜂͖�����
								SendCSkillAtk1(tm, tc, ts1, Tick, dmg[0], MUseLV);
								//�_���[�W����
								DamageProcess1(tm, tc, ts1, dmg[0], Tick);
							end;
						end;
					end;
{}
				148: //�`���[�W_�A���[
					begin
						//�Ƃ΂��������菈��
						//FW����̃p�N��
						xy.X := ts.Point.X - Point.X;
						xy.Y := ts.Point.Y - Point.Y;
						if abs(xy.X) > abs(xy.Y) * 3 then begin
							//������
							if xy.X > 0 then b := 6 else b := 2;
							end else if abs(xy.Y) > abs(xy.X) * 3 then begin
								//�c����
								if xy.Y > 0 then b := 0 else b := 4;
								end else begin
									if xy.X > 0 then begin
									if xy.Y > 0 then b := 7 else b := 5;
								end else begin
									if xy.Y > 0 then b := 1 else b := 3;
							end;
						end;

						//�e����΂��Ώۂɑ΂���_���[�W�̌v�Z
						DamageCalc1(tm, tc, ts, Tick, 0, tl.Data1[MUseLV], tl.Element, 0);
						if dmg[0] < 0 then dmg[0] := 0; //�����U���ł̉񕜂͖�����
						//�p�P���M
						SendCSkillAtk1(tm, tc, ts, Tick, dmg[0], 1);

						//�m�b�N�o�b�N����
						if (dmg[0] > 0) then begin
							SetLength(bb, 6);
							bb[0] := 6;
							xy := ts.Point;
							DirMove(tm, ts.Point, b, bb);
							//�u���b�N�ړ�
							if (xy.X div 8 <> ts.Point.X div 8) or (xy.Y div 8 <> ts.Point.Y div 8) then begin
								with tm.Block[xy.X div 8][xy.Y div 8].Mob do begin
									assert(IndexOf(ts.ID) <> -1, 'MobBlockDelete Error');
									Delete(IndexOf(ts.ID));
								end;
								tm.Block[ts.Point.X div 8][ts.Point.Y div 8].Mob.AddObject(ts.ID, ts);
							end;
							ts.pcnt := 0;
							//�p�P���M
							WFIFOW(0, $0088);
							WFIFOL(2, ts.ID);
							WFIFOW(6, ts.Point.X);
							WFIFOW(8, ts.Point.Y);
							SendBCmd(tm, ts.Point, 10);
						end;
						if not DamageProcess1(tm, tc, ts, dmg[0], Tick) then
							StatCalc1(tc, ts, Tick);
					end;
				152: //�Γ���
					begin
						dmg[0] := 30;
						dmg[0] := dmg[0] * ElementTable[tl.Element][ts.Element] div 100;
						SendCSkillAtk1(tm, tc, ts, Tick, dmg[0], 1);
						if Random(1000) < 50 then begin
							if (ts.Stat1 <> 3) then begin
								ts.nStat := 3;
								ts.BodyTick := Tick + tc.aMotion;
							end else ts.BodyTick := ts.BodyTick + 30000;
						end;
						DamageProcess1(tm, tc, ts, dmg[0], Tick, False);
					end;
				253: //�z�[���[�N���X�i�b��j
					begin
						//�_���[�W�Z�o1
						DamageCalc1(tm, tc, ts, Tick, 0, tl.Data1[MUseLV], tl.Element, tl.Data1[MUseLV]);
						if dmg[0] < 0 then dmg[0] := 0; //�����U���ł̉񕜂͖�����
						//�p�P���M
						SendCSkillAtk1(tm, tc, ts, Tick, dmg[0], 1);
						xy := ts.Point;
						//�_���[�W�Z�o
						sl.Clear;
						for j1 := (xy.Y - tl.Range2) div 8 to (xy.Y + tl.Range2) div 8 do begin
							for i1 := (xy.X - tl.Range2) div 8 to (xy.X + tl.Range2) div 8 do begin
								for k1 := 0 to tm.Block[i1][j1].Mob.Count - 1 do begin
									ts1 := tm.Block[i1][j1].Mob.Objects[k1] as TMob;
									//�\���̌v�Z x����v����y���͈͓����Ay����v����x���͈͓�
									if ts = ts1 then Continue;
									if ((abs(ts1.Point.X - xy.X) = 0) and (abs(ts1.Point.Y - xy.Y) <= tl.Range2)) or
									((abs(ts1.Point.X - xy.X) <= tl.Range2) and (abs(ts1.Point.Y - xy.Y) = 0)) then begin
										sl.AddObject(IntToStr(ts1.ID),ts1);
									end;
								end;
							end;
						end;
						if sl.Count <> 0then begin
							for k := 0 to sl.Count -1 do begin
								ts1 := sl.Objects[k] as TMob;
								DamageCalc1(tm, tc, ts1, Tick, 0, tl.Data1[MUseLV], tl.Element, tl.Data2[MUseLV]);
								if dmg[0] < 0 then dmg[0] := 0; //�����U���ł̉񕜂͖�����
								//�p�P���M �z�[���[�N���X�͂Q�A���炵��
								SendCSkillAtk1(tm, tc, ts1, Tick, dmg[0], 2);
								//�_���[�W����
								if not DamageProcess1(tm, tc, ts1, dmg[0], Tick) then
									StatCalc1(tc, ts1, Tick);
							end;
						end;
						if not DamageProcess1(tm, tc, ts, dmg[0], Tick) then
							StatCalc1(tc, ts, Tick);
					end;
				else
					begin
						tc.MMode := 4;
						Exit;
					end;
{}
			end;
		end else begin //MTargetType = 0
			tc1 := tc.AData;
			if tc1 <> nil then begin
				//�˒��`�F�b�N
				if (abs(Point.X - tc1.Point.X) <= tl.Range) and (abs(Point.Y - tc1.Point.Y) <= tl.Range) then begin
				end else begin
					if MTick + 500 < Tick then begin
						MMode := 4;
						Exit;
					end;
				end;
			end;
			case tc.MSkill of
				8: //�C���f���A
					begin
						tc1 := tc;
						ProcessType := 2;
					end;
				10,24: //�T�C�g�A���A�t
					begin
						tc1 := tc;
						Option := Option or 1;
						WFIFOW(0, $0119);
						WFIFOL(2, ID);
						WFIFOW(6, 0);
						WFIFOW(8, 0);
						WFIFOW(10, Option);
						WFIFOB(12, 0);
						SendBCmd(tm, Point, 13);
						ProcessType := 2;
					end;
				28: //�q�[��
					begin
						//�΃v���C���[
						//�񕜗� = (( BaseLv + INT) / 8�̒[���؎̂� ) * ( �q�[��Lv x 8 + 4 )
						dmg[0] := ((BaseLV + Param[3]) div 8) * tl.Data1[MUseLV];
						tc1.HP := tc1.HP + dmg[0];
						if tc1.HP > tc1.MAXHP then tc1.HP := tc1.MAXHP;
						SendCStat1(tc1, 0, 5, tc1.HP);
						ProcessType := 0;
						tc.MTick := Tick + 1000;
					end;
				29: //���x����
					begin
						ProcessType := 3;
						tc.MTick := Tick + 1000;
					end;
{
				31: //�A�N�A_�x�l�f�B�b�N�^
					begin
						ProcessType := 3;
					end;
}
				33: //�G���W�F���X
					begin
						tc1 := tc;
						ProcessType := 5;
					end;
				34: //�u���X
					begin
						ProcessType := 3;
					end;
				35: //�L���A�|
					begin
						tc1.Stat2 := tc1.Stat2 and (not $1C);
						ProcessType := 0;
					end;
				45: //�W���͌���
					begin
						tc1 := tc;
						ProcessType := 3;
					end;
				51: //�n�C�f�B���O
					begin
						if tc.Option = 6 then begin
							tc.Option := tc.Optionkeep;
							ProcessType := 2;
                                                        tc.SP := tc.SP + 10;
                                                        if tc.SP > tc.MAXSP then tc.SP := tc.SP;
						end else begin
                                                        tc.Optionkeep := tc.Option;
							tc.Option := 6;
							ProcessType := 2;
						end;
						WFIFOW(0, $0119);
						WFIFOL(2, tc.ID);
						WFIFOW(6, tc.Stat1);
						WFIFOW(8, tc.Stat2);
						WFIFOW(10, tc.Option);
						WFIFOB(12, 0);
						SendBCmd(tm, tc.Point, 13);
					end;
				54: //���U���N�V����
					begin
						if (tc1.Sit <> 1) or (tc1.HP > 0) then begin
							dmg[0] := 0;
							Exit;
						end else begin
							dmg[0] := ((tc1.MAXHP * tl.Data1[MUseLV]) div 100) + 1;
							tc1.Sit := 3;
							tc1.HP := tc1.HP + dmg[0];
							SendCStat1(tc1, 0, 5, tc1.HP);
							WFIFOW( 0, $0148);
							WFIFOL( 2, tc1.ID);
							WFIFOW( 6, 100);
							SendBCmd(tm, tc1.Point, 8);
						end;
						ProcessType := 0;
					end;
				60,258: //�c�[�n���h�N�C�b�N��//Editted By AppleGirl
					begin
						tc1 := tc;
						//�p�P���M
						WFIFOW( 0, $00b0);
						WFIFOW( 2, $0035);
						WFIFOL( 4, ASpeed);
						Socket.SendBuf(buf[0], 8);
						ProcessType := 3;
					end;
				61: //AC
					begin
						tc1 := tc;
						ProcessType := 3;
					end;
				66: //�C���|�V�e�B�I_�}�k�X
					begin
						ProcessType := 3;
						tc.MTick := Tick + 3000;
					end;
				67: //�T�t���M�E��
					begin
						ProcessType := 3;
						ProcessType := 2;
					end;
				154: //�`�F���W�J�[�g
					begin
						tc1 := tc;
					end;
				68: //�A�X�y���V�I
					begin
						ProcessType := 3;
                                        end;
				69: //���̍~��
					begin
						ProcessType := 3;
					end;
				73: //�L���G_�G�����C�\��
					begin
						tc1 := tc;
						ProcessType := 5;
					end;
				74: //�}�j�s�J�b�g
					begin
						tc1 := tc;
						ProcessType := 5;
					end;
{�ǉ�:119}
				75: //�O�����A
					begin
						tc1 := tc;
						ProcessType := 5;
						tc.MTick := Tick + 2000;
					end;
{�ǉ�:119�R�R�܂�}
{�ǉ�:code}
				111: //�A�h���i����_���b�V
					begin
						tc1 := tc;
						ProcessType := 5;
					end;
				112: //�E�F�|���p�[�t�F�N�V����
					begin
						tc1 := tc;
						ProcessType := 4;
					end;
				113: //�I�[�o�[�g���X�g
					begin
						tc1 := tc;
						ProcessType := 5;
					end;
{				114: //��L�V��C�Y�p���[
					begin
						tc1 := tc;
						ProcessType := 5;
					end;}
				138: //�G���`�����g_�|�C�Y��
					begin
						ProcessType := 3;
					end;
{				139: //�|�C�Y��_���A�N�g
					begin
						tc1 := tc;
						ProcessType := 5;
					end;}
{�ǉ�:code�R�R�܂�}
{�ǉ�:119}
				142: //���}�蓖
					begin
						dmg[0] := 5;
						tc.HP := tc.HP + dmg[0];
						if tc.HP > tc.MAXHP then tc.HP := tc.MAXHP;
						SendCStat1(tc, 0, 5, tc.HP);
						ProcessType := 0;
					end;
				143: //���񂾃t��
					begin
						if tc1.Sit = 1 then begin
							tc1.Sit := 0;
							WFIFOW( 0, $0148);
							WFIFOL( 2, tc1.ID);
							WFIFOW( 6, 100);
							SendBCmd(tm, tc1.Point, 8);
						end else begin
							tc1.Sit := 1;
							//�b��
							WFIFOW(0, $0080);
							WFIFOL(2, tc.ID);
							WFIFOB(6, 1);
							Socket.SendBuf(buf, 7);
						end;
						ProcessType := 2;
					end;
				157: //�G�l���M�[�R�[�g
					begin
						tc1 := tc;
						ProcessType := 3;
					end;
				155: //�吺�̏�
					begin
						tc1 := tc;
						ProcessType := 3;
					end;
				else
					begin
						tc.MMode := 4;
						Exit;
					end;
{�ǉ�:119�R�R�܂�}
			end;
			case ProcessType of
				0: //�΃v���C���[�A���Ԑ�������
					begin
						//�p�P���M
						WFIFOW( 0, $011a);
						WFIFOW( 2, MSkill);
						WFIFOW( 4, dmg[0]);
						WFIFOL( 6, tc1.ID);
						WFIFOL(10, ID);
						WFIFOB(14, 1);
						SendBCmd(tm, tc1.Point, 15);
          end;
				2, 3: //�΃v���C���[�A���Ԑ����L��X�L��
					begin
						//�p�P���M
						WFIFOW( 0, $011a);
						WFIFOW( 2, MSkill);
						WFIFOW( 4, MUseLV);
						WFIFOL( 6, tc1.ID);
						WFIFOL(10, ID);
						WFIFOB(14, 1);
						SendBCmd(tm, tc1.Point, 15);
						tc1.Skill[MSkill].Tick := Tick + cardinal(tl.Data1[MUseLV]) * 1000;
						tc1.Skill[MSkill].EffectLV := MUseLV;
						tc1.Skill[MSkill].Effect1 := tl.Data2[MUseLV];
						if SkillTick > tc1.Skill[MSkill].Tick then begin
							SkillTick := tc1.Skill[MSkill].Tick;
							SkillTickID := MSkill;
						end;
						if MSkill = 61 then tc1.Skill[MSkill].Tick := Tick + cardinal(tl.Data1[MUseLV]) * 110;
						CalcStat(tc1, Tick);
						if ProcessType = 3 then SendCStat(tc1);
						//�A�C�R���\��
{�C��}			if tl.Icon <> 0 then begin
							DebugOut.Lines.Add('(߁��)!');
							WFIFOW(0, $0196);
							WFIFOW(2, tl.Icon);
							WFIFOL(4, ID);
							WFIFOB(8, 1);
							//Socket.SendBuf(buf, 9);
                                                        SendBCmd(tm, tc1.Point, 9);
						end;
					end;
{�p�[�e�B�[�@�\�ǉ�}
				4,5: //�΃p�[�e�B���Ԑ����L��X�L��(4�̓X�e�[�^�X�\�����ς��Ȃ����� 5�̓X�e�[�^�X�\���ɕω����y�ڂ�����)
					begin
						sl.Clear;
						if (tc.PartyName = '') then begin
							sl.AddObject(IntToStr(tc.ID),tc);
						end else begin
							tpa := PartyNameList.Objects[PartyNameList.IndexOf(tc.PartyName)] as TParty;
							for k := 0 to 11 do begin
								if(tpa.MemberID[k] = 0) then break;
								if tpa.Member[k].Login <> 2 then Continue;
								if tc.Map <> tpa.Member[k].Map then Continue;
								if (abs(tc.Point.X - tpa.Member[k].Point.X) < 16) and
								(abs(tc.Point.Y - tpa.Member[k].Point.Y) < 16) then
									sl.AddObject(IntToStr(tpa.MemberID[k]),tpa.Member[k]);
							end;
						end;
						if sl.Count <> 0 then begin
							for k := 0 to sl.Count -1 do begin
								tc1 := sl.Objects[k] as TChara;
								//�p�P���M
								WFIFOW( 0, $011a);
								WFIFOW( 2, tc.MSkill);
								WFIFOW( 4, tc.MUseLV);
								WFIFOL( 6, tc1.ID);
								WFIFOL(10, tc1.ID);
								WFIFOB(14, 1);
								SendBCmd(tm, tc1.Point, 15);
								DebugOut.Lines.Add(Format('ID %d casts %d to ID %d', [tc.ID,tc.MSkill,tc1.ID]));
								tc1.Skill[tc.MSkill].Tick := Tick + cardinal(tl.Data1[tc.MUseLV]) * 1000;
								tc1.Skill[tc.MSkill].EffectLV := tc.MUseLV;
								tc1.Skill[tc.MSkill].Effect1 := tl.Data2[tc.MUseLV];
								if tc1.SkillTick > tc1.Skill[tc.MSkill].Tick then begin
									tc1.SkillTick := tc1.Skill[tc.MSkill].Tick;
									tc1.SkillTickID := tc.MSkill;
								end;
								CalcStat(tc1, Tick);
								if ProcessType = 5 then SendCStat(tc1);
								//�A�C�R���\��
								if (tl.Icon <> 0) then begin
									WFIFOW(0, $0196);
									WFIFOW(2, tl.Icon);
									WFIFOL(4, tc1.ID);
									WFIFOB(8, 1);
									tc1.Socket.SendBuf(buf, 9);
								end;
							end;
						end;
					end;
			end;
{�p�[�e�B�[�@�\�ǉ��R�R�܂�}
		end;
	end;
	sl.Free;
end;

{�ǉ������܂�}
//------------------------------------------------------------------------------
//�񕜃X�L����
procedure TfrmMain.CharaPassive(tc:TChara;Tick:cardinal);
var
	j :Integer;
begin
	with tc do begin
		//HPSP�񕜏���
		if Weight * 2 < MaxWeight then begin
			//HP������
			if HPTick + HPDelay[3 - Sit] <= Tick then begin
				if HP <> MAXHP then begin
					for j := 1 to (Tick - HPTick) div HPDelay[3 - Sit] do begin
						Inc(HP);
						HPTick := HPTick + HPDelay[3 - Sit];
					end;
					if HP > MAXHP then HP := MAXHP;
					WFIFOW( 0, $00b0);
					WFIFOW( 2, $0005);
					WFIFOL( 4, HP);
					Socket.SendBuf(buf, 8);
				end else begin
					HPTick := Tick;
				end;
			end;
			//SP������
			if SPTick + SPDelay[3 - Sit] <= Tick then begin
				if SP <> MAXSP then begin
					for j := 1 to (Tick - SPTick) div SPDelay[3 - Sit] do begin
						Inc(SP);
						SPTick := SPTick + SPDelay[3 - Sit];
					end;
					if SP > MAXSP then SP := MAXSP;
						WFIFOW( 0, $00b0);
						WFIFOW( 2, $0007);
						WFIFOL( 4, SP);
						Socket.SendBuf(buf, 8);
					end else begin
						SPTick := Tick;
				end;
			end;
			if Sit >= 2 then begin
				//HP�񕜃X�L��
				if (Skill[4].Lv <> 0) and (HPRTick + 10000 <= Tick) then begin
					if HP <> MAXHP then begin
						j := (5 + MAXHP div 500) * Skill[4].Lv;
						if HP + j > MAXHP then j := MAXHP - HP;
						HP := HP + j;
						WFIFOW( 0, $013d);
						WFIFOW( 2, $0005);
						WFIFOW( 4, j);
						Socket.SendBuf(buf, 6);
						WFIFOW( 0, $00b0);
						WFIFOW( 2, $0005);
						WFIFOL( 4, HP);
						Socket.SendBuf(buf, 8);
					end;
					HPRTick := Tick;
				end;
				//SP�񕜃X�L��
				if (Skill[9].Lv <> 0) and (SPRTick + 10000 <= Tick) then begin
					if SP <> MAXSP then begin
{�Z�p229}   j := (3 + MAXSP * 2 div 1000) * Skill[9].Lv;
						if SP + j > MAXSP then j := MAXSP - SP;
						SP := SP + j;
						WFIFOW( 0, $013d);
						WFIFOW( 2, $0007);
						WFIFOW( 4, j);
						Socket.SendBuf(buf, 6);
						WFIFOW( 0, $00b0);
						WFIFOW( 2, $0007);
						WFIFOL( 4, SP);
						Socket.SendBuf(buf, 8);
					end;
					SPRTick := Tick;
				end;
			{ �Ђ���Ƃ����炱�̏������邩��
			end else begin
				HPTick := Tick;
				SPTick := Tick;
			}
			end;
		end else begin
			HPTick := Tick;
			SPTick := Tick;
		end;
	end;
end;
//------------------------------------------------------------------------------
function TfrmMain.NPCAction(tm:TMap;tn:TNPC;Tick:cardinal) : Integer;
var
	k,m,c: Integer;
	i,j:Integer;
	i1,j1,k1:integer;
	i2,j2,k2:integer;
	tc1:TChara;
	ts1:TMob;
	tl	:TSkillDB;
	xy:TPoint;
	bb:array of byte;
	sl:TStringList;
	flag:Boolean;
begin
	k := 0;
	if (tn.CType = 3) and (tn.Tick <= Tick) then begin
		//�A�C�e���P��
		WFIFOW(0, $00a1);
		WFIFOL(2, tn.ID);
		SendBCmd(tm, tn.Point, 6);
		//�A�C�e���폜
		tm.NPC.Delete(tm.NPC.IndexOf(tn.ID));
		with tm.Block[tn.Point.X div 8][tn.Point.Y div 8].NPC do
			Delete(IndexOf(tn.ID));
			tn.Free;
	end else if (tn.CType = 4) then begin //�X�L�����\�n
		if tn.Tick <= Tick then begin
			case tn.JID of
				$81://�|�[�^�������O->������
					begin
						tn.JID := $80;
						WFIFOW(0, $00c3);
						WFIFOL(2, tn.ID);
						WFIFOB(6, 0);
						WFIFOB(7, tn.JID);
						SendBCmd(tm, tn.Point, 8);
						tn.Tick := Tick + 20000;
					end;
				$8F://�u���X�g�����O
					begin
						tn.JID := $74;
						WFIFOW(0, $00c3);
						WFIFOL(2, tn.ID);
						WFIFOB(6, 0);
						WFIFOB(7, tn.JID);
						SendBCmd(tm, tn.Point, 8);
						tn.Tick := Tick + 2000;
					end;
				else
					begin
						//�X�L�����\�n�P��
						DelSkillUnit(tm, tn);
						Dec(k);
					end;
			end;
		end else begin
			//�X�L�����\�n���� Chara���݌^
			c := 0;
			while (c >= 0) and (c < tm.Block[tn.Point.X div 8][tn.Point.Y div 8].CList.Count) do begin
				tc1 := tm.Block[tn.Point.X div 8][tn.Point.Y div 8].CList.Objects[c] as TChara;
				Inc(c);
				if tc1 = nil then continue;
				if (tc1.pcnt = 0) and (tc1.Point.X = tn.Point.X) and (tc1.Point.Y = tn.Point.Y) then begin
					case tn.JID of
						$80: //�|�[�^��������
							begin
{�`���b�g���[���@�\�ǉ�}
								if (tc1.ChatRoomID <> 0) then continue;
{�`���b�g���[���@�\�ǉ��R�R�܂�}
								SendCLeave(tc1, 0);
								tc1.tmpMap := tn.WarpMap;
								tc1.Point := tn.WarpPoint;
								MapMove(tc1.Socket, tn.WarpMap, tn.WarpPoint);
								Dec(tn.Count);
								if tn.Count = 0 then begin //�����̏��������܂��������ǂ�����
									DelSkillUnit(tm, tn);
									Dec(k);
									c := -1;
									continue;
								end else begin
									Dec(c);
								end;
							end;
					end;
				end;
			end;

			tc1 := tn.CData;
			tl := SkillDB.IndexOfObject(tn.MSkill) as TSkillDB;
			if tl <> nil then begin
				m := tl.Range2;
			end else begin
				m := 0;
			end;
			//�ꏊ�w��X�L�� �͈͌^
		  flag := False;
			sl := TStringList.Create;
			for j1 := (tn.Point.Y - m) div 8 to (tn.Point.Y + m) div 8 do begin
				for i1 := (tn.Point.X - m) div 8 to (tn.Point.X + m) div 8 do begin
					for c := 0 to tm.Block[i1][j1].Mob.Count -1 do begin
						ts1 := tm.Block[i1][j1].Mob.Objects[c] as TMob;
						if ts1 = nil then Continue;
						if (abs(ts1.Point.X - tn.Point.X) <= m) and (abs(ts1.Point.Y - tn.Point.Y) <= m) then
							sl.AddObject(IntToStr(ts1.ID),ts1);
						if (ts1.Point.X = tn.Point.X) and (ts1.Point.Y = tn.Point.Y) then
							flag := True;
					end;
				end;
			end;
			if sl.Count <> 0 then begin
				for c := 0 to sl.Count -1 do begin
					ts1 := sl.Objects[c] as TMob;
					case tn.JID of
{:119}
						$74://�u���X�g�}�C������
							begin
								dmg[0] := (tc1.Param[4] + 75) * (100 + tc1.Param[3]) div 100;
								dmg[0] := dmg[0] * tn.Count;
								dmg[0] := dmg[0] * ElementTable[tl.Element][ts1.Element] div 100;
								if dmg[0] < 0 then dmg[0] := 0; //���@�U���ł̉񕜂͖�����
								tn.Tick := Tick;
								WFIFOW( 0, $0114);
								WFIFOW( 2, $74);
								WFIFOL( 4, tn.ID);
								WFIFOL( 8, ts1.ID);
								WFIFOL(12, Tick);
								WFIFOL(16, tc1.aMotion);
								WFIFOL(20, ts1.Data.dMotion);
								WFIFOW(24, dmg[0]);
								WFIFOW(26, tn.Count);
								WFIFOW(28, 1);
								WFIFOB(30, 5);
								SendBCmd(tm, tn.Point, 31);
								DamageProcess1(tm, tc1, ts1, dmg[0], tick);
							end;
{:119}
						$7f: //�t�@�C�A�[�E�H�[��
							begin
								//�_���[�W�Z�o
								dmg[0] := tn.CData.MATK1 + Random(tn.CData.MATK2 - tn.CData.MATK1 + 1) * tn.CData.MATKFix div 100 * tn.CData.Skill[18].Data.Data1[tn.MUseLV] div 100;
								//dmg[0] := tn.MATK1 + Random(tn.MATK2 - tn.MATK1 + 1);
								dmg[0] := dmg[0] * (100 - ts1.Data.MDEF) div 100; //MDEF%
								dmg[0] := dmg[0] - ts1.Data.Param[3]; //MDEF-
								if dmg[0] < 1 then dmg[0] := 1;
								dmg[0] := dmg[0] * ElementTable[tn.CData.Skill[18].Data.Element][ts1.Element] div 100;
								if dmg[0] < 0 then dmg[0] := 0; //���@�U���ł̉񕜂͖�����
								//�_���[�W�p�P���M
								WFIFOW( 0, $0114);
								WFIFOW( 2, 18);
								WFIFOL( 4, tn.ID);
								WFIFOL( 8, ts1.ID);
								WFIFOL(12, Tick);
								WFIFOL(16, 0);
								WFIFOL(20, ts1.Data.dMotion);
								WFIFOW(24, dmg[0]);
								WFIFOW(26, 1);
								WFIFOW(28, 1);
								WFIFOB(30, 4);
								SendBCmd(tm, tn.Point, 31);
								//�m�b�N�o�b�N����
								if (dmg[0] > 0) and (ts1.Data.Race <> 1) then begin
									SetLength(bb, 2);
									bb[0] := 4;
									bb[1] := 4;
									xy := ts1.Point;
									DirMove(tm, ts1.Point, ts1.Dir, bb);
									//�u���b�N�ړ�
									if (xy.X div 8 <> ts1.Point.X div 8) or (xy.Y div 8 <> ts1.Point.Y div 8) then begin
										with tm.Block[xy.X div 8][xy.Y div 8].Mob do begin
											assert(IndexOf(ts1.ID) <> -1, 'MobBlockDelete Error');
											Delete(IndexOf(ts1.ID));
										end;
										tm.Block[ts1.Point.X div 8][ts1.Point.Y div 8].Mob.AddObject(ts1.ID, ts1);
									end;
									ts1.pcnt := 0;
									//�p�P���M
									WFIFOW(0, $0088);
									WFIFOL(2, ts1.ID);
									WFIFOW(6, ts1.Point.X);
									WFIFOW(8, ts1.Point.Y);
									SendBCmd(tm, ts1.Point, 10);
								end;
								DamageProcess1(tm, tn.CData, ts1, dmg[0], Tick);
								Dec(tn.Count);
								if tn.Count = 0 then begin //�����̏��������܂��������ǂ�����
									DelSkillUnit(tm, tn);
									Dec(k);
									Break;
								end;
							end;
{�ǉ�:119}
						$84: //�}�O�k�X
							begin
								if (ts1.Element mod 20 = 9) or ((ts1.Data.Race = 6) and (ts1.Element <> 21)) then begin
									//�_���[�W�Z�o
									dmg[0] := tn.CData.MATK1 + Random(tn.CData.MATK2 - tn.CData.MATK1 + 1) * tn.CData.MATKFix div 100;
									dmg[0] := dmg[0] * (100 - ts1.Data.MDEF) div 100; //MDEF%
									dmg[0] := dmg[0] - ts1.Data.Param[3]; //MDEF-
									if dmg[0] < 1 then dmg[0] := 1;
									dmg[0] := dmg[0] * tn.Count;
									dmg[0] := dmg[0] * ElementTable[tn.CData.Skill[79].Data.Element][29] div 100;
									if dmg[0] < 0 then dmg[0] := 0;
									tn.Tick := Tick;
									//�_���[�W�p�P���M
									WFIFOW( 0, $0114);
									WFIFOW( 2, 79);
									WFIFOL( 4, tn.ID);
									WFIFOL( 8, ts1.ID);
									WFIFOL(12, Tick);
									WFIFOL(16, tc1.aMotion);
									WFIFOL(20, ts1.Data.dMotion);
									WFIFOW(24, dmg[0]);
									WFIFOW(26, tn.Count);
									WFIFOW(28, tl.Data2[tn.Count]);
									WFIFOB(30, 8);
									SendBCmd(tm, tn.Point, 31);
									DamageProcess1(tm, tn.CData, ts1, dmg[0], Tick);
								end;
							end;
{�ǉ�:119�R�R�܂�}
						$86: //LoV
							begin
								if (tn.Tick + 1000 * tn.Count) < (Tick + 3000) then begin
									dmg[0] := tc1.MATK1 + Random(tc1.MATK2 - tc1.MATK1 + 1) * tc1.MATKFix div 100 * tl.Data1[tn.MUseLV] div 100;
									dmg[0] := dmg[0] * (100 - ts1.Data.MDEF) div 100; //MDEF%
									dmg[0] := dmg[0] - ts1.Data.Param[3]; //MDEF-
									if dmg[0] < 1 then dmg[0] := 1;
									dmg[0] := dmg[0] * ElementTable[tl.Element][ts1.Element] div 100;
									dmg[0] := dmg[0] * tl.Data2[tn.MUseLV];
									if dmg[0] < 0 then dmg[0] := 0; //���@�U���ł̉񕜂͖�����
									WFIFOW( 0, $0114);
									WFIFOW( 2, 85);
									WFIFOL( 4, tn.ID);
									WFIFOL( 8, ts1.ID);
									WFIFOL(12, Tick);
									WFIFOL(16, tc1.aMotion);
									WFIFOL(20, ts1.Data.dMotion);
									WFIFOW(24, dmg[0]);
									WFIFOW(26, tn.MUseLV);
									WFIFOW(28, tl.Data2[tn.MUseLV]);
									WFIFOB(30, 8);
									SendBCmd(tm, tn.Point, 31);
									DamageProcess1(tm,tc1,ts1,dmg[0],tick);
									if c = (sl.Count -1) then begin
										Inc(tn.Count);	//Count�𔭓�������SkillLV�Ɏg�p
										if tn.Count = 3 then tn.Tick := Tick
									end;
								end;
							end;
						$87: //FP
							begin
								//debugout.Lines.Add('Hit') ;
								if not flag then Break; //����łȂ�
								tn.Tick := Tick;
								dmg[0] := (tc1.MATK1 + Random(tc1.MATK2 - tc1.MATK1 + 1)) * tc1.MATKFix div 500 + 50;
								if dmg[0] < 51 then dmg[0] := 51;
								dmg[0] := dmg[0] * tl.Data2[tn.Count];
								dmg[0] := dmg[0] * ElementTable[tl.Element][ts1.Element] div 100;
								if dmg[0] < 0 then dmg[0] := 0; //���@�U���ł̉񕜂͖�����
								//�������G�t�F�N�g���o���Ă݂�
								SetSkillUnit(tm,tc1.ID,tn.Point,Tick,$88,0,4000);

								WFIFOW( 0, $0114);
								WFIFOW( 2, tn.JID);
								WFIFOL( 4, tn.ID);
								WFIFOL( 8, ts1.ID);
								WFIFOL(12, Tick);
								WFIFOL(16, tc1.aMotion);
								WFIFOL(20, ts1.Data.dMotion);
								WFIFOW(24, dmg[0]);
								WFIFOW(26, tn.Count);
								WFIFOW(28, tl.Data2[tn.Count]);
								WFIFOB(30, 8);
								SendBCmd(tm, tn.Point, 31);
								DamageProcess1(tm,tc1,ts1,dmg[0],Tick);
							end;
{:119}
						$8d: //�A�C�X�E�H�[��
							begin
								//�m�b�N�o�b�N����
								SetLength(bb, 2);
								bb[0] := 4;
								bb[1] := 4;
								xy := ts1.Point;
								DirMove(tm, ts1.Point, ts1.Dir, bb);
								//�u���b�N�ړ�
								if (xy.X div 8 <> ts1.Point.X div 8) or (xy.Y div 8 <> ts1.Point.Y div 8) then begin
									with tm.Block[xy.X div 8][xy.Y div 8].Mob do begin
										assert(IndexOf(ts1.ID) <> -1, 'MobBlockDelete Error');
										Delete(IndexOf(ts1.ID));
									end;
									tm.Block[ts1.Point.X div 8][ts1.Point.Y div 8].Mob.AddObject(ts1.ID, ts1);
								end;
								ts1.pcnt := 0;
								//�p�P���M
								WFIFOW(0, $0088);
								WFIFOL(2, ts1.ID);
								WFIFOW(6, ts1.Point.X);
								WFIFOW(8, ts1.Point.Y);
								SendBCmd(tm, ts1.Point, 10);
							end;
{:119}
						$91: //AS
							begin
								if tn.Count <> 0 then begin
									tn.Tick := Tick + tn.Count * 1000;
									ts1.DmgTick := Tick + tn.Count * 1000;
									ts1.Point.X := tn.Point.X;
									ts1.Point.Y := tn.Point.Y;
									ts1.pcnt := 0;
									WFIFOW(0, $0088);
									WFIFOL(2, ts1.ID);
									WFIFOW(6, ts1.Point.X);
									WFIFOW(8, ts1.Point.Y);
									SendBCmd(tm, ts1.Point, 10);
									if c = (sl.Count -1) then tn.Count := 0;
								end;
							end;
						$93: //LM
							begin
								if not flag then Break; //����łȂ�
								dmg[0] := (tc1.Param[4] + 75) * (100 + tc1.Param[3]) div 100;
								dmg[0] := dmg[0] * tn.Count;
								dmg[0] := dmg[0] * ElementTable[tl.Element][ts1.Element] div 100;
								if dmg[0] < 0 then dmg[0] := 0; //���@�U���ł̉񕜂͖�����
								tn.Tick := Tick;
								WFIFOW( 0, $0114);
								WFIFOW( 2, 116);
								WFIFOL( 4, tn.ID);
								WFIFOL( 8, ts1.ID);
								WFIFOL(12, Tick);
								WFIFOL(16, tc1.aMotion);
								WFIFOL(20, ts1.Data.dMotion);
								WFIFOW(24, dmg[0]);
								WFIFOW(26, tn.Count);
								WFIFOW(28, 1);
								WFIFOB(30, 5);
								SendBCmd(tm, tn.Point, 31);
								DamageProcess1(tm, tc1, ts1, dmg[0], tick);
							end;
{:119}
						$95: //SM
							begin
								if not flag then Break; //����łȂ�
								if Random(1000) < tn.CData.Skill[121].Data.Data2[tn.Count] * 10 then begin
									if (ts1.Stat1 <> 4) then begin
										ts1.nStat := 4;
										ts1.BodyTick := Tick + tc1.aMotion;
									end;
								end;
								tn.Tick := Tick;
								WFIFOW( 0, $0114);
								WFIFOW( 2, 15);
								WFIFOL( 4, tn.ID);
								WFIFOL( 8, ts1.ID);
								WFIFOL(12, Tick);
								WFIFOL(16, tc1.aMotion);
								WFIFOL(20, ts1.Data.dMotion);
								WFIFOW(24, 0);
								WFIFOW(26, tn.Count);
								WFIFOW(28, 1);
								WFIFOB(30, 5);
								SendBCmd(tm, tn.Point, 31);
							end;
						$96: //�t���b�V���[
							begin
								if not flag then Break; //����łȂ�
								if Random(1000) < tn.CData.Skill[121].Data.Data2[tn.Count] * 10 then begin
									if Boolean((1 shl 4) and ts1.Stat2) then begin
										ts1.HealthTick[4] := ts1.HealthTick[4] + 30000; //����
									end else begin
										ts1.HealthTick[4] := Tick + tc1.aMotion;
									end;
								end;
								tn.Tick := Tick;
								WFIFOW( 0, $0114);
								WFIFOW( 2, 120);
								WFIFOL( 4, tn.ID);
								WFIFOL( 8, ts1.ID);
								WFIFOL(12, Tick);
								WFIFOL(16, tc1.aMotion);
								WFIFOL(20, ts1.Data.dMotion);
								WFIFOW(24, 0);
								WFIFOW(26, tn.Count);
								WFIFOW(28, 1);
								WFIFOB(30, 5);
								SendBCmd(tm, tn.Point, 31);
							end;
						$97: //FT
							begin
								if not flag then Break; //����łȂ�
								if Random(1000) < tn.CData.Skill[121].Data.Data2[tn.Count] * 10 then begin
									if (ts1.Stat1 <> 2) then begin
										ts1.nStat := 2;
										ts1.BodyTick := Tick + tc1.aMotion;
									end;
								end;
								tn.Tick := Tick;
								WFIFOW( 0, $0114);
								WFIFOW( 2, $79);
								WFIFOL( 4, tn.ID);
								WFIFOL( 8, ts1.ID);
								WFIFOL(12, Tick);
								WFIFOL(16, tc1.aMotion);
								WFIFOL(20, ts1.Data.dMotion);
								WFIFOW(24, 0);
								WFIFOW(26, tn.Count);
								WFIFOW(28, 1);
								WFIFOB(30, 5);
								SendBCmd(tm, tn.Point, 31);
							end;
						$98: //CT
							begin
								if not flag then Break; //����łȂ�
								dmg[0] := (tc1.Param[4] + 75) * (100 + tc1.Param[3]) div 100;
								dmg[0] := dmg[0] * tn.Count;
								dmg[0] := dmg[0] * ElementTable[tl.Element][ts1.Element] div 100;
								if dmg[0] < 0 then dmg[0] := 0; //���@�U���ł̉񕜂͖�����
								tn.Tick := Tick;
								WFIFOW( 0, $0114);
								WFIFOW( 2, 123);
								WFIFOL( 4, tn.ID);
								WFIFOL( 8, ts1.ID);
								WFIFOL(12, Tick);
								WFIFOL(16, tc1.aMotion);
								WFIFOL(20, ts1.Data.dMotion);
								WFIFOW(24, dmg[0]);
								WFIFOW(26, tn.Count);
								WFIFOW(28, 1);
								WFIFOB(30, 5);
								SendBCmd(tm, tn.Point, 31);
								DamageProcess1(tm, tc1, ts1, dmg[0], tick);
							end;
{:119}
					end; //case
				end;
			end;
		end;
	end;
	Result := k;
end;
//------------------------------------------------------------------------------










//------------------------------------------------------------------------------
procedure TfrmMain.MobAI(tm:TMap; ts:TMob; Tick:Cardinal);
var
	j,i1,j1,k1:integer;
	tc1:TChara;
	ts2:TMob;
	tn:TNPC;
	sl:TStringList;
begin
	sl := TStringList.Create;
	with ts do begin
		//��ԂP�ł͈ړ��U���s��
		if (ts.Stat1 <> 0) and (Data.Range1 > 0) then begin
			pcnt := 0;
			Exit;
		end;
		if (ATarget = 0) then begin
			//if Data.isActive then begin  �������������Ȃ��悤�ɕύX
			if isActive then begin
			//�A�N�e�B�u�����X�^�[
				sl.Clear;
				for j1 := Point.Y div 8 - 3 to Point.Y div 8 + 3 do begin
					for i1 := Point.X div 8 - 3 to Point.X div 8 + 3 do begin
						for k1 := 0 to tm.Block[i1][j1].CList.Count - 1 do begin
							tc1 := tm.Block[i1][j1].CList.Objects[k1] as TChara;
							if (tc1.HP > 0) and (abs(ts.Point.X - tc1.Point.X) <= 10) and (abs(ts.Point.Y - tc1.Point.Y) <= 10) then begin
                                                                {�o�O�� 646 ���ɑ��Ȃ�}
                                                                if tc1.Sit = 1 then Continue;
                                                                {�o�O�� 646 ���ɑ��Ȃ�}
								//�^�[�Q�b�g���ɒǉ�
								sl.AddObject(IntToStr(tc1.ID), tc1);
							end;
						end;
					end;
				end;
				if sl.Count <> 0 then begin
					//���E���̒N���Ƀ^�[�Q�b�g���߂�
					j := Random(sl.Count);
					ATarget := StrToInt(sl.Strings[j]);
					ARangeFlag := false;
					AData := sl.Objects[j];
					ATick := Tick;
					ARangeFlag := false;
					Exit;
				end;
			end;
			if (not isLooting) and Data.isLoot then begin
				//���[�g�����X
				sl.Clear;

				//�A�C�e���T��
				for j1 := Point.Y div 8 - 3 to Point.Y div 8 + 3 do begin
					for i1 := Point.X div 8 - 3 to Point.X div 8 + 3 do begin
						for k1 := 0 to tm.Block[i1][j1].NPC.Count - 1 do begin
							tn := tm.Block[i1][j1].NPC.Objects[k1] as TNPC;
							if tn.CType <> 3 then Continue;
							if (abs(tn.Point.X - Point.X) <= 10) and (abs(tn.Point.Y - Point.Y) <= 10) then begin
								//���ɒǉ�
								sl.AddObject(IntToStr(tn.ID), tn);
							end;
						end;
					end;
				end;
				if sl.Count <> 0 then begin
					j := Random(sl.Count);
					tn := sl.Objects[j] as TNPC;
					j := SearchPath2(path, tm, Point.X, Point.Y, tn.Point.X, tn.Point.Y);
					if j <> 0 then begin
						isLooting := True;
						ATarget := tn.ID;
						ATick := Tick;

						pcnt := j;
						ppos := 0;
						MoveTick := Tick;
						tgtPoint := tn.Point;
						WFIFOW(0, $0088);
						WFIFOL(2, ts.ID);
						WFIFOW(6, ts.Point.X);
						WFIFOW(8, ts.Point.Y);
						SendBCmd(tm, ts.Point, 10);

						ZeroMemory(@buf[0], 60);
						WFIFOW( 0, $007b);
						WFIFOL( 2, ID);
						WFIFOW( 6, Speed);
						WFIFOW( 8, Stat1);
						WFIFOW(10, Stat2);
						WFIFOW(14, JID);
						WFIFOL(22, Tick);
						WFIFOW(36, Dir);
						WFIFOM2(50, tgtPoint, Point);
						WFIFOB(56, 5);
						WFIFOB(57, 5);
						SendBCmd(tm,ts.Point,58,nil,True);
					end;
					Exit;
				end;
			end;
		end else begin
			//�����N�����X�^�[
			if Data.isLink and (not isLooting) then begin
				for j1 := Point.Y div 8 - 3 to Point.Y div 8 + 3 do begin
					for i1 := Point.X div 8 - 3 to Point.X div 8 + 3 do begin
						for k1 := 0 to tm.Block[i1][j1].Mob.Count - 1 do begin
							ts2 := tm.Block[i1][j1].Mob.Objects[k1] as TMob;
{�C��}				if (ts2 = nil) or (ts2 = ts) then Continue;
							if ts2.JID <> ts.JID then continue;
							if (abs(ts.Point.X - ts2.Point.X) <= 10) and (abs(ts.Point.Y - ts2.Point.Y) <= 10) then begin
								if ts2.ATarget = 0 then begin
									ts2.ATarget := ts.ATarget;
									ts2.ARangeFlag := false;
									ts2.AData := ts.AData;
									ts2.ATick := Tick;
									ts2.ARangeFlag := false;
								end;
							end;
						end;
					end;
				end;
			end;
		end;
{�ǉ��R�R�܂�}
	sl.Free;
	end;
end;
//------------------------------------------------------------------------------
procedure TfrmMain.MobMoveL(tm:TMap; Tick:Cardinal);
var
	i,j,a,c:integer;
	xy:TPoint;
	ts:TMob;
begin
	//�ړ�����
	for j := 0 to tm.BlockSize.Y - 1 do begin
		for i := 0 to tm.BlockSize.X - 1 do begin
			//if not Block[i][j].MobProcess then begin
			if tm.Block[i][j].MobProcTick < Tick then begin
				//for a := 0 to Block[i][j].Mob.Count - 1 do begin
				a := 0;
				while (a >= 0) and (a < tm.Block[i][j].Mob.Count) do begin
					ts := tm.Block[i][j].Mob.Objects[a] as TMob;
					with ts do begin
{�C��}			if (Data.isDontMove) or (HP = 0) or (ts.Stat1 <> 0) then begin
							Inc(a);
							continue;
						end;
						ATarget := 0; //030317 �U���Ώۂ����΂ɂ��Ȃ��̂ŉ���(���ʂ�if�g��Ȃ���������������)
						ARangeFlag := false;
						if pcnt <> 0 then begin
							//�O�̈ړ��������c���Ă���Ƃ�
							//�u���b�N�ړ�
							if (tgtPoint.X div 8 <> Point.X div 8) or (tgtPoint.Y div 8 <> Point.Y div 8) then begin
								c := tm.Block[Point.X div 8][Point.Y div 8].Mob.IndexOf(ID);
								Assert(c <> -1, Format('MobBlockDelete3 %d (%d,%d)',[c,Point.X,Point.Y]));
								tm.Block[Point.X div 8][Point.Y div 8].Mob.Delete(c);
								//�V�����u���b�N�Ƀf�[�^�ǉ�
								tm.Block[tgtPoint.X div 8][tgtPoint.Y div 8].Mob.AddObject(ID, ts);
							end;
							Point := tgtPoint;
							pcnt := 0;
							MoveWait := Tick + 5000 + Cardinal(Random(5000));
						end else begin
							//�ړ����ĂȂ��Ƃ�
							if MoveWait < Tick then begin
								//�ړ��J�n
								//AMode := 0;
								c := 0;
								repeat
									//repeat
										xy.X := Random(17) - 8; //�ړ��͈͍͂ő�8�}�X
										xy.Y := Random(17) - 8; //��(2�u���b�N�ȏ�ړ����Ȃ��悤��)
										//until (abs(xy.X) > 2) and (abs(xy.Y) > 2);
										xy.X := xy.X + Point.X;
										xy.Y := xy.Y + Point.Y;
										//030316-2 ����������/030317
										if (xy.X < 0) or (xy.X > tm.Size.X - 2) or (xy.Y < 0) or (xy.Y > tm.Size.Y - 2) then begin
											//DebugOut.Lines.Add(Format('***RandomRoute Error!! (%d,%d) %dx%d', [xy.X,xy.Y,tm.Size.X,tm.Size.Y]));
											if xy.X < 0 then xy.X := 0;
											if xy.X > tm.Size.X - 2 then xy.X := tm.Size.X - 2;
											if xy.Y < 0 then xy.Y := 0;
											if xy.Y > tm.Size.Y - 2 then xy.Y := tm.Size.Y - 2;
										end;
										//---
										Inc(c);
									until ((tm.gat[xy.X][xy.Y] and 1) <> 0) or (c = 100);
									if c <> 100 then begin
										//�u���b�N�ړ�
										if (xy.X div 8 <> Point.X div 8) or (xy.Y div 8 <> Point.Y div 8) then begin
											//�ȑO�̃u���b�N�̃f�[�^����
											//with tm.Block[xy.X div 8][xy.Y div 8].Mob do begin
											//	Delete(IndexOf(IntToStr(ID)));
											//end;
											c := tm.Block[Point.X div 8][Point.Y div 8].Mob.IndexOf(ID);
											//DebugOut.Lines.Add('MobBlockDelete2 ' + Inttostr(c));
											if c <> -1 then begin
												tm.Block[Point.X div 8][Point.Y div 8].Mob.Delete(c);
												Dec(a);
											end else begin
												DebugOut.Lines.Add(Format('MobBlockDelete2 %d (%d,%d)',[c,Point.X,Point.Y]));
										end;
										//�V�����u���b�N�Ƀf�[�^�ǉ�
										tm.Block[xy.X div 8][xy.Y div 8].Mob.AddObject(ID, ts);
									end;
									Point.X := xy.X;
									Point.Y := xy.Y;
								end;
								MoveWait := Tick + 5000 + Cardinal(Random(5000));
							end;
						end;
					end;
					Inc(a);
				end;
				//tm.Block[a][b].MobProcess := true;
				//tm.Block[i][j].MobProcTick := Tick;
			end;
		end;
	end;
end;
//------------------------------------------------------------------------------
function TfrmMain.MobMoving(tm:TMap; ts:TMob; Tick:Cardinal) : Integer;
var
	i,j,k,m,n,c:integer;
	tc1:TChara;
	tn:TNPC;
	spd:cardinal;
	xy:TPoint;
	dx,dy:integer;
begin
	k := 0;
	with ts do begin
		if (path[ppos] and 1) = 0 then begin
			spd := Speed;
		end else begin
			spd := Speed * 140 div 100; //�΂߂�1.4�{���Ԃ�������
		end;
		for j := 1 to (Tick - MoveTick) div spd do begin
			xy := Point;
			Dir := path[ppos];
			case Dir of
				0: begin               Inc(Point.Y); dx :=  0; dy :=  1; end;
				1: begin Dec(Point.X); Inc(Point.Y); dx := -1; dy :=  1; end;
				2: begin Dec(Point.X);               dx := -1; dy :=  0; end;
				3: begin Dec(Point.X); Dec(Point.Y); dx := -1; dy := -1; end;
				4: begin               Dec(Point.Y); dx :=  0; dy := -1; end;
				5: begin Inc(Point.X); Dec(Point.Y); dx :=  1; dy := -1; end;
				6: begin Inc(Point.X);               dx :=  1; dy :=  0; end;
				7: begin Inc(Point.X); Inc(Point.Y); dx :=  1; dy :=  1; end;
				else
					begin              {HeadDir := 0;} dx :=  0; dy :=  0; end; //�{���͋N����͂����Ȃ�
			end;
			Inc(ppos);
			//DebugOut.Lines.Add(Format('	 Mob-Move %d/%d (%d,%d) %d %d %d', [ppos, pcnt, Point.X, Point.Y, path[ppos-1], spd, Tick]));
			if (tm.gat[Point.X][Point.Y] and 1) = 0 then begin
				//�ǂ߂肱��
				DebugOut.Lines.Add(Format('***Mob Move ERROR %d/%d (%d,%d) %d %d %d', [ppos, pcnt, Point.X, Point.Y, path[ppos-1], spd, Tick]));
			end;
			//�u���b�N����
			for n := xy.Y div 8 - 2 to xy.Y div 8 + 2 do begin
				for m := xy.X div 8 - 2 to xy.X div 8 + 2 do begin

					//�v���C���[�ɒʒm
					for c := 0 to tm.Block[m][n].CList.Count - 1 do begin
						tc1 := tm.Block[m][n].CList.Objects[c] as TChara;
						if tc1 = nil then continue;
						if ((dx <> 0) and (abs(xy.Y - tc1.Point.Y) < 16) and (xy.X = tc1.Point.X + dx * 15)) or
						 ((dy <> 0) and (abs(xy.X - tc1.Point.X) < 16) and (xy.Y = tc1.Point.Y + dy * 15)) then begin
							//���Œʒm
							WFIFOW(0, $0080);
							WFIFOL(2, ts.ID);
							WFIFOB(6, 0);
							tc1.Socket.SendBuf(buf, 7);
						end;
						if ((dx <> 0) and (abs(Point.Y - tc1.Point.Y) < 16) and (Point.X = tc1.Point.X - dx * 15)) or
						((dy <> 0) and (abs(Point.X - tc1.Point.X) < 16) and (Point.Y = tc1.Point.Y - dy * 15)) then begin
							//�o���ʒm
							SendMData(tc1.Socket, ts);
							//�ړ��ʒm
							if (abs(Point.X - tc1.Point.X) < 16) and (abs(Point.Y - tc1.Point.Y) < 16) then begin
{�C��}					SendMMove(tc1.Socket, ts, Point, tgtPoint, tc1.ver2);
							end;
						end;
					end;
				end;
			end;
			//�u���b�N�ړ�
			if (xy.X div 8 <> Point.X div 8) or (xy.Y div 8 <> Point.Y div 8) then begin
				//�ȑO�̃u���b�N�̃f�[�^����
				//with tm.Block[xy.X div 8][xy.Y div 8].Mob do begin
				//	Delete(IndexOf(IntToStr(ID)));
				//end;
				c := tm.Block[xy.X div 8][xy.Y div 8].Mob.IndexOf(ID);
				if c <> -1 then begin
					tm.Block[xy.X div 8][xy.Y div 8].Mob.Delete(c);
					Dec(k);
				end else begin
					DebugOut.Lines.Add(Format('MobBlockDelete %d (%d,%d)',[c,xy.X,xy.Y]));
				end;
				//�V�����u���b�N�Ƀf�[�^�ǉ�
				tm.Block[Point.X div 8][Point.Y div 8].Mob.AddObject(ID, ts);
			end;

			if (ATarget <> 0) then begin
				if isLooting then begin
					tn := tm.NPC.IndexOfObject(ts.ATarget) as TNPC;
					if tn = nil then begin
						WFIFOW( 0, $0088);
						WFIFOL( 2, ts.ID);
						WFIFOW( 6, ts.Point.X);
						WFIFOW( 8, ts.Point.Y);
						SendBCmd(tm, ts.Point, 10);
						isLooting := False;
						ATarget := 0;
						ppos := pcnt;
						MoveWait := Tick + Data.dMotion;
					end else if (abs(ts.Point.X - tn.Point.X) <2) and (abs(ts.Point.Y - tn.Point.Y) <2) then begin
						tgtPoint := Point;
						ppos := pcnt;
						ATick := Tick + Speed;
					end;
				end else begin
					tc1 := AData;
					if (abs(ts.Point.X - tc1.Point.X) > 13) or (abs(ts.Point.Y - tc1.Point.Y) > 13) then begin
						//���E�̂��Ƃ܂œ�����ꂽ
						WFIFOW( 0, $0088);
						WFIFOL( 2, ts.ID);
						WFIFOW( 6, ts.Point.X);
						WFIFOW( 8, ts.Point.Y);
						SendBCmd(tm, ts.Point, 10);
						ATarget := 0;
						ARangeFlag := false;
						MoveWait := Tick + 5000;
					end else if (abs(Point.X - tc1.Point.X) <= Data.Range1) and (abs(Point.Y - tc1.Point.Y) <= Data.Range1) then begin
						//�˒����܂Œǂ�����
						tgtPoint := Point;
						ppos := pcnt;
						ATick := Tick;
					end;
				end;
			end;

			if ppos = pcnt then begin
				//�ړ�����
				pcnt := 0;
				if ATarget = 0 then begin
					MoveWait := Tick + 5000;
				end else begin
					MoveWait := Tick;
				end;
				ATick := Tick - Data.ADelay;
				//�p�P���M(�|�U���ł̈ʒu����΍�)
				WFIFOW(0, $0088);
				WFIFOL(2, ts.ID);
				WFIFOW(6, ts.Point.X);
				WFIFOW(8, ts.Point.Y);
				SendBCmd(tm, ts.Point, 10);
				break;
			end;
			MoveTick := MoveTick + spd;
		end;
	end;
	Result := k;
end;
//------------------------------------------------------------------------------
procedure TfrmMain.MobAttack(tm:TMap;ts:TMob;Tick:cardinal);
var
	j,c:integer;
	tc1:TChara;
	xy:TPoint;
begin
//�������[�h
	with ts do begin
		tc1 := AData;
		if ( (tc1.Sit = 1) or (tc1.Login <> 2) ) and (not isLooting) then begin
		//�U���Ώۂ�����ł��邩���O�A�E�g���Ă���
			ATarget := 0;
			ARangeFlag := false;
		end else if (abs(ts.Point.X - tc1.Point.X) <= ts.Data.Range1) and (abs(ts.Point.Y - tc1.Point.Y) <= ts.Data.Range1) then begin
			if (ATick + Data.ADelay < Tick) then begin
				ATick := Tick - Data.ADelay;
			end;
			if ATick + Data.ADelay <= Tick then begin
			//�ʒu����C��
			WFIFOW(0, $0088);
			WFIFOL(2, ts.ID);
			WFIFOW(6, ts.Point.X);
			WFIFOW(8, ts.Point.Y);
			SendBCmd(tm, ts.Point, 10);
			for j := 1 to (Tick - ATick) div Data.ADelay do begin
				//����
				DamageCalc2(tm, tc1, ts, Tick);
				WFIFOW( 0, $008a);
				WFIFOL( 2, ID);
				WFIFOL( 6, ATarget);
				WFIFOL(10, timeGetTime());
				WFIFOL(14, ts.Data.aMotion);
				WFIFOL(18, tc1.dMotion);
				WFIFOW(22, dmg[0]); //�_���[�W
				WFIFOW(24, dmg[4]); //������
				if tc1.dMotion = 0 then dmg[5] := 4;
				WFIFOB(26, dmg[5]); //0=�P�U�� 8=����
				WFIFOW(27, 0); //�t��
				SendBCmd(tm, tc1.Point, 29);
				if (dmg[0] <> 0) and (tc1.pcnt <> 0) and (tc1.dMotion <> 0) then begin
					//�_���[�W���󂯂�Ɨ����~�܂�
					tc1.Sit := 3;
					tc1.HPTick := Tick;
					tc1.HPRTick := Tick - 500;
					tc1.SPRTick := Tick;
					tc1.pcnt := 0;
{�ǉ�}
					WFIFOW(0, $0088);
					WFIFOL(2, tc1.ID);
					WFIFOW(6, tc1.Point.X);
					WFIFOW(8, tc1.Point.Y);
					SendBCmd(tm, tc1.Point, 10);
{�ǉ��R�R�܂�}
				end;
				if ts.Data.MEXP <> 0 then begin
					for c := 0 to 31 do begin
						if (ts.MVPDist[c].CData = nil) or (ts.MVPDist[c].CData = tc1) then begin
							ts.MVPDist[c].CData := tc1;
							Inc(ts.MVPDist[c].Dmg, dmg[0]);
							break;
						end;
					end;
				end;
				if tc1.HP > dmg[0] then begin
					tc1.HP := tc1.HP - dmg[0];
					if dmg[0] <> 0 then begin
						tc1.DmgTick := Tick + tc1.dMotion div 2;
					end;
				end else begin
					//�L�������S
					tc1.HP := 0;
					WFIFOW( 0, $0080);
					WFIFOL( 2, tc1.ID);
					WFIFOB( 6, 1);
					SendBCmd(tm, tc1.Point, 7);
					tc1.Sit := 1;
					//if tc1.Job = 0 then tc1.HP := tc1.MAXHP div 2 else tc1.HP := 1;
					tc1.pcnt := 0;
					if (tc1.AMode = 1) or (tc1.AMode = 2) then tc1.AMode := 0;
						ATarget := 0;
						ARangeFlag := false;
					end;
					WFIFOW( 0, $00b0);
					WFIFOW( 2, $0005);
					WFIFOL( 4, tc1.HP);
					tc1.Socket.SendBuf(buf, 8);
					ATick := ATick + Data.ADelay;
				end;
			end;
			ARangeFlag := true;
		end else if (abs(ts.Point.X - tc1.Point.X) > 13) or (abs(ts.Point.Y - tc1.Point.Y) > 13) then begin
			//���E�̂��Ƃ܂œ�����ꂽ
			WFIFOW( 0, $0088);
			WFIFOL( 2, ts.ID);
			WFIFOW( 6, ts.Point.X);
			WFIFOW( 8, ts.Point.Y);
			SendBCmd(tm, ts.Point, 10);
			ATarget := 0;
			if Data.isDontMove then
				MoveWait := $FFFFFFFF
			else
				MoveWait := Tick + 5000;
			ATick := Tick - Data.ADelay;
			ARangeFlag := false;
		end else begin //if MoveWait < Tick then begin
			if Data.isDontMove then begin
				ATick := Tick - Data.ADelay;
			end else begin
				ARangeFlag := false;
				if (not EnableMonsterKnockBack) or (DmgTick <= Tick) then begin
					//���E���ɂ���̂Œǂ�������
					pcnt := 0;
					j := 0;
					repeat
						xy.X := tc1.Point.X + Random(3) - 1;
						xy.Y := tc1.Point.Y + Random(3) - 1;
						//if xy.X <= 0 then xy.X := 1;
						//if xy.X >= tm.Size.X - 1 then xy.X := tm.Size.X - 2;
						//if xy.Y <= 0 then xy.Y := 1;
						//if xy.Y >= tm.Size.Y - 1 then xy.Y := tm.Size.Y - 2;
						if (tm.gat[xy.X][xy.Y] and 1) <> 0 then break;
						Inc(j);
					until (j = 100);
					if j = 100 then DebugOut.Lines.Add('*** TraceError 1');
					if j <> 100 then pcnt := SearchPath2(path, tm, Point.X, Point.Y, xy.X, xy.Y);
					if pcnt = 0 then begin
						//�L�����̏��܂ŕ����Ȃ�=�U���s�\�A�^�[�Q�b�g����
						//if j <> 100 then DebugOut.Lines.Add('*** TraceError 2');
						//ATarget := 0;
						MoveWait := Tick + 5000;
					end else begin
						//�L�����̏��܂ňړ��J�n
						ppos := 0;
						MoveTick := Tick;
						tgtPoint := xy;
						//�u���b�N����
						//����̐l�ɒʒm
{�C��}
						SendMMove(tc1.Socket, ts, Point, tgtPoint, tc1.ver2);
						SendBCmd(tm,ts.Point,58,tc1,True);
{�C���R�R�܂�}
					end;
				end;
			end;
		end;
	end;
end;
//------------------------------------------------------------------------------
procedure TfrmMain.StatEffect(tm:TMap; ts:TMob; Tick:Cardinal);
var
	sflag:Boolean;
	j,m,n:Word;
begin
	sflag := False;
	if (ts.Stat1 = 0) or (ts.Stat1 <> ts.nStat) then begin
		if (ts.BodyTick <> 0) and (ts.BodyTick < Tick) then begin
			if ts.Stat1 <> 0 then begin
				//����
				case ts.Stat1 of
					2:
						begin
							ts.Element := ts.Data.Element;
						end;
				end;
			end;
			//�ُ픭��1
			ts.Stat1 := ts.nStat;
			case ts.nStat of
				2:
					begin
						ts.Element := 21;
					end;
			end;
			ts.BodyTick := Tick + 30000; //�K��
			sflag := True;
      ts.pcnt := 0;
		end;
	end else begin
		if ts.BodyTick < Tick then begin
			case ts.Stat1 of
				2:
					begin
						ts.Element := ts.Data.Element;
					end;
			end;
			//����1
			ts.Stat1 := 0;
			ts.nStat := 0;
			ts.BodyTick := 0;
			ZeroMemory(@buf[0], 60);
			WFIFOW( 0, $007b);
			WFIFOL( 2, ts.ID);
			WFIFOW( 6, ts.Speed);
			WFIFOW( 8, ts.Stat1);
			WFIFOW(10, ts.Stat2);
			WFIFOW(14, ts.JID);
			WFIFOL(22, timeGetTime());
			WFIFOW(36, ts.Dir);
			WFIFOM2(50, ts.Point, ts.Point);
			WFIFOB(56, 5);
			WFIFOB(57, 5);
			SendBCmd(tm,ts.Point,58,nil,True);
		end;
	end;
	//��ԕω�2
	m := 0;
	for n:= 0 to 4 do begin
		j := 1 shl n;
		if (ts.Stat2 and j) = 0 then begin
			if (ts.HealthTick[n] <> 0) and (ts.HealthTick[n] < Tick) then begin
				//�ُ픭��2
				ts.Stat2 := ts.Stat2 or j;
				ts.HealthTick[n] := Tick + 30000; //�K��
				sflag := True;
				m := m or j;
			end;
		end else if ts.HealthTick[n] < Tick then begin
			//����
			ts.Stat2 := ts.Stat2 and (not j);
			ts.HealthTick[n] := 0;
			sflag := True;
		end;
	end;
	if sflag then begin
		WFIFOW(0, $0119);
		WFIFOL(2, ts.ID);
		WFIFOW(6, ts.nStat);
		WFIFOW(8, m);
		WFIFOW(10, 0);
		WFIFOB(12, 0);
		SendBCmd(tm, ts.Point, 13);
		WFIFOW(0, $0088);
		WFIFOL(2, ts.ID);
		WFIFOW(6, ts.Point.X);
		WFIFOW(8, ts.Point.Y);
		SendBCmd(tm, ts.Point, 10);
	end;
end;
//------------------------------------------------------------------------------









//------------------------------------------------------------------------------
{�ǉ�}
procedure AutoAction(tc:TChara; Tick:Cardinal);
var
	i1,j1,k1,i,j,k:Integer;
	ts:TMob;
	ts1:TMob;
	tm:TMap;
	tn:TNPC;
	tn1:TNPC;
	tl:TSkillDB;
	sl:TStringList;
	xy:TPoint;
	X,Y,Z:Cardinal;
	label Looting;
begin
	ts := nil;
	tm := tc.MData;
	with tc do begin
		if ((ATarget <> 0) or (MMode <> 0)) then begin
			ts := AData;
			//����ł���,���E�̊O�ɋ���
			if (ts.HP = 0) or (abs(Point.X - ts.Point.X) > 15) or (abs(Point.Y - ts.Point.Y) > 15) then begin
				MMode := 0;
				MTarget := 0;
				MPoint.X := 0;
				MPoint.Y := 0;
				AMode := 0;
				ATarget := 0;
				AData := nil;
			end;
		end;
		if MMode <> 0 then Exit; //�r�����͍s���ł��Ȃ�
		if ((auto and $02) = $02) and (A_Skill <> 0) and (SP > Skill[A_Skill].Data.SP[A_Lv]) then begin
			tl := Skill[A_Skill].Data;
			if tl.SP[A_Lv] > SP then begin
				Sit := 2;
				WFIFOW(0, $008a);
				WFIFOL(2, tc.ID);
				WFIFOB(26, 2);
				SendBCmd(tm, Point, 29);
				Exit;
			end;
			if (MMode = 0) and (MPoint.X = 0) and (MPoint.Y = 0) then begin
				sl := TStringList.Create;
				for j1 := Point.Y div 8 - 3 to Point.Y div 8 + 3 do begin
					for i1 := Point.X div 8 - 3 to Point.X div 8 + 3 do begin
						for k1 := 0 to tm.Block[i1][j1].Mob.Count - 1 do begin
							ts := tm.Block[i1][j1].Mob.Objects[k1] as TMob;
							if ts.HP = 0 then Continue;
							if (abs(ts.Point.X - Point.X) <= 15) and (abs(ts.Point.Y - Point.Y) <= 15) then begin
								//���E���ɂ��Ď���łȂ�
								sl.AddObject(IntToStr(ts.ID), ts);
							end;
						end;
					end;
					end;
				ts := nil;
				if sl.Count <> 0 then begin
					j := 20;
					for i := 0 to sl.Count -1 do begin
						ts1 := sl.Objects[i] as TMob;
						X := abs(ts1.Point.X - Point.X);
						Y := abs(ts1.Point.Y - Point.Y);
						if (X + Y) < Cardinal(j) then begin //��������ԋ߂�
							k := SearchPath2(tc.path, tm, Point.X, Point.Y, ts1.Point.X, ts1.Point.Y);
							//�H�蒅�����˒��O�Ȃ疳��
							if (k = 0) and ((X > tl.Range) or (Y > tl.Range)) then Continue;
							j := X + Y;
							ts := ts1;
						end;
					end;
				end;
				sl.Free;
			end;

			if ts = nil then begin
				//������Ȃ�����
				MMode := 0;
				MTarget := 0;
				MPoint.X := 0;
				MPoint.Y := 0;
			end else begin

				if (abs(Point.X - ts.Point.X) > tl.Range) or (abs(Point.Y - ts.Point.Y) > tl.Range) then begin
					NextFlag := True;
					NextPoint := ts.Point;
				end else begin
					//�U���\
					NextFlag := False;
					Sit := 3;
					pcnt := 0;
					WFIFOW(0, $0088);
					WFIFOL(2, ID);
					WFIFOW(6, Point.X);
					WFIFOW(8, Point.Y);
					SendBCmd(tm, Point, 10);
					MUseLV := A_Lv;
					MSkill := A_Skill;
					k := 0;
					if tl.SType = 1 then begin
						//�^�Q�^
						MMode := 1;
						MTarget := ts.ID;
						AData := ts;
						MPoint.X := 0;
						MPoint.Y := 0;
						k := UseTargetSkill(tc,Tick);
					end else if tl.SType = 2 then begin
						//�ꏊ�^
						MMode := 2;
						MTarget := 0;
						MPoint.X := ts.Point.X;
						MPoint.Y := ts.Point.Y;
						k := UseFieldSkill(tc,Tick);
					end;
					if k <> 0 then begin //�G���[���o����s����~
						SendSkillError(tc,k);
						Auto := Auto xor 2;
					end;
					ActTick := MTick + ADelay; //�X�L���f�B���C�����܂�������Ȃ��̂�
					Exit;
				end;
			end;
		end else if (auto and $01) = $01 then begin

			if (AMode = 0) and (ATarget = 0) then begin
				//�^�Q�T��
				sl := TStringList.Create;
				for j1 := Point.Y div 8 - 3 to Point.Y div 8 + 3 do begin
					for i1 := Point.X div 8 - 3 to Point.X div 8 + 3 do begin
						for k1 := 0 to tm.Block[i1][j1].Mob.Count - 1 do begin
							ts := tm.Block[i1][j1].Mob.Objects[k1] as TMob;
							if ts.HP = 0 then Continue;
							if (abs(ts.Point.X - Point.X) <= 15) and (abs(ts.Point.Y - Point.Y) <= 15) then begin
								//���E���ɂ��Ď���łȂ�
								sl.AddObject(IntToStr(ts.ID), ts);
							end;
						end;
					end;
				end;
				ts := nil;
				if sl.Count <> 0 then begin
					Z := 20;
					for i := 0 to sl.Count -1 do begin
						ts1 := sl.Objects[i] as TMob;
						X := abs(ts1.Point.X - Point.X);
						Y := abs(ts1.Point.Y - Point.Y);
						if (X + Y) < Z then begin //��������ԋ߂�
							k := SearchPath2(tc.path, tm, Point.X, Point.Y, ts1.Point.X, ts1.Point.Y);
							//�H�蒅�����˒��O�Ȃ疳��
							if (k = 0) and ((X > Range) or (Y > Range)) then Continue;
						 	Z := X + Y;
							ts := ts1;
						end;
					end;
				end;
				sl.Free;
			end;

			if ts = nil then begin
				//�^�Q��������Ȃ�����
				AMode := 0;
				ATarget := 0;
			end else begin
				if (abs(Point.X - ts.Point.X) > Range) or (abs(Point.Y - ts.Point.Y) > Range) then begin
					//�˒��O�Ȃ�ǐ�
					NextFlag := True;
					NextPoint := ts.Point;
					ActTick := Tick + Speed div 2;
					if ts.ID <> ATarget then begin
						WFIFOW( 0, $0139);
						WFIFOL( 2, ts.ID);
						WFIFOW( 6, ts.Point.X);
						WFIFOW( 8, ts.Point.Y);
						WFIFOW(10, tc.Point.X);
						WFIFOW(12, tc.Point.Y);
						WFIFOW(14, tc.Range); //�˒�
						Socket.SendBuf(buf, 16);
					end;
				end else begin
					//�U���\
					Sit := 3;
					NextFlag := False;
					AMode := 2;
					if ATarget <> ts.ID then begin
						ATarget := ts.ID;
						AData := ts;
						if ATick + tc.ADelay - 200 < Tick then
							ATick := Tick - ADelay + 200;
					end;
					ActTick := Tick + 200 - ADelay + aMotion;
					Exit;
				end;
			end;
		end;
		if ((Auto and $04) = $04) and (ATarget = 0) and (MMode = 0) then begin //���[�g
				//�A�C�e���T��
				sl := TStringList.Create;
				for j1 := Point.Y div 8 - 3 to Point.Y div 8 + 3 do begin
					for i1 := Point.X div 8 - 3 to Point.X div 8 + 3 do begin
						for k1 := 0 to tm.Block[i1][j1].NPC.Count - 1 do begin
							tn := tm.Block[i1][j1].NPC.Objects[k1] as TNPC;
							if tn.CType <> 3 then Continue;
							if (abs(tn.Point.X - Point.X) <= 15) and (abs(tn.Point.Y - Point.Y) <= 15) then begin
								//���ɒǉ�
								sl.AddObject(IntToStr(tn.ID), tn);
							end;
						end;
					end;
				end;
				tn := nil;
				if sl.Count <> 0 then begin
					//��ԋ߂����̂�
					j := 20;
					for i := 0 to sl.Count -1 do begin
						tn1 := sl.Objects[i] as TNPC;
						X := abs(tn1.Point.X - Point.X);
						Y := abs(tn1.Point.Y - Point.Y);
						if (X + Y) < Cardinal(j) then begin
							k := SearchPath2(tc.path, tm, Point.X, Point.Y, tn1.Point.X, tn1.Point.Y);
							if (k = 0) and ((X > 1) or (Y > 1)) then Continue;
							j := X + Y;
							tn := tn1;
						end;
					end;
				end;
				sl.Free;

			if tn = nil then begin
				//����ɉ�������
			end else begin
				if (abs(Point.X - tn.Point.X) > 1) or (abs(Point.Y - tn.Point.Y) > 1) then begin
				NextFlag := True;
				NextPoint := tn.Point;
				end else begin
					if ATick < Tick then begin
						WFIFOW(0, $0088);
						WFIFOL(2, ID);
						WFIFOW(6, Point.X);
						WFIFOW(8, Point.Y);
						SendBCmd(tm, Point, 10);
						PickUpItem(tc,tn.ID);
						ActTick := Tick + 200;
					end;
				end;
				Exit;
			end;
		end;
		if ((auto and $10) = $10) and (Sit = 3) and (ATarget = 0) and (MMode = 0) then begin
			//�t���t���K���Ɉړ�
			j := 0;
			i := 0;
			repeat
				k := 0;
				repeat
					xy.X := Point.X + Random(17) - 8; //�ړ��͈͍͂ő�8�}�X
					xy.Y := Point.Y + Random(17) - 8; //��(2�u���b�N�ȏ�ړ����Ȃ��悤��)
					Inc(k);
				until ((xy.X >= 0) and (xy.X <= tm.Size.X - 2) and (xy.Y >= 0) and (xy.Y <= tm.Size.Y - 2)) or (k = 100);
				if k = 100 then begin
					//�ړ��\�ӏ����Ȃ�or���Ȃ�����Ƃ��͈ړ����Ȃ�
					j := 100;
					break;
				end;
				//---
				if (tm.gat[xy.X][xy.Y] and 1) <> 0 then
					//pcnt := SearchPath(path, tm, Point, xy);
				i := SearchPath2(path, tm, Point.X, Point.Y, xy.X, xy.Y);
				Inc(j);
			until (i <> 0) or (j = 100);
			if j <> 100 then begin
				NextFlag := True;
				NextPoint := xy;
				//�҂�����(���Ȃ�K��)
				ActTick := Tick + Cardinal(Random(1000)) + Speed * Cardinal(i);
			end;
		end;

	end;
end;
{�ǉ��R�R�܂�}
//------------------------------------------------------------------------------
procedure TfrmMain.cmdStartClick(Sender: TObject);
var
	i,j,k,m,n,a,b,c:integer;
	i1,j1,k1:integer;
	Tick:cardinal;
	//tp:TPlayer;
	tc:TChara;
	//tp1:TPlayer;
	tc1:TChara;
	tm:TMap;
	tn:TNPC;
	ts:TMob;
	ts1:TMob;
	ts2:TMob;
	tk	:TSkill;
	tl	:TSkillDB;
	spd:cardinal;
	Tick1:cardinal;
	xy:TPoint;
	dx,dy:integer;
	DropFlag:boolean;
	SkillProcessType:byte;
	sl:TStringList;
	bb:array of byte;
{�L���[�y�b�g}
				tpe:TPet;
{�L���[�y�b�g�����܂�}
{NPC�C�x���g�ǉ�}
	tr      :NTimer;
{NPC�C�x���g�ǉ��R�R�܂�}
label ExitWarpSearch;
begin
	sl := TStringList.Create;
	try
	cmdStart.Enabled := false;
	sv1.Active := true;
	sv2.Active := true;
	sv3.Active := true;

	ServerRunning := true;
	cmdStop.Enabled := true;
	TickCheckCnt := 0;
	repeat
		Tick := timeGetTime();

		//�L�����N�^�[�v���Z�X
		for i := 0 to CharaName.Count - 1 do begin
			tc := CharaName.Objects[i] as TChara;
			if tc.Login <> 2 then continue;
			with tc do begin
				tm := MData;
				if tm = nil then continue;

{�ǉ�}	//�����s��
				if (Sit <> 1) and (Auto <> 0) and (ActTick < Tick) then begin
					AutoAction(tc,Tick);
				end;
{�ǉ��R�R�܂�}
				//�ړ�����
				if pcnt <> 0 then begin
					if (Path[ppos] and 1) = 0 then spd := Speed else spd := Speed * 140 div 100;
					if MoveTick + spd <= Tick then begin
{�C��}
						if CharaMoving(tc,Tick) then begin
							goto ExitWarpSearch;
						end;
{�C���R�R�܂�}
					end;
				end;

{U0x003b}
			try
				//�ǉ��ړ�����
				if NextFlag and (DmgTick <= Tick) then begin
					if (tm.Size.X < NextPoint.X) or (tm.Size.Y < NextPoint.Y) then begin
						DebugOut.Lines.Add('Move processing error');
					end else begin
					if (tc.MMode = 0) and (tm.gat[NextPoint.X][NextPoint.Y] <> 0) then begin
						//�ǉ��ړ�
						AMode := 0;
						k := SearchPath2(tc.path, tm, Point.X, Point.Y, NextPoint.X, NextPoint.Y);
						if k <> 0 then begin
							if pcnt = 0 then MoveTick := Tick;
								pcnt := k;
								ppos := 0;
								Sit := 0;
								tgtPoint := NextPoint;
								//�o�H�T��OK
								WFIFOW(0, $0087);
								WFIFOL(2, MoveTick);
								WFIFOM2(6, NextPoint, Point);
								WFIFOB(11, 0);
								Socket.SendBuf(buf, 12);
								//�u���b�N����
								for n := Point.Y div 8 - 2 to Point.Y div 8 + 2 do begin
									for m := Point.X div 8 - 2 to Point.X div 8 + 2 do begin
										//����̐l�ɒʒm&����ɂ���l��\��������
										for k := 0 to tm.Block[m][n].CList.Count - 1 do begin
											tc1 := tm.Block[m][n].CList.Objects[k] as TChara;
											if (tc <> tc1) and (abs(Point.X - tc1.Point.X) < 16) and (abs(Point.Y - tc1.Point.Y) < 16) then begin
												SendCMove(tc1.Socket, tc, Point, NextPoint);
{�`���b�g���[���@�\�ǉ�}
												//���ӂ̃`���b�g���[����\��
												ChatRoomDisp(tc.Socket, tc1);
{�`���b�g���[���@�\�ǉ��R�R�܂�}
{�I�X�X�L���ǉ�}
												//���ӂ̘I�X��\��
												VenderDisp(tc.Socket, tc1);
{�I�X�X�L���ǉ��R�R�܂�}
											end;
										end;
									end;
								end;
							end;
						end else begin
							Sit := 3;
						end;
						NextFlag := false;
					end;
				end;
			except
				DebugOut.Lines.Add('Move processing error');
			end;
{U0x003b�R�R�܂�}
{�C��}
				if (AMode = 1) or (AMode = 2) then begin
					//�U������
					if Sit = 1 then begin
					//���񂾂Ƃ��͍U���L�����Z��
						AMode := 0;
					end else if ATick + ADelay < Tick then begin
					CharaAttack(tc,Tick);
					if AMode = 1 then AMode := 0;
					end else begin
						//�U�����͂��Ȃ��Ƃ���ɓG���ړ�����
						//if (abs(tgtPoint.X - ts.Point.X) > 1) or (abs(tgtPoint.Y - ts.Point.Y) > 1) then AMode := 0;
						{
						DebugOut.Lines.Add(Format('3:%.8d RET %.4x', [tc.ID, $0139]));
						WFIFOW( 0, $0139);
						WFIFOL( 2, ts.ID);
						WFIFOW( 6, ts.Point.X);
						WFIFOW( 8, ts.Point.Y);
						WFIFOW(10, tc.Point.X);
						WFIFOW(12, tc.Point.Y);
						WFIFOW(14, tc.Range); //�˒�
						Socket.SendBuf(buf, 16);
						}
						//AMode := 0;
					end;
				end;
				//�X�L������
				if Boolean(MMode and $03) and (MTick <= Tick) then begin
					tl := tc.Skill[tc.MSkill].Data;
					tk := tc.Skill[tc.MSkill];
					if tc.SP < tl.SP[tc.MUseLV] then begin
						//SP�s��
						WFIFOW( 0, $0110);
						WFIFOW( 2, tc.MSkill);
						WFIFOW( 4, 0);
						WFIFOW( 6, 0);
						WFIFOB( 8, 0);
						WFIFOB( 9, 1);
						Socket.SendBuf(buf, 10);
							if MMode = 1 then begin
								MMode := 0;
								MTarget := 0;
							end else begin
								MMode := 0;
								MPoint.X := 0;
								MPoint.Y := 0;
							end;
					end else if tc.Weight * 100 div tc.MaxWeight >= 90 then begin
						//�d�ʃI�[�o�[
						WFIFOW(0, $013b);
						WFIFOW(2, 2);
						Socket.SendBuf(buf, 4);
							if MMode = 1 then begin
								MMode := 0;
								MTarget := 0;
							end else begin
								MMode := 0;
								MPoint.X := 0;
								MPoint.Y := 0;
							end;
					end else begin
						if tk.Lv < MUseLV then begin
							//���x��������Ȃ�(�s���p�P�b�g)
							if MMode = 1 then begin
								MMode := 0;
								MTarget := 0;
							end else begin
								MMode := 0;
								MPoint.X := 0;
								MPoint.Y := 0;
							end;
						end else begin
							if Boolean(MMode and $02) then begin
								CreateField(tc,Tick);
							end else if Boolean(MMode and $01) then begin
								pcnt := 0;
								SkillEffect(tc,Tick);
								MTarget := 0;
							end;
							if Boolean(MMode xor $04) then
								DecSP(tc, MSkill, MUseLV);
							tc.MMode	:= 0;
							tc.MSkill := 0;
							tc.MUseLv := 0;
						end;
					end;
				end;

				CharaPassive(tc,Tick);

{�C���R�R�܂�}
				//���Ԑ����X�L�����؂ꂽ���ǂ����`�F�b�N
				if SkillTick <= Tick then begin
					case SkillTickID of
						10,24: //���A�t�A�T�C�g�̉���
							begin
								Option := Option and $FE;
								WFIFOW(0, $0119);
								WFIFOL(2, tc.ID);
								WFIFOW(6, 0);
								WFIFOW(8, 0);
								WFIFOW(10, tc.Option);
								WFIFOB(12, 0);
								SendBCmd(tm, tc.Point, 13);
								//Skill[10].Tick := 0;
								//Skill[24].Tick := 0;
							end;
						51,135: //�n�C�h�A�N���[�L���O
							begin
								Option := Option and $F4;
								WFIFOW(0, $0119);
								WFIFOL(2, tc.ID);
								WFIFOW(6, 0);
								WFIFOW(8, 0);
								WFIFOW(10, tc.Option);
								WFIFOB(12, 0);
								SendBCmd(tm, tc.Point, 13);
							end;
					end;
					//�A�C�R���\������
{�C��}		if tc.Skill[SkillTickID].Data.Icon <> 0 then begin
						DebugOut.Lines.Add('(߁��)?');
						WFIFOW(0, $0196);
						WFIFOW(2, tc.Skill[SkillTickID].Data.Icon);
						WFIFOL(4, tc.ID);
						WFIFOB(8, 0);
						Socket.SendBuf(buf, 9);
					end;
					CalcStat(tc, Tick);
					SendCStat(tc);
					CalcSkillTick(tm, tc, Tick);
				end;

				//Mob&Item Process
				tm := tc.MData;
				for b := Point.Y div 8 - 3 to Point.Y div 8 + 3 do begin
					for a := Point.X div 8 - 3 to Point.X div 8 + 3 do begin
{�ǉ�}			if tm.Block[a][b] = nil then continue;
						//if not tm.Block[a][b].MobProcess then begin
						if tm.Block[a][b].MobProcTick < Tick then begin
							//�����X�^�[�ړ�����(�t�߂̃����X�^�[)
							//for k := 0 to tm.Block[a][b].Mob.Count - 1 do begin
							k := 0;
							while (k >= 0) and (k < tm.Block[a][b].Mob.Count) do begin
								//DebugOut.Lines.Add('mob : ' + IntToStr(k));
								ts := tm.Block[a][b].Mob.Objects[k] as TMob;
								Inc(k);
								if ts = nil then Continue;
								if (ts.HP = 0) and (ts.SpawnTick + ts.SpawnDelay1 + cardinal(Random(ts.SpawnDelay2 + 1)) <= Tick) then begin
									//Spawn
									MonsterSpawn(tm, ts, Tick);
								end;
								{
								if ts.Data.isDontMove then begin
									Inc(k);
									continue;
								end;
								}
								//continue;
								with ts do begin
									//��ԕω�
									StatEffect(tm,ts,Tick);
									//��ԂP�ł͍s���s��
									if ts.Stat1 <> 0 then Continue;
									MobAI(tm,ts,Tick);
									if (pcnt <> 0) then begin
										//�ړ�����
										if (path[ppos] and 1) = 0 then spd := Speed else spd := Speed * 140 div 100; //�΂߂�1.4�{���Ԃ�������
										if MoveTick + spd <= Tick then begin
{�C��}								k := k + MobMoving(tm,ts,Tick);
										end;
									end else begin
										//�ړ����ĂȂ��Ƃ�
										if isLooting then begin
											if ATick < Tick then
											 	PickUp(tm,ts,Tick);
										end else if (ATarget <> 0) and (Data.Range1 > 0)	then begin
											MobAttack(tm,ts,Tick);

{�C��}							end else if (MoveWait < Tick) and (not isLooting) then begin
											//�ړ��J�n
											j := 0;
											if LeaderID <> 0 then begin
												//��芪���p
												ts2 := tm.Mob.IndexOfObject(LeaderID) as TMob;
												if (ts2 = nil) or (ts2.HP = 0) or (ts2.Map <> ts.Map) then
													LeaderID := 0
												else begin
													repeat
														k := 0;
														repeat
															xy.X := ts2.Point.X + Random(11) - 5;
															xy.Y := ts2.Point.Y + Random(11) - 5;
															Inc(k);
														until ((xy.X >= 0) and (xy.X <= tm.Size.X - 2) and (xy.Y >= 0) and (xy.Y <= tm.Size.Y - 2)) or (k = 100);
														if k = 100 then begin
															//�ړ��\�ӏ����Ȃ�or���Ȃ�����Ƃ��͈ړ����Ȃ�
															j := 100;
															Break;
														end;
														if (tm.gat[xy.X][xy.Y] and 1) <> 0 then
															pcnt := SearchPath2(path, tm, Point.X, Point.Y, xy.X, xy.Y);
														Inc(j);
													until (pcnt <> 0) or (j = 100);
												end;
											end else begin
												//AMode := 0;
												//030316-2 ����������/030317
												repeat
													k := 0;
													repeat
														xy.X := Point.X + Random(17) - 8; //�ړ��͈͍͂ő�8�}�X
														xy.Y := Point.Y + Random(17) - 8; //��(2�u���b�N�ȏ�ړ����Ȃ��悤��)
														Inc(k);
													until ((xy.X >= 0) and (xy.X <= tm.Size.X - 2) and (xy.Y >= 0) and (xy.Y <= tm.Size.Y - 2)) or (k = 100);
													if k = 100 then begin
														//�ړ��\�ӏ����Ȃ�or���Ȃ�����Ƃ��͈ړ����Ȃ�
														j := 100;
														break;
													end;
													//---
													if (tm.gat[xy.X][xy.Y] and 1) <> 0 then
														//pcnt := SearchPath(path, tm, Point, xy);
														pcnt := SearchPath2(path, tm, Point.X, Point.Y, xy.X, xy.Y);
													Inc(j);
												until (pcnt <> 0) or (j = 100);
											end;
												if j <> 100 then begin
												ppos := 0;
												if pcnt <> 0 then begin
													MoveTick := Tick;
													tgtPoint := xy;
													//�o�H�T��OK
													//�u���b�N����
{�C��}
													WFIFOW(0, $0088);
													WFIFOL(2, ts.ID);
													WFIFOW(6, ts.Point.X);
													WFIFOW(8, ts.Point.Y);
													SendBCmd(tm, ts.Point, 10);

													SendMMove(tc.Socket, ts, Point, tgtPoint, tc.ver2);
													SendBCmd(tm,ts.Point,58,tc,True);
												end;
{�C���R�R�܂�}
											end else begin
												DebugOut.Lines.Add(Format('* * * * SearchPath Error (%d,%d)',[Point.X,Point.Y]));
												MoveWait := Tick + 10000;
											end;
										end;
									end;
								end;
							end;
							//�A�C�e��&�X�L�����\�n����(�t�߂̂��̂̂ݏ���)
							k := 0;
							while (0 <= k) and (k < tm.Block[a][b].NPC.Count) do begin
								//DebugOut.Lines.Add('mob : ' + IntToStr(k));
								tn := tm.Block[a][b].NPC.Objects[k] as TNPC;
								Inc(k);
								if tn = nil then Continue;
								k := k + NPCAction(tm,tn,Tick);
							end;
							//�t���OON
							//tm.Block[a][b].MobProcess := true;
							tm.Block[a][b].MobProcTick := Tick;
						end;
					end;
				end;
{�L���[�y�b�g}
                                        if ( PetData <> nil ) and ( PetNPC <> nil ) then begin
                                                tpe := PetData;
                                                tn := PetNPC;

                                                // �ړ�
                                                j := 0;
                                                k := SearchPath2( tn.path, tm, tn.Point.X, tn.Point.Y, Point.X, Point.Y );
                                                if k > 2 then begin

                                                        if Sit = 0 then begin
                                                                xy := Point;
                                                        end else begin
                                                                repeat
                                                                        if j >= 100 then begin
                                                                                xy := Point;
                                                                                break;
                                                                        end;

                                                                        xy.X := Point.X + Random(5) - 2;
                                                                        xy.Y := Point.Y + Random(5) - 2;
                                                                        Inc(j);
                                                                until ( xy.X <> Point.X ) or ( xy.Y <> Point.Y );

                                                                k := SearchPath2( tn.path, tm, tn.Point.X, tn.Point.Y, xy.X, xy.Y );
                                                        end;

                                                        if k <> 0 then begin
                                                                tn.NextPoint := xy;
                                                                SendPetMove( Socket, tc, xy );
                                                                SendBCmd( tm, tn.Point, 58, tc, True );

                                                                if tn.pcnt = 0 then MoveTick := Tick;
                                                                tn.pcnt := k;
                                                                tn.ppos := 0;

                                                                if (tn.Path[tn.ppos] and 1) = 0 then spd := Speed else spd := Speed * 140 div 100;
                                                                if tn.MoveTick + spd <= Tick then begin
                                                                        PetMoving( tc, Tick );
                                                                end;
                                                        end;
                                                end;

                                                // ����������V�X�e��
                                                if tpe.Fullness > 0 then begin
                                                        if ( tn.HungryTick + tpe.Data.HungryDelay ) < Tick then begin
                                                                Dec( tpe.Fullness );

                                                                WFIFOW( 0, $01a4 );
                                                                WFIFOB( 2, 2 );
                                                                WFIFOL( 3, tn.ID );
                                                                WFIFOL( 7, tpe.Fullness );
                                                                tc.Socket.SendBuf( buf, 11 );

                                                                tn.HungryTick := Tick;
                                                        end;
                                                end;
                                        end;
{�L���[�y�b�g�����܂�}
			end;
			ExitWarpSearch:
		end;

{NPC�C�x���g�ǉ�}
		for k := 0 to Map.Count - 1 do begin
			tm := Map.Objects[k] as TMap;
			with tm do begin
				if (TimerAct.Count > 0) then begin
					for i := 0 to TimerAct.Count - 1 do begin
						tr := TimerAct.Objects[i] as NTimer;
						tn := tm.NPC.IndexOfObject(tr.ID) as TNPC;
						for a := 0 to tr.Cnt - 1 do begin
							if (tr.Tick + cardinal(tr.Idx[a]) <= Tick) and (tr.Done[a] = 0) then begin
								DebugOut.Lines.Add(Format('NPC Timer Event(%d)', [tr.Idx[a]]));
								tr.Done[a] := 1;
								tc1 := TChara.Create;
								tc1.TalkNPCID := tr.ID;
								tc1.ScriptStep := tr.Step[a];
								tc1.AMode := 3;
								tc1.AData := tn;
								tc1.Login := 0;
								NPCScript(tc1,0,1);
								tc1.Free;
							end;
						end;
					end;
				end;
			end;
		end;
{NPC�C�x���g�ǉ��R�R�܂�}

		//�����X�^�[����(�L�����̂��΂ɂ��Ȃ������X�^�[�͊ȈՏ����̂�)
		for k := 0 to Map.Count - 1 do begin
			tm := Map.Objects[k] as TMap;
			with tm do begin
				if (Mode = 2) and (CList.Count > 0) then begin
					MobMoveL(tm,Tick);
					//Spwan����
					for i := 0 to Mob.Count - 1 do begin
						ts := Mob.Objects[i] as TMob;
						if (ts.HP = 0) and (ts.SpawnTick + ts.SpawnDelay1 + cardinal(Random(ts.SpawnDelay2 + 1)) <= Tick) then begin
							MonsterSpawn(tm, ts, Tick);
						end;
					end;
				end;
			end;
		end;

		Application.ProcessMessages;
		Tick1 := timeGetTime();
		if (Tick + 30) > Tick1 then begin
			Sleep(Tick + 30 - Tick1);
			//Tick1 := timeGetTime();
		end;

		//if (Tick1 - Tick) <> 0 then begin
			TickCheck[TickCheckCnt] := Tick1 - Tick;
			Inc(TickCheckCnt);
			if TickCheckCnt = 10 then begin
				Tick1 := 0;
				for i := 0 to 9 do Tick1 := Tick1 + TickCheck[i];
				lbl00.Caption := IntToStr(Tick1 div 10);
				TickCheckCnt := 0;
			end;
		//end;

		//if (timeGetTime() - Tick) <> 0 then lbl00.Caption := IntToStr(timeGetTime() - Tick);
	until CancelFlag;
	finally
	sl.Free;
	for i := 0 to sv1.Socket.ActiveConnections - 1 do
		sv1.Socket.Disconnect(i);
	sv1.Active := false;
	for i := 0 to sv2.Socket.ActiveConnections - 1 do
		sv2.Socket.Disconnect(i);
	sv2.Active := false;
	for i := 0 to sv3.Socket.ActiveConnections - 1 do
		sv3.Socket.Disconnect(i);
	sv3.Active := false;
	cmdStop.Enabled := false;
	ServerRunning := false;
	CancelFlag := false;
	cmdStart.Enabled := true;
	lbl00.Caption := '(�L-�M)';
	end;
end;

procedure TfrmMain.cmdStopClick(Sender: TObject);
begin
	CancelFlag := true;
	cmdStop.Enabled := false;
end;
//------------------------------------------------------------------------------
{U0x003b}
procedure TfrmMain.DBsaveTimerTimer(Sender: TObject);
begin
	DataSave();
	DebugOut.Lines.Add('15 Mins save');
end;

//==============================================================================

end.
 
