import samurai;

import std.stdio;

void main(string[] args)
{
  GameInfo info = new GameInfo();
  PlayerTarou p = new PlayerTarou(info.weapon, info.side, args);

  while (1) {
    info.readTurnInfo();
    stderr.writefln("# Turn %d", info.turn);
    int idx = -1;
    for (int i = 0; i < 3; ++i) {
      with(info.samuraiInfo[i]) {
        stderr.writefln("#%d : %d, %d, %d, %d, %d", i, curX, curY, done, hidden, curePeriod);
        if (!done && curePeriod == 0) {
          idx = i;
          break;
        }
      }
    }
    if (idx != -1) {
      info.weapon = idx;
      p.play(info);
      0.writeln;
    } else {
      p.setDup(info);
      "0 0".writeln;
    }
    stdout.flush;
  }
}

