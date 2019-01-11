Unit BloxiEng;

Interface

Uses Dos, Graph, Crt;

Const
 MaxEnemies = 11; {Max 12 enemies}

Type
 PlayerType = Record
 x, y : ShortInt;
 end;

 EnemyType = Record
 Direction : String;
 x, y, Species : ShortInt;
 Enabled : Boolean;
 end;

var
 Map  : Array [0..11, 0..16] of ShortInt;
 Player : Array [0..1] of PlayerType;
 Enemy : Array [0..MaxEnemies] of EnemyType;
 Gamestate, Diamonds, Level, Lives : ShortInt;
 Points : Integer;
 s1, s2 : word;
 Shooter, WallTile, Boulder, BigWall, SmallWall, BloxiPlayer,
 Diamond, Exit, ExitOpen, Spider, ArrowLeft, ArrowRight : pointer;
 Start, Endtime : real;
 MapTitle : string;
 Noise : Boolean;

Procedure InitGraphics; {Initialize graphics}
Procedure DestroyApp; {Kills application, reset textmode}
Procedure ResetGame; {clear map, enemies, lives etc}
Function Str2Int(s:string):word; {String to Integer}
Function Int2Str(L : LongInt) : string; {Integer to String}
Function timer:real; {used for gametics/timer}
Procedure RestartGame;
Procedure RestartLevel;
Procedure EndLevel;
Function CheckMovement(x, y : integer; Initiator : String) : Boolean; {Checks if player/enemy/boulder can move}
Procedure AddPoints (Amount : integer); {Addpoints after diamond pick-up}
Procedure BloxiUp; {draws player up}
Procedure BloxiLeft;
Procedure BloxiRight;
Procedure BloxiDown;
Procedure DrawLevel; {redraw level}
Procedure ChangeLives(s : string); {add, remove or redraw lives}
Procedure PlayerDead;
Procedure CheckPlayerContact(i : integer); {checks player contact with enemy}
Procedure Enemymovement; {Decides if an enemy can move or not}
Procedure ShowMenu;
Procedure GamestateZeroKeys (Key : char); {Read the pressed keys}
Procedure GamestateOneKeys (Key : char); {Read the pressed keys}
Procedure RefreshScreen; {redraws map, gamestate to zero}
Procedure DrawEmpty(i, j : integer); {draws empty spot}
Procedure DrawWallTile(i, j : integer); {draws wall}
Procedure DrawWallLarge(i, j : integer);
Procedure DrawWallSmall(i, j : integer);
Procedure DrawBoulder(i, j : integer);
Procedure DrawDiamond(i, j : integer);
Procedure DrawSpider(i, j : integer); {Moving enemy}
Procedure DrawShooter(i, j : integer); {Static enemy}
Procedure DrawPlayer(i, j : integer);
Procedure DrawExit(i, j : integer);
Procedure DrawExitOpen(i, j : integer);
Procedure DrawArrowLeft(i, j : integer); {draws arrow from shooter}
Procedure DrawArrowRight(i, j : integer);
Procedure ActivateExit; {initiate DrawExitOpen, resets diamonds to 127}
Procedure DrawObject(i, j, Obj : integer); {chooses which object to be drawn}
Procedure ReadMap(level : integer); {reads map from levels.dat}
Procedure GenerateObjects; {generate enemies etc.}
Procedure DrawMap;
Procedure DrawHud;
Procedure GenerateGraphics; {draw graphics in left corner and puts it in pointer}
Procedure DiamondSound;
Procedure BoulderSound;
Procedure ExitSound;
Procedure ToggleSound;

Implementation

Procedure InitGraphics; {Initialize CGA graphics}
var
 gd, gm : Integer;
begin
 gm:=CGAC3;
 gd:=CGA;
 initgraph(gd, gm, 'system');
 gd:=graphresult;
 if gd<>grOK then
 begin
  writeln('Error in initializing graphic card! The error is');
  writeln(grapherrormsg(gd)); halt;
 end;
end;

Procedure DestroyApp; {Closes the application}
begin
 CloseGraph;
 TextColor(7);
 TextBackground(0);
 {Halt;}
 Gotoxy(1,1);
 Writeln('Thank you for playing Bloxinies.');
end;

Procedure ResetGame; {Reset enemies, clear map, reset lives etc}
var
 i, j : integer;
begin
 for i:=0 to 11 do
  begin
   for j:=0 to 16 do Map[i,j] :=0;
  end;

 for i:=0 to MaxEnemies do
  begin
   Enemy[i].Direction:='Right';
   Enemy[i].Enabled:=FALSE;
  end;

  {Reset total number of diamonds in map}
  Diamonds:=0;

  {First level}
  Level:=0;
  Lives:=3;
end;

Function Str2Int(s:string):word;
var
 i, code : word;
begin
 val (s, i, code);
 if code <> 0 then Str2Int:=0 else Str2Int:=i;
end;

Function Int2Str(L : LongInt) : string;
var
 s : string;
begin
 Str(L, S);
 Int2Str:=s;
end;

