unit Path;



interface

uses
	Windows, Common;

//==============================================================================
// 関数定義
		function  DirMove(tm:TMap; var xy:TPoint; Dir:byte; bb:array of byte):boolean;
		function  CanMove(tm:TMap; x0, y0, x1, y1:integer):boolean;
		procedure AddPath2(var aa:array of rHeap; var n:byte; rh:rHeap; x1, y1, x2, y2, dx, dy, dir, dist:integer);
		function  SearchPath2(var path:array of byte; tm:TMap; x1, y1, x2, y2:cardinal):byte;
		procedure PopHeap(var aa:array of rHeap;var n:byte);
		procedure PushHeap(var d:rHeap; var aa:array of rHeap;var n:byte);
		procedure UpHeap(x:byte; var aa:array of rHeap;var n:byte);
//==============================================================================










implementation
//==============================================================================
function DirMove(tm:TMap; var xy:TPoint; Dir:byte; bb:array of byte):boolean;
var
	i:integer;
	xy1:TPoint;
begin
	Result := false;
	for i := 0 to Length(bb) - 1 do begin
		xy1 := xy;
		case (bb[i] + Dir) mod 8 of
		0: begin           Inc(xy.Y); end;
		1: begin Dec(xy.X);Inc(xy.Y); end;
		2: begin Dec(xy.X);           end;
		3: begin Dec(xy.X);Dec(xy.Y); end;
		4: begin           Dec(xy.Y); end;
		5: begin Inc(xy.X);Dec(xy.Y); end;
		6: begin Inc(xy.X);           end;
		7: begin Inc(xy.X);Inc(xy.Y); end;
		end;
		if (tm.gat[xy.X][xy.Y] and 1) = 0 then begin
			xy := xy1;
			exit;
		end;
	end;
end;
//------------------------------------------------------------------------------
function CanMove(tm:TMap; x0, y0, x1, y1:integer):boolean;
var
	b1 :byte;
	b2 :byte;
begin
	Result := false;
	if (x0 - x1 < -1) or (x0 - x1 > 1) or (y0 - y1 < -1) or (y0 - y1 > 1) then exit;
	if (x1 < 0) or (y1 < 0) or (x1 >= tm.Size.X) or (y1 >= tm.Size.Y) then exit;
	b1 := tm.gat[x0][y0];
	if (b1 and 1) = 0 then exit;
	b1 := tm.gat[x1][y1];
  if (b1 and 1) = 0 then exit;
  if (x0 = x1) or (y0 = y1) then begin
    Result := true;
    exit;
  end;
  b1 := tm.gat[x0][y1];
  b2 := tm.gat[x1][y0];
	if ((b1 and 1) = 0) or ((b2 and 1) = 0) then exit;

  Result := true;
end;
//------------------------------------------------------------------------------
procedure AddPath2(var aa:array of rHeap; var n:byte; rh:rHeap; x1, y1, x2, y2, dx, dy, dir, dist:integer);
var
	x, y:integer;
	rh1	:rHeap;
	cost:word;
begin
	x := rh.mx + dx;
	if (x < 0) or (x > 30) then exit;
	y := rh.my + dy;
	if (y < 0) or (y > 30) then exit;
	cost := rh.cost2 + dist + (abs(x2 - (rh.x + dx)) + abs(y2 - (rh.y + dy))) * 10;
	if mm[x][y].cost <> 0 then begin
		//今までに同じ点があったならcostを比較し小さいなら新しいpathでその点を再登録
		if mm[x][y].cost > cost then begin
			rh1.x := rh.x + dx;
			rh1.y := rh.y + dy;
			rh1.mx := x;
			rh1.my := y;
			rh1.cost2 := rh.cost2 + dist;
			rh1.cost1 := cost;
			//rh1.dir := dir;
			CopyMemory(@rh1.path, @rh.path, rh.pcnt);
			rh1.pcnt := rh.pcnt + 1;
			rh1.path[rh.pcnt] := dir;
			mm[x][y].cost := cost;
			mm[x][y].pcnt := rh1.pcnt;
			CopyMemory(@mm[x][y].path, @rh1.path, rh1.pcnt);
			if mm[x][y].addr <> 0 then begin
				aa[mm[x][y].addr] := rh1;
				UpHeap(mm[x][y].addr, aa, n);
			end else begin
				mm[x][y].addr := n;
				PushHeap(rh1, aa, n);
			end;
		end;
	end else begin
			//同じ点がなければその点を登録
			rh1.x := rh.x + dx;
			rh1.y := rh.y + dy;
			rh1.mx := x;
			rh1.my := y;
			rh1.cost2 := rh.cost2 + dist;
			rh1.cost1 := cost;
			//rh1.dir := dir;
			CopyMemory(@rh1.path, @rh.path, rh.pcnt);
			rh1.pcnt := rh.pcnt + 1;
			rh1.path[rh.pcnt] := dir;
			mm[x][y].cost := cost;
			mm[x][y].pcnt := rh1.pcnt;
			CopyMemory(@mm[x][y].path, @rh1.path, rh1.pcnt);
			mm[x][y].addr := n + 1;
			PushHeap(rh1, aa, n);
	end;
