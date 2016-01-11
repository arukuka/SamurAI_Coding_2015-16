import samurai;

import std.stdio;

void main()
{
  GameInfo info = new GameInfo();
  PlayerTarou p = new PlayerTarou();

  while (1) {
    info.readTurnInfo();
    writeln("# Turn ", info.turn);
    if (info.curePeriod != 0) {
      if (info.curePeriod == 1) {
        p.setDup(info);
      }
      0.writeln;
    } else {
      p.play(info);
      0.writeln;
    }
    stdout.flush;
  }
}

