module samurai.PlayerTarou;
import samurai;

import std.stdio;
import std.random;
import std.algorithm;
import std.range;
import std.array;
import std.conv;
import std.typecons;
import std.format;

class PlayerTarou : Player {
  private:
    enum COST = [0, 4, 4, 4, 4, 2, 2, 2, 2, 1];
    enum MAX_POWER = 7;

    int[][] latestField = null;
    SamuraiInfo[] samuraiMemory = null;
    int[][] fieldDup = null;
    SamuraiInfo[] samuraiDup = null;
    Point[][6] probPointDup;
    int[][3] prevActions = [[0], [0], [0]];

    static const Merits SPEAR_MERITS = new Merits.MeritsBuilder()
        .setTerr(40)
        .setSelf(0)
        .setKill(100000)
        .setHide(0.5)
        .setSafe(5000)
        .setUsur(50)
        .setMidd(1)
        .setGrup(5)
        .setGiri(1)
        .setTrgt(1500)
        .setComb(300)
        .setMuda(-1)
        .setZako(-100)
//        .setMvat(22)
        .build();
    static const Merits SWORD_MERITS = new Merits.MeritsBuilder()
        .setTerr(40)
        .setSelf(0)
        .setKill(100000)
        .setHide(0.5)
        .setSafe(5000)
        .setUsur(50)
        .setMidd(1)
        .setTrgt(1500)
        .setGiri(1)
        .setComb(300)
        .setMuda(-1)
//        .setLand(20)
//        .setMvat(22)
        .build();
    static const Merits BATTLEAX_MERITS = new Merits.MeritsBuilder()
        .setTerr(40)
        .setSelf(0)
        .setKill(100000)
        .setHide(0.5)
        .setSafe(5000)
        .setUsur(50)
        .setMidd(-1)
        .setGrup(5)
        .setTrgt(1500)
        .setGiri(1)
        .setComb(300)
        .setMuda(-1)
//        .setMvat(22)
        .build();
    static const Merits[3] MERITS4WEAPON = [
      SPEAR_MERITS,
      SWORD_MERITS,
      BATTLEAX_MERITS
    ];

    static const Merits NEXT_SPEAR_MERITS = new Merits.MeritsBuilder()
        .setTerr(36)
        .setSelf(0)
        .setUsur(45)
        .setMidd(1)
        .setGrup(1)
        .build();
    static const Merits NEXT_SWORD_MERITS = new Merits.MeritsBuilder()
        .setTerr(36)
        .setSelf(0)
        .setUsur(45)
        .setMidd(1)
        .build();
    static const Merits NEXT_BATTLEAX_MERITS = new Merits.MeritsBuilder()
        .setTerr(36)
        .setSelf(0)
        .setUsur(45)
        .setMidd(1)
        .setGrup(1)
        .build();
    static const Merits[3] NEXT_MERITS4WEAPON = [
      NEXT_SPEAR_MERITS,
      NEXT_SWORD_MERITS,
      NEXT_BATTLEAX_MERITS
    ];
    static const Merits LAST_TURN_MERIT = new Merits.MeritsBuilder()
        .setTerr(20)
        .setUsur(40)
        .setSelf(0)
        .setLskl(10000)
        .build();

    static class HistoryTree {
      private:
        GameInfo info;
        HistoryTree[] children;
        HistoryTree parent;
        int action;

        int[] getActions(int[] actions) @safe const pure nothrow {
          if (parent !is null) {
            actions = action ~ actions;
            return parent.getActions(actions);
          } else {
            return actions;
          }
        }

      public:
        this(HistoryTree parent, GameInfo info, int action) @safe pure {
          this.parent = parent;
          this.info = info;
          this.action = action;
        }
        GameInfo getInfo() @safe pure nothrow { return info; }

        void add(HistoryTree c) @safe pure nothrow { children ~= c; }

        int[] getActions() @safe const pure nothrow {
          return getActions([]);
        }

        HistoryTree[] collect() @safe pure nothrow {
          HistoryTree[] list;
          if (children.length > 0) {
            foreach (c; children) {
              list ~= c.collect();
            }
          }
          list ~= this;
          return list;
        }
        
