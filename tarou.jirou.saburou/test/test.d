import std.stdio;
import std.range;
import std.algorithm;
import std.container;

void main()
{
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
}

