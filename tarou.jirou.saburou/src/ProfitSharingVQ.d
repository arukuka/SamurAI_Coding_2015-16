module samurai.ProfitSharingVQ;
import samurai;

import std.string;
import std.stdio;
import std.conv;
import std.typecons;
import std.file;

class ProfitSharingVQ {
  private:
    int[5][180000] Q;
  
    alias Tuple!(int, "s", int, "a") SA;
    SA[2] queue;
    immutable int weapon;
    immutable int side;
    
    enum IS_LEARNING = true;
    enum USE_FILE_FLAG = true;
  public:
    this(int weapon, int side) {
      this.weapon = weapon;
      this.side = side;
      static if(USE_FILE_FLAG) {
        string filename = format("Q%d.csv", weapon);
        if (exists(filename)) {
          stderr.writeln("[DEBUG]: reading Q value setting..." ~ filename);
          auto fp = new File(filename, "r");
          for (int i = 0; i < 180000; ++i) {
            string[] acts = fp.readln.chomp.split(",");
            for (int j = 0; j < 5; ++j) {
              Q[i][j] = acts[j].to!int;
            }
          }
        }
      }
    }
    
    static int encodeState(const GameInfo src, const GameInfo next) {
      const SamuraiInfo mesrc = src.samuraiInfo[src.weapon];
      const SamuraiInfo menext = next.samuraiInfo[src.weapon];
      
      int code = 0;
      code += menext.curX;
      code += menext.curY * 15;
      code += src.get(mesrc.curX, mesrc.curY) * 15 * 15;
      code += next.get(menext.curX, menext.curY) * 15 * 15 * 10;
      code += ((src.turn * 4) / src.turns) * 15 * 15 * 10 * 10;
      code += src.side * 15 * 15 * 10 * 10 * 4;
      
      return code;
    }
    
    static int encodeAction(int[] actions) {
      foreach (act; actions) {
        if (1 <= act && act <= 4) {
          return act;
        }
      }
      return 0;
    }
    
    void evapolate() pure @safe nothrow {
      static if(IS_LEARNING) {
        for (int i = 0; i < 90000; ++i) {
          for (int j = 0; j < 5; ++j) {
            Q[i + side * 90000][j] -= Q[i + side * 90000][j] / 50;
          }
        }
      }
    }
    
    void enqueue(int state, int action) pure @safe nothrow{
      static if(IS_LEARNING) {
        SA sa = SA(state, action);
        queue[0] = queue[1];
        queue[1] = sa;
      }
    }
    
    int get(int state, int action) const pure @safe nothrow {
      return Q[state][action];
    }
    
    void reward() pure @safe nothrow {
      static if(IS_LEARNING) {
        int reward_value = 10;
        foreach (sa; queue) {
          Q[sa.s][sa.a] += reward_value;
          reward_value /= 5;
        }
      }
    }
    
    void save() const {
      static if(USE_FILE_FLAG) {
        string filename = format("Q%d.csv", weapon);
        auto fp = new File(filename, "w");
        for (int i = 0; i < 180000; i ++) {
          fp.writeln = format("%(%d,%)", Q[i]);
        }
        fp.close();
      }
    }
}

