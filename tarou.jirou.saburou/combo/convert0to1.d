import std.stdio;
import std.conv;
import std.string;

void main()
{
  enum LUT = [
    0,
    3,
    4,
    1,
    2,
    7,
    8,
    5,
    6
  ];
  for (;;) {
    string l = readln;
    if (l.length == 0) {
      break;
    }
    foreach (i, a; l.split) {
      if (i) {
        write = " ";
      }
      write = LUT[a.to!int];
    }
    writeln;
  }
}