end;
//------------------------------------------------------------------------------
function SearchPath2(var path:array of byte; tm:TMap; x1, y1, x2, y2:cardinal):byte;
var
	aa	:array[0..255] of rHeap;
	x, y:integer;
	rh	:rHeap;
	n		:byte;
	//cost:word;
	//str:string;
	//i:integer;
begin
	ZeroMemory(@aa, sizeof(aa));
	aa[1].x := x1;
	aa[1].y := y1;
	aa[1].mx := 15;
	aa[1].my := 15;
	aa[1].cost2 := 0;
	aa[1].cost1 := 1;
	//aa[1].dir := 0;
	aa[1].pcnt := 0;
	n := 1;
	ZeroMemory(@mm, sizeof(mm));
	mm[15][15].cost := 1;
	mm[15][15].addr := 1;
	
	while (n <> 0) and ((aa[1].x <> x2) or (aa[1].y <> y2)) do begin
		rh := aa[1];
		PopHeap(aa, n);
		if CanMove(tm, rh.x, rh.y, rh.x+1, rh.y-1) then
			AddPath2(aa, n, rh, x1, y1, x2, y2,  1, -1, 5, 14);
		if CanMove(tm, rh.x, rh.y, rh.x+1, rh.y  ) then
			AddPath2(aa, n, rh, x1, y1, x2, y2,  1,  0, 6, 10);
		if CanMove(tm, rh.x, rh.y, rh.x+1, rh.y+1) then
			AddPath2(aa, n, rh, x1, y1, x2, y2,  1,  1, 7, 14);
		if CanMove(tm, rh.x, rh.y, rh.x  , rh.y+1) then
			AddPath2(aa, n, rh, x1, y1, x2, y2,  0,  1, 0, 10);
		if CanMove(tm, rh.x, rh.y, rh.x-1, rh.y+1) then
			AddPath2(aa, n, rh, x1, y1, x2, y2, -1,  1, 1, 14);
		if CanMove(tm, rh.x, rh.y, rh.x-1, rh.y  ) then
			AddPath2(aa, n, rh, x1, y1, x2, y2, -1,  0, 2, 10);
		if CanMove(tm, rh.x, rh.y, rh.x-1, rh.y-1) then
			AddPath2(aa, n, rh, x1, y1, x2, y2, -1, -1, 3, 14);
		if CanMove(tm, rh.x, rh.y, rh.x  , rh.y-1) then
			AddPath2(aa, n, rh, x1, y1, x2, y2,  0, -1, 4, 10);
	end;
	if n = 0 then begin
		Result := 0;
		exit;
	end;
	{
			str := '';
			for i := 0 to aa[1].pcnt - 1 do
				str := str + IntToStr(aa[1].path[i]);
			DebugOut.Lines.Add(Format('search path ok (%d,%d)-(%d,%d) %s', [x1,y1,x2,y2,str]));
	}
	x := aa[1].mx;
	y := aa[1].my;
	if mm[x][y].cost <> 0 then begin
		CopyMemory(@path, @mm[x][y].path, mm[x][y].pcnt);
		Result := mm[x][y].pcnt;
	end else begin
		Result := 0;
	end;
end;
//------------------------------------------------------------------------------
// ヒープから最小の要素を削除する
procedure PopHeap(var aa:array of rHeap;var n:byte);
var
	i, j	:cardinal;