        HistoryTree[] collectEnd() @safe pure nothrow {
          if (children.length == 0) {
            return [this];
          }
          HistoryTree[] list;
          foreach (c; children) {
            list ~= c.collectEnd();
          }
          return list;
        }
    }

    deprecated
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
    struct Node {
      int cost;
      int attack;
      HistoryTree tree;

      string toString() @safe const pure {
        return format("{%d, %b, %b, [%(%d %)]}", cost, attack, tree.getActions());
      }

      bool opEquals(ref const typeof(this) r) const @safe pure nothrow {
        return tree.getActions() == r.tree.getActions();
      }

      Node dup() @safe pure nothrow {
        Node res = {
          cost,
          attack,
          tree
        };
        return res;
      }
    }

    // attack, hidden, height, width : power
    int[13][2][20][20] done;
    void done_init() pure @trusted nothrow
    {
      import core.stdc.string : memset;
      memset(&done, -1, int.sizeof * 20 * 20 * 13 * 2);
    }
    void plan2(HistoryTree root) pure @trusted
    {
      auto queue = redBlackTree!((l, r) => l.cost > r.cost, true, Node)();
      Node atom = {
        MAX_POWER,
        0,
        root
      };
      queue.insert(atom);
      debug(2) {
        stderr.writeln("-- plan2 --");
      }
      done_init();
      auto me = root.info.samuraiInfo[root.info.weapon];
      done[me.curX][me.curY][me.hidden][0] = MAX_POWER;
      while (queue.length) {
        Node node = queue.front();
        queue.removeFront();
        debug(2) {
          stderr.writeln("\t", node.cost, node.tree.getActions());
        }

        for (int i = 1; i < COST.length; ++i) {
          if (COST[i] <= node.cost && node.tree.getInfo().isValid(i)) {
            GameInfo next = new GameInfo(node.tree.getInfo());
            next.doAction(i);
            auto nme = next.samuraiInfo[next.weapon];
            immutable attack_id = ((1 <= i && i <= 4) ?
                        (nme.curX == me.curX && nme.curY == me.curY) << 3 | i
                        : 0);
            if (node.cost - COST[i]
                <= done[nme.curX][nme.curY]
                    [nme.hidden]
                    [node.attack | attack_id]
                ) {
              continue;
            }

            debug(2) {
              stderr.writeln("\t\t", i, " -> ", node.cost - COST[i]);
            }

            done[nme.curX][nme.curY]
                    [nme.hidden]
                    [node.attack | attack_id]
                = node.cost - COST[i];

            HistoryTree child = new HistoryTree(node.tree, next, i);
            node.tree.add(child);
            Node nnode = {
              node.cost - COST[i],
              node.attack | attack_id,
              child
            };

            queue.insert(nnode);
          }
        }
      }
    }
    deprecated
    void next_plan(HistoryTree root) pure @trusted
    {
      auto queue = redBlackTree!((l, r) => l.cost > r.cost, true, Node)();
      Node atom = {
        MAX_POWER,
        0,
        root
      };
      queue.insert(atom);
      /+
      debug {
        stderr.writeln("-- next plan --");
      }
      +/
      done_init();
      auto me = root.info.samuraiInfo[root.info.weapon];
      done[me.curX][me.curY][me.hidden][0] = MAX_POWER;
      while (queue.length) {
        Node node = queue.front();
        queue.removeFront();
        /+
        debug {
          stderr.writeln("\t", node.cost, node.tree.getActions());
        }
        +/
        
        if (node.attack > 0) {
          continue;
        }

        for (int i = 1; i < COST.length; ++i) {
          if (COST[i] <= node.cost && node.tree.getInfo().isValid(i)) {
            if (5 <= node.tree.action && node.tree.action <= 8
                && 5 <= i && i <= 8) {
                continue;
            }
            GameInfo next = new GameInfo(node.tree.getInfo());
            if (next.samuraiInfo[next.weapon].hidden == 0 && i == 9) {
              continue;
            }
            next.doAction(i);
            auto nme = next.samuraiInfo[next.weapon];
            immutable attack_id = ((1 <= i && i <= 4) ?
                        (nme.curX == me.curX && nme.curY == me.curY) << 3 | i
                        : 0);
            if (node.cost - COST[i]
                <= done[nme.curX][nme.curY]
                    [nme.hidden]
                    [node.attack | attack_id]
                ) {
              continue;
            }

            /+
            debug {
              stderr.writeln("\t\t", i, " -> ", node.cost - COST[i]);
            }
            +/

            done[nme.curX][nme.curY]
                    [nme.hidden]
                    [node.attack | attack_id]
                = node.cost - COST[i];

            HistoryTree child = new HistoryTree(node.tree, next, i);
            node.tree.add(child);
            Node nnode = {
              node.cost - COST[i],
              node.attack | attack_id,
              child
            };

            queue.insert(nnode);
          }
        }
      }
    }
    void next_plan2(HistoryTree root) pure @safe
    {
      HistoryTree ptr = root;
      GameInfo atom = new GameInfo(root.getInfo());
      if (atom.samuraiInfo[atom.weapon].hidden == 1) {
        atom.doAction(9);
        HistoryTree child = new HistoryTree(root, atom, 9);
        root.add(child);
        ptr = child;
      }
      for (int i = 1; i <= 4; ++i) {
        GameInfo next = new GameInfo(ptr.getInfo());
        next.doAction(i);
        HistoryTree child = new HistoryTree(ptr, next, i);
        ptr.add(child);
      }
      for (int i = 5; i <= 8; ++i) {
        if (!ptr.getInfo().isValid(i)) {
          continue;
        }
        GameInfo next = new GameInfo(ptr.getInfo());
        next.doAction(i);
        HistoryTree child = new HistoryTree(ptr, next, i);
        ptr.add(child);
        for (int j = 1; j <= 4; ++j) {
          GameInfo next2 = new GameInfo(next);
          next2.doAction(j);
          HistoryTree grand = new HistoryTree(child, next2, j);
          child.add(grand);
        }
      }
    }

