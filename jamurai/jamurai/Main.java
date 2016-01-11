public class Main implements Runnable {
  public static void main(String[] argv) {
    new Thread(null, new Main(), "", 16 * 1024 * 1024).start();
  }

  public void run() {
    GameInfo info = new GameInfo();
    OtameshiPlayer p = new OtameshiPlayer();

    while (true) {
      info.readTurnInfo();
      System.out.println("# Turn " + info.turn);
      if (info.curePeriod != 0) {
        if (info.curePeriod == 1) {
          p.setDup(info);
        }
        System.out.println("0");
      } else {
        p.play(info);
        System.out.println("0");
      }
    }
  }
}