begin
	// ヒープが空でないことを確認する
	if n < 1 then exit;

	// ヒープの最小の要素を削除する
	mm[aa[1].mx][aa[1].my].addr := 0;

	// 根から初めて，節ｉが子をもっている限り繰り返す
	i := 1;
	while i <= (n div 2) do begin // 葉を持つ節は 1..n/2
		// 節ｉの子のうち、小さい方をｊとする
		j := i * 2;
		if (j+1 <= n) and (aa[j].cost1 >= aa[j+1].cost1) then Inc(j);
		// 節ｉに節ｊの値を入れて，節ｊに注目する
		aa[i] := aa[j];
		mm[aa[i].mx][aa[i].my].addr := i;
		i := j;
	end;

	// ヒープの最後の要素を節iに移動する
	if i <> n then begin
		aa[i] := aa[n];
		mm[aa[i].mx][aa[i].my].addr := i;
		Dec(n);
		UpHeap(i, aa, n);
	end else begin
		Dec(n);
	end;
end;
{
procedure PopHeap(var aa:array of rHeap;var n:byte);
var
	i, j	:cardinal;
	val		:cardinal;
	rh		:rHeap;
begin
	// ヒープが空でないことを確認する
	if n < 1 then exit;

	// ヒープの最後の要素を先頭に移動する
	mm[aa[1].mx][aa[1].my].addr := 0;
	aa[1] := aa[n];
	Dec(n);

	// 沈められる要素の値を val にセットしておく
	rh := aa[1];
	val := rh.cost1;

	// 根から初めて，節ｉが子をもっている限り繰り返す
	i := 1;
	while i <= (n div 2) do begin // 葉を持つ節は 1..n/2
		// 節ｉの子のうち、小さい方をｊとする
		j := i * 2;
		if (j+1 <= n) and (aa[j].cost1 >= aa[j+1].cost1) then Inc(j);
		// もし，親が子より大きくないという関係が成り立てば，
		// これ以上沈める必要はない
		if val <= aa[j].cost1 then break;
		// 節ｉに節ｊの値を入れて，節ｊに注目する
		aa[i] := aa[j];
		mm[aa[i].mx][aa[i].my].addr := i;
		i := j;
	end;

	//先頭にあった要素を節ｉに入れる
	aa[i] := rh;
	mm[aa[i].mx][aa[i].my].addr := i;
end;
}
//------------------------------------------------------------------------------
// ヒープに要素を登録する
procedure PushHeap(var d:rHeap; var aa:array of rHeap;var n:byte);
var
	i		:cardinal;
	val	:cardinal;
	rh		:rHeap;
begin
	Inc(n);
	aa[n] := d;

	// 浮かび上がらせる要素の値を val に入れておく
	rh := aa[n];
	val := rh.cost1;
	// 要素が根まで浮かび上がっていない，かつ
	// 「親が子より大きい」あいだ繰り返す
	i := n;
	while (i > 1) and (aa[i div 2].cost1 > val) do begin
		// 親の値を子に移す
		aa[i] := aa[i div 2];
		mm[aa[i].mx][aa[i].my].addr := i;
		i := i div 2;
	end;

	// 最終的な落ち着き先が決まった
	aa[i] := rh;
	mm[aa[i].mx][aa[i].my].addr := i;
end;
//------------------------------------------------------------------------------
// ヒープ中の x 番目の要素を必要な場所まで浮かび上がらせる
procedure UpHeap(x:byte; var aa:array of rHeap;var n:byte);
var
	i		:cardinal;
	val	:cardinal;
	rh		:rHeap;
begin
	// 浮かび上がらせる要素の値を val に入れておく
	rh := aa[x];
	val := rh.cost1;
	// 要素が根まで浮かび上がっていない，かつ
	// 「親が子より大きい」あいだ繰り返す
	i := x;
	while (i > 1) and (aa[i div 2].cost1 > val) do begin
		// 親の値を子に移す
		aa[i] := aa[i div 2];
		mm[aa[i].mx][aa[i].my].addr := i;
		i := i div 2;
	end;

	// 最終的な落ち着き先が決まった
	aa[i] := rh;
	mm[aa[i].mx][aa[i].my].addr := i;
end;
//==============================================================================
end.