  public:
    void setDup(in GameInfo info) pure @safe {
      fieldDup = info.field.map!(a => a.dup).array;
      samuraiDup = info.samuraiInfo.dup;
    }
    void search(GameInfo info) {
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
        int[6] diffPrevCount;
        for (int y = 0; y < info.height; ++y) {
          for (int x = 0; x < info.width; ++x) {
            if (info.field[y][x] != fieldDup[y][x] && fieldDup[y][x] != 9 && info.field[y][x] != 9) {
              int v = info.field[y][x];
              if (3 <= v && v < 6) {
                ++diffPrevCount[v];
              }
            }
          }
        }

        for (int i = 3; i < 6; ++i) {
          auto si = info.samuraiInfo[i];
          if (si.curX == -1 && si.curY == -1) {
            debug {
              stderr.writeln("search ", i);
            }
            Point[] arr;
            for (int y = 0; y < info.height; ++y) {
              for (int x = 0; x < info.width; ++x) {
                for (int r = 0; r < 4; ++r) {
                  bool flag = true;
                  if (samuraiDup[i].curX != -1 && samuraiDup[i].curY != -1) {
                    flag &= Math.abs(samuraiDup[i].curX - x) + Math.abs(samuraiDup[i].curY - y) <= 1;
                  }
                  flag &= diffPrevCount[i] > 0;
                  bool done = false;
                  int diffCount = 0;
                  for (int d = 0; flag && d < ox[i - 3].length; ++d) {
                    auto pos = GameInfo.rotate(r, ox[i - 3][d], oy[i - 3][d]);
                    int px = x + pos.x;
                    int py = y + pos.y;
                    if (px < 0 || info.width <= px || py < 0 || info.height <= py) {
                      continue;
                    }
                    done |= info.field[py][px] == i;
                    flag &= info.field[py][px] == i
                        || info.field[py][px] == 9;
                    if (info.field[py][px] == i && info.field[py][px] != fieldDup[py][px] && fieldDup[py][px] != 9) {
                      ++diffCount;
                    }
                  }
                  flag &= done;
                  flag &= diffCount == diffPrevCount[i];
                  if (flag && (info.field[y][x] < 3 || info.field[y][x] == 8)) {
                    bool arieru = true;
                    if (fieldDup[y][x] != 9) {
                      with (samuraiDup[i]) {
                        if (curX == -1 || curY == -1) {
                          arieru = false;
                        }
                      }
                    }
                    if (arieru) {
                      enum mawari = [
                        [0, 1],
                        [0, -1],
                        [1, 0],
                        [-1, 0]
                      ];
                      foreach (d; mawari) {
                        int px = x + d[0];
                        int py = y + d[1];
                        if (px < 0 || info.width <= px || py < 0 || info.height <= py) {
                          continue;
                        }
                        if (3 <= info.field[py][px] && info.field[py][px] < 6) {
                          arr ~= Point(px, py);
                        }
                      }
                      continue;
                    }
                  }
                  flag &= (info.field[y][x] >= 3 && info.field[y][x] < 6) || info.field[y][x] == 9;
                  if (flag) {
                    arr ~= Point(x, y);
                  }
                }
              }
            }
            arr = arr.sort.uniq.array;
            debug {
              foreach (k; arr) {
                stderr.writeln("\t? : ", k);
              }
            }
            if (arr.length == 1) {
              Point p = arr.front;
              int x = p.x;
              int y = p.y;
              debug {
                stderr.writeln("\t\tgot it! : ", p);
              }
              si.curX = x;
              si.curY = y;
              info.samuraiInfo[i] = si;
              probPointDup[i] = probPointDup[i].init;
              info.setProbPlaces(i, probPointDup[i]);
            } else if (arr.length == 0) {
              if ( (info.samuraiInfo[i].done && !samuraiMemory[i].done)
                  || (info.turn % 6 == 1 && info.samuraiInfo[i].done)
                  || (info.turn % 6 == 0 && !samuraiMemory[i].done)) {
                probPointDup[i] = probPointDup[i].init;
              }
              info.setProbPlaces(i, probPointDup[i]);
            } else {
              info.setProbPlaces(i, arr);
              probPointDup[i] = arr;
            }
          } else {
            probPointDup[i] = probPointDup[i].init;
            info.setProbPlaces(i, probPointDup[i]);
            debug {
              stderr.writeln("I see ", i, " : (", si.curX, ", ", si.curY, ")");
            }
          }
        }
      }
      
