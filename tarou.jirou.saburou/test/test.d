import std.stdio;
import std.range;
import std.algorithm;
import std.container;
import std.typecons;
import std.random;
import std.traits;

alias Tuple!(int, "x", int, "y") Point;

auto iterateArr()
{
  Point[] arr;
  for (int i = 0; i < 10; ++i) {
    arr ~= Point(uniform(0, 10), uniform(0, 10));
  }
  arr = arr.sort.uniq.array;
  Point[] dst;
  dst = arr.dup;
  return dst;
}

auto iterateByKey()
{
  bool[Point] set;
  for (int i = 0; i < 10; ++i) {
    set[Point(uniform(0, 10), uniform(0, 10))] = true;
  }
  Point[] arr;
  foreach (p; set.byKey) {
    arr ~= p;
  }
  return arr;
}

void test()
{
  for (int i = 0; i < 1000; ++i) {
    auto a = iterateByKey();
    auto b = iterateArr();
    auto c = a ~ b;
  }
}

template hasToString(T, Char)
{
    static if(isPointer!T && !isAggregateType!T)
    {
        // X* does not have toString, even if X is aggregate type has toString.
        enum hasToString = 0;
    }
    else static if (is(typeof({ T val = void; FormatSpec!Char f; val.toString((const(char)[] s){}, f); })))
    {
        enum hasToString = 4;
    }
    else static if (is(typeof({ T val = void; val.toString((const(char)[] s){}, "%s"); })))
    {
        enum hasToString = 3;
    }
    else static if (is(typeof({ T val = void; val.toString((const(char)[] s){}); })))
    {
        enum hasToString = 2;
    }
    else static if (is(typeof({ T val = void; return val.toString(); }()) S) && isSomeString!S)
    {
        enum hasToString = 1;
    }
    else
    {
        enum hasToString = 0;
    }
}

class C {
  int d;
}

static assert(is(typeof({ C val = void; return val.toString(); }()) S) && isSomeString!S);
static assert(is(typeof({ return redBlackTree!C; }())));
static assert(is(typeof(f())));

auto f()
{
  RedBlackTree!(C, (a, b)=>a.d > b.d, true)[96] t;
  foreach (ref s; t) {
    s = new typeof(t[0]);
  }
  return t;
}

void main()
{
  /+
  5.iota.each!(i => {
    writeln = i; // nothing happen
  });
  10.iota.each!((i){
    writeln = i;
  });
  15.iota.tee!(i => {
    writeln = i; // nothing happen
  });

  int[][] f = [[0, 1], [2, 3]];
  int[][] g = f.dup;
  int[][] h = f.map!(a => a.dup).array;
  g[0][0] = 9;
  f.writeln;  // modified
  h[0][0] = 0;
  f.writeln;  // unmodified

  auto rbt4 = redBlackTree!"a > b"(0, 1, 5, 7);
  while (rbt4.length) {
    rbt4.front.writeln;
    rbt4.removeFront;
  }
  +/
  bool[3] flags;
  flags[1] = true;
  flags.writeln;
  bool[3] arr = flags;
  arr[2] = true;
  arr.writeln;
  flags.writeln;
  test();
}

