module samurai.Merits;

interface Builder(T) {
  public T build();
}

immutable class Merits {
  public:
    immutable double self; // occupying out team's territory
    immutable double kill; // has killed
    immutable double hide; // being hidden
    immutable double terr; // occupying nobody's territory
    immutable double safe; // being safe
    immutable double usur; // occupying enemy's territory
    immutable double depl; // deployment for our team
    immutable double midd; // stay at middle in the field
    immutable double fght; // occupying hiscoreman's teritorry
    immutable double grup; // occupying with grouping
    immutable double krnt; // killing rival who is enemy w/ same weapon at next turn
    immutable double tchd; // has hidden tactically
    immutable double land; // making safe land
    immutable double mvat; // moved after attack
    immutable double giri; // girigiri
    immutable double trgt; // target
    immutable double comb; // combo
    immutable double muda; // attacked but no occupying
    immutable double chop; // occupying probable enemy's point
    immutable double lskl; // killing at last turn
    immutable double zako; // occupying score ga syoboi
    immutable double ysnk; // Yasya No Kamae
    immutable double ksnr; // kasanari
    immutable double yttk; // yattaka?! (occupying point in sokokamo)
    immutable double yttz; // yattaze (occupying point in predict)
    immutable double saki; // 身バレしているやつから先にkillをする

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
        double krnt = 0;
        double tchd = 0;
        double land = 0;
        double mvat = 0;
        double giri = 0;
        double trgt = 0;
        double comb = 0;
        double muda = 0;
        double chop = 0;
        double lskl = 0;
        double zako = 0;
        double ysnk = 0;
        double ksnr = 0;
        double yttk = 0;
        double yttz = 0;
        double saki = 0;

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
        MeritsBuilder setKrnt(double krnt) {
          this.krnt = krnt;
          return this;
        }
        MeritsBuilder setTchd(double tchd) {
          this.tchd = tchd;
          return this;
        }
        MeritsBuilder setLand(double land) {
          this.land = land;
          return this;
        }
        MeritsBuilder setMvat(double mvat) {
          this.mvat = mvat;
          return this;
        }
        MeritsBuilder setGiri(double giri) {
          this.giri = giri;
          return this;
        }
        MeritsBuilder setTrgt(double trgt) {
          this.trgt = trgt;
          return this;
        }
        MeritsBuilder setComb(double comb) {
          this.comb = comb;
          return this;
        }
        MeritsBuilder setMuda(double muda) {
          this.muda = muda;
          return this;
        }
        MeritsBuilder setChop(double chop) {
          this.chop = chop;
          return this;
        }
        MeritsBuilder setLskl(double lskl) {
          this.lskl = lskl;
          return this;
        }
        MeritsBuilder setZako(double zako) {
          this.zako = zako;
          return this;
        }
        MeritsBuilder setYsnk(double ysnk) {
          this.ysnk = ysnk;
          return this;
        }
        MeritsBuilder setKsnr(double ksnr) {
          this.ksnr = ksnr;
          return this;
        }
        MeritsBuilder setYttk(double yttk) {
          this.yttk = yttk;
          return this;
        }
        MeritsBuilder setYttz(double yttz) {
          this.yttz = yttz;
          return this;
        }
        MeritsBuilder setSaki(double saki) {
          this.saki = saki;
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
      this.krnt = mb.krnt;
      this.tchd = mb.tchd;
      this.land = mb.land;
      this.mvat = mb.mvat;
      this.giri = mb.giri;
      this.trgt = mb.trgt;
      this.comb = mb.comb;
      this.muda = mb.muda;
      this.chop = mb.chop;
      this.lskl = mb.lskl;
      this.zako = mb.zako;
      this.ysnk = mb.ysnk;
      this.ksnr = mb.ksnr;
      this.yttk = mb.yttk;
      this.yttz = mb.yttz;
      this.saki = mb.saki;
    }
}

