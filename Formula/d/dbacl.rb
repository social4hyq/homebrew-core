class Dbacl < Formula
  desc "Digramic Bayesian classifier"
  homepage "https://dbacl.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/dbacl/dbacl/1.14.1/dbacl-1.14.1.tar.gz"
  sha256 "ff0dfb67682e863b1c3250acc441ce77c033b9b21d8e8793e55b622e42005abd"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "79ed90e41822480bc0d3c947fb729c363635b5c4b69fa9681a601c6e2453870d"
  end

  def install
    args = []
    if OS.linux?
      # Help old config scripts identify arm64 linux
      args << "--build=aarch64-unknown-linux-gnu" if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      # Work around error: unknown type name 'locale_t'
      ENV.append "CFLAGS", "-std=gnu99"
    end

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"mark-twain.txt").write <<~EOS
      The report of my death was an exaggeration.
      The secret of getting ahead is getting started.
      Travel is fatal to prejudice, bigotry, and narrow-mindedness.
      I have never let my schooling interfere with my education.
      Whenever you find yourself on the side of the majority, it is time to pause and reflect.
      Kindness is the language which the deaf can hear and the blind can see.
      The two most important days in your life are the day you are born and the day you find out why.
      Truth is stranger than fiction, but it is because Fiction is obliged to stick to possibilities; Truth isn't.
      If you tell the truth, you don't have to remember anything.
      It's not the size of the dog in the fight, it's the size of the fight in the dog.
    EOS

    (testpath/"william-shakespeare.txt").write <<~EOS
      Hell is empty and all the devils are here.
      All that glitters is not gold
      To thine own self be true, and it must follow, as the night the day, thou canst not then be false to any man.
      Love all, trust a few, do wrong to none.
      To be, or not to be, that is the question
      Be not afraid of greatness: some are born great, some achieve greatness, and some have greatness thrust upon them.
      The lady doth protest too much, methinks.
      So full of artless jealousy is guilt, It spills itself in fearing to be spilt.
      If music be the food of love, play on.
      There is nothing either good or bad, but thinking makes it so.
      The course of true love never did run smooth.
    EOS

    system bin/"dbacl", "-l", "twain", "mark-twain.txt"
    system bin/"dbacl", "-l", "shake", "william-shakespeare.txt"

    output = pipe_output("#{bin}/dbacl -v -c twain -c shake", "to be or not to be")
    assert_equal "shake", output.strip
  end
end