      if (samuraiMemory is null) {
        samuraiMemory = info.samuraiInfo.dup;
      } else {
        for (int i = 3; i < 6; ++i) {
          if ((info.samuraiInfo[i].curX != -1 && info.samuraiInfo[i].curY != -1)
          || (info.samuraiInfo[i].done && !samuraiMemory[i].done)
          || (info.turn % 6 == 1 && info.samuraiInfo[i].done)
          || (info.turn % 6 == 0 && !samuraiMemory[i].done)) {
            samuraiMemory[i].curX = info.samuraiInfo[i].curX;
            samuraiMemory[i].curY = info.samuraiInfo[i].curY;
            if (info.samuraiInfo[i].curX == -1 || info.samuraiInfo[i].curY == -1) {
              tegakari[i].count++;
            } else {
              tegakari[i].x = info.samuraiInfo[i].curX;
              tegakari[i].y = info.samuraiInfo[i].curY;
              tegakari[i].count = 0;
            }
            debug {
              stderr.writeln("\trenew ", i , " : (", samuraiMemory[i].curX, ", ", samuraiMemory[i].curY, ")");
              stderr.writeln("\t\t because : ", [(info.samuraiInfo[i].curX != -1 && info.samuraiInfo[i].curY != -1)
          , (info.samuraiInfo[i].done && !samuraiMemory[i].done)
          , (info.turn % 6 == 1 && info.samuraiInfo[i].done)
          , (info.turn % 6 == 0 && !samuraiMemory[i].done)]);
            }
          } else if (info.samuraiInfo[i].curePeriod > 0) {
            samuraiMemory[i].curX = info.samuraiInfo[i].curX = info.samuraiInfo[i].homeX;
            samuraiMemory[i].curY = info.samuraiInfo[i].curY = info.samuraiInfo[i].homeY;
            tegakari[i].x = info.samuraiInfo[i].curX;
            tegakari[i].y = info.samuraiInfo[i].curY;
            tegakari[i].count = 0;
            probPointDup[i] = probPointDup[i].init;
            info.setProbPlaces(i, probPointDup[i]);
            debug {
              stderr.writeln("\tchange ", i, " : (", samuraiMemory[i].curX, ", ", samuraiMemory[i].curY, ")");
            }
          } else {
            info.samuraiInfo[i].curX = samuraiMemory[i].curX;
            info.samuraiInfo[i].curY = samuraiMemory[i].curY;
            debug {
              stderr.writeln("\tknew ", i , " : (", samuraiMemory[i].curX, ", ", samuraiMemory[i].curY, ")");
            }
          }
          samuraiMemory[i].done = info.samuraiInfo[i].done;
        }
      }

