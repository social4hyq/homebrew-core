class SNail < Formula
  desc "Fork of Heirloom mailx"
  homepage "https://www.sdaoden.eu/code.html"
  url "https://www.sdaoden.eu/downloads/s-nail-14.9.25.tar.xz"
  sha256 "20ff055be9829b69d46ebc400dfe516a40d287d7ce810c74355d6bdc1a28d8a9"
  license all_of: [
    "BSD-2-Clause", # file-dotlock.h
    "BSD-3-Clause",
    "BSD-4-Clause",
    "ISC",
    "HPND-sell-variant", # GSSAPI code
    "RSA-MD", # MD5 code
  ]

  livecheck do
    url :homepage
    regex(/href=.*?s-nail[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2dced91cb75797584ca04328c33f7b3c46f976368e25bb7c3da08366ba92aee2"
  end

  depends_on "libidn2"
  depends_on "openssl@3"

  uses_from_macos "ncurses"

  def install
    system "make", "CC=#{ENV.cc}",
                   "C_INCLUDE_PATH=#{Formula["openssl@3"].opt_include}",
                   "LDFLAGS=-L#{Formula["openssl@3"].opt_lib}",
                   "VAL_PREFIX=#{prefix}",
                   "OPT_DOTLOCK=no",
                   "config"
    system "make", "build"
    system "make", "install"
  end

  test do
    timestamp = 844_221_007
    ENV["SOURCE_DATE_EPOCH"] = timestamp.to_s

    date1 = Time.at(timestamp).strftime("%a %b %e %T %Y")
    date2 = Time.at(timestamp).strftime("%a, %d %b %Y %T %z")

    expected = <<~EOS
      From reproducible_build #{date1.chomp}
      Date: #{date2.chomp}
      User-Agent: s-nail reproducible_build

      Hello oh you Hammer2!
    EOS

    input = "Hello oh you Hammer2!\n"
    output = pipe_output("#{bin}/s-nail -#:/ -Sexpandaddr -", input, 0)
    assert_equal expected, output.chomp
  end
end
