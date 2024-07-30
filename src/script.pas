unit Script;



interface

uses
	Windows, Types, SysUtils, Common, MMSystem;

//==============================================================================
// 関数定義
		procedure NPCScript(tc:TChara; value:cardinal = 0; mode:byte = 0);
//==============================================================================










implementation
//==============================================================================
procedure NPCScript(tc:TChara; value:cardinal = 0; mode:byte = 0);
var
	i,j,k,l :integer;
	cnt     :integer;
	str     :string;
	p       :pointer;
	len     :cardinal;
	flag    :boolean;
	tn      :TNPC;
	td      :TItemDB;
{NPCイベント追加}
	ts      :TMob;
	ts1     :TMob;
	tm      :TMap;
	tm1     :TMap;
	tn1     :TNPC;
	tc1     :TChara;
	w       :word;
	Tick    :cardinal;
	tr      :NTimer;
	tcr     :TChatRoom;
	mi      :MapTbl;
{NPCイベント追加ココまで}
begin
	flag := false;

	if (tc.AMode <> 3) then exit;
	tn := tc.AData;
	//with tn do begin
		//距離チェック
{NPCイベント追加}
		if (mode = 0) then begin
			if (tc.Map <> tn.Map) or (abs(tc.Point.X - tn.Point.X) > 15) or (abs(tc.Point.Y - tn.Point.Y) > 15) then begin
				tc.AMode := 0;
				exit;
			end;
		end;
		tm := Map.Objects[Map.IndexOf(tn.Map)] as TMap;
		Tick := timeGetTime();
{NPCイベント追加ココまで}
		cnt := 0;
		while (tc.ScriptStep < tn.ScriptCnt) and (cnt < 100) do begin
			case tn.Script[tc.ScriptStep].ID of
			0: //(nop)
				begin
					Inc(tc.ScriptStep);
				end;
			1: //mes
				begin
					str := tn.Script[tc.ScriptStep].Data1[0];
					i := AnsiPos('$[', str);
					while i <> 0 do begin
						j := AnsiPos(']', Copy(str, i + 2, 256));
						if j <= 1 then break;
{NPCイベント追加}
						if (Copy(str, i + 2, 1) = '$') then begin
							str := Copy(str, 1, i - 1) + tc.Flag.Values[Copy(str, i + 2, j - 1)]  + Copy(str, i + j + 2, 256);
						end else if (Copy(str, i + 2, 2) = '\$') then begin
							str := Copy(str, 1, i - 1) + ServerFlag.Values[Copy(str, i + 2, j - 1)]  + Copy(str, i + j + 2, 256);
						end else begin
							k := ConvFlagValue(tc, Copy(str, i + 2, j - 1), true);
							if k <> -1 then begin
								str := Copy(str, 1, i - 1) + IntToStr(k) + Copy(str, i + j + 2, 256);
							end else begin
								str := Copy(str, 1, i - 1) + Copy(str, i + j + 2, 256);
							end;
						end;
{NPCイベント追加ココまで}
						i := AnsiPos('$[', str);
					end;
					str := StringReplace(str, '$codeversion', CodeVersion, [rfReplaceAll]);
					str := StringReplace(str, '$charaname', tc.Name, [rfReplaceAll]);
					str := StringReplace(str, '$$', '$', [rfReplaceAll]);
					i := Length(str);
					WFIFOW(0, $00b4);
					WFIFOW(2, i + 8);
					WFIFOL(4, tn.ID);
					WFIFOS(8, str, i);
					tc.Socket.SendBuf(buf[0], i + 8);
					Inc(tc.ScriptStep);
				end;
			2: //next
				begin
					WFIFOW(0, $00b5);
					WFIFOL(2, tn.ID);
					tc.Socket.SendBuf(buf[0], 6);
					Inc(tc.ScriptStep);
					break;
				end;
			3: //close
				begin
					WFIFOW(0, $00b6);
					WFIFOL(2, tn.ID);
					tc.Socket.SendBuf(buf[0], 6);
					tc.ScriptStep := $FFFF;
					break;
				end;
			4: //menu
				begin
					if value = 0 then begin
						for i := 0 to tn.Script[tc.ScriptStep].DataCnt - 1 do begin
							if i = 0 then
								str := tn.Script[tc.ScriptStep].Data1[i]
							else
								str := str + ':' + tn.Script[tc.ScriptStep].Data1[i];
						end;
						i := Length(str);
						WFIFOW(0, $00b7);
						WFIFOW(2, i + 8);
						WFIFOL(4, tn.ID);
						WFIFOS(8, str, i);
						tc.Socket.SendBuf(buf[0], i + 8);
						break;
					end else begin
						if value = $FF then begin
{精錬NPC機能追加}
              //EqLock解除
							if tc.EqLock = true then tc.EqLock := false;
{精錬NPC機能追加ココまで}
							tc.ScriptStep := $FFFF;
							break;
						end;
						Dec(value);
						if tn.Script[tc.ScriptStep].DataCnt <= value then begin
							tc.ScriptStep := $FFFF;
							break;
						end;
						tc.ScriptStep := tn.Script[tc.ScriptStep].Data3[value];
						value := 0;
					end;
				end;
			5: //goto
				begin
					tc.ScriptStep := tn.Script[tc.ScriptStep].Data3[0];
				end;
			6: //cutin
				begin
					WFIFOW(0, $0145);
					WFIFOS(2, tn.Script[tc.ScriptStep].Data1[0], 16);
					WFIFOB(18, tn.Script[tc.ScriptStep].Data3[0]);
					tc.Socket.SendBuf(buf[0], 19);
					Inc(tc.ScriptStep);
				end;
			7: //store
				begin
					tc.AMode := 4;
					SendCStoreList(tc);
					Inc(tc.ScriptStep);
				end;
			8: //warp
				begin
					SendCLeave(tc, 2);
					tc.tmpMap := tn.Script[tc.ScriptStep].Data1[0];
					tc.Point := Point(tn.Script[tc.ScriptStep].Data3[0],tn.Script[tc.ScriptStep].Data3[1]);
					MapMove(tc.Socket, tc.tmpMap, tc.Point);
					exit;
				end;
			9: //save
				begin
{NPCイベント追加}
					i := MapInfo.IndexOf(tm.Name);
					if (i <> -1) then begin
						mi := MapInfo.Objects[i] as MapTbl;
						if (mi.noSave <> true) then begin
							tc.SaveMap := tn.Script[tc.ScriptStep].Data1[0];
							tc.SavePoint := Point(tn.Script[tc.ScriptStep].Data3[0],tn.Script[tc.ScriptStep].Data3[1]);
						end;
					end;
{NPCイベント追加ココまで}
					Inc(tc.ScriptStep);
				end;
			10: //heal
				begin
					Inc(tc.HP, tn.Script[tc.ScriptStep].Data3[0]);
					if tc.HP > tc.MAXHP then tc.HP := tc.MAXHP;
					Inc(tc.SP, tn.Script[tc.ScriptStep].Data3[1]);
					if tc.SP > tc.MAXSP then tc.SP := tc.MAXSP;
					//パケ送信
					WFIFOW( 0, $011a);
					WFIFOW( 2, 28);
					WFIFOW( 4, tn.Script[tc.ScriptStep].Data3[0]);
					WFIFOL( 6, tc.ID);
					WFIFOL(10, tn.ID);
					WFIFOB(14, 1);
					SendBCmd(tc.MData, tn.Point, 15);
					{
					WFIFOW( 0, $013d);
					WFIFOW( 2, $0007);
					WFIFOW( 4, tn.Script[tc.ScriptStep].Data3[1]);
					tc.Socket.SendBuf(buf, 6);
					}
					WFIFOW( 0, $00b0);
					WFIFOW( 2, $0005);
					WFIFOL( 4, tc.HP);
					tc.Socket.SendBuf(buf, 8);
					WFIFOW( 0, $00b0);
					WFIFOW( 2, $0007);
					WFIFOL( 4, tc.SP);
					tc.Socket.SendBuf(buf, 8);
					Inc(tc.ScriptStep);
				end;
			11: //set
				begin
					str := tn.Script[tc.ScriptStep].Data1[0];
					p := nil;
					len := 0;
							 if str = 'zeny'        then begin p := @tc.Zeny;        len := 4; end
					else if str = 'job'         then begin p := @tc.JID;         len := 2; end
					else if str = 'baselevel'   then begin p := @tc.BaseLV;      len := 2; end
					else if str = 'joblevel'    then begin p := @tc.JobLV;       len := 2; end
					else if str = 'statuspoint' then begin p := @tc.StatusPoint; len := 2; end
					else if str = 'skillpoint'  then begin p := @tc.SkillPoint;  len := 2; end
					else if str = 'option'      then begin p := @tc.Option;      len := 4; end
					else if str = 'speed'       then begin p := @tc.Speed;       len := 2; end;
					if len <> 0 then begin
						//左辺はパラメータ
{NPCイベント追加}
						j := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[1]);
{NPCイベント追加ココまで}
						i := 0;
						if tn.Script[tc.ScriptStep].Data3[0] <> 0 then CopyMemory(@i, p, len);
						case tn.Script[tc.ScriptStep].Data3[0] of
						0,1:	i := i + j;
						2:		i := i - j;
						3:		i := i * j;
						4:		i := i div j;
						end;
						if i < 0 then i := 0;
						if (tn.Script[tc.ScriptStep].Data3[1] <> 0) and
								(i > tn.Script[tc.ScriptStep].Data3[1]) then i := tn.Script[tc.ScriptStep].Data3[1];
						CopyMemory(p, @i, len);
						SendCStat(tc);
					end else begin
						//左辺はフラグ
{NPCイベント追加}
						j := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[1]);
						if (tn.Script[tc.ScriptStep].Data3[0] = 0) then begin
							i := 0;
						end else begin
							i := ConvFlagValue(tc, str);
						end;
{NPCイベント追加ココまで}
						case tn.Script[tc.ScriptStep].Data3[0] of
						0,1:  i := i + j;
						2:    i := i - j;
						3:    i := i * j;
						4:    i := i div j;
						end;
						if i < 0 then i := 0;
						if (tn.Script[tc.ScriptStep].Data3[1] <> 0) and
							 (i > tn.Script[tc.ScriptStep].Data3[1]) then i := tn.Script[tc.ScriptStep].Data3[1];
{NPCイベント追加}
						if (Copy(str, 1, 1) <> '\') then begin
							tc.Flag.Values[str] := IntToStr(i);
						end else begin
							ServerFlag.Values[str] := IntToStr(i);
						end;
{NPCイベント追加ココまで}
					end;
					Inc(tc.ScriptStep);
				end;
			12: //additem
				begin
{NPCイベント追加}
					i := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[0]);
					j := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[1]);
{NPCイベント追加ココまで}
					td := ItemDB.IndexOfObject(i) as TItemDB;
					if tc.MaxWeight >= tc.Weight + cardinal(td.Weight) * cardinal(j) then begin
						k := SearchCInventory(tc, i, td.IEquip);
						if k <> 0 then begin
							if tc.Item[k].Amount + j > 30000 then j := 30000 - tc.Item[k].Amount;
							if td.IEquip then j := 1;
							//アイテム追加
							tc.Item[k].ID := i;
							tc.Item[k].Amount := tc.Item[k].Amount + j;
							tc.Item[k].Equip := 0;
							tc.Item[k].Identify := 1;
							tc.Item[k].Refine := 0;
							tc.Item[k].Attr := 0;
							tc.Item[k].Card[0] := 0;
							tc.Item[k].Card[1] := 0;
							tc.Item[k].Card[2] := 0;
							tc.Item[k].Card[3] := 0;
							tc.Item[k].Data := td;
							//重量追加
							tc.Weight := tc.Weight + cardinal(td.Weight) * cardinal(j);
							WFIFOW( 0, $00b0);
							WFIFOW( 2, $0018);
							WFIFOL( 4, tc.Weight);
							tc.Socket.SendBuf(buf, 8);

							//アイテムゲット通知
							SendCGetItem(tc, k, j);
						end;
					end else begin
						//重量オーバー
						WFIFOW( 0, $00a0);
						WFIFOB(22, 2);
						tc.Socket.SendBuf(buf, 23);
					end;
					Inc(tc.ScriptStep);
				end;
			13: //delitem
				begin
{NPCイベント追加}
					i := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[0]);
					j := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[1]);
{NPCイベント追加ココまで}
					k := SearchCInventory(tc, i, false);
					if k <> 0 then begin
						if j > tc.Item[k].Amount then j := tc.Item[k].Amount;
						//装備中なら装備解除
						if tc.Item[k].Equip <> 0 then begin
							WFIFOW(0, $00ac);
							WFIFOW(2, k);
							WFIFOW(4, tc.Item[k].Equip);
							tc.Item[k].Equip := 0;
							WFIFOB(6, 1);
							tc.Socket.SendBuf(buf, 7);
							CalcStat(tc);
							SendCStat(tc);
						end;
						//アイテム数減少
						Dec(tc.Item[k].Amount, j);
						if tc.Item[k].Amount = 0 then tc.Item[k].ID := 0;
						WFIFOW( 0, $00af);
						WFIFOW( 2, k);
						WFIFOW( 4, j);
						tc.Socket.SendBuf(buf, 6);
						//重量変更
						tc.Weight := tc.Weight - tc.Item[k].Data.Weight * cardinal(j);
						WFIFOW( 0, $00b0);
						WFIFOW( 2, $0018);
						WFIFOL( 4, tc.Weight);
						tc.Socket.SendBuf(buf, 8);
					end;
					Inc(tc.ScriptStep);
				end;
			14: //checkitem
				begin
{NPCイベント追加}
					i := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[0]);
					j := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[1]);
{NPCイベント追加ココまで}
					k := SearchCInventory(tc, i, false);
					if (k <> 0) and (tc.Item[k].Amount >= j) then begin
						DebugOut.Lines.Add(Format('s-checkitem: %d %d = 1', [i, j]));
						tc.ScriptStep := tn.Script[tc.ScriptStep].Data3[0];
					end else begin
						DebugOut.Lines.Add(Format('s-checkitem: %d %d = 0', [i, j]));
						tc.ScriptStep := tn.Script[tc.ScriptStep].Data3[1];
					end;
				end;
			15: //check
				begin
					str := tn.Script[tc.ScriptStep].Data1[0];
							 if str = 'zeny'        then begin i := tc.Zeny;        end
					else if str = 'job'         then begin i := tc.JID;         end
					else if str = 'baselevel'   then begin i := tc.BaseLV;      end
					else if str = 'joblevel'    then begin i := tc.JobLV;       end
					else if str = 'statuspoint' then begin i := tc.StatusPoint; end
					else if str = 'skillpoint'  then begin i := tc.SkillPoint;  end
					else if str = 'option'      then begin i := tc.Option;      end
					else if str = 'speed'       then begin i := tc.Speed;       end
					else if str = 'gender'      then begin i := tc.Gender;      end
{髪色変更追加}
					else if str = 'hcolor'      then begin i := tc.HairColor;   end
{髪色変更追加ココまで}
					else begin
{NPCイベント追加ココまで}
						i := ConvFlagValue(tc, str);
					end;
					j := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[1]);
{NPCイベント追加ココまで}
					case tn.Script[tc.ScriptStep].Data3[2] of
					0: flag := boolean(i >= j);
					1: flag := boolean(i <= j);
					2: flag := boolean(i  = j);
					3: flag := boolean(i <> j);
					4: flag := boolean(i >  j);
					5: flag := boolean(i <  j);
					else
						begin
							DebugOut.Lines.Add(Format('s-check: invalid formula "%s"', [tn.Script[tc.ScriptStep].Data1[2]]));
							tc.ScriptStep := $FFFF;
							break;
						end;
					end;
					DebugOut.Lines.Add(Format('s-check: %s %s(%d) %s = %d', [tn.Script[tc.ScriptStep].Data1[0], tn.Script[tc.ScriptStep].Data1[2], tn.Script[tc.ScriptStep].Data3[2], tn.Script[tc.ScriptStep].Data1[1], byte(flag)]));
					if flag then begin
						tc.ScriptStep := tn.Script[tc.ScriptStep].Data3[0];
					end else begin
						tc.ScriptStep := tn.Script[tc.ScriptStep].Data3[1];
					end;
				end;
			16: //checkadditem
				begin
{NPCイベント追加}
					i := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[0]);
					j := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[1]);
{NPCイベント追加ココまで}
					td := ItemDB.IndexOfObject(i) as TItemDB;
					if tc.MaxWeight >= tc.Weight + cardinal(td.Weight) * cardinal(j) then begin
						k := SearchCInventory(tc, i, td.IEquip);
						if k <> 0 then begin
							tc.ScriptStep := tn.Script[tc.ScriptStep].Data3[0];
						end else begin
							//アイテム種類数オーバー
							tc.ScriptStep := tn.Script[tc.ScriptStep].Data3[1];
						end;
					end else begin
						//重量オーバー
						tc.ScriptStep := tn.Script[tc.ScriptStep].Data3[1];
					end;
				end;
			17: //jobchange
				begin
                                   {バグ報告657}
                                        //装備解除
					for i := 1 to 100 do begin
					        if tc.Item[i].Equip = 32768 then
                                                begin
					                tc.Item[i].Equip := 0;
					                WFIFOW(0, $013c);
				                	WFIFOW(2, 0);
					                tc.Socket.SendBuf(buf, 4);
					        end else
                                                if tc.Item[i].Equip <> 0 then
                                                begin
					                WFIFOW(0, $00ac);
					                WFIFOW(2, i);
					                WFIFOW(4, tc.Item[i].Equip);
					                tc.Item[i].Equip := 0;
					                WFIFOB(6, 1);
					                tc.Socket.SendBuf(buf, 7);
					        end;
					end;
                                        //ジョブ変更
					tc.JID := tn.Script[tc.ScriptStep].Data3[0];
					tc.JobEXP := 0;
					tc.ClothesColor := 0;
					tc.JobLV := 1;
					SendCStat1(tc, 0, $0037, tc.JobLV);
					CalcStat(tc);
					tc.SkillPoint := 0;
                                        //ステータス再計算
					CalcStat(tc);
					SendCStat(tc, true);
					SendCSkillList(tc);
					WFIFOW(0, $00c3);
					WFIFOL(2, tc.ID);
					WFIFOB(6, 0);
					WFIFOB(7, tc.JID);
					SendBCmd(tc.MData, tc.Point, 8); //ここまで
                                   {バグ報告 657}
					Inc(tc.ScriptStep);
				end;
			18: //viewpoint
				begin
					WFIFOW( 0, $0144);
					WFIFOL( 2, tn.ID);
					WFIFOL( 6, tn.Script[tc.ScriptStep].Data3[0]);
					WFIFOL(10, tn.Script[tc.ScriptStep].Data3[1]);
					WFIFOL(14, tn.Script[tc.ScriptStep].Data3[2]);
					WFIFOB(18, tn.Script[tc.ScriptStep].Data3[3]);
					WFIFOL(19, tn.Script[tc.ScriptStep].Data3[4]);
					tc.Socket.SendBuf(buf, 23);

					Inc(tc.ScriptStep);
				end;
			19: //input
				begin
					if value = 0 then begin
						WFIFOW( 0, $0142);
						WFIFOL( 2, tn.ID);
						tc.Socket.SendBuf(buf, 6);
						break;
					end else begin
						//フラグセット
{NPCイベント追加}
						if (Copy(tn.Script[tc.ScriptStep].Data1[0], 1, 1) <> '\') then begin
							tc.Flag.Values[tn.Script[tc.ScriptStep].Data1[0]] := IntToStr(value - 1);
						end else begin
							ServerFlag.Values[tn.Script[tc.ScriptStep].Data1[0]] := IntToStr(value - 1);
						end;
{NPCイベント追加ココまで}
						Inc(tc.ScriptStep);
					end;
				end;
			20: //random
				begin
{NPCイベント追加}
					if (Copy(tn.Script[tc.ScriptStep].Data1[0], 1, 1) <> '\') then begin
						tc.Flag.Values[tn.Script[tc.ScriptStep].Data1[0]] := IntToStr(Random(tn.Script[tc.ScriptStep].Data3[0]));
					end else begin
						ServerFlag.Values[tn.Script[tc.ScriptStep].Data1[0]] := IntToStr(Random(tn.Script[tc.ScriptStep].Data3[0]));
					end;
{NPCイベント追加ココまで}
					Inc(tc.ScriptStep);
				end;
			21: //option
				begin
					if tn.Script[tc.ScriptStep].Data3[1] = 1 then begin
						case tn.Script[tc.ScriptStep].Data3[0] of
						0: tc.Option := (tc.Option and $F877) or $0008; //カート1
						1: tc.Option := tc.Option or $0010; //たか
						2: tc.Option := tc.Option or $0020; //ぺこ
						3: tc.Option := (tc.Option and $F877) or $0008; //カート1
						4: tc.Option := (tc.Option and $F877) or $0080; //カート2
						5: tc.Option := (tc.Option and $F877) or $0100; //カート3
						6: tc.Option := (tc.Option and $F877) or $0200; //カート4
						7: tc.Option := (tc.Option and $F877) or $0400; //カート5    
						end;
					end else begin
						case tn.Script[tc.ScriptStep].Data3[0] of
						0: tc.Option := tc.Option and $F877; //カート全解除  F847=全解除
						1: tc.Option := tc.Option and $FFEF; //たか
						2: tc.Option := tc.Option and $FFDF; //ぺこ
						end;
					end;

					CalcStat(tc);
					//見た目変更
					WFIFOW(0, $0119);
					WFIFOL(2, tc.ID);
					WFIFOW(6, 0);
					WFIFOW(8, 0);
					WFIFOW(10, tc.Option);
					WFIFOB(12, 0);
					SendBCmd(tc.MData, tc.Point, 13);
					Inc(tc.ScriptStep);
				end;
			22: //speed
				begin
					//パケ送信
{NPCイベント追加}
					i := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[0], true);
{NPCイベント追加ココまで}
					//スピード変更
					if (i >= 25) and (i <= 1000) then begin
						tc.Speed := i;
						tc.DefaultSpeed := i;
 
						CalcStat(tc);
						WFIFOW(0, $00b0);
						WFIFOW(2, $0000);
						WFIFOL(4, tc.Speed);
						tc.Socket.SendBuf(buf, 8);
 
						Inc(tc.ScriptStep);
					end;
				end;
			23: //die
				begin
					//パケ送信
					//プレーヤー即死
					CalcStat(tc);
					tc.HP := 0;
					tc.Sit := 1;
					SendCStat1(tc, 0, 5, tc.HP);
					WFIFOW(0, $0080);
					WFIFOL(2, tc.ID);
					WFIFOB(6, 1);
					tc.Socket.SendBuf(buf, 7);
					Inc(tc.ScriptStep);
				end;
			24: //ccolor
				begin
					//パケ送信
{NPCイベント追加}
					i := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[0], true);
{NPCイベント追加ココまで}
					//色変更
					if (i >= 1) and (i <= 4) then begin
						CalcStat(tc);
						tc.ClothesColor := i - 1;
						WFIFOW(0, $00c3);
						WFIFOL(2, tc.ID);
						WFIFOB(6, 7);
						WFIFOB(7, i-1);
						tc.Socket.SendBuf(buf, 8);
						SendBCmd(tc.MData, tc.Point, 8, tc);
					end;
					Inc(tc.ScriptStep);
				end;
			25: //refine		refine[itemID][fail][+val]
				begin
{NPCイベント追加}
					j := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[0]);
					k := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[1]);
					l := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[2]);
{NPCイベント追加ココまで}
					//精錬
					if (j >= 0) and (j <= 10) then begin
						for i := 1 to 100 do begin
							if (tc.Item[i].ID <> 0) and (tc.Item[i].Amount <> 0) and tc.Item[i].Data.IEquip and
								 (tc.Item[i].Equip <> 0) and (tc.Item[i].Card[0] <> $00ff) then begin
								tc.Item[i].Refine := byte(l);
								WFIFOW(0, $0188);
								WFIFOW(2, k);
								WFIFOW(4, i);
								WFIFOW(6, word(l));
								tc.Socket.SendBuf(buf, 8);
							end;
						end;
						CalcStat(tc);
						WFIFOW(0, $019b);
						WFIFOL(2, tc.ID);
						WFIFOL(6, 3);
						//パケ送信
						SendBCmd(tc.MData, tc.Point, 10, tc);
						SendCStat(tc);
					end;
					Inc(tc.ScriptStep);
				end;
			26: //getitemamount
				begin
{NPCイベント追加}
					i := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[0]);
{NPCイベント追加ココまで}
					k := SearchCInventory(tc, i, false);
					if k <> 0 then begin
						tc.Flag.Values[tn.Script[tc.ScriptStep].Data1[1]] := IntToStr(tc.Item[k].Amount);
					end else begin
						tc.Flag.Values[tn.Script[tc.ScriptStep].Data1[1]] := '0';
					end;
					Inc(tc.ScriptStep);
				end;
{追加:スクリプト144}
			27: //getskilllevel //S144 addstart
				begin
{NPCイベント追加}
					i := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[0]);
					if (Copy(tn.Script[tc.ScriptStep].Data1[0], 1, 1) <> '\') then begin
						if i = 0 then begin
							tc.Flag.Values[tn.Script[tc.ScriptStep].Data1[0]] := '0';
						end else begin
							tc.Flag.Values[tn.Script[tc.ScriptStep].Data1[1]] := IntToStr(tc.Skill[i].Lv);
						end;
					end else begin
						if i = 0 then begin
							ServerFlag.Values[tn.Script[tc.ScriptStep].Data1[0]] := '0';
						end else begin
							ServerFlag.Values[tn.Script[tc.ScriptStep].Data1[1]] := IntToStr(tc.Skill[i].Lv);
						end;
					end;
{NPCイベント追加ココまで}
					Inc(tc.ScriptStep);
				end;
			28: //setskilllevel
				begin
{NPCイベント追加}
					i := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[0]);
					if i <> 0 then begin
						l := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[1]);
{NPCイベント追加ココまで}
						if ((0 <= l) and (l <= 10)) then tc.Skill[i].Lv := l;
						SendCSKillList(tc);
					end;
					Inc(tc.ScriptStep);
				end; //S144 addend
{追加:スクリプト144ココまで}
{精錬NPC機能追加}
			29: //refinery
				begin
{NPCイベント追加}
					j := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[0]);
					k := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[1]);
{NPCイベント追加ココまで}
					case j of
						1:  l := $100; //頭上段
						2:  l := $10;  //鎧
						3:  l := $20;  //左手
						4:  l := $2;   //右手
						5:  l := $4;   //肩
						6:  l := $40;  //靴
						7:  l := $8;   //アクセ1
						8:  l := $80;  //アクセ2
						9:  l := $200; //頭上段
						10: l := $1;   //頭下段
						else l := 0;
					end;
{NPCイベント追加}
					j := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[2]);
{NPCイベント追加ココまで}
					if (j < 0) or (j > 10) then j := 0;
					if l <> 0 then begin
						for i := 1 to 100 do begin
							if (tc.Item[i].ID <> 0) and (tc.Item[i].Amount <> 0) and tc.Item[i].Data.IEquip and
								 ((tc.Item[i].Equip and l) = l) and (tc.Item[i].Refine < 10) then begin
								//装備解除
								WFIFOW(0, $00ac);
								WFIFOW(2, i);
								WFIFOW(4, tc.Item[i].Equip);
								WFIFOB(6, 1);
           			tc.Socket.SendBuf(buf, 7);
								//精錬成功
								if k = 0 then begin
									tc.Item[i].Refine := j;
									//エフェクト
									WFIFOW(0, $0188);
									WFIFOW(2, 0);
									WFIFOW(4, i);
									WFIFOW(6, tc.Item[i].Refine);
									tc.Socket.SendBuf(buf, 8);
									//再装備
									WFIFOW(0, $00aa);
									WFIFOW(2, i);
									WFIFOW(4, tc.Item[i].Equip);
									WFIFOB(6, 1);
									tc.Socket.SendBuf(buf, 7);
								//精錬失敗
								end else begin
									tc.Item[i].Refine := 0;
									tc.Item[i].Equip := 0;
									//エフェクト
									WFIFOW(0, $0188);
									WFIFOW(2, 1);
									WFIFOW(4, i);
									WFIFOW(6, word(tc.Item[i].Refine));
									tc.Socket.SendBuf(buf, 8);
									if k = 1 then begin
										//アイテム減少
										Dec(tc.Item[i].Amount, 1);
										if tc.Item[i].Amount = 0 then tc.Item[i].ID := 0;
										WFIFOW( 0, $00af);
										WFIFOW( 2, i);
										WFIFOW( 4, 1);
										tc.Socket.SendBuf(buf, 6);
										//重量変更
										tc.Weight := tc.Weight - tc.Item[i].Data.Weight * cardinal(1);
										WFIFOW( 0, $00b0);
										WFIFOW( 2, $0018);
										WFIFOL( 4, tc.Weight);
										tc.Socket.SendBuf(buf, 8);
									end;
					  		end;
						  end;
						end;
 						CalcStat(tc);
						WFIFOW(0, $019b);
						WFIFOL(2, tc.CID);
            if k = 0 then WFIFOL(6, 3) else WFIFOL(6, 2);
						//パケ送信
						SendBCmd(tc.MData, tc.Point, 10, tc);
						SendCStat(tc);
					end;
					Inc(tc.ScriptStep);
				end;
      30: //equipmenu
				begin
					if value = 0 then begin
						tn.Script[tc.ScriptStep].Data2[0] := '[頭 - 装着していない]';
						tn.Script[tc.ScriptStep].Data2[1] := '[体 - 装着していない]';
						tn.Script[tc.ScriptStep].Data2[2] := '[左手 - 装着していない]';
						tn.Script[tc.ScriptStep].Data2[3] := '[右手 - 装着していない]';
						tn.Script[tc.ScriptStep].Data2[4] := '[ローブ - 装着していない]';
						tn.Script[tc.ScriptStep].Data2[5] := '[靴 - 装着していない]';
						tn.Script[tc.ScriptStep].Data2[6] := '[アクセサリー1 - 装着していない]';
						tn.Script[tc.ScriptStep].Data2[7] := '[アクセサリー2 - 装着していない]';
						tn.Script[tc.ScriptStep].Data2[8] := '[頭2 - 装着していない]';
						tn.Script[tc.ScriptStep].Data2[9] := '[頭3 - 装着していない]';
            for i := 1 to 100 do begin
	  					if (tc.Item[i].ID <> 0) and (tc.Item[i].Amount <> 0) and (tc.Item[i].Equip <> 0) then begin
                if tc.Item[i].Refine > 0 then str := '(+' + IntToStr(tc.Item[i].Refine) + ')'
                  else str := '';
                str := tc.Item[i].Data.JName + str;
                case tc.Item[i].Equip of
									$1: //頭下段
										tn.Script[tc.ScriptStep].Data2[9] := str;
									$2: //右手
										tn.Script[tc.ScriptStep].Data2[3] := str;
									$4: //肩
										tn.Script[tc.ScriptStep].Data2[4] := str;
									$8: //アクセ1
										tn.Script[tc.ScriptStep].Data2[6] := str;
									$10: //鎧
										tn.Script[tc.ScriptStep].Data2[1] := str;
                  $20: //左手
										tn.Script[tc.ScriptStep].Data2[2] := str;
									$22: //両手武器
										begin
											tn.Script[tc.ScriptStep].Data2[2] := str;
											tn.Script[tc.ScriptStep].Data2[3] := str;
										end;
									$40: //靴
										tn.Script[tc.ScriptStep].Data2[5] := str;
									$80: //アクセ2
										tn.Script[tc.ScriptStep].Data2[7] := str;
									$100: //頭上段
										tn.Script[tc.ScriptStep].Data2[0] := str;
									$200: //頭中段
										tn.Script[tc.ScriptStep].Data2[8] := str;
									$201: //頭中下段
										begin
											tn.Script[tc.ScriptStep].Data2[8] := str;
											tn.Script[tc.ScriptStep].Data2[9] := str;
										end;
									$300: //頭上中段
										begin
											tn.Script[tc.ScriptStep].Data2[0] := str;
											tn.Script[tc.ScriptStep].Data2[8] := str;
										end;
									$301: //頭上中下段
										begin
											tn.Script[tc.ScriptStep].Data2[0] := str;
											tn.Script[tc.ScriptStep].Data2[8] := str;
											tn.Script[tc.ScriptStep].Data2[9] := str;
										end;
								end;
							end;
						end;
						for i := 0 to 9 do begin
							if i = 0 then
								str := tn.Script[tc.ScriptStep].Data2[i]
							else
								str := str + ':' + tn.Script[tc.ScriptStep].Data2[i];
						end;
						i := Length(str);
						WFIFOW(0, $00b7);
						WFIFOW(2, i + 8);
						WFIFOL(4, tn.ID);
						WFIFOS(8, str, i);
						tc.Socket.SendBuf(buf[0], i + 8);
						break;
					end else begin
						if value = $FF then begin
              //EqLock解除
              if tc.EqLock = true then tc.EqLock := false;
							tc.ScriptStep := $FFFF;
							break;
						end;
{NPCイベント追加}
						if (Copy(tn.Script[tc.ScriptStep].Data1[0], 1, 1) <> '\') then begin
							tc.Flag.Values[tn.Script[tc.ScriptStep].Data1[0]] := IntToStr(value);
						end else begin
							ServerFlag.Values[tn.Script[tc.ScriptStep].Data1[0]] := IntToStr(value);
						end;
{NPCイベント追加ココまで}
						case value of
							1:  l := $100; //頭上段
							2:  l := $10;  //鎧
							3:  l := $20;  //左手
							4:  l := $2;   //右手
							5:  l := $4;   //肩
							6:  l := $40;  //靴
							7:  l := $8;   //アクセ1
							8:  l := $80;  //アクセ2
							9:  l := $200; //頭上段
							10: l := $1;   //頭下段
							else l := 0;
						end;
						if l <> 0 then begin
							k := 0;
							j := 99;
							for i := 1 to 100 do begin
	    					if (tc.Item[i].ID <> 0) and (tc.Item[i].Amount <> 0) and tc.Item[i].Data.IEquip and
  		  					 ((tc.Item[i].Equip and l) = l) then begin
                  if tc.Item[i].Data.IType = 4 then begin
                    j := tc.Item[i].Data.wLV;
                  end else begin
                    j := 0;
                  end;
                  k := i;
                  break;
                end;
              end;
{NPCイベント追加}
							if (Copy(tn.Script[tc.ScriptStep].Data1[1], 1, 1) <> '\') then begin
								tc.Flag.Values[tn.Script[tc.ScriptStep].Data1[1]] := IntToStr(j);
							end else begin
								ServerFlag.Values[tn.Script[tc.ScriptStep].Data1[1]] := IntToStr(j);
							end;
							if (Copy(tn.Script[tc.ScriptStep].Data1[2], 1, 1) <> '\') then begin
								if k <> 0 then
									tc.Flag.Values[tn.Script[tc.ScriptStep].Data1[2]] := IntToStr(tc.Item[i].Refine)
								else
									tc.Flag.Values[tn.Script[tc.ScriptStep].Data1[2]] := '0';
							end else begin
								if k <> 0 then
									ServerFlag.Values[tn.Script[tc.ScriptStep].Data1[2]] := IntToStr(tc.Item[i].Refine)
								else
									ServerFlag.Values[tn.Script[tc.ScriptStep].Data1[2]] := '0';
							end;
{NPCイベント追加ココまで}
						end;
  					value := 0;
					end;
					Inc(tc.ScriptStep);
				end;
			31: //lockitem
				begin
{NPCイベント追加}
					i := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[0], true);
{NPCイベント追加ココまで}
					if i = 0 then tc.EqLock := false
						else if i = 1 then tc.EqLock := true;
					Inc(tc.ScriptStep);
				end;
{精錬NPC機能追加ココまで}
{髪色変更追加}
			32: //hcolor
				begin
{NPCイベント追加}
					i := ConvFlagValue(tc, tn.Script[tc.ScriptStep].Data1[0], true);
{NPCイベント追加ココまで}
					if (i >= 0) and (i <= 8) then begin
						tc.HairColor := i;
						WFIFOW(0, $00c3);
						WFIFOL(2, tc.ID);
						WFIFOB(6, 6);
						WFIFOB(7, i);
						SendBCmd(tc.MData, tc.Point, 8);
					end;
					Inc(tc.ScriptStep);
				end;
{髪色変更追加ココまで}
{NPCイベント追加}
			33: //callmob
				begin
					ts := TMob.Create;
					with ts do begin
						Map := tn.Script[tc.ScriptStep].Data1[0];
						Point.X := tn.Script[tc.ScriptStep].Data3[0];
						Point.Y := tn.Script[tc.ScriptStep].Data3[1];
						if (Point.X = 0) and (Point.Y = 0) then begin
							j := 0;
							repeat
								Point.X := Random(tm.Size.X - 2) + 1;
								Point.Y := Random(tm.Size.Y - 2) + 1;
								Inc(j);
							until (tm.gat[Point.X, Point.Y] and 1 <> 0) or (j = 100);
						end;
						if (j = 100) then continue;

						Name := tn.Script[tc.ScriptStep].Data1[1];
						JID := tn.Script[tc.ScriptStep].Data3[2];
						Data := MobDB.IndexOfObject(ts.JID) as TMobDB;
						ID := NowMobID;
						Inc(NowMobID);
						//イベント設定
						if (tn.Script[tc.ScriptStep].Data2[0] = '') then Event := 0
						else Event := StrToInt(tn.Script[tc.ScriptStep].Data2[0]);

						Dir := Random(8);
						HP := Data.HP;
						Speed := Data.Speed;
						SpawnDelay1 := $7FFFFFFF;
						SpawnDelay2 := 0;
						SpawnType := 0;
						SpawnTick := 0;

						isLooting := False;
						for j:= 1 to 10 do begin
							Item[j].ID := 0;
							Item[j].Amount := 0;
							Item[j].Equip := 0;
							Item[j].Identify := 0;
							Item[j].Refine := 0;
							Item[j].Attr := 0;
							Item[j].Card[0] := 0;
							Item[j].Card[1] := 0;
							Item[j].Card[2] := 0;
							Item[j].Card[3] := 0;
						end;

						if (tn.Script[tc.ScriptStep].Data3[3] = 0) then begin
							if Data.isDontMove then
								MoveWait := 4294967295
							else
								MoveWait := Tick + 5000 + Cardinal(Random(10000));
							isActive := ts.Data.isActive;
						end else begin
							MoveWait := timeGetTime();
							isActive := true;
						end;
						ATarget := 0;
						ATKPer := 100;
						DEFPer := 100;
						DmgTick := 0;
						Element := Data.Element;

						for j := 0 to 31 do begin
							EXPDist[j].CData := nil;
							EXPDist[j].Dmg := 0;
						end;
						if Data.MEXP <> 0 then begin
							for j := 0 to 31 do begin
								MVPDist[j].CData := nil;
								MVPDist[j].Dmg := 0;
							end;
							MVPDist[0].Dmg := Data.HP * 30 div 100; //FAに30%加算
						end;
						isSummon := True;

						tm.Mob.AddObject(ID, ts);
						tm.Block[Point.X div 8][Point.Y div 8].Mob.AddObject(ID, ts);

						//周囲に送信
						ZeroMemory(@buf[0], 41);
						WFIFOW( 0, $007c);
						WFIFOL( 2, ID);
						WFIFOW( 6, Speed);
						WFIFOW( 8, Stat1);
						WFIFOW(10, Stat2);
						WFIFOW(20, JID);
						WFIFOM1(36, Point, Dir);
						SendBCmd(tm,Point,41,nil,true);
						Inc(tc.ScriptStep);
					end;
				end;
			34: //broadcast
				begin
					l := tn.Script[tc.ScriptStep].Data3[0];
					str := tn.Script[tc.ScriptStep].Data1[0] + chr(0);
					i := AnsiPos('$[', str);
					while i <> 0 do begin
						j := AnsiPos(']', Copy(str, i + 2, 256));
						if j <= 1 then break;
						if (Copy(str, i + 2, 1) = '$') then begin
							str := Copy(str, 1, i - 1) + tc.Flag.Values[Copy(str, i + 2, j - 1)]  + Copy(str, i + j + 2, 256);
						end else if (Copy(str, i + 2, 2) = '\$') then begin
							str := Copy(str, 1, i - 1) + ServerFlag.Values[Copy(str, i + 2, j - 1)]  + Copy(str, i + j + 2, 256);
						end else begin
							k := ConvFlagValue(tc, Copy(str, i + 2, j - 1), true);
							if k <> -1 then begin
								str := Copy(str, 1, i - 1) + IntToStr(k) + Copy(str, i + j + 2, 256);
							end else begin
								str := Copy(str, 1, i - 1) + Copy(str, i + j + 2, 256);
							end;
						end;
						i := AnsiPos('$[', str);
					end;
					str := StringReplace(str, '$codeversion', CodeVersion, [rfReplaceAll]);
					str := StringReplace(str, '$charaname', tc.Name, [rfReplaceAll]);
					str := StringReplace(str, '$$', '$', [rfReplaceAll]);
					str := StringReplace(str, '\\', '\', [rfReplaceAll]);
					if ((l mod 100) div 10 = 0) then str := tn.Name + ' : ' + str;
					if (l div 100 = 1) then str := 'blue' + str;
					w := Length(str) + 4;
					WFIFOW(0, $009a);
					WFIFOW(2, w);
					WFIFOS(4, str, w - 4);

					if (l mod 10 = 0) then begin
						//カレントMAPのキャラに送信
						tm := Map.Objects[Map.IndexOf(tn.Map)] as TMap;
						for i := 0 to tm.CList.Count - 1 do begin
							tc1 := tm.CList.Objects[i] as TChara;
							if tc1.Login = 2 then tc1.Socket.SendBuf(buf, w);
						end;
					end else begin
						//全ワールドのキャラに送信
						for i := 0 to CharaName.Count - 1 do begin
							tc1 := CharaName.Objects[i] as TChara;
							if tc1.Login = 2 then tc1.Socket.SendBuf(buf, w);
						end;
					end;
					Inc(tc.ScriptStep);
				end;
			35: //npctimer
				begin
					i := tn.Script[tc.ScriptStep].Data3[0];
					j := tm.TimerAct.IndexOf(tn.ID);
					if (i = 0) then begin
						//タイマーOFF
						if (j <> -1) then begin
							DebugOut.Lines.Add(Format('NPC Timer(%d) was deleted / Remaining Timer(%d)', [tn.ID,tm.TimerAct.Count-1]));
							tm.TimerAct.Delete(tm.TimerAct.IndexOf(tn.ID));
						end;
					end else if (i = 1) then begin
						//タイマーON
						if (j = -1) then begin
							//新規スタート
							j := tm.TimerDef.IndexOf(tn.ID);
							if (j <> -1) then begin
								tr := tm.TimerDef.Objects[j] as NTimer;
								tr.Tick := timeGetTime();
								for k := 0 to tr.Cnt - 1 do begin
									tr.Done[k] := 0;
								end;
								tm.TimerAct.AddObject(tn.ID, tr);
								DebugOut.Lines.Add(Format('NPC Timer(%d) was started / Starting Timer(%d)', [tn.ID,tm.TimerAct.Count]));
							end;
						end else begin
							//再スタート
							tr := tm.TimerAct.Objects[j] as NTimer;
							tr.Tick := timeGetTime();
							for k := 0 to tr.Cnt - 1 do begin
								tr.Done[k] := 0;
							end;
							DebugOut.Lines.Add(Format('NPC Timer(%d) was re-started / Starting Timer(%d)', [tn.ID,tm.TimerAct.Count]));
						end;
					end;
					Inc(tc.ScriptStep);
				end;
			36: //addnpctimer
				begin
					i := -1;
					for k := 0 to tm.NPC.Count - 1 do begin
						tn1 := tm.NPC.Objects[k] as TNPC;
						if (tn1.Name = tn.Script[tc.ScriptStep].Data1[0]) then begin
							i := 0;
							break;
						end;
					end;
					if (i <> -1) then begin
						i := tn.Script[tc.ScriptStep].Data3[0];
						j := tm.TimerAct.IndexOf(tn1.ID);
						if (j <> -1) then begin
							tr := tm.TimerAct.Objects[j] as NTimer;
							if (i > 0) then tr.Tick := tr.Tick - cardinal(i)
							else tr.Tick := tr.Tick + cardinal(abs(i));
							if (tr.Tick > Tick) then tr.Tick := Tick;
							for k := 0 to tr.Cnt - 1 do begin
								if (i < 0) and (tr.Tick + cardinal(tr.Idx[k]) > Tick) then begin
									//過去のイベントを未実行にする
									tr.Done[k] := 0;
								end else if (i > 0) and (tr.Tick + cardinal(tr.Idx[k]) < Tick) then begin
									//未来のイベントを実行済にする
									tr.Done[k] := 1;
								end;
							end;
							DebugOut.Lines.Add(Format('NPC Timer(%d) was added (%d)ms', [tn.ID,i]));
						end;
					end;
					Inc(tc.ScriptStep);
				end;
			37: //return
				begin
					tc.ScriptStep := $FFFF;
					break;
				end;
			38: //warpallpc
				begin
					if (tn.Script[tc.ScriptStep].Data3[2] = 0) then begin
						//カレントMAPのキャラを転送
						tm := Map.Objects[Map.IndexOf(tn.Map)] as TMap;
						while (tm.CList.Count > 0) do begin
							tc1 := tm.CList.Objects[0] as TChara;
							if tc1.Login = 2 then begin
								SendCLeave(tc1, 2);
								tc1.tmpMap := tn.Script[tc.ScriptStep].Data1[0];
								tc1.Point := Point(tn.Script[tc.ScriptStep].Data3[0],tn.Script[tc.ScriptStep].Data3[1]);
								MapMove(tc1.Socket, tc1.tmpMap, tc1.Point);
							end;
						end;
					end else if (tn.Script[tc.ScriptStep].Data3[2] = 1) then begin
						//全ワールドのキャラを転送
						for j := 0 to CharaName.Count - 1 do begin
							tc1 := CharaName.Objects[j] as TChara;
							if tc1.Login = 2 then begin
								SendCLeave(tc1, 2);
								tc1.tmpMap := tn.Script[tc.ScriptStep].Data1[0];
								tc1.Point := Point(tn.Script[tc.ScriptStep].Data3[0],tn.Script[tc.ScriptStep].Data3[1]);
								MapMove(tc1.Socket, tc1.tmpMap, tc1.Point);
							end;
						end;
					end else begin
						//NPCチャットルーム内のキャラを転送
						if (tn.ChatRoomID <> 0) then begin
							i := ChatRoomList.IndexOf(tn.ChatRoomID);
							tcr := ChatRoomList.Objects[i] as TChatRoom;
							if (tcr.Users < 2) then continue;
							while (tcr.Users > 1) do begin
								tc1 := CharaPID.IndexOfObject(tcr.MemberID[1]) as TChara;
								if tc1.Login = 2 then begin
									SendCLeave(tc1, 2);
									tc1.tmpMap := tn.Script[tc.ScriptStep].Data1[0];
									tc1.Point := Point(tn.Script[tc.ScriptStep].Data3[0],tn.Script[tc.ScriptStep].Data3[1]);
									MapMove(tc1.Socket, tc1.tmpMap, tc1.Point);
								end;
							end;
						end;
					end;
					Inc(tc.ScriptStep);
				end;
			39: //waitingroom
				begin
					if (tn.ChatRoomID = 0) then begin
						tcr := TChatRoom.Create;
						tcr.Title := tn.Script[tc.ScriptStep].Data1[0];
						tcr.Limit := tn.Script[tc.ScriptStep].Data3[0];
						tcr.Pub := 1;

						tcr.MemberID[0] := tn.ID; //オーナー:0
						tcr.MemberCID[0] := tn.JID;
						tcr.MemberName[0] := tn.Name;
						ChatMaxID := ChatMaxID + 1;
						tcr.ID := ChatMaxID;
						tcr.Users := 1;
						tcr.NPCowner := 1;

						tn.ChatRoomID := tcr.ID;
						ChatRoomList.AddObject(tcr.ID, tcr);
						DebugOut.Lines.Add(Format('ChatRoomTitle = %s : OwnerID = %d : OwnerName = %s', [tcr.Title, tcr.MemberID[0], tcr.MemberName[0]]));

						//周辺にパケ送信
						w := Length(tcr.Title);
						WFIFOW(0, $00d7);
						WFIFOW(2, w + 17);
						WFIFOL(4, tcr.MemberID[0]);
						WFIFOL(8, tcr.ID);
						WFIFOW(12, tcr.Limit);
						WFIFOW(14, tcr.Users);
						WFIFOB(16, tcr.Pub);
						WFIFOS(17, tcr.Title, w);
						SendBCmd(tm, tn.Point, w + 17, nil);
					end;
					break;
				end;
			40: //enablenpc
				begin
					if Map.IndexOf(tn.Script[tc.ScriptStep].Data1[0]) = -1 then
						MapLoad(tn.Script[tc.ScriptStep].Data1[0]);
					tm1 := Map.Objects[Map.IndexOf(tn.Script[tc.ScriptStep].Data1[0])] as TMap;
					if (tn.Script[tc.ScriptStep].Data3[0] = 1) then begin
						//enable
						i := -1;
						for k := 0 to tm1.NPC.Count - 1 do begin
							tn1 := tm1.NPC.Objects[k] as TNPC;
							if (tn1.Name = tn.Script[tc.ScriptStep].Data1[1]) then begin
								i := 0;
								break;
							end;
						end;
						if (tn1.ScriptInitS <> -1) then begin
							//OnInitラベルを実行
							DebugOut.Lines.Add(Format('OnInit Event(%d)', [tn1.ID]));
							tc1 := TChara.Create;
							tc1.TalkNPCID := tn1.ID;
							tc1.ScriptStep := tn1.ScriptInitS;
							tc1.AMode := 3;
							tc1.AData := tn1;
							tc1.Login := 0;
							NPCScript(tc1,0,1);
							tn.ScriptInitD := true;
							tc1.Free;
						end;
						if (i = 0) and (tn1.Enable = false) then begin
							tn1.Enable := true;
							for j := tn1.Point.Y div 8 - 2 to tn1.Point.Y div 8 + 2 do begin
								for i := tn1.Point.X div 8 - 2 to tn1.Point.X div 8 + 2 do begin
									for k := 0 to tm1.Block[i][j].CList.Count - 1 do begin
										tc1 := tm1.Block[i][j].Clist.Objects[k] as TChara;
										if (abs(tc1.Point.X - tn1.Point.X) < 16) and (abs(tc1.Point.Y - tn1.Point.Y) < 16) then begin
											SendNData(tc1.Socket, tn1, tc1.ver2);
										end;
									end;
								end;
							end;
						end;
					end else begin
						//disable
						i := -1;
						for k := 0 to tm1.NPC.Count - 1 do begin
							tn1 := tm1.NPC.Objects[k] as TNPC;
							if (tn1.Name = tn.Script[tc.ScriptStep].Data1[1]) then begin
								i := 0;
								break;
							end;
						end;
						if (i = 0) and (tn1.Enable = true) then begin
							tn1.Enable := false;
							l := tm.TimerAct.IndexOf(tn1.ID);
							if (l <> -1) then begin
								DebugOut.Lines.Add(Format('NPC Timer(%d) was deleted / Remaining Timer(%d)', [tn.ID,tm.TimerAct.Count-1]));
								tm.TimerAct.Delete(tm.TimerAct.IndexOf(tn1.ID));
							end;
							for j := tn1.Point.Y div 8 - 2 to tn1.Point.Y div 8 + 2 do begin
								for i := tn1.Point.X div 8 - 2 to tn1.Point.X div 8 + 2 do begin
									for k := 0 to tm1.Block[i][j].CList.Count - 1 do begin
										tc1 := tm1.Block[i][j].Clist.Objects[k] as TChara;
										if (abs(tc1.Point.X - tn1.Point.X) < 16) and (abs(tc1.Point.Y - tn1.Point.Y) < 16) then begin
											WFIFOW(0, $0080);
											WFIFOL(2, tn1.ID);
											WFIFOB(6, 0);
											tc1.Socket.SendBuf(buf, 7);
										end;
									end;
								end;
							end;
						end;
					end;
					Inc(tc.ScriptStep);
				end;
			41: //resetmymob
				begin
					if Map.IndexOf(tn.Script[tc.ScriptStep].Data1[0]) <> -1 then begin
						tm1 := Map.Objects[Map.IndexOf(tn.Script[tc.ScriptStep].Data1[0])] as TMap;
						for i := tm1.Mob.Count -1 downto 0 do begin
							ts := tm1.Mob.Objects[i] as TMob;
							if (ts.isSummon = true) then begin
								if (tm1.CList.Count > 0) then begin
									WFIFOW( 0, $0080);
									WFIFOL( 2, ts.ID);
									WFIFOB( 6, 1);
									SendBCmd(tm1, ts.Point, 7);
								end;
								j := tm1.Block[ts.Point.X div 8][ts.Point.Y div 8].Mob.IndexOf(ts.ID);
								if (j <> -1) then tm1.Block[ts.Point.X div 8][ts.Point.Y div 8].Mob.Delete(j);
								j := tm1.Mob.IndexOf(ts.ID);
								if (j <> -1) then tm1.Mob.Delete(j);
							end;
						end;
					end;
					Inc(tc.ScriptStep);
				end;
			42: //getmapusers
				begin
					if Map.IndexOf(tn.Script[tc.ScriptStep].Data1[0]) <> -1 then begin
						tm1 := Map.Objects[Map.IndexOf(tn.Script[tc.ScriptStep].Data1[0])] as TMap;
						if (Copy(tn.Script[tc.ScriptStep].Data1[1], 1, 1) <> '\') then begin
							tc.Flag.Values[tn.Script[tc.ScriptStep].Data1[1]] := IntToStr(tm1.CList.Count);
						end else begin
							ServerFlag.Values[tn.Script[tc.ScriptStep].Data1[1]] := IntToStr(tm1.CList.Count);
						end;
					end;
					Inc(tc.ScriptStep);
				end;
			43: //setstr
				begin
					j := tn.Script[tc.ScriptStep].Data3[0];
					str := '';
					//右辺フラグチェック
					if (Copy(tn.Script[tc.ScriptStep].Data1[1], 1, 1) = '\') then begin
						//サーバ共有フラグ
						str := ServerFlag.Values[tn.Script[tc.ScriptStep].Data1[1]];
					end else begin
						i := -1;
						if (tc.Login = 2) then begin
							i := tc.Flag.IndexOfName(tn.Script[tc.ScriptStep].Data1[1]);
						end;
						if (i <> -1) then begin
							//キャラクターフラグ
							str := tc.Flag.Values[tn.Script[tc.ScriptStep].Data1[1]];
						end else begin
							//文字列
							str := tn.Script[tc.ScriptStep].Data1[1];
						end;
					end;

					//左辺フラグチェック
					if (Copy(tn.Script[tc.ScriptStep].Data1[0], 1, 1) = '\') then begin
						//サーバ共有フラグ
						if (j = 0) then begin
							ServerFlag.Values[tn.Script[tc.ScriptStep].Data1[0]] := str;
						end else begin
							ServerFlag.Values[tn.Script[tc.ScriptStep].Data1[0]] := ServerFlag.Values[tn.Script[tc.ScriptStep].Data1[0]] + str;
						end;
					end else if (tc.Login = 2) then begin
						//キャラクターフラグ
						if (j = 0) then begin
							tc.Flag.Values[tn.Script[tc.ScriptStep].Data1[0]] := str;
						end else begin
							tc.Flag.Values[tn.Script[tc.ScriptStep].Data1[0]] := tc.Flag.Values[tn.Script[tc.ScriptStep].Data1[0]] + str;
						end;
					end;
					Inc(tc.ScriptStep);
				end;
			44: //checkstr
				begin
					j := tn.Script[tc.ScriptStep].Data3[2];
					str := '';
					//右辺フラグチェック
					if (Copy(tn.Script[tc.ScriptStep].Data1[1], 1, 1) = '\') then begin
						//サーバ共有フラグ
						str := ServerFlag.Values[tn.Script[tc.ScriptStep].Data1[1]];
					end else begin
						i := -1;
						if (tc.Login = 2) then begin
							i := tc.Flag.IndexOfName(tn.Script[tc.ScriptStep].Data1[1]);
						end;
						if (i <> -1) then begin
							//キャラクターフラグ
							str := tc.Flag.Values[tn.Script[tc.ScriptStep].Data1[1]];
						end else begin
							//文字列
							str := tn.Script[tc.ScriptStep].Data1[1];
						end;
					end;

					flag := false;
					//左辺フラグチェック
					if (Copy(tn.Script[tc.ScriptStep].Data1[0], 1, 1) = '\') then begin
						//サーバ共有フラグ
						if (ServerFlag.Values[tn.Script[tc.ScriptStep].Data1[0]] = str) then begin
							flag := true;
						end;
					end else if (tc.Login = 2) then begin
						//キャラクターフラグ
						DebugOut.Lines.Add(Format('str-check: %s', [tc.Flag.Values[tn.Script[tc.ScriptStep].Data1[0]]]));
						if (tc.Flag.Values[tn.Script[tc.ScriptStep].Data1[0]] = str) then begin
							flag := true;
						end;
					end;

					DebugOut.Lines.Add(Format('str-check: %s %s %s(%s) = %d', [tn.Script[tc.ScriptStep].Data1[0], tn.Script[tc.ScriptStep].Data1[2], tn.Script[tc.ScriptStep].Data1[1], str, byte(flag)]));
					if ((j = 0) and (flag = true)) or ((j = 1) and (flag = false)) then begin
						tc.ScriptStep := tn.Script[tc.ScriptStep].Data3[0];
					end else begin
						tc.ScriptStep := tn.Script[tc.ScriptStep].Data3[1];
					end;
				end;
{NPCイベント追加ココまで}
			end;
			Inc(cnt);
		end;
		if cnt >= 100 then begin
			DebugOut.Lines.Add('script error!!! : infinity loop founded');
		end;
		if (tc.ScriptStep >= tn.ScriptCnt) or (cnt >= 100) then begin
			//スクリプト終了
			tc.AMode := 0;
		end;
	//end;
end;
//==============================================================================
end.
