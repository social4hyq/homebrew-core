class Cdargs < Formula
  desc "Directory bookmarking system - Enhanced cd utilities"
  homepage "https://github.com/cbxbiker61/cdargs"
  url "https://github.com/cbxbiker61/cdargs/archive/refs/tags/2.1.tar.gz"
  sha256 "062515c3fbd28c68f9fa54ff6a44b81cf647469592444af0872b5ecd7444df7d"
  license "GPL-2.0-or-later"
  head "https://github.com/cbxbiker61/cdargs.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b0228850b20e1a31df8bd9b3595354317e8ae81489eeda4d706273821db496b8"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build

  uses_from_macos "ncurses"

  # fixes zsh usage using the patch provided at the cdargs homepage
  # (See https://www.skamphausen.de/cgi-bin/ska/CDargs)
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/cdargs/1.35.patch"
    sha256 "adb4e73f6c5104432928cd7474a83901fe0f545f1910b51e4e81d67ecef80a96"
  end

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"

    rm Dir["contrib/Makefile*"]
    prefix.install "contrib"
    bash_completion.install_symlink "#{prefix}/contrib/cdargs-bash.sh"
  end

  def caveats
    <<~EOS
      Support files for bash, tcsh, and emacs have been installed to:
        #{prefix}/contrib
    EOS
  end

  test do
    system bin/"cdargs", "--version"
  end
end
