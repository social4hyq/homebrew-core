class Pla < Formula
  desc "Tool for building Gantt charts in PNG, EPS, PDF or SVG format"
  homepage "https://www.arpalert.org/pla.html"
  url "https://github.com/thierry-f-78/pla/archive/refs/tags/1.3.tar.gz"
  sha256 "966ff0de604cfe4fe6e9650ee7776c5096211ad76e060ff4fd9edbd711977ef2"
  license "GPL-2.0-only"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "237b5e3055273f4b59f40ffbff90dacd5f1deee50733dd0c315dda4642152d28"
  end

  depends_on "pkgconf" => :build
  depends_on "cairo"

  def install
    # Ubuntu-specific fix to add --no-as-needed linker flag on Linux.
    inreplace "Makefile", "LDFLAGS = -lm", "LDFLAGS = -lm -Wl,--no-as-needed" if OS.linux?
    system "make"
    bin.install "pla"
  end

  test do
    (testpath/"test.pla").write <<~EOS
      [4] REF0 Install des serveurs
        color #8cb6ce
        child 1
        child 2
        child 3

        [1] REF0 Install 1
          start 2010-04-08 01
          duration 24
          color #8cb6ce
          dep 2
          dep 6
    EOS
    system bin/"pla", "-i", testpath/"test.pla", "-o test"
  end
end
