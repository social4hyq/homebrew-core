class Fastbit < Formula
  desc "Open-source data processing library in NoSQL spirit"
  homepage "https://sdm.lbl.gov/fastbit/"
  # Upstream download url is blocking access: Cloudflare Error 1006: IP Address Restriction
  # Use an archived copy from archive.org until upstream url is restored
  url "https://web.archive.org/web/20210319090732/code.lbl.gov/frs/download.php/file/426/fastbit-2.0.3.tar.gz"
  mirror "https://code.lbl.gov/frs/download.php/file/426/fastbit-2.0.3.tar.gz"
  sha256 "1ddb16d33d869894f8d8cd745cd3198974aabebca68fa2b83eb44d22339466ec"
  license "BSD-3-Clause"
  revision 2

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "21b40c38e3b109039e9c2ee4cbe6d5eb9cefb713f1102108e1e54164d5982b39"
  end

  deprecate! date: "2024-06-18", because: :unmaintained
  disable! date: "2025-06-21", because: :unmaintained

  depends_on "openjdk"

  # Fix compilation with Xcode 9, reported by email on 2018-03-13
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/fastbit/xcode9.patch"
    sha256 "e1198caf262a125d2216d70cfec80ebe98d122760ffa5d99d34fc33646445390"
  end

  # Fix -flat_namespace being used on Big Sur and later.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-pre-0.4.2.418-big_sur.diff"
    sha256 "83af02f2aa2b746bb7225872cab29a253264be49db0ecebb12f841562d9a2923"
  end

  def install
    ENV.cxx11
    args = ["--with-java=#{Formula["openjdk"].opt_prefix}"]
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", *args, *std_configure_args
    system "make", "install"
    libexec.install lib/"fastbitjni.jar"
    bin.write_jar_script libexec/"fastbitjni.jar", "fastbitjni"
  end

  test do
    assert_equal prefix.to_s, shell_output("#{bin}/fastbit-config --prefix").chomp
    (testpath/"test.csv").write <<~CSV
      Potter,Harry
      Granger,Hermione
      Weasley,Ron
    CSV
    system bin/"ardea", "-d", testpath, "-m", "a:t,b:t", "-t", testpath/"test.csv"
  end
end