{Timer to move enemy every second}
Function timer:real;
var
 Hour, Minute, Second, Sec100 : word;
begin
     gettime(hour,minute,second,sec100);
     timer:=(hour*3600.0+minute*60.0+second+sec100/100)
end;

Procedure RestartGame;
begin
 ResetGame; {Clears map, enemies, level to 0, etc}
 SetFillStyle(1,0);
 Bar(10,80,30,90);
 ChangeLives('Redraw');
 ReadMap(Level); {Read map with active level; level 0 in this case}
 SetFillStyle(1,0);
 Bar(10,21,30,29);
 Points:=0;
 SetFillStyle(1,0);
 Bar(10,51,30,59);
 SetColor(1);
 OutTextXY(10,49,Int2Str(Points));
 DrawLevel;
 GenerateObjects;
 DrawMap;
 Gamestate:=0; {Running state}
end;

Procedure RestartLevel;
begin
 ReadMap(Level);
 ChangeLives('Remove');
 GenerateObjects;
 DrawMap;
 Gamestate:=0;
end;

Procedure Endlevel;
begin
 Level:=Level+1;
 ReadMap(Level);
 DrawLevel;
 GenerateObjects;
 DrawMap;
 {Gamestate:=0;}
end;

{Checks movement of players, enemies, moveable objects and returns FALSE if they can't move}
Function CheckMovement(x, y : integer; Initiator : String) : Boolean;
var
 i : integer;
begin
 CheckMovement:=TRUE;
 {Can't move into walls}
 if (Map[x,y] = 1) or (Map[x,y] = 2) or (Map[x,y] = 3) or
    (Map[x,y] = 7) or (Map[x,y] = 8) or (Map[x,y] = 9) then CheckMovement:=FALSE;
 if (x > 11) or (x < 0) or (y < 0) or (y > 16) then CheckMovement:=FALSE;

 if (Initiator = 'Human') then
  begin {Player moved}

   {Boulder movement-logic; actually misplaced here but it works}
   if (Map[x,y] = 4) then
    begin {Move boulder}
     if (Player[0].y < y) then
      begin {Player downwards}
       if (CheckMovement(x,y+1,'Boulder') = TRUE) then
        begin {Move boulder}
         if Noise = TRUE then BoulderSound;
         DrawBoulder(x,y+1);
         Map[x,y]:=0;
         Map[x,y+1]:=4;
        end else CheckMovement:=FALSE;
      end;

      if (Player[0].y > y) then
      begin {Player upwards}
        if (CheckMovement(x,y-1,'Boulder') = TRUE) then
         begin {Move boulder}
          if Noise = TRUE then BoulderSound;
          DrawBoulder(x,y-1);
          Map[x,y]:=0;
          Map[x,y-1]:=4;
         end else CheckMovement:=FALSE;
      end;

      if (Player[0].x < x) then
      begin {Player down?}
        if (CheckMovement(x+1,y,'Boulder') = TRUE) then
         begin {Move boulder}
          if Noise = TRUE then BoulderSound;
          DrawBoulder(x+1,y);
          Map[x,y]:=0;
          Map[x+1,y]:=4;
         end else CheckMovement:=FALSE;
      end;

      if (Player[0].x > x) then
      begin {Player right}
        if (CheckMovement(x-1,y,'Boulder') = TRUE) then
         begin {Move boulder}
          if Noise = TRUE then BoulderSound;
          DrawBoulder(x-1,y);
          Map[x,y]:=0;
          Map[x-1,y]:=4;
         end else CheckMovement:=FALSE;
      end;
    end;
    {Boulder movement-logic end}

   if (Map[x,y] = 6) then
    begin {Diamond grabbed}
     Map[x,y] := 0;
     AddPoints(10);
     if Noise = TRUE then DiamondSound;
    end;

   {Player can move into exit when all diamonds are grabbed}
   if (Map[x,y] = 9) and (Diamonds = 127) then
    begin
     CheckMovement:=FALSE;
     if Noise=TRUE then ExitSound;
     EndLevel;
    end;
  end;

 if (Initiator = 'Enemy') then
  begin {Enemy moved}
   if (Map[x,y] = 4) or (Map[x,y] = 6) or (Map[x,y] = 9) then CheckMovement:=FALSE;
   for i:=0 to MaxEnemies do if (Enemy[i].Enabled = TRUE) and (Enemy[i].x = x) and (Enemy[i].y=y) then CheckMovement:=FALSE;
  end;

 if (Initiator = 'Boulder') then
  begin {Boulder moved}
   if (Map[x,y] = 4) or (Map[x,y] = 6) then CheckMovement:=FALSE;
   for i:=0 to MaxEnemies do if (Enemy[i].Enabled = TRUE) and (Enemy[i].x = x) and (Enemy[i].y=y) then CheckMovement:=FALSE;
  end;
end;

Procedure AddPoints (Amount : integer);
begin
 SetColor(0);
 OutTextXY(10,49,Int2Str(Points));
 Points:=Points+Amount;
 SetColor(1);
 OutTextXY(10,49,Int2Str(Points));
 Diamonds:=Diamonds-1;
 if (Points = 500) then ChangeLives('Add');
 if (Points = 1000) then ChangeLives('Add');
 if (Points = 1500) then ChangeLives('Add');
 if (Points = 2000) then ChangeLives('Add');
 if (Points = 2500) then ChangeLives('Add');
 if (Points = 3000) then ChangeLives('Add');
 if (Points = 3500) then ChangeLives('Add');
 if (Points = 4000) then ChangeLives('Add');
end;

Procedure BloxiUp;
var
 i : integer;
begin
 if (CheckMovement(Player[0].x-1, Player[0].y,'Human') = TRUE) then
  begin { Bloxi can move up}
   DrawEmpty(Player[0].x,Player[0].y);
   Player[0].x:=Player[0].x-1;
   DrawPlayer(Player[0].x,Player[0].y);
   for i:=0 to MaxEnemies do CheckPlayerContact(i);
  end;
end;

Procedure BloxiLeft;
var
 i : integer;
begin
 if (CheckMovement(Player[0].x, Player[0].y-1, 'Human') = TRUE) then
  begin { Bloxi can move up}
   DrawEmpty(Player[0].x,Player[0].y);
   Player[0].y:=Player[0].y-1;
   DrawPlayer(Player[0].x,Player[0].y);
   for i:=0 to MaxEnemies do CheckPlayerContact(i);
  end;
end;

Procedure BloxiRight;
var
 i : integer;
begin
 if (CheckMovement(Player[0].x, Player[0].y+1, 'Human') = TRUE) then
  begin { Bloxi can move up}
   DrawEmpty(Player[0].x,Player[0].y);
   Player[0].y:=Player[0].y+1;
   DrawPlayer(Player[0].x,Player[0].y);
   for i:=0 to MaxEnemies do CheckPlayerContact(i);
  end;
end;

Procedure BloxiDown;
var
 i : integer;
begin
 if (CheckMovement(Player[0].x+1, Player[0].y, 'Human') = TRUE) then
  begin { Bloxi can move up}
   DrawEmpty(Player[0].x,Player[0].y);
   Player[0].x:=Player[0].x+1;
   DrawPlayer(Player[0].x,Player[0].y);
   for i:=0 to MaxEnemies do CheckPlayerContact(i);
  end;
end;

Procedure DrawLevel;
begin
 SetColor(0);
 OutTextXY(18,19,Int2Str(Level));
 SetColor(1);
 OutTextXY(18,19,Int2Str(Level+1));
end;

Procedure ChangeLives(s : string);
begin
 if not (s = 'Redraw') then
  begin
   SetColor(0);
   OutTextXY(19,79,Int2Str(Lives));
   if (s = 'Add') then Lives:=Lives+1;
   if (s = 'Remove') then Lives:=Lives-1;
  end;
   SetColor(1);
   OutTextXY(19,79,Int2Str(Lives));
end;

Procedure PlayerDead;
begin
 RestartLevel;
end;

Procedure CheckPlayerContact(i : integer); {Checks if player comes into contact with enemy}
var
 j, Step : integer;
 Obstacle : Boolean;
begin
 if (Enemy[i].Enabled = TRUE) then
  begin
   if (Enemy[i].Species = 7) {Spiders}
    then
     begin
      if ((Enemy[i].x=Player[0].x) and (Enemy[i].y=Player[0].y)) then PlayerDead;
      if ((Enemy[i].x=Player[0].x+1) and (Enemy[i].y=Player[0].y)) then PlayerDead;
      if ((Enemy[i].x=Player[0].x-1) and (Enemy[i].y=Player[0].y)) then PlayerDead;
      if ((Enemy[i].x=Player[0].x) and (Enemy[i].y=Player[0].y+1)) then PlayerDead;
      if ((Enemy[i].x=Player[0].x) and (Enemy[i].y=Player[0].y-1)) then PlayerDead;
     end;

 {Check shooter contact}
 if (Enemy[i].Species = 8) then
  begin
   if ((Enemy[i].x = Player[0].x) and (Enemy[i].y < Player[0].y)) then
    begin
     Obstacle:=FALSE;
     for j:=Enemy[i].y to Player[0].y do
      begin
       if (Map[Enemy[i].x,j] = 1) or (Map[Enemy[i].x,j] = 2) or (Map[Enemy[i].x,j] = 3) or
          (Map[Enemy[i].x,j] = 4) or (Map[Enemy[i].x,j] = 6) or (Map[Enemy[i].x,j] = 9) or
          (Map[Enemy[i].x,j] = 7) then
          begin
           {Obstacle found}
           Obstacle:=TRUE;
          end;
      end;
     if Obstacle=FALSE then
      begin
       Step:=0;
       for j:=Enemy[i].y+1 to Player[0].y do
        begin
         DrawArrowRight(Enemy[i].x,j);
         if Noise = TRUE then
          begin
           Sound(50*Step);
           Inc(Step);
          end;
         Delay(25);
         NoSound;
         DrawEmpty(Enemy[i].x,j);
        end;
       PlayerDead;
      end;
    end;

   if ((Enemy[i].x = Player[0].x) and (Enemy[i].y > Player[0].y)) then
    begin
     Obstacle:=FALSE;
     for j:=Player[0].y to Enemy[i].y do
      begin
       if (Map[Enemy[i].x,j] = 1) or (Map[Enemy[i].x,j] = 2) or (Map[Enemy[i].x,j] = 3) or
          (Map[Enemy[i].x,j] = 4) or (Map[Enemy[i].x,j] = 6) or (Map[Enemy[i].x,j] = 7) or
          (Map[Enemy[i].x,j] = 9) then
          begin
           {Obstacle found}
           Obstacle:=TRUE;
          end;
      end;
     if Obstacle=FALSE then
      begin
       Step:=0;
       j:=Enemy[i].y-1;
       Repeat
         DrawArrowLeft(Enemy[i].x,j);
         if Noise = TRUE then
          begin
           Sound(50*Step);
           Inc(Step);
          end;
         Delay(25);
         NoSound;
         DrawEmpty(Enemy[i].x,j);
        j:=j-1;
       until j=Player[0].y-1;
       PlayerDead;
      end;
    end;
  end;
end;
end;

Procedure Enemymovement; {Moves enemy around; enemy walks and turn to right if it blocks}
var
i : integer;

begin
for i:=0 to MaxEnemies do
 begin
  if (Enemy[i].Enabled = TRUE) and (Enemy[i].Species = 7) then
   begin
    if (Enemy[i].Direction = 'Right') then
     begin
      if (CheckMovement(Enemy[i].x,Enemy[i].y+1, 'Enemy') = TRUE) then
       begin
        Map[Enemy[i].x,Enemy[i].y]:=0;
        DrawEmpty(Enemy[i].x, Enemy[i].y);
        Enemy[i].y:=Enemy[i].y+1;
        Map[Enemy[i].x,Enemy[i].y]:=7;
        DrawSpider(Enemy[i].x, Enemy[i].y);
	CheckPlayerContact(i);
       end else Enemy[i].Direction := 'Up';
     end;
   end;

  if (Enemy[i].Enabled = TRUE) and (Enemy[i].Species = 7) then
   begin
    if (Enemy[i].Direction = 'Up') then
     begin
      if (CheckMovement(Enemy[i].x-1,Enemy[i].y, 'Enemy') = TRUE) then
       begin
        Map[Enemy[i].x,Enemy[i].y]:=0;
        DrawEmpty(Enemy[i].x, Enemy[i].y);
        Enemy[i].x:=Enemy[i].x-1;
        Map[Enemy[i].x,Enemy[i].y]:=7;
        DrawSpider(Enemy[i].x, Enemy[i].y);
	CheckPlayerContact(i);
       end else Enemy[i].Direction := 'Left';
     end;
   end;

  if (Enemy[i].Enabled = TRUE) and (Enemy[i].Species = 7) then
   begin
    if (Enemy[i].Direction = 'Left') then
     begin
      if (CheckMovement(Enemy[i].x,Enemy[i].y-1, 'Enemy') = TRUE) then
       begin
        Map[Enemy[i].x,Enemy[i].y]:=0;
        DrawEmpty(Enemy[i].x, Enemy[i].y);
        Enemy[i].y:=Enemy[i].y-1;
        Map[Enemy[i].x,Enemy[i].y]:=7;
        DrawSpider(Enemy[i].x, Enemy[i].y);
	CheckPlayerContact(i);
       end else Enemy[i].Direction := 'Down';
     end;
   end;

  if (Enemy[i].Enabled = TRUE) and (Enemy[i].Species = 7) then
   begin
    if (Enemy[i].Direction = 'Down') then
     begin
      if (CheckMovement(Enemy[i].x+1,Enemy[i].y, 'Enemy') = TRUE) then
       begin
        Map[Enemy[i].x,Enemy[i].y]:=0;
        DrawEmpty(Enemy[i].x, Enemy[i].y);
        Enemy[i].x:=Enemy[i].x+1;
        Map[Enemy[i].x,Enemy[i].y]:=7;
        DrawSpider(Enemy[i].x, Enemy[i].y);
	CheckPlayerContact(i);
       end else
        begin {Move enemy to the right to avoid cycle-delay}
         Enemy[i].Direction := 'Right';
         if (CheckMovement(Enemy[i].x,Enemy[i].y+1, 'Enemy') = TRUE) then
          begin
           Map[Enemy[i].x,Enemy[i].y]:=0;
           DrawEmpty(Enemy[i].x, Enemy[i].y);
           Enemy[i].y:=Enemy[i].y+1;
           Map[Enemy[i].x,Enemy[i].y]:=7;
           DrawSpider(Enemy[i].x, Enemy[i].y);
	   CheckPlayerContact(i);
          end;
        end;
     end;
   end;

 end;
end;

Procedure ShowMenu;
begin
 GameState:=1;
 SetFillStyle(1,0);
 Bar(78,48,242,152);
 SetColor(3);
 Rectangle(80,50,240,150);
 Rectangle(78,48,242,152);
 SetColor(1);
 Outtextxy(120,55,'Bloxinies menu');
 SetColor(3);
 Outtextxy(85,70,'   F1: this menu');
 Outtextxy(85,80,'   F2: restart level');
 Outtextxy(85,90,'   F3: start new game');
 Outtextxy(85,100,'   F4: toggle sound');
 Outtextxy(85,110,'   F8: leave menu');
 Outtextxy(85,135,'ESC/Q: quit game');
end;

Procedure GamestateZeroKeys (Key : char); {Read the pressed keys from the active game}
begin
 case Key of
  'H': BloxiUp;
  'K': BloxiLeft;
  'M': BloxiRight;
  'P': BloxiDown;
  '+': EndLevel;
  ';': ShowMenu;
  #59: ShowMenu;
  #60: RestartLevel;
  #61: RestartGame;
  #62: ToggleSound;
  'Q': Gamestate:=3;
  'q': Gamestate:=3;
  #27: Gamestate:=3;
  end;
end;

Procedure GamestateOneKeys (Key : char); {Read the pressed keys in menu}
begin
 case Key of
 #62: ToggleSound;
 #66: RefreshScreen;
 #27: Gamestate:=3;
 'q': Gamestate:=3;
 end;
end;

Procedure RefreshScreen; {Redraw map without changing level, enemies, etc}
begin
 DrawMap;
 Gamestate:=0;
end;

Procedure DrawEmpty(i, j : integer); {Draw empty tile}
begin
 SetFillStyle(1,0);
 Bar(48+(j*16),0+(i*16),48+15+(j*16),15+(i*16));
end;

Procedure DrawWallTile(i, j : integer); {Draw wall tile}
begin
 PutImage(48+(j*16),0+(i*16),WallTile^,0);
end;

Procedure DrawWallLarge(i, j : integer);
begin
 PutImage(48+(j*16),0+(i*16),BigWall^,0);
end;

Procedure DrawWallSmall(i, j : integer);
begin
 PutImage(48+(j*16),0+(i*16),SmallWall^,0);
end;

Procedure DrawBoulder(i, j : integer);
begin
 PutImage(48+(j*16),0+(i*16),Boulder^,0);
end;

Procedure DrawDiamond(i, j : integer);
begin
 PutImage(48+(j*16),0+(i*16),Diamond^,0);
end;

Procedure DrawSpider(i, j : integer);
begin
 PutImage(48+(j*16),0+(i*16),Spider^,0);
end;

Procedure DrawShooter(i, j : integer);
begin
 PutImage(48+(j*16),0+(i*16),Shooter^,0);
end;

Procedure DrawPlayer(i, j : integer);
begin
 PutImage(48+(j*16),0+(i*16),BloxiPlayer^,0);
 Player[0].x:=i;
 Player[0].y:=j;
end;

Procedure DrawExit(i, j : integer);
begin
 PutImage(48+(j*16),0+(i*16),Exit^,0);
end;

Procedure DrawExitOpen(i, j : integer);
begin
 PutImage(48+(j*16),0+(i*16),ExitOpen^,0);
end;

Procedure DrawArrowLeft(i, j : integer);
begin
 PutImage(48+(j*16),0+(i*16),ArrowLeft^,0);
end;

Procedure DrawArrowRight(i, j : integer);
begin
 PutImage(48+(j*16),0+(i*16),ArrowRight^,0);
end;

Procedure ActivateExit; {Activates exit}
var
 i, j : integer;
begin
for i:=0 to 11 do
 begin
  for j:=0 to 16 do
   begin
    if (Map[i,j] = 9) then
     begin
      DrawExitOpen(i,j);
      Diamonds:=127;
     end;
   end;
 end;
end;

Procedure DrawObject(i, j, Obj : integer); {Is used in DrawMap to draw Objects}
begin
 if Obj = 0 then DrawEmpty(i,j);
 if Obj = 1 then DrawWallTile(i,j);
 if Obj = 2 then DrawWallLarge(i,j);
 if Obj = 3 then DrawWallSmall(i,j);
 if Obj = 4 then DrawBoulder(i,j);
 if Obj = 5 then DrawPlayer(i,j);
 if Obj = 6 then DrawDiamond(i,j);
 if Obj = 7 then DrawSpider(i,j);
 if Obj = 8 then DrawShooter(i,j);
 if Obj = 9 then DrawExit(i,j);
end;

Procedure ReadMap(level : integer);
var
 Row : string;
 f : text;
 i,j : integer;
begin
 Assign(f,'LEVELS.DAT');
 Reset(f);
 for j:=0 to level*13 do
  begin {Read ahead on file to select correct level}
   Readln(f,MapTitle);
   if (MapTitle = '') then Gamestate:=2; {If maptitle is empty all levels are finished}
  end;
 j:=0;
 Repeat
 Readln(f,Row);
  for i:=0 to 16 do
   begin
    Map[j,i]:=Str2Int(Copy(Row,i+1,1));
   end;
 Inc(j);
 Until j=13+(level*1);
 Close(f);
end;

Procedure GenerateObjects;
var
 i, j, k : integer;
 RunOnce : Boolean;
begin
 {Reset enemies and diamonds}
 i:=0;
 for i:=0 to MaxEnemies do
  begin
   Enemy[i].Direction:='Right';
   Enemy[i].Enabled:=FALSE;
   Enemy[i].Species:=0;
  end;
i:=0;
Diamonds:=0;

for i:=0 to 11 do
 begin
  for j:=0 to 16 do
   begin
     if (Map[i,j] = 6) then
      begin {Diamond}
       Diamonds:=Diamonds+1;
      end;

     if (Map[i,j] = 7) then
      begin {Spider}
       RunOnce:=FALSE;
       for k:=0 to MaxEnemies do
        begin
         if (Enemy[k].Enabled = FALSE) and (RunOnce = FALSE) then
          begin
	   RunOnce:=TRUE;
           Enemy[k].x:=i;
           Enemy[k].y:=j;
           Enemy[k].Enabled:=TRUE;
           Enemy[k].Species:=7;
           Enemy[k].Direction:='Right';
           Map[i,j] := 0;
          end;
        end;
      end; {Spider end}

      if Map[i,j] = 8 then
	begin {Snake}
        RunOnce:=FALSE;
	 for k:=0 to MaxEnemies do
	  begin
	   if (Enemy[k].Enabled = FALSE) and (RunOnce = FALSE) then
	    begin
             RunOnce:=TRUE;
             Enemy[k].x:=i;
             Enemy[k].y:=j;
             Enemy[k].Enabled:=TRUE;
             Enemy[k].Species:=8;
            end;
	  end;
         end; {Snake end}

   end;
 end;
end;

Procedure DrawMap; {Draw the map}
var
 i, j : integer;
begin
for i:=0 to 11 do
 begin
  for j:=0 to 16 do
   begin
    DrawObject(i,j,Map[i,j]);
   end;
 end;
end;

Procedure DrawHud;
begin
SetColor(2);
Settextstyle(SmallFont,HorizDir,4);
Line(5,16,8,16);
Line(38,16,41,16);
Line(4,17,4,30);
Line(42,17,42,30);
Line(5,31,41,31);
OutTextXY(10,10,'Level');
DrawLevel;
SetColor(2);

Line(5,46,8,46);
Line(40,46,41,46);
Line(4,47,4,60);
Line(42,47,42,60);
Line(5,61,41,61);
OutTextXY(10,40,'Score');
SetColor(1);
OutTextXY(10,49,'0');
SetColor(2);

Line(5,76,8,76);
Line(38,76,41,76);
Line(4,77,4,90);
Line(42,77,42,90);
Line(5,91,41,91);
OutTextXY(10,70,'Lives');
OutTextXY(19,79,'');
ChangeLives('Redraw');
Rectangle(0,190,47,0);
PutPixel(0,0,0);
PutPixel(0,190,0);
PutPixel(47,0,0);
PutPixel(47,190,0);

Outtextxy(3,176,'F1:Menu');
Outtextxy(149,189,'Bloxinies');
end;

Procedure GenerateGraphics; {Generate the graphics and make sprites}
begin
{0 black, 1 green, 2 red, 3 brown}
{Border}
SetColor(1);
Line(0,17,0,0);
Line(17,17,0,17);
Line(17,0,17,17);
Line(0,0,17,0);
OutTextXY(0,20,'Generating Graphics ...');

{Inhoud}
SetFillStyle(1,1);
Bar(1,1,16,16);
SetColor(0);
Line(1,8,16,8);
Line(8,8,8,16);
Line(16,1,16,7);
Line(0,16,16,16);
PutPixel(1,7,0);
PutPixel(1,1,0);
PutPixel(15,1,0);
PutPixel(15,7,0);
PutPixel(7,9,0);
PutPixel(7,15,0);
PutPixel(9,9,0);
PutPixel(9,15,0);

s1:=imagesize(0,0,15,15);
getmem(BigWall,s1);
getimage(1,1,16,16,BigWall^);

{Clear}
SetFillStyle(1,0);
Bar(0,0,19,17);

SetColor(3);
{small wall}
line(1,1,16,1); {Brown lines}
line(1,5,16,5);
line(1,9,16,9);
line(1,13,16,13);
PutPixel(5,1,0); {Black spots}
PutPixel(13,1,0);
PutPixel(1,5,0);
PutPixel(9,5,0);
PutPixel(5,9,0);
PutPixel(13,9,0);
PutPixel(1,13,0);
PutPixel(9,13,0);
PutPixel(4,2,3); {Brown pixels}
PutPixel(12,2,3);
PutPixel(8,6,3);
PutPixel(16,6,3);
PutPixel(4,10,3);
PutPixel(12,10,3);
PutPixel(8,14,3);
PutPixel(16,14,3);
PutPixel(1,2,2); {Red pixels}
PutPixel(3,2,2);
PutPixel(7,2,2);
PutPixel(9,2,2);
PutPixel(11,2,2);
PutPixel(15,2,2);
PutPixel(2,3,2);
PutPixel(4,3,2);
PutPixel(6,3,2);
PutPixel(8,3,2);
PutPixel(10,3,2);
PutPixel(12,3,2);
PutPixel(14,3,2);
PutPixel(16,3,2);

PutPixel(3,6,2); {Red pixels 2nd row}
PutPixel(5,6,2);
PutPixel(7,6,2);
PutPixel(11,6,2);
PutPixel(13,6,2);
PutPixel(15,6,2);
PutPixel(2,7,2);
PutPixel(4,7,2);
PutPixel(6,7,2);
PutPixel(8,7,2);
PutPixel(10,7,2);
PutPixel(12,7,2);
PutPixel(14,7,2);
PutPixel(16,7,2);

PutPixel(1,10,2); {Red pixels 3rd row}
PutPixel(3,10,2);
PutPixel(7,10,2);
PutPixel(9,10,2);
PutPixel(11,10,2);
PutPixel(15,10,2);
PutPixel(2,11,2);
PutPixel(4,11,2);
PutPixel(6,11,2);
PutPixel(8,11,2);
PutPixel(10,11,2);
PutPixel(12,11,2);
PutPixel(14,11,2);
PutPixel(16,11,2);

PutPixel(3,14,2); {Red pixels 4th row}
PutPixel(5,14,2);
PutPixel(7,14,2);
PutPixel(11,14,2);
PutPixel(13,14,2);
PutPixel(15,14,2);
PutPixel(2,15,2);
PutPixel(4,15,2);
PutPixel(6,15,2);
PutPixel(8,15,2);
PutPixel(10,15,2);
PutPixel(12,15,2);
PutPixel(14,15,2);
PutPixel(16,15,2);

s1:=imagesize(0,0,15,15);
getmem(SmallWall,s1);
getimage(1,1,16,16,SmallWall^);

{Clear}
SetFillStyle(1,0);
Bar(0,0,19,17);
SetColor(3);

SetColor(1);
Line(0,17,0,0);
Line(17,17,0,17);
Line(17,0,17,17);
Line(0,0,17,0);

SetColor(3);
Line(4,1,12,1);
Line(3,2,13,2);
Line(3,3,5,3);
Line(11,3,13,3);
Line(3,4,3,13);
Line(13,4,13,13);
Line(4,14,12,14);
PutPixel(4,13,3);
PutPixel(12,13,3);

PutPixel(6,5,3);
PutPixel(6,6,3);
PutPixel(7,5,3);
PutPixel(9,5,3);
PutPixel(10,5,3);
PutPixel(10,6,3);

PutPixel(6,10,3);
PutPixel(10,10,3);
Line(6,9,10,9);
Line(7,11,9,11);

s1:=imagesize(0,0,15,15);
getmem(BloxiPlayer,s1);
getimage(1,1,16,16,BloxiPlayer^);

{Clear}
SetFillStyle(1,0);
Bar(0,0,19,17);

{Diamond}
SetColor(2);
Line(8,11,12,7);
Line(11,6,8,3);
SetColor(1);
Line(8,10,11,7);
Line(7,10,10,7);
Line(8,8,10,6);
Line(6,9,9,6);
Line(7,7,9,5);
Line(5,8,8,5);
Line(4,7,7,4);
SetColor(3);
Line(7,9,5,7);
Line(6,6,8,4);

s1:=imagesize(0,0,15,15);
getmem(Diamond,s1);
getimage(1,1,16,16,Diamond^);

{Clear}
SetFillStyle(1,0);
Bar(0,0,19,17);

SetFillStyle(1,2);
Bar(2,1,15,16);
SetColor(0);
Line(3,2,14,2);
Line(3,3,3,5);
Line(3,7,11,7);
Line(3,8,3,10);
Line(3,12,14,12);
Line(3,13,3,15);
SetColor(1);
Line(4,5,14,5);
Line(14,4,14,3);
Line(4,10,11,10);
Line(11,9,11,8);
Line(4,15,14,15);
Line(14,14,14,13);
PutPixel(13,8,3);
PutPixel(14,8,3);
PutPixel(13,9,3);
PutPixel(14,9,1);

s1:=imagesize(0,0,15,15);
getmem(Exit,s1);
getimage(1,1,16,16,Exit^);
{Make door open}


s2:=imagesize(0,0,18,18);
getmem(ExitOpen,s2);
getimage(11,1,18,16,ExitOpen^);
PutImage(9,1,ExitOpen^,0);
getimage(11,3,18,16,ExitOpen^);
PutImage(9,2,ExitOpen^,0);
getimage(6,3,18,16,ExitOpen^);
PutImage(6,2,ExitOpen^,0);
SetColor(0);
Line(12,1,14,1);
Line(9,15,13,15);
Line(6,16,13,16);
PutPixel(6,2,0);
PutPixel(8,8,1);
Line(7,1,8,1);
GetImage(1,1,16,16,ExitOpen^);
{Clear}
SetFillStyle(1,0);
Bar(0,0,19,17);

Setcolor(2);
SetFillStyle(1,2);
Bar(4,2,11,11);
PutPixel(3,4,2);
PutPixel(2,3,2);
PutPixel(3,9,2);
PutPixel(12,9,2);
Line(6,12,9,12);
PutPixel(4,12,2);
PutPixel(11,12,2);
Line(3,13,3,14);
Line(12,13,12,14);
PutPixel(12,4,2);
PutPixel(13,3,2);
PutPixel(2,8,2);
PutPixel(13,8,2);
SetColor(1);
PutPixel(2,2,1);
Line(6,1,9,1);
PutPixel(10,2,1);
PutPixel(13,2,1);
PutPixel(2,7,1);
PutPixel(13,7,1);
SetColor(3);
Line(6,8,6,9);
Line(9,8,9,9);
PutPixel(4,2,0);
PutPixel(11,2,0);
PutPixel(4,11,0);
PutPixel(11,11,0);

s1:=imagesize(0,0,15,15);
getmem(Spider,s1);
getimage(1,1,16,16,Spider^);

SetFillStyle(1,0);
Bar(0,0,19,17);

SetColor(2);
SetFillStyle(1,2);
FillEllipse(9,8,7,7);
PutPixel(10,3,3);
PutPixel(11,3,3);
PutPixel(12,4,3);
PutPixel(13,5,3);
PutPixel(13,6,3);

s1:=imagesize(0,0,15,15);
getmem(Boulder,s1);
getimage(1,1,16,16,Boulder^);

{Clear}
SetFillStyle(1,0);
Bar(0,0,19,17);

SetColor(1);
Line(4,1,11,1);
Line(3,2,12,2);
Line(2,3,13,3);
Line(3,4,12,4);
Line(3,5,12,5);
Line(3,6,12,6);
Line(1,7,14,7);
Line(1,8,14,8);
Line(1,9,14,9);
Line(1,10,14,10);
Line(4,11,11,11);
Line(2,12,13,12);
Line(2,13,13,13);
Line(3,14,12,14);
SetColor(0);
Line(7,1,7,14);
Line(8,1,8,14);

s1:=imagesize(0,0,15,15);
getmem(Shooter,s1);
getimage(1,1,16,16,Shooter^);
{Clear}
SetFillStyle(1,0);
Bar(0,0,19,17);

SetFillStyle(1,3);
Bar(1,1,16,16);
Line(1,1,16,16);
Line(1,3,14,16);
Line(1,5,12,16);
Line(1,7,10,16);
Line(1,9,8,16);
Line(1,11,6,16);
Line(1,13,4,16);
Line(1,15,2,16);

Line(3,1,16,14);
Line(5,1,16,12);
Line(7,1,16,10);
Line(9,1,16,8);
Line(11,1,16,6);
Line(13,1,16,4);
Line(15,1,16,2);
SetColor(0);
Line(7,2,7,15);
Line(2,7,14,7);
SetColor(3);
Line(8,8,8,15);
Line(9,8,9,12);
Line(2,1,6,1);

s1:=imagesize(0,0,15,15);
getmem(WallTile,s1);
getimage(1,1,16,16,WallTile^);

{Clear}
SetFillStyle(1,0);
Bar(0,0,19,17);

PutPixel(4,7,2);
PutPixel(4,8,2);
PutPixel(5,8,3);
SetColor(3);
Line(6,7,12,7);
s1:=imagesize(0,0,15,15);
getmem(ArrowLeft,s1);
getimage(1,1,16,16,ArrowLeft^);

{Clear}
SetFillStyle(1,0);
Bar(0,0,19,17);

PutPixel(11,7,2);
PutPixel(11,8,2);
PutPixel(10,8,3);
SetColor(3);
Line(3,7,9,7);
s1:=imagesize(0,0,15,15);
getmem(ArrowRight,s1);
getimage(1,1,16,16,ArrowRight^);

{Clear}
SetFillStyle(1,0);
Bar(0,0,19,17);


SetColor(0);
OutTextXY(0,20,'Generating Graphics ...');
end;

Procedure DiamondSound;
begin
 Sound(350);
 Delay(10);
 Sound(1250);
 Delay(10);
 Sound(150);
 Delay(10);
 Sound(950);
 Delay(10);
 NoSound;
end;

Procedure BoulderSound;
begin
 Sound(150);
 Delay(20);
 Sound(200);
 Delay(20);
 NoSound;
end;

Procedure ExitSound;
begin
 Sound(400);
 Delay(50);
 Sound(300);
 Delay(25);
 Sound(350);
 Delay(25);
 Sound(450);
 Delay(25);
 NoSound;
end;

Procedure ToggleSound;
begin
 if (Noise = FALSE) then Noise := TRUE else Noise := FALSE;
 Sound(100);
 Delay(50);
 NoSound;
end;

begin
end.
