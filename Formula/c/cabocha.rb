class Cabocha < Formula
  desc "Yet Another Japanese Dependency Structure Analyzer"
  homepage "https://taku910.github.io/cabocha/"
  # Files are listed in https://drive.google.com/drive/folders/0B4y35FiV1wh7cGRCUUJHVTNJRnM
  url "https://distfiles.macports.org/cabocha/cabocha-0.69.tar.bz2"
  mirror "https://mirrorservice.org/sites/ftp.netbsd.org/pub/pkgsrc/distfiles/cabocha-20160909/cabocha-0.69.tar.bz2"
  sha256 "9db896d7f9d83fc3ae34908b788ae514ae19531eb89052e25f061232f6165992"
  license any_of: ["BSD-3-Clause", "LGPL-2.1-or-later"]

  livecheck do
    url :homepage
    regex(%r{>\d{4}/\d{2}/\d{2}\s+(\d+(?:\.\d+)+)<}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0ca0fb2a0e23f06c30eb6ccbec1d754c08aacdd63e5422da01b2c6e859183980"
  end

  depends_on "crf++"
  depends_on "mecab"
  depends_on "mecab-ipadic"

  def install
    ENV["LIBS"] = "-liconv" if OS.mac?

    inreplace "Makefile.in" do |s|
      s.change_make_var! "CFLAGS", ENV.cflags || ""
      s.change_make_var! "CXXFLAGS", ENV.cflags || ""
    end

    args = %W[
      --disable-dependency-tracking
      --prefix=#{prefix}
      --with-charset=UTF8
      --with-posset=IPA
    ]
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", *args
    system "make", "install"
  end

  test do
    md5 = if OS.mac?
      "md5"
    else
      "md5sum"
    end
    result = pipe_output(md5, pipe_output(bin/"cabocha", "CaboCha はフリーソフトウェアです。", 0))
    assert_equal "a5b8293e6ebcb3246c54ecd66d6e18ee", result.chomp.split.first
  end
end
