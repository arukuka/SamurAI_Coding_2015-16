module samurai.GameInfo;
import samurai;

import std.stdio;
import std.string;
import std.array;
import std.conv;
import std.range;
import std.algorithm;
import std.typecons;
import Math = std.math;

alias Point = Tuple!(int, "x", int, "y");

class GameInfo {
  public:
    enum PLAYER_NUM = 6;
    enum TURNS_RULE = [0, 3, 4, 1, 2, 5, 3, 0, 1, 4, 5, 2];
    enum int[3][12] NEXT_AI_TURN_LUT = [
      [2, 1, 1],
      [0, 1, 1],
      [1, 2, 1],
      [1, 0, 1],
      [1, 1, 2],
      [1, 1, 0],
      [2, 1, 1],
      [0, 1, 1],
      [1, 2, 1],
      [1, 0, 1],
      [1, 1, 2],
      [1, 1, 0]
    ];
    enum int[2][3][2] HOME_POSITION = [
      [
        [0, 0],
        [0, 7],
        [7, 0]
      ],
      [
        [14, 14],
        [14, 7],
        [7, 14]
      ]
    ];
    int turns;
    int side;
    int weapon;
    int width, height;
    int maxCure;
    SamuraiInfo[PLAYER_NUM] samuraiInfo;
    int turn;
    int[][] field;

    this(GameInfo info) @safe pure {
      this.turns = info.turns;
      this.side = info.side;
      this.weapon = info.weapon;
      this.width = info.width;
      this.height = info.height;
      this.maxCure = info.maxCure;
      this.samuraiInfo = info.samuraiInfo.dup;
      this.turn = info.turn;
//      this.field = info.field.map!(a => a.dup).array;
      this.field = info.field;

      this.occupyCount = info.occupyCount;
      this.playerKill = info.playerKill;
      this.selfCount = info.selfCount;
      this.usurpCount = info.usurpCount;
      this.fightCount = info.fightCount;
      this.groupLevel = info.groupLevel;

      this.paints = info.paints;

      this.probPlaces = info.probPlaces;

      this.isAttackContain = info.isAttackContain;
      this.isMoveContain = info.isMoveContain;
      this.moveAfterAttack = info.moveAfterAttack;
      this.isKilled = info.isKilled;
      
      this.occupiedPointsArray = info.occupiedPointsArray;
      
      this.naname2dangerAtom = info.naname2dangerAtom;
      this.yabasou = info.yabasou;
      this.hora364364 = info.hora364364;
      this.korosisou = info.korosisou;
      this.target = info.target;
      this.reservedTarget = info.reservedTarget;
      
      this.actions = info.actions.dup;
      
      this.comboFlag = info.comboFlag;
      this.comboActions = info.comboActions;
      
      this.tugikuruDanger = info.tugikuruDanger;
      this.yasyaNoKamae = info.yasyaNoKamae;
      
      this.beActive = info.beActive;
      
      this.sokokamo = info.sokokamo;
      this.sokokamoAtom = info.sokokamoAtom;
      this.yattakaCount = info.yattakaCount;
      
      this.mazui = info.mazui;
    }
    
