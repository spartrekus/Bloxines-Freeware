   ___ _           _       _           
  / __\ | _____  _(_)_ __ (_) ___  ___ 
 /__\// |/ _ \ \/ / | '_ \| |/ _ \/ __|
/ \/  \ | (_) >  <| | | | | |  __/\__ \
\_____/_|\___/_/\_\_|_| |_|_|\___||___/

|----------------------------------------------------------------------------|
| Bloxinies                                                                  |
| Made by Sebastiaan Jansen                                                  |
| http://thandor.net                                                         |
|----------------------------------------------------------------------------|

Bloxinies is a little character with ever smiling face. In this game he went
out for a walk and entered an odd looking gate, which led him into a puzzle 
world. He can only escape by collecting all the diamonds which open the door.

|----------------------------------------------------------------------------|
| How to play?                                                               |
|----------------------------------------------------------------------------|

Start Bloxinies by starting BLOXI.EXE. The game starts and after the short
introduction you'll start with the first level. The goal is to pick up all
the diamonds. Once you've collected all the diamonds the door will open.
Enter the door to advance to the next level.

You can use the arrow keys to move Bloxinies around.

Boulders can be pushed in order to block enemies or block shooters. Enemies
can also be used to prevent the static shooters from shooting you.

The F1 key will open the menu and F8 will close the menu. 

In game you can use:
 - F2 to restart the current level, at the cost of one life.
 - F3 to restart the game, taking you back to level one.
 - F4 to toggle sound effects.
 - ESC or Q to quit the game.

|----------------------------------------------------------------------------|
| System requirements                                                        |
|----------------------------------------------------------------------------|

The game has been tested on an 8MHz 8088 with 640KB RAM and CGA-graphics. Due
the simplicity of the game it will probably run fine on 4,77MHz systems as 
well. In case the game runs slow, try disabling sound effects by pressing F4.

|----------------------------------------------------------------------------|
| Creating Maps                                                              |
|----------------------------------------------------------------------------|

The file LEVELS.DAT allows you to modify/create levels. The first row is the
name of the level (which isn't used in-game actually, but an empty title 
triggers the end-game sequence) and is followed by a block of 12x16 numbers 
which are the actual map. Use the following legend to create a map:

0: Empty tile
1: Concrete wall
2: Big stone wall
3: Small brick wall
4: Boulder
5: Bloxinies
6: Diamond
7: Enemy
8: Static shooter
9: Exit door

Place only one Bloxinies (#5) and one Exit (#9) in each map. It's not necessary
to place walls as a border; Bloxinies can not fall off the map. The source 
code defines a maximum of 12 enemies, but this is usually enough to create a
tough map.