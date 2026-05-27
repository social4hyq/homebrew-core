class Analog < Formula
  desc "Logfile analyzer"
  homepage "https://www.c-amie.co.uk/software/analog/"
  url "https://github.com/c-amie/analog-ce/archive/refs/tags/6.0.18.tar.gz"
  sha256 "6c5d3f05643196b64eadeccb7b5063e2508c0155ac34c1fe848f6d055c371933"
  license "GPL-2.0-only"
  head "https://github.com/c-amie/analog-ce.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5bd58e0e1ead70218465e4d7d7a9398a424313584e73b02392584ae40ee653b1"
  end

  depends_on "gd"
  depends_on "jpeg-turbo"
  depends_on "libpng"
  depends_on "minizip"
  depends_on "pcre2"

  uses_from_macos "bzip2"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    args = [
      "CC=#{ENV.cc}",
      "CFLAGS=#{ENV.cflags}",
      %Q(DEFS='-DLANGDIR="#{pkgshare}/lang/"' -DHAVE_GD -DHAVE_ZLIB -DHAVE_BZLIB -DHAVE_PCRE),
      "LIBS=-lgd -lpng -ljpeg -lz -lbz2 -lpcre2-8 -lminizip -lm",
      "OS=#{OS.mac? ? "OSX" : "UNIX"}",
      "SUBDIRS=libgd",
      "SUBDIROBJS=libgd/gdfontf.o",
    ]
    system "make", *args

    bin.install "analog"
    pkgshare.install "examples", "how-to", "images", "lang"
    pkgshare.install "analog.cfg-sample"
    (pkgshare/"examples").install "logfile.log"
    man1.install "analog.man" => "analog.1"
  end

  test do
    output = shell_output("#{bin}/analog #{pkgshare}/examples/logfile.log")
    assert_match "(United Kingdom)", output
  end
end
