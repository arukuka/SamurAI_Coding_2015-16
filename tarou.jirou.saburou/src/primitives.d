/**
This module is a submodule of $(LINK2 std_range.html, std.range).

It provides basic range functionality by defining several templates for testing
whether a given object is a _range, and what kind of _range it is:

$(BOOKTABLE ,
    $(TR $(TD $(D $(LREF isInputRange)))
        $(TD Tests if something is an $(I input _range), defined to be
        something from which one can sequentially read data using the
        primitives $(D front), $(D popFront), and $(D empty).
    ))
    $(TR $(TD $(D $(LREF isOutputRange)))
        $(TD Tests if something is an $(I output _range), defined to be
        something to which one can sequentially write data using the
        $(D $(LREF put)) primitive.
    ))
    $(TR $(TD $(D $(LREF isForwardRange)))
        $(TD Tests if something is a $(I forward _range), defined to be an
        input _range with the additional capability that one can save one's
        current position with the $(D save) primitive, thus allowing one to
        iterate over the same _range multiple times.
    ))
    $(TR $(TD $(D $(LREF isBidirectionalRange)))
        $(TD Tests if something is a $(I bidirectional _range), that is, a
        forward _range that allows reverse traversal using the primitives $(D
        back) and $(D popBack).
    ))
    $(TR $(TD $(D $(LREF isRandomAccessRange)))
        $(TD Tests if something is a $(I random access _range), which is a
        bidirectional _range that also supports the array subscripting
        operation via the primitive $(D opIndex).
    ))
)

It also provides number of templates that test for various _range capabilities:

$(BOOKTABLE ,
    $(TR $(TD $(D $(LREF hasMobileElements)))
        $(TD Tests if a given _range's elements can be moved around using the
        primitives $(D moveFront), $(D moveBack), or $(D moveAt).
    ))
    $(TR $(TD $(D $(LREF ElementType)))
        $(TD Returns the element type of a given _range.
    ))
    $(TR $(TD $(D $(LREF ElementEncodingType)))
        $(TD Returns the encoding element type of a given _range.
    ))
    $(TR $(TD $(D $(LREF hasSwappableElements)))
        $(TD Tests if a _range is a forward _range with swappable elements.
    ))
    $(TR $(TD $(D $(LREF hasAssignableElements)))
        $(TD Tests if a _range is a forward _range with mutable elements.
    ))
    $(TR $(TD $(D $(LREF hasLvalueElements)))
        $(TD Tests if a _range is a forward _range with elements that can be
        passed by reference and have their address taken.
    ))
    $(TR $(TD $(D $(LREF hasLength)))
        $(TD Tests if a given _range has the $(D length) attribute.
    ))
    $(TR $(TD $(D $(LREF isInfinite)))
        $(TD Tests if a given _range is an $(I infinite _range).
    ))
    $(TR $(TD $(D $(LREF hasSlicing)))
        $(TD Tests if a given _range supports the array slicing operation $(D
        R[x..y]).
    ))
)

Finally, it includes some convenience functions for manipulating ranges:

$(BOOKTABLE ,
    $(TR $(TD $(D $(LREF popFrontN)))
        $(TD Advances a given _range by up to $(I n) elements.
    ))
    $(TR $(TD $(D $(LREF popBackN)))
        $(TD Advances a given bidirectional _range from the right by up to
        $(I n) elements.
    ))
    $(TR $(TD $(D $(LREF popFrontExactly)))
        $(TD Advances a given _range by up exactly $(I n) elements.
    ))
    $(TR $(TD $(D $(LREF popBackExactly)))
        $(TD Advances a given bidirectional _range from the right by exactly
        $(I n) elements.
    ))
    $(TR $(TD $(D $(LREF moveFront)))
        $(TD Removes the front element of a _range.
    ))
    $(TR $(TD $(D $(LREF moveBack)))
        $(TD Removes the back element of a bidirectional _range.
    ))
    $(TR $(TD $(D $(LREF moveAt)))
        $(TD Removes the $(I i)'th element of a random-access _range.
    ))
    $(TR $(TD $(D $(LREF walkLength)))
        $(TD Computes the length of any _range in O(n) time.
    ))
)

Source: $(PHOBOSSRC std/range/_primitives.d)

Macros:

WIKI = Phobos/StdRange

Copyright: Copyright by authors 2008-.

License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).

Authors: $(WEB erdani.com, Andrei Alexandrescu), David Simcha,
and Jonathan M Davis. Credit for some of the ideas in building this module goes
to $(WEB fantascienza.net/leonardo/so/, Leonardo Maffi).
*/
module samurai.range.primitives;

import std.traits;

/**
Returns $(D true) if $(D R) is an input range. An input range must
define the primitives $(D empty), $(D popFront), and $(D front). The
following code should compile for any input range.

----
R r;              // can define a range object
if (r.empty) {}   // can test for empty
r.popFront();     // can invoke popFront()
auto h = r.front; // can get the front of the range of non-void type
----

The semantics of an input range (not checkable during compilation) are
assumed to be the following ($(D r) is an object of type $(D R)):

$(UL $(LI $(D r.empty) returns $(D false) iff there is more data
available in the range.)  $(LI $(D r.front) returns the current
element in the range. It may return by value or by reference. Calling
$(D r.front) is allowed only if calling $(D r.empty) has, or would
have, returned $(D false).) $(LI $(D r.popFront) advances to the next
element in the range. Calling $(D r.popFront) is allowed only if
calling $(D r.empty) has, or would have, returned $(D false).))

Params:
    R = type to be tested

Returns:
    true if R is an InputRange, false if not
 */
template isInputRange(R)
{
    enum bool isInputRange = is(typeof(
    (inout int = 0)
    {
        R r = R.init;     // can define a range object
        if (r.empty) {}   // can test for empty
        r.popFront();     // can invoke popFront()
        auto h = r.front; // can get the front of the range
    }));
}

///
@safe unittest
{
    struct A {}
    struct B
    {
        void popFront();
        @property bool empty();
        @property int front();
    }
    static assert(!isInputRange!A);
    static assert( isInputRange!B);
    static assert( isInputRange!(int[]));
    static assert( isInputRange!(char[]));
    static assert(!isInputRange!(char[4]));
    static assert( isInputRange!(inout(int)[]));
}

