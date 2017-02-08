import samurai;

import std.stdio;
import std.getopt;

void main(string[] args)
{
  string[2] combo;
  void myHandler(string option, string value) {
    if (option == "seed") {
      import std.conv;
      import std.random;
      uint s = value.to!int;
      rndGen.seed = s;
    }
  }
  getopt(
    args,
    "seed", &myHandler,
    "combo-0", &combo[0],
    "combo-1", &combo[1]
  );
  GameInfo info = new GameInfo();
  PlayerTarou p = new PlayerTarou(info);

  import std.file;
  if (combo[info.side].exists && combo[info.side].isFile) {
    info.readCombo = combo[info.side];
  } else {
    info.beamStackSearch;
  }
  
  0.writeln;
  stdout.flush;

  while (1) {
    info.readTurnInfo();
    stderr.writefln("# Turn %d", info.turn);
    bool able = false;
    for (int i = 0; i < 3; ++i) {
      with(info.samuraiInfo[i]) {
        // debug{
          stderr.writefln("#%d : %d, %d, %d, %d, %d", i, curX, curY, done, hidden, curePeriod);
        // }
        if (!done && curePeriod == 0) {
          able |= true;
        }
      }
    }
    // debug {
      for (int i = 3; i < 6; ++i) {
        with(info.samuraiInfo[i]) {
          stderr.writefln("#%d : %d, %d, %d, %d, %d", i, curX, curY, done, hidden, curePeriod);
        }
      }
    // }
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

private class Node {
  int score;
  double additional;
  GameInfo info;
  Node prev = null;
}

GameInfo[] nextAllStates(GameInfo atom, int remain = 7)
{
  enum COST = [1 << 28, 4, 4, 4, 4, 2, 2, 2, 2];
  GameInfo[] ret;
  ret ~= atom;
  for (int i = 1; i <= 8; ++i) {
    if (atom.isValid(i) && remain >= COST[i]) {
      GameInfo next = new GameInfo(atom);
      next.doAction(i);
      GameInfo[] sub = nextAllStates(next, remain - COST[i]);
      ret ~= sub;
    }
  }
  return ret;
}

GameInfo[] nextRemitedStates(GameInfo atom, bool attack = false, bool move = false)
{
  if (attack) {
    return [atom];
  }
  GameInfo[] ret;
  for (int i = 1; i <= 4; ++i) {
    if (atom.isValid(i)) {
      GameInfo next = new GameInfo(atom);
      next.doAction(i);
      GameInfo[] sub = nextRemitedStates(next, true, move);
      ret ~= sub;
    }
  }
  if (move) {
    return ret;
  }
  for (int i = 5; i <= 8; ++i) {
    if (atom.isValid(i)) {
      GameInfo next = new GameInfo(atom);
      next.doAction(i);
      GameInfo[] sub = nextRemitedStates(next, attack, true);
      ret ~= sub;
    }
  }
  return ret;
}

/++
 + クラス内メソッドにするとコンパイルが落ちる。
 + unkoすぎるバージョン
 + 新しいRedBlackTreeだとコンパイルが通らない
 + （一方で古いRedBlackTreeだとPlayerTarou.dの
 + ほうでコンパイルが通らない）
 +/
import std.container : OldRedBlackTree = RedBlackTree;
import std.algorithm : max, map, reduce;
import std.random : randomShuffle, uniform;
import core.time;
import std.datetime;
void beamStackSearch(GameInfo atom)
{
  bool[GameInfo] done;
  done[atom] = true;
  enum END = 6 * 8;
  /+
  OldRedBlackTree!(Node, (a, b) {
    if (a.score != b.score) {
      return a.score > b.score;
    }
    return a.additional > b.additional;
  }, true)[END + 2] states;
  +/
  OldRedBlackTree!(Node, (a, b) => a.score + a.additional > b.score + b.additional, true)[END + 2] states;
  foreach (ref s; states) {
    s = new typeof(s);
  }
  Node a = new Node();
  a.score = 0;
  a.additional = 0;
  a.info = atom;
  states[atom.side].insert(a);
  enum BEAM_WIDTH = 1;
  StopWatch sw;
  sw.start();
  for (int n = 0; ; ++n) {
    sw.stop();
    auto dur = sw.peek();
    if (dur.seconds >= 7) {
      break;
    }
    sw.start();
    int weapon = 1;
    for (int turn = atom.side; turn < END; turn += 2) {
      for (int i = 0; i < BEAM_WIDTH; ++i) {
        if (states[turn].length == 0) {
          continue;
        }
        Node node = states[turn].front;
        states[turn].removeFront;
        auto info = new GameInfo(node.info);
        info.initActions;
        info.weapon = weapon;
        info.resetPreScore;
        auto nexts = nextAllStates(info);
        foreach (next; nexts) {
          if (next in done) {
            continue;
          }
          next.paintUsingHistory();
          done[next] = true;
          auto wao = nextRemitedStates(next);
          auto ket = wao.map!(a => a.getPreScore[0]).reduce!max;
          Node mode = new Node();
          auto ret = next.getPreScore();
          // mode.score = node.score + ret[0];
          // mode.additional = ket * 0.8 + next.centerLevel * 0.001 + uniform(0.0, 0.001);

          if (turn + 2 < END + atom.side) {
            mode.score = node.score + ret[0];
            mode.additional = ket * 0.9 + next.centerLevel * 1e-3 + ret[1] * 1e-6 + uniform(0.0, 1e-9);
          } else {
            mode.score = node.score + ret[0];
            mode.additional = uniform(0.0, 0.1);
          }
          // mode.additional = ret[1] + uniform(0.0, 1.0);
          // mode.additional = next.centerLevel + uniform(0.0, 1.0);
          // mode.additional = uniform(0.0, 1.0);
          mode.info = next;
          mode.prev = node;
          states[turn + 2].insert(mode);
        }
      }
      ++weapon;
      weapon %= 3;
    }
    // debug{
      auto g = states[END + atom.side].front.info;
      stderr.writefln("#%4d: score = %d", n, states[END + atom.side].front.score);
      for (int i = 0; i < g.height; ++i) {
        for (int j = 0; j < g.width; ++j) {
          stderr.write(' ', g.field[i][j], ' ');
        }
        stderr.writeln;
      }
      stderr.writeln = g.actions;
      stderr.writeln = states[END + atom.side].front.prev.prev.prev.info.actions;
      stderr.writeln = states[END + atom.side].front.prev.prev.prev.prev.prev.prev.info.actions;
    // }
  }
  int[][] actions;
  Node ite = states[END + atom.side].front;
  while (ite.prev !is null) {
    actions = ite.info.actions ~ actions;
    ite = ite.prev;
  }
  int idx = atom.side;
  foreach (action; actions) {
    stderr.writeln("turn ", idx, " : ", action);
    idx += 2;
  }
  atom.setComboActions(actions);
}

import std.string;
import std.conv;
import std.array;

void readCombo(GameInfo info, string fn)
{
  auto f = File(fn, "r");
  int[][] actions;
  for (;;) {
    string l = f.readln;
    if (l.length == 0) {
      break;
    }
    actions ~= l.chomp.split.map!(to!int).array;
  }
  info.setComboActions(actions);
}


