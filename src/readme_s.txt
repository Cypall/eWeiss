"Weiss" the one of Network Game Transfer Protocol - Server
スクリプト仕様書
----------------------------------------------------------

ここでは、NPCスクリプトファイルの仕様について説明します。
スクリプトファイルは、scriptフォルダ内またはscriptフォルダ以下の、
拡張子が.txtのファイルであれば全て読み込みます。
書式はAthena系を真似ていますが、
これはできるだけ簡単にスクリプトを双方へ移植できるようにするためです。
ただ、細部は結構違います。特に条件判断やzeny、
アイテム操作は別関数ですので移植の際はご注意ください。
なお、Weissのスクリプト読み込みはいい加減にやってあるので(;´Д`)
ちょっとした書き間違いでエラーを吐いたり、
何も話さなかったり、Weissが暴走したりします。ご了承ください。





＜基本＞
スクリプトは、以下のような形式で書かれます。

//テストスクリプト
prontera.gat,154,195,4	script	カプラ職員	117,{
	cutin "kafra_01",2;
	mes "[カプラ職員]";
	mes "こんにちは〜";
	mes "カプラはいつでも、皆様のそばにあるんですわ〜♪";
	next
	menu "テスト1",LTest1,"テスト2",LTest2;
LTest1:
	mes "[カプラ職員]";
	mes "テストメッセージその1です。";
	cutin "kafra_02",255;
	close;
LTest2:
	mes "[カプラ職員]";
	mes "テストメッセージその2です。";
	cutin "kafra_02",255;
	close;
}

まず、1行目はwarpやshopとほぼ同じ書式です。
[マップ名],[X],[Y],[向き]	script	[NPC名前]	[NPCグラフィックID],{
"script"、NPCの名前の前後は、きちんとタブで区切ってください。
タブ区切り以外は認識しません。
また、NPCグラフィックIDの先にある",{"は無くても動きますが、
Athena系との互換性のため、必ずつけるようにしてください。
で、2行目以降がスクリプト(クリックしたときの処理)になります。

次に、最後の行については、"}"1文字ですね。
これは、ここまででスクリプトが終わりであることを表します。
Athena系では"}"はどこにあっても構いませんが、
Weissでは、必ず1行とって、その行に"}"だけを書いてください。
これ以外はスクリプトの終わりとして認識しません。

スクリプトについては、行末に";"が付きます。
Weissでは、コマンド(mesとかcloseとか)は必ず1行に1つだけ書いてください。
2つ以上書くと、その行がスクリプトエラーになります。

コメントは、行頭に#とか//とか適当なものを置いていれば、
コメントとして扱います。コメント行にタブを入れると
誤動作すると思いますので、コメント行にはタブを使わないでください。

"LTest1:"などは、ラベルです。メニューでのジャンプ先につかわれます。
行末に":"を書くことで、その行はコメント行として扱われます。
なお、特殊なラベルとして、"-"があります。これは、ラベルに移動せずに
そのまま次の行に処理を移します。
ラベルには、"-"(ハイフン)、コマンドは使用しないでください。
コマンド等と重複しないように、ラベルの頭文字は"L"にすることをお勧めします。
また、ラベルは大文字小文字を区別「しません」。ご注意ください。

スクリプトの行頭には、見やすいように任意数のタブを入れることができます。
推奨形式は、上のようにラベル以外を1段右にやっておくとよいかと思います。





＜コマンド＞
コマンドや変数は、大文字小文字を区別しません。
ただしマップ名やファイル名は大文字小文字を区別します。
必ず全て小文字で書いてください。

・mes "[message]";
メッセージウインドウに文字を表示します。
これを複数書くことで、複数行のメッセージを表示させることが可能です。
1行の文字数があまり長すぎると、不具合が出るかもしれません。

・next;
メッセージウインドウに、「NEXT」ボタンを表示させます。
メッセージの表示を一回きって、プレイヤーがボタンを押すのを待つ場合に使います。

・close;
メッセージウインドウに「CLOSE」ボタンを表示して、スクリプト処理を終了します。
スクリプトは、どんな場合でも必ず最後にcloseか、
後述のwarpコマンドを呼び出してください。
スクリプト終了処理がない場合、キャラが移動できない状態のままになります。

・menu "[text]",[label],"[text]",[label]・・・;
選択肢ウインドウを表示します。[text]がウインドウに表示させる文字、
[label]がその選択肢を選んだときに、処理をどのラベルに移動するかです。
選択肢の数はあまり多すぎるとクライアント側で不具合が出るかもしれません。

・goto [label];
スクリプト処理を、指定したラベルの所まで移動させます。

・cutin "[filename]",[flag];
カットイン(カプラさんの絵)を表示させます。[filename]は絵のファイル名で、
kafra_01〜kafra_06(コモドは07)までが使用できます。
拡張子はWeiss側で自動的に補完(.bmp)します。
また、[flag]は、2でカットイン表示、255でカットイン消去です。
カットインを表示させた場合は、スクリプト処理が終わるまでに、
必ずカットインを消去してください。
また、カットイン消去は、closeの手前で行うようにしてください。

・store;
倉庫ウインドウを表示させます。
このコマンドを実行すると、処理が倉庫ウインドウの方に移動します。
このコマンドの後は、(必要であれば)mesとcutinでのカットイン消去を行い、
最後に必ずcloseコマンドを書いてください。

・warp "[mapname]",[X],[Y];
キャラを他の場所へ移動させます。
ワープ先のマップや座標が存在するか、歩行可能な場所かどうかは
チェックしていませんので、あらかじめ移動先の場所に行き、
/whereコマンドでマップ名と座標を確認してそれを使用してください。

・save "[mapname]",[X],[Y];
キャラが死んだときのリスタート場所を設定します。
ワープ先のマップや座標が存在するか、歩行可能な場所かどうかは
チェックしていませんので、あらかじめ移動先の場所に行き、
/whereコマンドでマップ名と座標を確認してそれを使用してください。

・heal [HP+],[SP+];
キャラクターのHPとSPを指定量回復させます。
指定できる数値の最大はそれぞれ30000です。

・set [formula],[limit];
キャラクターの各種データを変更します。
キャラクターの各種データをチェックします。[formula]は、
[type][= + += - -=][val]の形式で指定します。
[type]は(Zeny,Job,BaseLevel,JobLevel,StatusPoint,SkillPoint)で、
これ以外はフラグとして認識されます。
typeとvalの間が[=]でtypeの値を[val]に変更(上書き)、
[+(+=)]か[-(-=)]でtypeの値に[val]を加算(減算)できます。
[val]にあまり大きな数値を入れると不具合が出るかもしれません。
また、[limit]に0以外の値を入れると、
[type]で指定した値の最大値を[limit]に制限します。

・additem [ItemID],[amount];
[ItemID]で指定されるアイテムを[Amount]個増やします。
装備を与えるときは、[amount]は必ず1にしてください。

・delitem [ItemID],[amount];
[ItemID]で指定されるアイテムを[Amount]個減らします。
装備を減らすときは、[amount]は必ず1にしてください。

・checkitem [ItemID],[amount],[label1],[label2];
[ItemID]で指定されるアイテムを[Amount]個以上持っていれば
[label1]のラベルへ、持っていなければ[label2]のラベルへジャンプします。
装備をチェックするときは、[amount]は必ず1にしてください。

・check [formula],[label1],[label2];
キャラクターの各種データをチェックします。[formula]は、
[type][<= >= = == <> != > <][val]の形式で指定します。
[type]は(Zeny,Job,BaseLevel,JobLevel,StatusPoint,SkillPoint)、
それ以外の文字はフラグとして認識されます。
式が成立すれば[label1]のラベルへ、
成立しなければ[label2]のラベルへジャンプします。
等号or不等号の左右は、スペースを入れても動きます。

・checkadditem [ItemID],[amount],[label1],[label2];
[ItemID]で指定されるアイテムを[Amount]個以上手に入れたとして、
重量オーバーにならないなら[label1]のラベルへ、
重量オーバーになるなら[label2]のラベルへジャンプします。
装備をチェックするときは、[amount]は必ず1にしてください。

・jobchange [job];
キャラの職業を変更します。[job]は数字で指定します。
なお、職業を変更すると、装備が全て解除されます。
（[job]の数値と実際のジョブの対応表）
0=ノービス
1=剣士
2=マジシャン
3=アーチャー
4=アコライト
5=商人
6=シーフ
7=ナイト
8=プリースト
9=ウィザード
10=ブラックスミス
11=ハンター
12=アサシン

・viewpoint [type],[X],[Y],[PointID],[color];
ミニマップ上に色の付いた点を表示します。
Athena系のものと同じ動作をするようにしていますが、
各パラメータの詳細などは不明です。情報求む。
なお、[color]は必ず16進表記で書いてください。
頭に"0x"か"$"が付いていても付いていなくても、16進数で読み込みます。





＜スクリプトラベル＞
・scriptlabel [scriptlabel];
・script [scriptlabel];
scriptlabelコマンドがスクリプトの先頭に書かれていると、
スクリプト全体は[scriptlabel]と言うスクリプトラベル(前述のラベルとは無関係、
重複可)を持つようになります。これを書いておくと、
他のスクリプトにscriptコマンド「のみ」を書くことで、
scriptlabelコマンドのあるNPCと全く同じ内容を話すことができるようになります。
なお、同じ事を喋らせるときは、NPCの名前をメッセージ中に入れないようにするか、
またはNPCの名前をみんな同じにするかしてください。
スクリプトラベルの参照は、同マップ内であれば別ファイルのものも使えます。
例）
prt_in.gat,178,92,2	script	管理人ギース	55,{
LStart:
	scriptlabel Dictionary;
	mes "今は王立図書館の開場準備期間です。"
	mes "それと、隣の図書館も同じく準備中です。"
	close;
}
prt_in.gat,175,50,2	script	アルバイト	71,{
	script Dictionary;
}





＜フラグについて＞
set、checkコマンドでは、フラグを使用することができます。
例えば、

	check F_SEWB = 1,-,LJoin;
	mes "下水前にワープします。";
	warp 〜〜〜;
LJoin:
	mes "貴方を地下水道掃除隊隊員に任命します。";
	mes "地下水道のゴキどもを狩り尽くしていただきたい。";
	set F_SEWB = 1;
	close;

こんな感じです。
なお、セーブする必要のない一時的なフラグ(カプラ利用権チェックなど)は、
フラグ名の頭に「@」をつけてください。頭に「@」が付くフラグは、
chara.txtに保存されません。
値が未設定のフラグの値は0になっています。
また、値が0のフラグはchara.txtに保存されません。





＜注意点＞
スクリプトの書き方によっては、無限ループが作成できるかと思います。
無限ループは一応チェックをして停止するようにしていますが、
最悪OSが固まったようになる可能性があります。
無限ループにはご注意ください。
また、コマンド名と引数の間には半角空白を1つ以上入れてください。
読み込み処理はだいぶ強化しましたが、
空白やタブを入れるとうまく動かないかもしれません。
あと、ラベルやスクリプトラベルは前方後方参照がかかっていますので、
ファイル中にどの順序で出てきても正常に認識します。





＜最後に＞
この説明だけでは不明なところも多いかと思いますので、
後は実際にスクリプトを書いてみたり、またはNPCスクリプトスレでご質問ください。
今後、ジョブ変更やそれに必要な装備解除、後精錬などを実装予定です。
こんなコマンドが欲しい、というものも、スクリプトスレへどうぞ。
ただ、全ての要望に応えることはできないかもしれません。
その点はあしからずご了承ください。
ではでは。(*ﾟ∀ﾟ)ノﾁﾝﾁｺｰﾚ!