/+
puts the whole raw element $(D e) into $(D r). doPut will not attempt to
iterate, slice or transcode $(D e) in any way shape or form. It will $(B only)
call the correct primitive ($(D r.put(e)),  $(D r.front = e) or
$(D r(0)) once.

This can be important when $(D e) needs to be placed in $(D r) unchanged.
Furthermore, it can be useful when working with $(D InputRange)s, as doPut
guarantees that no more than a single element will be placed.
+/
private void doPut(R, E)(ref R r, auto ref E e)
{
    static if(is(PointerTarget!R == struct))
        enum usingPut = hasMember!(PointerTarget!R, "put");
    else
        enum usingPut = hasMember!(R, "put");

    static if (usingPut)
    {
        static assert(is(typeof(r.put(e))),
            "Cannot put a " ~ E.stringof ~ " into a " ~ R.stringof ~ ".");
        r.put(e);
    }
    else static if (isInputRange!R)
    {
        static assert(is(typeof(r.front = e)),
            "Cannot put a " ~ E.stringof ~ " into a " ~ R.stringof ~ ".");
        r.front = e;
        r.popFront();
    }
    else static if (is(typeof(r(e))))
    {
        r(e);
    }
    else
    {
        static assert (false,
            "Cannot put a " ~ E.stringof ~ " into a " ~ R.stringof ~ ".");
    }
}

@safe unittest
{
    static assert (!isNativeOutputRange!(int,     int));
    static assert ( isNativeOutputRange!(int[],   int));
    static assert (!isNativeOutputRange!(int[][], int));

    static assert (!isNativeOutputRange!(int,     int[]));
    static assert (!isNativeOutputRange!(int[],   int[]));
    static assert ( isNativeOutputRange!(int[][], int[]));

    static assert (!isNativeOutputRange!(int,     int[][]));
    static assert (!isNativeOutputRange!(int[],   int[][]));
    static assert (!isNativeOutputRange!(int[][], int[][]));

    static assert (!isNativeOutputRange!(int[4],   int));
    static assert ( isNativeOutputRange!(int[4][], int)); //Scary!
    static assert ( isNativeOutputRange!(int[4][], int[4]));

    static assert (!isNativeOutputRange!( char[],   char));
    static assert (!isNativeOutputRange!( char[],  dchar));
    static assert ( isNativeOutputRange!(dchar[],   char));
    static assert ( isNativeOutputRange!(dchar[],  dchar));

}

/++
Outputs $(D e) to $(D r). The exact effect is dependent upon the two
types. Several cases are accepted, as described below. The code snippets
are attempted in order, and the first to compile "wins" and gets
evaluated.

In this table "doPut" is a method that places $(D e) into $(D r), using the
correct primitive: $(D r.put(e)) if $(D R) defines $(D put), $(D r.front = e)
if $(D r) is an input range (followed by $(D r.popFront())), or $(D r(e))
otherwise.

$(BOOKTABLE ,
    $(TR
        $(TH Code Snippet)
        $(TH Scenario)
    )
    $(TR
        $(TD $(D r.doPut(e);))
        $(TD $(D R) specifically accepts an $(D E).)
    )
    $(TR
        $(TD $(D r.doPut([ e ]);))
        $(TD $(D R) specifically accepts an $(D E[]).)
    )
    $(TR
        $(TD $(D r.putChar(e);))
        $(TD $(D R) accepts some form of string or character. put will
            transcode the character $(D e) accordingly.)
    )
    $(TR
        $(TD $(D for (; !e.empty; e.popFront()) put(r, e.front);))
        $(TD Copying range $(D E) into $(D R).)
    )
)

Tip: $(D put) should $(I not) be used "UFCS-style", e.g. $(D r.put(e)).
Doing this may call $(D R.put) directly, by-passing any transformation
feature provided by $(D Range.put). $(D put(r, e)) is prefered.
 +/
void put(R, E)(ref R r, E e)
{
    //First level: simply straight up put.
    static if (is(typeof(doPut(r, e))))
    {
        doPut(r, e);
    }
    //Optional optimization block for straight up array to array copy.
    else static if (isDynamicArray!R && !isNarrowString!R && isDynamicArray!E && is(typeof(r[] = e[])))
    {
        immutable len = e.length;
        r[0 .. len] = e[];
        r = r[len .. $];
    }
    //Accepts E[] ?
    else static if (is(typeof(doPut(r, [e]))) && !isDynamicArray!R)
    {
        if (__ctfe)
        {
            E[1] arr = [e];
            doPut(r, arr[]);
        }
        else
            doPut(r, (ref e) @trusted { return (&e)[0..1]; }(e));
    }
    //special case for char to string.
    else static if (isSomeChar!E && is(typeof(putChar(r, e))))
    {
        putChar(r, e);
    }
    //Extract each element from the range
    //We can use "put" here, so we can recursively test a RoR of E.
    else static if (isInputRange!E && is(typeof(put(r, e.front))))
    {
        //Special optimization: If E is a narrow string, and r accepts characters no-wider than the string's
        //Then simply feed the characters 1 by 1.
        static if (isNarrowString!E && (
            (is(E : const  char[]) && is(typeof(doPut(r,  char.max))) && !is(typeof(doPut(r, dchar.max))) && !is(typeof(doPut(r, wchar.max)))) ||
            (is(E : const wchar[]) && is(typeof(doPut(r, wchar.max))) && !is(typeof(doPut(r, dchar.max)))) ) )
        {
            foreach(c; e)
                doPut(r, c);
        }
        else
        {
            for (; !e.empty; e.popFront())
                put(r, e.front);
        }
    }
    else
    {
        static assert (false, "Cannot put a " ~ E.stringof ~ " into a " ~ R.stringof ~ ".");
    }
}

@safe pure nothrow @nogc unittest
{
    static struct R() { void put(in char[]) {} }
    R!() r;
    put(r, 'a');
}

//Helper function to handle chars as quickly and as elegantly as possible
//Assumes r.put(e)/r(e) has already been tested
private void putChar(R, E)(ref R r, E e)
if (isSomeChar!E)
{
    ////@@@9186@@@: Can't use (E[]).init
    ref const( char)[] cstringInit();
    ref const(wchar)[] wstringInit();
    ref const(dchar)[] dstringInit();

    enum csCond = !isDynamicArray!R && is(typeof(doPut(r, cstringInit())));
    enum wsCond = !isDynamicArray!R && is(typeof(doPut(r, wstringInit())));
    enum dsCond = !isDynamicArray!R && is(typeof(doPut(r, dstringInit())));

    //Use "max" to avoid static type demotion
    enum ccCond = is(typeof(doPut(r,  char.max)));
    enum wcCond = is(typeof(doPut(r, wchar.max)));
    //enum dcCond = is(typeof(doPut(r, dchar.max)));

    //Fast transform a narrow char into a wider string
    static if ((wsCond && E.sizeof < wchar.sizeof) || (dsCond && E.sizeof < dchar.sizeof))
    {
        enum w = wsCond && E.sizeof < wchar.sizeof;
        Select!(w, wchar, dchar) c = e;
        typeof(c)[1] arr = [c];
        doPut(r, arr[]);
    }
    //Encode a wide char into a narrower string
    else static if (wsCond || csCond)
    {
        import std.utf : encode;
        /+static+/ Select!(wsCond, wchar[2], char[4]) buf; //static prevents purity.
        doPut(r, buf[0 .. encode(buf, e)]);
    }
    //Slowly encode a wide char into a series of narrower chars
    else static if (wcCond || ccCond)
    {
        import std.encoding : encode;
        alias C = Select!(wcCond, wchar, char);
        encode!(C, R)(e, r);
    }
    else
    {
        static assert (false, "Cannot put a " ~ E.stringof ~ " into a " ~ R.stringof ~ ".");
    }
}

pure unittest
{
    auto f = delegate (const(char)[]) {};
    putChar(f, cast(dchar)'a');
}


@safe pure unittest
{
    static struct R() { void put(in char[]) {} }
    R!() r;
    putChar(r, 'a');
}

unittest
{
    struct A {}
    static assert(!isInputRange!(A));
    struct B
    {
        void put(int) {}
    }
    B b;
    put(b, 5);
}

unittest
{
    int[] a = [1, 2, 3], b = [10, 20];
    auto c = a;
    put(a, b);
    assert(c == [10, 20, 3]);
    assert(a == [3]);
}

unittest
{
    int[] a = new int[10];
    int b;
    static assert(isInputRange!(typeof(a)));
    put(a, b);
}

unittest
{
    void myprint(in char[] s) { }
    auto r = &myprint;
    put(r, 'a');
}

unittest
{
    int[] a = new int[10];
    static assert(!__traits(compiles, put(a, 1.0L)));
    put(a, 1);
    assert(a.length == 9);
    /*
     * a[0] = 65;       // OK
     * a[0] = 'A';      // OK
     * a[0] = "ABC"[0]; // OK
     * put(a, "ABC");   // OK
     */
    put(a, "ABC");
    assert(a.length == 6);
}

unittest
{
    char[] a = new char[10];
    static assert(!__traits(compiles, put(a, 1.0L)));
    static assert(!__traits(compiles, put(a, 1)));
    // char[] is NOT output range.
    static assert(!__traits(compiles, put(a, 'a')));
    static assert(!__traits(compiles, put(a, "ABC")));
}

unittest
{
    int[][] a = new int[][10];
    int[]   b = new int[10];
    int     c;
    put(b, c);
    assert(b.length == 9);
    put(a, b);
    assert(a.length == 9);
    static assert(!__traits(compiles, put(a, c)));
}

unittest
{
    int[][] a = new int[][](3);
    int[]   b = [1];
    auto aa = a;
    put(aa, b);
    assert(aa == [[], []]);
    assert(a  == [[1], [], []]);
    int[][3] c = [2];
    aa = a;
    put(aa, c[]);
    assert(aa.empty);
    assert(a == [[2], [2], [2]]);
}

unittest
{
    // Test fix for bug 7476.
    struct LockingTextWriter
    {
        void put(dchar c){}
    }
    struct RetroResult
    {
        bool end = false;
        @property bool empty() const { return end; }
        @property dchar front(){ return 'a'; }
        void popFront(){ end = true; }
    }
    LockingTextWriter w;
    RetroResult r;
    put(w, r);
}

unittest
{
    import std.conv : to;
    import std.meta : AliasSeq;
    import std.typecons : tuple;

    static struct PutC(C)
    {
        string result;
        void put(const(C) c) { result ~= to!string((&c)[0..1]); }
    }
    static struct PutS(C)
    {
        string result;
        void put(const(C)[] s) { result ~= to!string(s); }
    }
    static struct PutSS(C)
    {
        string result;
        void put(const(C)[][] ss)
        {
            foreach(s; ss)
                result ~= to!string(s);
        }
    }

    PutS!char p;
    putChar(p, cast(dchar)'a');

    //Source Char
    foreach (SC; AliasSeq!(char, wchar, dchar))
    {
        SC ch = 'I';
        dchar dh = '♥';
        immutable(SC)[] s = "日本語！";
        immutable(SC)[][] ss = ["日本語", "が", "好き", "ですか", "？"];

        //Target Char
        foreach (TC; AliasSeq!(char, wchar, dchar))
        {
            //Testing PutC and PutS
            foreach (Type; AliasSeq!(PutC!TC, PutS!TC))
            (){ // avoid slow optimizations for large functions @@@BUG@@@ 2396
                Type type;
                auto sink = new Type();

                //Testing put and sink
                foreach (value ; tuple(type, sink))
                {
                    put(value, ch);
                    assert(value.result == "I");
                    put(value, dh);
                    assert(value.result == "I♥");
                    put(value, s);
                    assert(value.result == "I♥日本語！");
                    put(value, ss);
                    assert(value.result == "I♥日本語！日本語が好きですか？");
                }
            }();
        }
    }
}

unittest
{
    static struct CharRange
    {
        char c;
        enum empty = false;
        void popFront(){};
        ref char front() return @property
        {
            return c;
        }
    }
    CharRange c;
    put(c, cast(dchar)'H');
    put(c, "hello"d);
}

unittest
{
    // issue 9823
    const(char)[] r;
    void delegate(const(char)[]) dg = (s) { r = s; };
    put(dg, ["ABC"]);
    assert(r == "ABC");
}

unittest
{
    // issue 10571
    import std.format;
    string buf;
    formattedWrite((in char[] s) { buf ~= s; }, "%s", "hello");
    assert(buf == "hello");
}

unittest
{
    import std.format;
    import std.meta : AliasSeq;
    struct PutC(C)
    {
        void put(C){}
    }
    struct PutS(C)
    {
        void put(const(C)[]){}
    }
    struct CallC(C)
    {
        void opCall(C){}
    }
    struct CallS(C)
    {
        void opCall(const(C)[]){}
    }
    struct FrontC(C)
    {
        enum empty = false;
        auto front()@property{return C.init;}
        void front(C)@property{}
        void popFront(){}
    }
    struct FrontS(C)
    {
        enum empty = false;
        auto front()@property{return C[].init;}
        void front(const(C)[])@property{}
        void popFront(){}
    }
    void foo()
    {
        foreach(C; AliasSeq!(char, wchar, dchar))
        {
            formattedWrite((C c){},        "", 1, 'a', cast(wchar)'a', cast(dchar)'a', "a"c, "a"w, "a"d);
            formattedWrite((const(C)[]){}, "", 1, 'a', cast(wchar)'a', cast(dchar)'a', "a"c, "a"w, "a"d);
            formattedWrite(PutC!C(),       "", 1, 'a', cast(wchar)'a', cast(dchar)'a', "a"c, "a"w, "a"d);
            formattedWrite(PutS!C(),       "", 1, 'a', cast(wchar)'a', cast(dchar)'a', "a"c, "a"w, "a"d);
            CallC!C callC;
            CallS!C callS;
            formattedWrite(callC,          "", 1, 'a', cast(wchar)'a', cast(dchar)'a', "a"c, "a"w, "a"d);
            formattedWrite(callS,          "", 1, 'a', cast(wchar)'a', cast(dchar)'a', "a"c, "a"w, "a"d);
            formattedWrite(FrontC!C(),     "", 1, 'a', cast(wchar)'a', cast(dchar)'a', "a"c, "a"w, "a"d);
            formattedWrite(FrontS!C(),     "", 1, 'a', cast(wchar)'a', cast(dchar)'a', "a"c, "a"w, "a"d);
        }
        formattedWrite((dchar[]).init,     "", 1, 'a', cast(wchar)'a', cast(dchar)'a', "a"c, "a"w, "a"d);
    }
}

/+
Returns $(D true) if $(D R) is a native output range for elements of type
$(D E). An output range is defined functionally as a range that
supports the operation $(D doPut(r, e)) as defined above. if $(D doPut(r, e))
is valid, then $(D put(r,e)) will have the same behavior.

The two guarantees isNativeOutputRange gives over the larger $(D isOutputRange)
are:
1: $(D e) is $(B exactly) what will be placed (not $(D [e]), for example).
2: if $(D E) is a non $(empty) $(D InputRange), then placing $(D e) is
guaranteed to not overflow the range.
 +/
package template isNativeOutputRange(R, E)
{
    enum bool isNativeOutputRange = is(typeof(
    (inout int = 0)
    {
        R r = void;
        E e;
        doPut(r, e);
    }));
}

///
@safe unittest
{
    int[] r = new int[](4);
    static assert(isInputRange!(int[]));
    static assert( isNativeOutputRange!(int[], int));
    static assert(!isNativeOutputRange!(int[], int[]));
    static assert( isOutputRange!(int[], int[]));

    if (!r.empty)
        put(r, 1); //guaranteed to succeed
    if (!r.empty)
        put(r, [1, 2]); //May actually error out.
}
/++
Returns $(D true) if $(D R) is an output range for elements of type
$(D E). An output range is defined functionally as a range that
supports the operation $(D put(r, e)) as defined above.
 +/
template isOutputRange(R, E)
{
    enum bool isOutputRange = is(typeof(
    (inout int = 0)
    {
        R r = R.init;
        E e = E.init;
        put(r, e);
    }));
}

///
@safe unittest
{
    void myprint(in char[] s) { }
    static assert(isOutputRange!(typeof(&myprint), char));

    static assert(!isOutputRange!(char[], char));
    static assert( isOutputRange!(dchar[], wchar));
    static assert( isOutputRange!(dchar[], dchar));
}

@safe unittest
{
    import std.array;
    import std.stdio : writeln;

    auto app = appender!string();
    string s;
    static assert( isOutputRange!(Appender!string, string));
    static assert( isOutputRange!(Appender!string*, string));
    static assert(!isOutputRange!(Appender!string, int));
    static assert(!isOutputRange!(wchar[], wchar));
    static assert( isOutputRange!(dchar[], char));
    static assert( isOutputRange!(dchar[], string));
    static assert( isOutputRange!(dchar[], wstring));
    static assert( isOutputRange!(dchar[], dstring));

    static assert(!isOutputRange!(const(int)[], int));
    static assert(!isOutputRange!(inout(int)[], int));
}


/**
Returns $(D true) if $(D R) is a forward range. A forward range is an
input range $(D r) that can save "checkpoints" by saving $(D r.save)
to another value of type $(D R). Notable examples of input ranges that
are $(I not) forward ranges are file/socket ranges; copying such a
range will not save the position in the stream, and they most likely
reuse an internal buffer as the entire stream does not sit in
memory. Subsequently, advancing either the original or the copy will
advance the stream, so the copies are not independent.

The following code should compile for any forward range.

----
static assert(isInputRange!R);
R r1;
auto s1 = r1.save;
static assert (is(typeof(s1) == R));
----

Saving a range is not duplicating it; in the example above, $(D r1)
and $(D r2) still refer to the same underlying data. They just
navigate that data independently.

The semantics of a forward range (not checkable during compilation)
are the same as for an input range, with the additional requirement
that backtracking must be possible by saving a copy of the range
object with $(D save) and using it later.
 */
template isForwardRange(R)
{
    enum bool isForwardRange = isInputRange!R && is(typeof(
    (inout int = 0)
    {
        R r1 = R.init;
        // NOTE: we cannot check typeof(r1.save) directly
        // because typeof may not check the right type there, and
        // because we want to ensure the range can be copied.
        auto s1 = r1.save;
        static assert (is(typeof(s1) == R));
    }));
}

///
@safe unittest
{
    static assert(!isForwardRange!(int));
    static assert( isForwardRange!(int[]));
    static assert( isForwardRange!(inout(int)[]));
}

@safe unittest
{
    // BUG 14544
    struct R14544
    {
        int front() { return 0;}
        void popFront() {}
        bool empty() { return false; }
        R14544 save() {return this;}
    }

    static assert( isForwardRange!R14544 );
}

/**
Returns $(D true) if $(D R) is a bidirectional range. A bidirectional
range is a forward range that also offers the primitives $(D back) and
$(D popBack). The following code should compile for any bidirectional
range.

The semantics of a bidirectional range (not checkable during
compilation) are assumed to be the following ($(D r) is an object of
type $(D R)):

$(UL $(LI $(D r.back) returns (possibly a reference to) the last
element in the range. Calling $(D r.back) is allowed only if calling
$(D r.empty) has, or would have, returned $(D false).))
 */
template isBidirectionalRange(R)
{
    enum bool isBidirectionalRange = isForwardRange!R && is(typeof(
    (inout int = 0)
    {
        R r = R.init;
        r.popBack();
        auto t = r.back;
        auto w = r.front;
        static assert(is(typeof(t) == typeof(w)));
    }));
}

///
unittest
{
    alias R = int[];
    R r = [0,1];
    static assert(isForwardRange!R);           // is forward range
    r.popBack();                               // can invoke popBack
    auto t = r.back;                           // can get the back of the range
    auto w = r.front;
    static assert(is(typeof(t) == typeof(w))); // same type for front and back
}

@safe unittest
{
    struct A {}
    struct B
    {
        void popFront();
        @property bool empty();
        @property int front();
    }
    struct C
    {
        @property bool empty();
        @property C save();
        void popFront();
        @property int front();
        void popBack();
        @property int back();
    }
    static assert(!isBidirectionalRange!(A));
    static assert(!isBidirectionalRange!(B));
    static assert( isBidirectionalRange!(C));
    static assert( isBidirectionalRange!(int[]));
    static assert( isBidirectionalRange!(char[]));
    static assert( isBidirectionalRange!(inout(int)[]));
}

/**
Returns $(D true) if $(D R) is a random-access range. A random-access
range is a bidirectional range that also offers the primitive $(D
opIndex), OR an infinite forward range that offers $(D opIndex). In
either case, the range must either offer $(D length) or be
infinite. The following code should compile for any random-access
range.

The semantics of a random-access range (not checkable during
compilation) are assumed to be the following ($(D r) is an object of
type $(D R)): $(UL $(LI $(D r.opIndex(n)) returns a reference to the
$(D n)th element in the range.))

Although $(D char[]) and $(D wchar[]) (as well as their qualified
versions including $(D string) and $(D wstring)) are arrays, $(D
isRandomAccessRange) yields $(D false) for them because they use
variable-length encodings (UTF-8 and UTF-16 respectively). These types
are bidirectional ranges only.
 */
template isRandomAccessRange(R)
{
    enum bool isRandomAccessRange = is(typeof(
    (inout int = 0)
    {
        static assert(isBidirectionalRange!R ||
                      isForwardRange!R && isInfinite!R);
        R r = R.init;
        auto e = r[1];
        auto f = r.front;
        static assert(is(typeof(e) == typeof(f)));
        static assert(!isNarrowString!R);
        static assert(hasLength!R || isInfinite!R);

        static if(is(typeof(r[$])))
        {
            static assert(is(typeof(f) == typeof(r[$])));

            static if(!isInfinite!R)
                static assert(is(typeof(f) == typeof(r[$ - 1])));
        }
    }));
}

///
unittest
{
    alias R = int[];

    // range is finite and bidirectional or infinite and forward.
    static assert(isBidirectionalRange!R ||
                  isForwardRange!R && isInfinite!R);

    R r = [0,1];
    auto e = r[1]; // can index
    auto f = r.front;
    static assert(is(typeof(e) == typeof(f))); // same type for indexed and front
    static assert(!isNarrowString!R); // narrow strings cannot be indexed as ranges
    static assert(hasLength!R || isInfinite!R); // must have length or be infinite

    // $ must work as it does with arrays if opIndex works with $
    static if(is(typeof(r[$])))
    {
        static assert(is(typeof(f) == typeof(r[$])));

        // $ - 1 doesn't make sense with infinite ranges but needs to work
        // with finite ones.
        static if(!isInfinite!R)
            static assert(is(typeof(f) == typeof(r[$ - 1])));
    }
}

@safe unittest
{
    struct A {}
    struct B
    {
        void popFront();
        @property bool empty();
        @property int front();
    }
    struct C
    {
        void popFront();
        @property bool empty();
        @property int front();
        void popBack();
        @property int back();
    }
    struct D
    {
        @property bool empty();
        @property D save();
        @property int front();
        void popFront();
        @property int back();
        void popBack();
        ref int opIndex(uint);
        @property size_t length();
        alias opDollar = length;
        //int opSlice(uint, uint);
    }
    struct E
    {
        bool empty();
        E save();
        int front();
        void popFront();
        int back();
        void popBack();
        ref int opIndex(uint);
        size_t length();
        alias opDollar = length;
        //int opSlice(uint, uint);
    }
    static assert(!isRandomAccessRange!(A));
    static assert(!isRandomAccessRange!(B));
    static assert(!isRandomAccessRange!(C));
    static assert( isRandomAccessRange!(D));
    static assert( isRandomAccessRange!(E));
    static assert( isRandomAccessRange!(int[]));
    static assert( isRandomAccessRange!(inout(int)[]));
}

@safe unittest
{
    // Test fix for bug 6935.
    struct R
    {
        @disable this();

        @property bool empty() const { return false; }
        @property int front() const { return 0; }
        void popFront() {}

        @property R save() { return this; }

        @property int back() const { return 0; }
        void popBack(){}

        int opIndex(size_t n) const { return 0; }
        @property size_t length() const { return 0; }
        alias opDollar = length;

        void put(int e){  }
    }
    static assert(isInputRange!R);
    static assert(isForwardRange!R);
    static assert(isBidirectionalRange!R);
    static assert(isRandomAccessRange!R);
    static assert(isOutputRange!(R, int));
}

/**
Returns $(D true) iff $(D R) is an input range that supports the
$(D moveFront) primitive, as well as $(D moveBack) and $(D moveAt) if it's a
bidirectional or random access range. These may be explicitly implemented, or
may work via the default behavior of the module level functions $(D moveFront)
and friends. The following code should compile for any range
with mobile elements.

----
alias E = ElementType!R;
R r;
static assert(isInputRange!R);
static assert(is(typeof(moveFront(r)) == E));
static if (isBidirectionalRange!R)
    static assert(is(typeof(moveBack(r)) == E));
static if (isRandomAccessRange!R)
    static assert(is(typeof(moveAt(r, 0)) == E));
----
 */
template hasMobileElements(R)
{
    enum bool hasMobileElements = isInputRange!R && is(typeof(
    (inout int = 0)
    {
        alias E = ElementType!R;
        R r = R.init;
        static assert(is(typeof(moveFront(r)) == E));
        static if (isBidirectionalRange!R)
            static assert(is(typeof(moveBack(r)) == E));
        static if (isRandomAccessRange!R)
            static assert(is(typeof(moveAt(r, 0)) == E));
    }));
}

///
@safe unittest
{
    import std.algorithm : map;
    import std.range : iota, repeat;

    static struct HasPostblit
    {
        this(this) {}
    }

    auto nonMobile = map!"a"(repeat(HasPostblit.init));
    static assert(!hasMobileElements!(typeof(nonMobile)));
    static assert( hasMobileElements!(int[]));
    static assert( hasMobileElements!(inout(int)[]));
    static assert( hasMobileElements!(typeof(iota(1000))));

    static assert( hasMobileElements!( string));
    static assert( hasMobileElements!(dstring));
    static assert( hasMobileElements!( char[]));
    static assert( hasMobileElements!(dchar[]));
}

/**
The element type of $(D R). $(D R) does not have to be a range. The
element type is determined as the type yielded by $(D r.front) for an
object $(D r) of type $(D R). For example, $(D ElementType!(T[])) is
$(D T) if $(D T[]) isn't a narrow string; if it is, the element type is
$(D dchar). If $(D R) doesn't have $(D front), $(D ElementType!R) is
$(D void).
 */
template ElementType(R)
{
    static if (is(typeof(R.init.front.init) T))
        alias ElementType = T;
    else
        alias ElementType = void;
}

///
@safe unittest
{
    import std.range : iota;

    // Standard arrays: returns the type of the elements of the array
    static assert(is(ElementType!(int[]) == int));

    // Accessing .front retrieves the decoded dchar
    static assert(is(ElementType!(char[])  == dchar)); // rvalue
    static assert(is(ElementType!(dchar[]) == dchar)); // lvalue

    // Ditto
    static assert(is(ElementType!(string) == dchar));
    static assert(is(ElementType!(dstring) == immutable(dchar)));

    // For ranges it gets the type of .front.
    auto range = iota(0, 10);
    static assert(is(ElementType!(typeof(range)) == int));
}

@safe unittest
{
    static assert(is(ElementType!(byte[]) == byte));
    static assert(is(ElementType!(wchar[]) == dchar)); // rvalue
    static assert(is(ElementType!(wstring) == dchar));
}

@safe unittest
{
    enum XYZ : string { a = "foo" }
    auto x = XYZ.a.front;
    immutable char[3] a = "abc";
    int[] i;
    void[] buf;
    static assert(is(ElementType!(XYZ) == dchar));
    static assert(is(ElementType!(typeof(a)) == dchar));
    static assert(is(ElementType!(typeof(i)) == int));
    static assert(is(ElementType!(typeof(buf)) == void));
    static assert(is(ElementType!(inout(int)[]) == inout(int)));
    static assert(is(ElementType!(inout(int[])) == inout(int)));
}

@safe unittest
{
    static assert(is(ElementType!(int[5]) == int));
    static assert(is(ElementType!(int[0]) == int));
    static assert(is(ElementType!(char[5]) == dchar));
    static assert(is(ElementType!(char[0]) == dchar));
}

@safe unittest //11336
{
    static struct S
    {
        this(this) @disable;
    }
    static assert(is(ElementType!(S[]) == S));
}

@safe unittest // 11401
{
    // ElementType should also work for non-@propety 'front'
    struct E { ushort id; }
    struct R
    {
        E front() { return E.init; }
    }
    static assert(is(ElementType!R == E));
}

/**
The encoding element type of $(D R). For narrow strings ($(D char[]),
$(D wchar[]) and their qualified variants including $(D string) and
$(D wstring)), $(D ElementEncodingType) is the character type of the
string. For all other types, $(D ElementEncodingType) is the same as
$(D ElementType).
 */
template ElementEncodingType(R)
{
    static if (is(StringTypeOf!R) && is(R : E[], E))
        alias ElementEncodingType = E;
    else
        alias ElementEncodingType = ElementType!R;
}

///
@safe unittest
{
    import std.range : iota;
    // internally the range stores the encoded type
    static assert(is(ElementEncodingType!(char[])  == char));

    static assert(is(ElementEncodingType!(wstring) == immutable(wchar)));

    static assert(is(ElementEncodingType!(byte[]) == byte));

    auto range = iota(0, 10);
    static assert(is(ElementEncodingType!(typeof(range)) == int));
}

@safe unittest
{
    static assert(is(ElementEncodingType!(wchar[]) == wchar));
    static assert(is(ElementEncodingType!(dchar[]) == dchar));
    static assert(is(ElementEncodingType!(string)  == immutable(char)));
    static assert(is(ElementEncodingType!(dstring) == immutable(dchar)));
    static assert(is(ElementEncodingType!(int[])  == int));
}

@safe unittest
{
    enum XYZ : string { a = "foo" }
    auto x = XYZ.a.front;
    immutable char[3] a = "abc";
    int[] i;
    void[] buf;
    static assert(is(ElementType!(XYZ) : dchar));
    static assert(is(ElementEncodingType!(char[]) == char));
    static assert(is(ElementEncodingType!(string) == immutable char));
    static assert(is(ElementType!(typeof(a)) : dchar));
    static assert(is(ElementType!(typeof(i)) == int));
    static assert(is(ElementEncodingType!(typeof(i)) == int));
    static assert(is(ElementType!(typeof(buf)) : void));

    static assert(is(ElementEncodingType!(inout char[]) : inout(char)));
}

@safe unittest
{
    static assert(is(ElementEncodingType!(int[5]) == int));
    static assert(is(ElementEncodingType!(int[0]) == int));
    static assert(is(ElementEncodingType!(char[5]) == char));
    static assert(is(ElementEncodingType!(char[0]) == char));
}

/**
Returns $(D true) if $(D R) is an input range and has swappable
elements. The following code should compile for any range
with swappable elements.

----
R r;
static assert(isInputRange!R);
swap(r.front, r.front);
static if (isBidirectionalRange!R) swap(r.back, r.front);
static if (isRandomAccessRange!R) swap(r[], r.front);
----
 */
template hasSwappableElements(R)
{
    import std.algorithm : swap;
    enum bool hasSwappableElements = isInputRange!R && is(typeof(
    (inout int = 0)
    {
        R r = R.init;
        swap(r.front, r.front);
        static if (isBidirectionalRange!R) swap(r.back, r.front);
        static if (isRandomAccessRange!R) swap(r[0], r.front);
    }));
}

///
@safe unittest
{
    static assert(!hasSwappableElements!(const int[]));
    static assert(!hasSwappableElements!(const(int)[]));
    static assert(!hasSwappableElements!(inout(int)[]));
    static assert( hasSwappableElements!(int[]));

    static assert(!hasSwappableElements!( string));
    static assert(!hasSwappableElements!(dstring));
    static assert(!hasSwappableElements!( char[]));
    static assert( hasSwappableElements!(dchar[]));
}

/**
Returns $(D true) if $(D R) is an input range and has mutable
elements. The following code should compile for any range
with assignable elements.

----
R r;
static assert(isInputRange!R);
r.front = r.front;
static if (isBidirectionalRange!R) r.back = r.front;
static if (isRandomAccessRange!R) r[0] = r.front;
----
 */
template hasAssignableElements(R)
{
    enum bool hasAssignableElements = isInputRange!R && is(typeof(
    (inout int = 0)
    {
        R r = R.init;
        r.front = r.front;
        static if (isBidirectionalRange!R) r.back = r.front;
        static if (isRandomAccessRange!R) r[0] = r.front;
    }));
}

///
@safe unittest
{
    static assert(!hasAssignableElements!(const int[]));
    static assert(!hasAssignableElements!(const(int)[]));
    static assert( hasAssignableElements!(int[]));
    static assert(!hasAssignableElements!(inout(int)[]));

    static assert(!hasAssignableElements!( string));
    static assert(!hasAssignableElements!(dstring));
    static assert(!hasAssignableElements!( char[]));
    static assert( hasAssignableElements!(dchar[]));
}

/**
Tests whether the range $(D R) has lvalue elements. These are defined as
elements that can be passed by reference and have their address taken.
The following code should compile for any range with lvalue elements.
----
void passByRef(ref ElementType!R stuff);
...
static assert(isInputRange!R);
passByRef(r.front);
static if (isBidirectionalRange!R) passByRef(r.back);
static if (isRandomAccessRange!R) passByRef(r[0]);
----
*/
template hasLvalueElements(R)
{
    enum bool hasLvalueElements = isInputRange!R && is(typeof(
    (inout int = 0)
    {
        void checkRef(ref ElementType!R stuff);
        R r = R.init;

        checkRef(r.front);
        static if (isBidirectionalRange!R) checkRef(r.back);
        static if (isRandomAccessRange!R) checkRef(r[0]);
    }));
}

///
@safe unittest
{
    import std.range : iota, chain;

    static assert( hasLvalueElements!(int[]));
    static assert( hasLvalueElements!(const(int)[]));
    static assert( hasLvalueElements!(inout(int)[]));
    static assert( hasLvalueElements!(immutable(int)[]));
    static assert(!hasLvalueElements!(typeof(iota(3))));

    static assert(!hasLvalueElements!( string));
    static assert( hasLvalueElements!(dstring));
    static assert(!hasLvalueElements!( char[]));
    static assert( hasLvalueElements!(dchar[]));

    auto c = chain([1, 2, 3], [4, 5, 6]);
    static assert( hasLvalueElements!(typeof(c)));
}

@safe unittest
{
    // bugfix 6336
    struct S { immutable int value; }
    static assert( isInputRange!(S[]));
    static assert( hasLvalueElements!(S[]));
}

/**
Returns $(D true) if $(D R) has a $(D length) member that returns an
integral type. $(D R) does not have to be a range. Note that $(D
length) is an optional primitive as no range must implement it. Some
ranges do not store their length explicitly, some cannot compute it
without actually exhausting the range (e.g. socket streams), and some
other ranges may be infinite.

Although narrow string types ($(D char[]), $(D wchar[]), and their
qualified derivatives) do define a $(D length) property, $(D
hasLength) yields $(D false) for them. This is because a narrow
string's length does not reflect the number of characters, but instead
the number of encoding units, and as such is not useful with
range-oriented algorithms.
 */
template hasLength(R)
{
    enum bool hasLength = !isNarrowString!R && is(typeof(
    (inout int = 0)
    {
        R r = R.init;
        ulong l = r.length;
    }));
}

///
@safe unittest
{
    static assert(!hasLength!(char[]));
    static assert( hasLength!(int[]));
    static assert( hasLength!(inout(int)[]));

    struct A { ulong length; }
    struct B { size_t length() { return 0; } }
    struct C { @property size_t length() { return 0; } }
    static assert( hasLength!(A));
    static assert( hasLength!(B));
    static assert( hasLength!(C));
}

/**
Returns $(D true) if $(D R) is an infinite input range. An
infinite input range is an input range that has a statically-defined
enumerated member called $(D empty) that is always $(D false),
for example:

----
struct MyInfiniteRange
{
    enum bool empty = false;
    ...
}
----
 */

template isInfinite(R)
{
    static if (isInputRange!R && __traits(compiles, { enum e = R.empty; }))
        enum bool isInfinite = !R.empty;
    else
        enum bool isInfinite = false;
}

///
@safe unittest
{
    import std.range : Repeat;
    static assert(!isInfinite!(int[]));
    static assert( isInfinite!(Repeat!(int)));
}

/**
Returns $(D true) if $(D R) offers a slicing operator with integral boundaries
that returns a forward range type.

For finite ranges, the result of $(D opSlice) must be of the same type as the
original range type. If the range defines $(D opDollar), then it must support
subtraction.

For infinite ranges, when $(I not) using $(D opDollar), the result of
$(D opSlice) must be the result of $(LREF take) or $(LREF takeExactly) on the
original range (they both return the same type for infinite ranges). However,
when using $(D opDollar), the result of $(D opSlice) must be that of the
original range type.

The following code must compile for $(D hasSlicing) to be $(D true):

----
R r = void;

static if(isInfinite!R)
    typeof(take(r, 1)) s = r[1 .. 2];
else
{
    static assert(is(typeof(r[1 .. 2]) == R));
    R s = r[1 .. 2];
}

s = r[1 .. 2];

static if(is(typeof(r[0 .. $])))
{
    static assert(is(typeof(r[0 .. $]) == R));
    R t = r[0 .. $];
    t = r[0 .. $];

    static if(!isInfinite!R)
    {
        static assert(is(typeof(r[0 .. $ - 1]) == R));
        R u = r[0 .. $ - 1];
        u = r[0 .. $ - 1];
    }
}

static assert(isForwardRange!(typeof(r[1 .. 2])));
static assert(hasLength!(typeof(r[1 .. 2])));
----
 */
template hasSlicing(R)
{
    enum bool hasSlicing = isForwardRange!R && !isNarrowString!R && is(typeof(
    (inout int = 0)
    {
        R r = R.init;

        static if(isInfinite!R)
        {
            typeof(r[1 .. 1]) s = r[1 .. 2];
        }
        else
        {
            static assert(is(typeof(r[1 .. 2]) == R));
            R s = r[1 .. 2];
        }

        s = r[1 .. 2];

        static if(is(typeof(r[0 .. $])))
        {
            static assert(is(typeof(r[0 .. $]) == R));
            R t = r[0 .. $];
            t = r[0 .. $];

            static if(!isInfinite!R)
            {
                static assert(is(typeof(r[0 .. $ - 1]) == R));
                R u = r[0 .. $ - 1];
                u = r[0 .. $ - 1];
            }
        }

        static assert(isForwardRange!(typeof(r[1 .. 2])));
        static assert(hasLength!(typeof(r[1 .. 2])));
    }));
}

///
@safe unittest
{
    import std.range : takeExactly;
    static assert( hasSlicing!(int[]));
    static assert( hasSlicing!(const(int)[]));
    static assert(!hasSlicing!(const int[]));
    static assert( hasSlicing!(inout(int)[]));
    static assert(!hasSlicing!(inout int []));
    static assert( hasSlicing!(immutable(int)[]));
    static assert(!hasSlicing!(immutable int[]));
    static assert(!hasSlicing!string);
    static assert( hasSlicing!dstring);

    enum rangeFuncs = "@property int front();" ~
                      "void popFront();" ~
                      "@property bool empty();" ~
                      "@property auto save() { return this; }" ~
                      "@property size_t length();";

    struct A { mixin(rangeFuncs); int opSlice(size_t, size_t); }
    struct B { mixin(rangeFuncs); B opSlice(size_t, size_t); }
    struct C { mixin(rangeFuncs); @disable this(); C opSlice(size_t, size_t); }
    struct D { mixin(rangeFuncs); int[] opSlice(size_t, size_t); }
    static assert(!hasSlicing!(A));
    static assert( hasSlicing!(B));
    static assert( hasSlicing!(C));
    static assert(!hasSlicing!(D));

    struct InfOnes
    {
        enum empty = false;
        void popFront() {}
        @property int front() { return 1; }
        @property InfOnes save() { return this; }
        auto opSlice(size_t i, size_t j) { return takeExactly(this, j - i); }
        auto opSlice(size_t i, Dollar d) { return this; }

        struct Dollar {}
        Dollar opDollar() const { return Dollar.init; }
    }

    static assert(hasSlicing!InfOnes);
}

/**
This is a best-effort implementation of $(D length) for any kind of
range.

If $(D hasLength!Range), simply returns $(D range.length) without
checking $(D upTo) (when specified).

Otherwise, walks the range through its length and returns the number
of elements seen. Performes $(BIGOH n) evaluations of $(D range.empty)
and $(D range.popFront()), where $(D n) is the effective length of $(D
range).

The $(D upTo) parameter is useful to "cut the losses" in case
the interest is in seeing whether the range has at least some number
of elements. If the parameter $(D upTo) is specified, stops if $(D
upTo) steps have been taken and returns $(D upTo).

Infinite ranges are compatible, provided the parameter $(D upTo) is
specified, in which case the implementation simply returns upTo.
 */
auto walkLength(Range)(Range range)
    if (isInputRange!Range && !isInfinite!Range)
{
    static if (hasLength!Range)
        return range.length;
    else
    {
        size_t result;
        for ( ; !range.empty ; range.popFront() )
            ++result;
        return result;
    }
}
/// ditto
auto walkLength(Range)(Range range, const size_t upTo)
    if (isInputRange!Range)
{
    static if (hasLength!Range)
        return range.length;
    else static if (isInfinite!Range)
        return upTo;
    else
    {
        size_t result;
        for ( ; result < upTo && !range.empty ; range.popFront() )
            ++result;
        return result;
    }
}

@safe unittest
{
    import std.algorithm : filter;
    import std.range : recurrence, take;

    //hasLength Range
    int[] a = [ 1, 2, 3 ];
    assert(walkLength(a) == 3);
    assert(walkLength(a, 0) == 3);
    assert(walkLength(a, 2) == 3);
    assert(walkLength(a, 4) == 3);

    //Forward Range
    auto b = filter!"true"([1, 2, 3, 4]);
    assert(b.walkLength() == 4);
    assert(b.walkLength(0) == 0);
    assert(b.walkLength(2) == 2);
    assert(b.walkLength(4) == 4);
    assert(b.walkLength(6) == 4);

    //Infinite Range
    auto fibs = recurrence!"a[n-1] + a[n-2]"(1, 1);
    assert(!__traits(compiles, fibs.walkLength()));
    assert(fibs.take(10).walkLength() == 10);
    assert(fibs.walkLength(55) == 55);
}

/**
    Eagerly advances $(D r) itself (not a copy) up to $(D n) times (by
    calling $(D r.popFront)). $(D popFrontN) takes $(D r) by $(D ref),
    so it mutates the original range. Completes in $(BIGOH 1) steps for ranges
    that support slicing and have length.
    Completes in $(BIGOH n) time for all other ranges.

    Returns:
    How much $(D r) was actually advanced, which may be less than $(D n) if
    $(D r) did not have at least $(D n) elements.

    $(D popBackN) will behave the same but instead removes elements from
    the back of the (bidirectional) range instead of the front.
*/
size_t popFrontN(Range)(ref Range r, size_t n)
    if (isInputRange!Range)
{
    static if (hasLength!Range)
    {
        n = cast(size_t) (n < r.length ? n : r.length);
    }

    static if (hasSlicing!Range && is(typeof(r = r[n .. $])))
    {
        r = r[n .. $];
    }
    else static if (hasSlicing!Range && hasLength!Range) //TODO: Remove once hasSlicing forces opDollar.
    {
        r = r[n .. r.length];
    }
    else
    {
        static if (hasLength!Range)
        {
            foreach (i; 0 .. n)
                r.popFront();
        }
        else
        {
            foreach (i; 0 .. n)
            {
                if (r.empty) return i;
                r.popFront();
            }
        }
    }
    return n;
}

/// ditto
size_t popBackN(Range)(ref Range r, size_t n)
    if (isBidirectionalRange!Range)
{
    static if (hasLength!Range)
    {
        n = cast(size_t) (n < r.length ? n : r.length);
    }

    static if (hasSlicing!Range && is(typeof(r = r[0 .. $ - n])))
    {
        r = r[0 .. $ - n];
    }
    else static if (hasSlicing!Range && hasLength!Range) //TODO: Remove once hasSlicing forces opDollar.
    {
        r = r[0 .. r.length - n];
    }
    else
    {
        static if (hasLength!Range)
        {
            foreach (i; 0 .. n)
                r.popBack();
        }
        else
        {
            foreach (i; 0 .. n)
            {
                if (r.empty) return i;
                r.popBack();
            }
        }
    }
    return n;
}

///
@safe unittest
{
    int[] a = [ 1, 2, 3, 4, 5 ];
    a.popFrontN(2);
    assert(a == [ 3, 4, 5 ]);
    a.popFrontN(7);
    assert(a == [ ]);
}

///
@safe unittest
{
    import std.algorithm : equal;
    import std.range : iota;
    auto LL = iota(1L, 7L);
    auto r = popFrontN(LL, 2);
    assert(equal(LL, [3L, 4L, 5L, 6L]));
    assert(r == 2);
}

///
@safe unittest
{
    int[] a = [ 1, 2, 3, 4, 5 ];
    a.popBackN(2);
    assert(a == [ 1, 2, 3 ]);
    a.popBackN(7);
    assert(a == [ ]);
}

///
@safe unittest
{
    import std.algorithm : equal;
    import std.range : iota;
    auto LL = iota(1L, 7L);
    auto r = popBackN(LL, 2);
    assert(equal(LL, [1L, 2L, 3L, 4L]));
    assert(r == 2);
}

/**
    Eagerly advances $(D r) itself (not a copy) exactly $(D n) times (by
    calling $(D r.popFront)). $(D popFrontExactly) takes $(D r) by $(D ref),
    so it mutates the original range. Completes in $(BIGOH 1) steps for ranges
    that support slicing, and have either length or are infinite.
    Completes in $(BIGOH n) time for all other ranges.

    Note: Unlike $(LREF popFrontN), $(D popFrontExactly) will assume that the
    range holds at least $(D n) elements. This makes $(D popFrontExactly)
    faster than $(D popFrontN), but it also means that if $(D range) does
    not contain at least $(D n) elements, it will attempt to call $(D popFront)
    on an empty range, which is undefined behavior. So, only use
    $(D popFrontExactly) when it is guaranteed that $(D range) holds at least
    $(D n) elements.

    $(D popBackExactly) will behave the same but instead removes elements from
    the back of the (bidirectional) range instead of the front.
*/
void popFrontExactly(Range)(ref Range r, size_t n)
    if (isInputRange!Range)
{
    static if (hasLength!Range)
        assert(n <= r.length, "range is smaller than amount of items to pop");

    static if (hasSlicing!Range && is(typeof(r = r[n .. $])))
        r = r[n .. $];
    else static if (hasSlicing!Range && hasLength!Range) //TODO: Remove once hasSlicing forces opDollar.
        r = r[n .. r.length];
    else
        foreach (i; 0 .. n)
            r.popFront();
}

/// ditto
void popBackExactly(Range)(ref Range r, size_t n)
    if (isBidirectionalRange!Range)
{
    static if (hasLength!Range)
        assert(n <= r.length, "range is smaller than amount of items to pop");

    static if (hasSlicing!Range && is(typeof(r = r[0 .. $ - n])))
        r = r[0 .. $ - n];
    else static if (hasSlicing!Range && hasLength!Range) //TODO: Remove once hasSlicing forces opDollar.
        r = r[0 .. r.length - n];
    else
        foreach (i; 0 .. n)
            r.popBack();
}

///
@safe unittest
{
    import std.algorithm : filterBidirectional, equal;

    auto a = [1, 2, 3];
    a.popFrontExactly(1);
    assert(a == [2, 3]);
    a.popBackExactly(1);
    assert(a == [2]);

    string s = "日本語";
    s.popFrontExactly(1);
    assert(s == "本語");
    s.popBackExactly(1);
    assert(s == "本");

    auto bd = filterBidirectional!"true"([1, 2, 3]);
    bd.popFrontExactly(1);
    assert(bd.equal([2, 3]));
    bd.popBackExactly(1);
    assert(bd.equal([2]));
}

/**
   Moves the front of $(D r) out and returns it. Leaves $(D r.front) in a
   destroyable state that does not allocate any resources (usually equal
   to its $(D .init) value).
*/
ElementType!R moveFront(R)(R r)
{
    static if (is(typeof(&r.moveFront))) {
        return r.moveFront();
    } else static if (!hasElaborateCopyConstructor!(ElementType!R)) {
        return r.front;
    } else static if (is(typeof(&(r.front())) == ElementType!R*)) {
        import std.algorithm : move;
        return move(r.front);
    } else {
        static assert(0,
                "Cannot move front of a range with a postblit and an rvalue front.");
    }
}

///
@safe unittest
{
    auto a = [ 1, 2, 3 ];
    assert(moveFront(a) == 1);

    // define a perfunctory input range
    struct InputRange
    {
        @property bool empty() { return false; }
        @property int front() { return 42; }
        void popFront() {}
        int moveFront() { return 43; }
    }
    InputRange r;
    assert(moveFront(r) == 43);
}

@safe unittest
{
    struct R
    {
        @property ref int front() { static int x = 42; return x; }
        this(this){}
    }
    R r;
    assert(moveFront(r) == 42);
}

/**
   Moves the back of $(D r) out and returns it. Leaves $(D r.back) in a
   destroyable state that does not allocate any resources (usually equal
   to its $(D .init) value).
*/
ElementType!R moveBack(R)(R r)
{
    static if (is(typeof(&r.moveBack))) {
        return r.moveBack();
    } else static if (!hasElaborateCopyConstructor!(ElementType!R)) {
        return r.back;
    } else static if (is(typeof(&(r.back())) == ElementType!R*)) {
        import std.algorithm : move;
        return move(r.back);
    } else {
        static assert(0,
                "Cannot move back of a range with a postblit and an rvalue back.");
    }
}

///
@safe unittest
{
    struct TestRange
    {
        int payload = 5;
        @property bool empty() { return false; }
        @property TestRange save() { return this; }
        @property ref int front() return { return payload; }
        @property ref int back() return { return payload; }
        void popFront() { }
        void popBack() { }
    }
    static assert(isBidirectionalRange!TestRange);
    TestRange r;
    auto x = moveBack(r);
    assert(x == 5);
}

/**
   Moves element at index $(D i) of $(D r) out and returns it. Leaves $(D
   r.front) in a destroyable state that does not allocate any resources
   (usually equal to its $(D .init) value).
*/
ElementType!R moveAt(R, I)(R r, I i) if (isIntegral!I)
{
    static if (is(typeof(&r.moveAt))) {
        return r.moveAt(i);
    } else static if (!hasElaborateCopyConstructor!(ElementType!(R))) {
        return r[i];
    } else static if (is(typeof(&r[i]) == ElementType!R*)) {
        import std.algorithm : move;
        return move(r[i]);
    } else {
        static assert(0,
                "Cannot move element of a range with a postblit and rvalue elements.");
    }
}

///
@safe unittest
{
    auto a = [1,2,3,4];
    foreach(idx, it; a)
    {
        assert(it == moveAt(a, idx));
    }
}

@safe unittest
{
    import std.internal.test.dummyrange;

    foreach(DummyType; AllDummyRanges) {
        auto d = DummyType.init;
        assert(moveFront(d) == 1);

        static if (isBidirectionalRange!DummyType) {
            assert(moveBack(d) == 10);
        }

        static if (isRandomAccessRange!DummyType) {
            assert(moveAt(d, 2) == 3);
        }
    }
}

/**
Implements the range interface primitive $(D empty) for built-in
arrays. Due to the fact that nonmember functions can be called with
the first argument using the dot notation, $(D array.empty) is
equivalent to $(D empty(array)).
 */

@property bool empty(T)(in T[] a) @safe pure nothrow @nogc
{
    return !a.length;
}

///
@safe pure nothrow unittest
{
    auto a = [ 1, 2, 3 ];
    assert(!a.empty);
    assert(a[3 .. $].empty);
}

/**
Implements the range interface primitive $(D save) for built-in
arrays. Due to the fact that nonmember functions can be called with
the first argument using the dot notation, $(D array.save) is
equivalent to $(D save(array)). The function does not duplicate the
content of the array, it simply returns its argument.
 */

@property T[] save(T)(T[] a) @safe pure nothrow @nogc
{
    return a;
}

///
@safe pure nothrow unittest
{
    auto a = [ 1, 2, 3 ];
    auto b = a.save;
    assert(b is a);
}

/**
Implements the range interface primitive $(D popFront) for built-in
arrays. Due to the fact that nonmember functions can be called with
the first argument using the dot notation, $(D array.popFront) is
equivalent to $(D popFront(array)). For $(GLOSSARY narrow strings),
$(D popFront) automatically advances to the next $(GLOSSARY code
point).
*/

void popFront(T)(ref T[] a) @safe pure nothrow @nogc
if (!isNarrowString!(T[]) && !is(T[] == void[]))
{
    assert(a.length, "Attempting to popFront() past the end of an array of " ~ T.stringof);
    a = a[1 .. $];
}

///
@safe pure nothrow unittest
{
    auto a = [ 1, 2, 3 ];
    a.popFront();
    assert(a == [ 2, 3 ]);
}

version(unittest)
{
    static assert(!is(typeof({          int[4] a; popFront(a); })));
    static assert(!is(typeof({ immutable int[] a; popFront(a); })));
    static assert(!is(typeof({          void[] a; popFront(a); })));
}

// Specialization for narrow strings. The necessity of
void popFront(C)(ref C[] str) @trusted pure nothrow
if (isNarrowString!(C[]))
{
    assert(str.length, "Attempting to popFront() past the end of an array of " ~ C.stringof);

    static if(is(Unqual!C == char))
    {
        immutable c = str[0];
        if(c < 0x80)
        {
            //ptr is used to avoid unnnecessary bounds checking.
            str = str.ptr[1 .. str.length];
        }
        else
        {
             import core.bitop : bsr;
             auto msbs = 7 - bsr(~c);
             if((msbs < 2) | (msbs > 6))
             {
                 //Invalid UTF-8
                 msbs = 1;
             }
             str = str[msbs .. $];
        }
    }
    else static if(is(Unqual!C == wchar))
    {
        immutable u = str[0];
        str = str[1 + (u >= 0xD800 && u <= 0xDBFF) .. $];
    }
    else static assert(0, "Bad template constraint.");
}

@safe pure unittest
{
    import std.meta : AliasSeq;

    foreach(S; AliasSeq!(string, wstring, dstring))
    {
        S s = "\xC2\xA9hello";
        s.popFront();
        assert(s == "hello");

        S str = "hello\U00010143\u0100\U00010143";
        foreach(dchar c; ['h', 'e', 'l', 'l', 'o', '\U00010143', '\u0100', '\U00010143'])
        {
            assert(str.front == c);
            str.popFront();
        }
        assert(str.empty);

        static assert(!is(typeof({          immutable S a; popFront(a); })));
        static assert(!is(typeof({ typeof(S.init[0])[4] a; popFront(a); })));
    }

    C[] _eatString(C)(C[] str)
    {
        while(!str.empty)
            str.popFront();

        return str;
    }
    enum checkCTFE = _eatString("ウェブサイト@La_Verité.com");
    static assert(checkCTFE.empty);
    enum checkCTFEW = _eatString("ウェブサイト@La_Verité.com"w);
    static assert(checkCTFEW.empty);
}

/**
Implements the range interface primitive $(D popBack) for built-in
arrays. Due to the fact that nonmember functions can be called with
the first argument using the dot notation, $(D array.popBack) is
equivalent to $(D popBack(array)). For $(GLOSSARY narrow strings), $(D
popFront) automatically eliminates the last $(GLOSSARY code point).
*/

void popBack(T)(ref T[] a) @safe pure nothrow @nogc
if (!isNarrowString!(T[]) && !is(T[] == void[]))
{
    assert(a.length);
    a = a[0 .. $ - 1];
}

///
@safe pure nothrow unittest
{
    auto a = [ 1, 2, 3 ];
    a.popBack();
    assert(a == [ 1, 2 ]);
}

version(unittest)
{
    static assert(!is(typeof({ immutable int[] a; popBack(a); })));
    static assert(!is(typeof({          int[4] a; popBack(a); })));
    static assert(!is(typeof({          void[] a; popBack(a); })));
}

// Specialization for arrays of char
void popBack(T)(ref T[] a) @safe pure
if (isNarrowString!(T[]))
{
    assert(a.length, "Attempting to popBack() past the front of an array of " ~ T.stringof);
    a = a[0 .. $ - std.utf.strideBack(a, $)];
}

@safe pure unittest
{
    import std.meta : AliasSeq;

    foreach(S; AliasSeq!(string, wstring, dstring))
    {
        S s = "hello\xE2\x89\xA0";
        s.popBack();
        assert(s == "hello");
        S s3 = "\xE2\x89\xA0";
        auto c = s3.back;
        assert(c == cast(dchar)'\u2260');
        s3.popBack();
        assert(s3 == "");

        S str = "\U00010143\u0100\U00010143hello";
        foreach(dchar ch; ['o', 'l', 'l', 'e', 'h', '\U00010143', '\u0100', '\U00010143'])
        {
            assert(str.back == ch);
            str.popBack();
        }
        assert(str.empty);

        static assert(!is(typeof({          immutable S a; popBack(a); })));
        static assert(!is(typeof({ typeof(S.init[0])[4] a; popBack(a); })));
    }
}

/**
Implements the range interface primitive $(D front) for built-in
arrays. Due to the fact that nonmember functions can be called with
the first argument using the dot notation, $(D array.front) is
equivalent to $(D front(array)). For $(GLOSSARY narrow strings), $(D
front) automatically returns the first $(GLOSSARY code point) as a $(D
dchar).
*/
@property ref T front(T)(T[] a) @safe pure nothrow @nogc
if (!isNarrowString!(T[]) && !is(T[] == void[]))
{
    assert(a.length, "Attempting to fetch the front of an empty array of " ~ T.stringof);
    return a[0];
}

///
@safe pure nothrow unittest
{
    int[] a = [ 1, 2, 3 ];
    assert(a.front == 1);
}

@safe pure nothrow unittest
{
    auto a = [ 1, 2 ];
    a.front = 4;
    assert(a.front == 4);
    assert(a == [ 4, 2 ]);

    immutable b = [ 1, 2 ];
    assert(b.front == 1);

    int[2] c = [ 1, 2 ];
    assert(c.front == 1);
}

@property dchar front(T)(T[] a) @safe pure if (isNarrowString!(T[]))
{
    import std.utf : decode;
    assert(a.length, "Attempting to fetch the front of an empty array of " ~ T.stringof);
    size_t i = 0;
    return decode(a, i);
}

/**
Implements the range interface primitive $(D back) for built-in
arrays. Due to the fact that nonmember functions can be called with
the first argument using the dot notation, $(D array.back) is
equivalent to $(D back(array)). For $(GLOSSARY narrow strings), $(D
back) automatically returns the last $(GLOSSARY code point) as a $(D
dchar).
*/
@property ref T back(T)(T[] a) @safe pure nothrow @nogc
if (!isNarrowString!(T[]))
{
    assert(a.length, "Attempting to fetch the back of an empty array of " ~ T.stringof);
    return a[$ - 1];
}

///
@safe pure nothrow unittest
{
    int[] a = [ 1, 2, 3 ];
    assert(a.back == 3);
    a.back += 4;
    assert(a.back == 7);
}

@safe pure nothrow unittest
{
    immutable b = [ 1, 2, 3 ];
    assert(b.back == 3);

    int[3] c = [ 1, 2, 3 ];
    assert(c.back == 3);
}

// Specialization for strings
@property dchar back(T)(T[] a) @safe pure if (isNarrowString!(T[]))
{
    import std.utf : decode;
    assert(a.length, "Attempting to fetch the back of an empty array of " ~ T.stringof);
    size_t i = a.length - std.utf.strideBack(a, a.length);
    return decode(a, i);
}

