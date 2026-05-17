class Vitetris < Formula
  desc "Terminal-based Tetris clone"
  homepage "https://www.victornils.net/tetris/"
  url "https://github.com/vicgeralds/vitetris/archive/refs/tags/v0.59.1.tar.gz"
  sha256 "699443df03c8d4bf2051838c1015da72039bbbdd0ab0eede891c59c840bdf58d"
  license "BSD-2-Clause"
  head "https://github.com/vicgeralds/vitetris.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9076a6a8d89793a50d22ceaf7ff542bf296d56821fff77af26748119b80429d3"
  end

  def install
    # workaround for newer clang
    ENV.append_to_cflags "-Wno-implicit-int" if DevelopmentTools.clang_build_version >= 1403

    # remove a 'strip' option not supported on OS X and root options for
    # 'install'
    inreplace "Makefile", "-strip --strip-all $(PROGNAME)", "-strip $(PROGNAME)"

    system "./configure", "--prefix=#{prefix}", "--without-xlib"
    system "make", "install"
  end

  test do
    system bin/"tetris", "-hiscore"
  end
end
