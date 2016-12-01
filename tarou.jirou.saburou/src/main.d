import samurai;

import std.stdio;

void main(string[] args)
{
  GameInfo info = new GameInfo();
  PlayerTarou p = new PlayerTarou();

  while (1) {
    info.readTurnInfo();
    stderr.writefln("# Turn %d", info.turn);
    bool able = false;
    for (int i = 0; i < 3; ++i) {
      with(info.samuraiInfo[i]) {
        debug{
          stderr.writefln("#%d : %d, %d, %d, %d, %d", i, curX, curY, done, hidden, curePeriod);
        }
        if (!done && curePeriod == 0) {
          able |= true;
        }
      }
    }
    debug {
      for (int i = 3; i < 6; ++i) {
        with(info.samuraiInfo[i]) {
          stderr.writefln("#%d : %d, %d, %d, %d, %d", i, curX, curY, done, hidden, curePeriod);
        }
      }
    }
    if (able) {
      p.play(info);
      0.writeln;
    } else {
      p.search(info);
      p.setDup(info);
      "0 0".writeln;
    }
    stdout.flush;
  }
}

