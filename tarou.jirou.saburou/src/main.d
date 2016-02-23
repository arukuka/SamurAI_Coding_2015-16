import samurai;

import std.stdio;

void main(string[] args)
{
  GameInfo info = new GameInfo();
  PlayerTarou p = new PlayerTarou(info.weapon, info.side, args);

  while (1) {
    info.readTurnInfo();
    writeln("# Turn ", info.turn);
    if (info.curePeriod != 0) {
      if (p.is_movable_next_turn(info)) {
        p.setDup(info);
        p.you_are_dead_already();
      }
      0.writeln;
    } else {
      p.play(info);
      0.writeln;
    }
    stdout.flush;
  }
}

