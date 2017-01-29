import samurai;

import std.stdio;

void main(string[] args)
{
  GameInfo info = new GameInfo();
  PlayerTarou p = new PlayerTarou(info);
  
  beamStackSearch(info);
  
  0.writeln;
  stdout.flush;

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
import core.thread, core.sync.mutex;
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
  Mutex[END + 2] mutexes;
  foreach (ref s; states) {
    s = new typeof(s);
  }
  foreach (ref m; mutexes) {
    m = new Mutex;
  }
  auto tg = new ThreadGroup;
  int[200] counters;
  Node a = new Node();
  a.score = 0;
  a.additional = 0;
  a.info = atom;
  states[atom.side].insert(a);
  Mutex im = new Mutex;
  Mutex dm = new Mutex;
  shared int warihuri = atom.side;
  for (int t = atom.side; t < END; t += 2) {
    tg.create( () {
      int turn;
      synchronized (im) {
        turn = warihuri;
        warihuri += 2;
      }
      immutable weapon = (1 + turn / 2) % 3;
      stderr.writefln("turn %d start!", turn);
      while (true) {
        Node node = null;
        synchronized (mutexes[turn]) {
          if (states[turn].length) {
            node = states[turn].front;
            states[turn].removeFront;
          }
        }
        if (node is null) {
          Thread.sleep(dur!"msecs"(100));
          continue;
        }
        auto info = new GameInfo(node.info);
        info.initActions;
        info.weapon = weapon;
        info.resetPreScore;
        auto nexts = nextAllStates(info);
        foreach (next; nexts) {
          bool yatta = false;
          synchronized (dm) {
            if (next in done) {
              yatta = true;
            }
            done[next] = true;
          }
          if (yatta) {
            continue;
          }
          next.paintUsingHistory();
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
          synchronized (mutexes[turn + 2]) {
            states[turn + 2].insert(mode);
          }
        }
      }
    });
  }
  while (1) {
    Node node = null;
    synchronized (mutexes[END + atom.side]) {
      if (states[END + atom.side].length) {
        node = states[END + atom.side].front;
        states[END + atom.side].removeFront;
      }
    }
    if (node is null) {
      Thread.sleep(dur!"msecs"(100));
      continue;
    }
    auto g = node.info;
    auto s = node.score;
    auto index = counters[s]++;
    import std.conv : to;
    string fn = s.to!string ~ "-" ~ index.to!string;
    stderr.writeln(fn);
    auto f = File("combo/" ~ fn ~ ".txt", "w");
    for (int i = 0; i < g.height; ++i) {
      for (int j = 0; j < g.width; ++j) {
        f.write(' ', g.field[i][j], ' ');
      }
      f.writeln;
    }
    int[][] actions;
    Node ite = node;
    while (ite.prev !is null) {
      actions = ite.info.actions ~ actions;
      ite = ite.prev;
    }
    foreach (action; actions) {
      foreach (i, v; action) {
        if (i) {
          f.write(" ");
        }
        f.write(v);
      }
      f.writeln;
    }
    f.close();
  }
}

