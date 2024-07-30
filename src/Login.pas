unit Login;



interface

uses
//Windows, Forms, Classes, SysUtils, Math, ScktComp, Common;
	Windows,Classes, SysUtils, ScktComp, Common, Database;

//==============================================================================
// 関数定義
		procedure sv1PacketProcess(Socket: TCustomWinSocket);
//==============================================================================


//==============================================================================
// 追加関数
//==============================================================================
// procedure sv1PacketProcessSub(Socket: TCustomWinSocket;w :word;userid:string;userpass  :string);
// パスワード確認→ログイン成功 処理
//             
//==============================================================================
// function sv1PacketProcessTo(Socket: TCustomWinSocket;w :word;userid:string;userpass  :string):Boolean;
// ログイン時にToplayer.txtを読み込み、データがあればplayer.txtに追加する、
// 再起動は必要ない
// (GMアカウント作成用かな)
//
//==============================================================================
// function sv1PacketProcessAdd(Socket: TCustomWinSocket;w :word;userid:string;userpass  :string):Boolean;
// ログイン時にaddplayer.txtを読み込み、データがあればplayer.txtに追加する、
// トランザクションIDは自動でつけられる
// 再起動は必要ない 
// (普通のアカウントはこっちで追加)
//





implementation
//==============================================================================
// ログインサーバーパケット処理

//ログイン成功
procedure sv1PacketProcessSub(Socket: TCustomWinSocket;w :word;userid:string;userpass  :string);
var
	tp        :TPlayer;
        count:integer;
begin

				tp := PlayerName.Objects[PlayerName.IndexOf(userid)] as TPlayer;
				if tp.Pass = userpass then begin

                                  {2重ログインチェック}
                                  if tp.Login = 1 then
                                  begin
                                    count := 0;

                                    while count < 8 do
                                    begin
                                      if (tp.CData[count] <> nil)and(tp.CData[count].Login <> 0) then
                                      begin
                                        //2重ログイン
			        	      WFIFOW( 0, $0081);
			       	              WFIFOB( 2, 08);
			         	      tp.CData[count].Socket.SendBuf(buf, 3);
                                               DebugOut.Lines.Add('Double Login.');
                                      end;
                                      inc(count);
                                    end;
                                  end;
                                  {2重ログインチェック　ここまで}

					tp.IP := Socket.RemoteAddress;
					tp.Login := 1;
					tp.LoginID1 := Random($7FFFFFFF) + 1;
					tp.LoginID2 := NowLoginID;
					Inc(NowLoginID);
					if NowLoginID >= 2000000000 then NowLoginID := 0;     
							DebugOut.Lines.Add('tp.ver2 = '+inttostr(w));
					//tp.ver2 := w;
					tp.ver2 := 9;

					WFIFOW( 0, $0069);
					WFIFOW( 2, 79);
					WFIFOL( 4, tp.LoginID1);
					WFIFOL( 8, tp.ID);
					WFIFOL(12, tp.LoginID2);
					WFIFOL(16, 0);
					WFIFOS(20, PChar(FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now)), 24);
					WFIFOW(44, 0);
					WFIFOB(46, tp.Gender); //sex 0=F 1=M
					WFIFOL(47, ServerIP);
					WFIFOW(51, sv2port);
					WFIFOS(53, ServerName, 20);
					WFIFOW(73, NowUsers);
					WFIFOW(75, 0);
					WFIFOW(77, 0);
					Socket.SendBuf(buf, 79);
				end else begin
					ZeroMemory(@buf[0],23);
					WFIFOW( 0, $006a);
					WFIFOB( 2, 1);
					Socket.SendBuf(buf, 23);
				end;
end;


//アカウント追加
// Toplayer.txtに書き込んだアカウントデータをそのまま取り込む
//
function sv1PacketProcessTo(Socket: TCustomWinSocket;w :word;userid:string;userpass  :string):Boolean;
var
	userdata  :string;
	count        :integer;
        addtxt :TextFile;
        txt :TextFile;
        tempList,tempList2:TStringList;
