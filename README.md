# samurAI2015-2016

5th Place

# SamurAI Coding 2016-17

2015-16のコードをいじり2016-17用にした。

## やったこと

基本は **盤面評価** して一番良い手を選びます。そのような手が複数あるときはランダムで1つ選びます。

次の1手を全探索→さらに次の1手を攻撃のみ探索して2ターンでいい塗り方ができるようにしています。

方針として

- いい塗り方をしていて
- 相手の位置特定を頑張って
- 相手を殺していき
- 自分は安全に行動

していけば強くなるというのが去年やってきた感想です。

探索部分のコード（src/PlayerTarou.d）

```d
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
```

盤面評価をするスコアの設定（src/PlayerTarou.d）

```d
    static const Merits SPEAR_MERITS = new Merits.MeritsBuilder()
        .setTerr(50)
        .setSelf(0)
        .setKill(100000)
        .setHide(0.5)
        .setSafe(5000)
        .setUsur(40)
        .setMidd(1)
        .setGrup(5)
        .setTchd(1000)
        .setGiri(1)
        .setTrgt(1500)
        .setComb(300)
        .build();
    static const Merits SWORD_MERITS = new Merits.MeritsBuilder()
        .setTerr(50)
        .setSelf(0)
        .setKill(100000)
        .setHide(0.5)
        .setSafe(5000)
        .setUsur(40)
        .setMidd(1)
        .setTchd(1000)
        .setTrgt(1500)
        .setGiri(1)
        .setComb(300)
        .build();
    static const Merits BATTLEAX_MERITS = new Merits.MeritsBuilder()
        .setTerr(50)
        .setSelf(0)
        .setKill(100000)
        .setHide(0.5)
        .setSafe(5000)
        .setUsur(40)
        .setMidd(-1)
        .setGrup(5)
        .setTchd(1000)
        .setTrgt(1500)
        .setGiri(1)
        .setComb(300)
        .build();
    static const Merits[3] MERITS4WEAPON = [
      SPEAR_MERITS,
      SWORD_MERITS,
      BATTLEAX_MERITS
    ];

    static const Merits NEXT_SPEAR_MERITS = new Merits.MeritsBuilder()
        .setTerr(45)
        .setSelf(0)
        .setUsur(36)
        .setMidd(1)
        .setGrup(1)
        .build();
    static const Merits NEXT_SWORD_MERITS = new Merits.MeritsBuilder()
        .setTerr(45)
        .setSelf(0)
        .setUsur(36)
        .setMidd(1)
        .build();
    static const Merits NEXT_BATTLEAX_MERITS = new Merits.MeritsBuilder()
        .setTerr(45)
        .setSelf(0)
        .setUsur(36)
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
        .setUsur(25)
        .setSelf(0)
        .build();
```

### それぞれの評価値について

src/Merits.d に記載しています。

- self

自分のチームを塗ったスコア。0に設定

- kill

殺したかどうか。最高値100000を設定

- hide

隠れるかどうか。したほうがいいので0.5に設定

- terr(territory)

誰からも取られていない陣地を塗ったスコア。後述のusur（相手の陣地を奪う）よりこっちのスコアを高くした方が強い。

1ターン目に50。2ターン目に45を設定

- safe

安全かどうか。

5000を設定

- usur(usurp)

相手の陣地を塗ったスコア。

1ターン目に40。2ターン目に36を設定

- depl(deployment)

互いに離れているかどうか。離れているほうが視野が増えるので良いと思ったがそうでもなかった。

0を設定

- midd(middle)

真ん中にいるかどうか。

1を設定

- fght(fight)

2015-16の名残です・・・。ランクの高いやつは味方であろうが陣地を奪うというもの。

2016-17では関係ないので0を設定

- grup(group)

塗ったときにまとまっているかどうか（塗った場所の周りが自陣地だと評価が高い）。これを槍と鉞には設定したほうが強い。

5を設定

- krnt(killing rival next turn)

2015-16の名残です・・・。2015-16はターン順序が決まっていて自分と同じ武器相手（rival）だとrivalのターンまで2ターンあるときがあるので2ターン使って殺しにいくかどうか。

2016-17では関係ないので0を設定

同じ方針のものを後述のtargetで設定しています。

- tchd(tactical hiding)

殺されず、かつ次のターンでこちらのほうに相手が来れば殺せるという場所が存在する。そこに攻撃なしで隠れていれば評価を高くする。

1000を設定

- land

もやもやして作った評価値。あまりにも弱くなったので説明したくない・・・。自分の周りに自陣地が塗られていたら安全だろうというもの。めちゃくちゃビビりになってダメだった。

- mvat(moving after attack)

攻撃すると相手から居場所がバレる。なので攻撃した後に移動すれば相手を騙せるだろうというもの。これもないほうがよかった。

- giri(ぎりぎり)

相手がtchdしている可能性があるとき、ぎりぎりの安全地帯にいればカウンターができるだろうというもの。

1を設定

- trgt(target)

自分が先攻のとき、相手がdoneだと2ターン使って殺しにいける。

1500を設定

- comb(combo)

初期化時間中にbeam stack searchを実行している。これで探索した結果に沿うように動いたら評価を上げる。

300を設定