      debug {
        for (int i = 3; i < 6; ++i) {
          stderr.writeln("(", i, ")");
          stderr.writefln("  %d, %d", info.samuraiInfo[i].curX, info.samuraiInfo[i].curY);
          stderr.writeln("  ", probPointDup[i]);
        }
      }
    }
    struct Tegakari {
      int x, y;
      int count;
    }
    Tegakari[6] tegakari;
    this (GameInfo info) {
      for (int i = 3; i < 6; ++i) {
        tegakari[i].x = info.samuraiInfo[i].homeX;
        tegakari[i].y = info.samuraiInfo[i].homeY;
        tegakari[i].count = 0;
      }
    }
    bool[3] target;
    override void play(GameInfo info) @trusted {
      debug {
        stderr.writeln("turn : ", info.turn, ", side : ", info.side, ", weapon : ", info.weapon, "...", info.isLastTurn());
      }
      
      if (latestField is null) {
        latestField = info.field.map!(a => a.dup).array;
      } else {
        for (int y = 0; y < info.height; ++y) {
          for (int x = 0; x < info.width; ++x) {
            if (info.field[y][x] == 9) {
              continue;
            }
            latestField[y][x] = info.field[y][x];
          }
        }
      }
      int[6] paintCount;
      for (int i = 0; i < 6; ++i) {
        paintCount[i] = 0;
      }
      for (int y = 0; y < info.height; ++y) {
        for (int x = 0; x < info.width; ++x) {
          int v = latestField[y][x];
          if (0 <= v && v < 6) {
            ++paintCount[v];
          }
        }
      }
      info.setRivalInfo(paintCount);

      search(info);
      
      int[][] naname2danger = new int[][](15, 15);
      bool[3] beActive;
      bool[3] yabasou;
      bool[3] yabe;
      for (int i = 0; i < 3; ++i) {
        bool yaba = false;
        foreach (v; prevActions[i]) {
          yaba |= 1 <= v && v <= 4;
        }
        yabe[i] = yaba;
        enum ofs = [
          [ [-2, -2], [-2, 2], [2, -2], [2, 2] ],
          [ [-4, 0], [-3, -1], [-2, -2], [-1, -3], [0, -4], 
            [ 4, 0], [ 3, -1], [ 2, -2], [ 1, -3],
                     [-3,  1], [-2,  2], [-1,  3], [0,  4],
                     [ 3,  1], [ 2,  2], [ 1,  3]           ],
          [ [-4, 0], [-3, -1], [-2, -2], [-1, -3], [0, -4], 
            [ 4, 0], [ 3, -1], [ 2, -2], [ 1, -3], [0, -3],
            [-3, 0], [-3,  1], [-2,  2], [-1,  3], [0,  4],
            [ 3, 0], [ 3,  1], [ 2,  2], [ 1,  3], [0,  3] ]
        ];
        if (info.samuraiInfo[i].hidden == 0 || yaba) {
          foreach (d; ofs[i]) {
            int x = info.samuraiInfo[i].curX + d[0];
            int y = info.samuraiInfo[i].curY + d[1];
            if (0 <= x && x < 15 && 0 <= y && y < 15
                && 3 <= info.field[y][x] && info.field[y][x] < 6) {
              for (int j = 3; j < 6; ++j) {
                if (info.samuraiInfo[j].curX != -1 || info.samuraiInfo[j].curY != -1) {
                  continue;
                }
                if (probPointDup[i].length) {
                  continue;
                }
                if (Math.abs(x - tegakari[j].x) + Math.abs(y - tegakari[j].y) > (tegakari[j].count == 0 ? 0 : 3 + tegakari[j].count - 1)) {
                  continue;
                }
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
                enum ofs2 = [
                  [0, 0],
                  [0, 1],
                  [0, -1],
                  [1, 0],
                  [-1, 0]
                ];
                foreach (d2; ofs2) {
                  int x2 = x + d2[0];
                  int y2 = y + d2[1];
                  for (int r = 0; r < 4; ++r) {
                    for (int k = 0; k < ox[j - 3].length; ++k) {
                      auto p = GameInfo.rotate(r, ox[j - 3][k], oy[j - 3][k]);
                      int nx = x2 + p.x;
                      int ny = y2 + p.y;
                      if (nx < 0 || 15 <= nx || ny < 0 || 15 <= ny) {
                        continue;
                      }
                      naname2danger[ny][nx]++;
                    }
                  }
                }
              }
            }
          }
        }
      }
      for (int i = 0; i < 3; ++i) {
        if (naname2danger[info.samuraiInfo[i].curY][info.samuraiInfo[i].curX]) {
          yabasou[i] = true;
          if (!yabe[i] && info.samuraiInfo[i].hidden == 1) {
            beActive[i] = true;
          }
          /+
          enum ofs = [
                                          [0, -3],
                                [-1, -2], [0, -2], [1, -2],
                      [-2, -1], [-1, -1], [0, -1], [1, -1], [2, -1],
            [-3,  0], [-2,  0], [-1,  0], [0,  0], [1,  0], [2,  0], [3, 0],
                      [-2,  1], [-1,  1], [0,  1], [1,  1], [2,  1],
                                [-1,  2], [0,  2], [1,  2],
                                          [0,  3]
          ];
          foreach (d; ofs) {
            int x = info.samuraiInfo[i].curX + d[0];
            int y = info.samuraiInfo[i].curY + d[1];
            if (x < 0 || 15 <= x || y < 0 || 15 <= y) {
              continue;
            }
            yabasou[i] &= naname2danger[y][x] > 0;
          }
          +/
        }
      }
      info.setNaname2Danger(naname2danger);
      info.setYabasou(yabasou);
      info.setBeActive(beActive);
      stderr.writeln("be active : ", beActive);
      bool[3] korosisou = true;
      for (int i = 0; i < 3; ++i) {
        foreach (v; prevActions[i]) {
          korosisou[i] &= v >= 5;
        }
        korosisou[i] &= info.samuraiInfo[i].hidden == 1;
      }
      info.setKorosisou(korosisou);
      
      for (int i = 3; i < 6; ++i) {
        with (tegakari[i]) {
          stderr.writefln("(%d) : %d, %d ... %d", i, x, y, count);
        }
      }
      
      info.initTarget();
      if (info.turn % 6 < 2) {
        this.target = false;
      }
      
      HistoryTree[] histories = HistoryTree[].init;
      
      /+
      if (info.turn / 2 < 7) {
        enum weapons = [
          1,
          0,
          2,
          1,
          0,
          2,
          0
        ];
        enum actions = [
          [
            [ 6, 6, 6 ],
            [ 6, 6, 5 ],
            [ 8, 8, 8 ],
            [ 6, 6, 6 ],
            [ 5, 5, 6 ],
            [ 8, 8, 8 ],
            [ 5, 3    ]
          ],
          [
            [ 8, 8, 8 ],
            [ 8, 8, 7 ],
            [ 6, 6, 6 ],
            [ 8, 8, 8 ],
            [ 7, 7, 8 ],
            [ 6, 6, 6 ],
            [ 7, 1    ]
          ]
        ];
        GameInfo best = new GameInfo(info);
        best.weapon = weapons[info.turn / 2];
        auto bestActions = actions[info.side][info.turn / 2];
        foreach (a; bestActions) {
          best.doAction(a);
        }
        best.weapon.writeln;
        "".reduce!((l, r) => l ~ " " ~ r)(bestActions.map!(a => a.to!string)).writeln;
        fieldDup = best.field.map!(a => a.dup).array;
        samuraiDup = best.samuraiInfo.dup;
        prevActions[best.weapon] = bestActions;
      } else { +/
        GameInfo[3] infos;
        for (int i = 0; i < 3; ++i) {
          with (info.samuraiInfo[i]) {
            if (done || curePeriod > 0) {
              continue;
            }
          }
          GameInfo jnfo = new GameInfo(info);
          jnfo.weapon = i;
          jnfo.setReservedTarget(this.target);
          infos[i] = jnfo;
          HistoryTree root = new HistoryTree(null, jnfo, 0);
          plan2(root);
          
          histories ~= root.collect();
        }

        alias node = Tuple!(ulong, "index", double, "score");
        node[] nodes = new node[histories.length];
        if (info.turn/6 == 15) {
          foreach (i, next; histories) {
            double v = next.getInfo().score(LAST_TURN_MERIT);
            nodes[i] = node(i, v);
          }
        } else {
          foreach (i, next; histories) {
            HistoryTree next_root = new HistoryTree(null, next.info, 0);
            next_plan2(next_root);
            auto next_histories = next_root.collectEnd();
            
            double next_max_score = 0.0.reduce!max(next_histories.map!(a => a.getInfo().score(NEXT_MERITS4WEAPON[next.getInfo().weapon])));
            
            next.getInfo().findTarget();

            double v = next.getInfo().score(MERITS4WEAPON[next.getInfo().weapon])
                        + next_max_score
                        - infos[next.getInfo().weapon].score(MERITS4WEAPON[next.getInfo().weapon]);
            nodes[i] = node(i, v);
          }
        }
        double max_score = nodes.map!(a => a.score).reduce!max;
        auto bests = nodes.filter!(a => a.score == max_score).array;
        auto idx = bests[uniform(0, bests.length)].index;
        GameInfo best = histories[idx].getInfo();
        auto bestActions = histories[idx].getActions();
        info.comboFlag[best.weapon] &= best.remainCombo();
        /+
        if (best.samuraiInfo[best.weapon].hidden == 0 && best.isValid(9)) {
          best.doAction(9);
          bestActions ~= 9;
        }
        +/
        debug {
          for (int y = 0; y < 15; ++y) {
            for (int x = 0; x < 15; ++x) {
              if (naname2danger[y][x]) {
                stderr.writef("%2d", naname2danger[y][x]);
              } else {
                stderr.write(" .");
              }
              if (y == best.samuraiInfo[best.weapon].curY
                  && x == best.samuraiInfo[best.weapon].curX) {
                stderr.write("*");
              } else {
                stderr.write(" ");
              }
            }
            stderr.writeln;
          }
        }
        stderr.writefln("score = %f", max_score);
        stderr.writeln(bestActions);
        stderr.writeln("combo : ", info.comboFlag);
        best.weapon.writeln;
        "".reduce!((l, r) => l ~ " " ~ r)(bestActions.map!(a => a.to!string)).writeln;
        
        best.paintUsingHistory();
        fieldDup = best.field.map!(a => a.dup).array;
        samuraiDup = best.samuraiInfo.dup;
        prevActions[best.weapon] = bestActions.dup;
        
        this.target[] |= best.getTarget()[];
      
        for (int i = 3; i < 6; ++i) {
          if ((best.samuraiInfo[i].curX != -1 && best.samuraiInfo[i].curY != -1)
          && best.samuraiInfo[i].curX != samuraiMemory[i].curX
          && best.samuraiInfo[i].curY != samuraiMemory[i].curY ) {
            samuraiMemory[i].curX = best.samuraiInfo[i].curX;
            samuraiMemory[i].curY = best.samuraiInfo[i].curY;
            debug {
              stderr.writeln("\tmay killed so : ", i , " : (", samuraiMemory[i].curX, ", ", samuraiMemory[i].curY, ")");
            }
          }
        }
      // }
    }
}

