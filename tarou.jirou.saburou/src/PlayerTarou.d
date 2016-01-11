module samurai.PlayerTarou;
import samurai;

import std.stdio;
import std.random;
import std.container;
import std.algorithm;
import std.range;
import std.array;
import std.conv;
import std.typecons;

class PlayerTarou : Player {
  private:
    enum COST = [0, 4, 4, 4, 4, 2, 2, 2, 2, 1, 1];
    enum MAX_POWER = 7;

    int[][] fieldDup = null;
    SamuraiInfo[] samuraiDup = null;

    static immutable Merits DEFAULT_MERITS = new Merits.MeritsBuilder()
        .setTerr(10)
        .setSelf(3)
        .setKill(100)
        .setHide(0)
        .setSafe(200)
        .setUsur(5)
        .setDepl(1)
        .setMidd(3)
        .build();

    static class HistoryTree {
      private:
        const GameInfo info;
//        SList!HistoryTree children;
        HistoryTree[] children;
        HistoryTree parent;
        int action;

        SList!int getActions(SList!int actions) {
          if (parent !is null) {
            actions.insert(action);
            return parent.getActions(actions);
          } else {
            return actions;
          }
        }

      public:
        this(HistoryTree parent, const GameInfo info, int action) {
          this.parent = parent;
          this.info = info;
          this.action = action;
        }
        GameInfo getInfo() const { return new GameInfo(info); }

        void add(HistoryTree c) { children ~= c; }

        double score() const { return info.score(DEFAULT_MERITS); }

        SList!int getActions() {
          return getActions(SList!int());
        }

       HistoryTree[] collect() {
          HistoryTree[] list;
          if (children.length != 0) {
            list ~= children.map!(c => c.collect()).reduce!((l, r) {
              l ~= r;
              return l;
            });
          }
          list ~= this;
          return list;
        }

    }
    void plan(HistoryTree tree, immutable int power) {
      for (int i = 1; i < COST.length; ++i) {
        if (COST[i] <= power && tree.getInfo().isValid(i)) {
          GameInfo next = new GameInfo(tree.getInfo());
          next.doAction(i);
          HistoryTree child = new HistoryTree(tree, next, i);
          tree.add(child);
          plan(child, power - COST[i]);
        }
      }
    }

  public:
    void setDup(in GameInfo info) {
      fieldDup = info.field.map!(a => a.dup).array;
      samuraiDup = info.samuraiInfo.dup;
    }
    override void play(const GameInfo info_) {
      GameInfo info = new GameInfo(info_);
      debug {
        stderr.writeln("turn : ", info.turn, ", side : ", info.side, ", weapon : ", info.weapon);
      }

      if (fieldDup !is null && samuraiDup !is null) {
        enum ox = [
          [0, 0, 0, 0],
          [0, 0, 1, 1, 2],
          [-1, -1, -1, 0, 1, 1, 1]
        ];
        enum oy = [
          [1, 2, 3, 4],
          [1, 2, 0, 1, 0],
          [0, -1, 1, 1, 1, -1, 0]
        ];
        alias Point = Tuple!(int, "x", int, "y");
        bool[Point] [int] map;
        for (int i = 3; i < 6; ++i) {
          bool[Point] set;
          map[i] = set;
        }
        for (int y = 0; y < info.height; ++y) {
          for (int x = 0; x < info.width; ++x) {
            if (info.field[y][x] != fieldDup[y][x] && fieldDup[y][x] != 9) {
              int v = info.field[y][x];
              if (3 <= v && v < 6) {
                map[v][Point(x, y)] = true;
              }
            }
          }
        }

        for (int i = 3; i < 6; ++i) {
          auto si = info.samuraiInfo[i];
          if (si.curX == -1 && si.curY == -1) {
            debug {stderr.writeln("search ", i);}
            bool[Point] set;
            for (int y = 0; y < info.height; ++y) {
              for (int x = 0; x < info.width; ++x) {
                for (int r = 0; r < 4; ++r) {
                  bool flag = true;
                  if (samuraiDup[i].curX != -1 && samuraiDup[i].curY != -1) {
                    flag &= Math.abs(samuraiDup[i].curX - x) + Math.abs(samuraiDup[i].curY - y) <= 1;
                  }
                  flag &= map[i].length > 0;
                  bool done = false;
                  int diffCount = 0;
                  for (int d = 0; flag && d < ox[i - 3].length; ++d) {
                    auto pos = GameInfo.rotate(r, ox[i - 3][d], oy[i - 3][d]);
                    int px = x + pos.x;
                    int py = y + pos.y;
                    if (px < 0 || info.width <= px || py < 0 || info.height <= py) {
                      continue;
                    }
                    if (info.field[py][px] == fieldDup[py][px]) {
                      continue;
                    }
                    done |= info.field[py][px] == i;
                    flag &= info.field[py][px] == i
                        || info.field[py][px] < 3
                        || info.field[py][px] >= 8;
                    if (info.field[py][px] == i && fieldDup[py][px] != 9) {
                      ++diffCount;
                    }
                  }
                  flag &= done;
                  flag &= diffCount == map[i].length;
                  if (info.samuraiInfo[i].curX == -1 && info.samuraiInfo[i].curY == -1) {
                    flag &= (info.field[y][x] >= 3 && info.field[y][x] < 6) || info.field[y][x] == 9;
                  }
                  if (flag) {
                    set[Point(x, y)] = true;
                  }
                }
              }
            }
            debug {
              foreach (k; set.byKey) {
                stderr.writeln("\t? : ", k);
              }
            }
            if (set.length == 1) {
              Point p = set.byKey().front;
              int x = p.x;
              int y = p.y;
              debug {stderr.writeln("\t\tgot it! : ", p);}
              si.curX = x;
              si.curY = y;
              info.samuraiInfo[i] = si;
            }
          }
        }
      }

      HistoryTree root = new HistoryTree(null, info, 0);
      plan(root, MAX_POWER);

      auto histories = root.collect();

      double[] roulette = new double[histories.length];
      double accum = 0.0;
      int i = 0;
      foreach (hist; histories[]) {
        double v = Math.exp(hist.getInfo().score(DEFAULT_MERITS));
        accum += v;
        roulette[i++] = accum;
      }
      debug {
        if (accum == double.infinity) {
          stderr.writeln("accum goes infinite!");
        }
      }
      auto idx = roulette.length - roulette.assumeSorted.upperBound(uniform(0.0, accum)).length;
      GameInfo best = histories[idx].getInfo();
      auto bestActions = histories[idx].getActions();
      bestActions[].map!(a => a.to!string).reduce!((l, r) => l ~ " " ~ r).writeln;
      stdout.flush;

      fieldDup = best.field.map!(a => a.dup).array;
      samuraiDup = best.samuraiInfo.dup;
    }
}

