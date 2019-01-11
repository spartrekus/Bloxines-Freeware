{Bloxinies v1.0
Programmed by Sebastiaan Jansen using TP7
http://thandor.net}

Program Bloxi;
Uses Graph, Crt, BloxiEng;

Const
 Gametime = 0.50;

begin
 {Start the game}
 gotoxy(1,1);
 writeln('Starting Bloxinies v1.0 [.  ]');
 ResetGame;
 gotoxy(1,1);
 writeln('Starting Bloxinies v1.0 [.. ]');
 ReadMap(Level);
 gotoxy(1,1);
 writeln('Starting Bloxinies v1.0 [...]');
 GenerateObjects;
 Gamestate:=0;
 Noise:=TRUE;
 InitGraphics;
 GenerateGraphics;
 DrawHud;

 {Intro}
 SetFillStyle(1,0);
 Bar(78,48,242,152);
 SetColor(3);
 Rectangle(80,50,285,170);
 Rectangle(78,48,287,172);
 SetColor(1);
 Outtextxy(82,55,'The story of Bloxinies');
 SetColor(3);
 Outtextxy(82,75,'The day started, as a normal day.');
 Outtextxy(82,85,'Bloxinies went out for a walk until');
 Outtextxy(82,95,'he came across an odd looking gate');
 Outtextxy(82,105,'Curious as he was he entered... and');
 Outtextxy(82,115,'got zapped into a puzzle world.');

 {Gate}
 Line(204,168,232,168);
 Line(247,168,278,168);
 Line(204,167,204,157);
 Line(205,157,225,157);
 Line(232,167,232,151);
 Line(232,150,236,146);
 Line(233,167,237,163);
 Line(237,162,237,146);
 Line(232,149,235,146);
 Line(238,146,242,146);
 Line(243,146,247,150);
 Line(244,146,247,149);
 Line(247,151,247,167);
 Line(279,167,283,163);
 Line(283,162,283,154);
 Line(279,156,282,153);
 Line(259,152,281,152);
 Line(278,157,278,167);
 Line(258,152,258,137);
 Line(257,137,254,140);
 Line(257,136,231,136);
 Line(230,137,227,140);
 Line(226,141,253,141);
 Line(253,142,253,156);
 Line(278,157,254,157);
 Line(254,156,257,153);
 Line(226,141,226,156);
 Line(205,156,208,153);
 Line(209,152,225,152);

 Line(171,164,171,150);
 Line(172,165,173,165);
 Line(174,166,175,166);
 Line(176,167,177,167);
 Line(178,168,191,168);
 Line(178,167,178,152);
 Line(177,151,176,151);
 Line(175,150,174,150);
 Line(173,149,172,149);
 Line(174,148,185,148);
 Line(186,149,187,149);
 Line(188,150,189,150);
 Line(179,151,191,151);
 Line(178,152,192,152);
 Line(179,153,180,153);
 Line(190,153,191,153);
 Line(192,153,192,167);
 Line(181,162,189,162);
 Line(182,164,188,164);
 PutPixel(181,163,3);
 PutPixel(189,163,3);
 Line(181,157,181,155);
 Line(182,155,183,155);
 Line(187,155,188,155);
 Line(189,155,189,157);

 Repeat
 Until Keypressed;
 DrawMap;

 repeat {until Quit=TRUE}
 if Gamestate = 0 then
  begin {Running game}
   if KeyPressed then GamestateZeroKeys(Readkey); {Keys pressed when in-game}
   if timer >= endtime then
    begin
     start:=timer;
     endtime:=start+gametime;
     EnemyMovement; {Logic for enemymovement}
    end;
   if (Diamonds = 0) then ActivateExit; {Opens the door}
   if (Lives < 0) then RestartGame; {Out of lives}
  end;

 if Gamestate = 1 then
  begin {ESC / Menu}
   if KeyPressed then GamestateOneKeys(Readkey); {Keys pressed in menu}
  end;
Until (Gamestate=3) or (Gamestate=2);
if (Gamestate = 2) then
begin {Outtro}
 Gamestate:=0;
 ClearViewPort;
 start:=timer;
 endtime:=start+gametime;
 SetColor(3);
 OuttextXY(40,90,'You have escaped from the puzzle world.');
 repeat
 if timer >= endtime+3 then
    begin
     SetColor(0);
     OuttextXY(40,90,'You have escaped from the puzzle world.');
     SetColor(3);
     Outtextxy(20,90,'So now you can enjoy freedom at the DOS-prompt.');
     Gamestate:=2;
    end;
 until gamestate = 2;
Gamestate:=0;
start:=timer;
endtime:=start+gametime;
 repeat
 if timer >= endtime+3 then
    begin
     Gamestate:=2;
    end;
 until gamestate = 2;
 SetColor(0);
 Outtextxy(20,90,'So now you can enjoy freedom at the DOS-prompt.');
end;
DestroyApp; {Kills the program}
end.