module samurai.Merits;

interface Builder(T) {
  public T build();
}

immutable class Merits {
  public:
    immutable double self;
    immutable double kill;
    immutable double hide;
    immutable double terr;
    immutable double safe;
    immutable double usur;
    immutable double depl;
    immutable double midd;
    immutable double fght;
    immutable double grup;

    static class MeritsBuilder : Builder!Merits {
      private:
        double self = 0;
        double kill = 0;
        double hide = 0;
        double terr = 0;
        double safe = 0;
        double usur = 0;
        double depl = 0;
        double midd = 0;
        double fght = 0;
        double grup = 0;

      public:
      pure:
      nothrow:
      @safe:
        Merits build() {
          return new Merits(this);
        }

        MeritsBuilder setMidd(double midd) {
          this.midd = midd;
          return this;
        }
        MeritsBuilder setDepl(double depl) {
          this.depl = depl;
          return this;
        }
        MeritsBuilder setUsur(double usur) {
          this.usur = usur;
          return this;
        }
        MeritsBuilder setHide(double hide) {
          this.hide = hide;
          return this;
        }
        MeritsBuilder setKill(double kill) {
          this.kill = kill;
          return this;
        }
        MeritsBuilder setSelf(double self) {
          this.self = self;
          return this;
        }
        MeritsBuilder setTerr(double terr) {
          this.terr = terr;
          return this;
        }
        MeritsBuilder setSafe(double safe) {
          this.safe = safe;
          return this;
        }
        MeritsBuilder setFght(double fght) {
          this.fght = fght;
          return this;
        }
        MeritsBuilder setGrup(double grup) {
          this.grup = grup;
          return this;
        }
    }

  private:
    this(MeritsBuilder mb) immutable pure nothrow @safe {
      this.self = mb.self;
      this.kill = mb.kill;
      this.hide = mb.hide;
      this.terr = mb.terr;
      this.safe = mb.safe;
      this.usur = mb.usur;
      this.depl = mb.depl;
      this.midd = mb.midd;
      this.fght = mb.fght;
      this.grup = mb.grup;
    }
}

