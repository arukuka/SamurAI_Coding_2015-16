import samurai;

import std.stdio;

void main(string[] args)
{
  GameInfo info = new GameInfo();
  PlayerTarou p = new PlayerTarou(info.weapon, info.side, args);

  while (1) {
    info.readTurnInfo();
    stderr.writeln("# Turn ", info.turn);
    p.play(info);
    0.writeln;
    stdout.flush;
    info.weapon = (info.weapon + 1) % 3;
  }
}

