class MoonBuggy < Formula
  desc "Drive some car across the moon"
  homepage "https://www.seehuhn.de/programs/moon-buggy"
  url "https://www.seehuhn.de/programs/moon-buggy/moon-buggy-1.1.0.tar.gz"
  sha256 "259ae6e7b1838c40532af5c0f20cd7c6173cd5c552ede408114064475bcfc5b6"
  license any_of: ["GPL-2.0-or-later", "GPL-3.0-or-later"]

  # Upstream uses a similar version format for stable and unstable versions
  # (e.g. 1.0 is stable but 1.0.51 is experimental), so this identifies stable
  # versions by looking for the trailing `stable version` annotation.
  livecheck do
    url :homepage
    regex(/href=.*?moon[._-]buggy[._-]v?(\d+(?:\.\d+)+)\.t.*[^<]+?stable\s+version/im)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "baea15e50b8721978202869dc9224fb24bb78d0b0021259afd1daab72b33dad3"
  end

  head do
    url "https://github.com/seehuhn/moon-buggy.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  uses_from_macos "ncurses"

  def install
    args = ["--mandir=#{man}", "--infodir=#{info}"]
    if build.head?
      system "./autogen.sh"
    elsif OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      args << "--build=aarch64-unknown-linux-gnu"
    end
    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    assert_match(/Moon-Buggy #{version}$/, shell_output("#{bin}/moon-buggy -V"))
  end
end
