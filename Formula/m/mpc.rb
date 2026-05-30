class Mpc < Formula
  desc "Command-line music player client for mpd"
  homepage "https://www.musicpd.org/clients/mpc/"
  url "https://www.musicpd.org/download/mpc/0/mpc-0.35.tar.xz"
  sha256 "382959c3bfa2765b5346232438650491b822a16607ff5699178aa1386e3878d4"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://www.musicpd.org/download/mpc/0/"
    regex(/href=.*?mpc[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fed9888eb7a163052f8592761398d504e55cddd3d5d1ca101860691d1aded0b6"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "libmpdclient"

  def install
    system "meson", "setup", "_build", *std_meson_args
    system "meson", "compile", "-C", "_build", "--verbose"
    system "meson", "install", "-C", "_build"

    bash_completion.install "contrib/mpc-completion.bash" => "mpc"
    rm share/"doc/mpc/contrib/mpc-completion.bash"
  end

  test do
    assert_match "query", shell_output("#{bin}/mpc list 2>&1", 1)
    assert_match "-F _mpc", shell_output("bash -c 'source #{bash_completion}/mpc && complete -p mpc'")
  end
end
