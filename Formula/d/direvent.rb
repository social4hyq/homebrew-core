class Direvent < Formula
  desc "Monitors events in the file system directories"
  homepage "https://www.gnu.org.ua/software/direvent/direvent.html"
  url "https://ftpmirror.gnu.org/gnu/direvent/direvent-5.4.tar.gz"
  mirror "https://ftp.gnu.org/gnu/direvent/direvent-5.4.tar.gz"
  sha256 "1dbbc6192aab67e345725148603d570c6a2828380c964215762af91524d795ba"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a8ca1336e600d5758eec50d0edb21764fc975528eb234189349d76e9ad3eeb0f"
  end

  def install
    # Fix compile with newer Clang
    ENV.append_to_cflags "-Wno-implicit-function-declaration" if DevelopmentTools.clang_build_version >= 1403

    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make"
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/direvent --version")
  end
end