begin
  Result := False;
    //DataSave();
    tempList := TStringList.Create;  
    tempList2 := TStringList.Create;
    if FileExists(AppPath + 'Toplayer.txt') then begin
           tempList.LoadFromFile(AppPath + 'Toplayer.txt');

          if FileExists(AppPath + 'player.txt') then begin
           tempList2.LoadFromFile(AppPath + 'player.txt');

           tempList2.AddStrings(tempList);
           tempList2.SaveToFile(AppPath + 'player.txt');
            tempList.Clear;
            tempList.SaveToFile(AppPath + 'Toplayer.txt');
            Result := True;
          end;
     end;
end;

//アカウント追加
// addplayer.txtに書き込んだアカウントデータに
// トランザクションIDを付け直して取り込む
//
function sv1PacketProcessAdd(Socket: TCustomWinSocket;w :word;userid:string;userpass  :string):Boolean;
var
	userdata  :string;
	count        :integer;
        addtxt :TextFile;
        txt :TextFile;
begin
  Result := False;
           DataSave();

           sv1PacketProcessTo(Socket,w,userid,userpass);
           AssignFile(addtxt, AppPath + 'addplayer.txt');
           AssignFile(txt, AppPath + 'player.txt');
       	  if not FileExists(AppPath + 'player.txt') then begin
                   Rewrite(txt);
                   Writeln(txt, '##Weiss.PlayerData.0x0002');
          end else
          begin
            Append(txt);
          end;
          if FileExists(AppPath + 'addplayer.txt') then
          begin
            Reset(addtxt);
            count := 1;
						while not SeekEof(addtxt) do
            begin
              Readln(addtxt,userdata);
              Writeln(txt, inttostr(100100+PlayerName.Count+count)+','+userdata);
              DebugOut.Lines.Add('Account Creation');
              Writeln(txt, '0');
              inc(count);
            end;
            Flush(txt);  { テキストが実際にファイルに書き込まれたことを確かめる }
            CloseFile(txt);

            Rewrite(addtxt);
            Flush(addtxt);  { テキストが実際にファイルに書き込まれたことを確かめる }
						CloseFile(addtxt);

            PlayerName.Clear;
            Player.Clear;

						CharaName.Clear;
            Chara.Clear;
            PartyNameList.Clear;
{氏{箱追加}
						SummonMobList.Free;
						SummonIOBList.Free;
						SummonIOVList.Free;
						SummonICAList.Free;
						SummonIGBList.Free;
{氏{箱追加ココまで}
{NPCイベント追加}
						ServerFlag.Free;
						MapInfo.Free;
{NPCイベント追加ココまで}
{ギルド機能追加}
						GuildList.Clear;
{ギルド機能追加ココまで}
            PetList.Clear;
            DataLoad();

            if PlayerName.IndexOf(userid) = -1 then exit;
						sv1PacketProcessSub(Socket,w,userid,userpass);
            Result := True;
         end;
end;
//==============================================================================
// ログインサーバーパケット処理
procedure sv1PacketProcess(Socket: TCustomWinSocket);
var
	id        :integer;
	w         :word;
	l         :longword;
	len       :integer;
	userid    :string;
	userpass  :string;
        txt :TextFile;
begin
	len := Socket.ReceiveLength;

	if len >= 55 then begin
		Socket.ReceiveBuf(buf, len);
		if (buf[0] = $64) and (buf[1] = $0) then begin
			RFIFOL(2, l);
			//DebugOut.Lines.Add('ver1 ' + IntToStr(l));
			RFIFOW(54, w);
			userid := RFIFOS(6, 24);
			userpass := RFIFOS(30, 24);

			DebugOut.Lines.Add('1:Login ID = ' + userid + ' Pass = ' + userpass);
			DebugOut.Lines.Add('ver1 = ' + IntToStr(l) + ':ver2 = ' + IntToStr(w));
			id := PlayerName.IndexOf(userid);
			if id <> -1 then begin
                           sv1PacketProcessSub(Socket,w,userid,userpass);
			end else begin
                        if not sv1PacketProcessAdd(Socket,w,userid,userpass) then
                        begin

				ZeroMemory(@buf[0],23);
				WFIFOW( 0, $006a);
				WFIFOB( 2, 0);
				Socket.SendBuf(buf, 23);
                           end;
			end;
		end;
	end;
end;
//==============================================================================
end.
