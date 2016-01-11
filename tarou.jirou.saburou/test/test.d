import std.stdio;
import std.range;
import std.algorithm;

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
}