    this() {
      string[] res = this.read();

      this.turns   = 96;
      this.side    = res[0].to!int;
      this.weapon  = -1;
      this.width   = 15;
      this.height  = 15;
      this.maxCure = 18;
      
      foreach(i, ref s; this.samuraiInfo) {
        if (i < 3) {
          s.curX = s.homeX = HOME_POSITION[this.side][i][0];
          s.curY = s.homeY = HOME_POSITION[this.side][i][1];
        } else {
          s.curX = s.homeX = HOME_POSITION[1 - this.side][i - 3][0];
          s.curY = s.homeY = HOME_POSITION[1 - this.side][i - 3][1];
        }
      }

      this.turn = 0;
      this.field = new int[][](this.height, this.width);
      for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
          field[y][x] = 8;
        }
      }

      this.occupyCount = 0;
      this.playerKill = 0;
      this.selfCount = 0;
      this.usurpCount = 0;
      this.fightCount = 0;
      this.groupLevel = 0;
      this.yattakaCount = 0;

      this.paints = 0;

      this.isAttackContain = false;
      this.isMoveContain = false;
      this.moveAfterAttack = false;
      this.isKilled = false;
      
      this.target = false;
      this.reservedTarget = false;
      
      this.comboFlag = true;
    }

    void readTurnInfo() {
      string[] res = this.read();

      assert(res.length > 0);

      this.turn = res[0].to!int;

      assert(turn >= 0);

      foreach (ref s; this.samuraiInfo)  {
        res = this.read();
        s.curX = res[0].to!int;
        s.curY = res[1].to!int;
        s.done = res[2].to!int == 1;
        s.hidden = res[3].to!int;
        s.curePeriod = res[4].to!int;
      }

      for (int i = 0; i < this.height; ++i) {
        res = this.read();
        for (int j = 0; j < this.width; ++j) {
          this.field[i][j] = res[j].to!int;
        }
      }
    }
    
    int get(in int x, in int y) const pure @safe nothrow {
      Point p = Point(x, y);
      foreach (r; occupiedPointsArray) {
        if (r.key == p) {
          return r.val;
        }
      }
      return this.field[y][x];
    }

    bool isValid(int action) const pure nothrow @safe {
      immutable me = this.samuraiInfo[this.weapon];
      int x = me.curX;
      int y = me.curY;

      switch (action) {
        case 1,2,3,4:
          return me.hidden == 0;
        case 5,6,7,8: {
          final switch(action) {
            case 5: ++y; break;
            case 6: ++x; break;
            case 7: --y; break;
            case 8: --x; break;
          }
          assert (x != me.curX || y != me.curY);
          if (x < 0 || this.width <= x
              || y < 0 || this.height <= y) {
            return false;
          }
          if (me.hidden == 1 && get(x, y) >= 3) {
            return false;
          }
          foreach (i, s; this.samuraiInfo) {
            if ( i == this.weapon ) {
              continue;
            }
            if ( x == s.curX && y == s.curY && me.hidden == 0 && s.hidden == 0 ) {
              return false;
            }
            if ( x == s.homeX && y == s.homeY ) {
              return false;
            }
          }
          return true;
        }
        case 9: {
          if (me.hidden == 0) {
            if (get(x, y) >= 3) {
              return false;
            }
            return true;
          } else {
            foreach (s; this.samuraiInfo) {
              if (s.hidden != 1 && s.curX == x && s.curY == y) {
                return false;
              }
            }
            return true;
          }
        }
        default:
          return action == 0;
      }
    }

    static auto rotate(int dir, int x, int y) pure nothrow @safe {
      final switch (dir) {
        case 0:
          return Point(x, y);
        case 1:
          return Point(y, -x);
        case 2:
          return Point(-x, -y);
        case 3:
          return Point(-y, x);
      }
    }

    void occupy(int dir) pure @safe {
      const fieldDup = this.field;
      // this.field = this.field.map!(a => a.dup).array;
      const field = this.field;
      this.occupiedPointsArray = this.occupiedPointsArray.dup;

      occupyCount = 0;
      playerKill = 0;
      selfCount = 0;
      usurpCount = 0;
      fightCount = 0;
      isKilled = false;
      yattakaCount = 0;
      int groupCount = 0;
      int yc = 0;
      int yac = 0;

      isAttackContain |= true;

      immutable me = this.samuraiInfo[this.weapon];
      immutable int curX = me.curX;
      immutable int curY = me.curY;

      enum size = [4, 5, 7];
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
      int[2] scores;
      for (int s = 0; s < 2; ++s) {
        for (int j = 0; j < 3; ++j) {
          scores[s] += this.paints[j + s * 3];
        }
      }
      int rem = this.width * this.height - (scores[0] + scores[1]);
      scores[1] += rem;
      Panel[] painted;
      for (int i = 0; i < size[this.weapon]; ++i) {
        auto pos = GameInfo.rotate(dir, ox[this.weapon][i], oy[this.weapon][i]);
        int nx = curX + pos.x;
        int ny = curY + pos.y;
        if (0<=nx && nx<width && 0<=ny && ny<height) {
          bool isHome = false;
          foreach (s; this.samuraiInfo) {
            isHome |= s.homeX == nx && s.homeY == ny;
          }
          if (!isHome) {
            if (get(nx, ny) != this.weapon) {
              if (get(nx, ny) >= 3) {
                if (get(nx, ny) < 6) {
                  ++usurpCount;
                }
                if (get(nx, ny) >= 8) {
                  ++occupyCount;
                }
                
                enum ofs = [
                  [0, 1],
                  [0, -1],
                  [1, 0],
                  [-1, 0]
                ];
                foreach (dp; ofs) {
                  int adjx = nx + dp[0];
                  int adjy = ny + dp[1];
                  if ( adjx < 0 || this.width <= adjx || adjy < 0 || this.height <= adjy ) {
                    ++groupCount;
                    break;
                  }
                  if (fieldDup[adjy][adjx] < 3) {
                    ++groupCount;
                    break;
                  }
                }
              } else {
                ++selfCount;
              }
              // field[ny][nx] = this.weapon;
              // this.occupiedPointsArray ~= Panel(Point(nx, ny), this.weapon);
              painted ~= Panel(Point(nx, ny), this.weapon);
            }
            for (int j = 3; j < GameInfo.PLAYER_NUM; ++j) {
              SamuraiInfo si = this.samuraiInfo[j];
              if (si.curX == nx && si.curY == ny) {
                si.curX = si.homeX;
                si.curY = si.homeY;
                si.hidden = 0;
                this.samuraiInfo[j] = si;
                ++playerKill;
                isKilled[j - 3] |= true;
              }
              if (j in sokokamo) {
                auto p = sokokamo[j];
                if (p.x == nx && p.y == ny) {
                  ++yc;
                }
              }
              if (j in sokokamoAtom) {
                auto p = sokokamoAtom[j];
                if (p.x == nx && p.y == ny) {
                  ++yac;
                }
              }
            }
          }
        }
      }

      yattakaCount = min(yc, yac);
      groupLevel = cast(double) groupCount / size[this.weapon];
      
      this.occupiedPointsArray ~= painted;
    }

    void doAction(int action) pure @safe {
      assert (isValid(action));
      auto me = this.samuraiInfo[this.weapon];
      int curX = me.curX;
      int curY = me.curY;
      
      if (isAttackContain && 5 <= action && action <= 8) {
        moveAfterAttack = true;
      }
      
      if (5 <= action && action <= 8) {
        isMoveContain = true;
      }

      final switch(action) {
        case 1, 2, 3, 4:
          this.occupy(action - 1);
          break;
        case 5: ++curY; break;
        case 6: ++curX; break;
        case 7: --curY; break;
        case 8: --curX; break;
        case 9:
          me.hidden = 1 - me.hidden;
          break;
      }
      me.curX = curX;
      me.curY = curY;
      this.samuraiInfo[this.weapon] = me;
      
      this.actions ~= action;
    }

    double score(const Merits m) const pure nothrow @safe {
      return this.samuraiInfo[this.weapon].hidden * m.hide
          + this.selfCount * m.self
          + this.playerKill * m.kill
          + this.occupyCount * m.terr
          + this.usurpCount * m.usur
          // + this.fightCount * m.fght
          + this.groupLevel * m.grup
          + this.safeLevel() * m.safe
          + this.deployLevel() * m.depl
          + this.centerLevel() * m.midd
          // + this.hasKilledRivalAtNextTurn() * m.krnt
          + this.hasHiddenTactically() * m.tchd
          // + this.isInSafeLand() * m.land
          + this.giriScore() * m.giri
          + this.existTarget() * m.trgt
          + this.remainCombo() * m.comb
          + this.hasMuda() * m.muda
          + this.chopCount * m.chop
          + this.temeehadameda() * m.lskl
          + this.isZako() * m.zako
          + this.kasanari * m.ksnr
          + this.isYasyaNoKamae() * m.ysnk
          + this.yattakaCount * m.yttk
          + this.moveAfterAttack * m.mvat;
    }

    deprecated
    bool isSafe() const pure nothrow @safe {
      bool flag = true;
      SamuraiInfo me = this.samuraiInfo[this.weapon];
      // 3
      {
        SamuraiInfo si = this.samuraiInfo[3];
        if (si.curX != -1 && si.curY != -1) {
          int dx = Math.abs(si.curX - me.curX);
          int dy = Math.abs(si.curY - me.curY);
          flag &= (dx + dy > 5 || min(dx, dy) >= 2);
        }
      }
      // 4
      {
        SamuraiInfo si = this.samuraiInfo[4];
        if (si.curX != -1 && si.curY != -1) {
          int dx = Math.abs(si.curX - me.curX);
          int dy = Math.abs(si.curY - me.curY);
          flag &= dx + dy > 3;
        }
      }
      // 5
      {
        SamuraiInfo si = this.samuraiInfo[5];
        if (si.curX != -1 && si.curY != -1) {
          int dx = Math.abs(si.curX - me.curX);
          int dy = Math.abs(si.curY - me.curY);
          flag &= dx + dy > 3 || max(dx, dy) > 2;
        }
      }
      return flag;
    }
    static bool isSafe(immutable Point me, immutable Point rv, immutable int idx) pure nothrow @safe {
      immutable int dx = Math.abs(rv.x - me.x);
      immutable int dy = Math.abs(rv.y - me.y);
      final switch (idx) {
        case 3:
          return (dx + dy > 5 || min(dx, dy) >= 2);
        case 4:
          return dx + dy > 3;
        case 5:
          return dx + dy > 3 || max(dx, dy) > 2;
      }
    }
    static bool isSafeW2T(immutable Point me, immutable Point rv, immutable int idx) pure nothrow @safe {
      immutable int dx = Math.abs(rv.x - me.x);
      immutable int dy = Math.abs(rv.y - me.y);
      final switch (idx) {
        case 3:
          return (dx + dy) >= 9;
        case 4:
          return (dx + dy) >= 7;
        case 5:
          return (dx + dy) >= 7 || max(dx, dy) >= 6;
      }
    }
    static bool isSafeW2A(immutable Point me, immutable Point rv, immutable int idx) pure nothrow @safe {
      immutable int dx = Math.abs(rv.x - me.x);
      immutable int dy = Math.abs(rv.y - me.y);
      final switch (idx) {
        case 3:
          return (dx + dy) >= 7 || min(dx, dy) >= 3;
        case 4:
          return (dx + dy) >= 5;
        case 5:
          return (dx + dy) >= 5 || max(dx, dy) >= 4;
      }
    }
    static double isSafeLimit(immutable Point me, immutable Point rv, immutable int idx) pure nothrow @safe {
      immutable int dx = Math.abs(rv.x - me.x);
      immutable int dy = Math.abs(rv.y - me.y);
      final switch(idx) {
        case 3:
          return dx == 2 && dy == 2;
        case 4:
          return (dx + dy) == 4;
        case 5:
          return ((dx + dy) == 4) + (min(dx, dy) == 0 && max(dx, dy) == 3) * 2;
      }
    }
    bool isSafe(immutable int idx, immutable Point p) const pure nothrow @safe {
      const SamuraiInfo me = this.samuraiInfo[this.weapon];
      return GameInfo.isSafe(Point(me.curX, me.curY), p, idx);
    }
    deprecated
    bool isSafe2(immutable int idx, immutable Point rvp) const pure nothrow @safe {
      const SamuraiInfo me = this.samuraiInfo[this.weapon];
      immutable mep = Point(me.curX, me.curY);
      immutable int[3] turns = nextAITurn2();
      final switch (turns[idx - 3]) {
        case 0:
          return true;
        case 1:
          return isSafe(mep, rvp, idx);
        case 2:
          if (isKilled[idx - 3]) {
            return true;
          } else {
            /+ TIMED OUT
            enum large_ofs = [
                                            [0, -3],
                                  [-1, -2], [0, -2], [1, -2],
                        [-2, -1], [-1, -1], [0, -1], [1, -1], [2, -1],
              [-3,  0], [-2,  0], [-1,  0], [0,  0], [1,  0], [2,  0], [3, 0],
                        [-2,  1], [-1,  1], [0,  1], [1,  1], [2,  1],
                                  [-1,  2], [0,  2], [1,  2],
                                            [0,  3]
            ];
            bool is_absolute_safe = true;
            foreach (dp; large_ofs) {
              if (!is_absolute_safe) {
                break;
              }
              Point np = Point(p.x + dp[0], p.y + dp[1]);
              if (np.x < 0 || this.width <= np.x || np.y < 0 || this.height <= np.y) {
                continue;
              }
              is_absolute_safe &= isSafe(idx, np);
            }
            if (is_absolute_safe) {
              return true;
            }
            +/
            /+
            if (isSafeW2T(mep, rvp, idx)) {
              return true;
            }
            if (isSafeW2A(mep, rvp, idx)) {
              return true;
            }
            +/
            return isSafeW2T(mep, rvp, idx)
                || (!isAttackContain && me.hidden && isSafeW2A(mep, rvp, idx));
            /+ TIMED OUT
            enum ofs = [
              [0, 1],
              [0, -1],
              [1, 0],
              [-1, 0]
            ];
            bool res = isSafe(mep, rvp, idx) && !isAttackContain && me.hidden;
            foreach (dp; ofs) {
              if (!res) {
                break;
              }
              Point np = Point(rvp.x + dp[0], rvp.y + dp[1]);
              if (np.x < 0 || this.width <= np.x || np.y < 0 || this.height <= np.y) {
                continue;
              }
              res &= isSafe(mep, np, idx);
            }
            return res;
            +/
          }
      }
    }

    double safeLevel() const pure nothrow @safe {
      SamuraiInfo me = this.samuraiInfo[this.weapon];
      bool daijoubu = false;
      if (this.side == 0) {
        bool hajimete = true;
        for (int i = 0; i < 3; ++i) {
          hajimete &= !this.reservedTarget[i];
        }
        daijoubu = hajimete;
        bool yaritin = false;
        for (int i = 0; i < 3; ++i) {
          yaritin |= this.target[i];
        }
        daijoubu &= yaritin;
      }
      
      for (int i = 0; i < 3; ++i) {
        if (i == this.weapon) {
          continue;
        }
        for (int j = 0; j < 3; ++j) {
          if (daijoubu && this.samuraiInfo[j + 3].done) {
            continue;
          }
          if (mazui[i][j][me.curY][me.curX]) {
            return 0.0;
          }
        }
      }
      
      
      if (!beActive[this.weapon]) {
        bool yf = false;
        foreach (i; 0..3) {
          if (daijoubu && this.samuraiInfo[i + 3].done) {
            continue;
          }
          yf |= yabasou[this.weapon][i];
        }
        if (yf) {
          if (isAttackContain || me.hidden == 0) {
            return 0.0;
          }
          bool hf = false;
          foreach (i; 3..6) {
            hf |= hora364364[i][me.curY][me.curX];
          }
          if (hf) {
            return 0.0;
          }
        } else {
          for (int i = 3; i < 6; ++i) {
            if (daijoubu && this.samuraiInfo[i].done) {
              continue;
            }
            if (naname2dangerAtom[i][me.curY][me.curX]) {
              return 0.0;
            }
          }
        }
      } else {
        for (int i = 3; i < 6; ++i) {
          SamuraiInfo si = this.samuraiInfo[i];
          immutable Point p = Point(si.curX, si.curY);
          if (daijoubu && si.done) {
            continue;
          }
          if (naname2dangerAtom[i][me.curY][me.curX]) {
            return 0.0;
          }
          if (hora364364[i][me.curY][me.curX]) {
            return 0.0;
          }
        }
      }
      // sine
      double[bool] init(double kagen) {
        double[bool] ret;
        ret[false] = kagen;
        ret[true] = 1.0;
        return ret;
      }
      enum double[bool] ret  = init = 0.0;
      enum double[bool] ret2 = init = 0.96;

      with (this.samuraiInfo[this.weapon]) {
        for (int i = 0; i < 3; ++i) {
          if (isKilled[i]) {
            continue;
          }
          if (tugikuruDanger[i][curY][curX] && !daijoubu) {
            return 0.0;
          }
        }
      }
      
      double safe = 1.0;
      for (int i = 3; i < 6; ++i) {
        SamuraiInfo si = this.samuraiInfo[i];
        immutable Point p = Point(si.curX, si.curY);
        if (daijoubu && si.done) {
          continue;
        }
        if (this.target[i - 3]) {
          safe = min(safe, ret2[isSafe(i, p)]);
          continue;
        }
        with (this.samuraiInfo[this.weapon]) {
          int v = yasyaNoKamae[this.weapon][curY][curX];
          if ( v == i ) {
            if (this.side == 1 && !si.done) {
              immutable Point mep = Point(me.curX, me.curY);
              safe = min(safe, ret[isSafeW2T(mep, p, i)
                  || ((!isAttackContain || moveAfterAttack) && me.hidden && isSafeW2A(mep, p, i))
                  ]);
            }
            safe = min(safe, ret[isSafe(i, p)]);
            continue;
          }
        }
        if (p.x != -1 && p.y != -1) {
          if (this.side == 1 && !si.done) {
            immutable Point mep = Point(me.curX, me.curY);
            safe = min(safe, ret[isSafeW2T(mep, p, i)
                || ((!isAttackContain || moveAfterAttack) && me.hidden && isSafeW2A(mep, p, i))
                ]);
          }
          safe = min(safe, ret[isSafe(i, p)]);
        }
        foreach(pp; this.probPlaces[i]) {
          if (get(pp.x, pp.y) < 3) {
            continue;
          }
          if (this.side == 1 && !si.done) {
            immutable Point mep = Point(me.curX, me.curY);
            safe = min(safe, ret[isSafeW2T(mep, pp, i)
                || ((!isAttackContain || moveAfterAttack) && me.hidden && isSafeW2A(mep, pp, i))
                ]);
          }
          safe = min(safe, ret[isSafe(i, pp)]);
        }
      }
      if (moveAfterAttack && me.hidden) {
        safe = max(safe, 0.94);
      }
      return safe;
    }

    double deployLevel() const pure nothrow @safe {
      const SamuraiInfo me = this.samuraiInfo[this.weapon];
      double res = 1 << 28;
      for (int i = 0; i < 3; ++i) {
        if (this.weapon == i) continue;
        SamuraiInfo si = this.samuraiInfo[i];
        res = min(res, Math.abs((me.curX - si.curX) + Math.abs(me.curY - si.curY)));
      }
      return res;
    }
    double centerLevel() const pure nothrow @safe {
      const SamuraiInfo me = this.samuraiInfo[this.weapon];
      double dist = Math.abs(me.curX - this.width / 2) + Math.abs(me.curY - this.height / 2);
      double maxd = this.width / 2 + this.height / 2;
      return maxd - dist;
    }
    deprecated
    bool hasKilledRivalAtNextTurn() const pure nothrow @safe {
      immutable int[3] turns = nextAITurn2();
      return isKilled[this.weapon] && turns[this.weapon] == 0;
    }
    double hasHiddenTactically() const pure nothrow @safe {
      const SamuraiInfo me = this.samuraiInfo[this.weapon];
      if (isAttackContain || !me.hidden) {
        return false;
      }
      /+
      if (korosisou[this.weapon]) {
        return false;
      }
      +/
      immutable mep = Point(me.curX, me.curY);
      // immutable int[3] turns = nextAITurn2();
      double flag = 0;
      for (int i = 3; i < 6; ++i) {
        const SamuraiInfo si = this.samuraiInfo[i];
        immutable sip = Point(si.curX, si.curY);
        if (sip.x == -1 || sip.y == -1) {
          continue;
        }
        if (sip.x == si.homeX && sip.y == si.homeY) {
          continue;
        }
        /+
        if (turns[i - 3] != 1) {
          continue;
        }
        +/
        flag += isSafeLimit(mep, sip, i);
        if (flag > 0) {
          auto dx = Math.abs(sip.x - mep.x);
          auto dy = Math.abs(sip.y - mep.y);
          if (min(dx, dy) == 0) {
            if (this.weapon == 0) {
              flag += 0.5;
            } else if (this.weapon == 2) {
              flag -= 1.0;
            }
          } else if (min(dx, dy) == 1 && this.weapon == 2) {
            flag -= 1.0;
          }
        }
      }
      return flag;
    }
    deprecated
    bool isInSafeLand() const pure nothrow @safe {
      const SamuraiInfo me = this.samuraiInfo[this.weapon];
      if (isAttackContain || me.hidden != 1) {
        return false;
      }
      enum ofs = [
        [0, 1],
        [1, 0],
        [-1, 0],
        [0, -1],
      ];
      immutable mep = Point(me.curX, me.curY);
      bool flag = true;
      foreach (dp; ofs) {
        if (!flag) {
          break;
        }
        int nx = dp[0] + mep.x;
        int ny = dp[1] + mep.y;
        if (nx < 0 || this.width <= nx || ny < 0 || this.height <= ny) {
          continue;
        }
        int v = get(nx, ny);
        flag &= !(3 <= v && v < 6);
      }
      return flag;
    }

    void setRivalInfo(int[6] paints) pure nothrow @safe {
      this.paints = paints;
    }

    deprecated
    void setProbPlaces(int idx, bool[Point] set) {
      this.probPlaces[idx] = [];
      foreach (p; set.byKey) {
        this.probPlaces[idx] ~= p;
      }
    }
    void setProbPlaces(int idx, Point[] arr) pure @safe {
      this.probPlaces[idx] = arr.dup;
    }

    deprecated
    int[3] nextAITurn() const pure @safe nothrow {
      int id = this.side * 3 + this.weapon;
      assert (TURNS_RULE[this.turn % 12] == id);
      int[6] cnt = 0;
      for (int i = 1; i <= 12; ++i) {
        int jd = TURNS_RULE[(this.turn + i) % 12];
        if (jd == id) {
          break;
        }
        ++cnt[jd];
      }
      int[3] res;
      for (int i = 0; i < 3; ++i) {
        res[i] = cnt[i + (1 - this.side) * 3];
      }
      assert (res == NEXT_AI_TURN_LUT[this.turn % 12]);
      return res;
    }
    deprecated
    int[3] nextAITurn2() const pure @safe nothrow {
      return NEXT_AI_TURN_LUT[this.turn % 12];
    }
    void paintUsingHistory() pure @safe {
      if (occupiedPointsArray.length == 0) {
        return;
      }
      this.field = this.field.map!(a => a.dup).array;
      foreach(panel; occupiedPointsArray) {
        this.field[panel.key.y][panel.key.x] = panel.val;
      }
      occupiedPointsArray = occupiedPointsArray.init;
    }
    
    deprecated
    bool isLastTurn() const pure @safe nothrow {
      int mid = this.weapon + 3 * this.side;
      foreach_reverse(idx, id; TURNS_RULE) {
        if (id == mid) {
          return this.turn == this.turns - TURNS_RULE.length + idx;
        }
      }
      return false;
    }
    bool haveEnemyIdea(int id) const pure @safe nothrow {
      return samuraiInfo[id].curX == -1 && samuraiInfo[id].curY == -1 && probPlaces[id].length == 0;
    }
    void setNaname2DangerAtom(int[][][] d) pure @safe nothrow {
      this.naname2dangerAtom = d;
    }
    void setYabasou(bool[3][3] yabasou) pure @safe nothrow {
      this.yabasou = yabasou;
    }
    void setKorosisou(bool[3] korosisou) pure @safe nothrow {
      this.korosisou = korosisou;
    }
    double giriScore() const pure @safe nothrow {
      auto me = this.samuraiInfo[this.weapon];
      auto p = Point(me.curX, me.curY);
      with (p) {
        int v = 0;
        for (int i = 3; i < 6; ++i) {
          v += naname2dangerAtom[i][y][x];
        }
        if (v > 0) {
          return 0.0;
        }
        if (isAttackContain || me.hidden == 0) {
          return 0.0;
        }
        enum ofs = [
          [0, 1],
          [0, -1],
          [1, 0],
          [-1, 0]
        ];
        int score = 0;
        foreach (d; ofs) {
          int nx = x + d[0];
          int ny = y + d[1];
          if ( nx < 0 || 15 <= nx || ny < 0 || 15 <= ny ) {
            continue;
          }
          int nv = 0;
          for (int i = 3; i < 6; ++i) {
            nv += naname2dangerAtom[i][ny][nx];
          }
          score += nv;
        }
        return score;
      }
    }
    bool existTarget() const pure @safe nothrow {
      foreach (t; this.target) {
        if (t) {
          return true;
        }
      }
      return false;
    }
    void findTarget() pure @safe nothrow {
      if (this.side != 0 && (isAttackContain || !this.samuraiInfo[this.weapon].hidden)) {
        return;
      }
      if (isAttackContain || !this.samuraiInfo[this.weapon].hidden) {
        foreach (f; this.reservedTarget) {
          if (f) {
            return;
          }
        }
      }
      for (int i = 3; i < 6; ++i) {
        SamuraiInfo si = this.samuraiInfo[i];
        if (!si.done) {
          continue;
        }
        Point sip = Point(si.curX, si.curY);
        if (sip.x == -1 || sip.y == -1) {
          continue;
        }
        if (sip.x == si.homeX && sip.y == si.homeY) {
          continue;
        }
        if (reservedTarget[i - 3]) {
          continue;
        }
        // is in kill zone
        SamuraiInfo me = this.samuraiInfo[this.weapon];
        Point mep = Point(me.curX, me.curY);
        this.target[i - 3] = !GameInfo.isSafe(mep, sip, this.weapon + 3);
      }
      for (int i = 3; i < 6; ++i) {
        SamuraiInfo si = this.samuraiInfo[i];
        if (!si.done) {
          continue;
        }
        if (i !in sokokamo) {
          continue;
        }
        Point sip = sokokamo[i];
        Point sipa = sokokamoAtom[i];
        if (sip.x == si.homeX && sip.y == si.homeY) {
          continue;
        }
        if (sipa.x == si.homeX && sipa.y == si.homeY) {
          continue;
        }
        if (reservedTarget[i - 3]) {
          continue;
        }
        // in in kill zone double
        SamuraiInfo me = this.samuraiInfo[this.weapon];
        Point mep = Point(me.curX, me.curY);
        this.target[i - 3] = !GameInfo.isSafe(mep, sip, this.weapon + 3) && !GameInfo.isSafe(mep, sipa, this.weapon + 3);
      }
    }
    void setReservedTarget(bool[3] reservedTarget) pure @safe nothrow {
      this.reservedTarget = reservedTarget;
    }
    bool[3] getTarget() const pure @safe nothrow {
      return this.target;
    }
    override size_t toHash() const {
      enum ulong B = 23;
      enum ulong M = 1L << 60;
      ulong hash = 0;
      for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
          hash = (hash * B + get(x, y)) % M;
        }
      }
      foreach (si; samuraiInfo) {
        hash = (hash * B + si.homeX) % M;
        hash = (hash * B + si.homeY) % M;
        hash = (hash * B + si.curX) % M;
        hash = (hash * B + si.curY) % M;
        hash = (hash * B + si.done) % M;
        hash = (hash * B + si.hidden) % M;
        hash = (hash * B + si.curePeriod) % M;
      }
      return cast(size_t) hash;
    }
    override bool opEquals(Object o) {
      if (this is o) {
        return true;
      }
      if (!cast(typeof(this))o) {
        return false;
      }
      typeof(this) g = cast(typeof(this)) o;
      bool flag = true;
      flag &= occupiedPointsArray == g.occupiedPointsArray;
      for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
          flag &= field[y][x] == g.field[y][x];
        }
      }
      flag &= samuraiInfo == g.samuraiInfo;
      return flag;
    }
    override int opCmp(Object o) {
      GameInfo g = cast(GameInfo) o;
      for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
          if (get(x, y) != g.get(x, y)) {
            return get(x, y) - g.get(x, y);
          }
        }
      }
      for (int i = 0; i < 6; ++i) {
        auto s = samuraiInfo[i];
        auto t = g.samuraiInfo[i];
        if (s.curX != t.curX) {
          return s.curX - t.curX;
        }
        if (s.curY != t.curY) {
          return s.curY - t.curY;
        }
      }
      return 0;
    }
    void initActions() pure @safe nothrow {
      actions = [];
    }
    auto getPreScore() const pure @safe nothrow {
      return tuple(occupyCount, groupLevel);
    }
    void resetPreScore() pure @safe nothrow {
      occupyCount = 0;
      groupLevel = 0;
    }
    void setComboActions(int[][] acts) pure @safe nothrow {
      this.comboActions = (this.comboActions).init;
      for (int p = 0; p < turns / 6; ++p) {
        if (p * 3 + 2 >= acts.length) {
          break;
        }
        Nmoo hai = Nmoo.init;
        enum s = 1;
        for (int i = 0; i < 3; ++i) {
          int w = (s + i) % 3;
          int idx = p * 3 + i;
          hai[w] = acts[idx];
        }
        this.comboActions ~= hai;
      }
    }
    bool remainCombo() const pure @safe nothrow {
      if (!comboFlag[this.weapon]) {
        return false;
      }
      int period = this.turn / 6;
      if (period >= comboActions.length) {
        return false;
      }
      auto actionsWasabiNuki = actions.filter!(a => a != 9);
      return actionsWasabiNuki.equal = comboActions[period][this.weapon];
    }
    void initTarget() pure @safe nothrow {
      this.target = false;
    }
    bool hasMuda() const pure @safe nothrow {
      if (!isAttackContain) {
        return false;
      }
      if (isMoveContain) {
        return false;
      }
      return playerKill == 0 && selfCount == 0 && usurpCount == 0 && occupyCount == 0;
    }
    int[] actions;
    bool[3] comboFlag;
    int chopCount() const pure @safe nothrow {
      int cnt = 0;
      for (int i = 3; i < 6; ++i) {
        foreach (p; probPlaces[i]) {
          if (get(p.x, p.y) < 3) {
            ++cnt;
          }
        }
      }
      return cnt;
    }
    auto getOccupiedPointsArray() const pure @safe {
      return occupiedPointsArray.idup;
    }
    void setTugikuruDanger(bool[][][] d) pure @safe nothrow {
      this.tugikuruDanger = d;
    }
    void setBeActive(bool[3] beActive) pure @safe nothrow {
      this.beActive = beActive;
    }
    int temeehadameda() const pure @safe nothrow {
      int cnt = 0;
      for (int i = 3; i < 6; ++i) {
        if (!samuraiInfo[i].done && isKilled[i - 3]) {
          ++cnt;
        }
      }
      return cnt;
    }
    bool isZako() const pure @safe nothrow {
      if (occupyCount + usurpCount == 0) {
        int moveCount = 0;
        foreach (v; actions) {
          if (4 <= v && v <= 8) {
            ++moveCount;
          }
        }
        if (moveCount == 3) {
          return false;
        }
      }
      return occupyCount + usurpCount <= 2;
    }
    void miruKasanari(PlayerTarou.HistoryTree[3] nuri) {
      bool[Point] set;
      int cnt = occupyCount + selfCount + usurpCount;
      foreach (h; nuri) {
        auto g = h.getInfo;
        foreach (p; g.occupiedPointsArray) {
          set[p.key] = true;
        }
        cnt += g.occupyCount + g.selfCount + g.usurpCount;
      }
      kasanari = cnt - cast(int)set.length;
    }
    void setYasyaNoKamae(int[][][] k) pure @safe nothrow {
      this.yasyaNoKamae = k;
    }
    bool isYasyaNoKamae() const pure @safe nothrow {
      with (this.samuraiInfo[this.weapon]) {
        if (isAttackContain || hidden == 0) {
          return false;
        }
        int v = yasyaNoKamae[this.weapon][curY][curX];;
        if (v == 0) {
          return false;
        }
        if (this.samuraiInfo[v].curePeriod > 0) {
          return false;
        }
        return true;
      }
    }
    void setSokokamo(Point[int] s) pure @safe nothrow {
      sokokamo = s;
    }
    void setSokokamoAtom(Point[int] s) pure @safe nothrow {
      sokokamoAtom = s;
    }
    int getPlayerKill() const pure @safe nothrow {
      return playerKill;
    }
    void setMazui(bool[][][][] m) pure @safe nothrow {
      mazui = m;
    }
    void set364364(bool[][][] h) pure @safe nothrow {
      hora364364 = h;
    }
 private:
    int occupyCount;
    int playerKill;
    int selfCount;
    int usurpCount;
    int fightCount;
    int yattakaCount;
    double groupLevel;
    int[6] paints;
    Point[][6] probPlaces;
    bool isAttackContain;
    bool moveAfterAttack;
    bool isMoveContain;
    bool[3] isKilled;
    alias Tuple!(Point, "key", int, "val") Panel;
    Panel[] occupiedPointsArray;
    int[][][] naname2dangerAtom;
    bool[][][] hora364364;
    bool[3][3] yabasou;
    bool[3] korosisou;
    bool[3] target;
    bool[3] reservedTarget;
    alias int[][3] Nmoo;
    Nmoo[] comboActions;
    bool[][][] tugikuruDanger;
    int[][][] yasyaNoKamae;
    bool[3] beActive;
    int kasanari;
    Point[int] sokokamo;
    Point[int] sokokamoAtom;
    bool[][][][] mazui;

    string[] read() {
      string line = "";
      do {
        line = readln.strip;
      } while (line.length > 0 && line[0] == '#');
      return line.split(" ");
    }
}


