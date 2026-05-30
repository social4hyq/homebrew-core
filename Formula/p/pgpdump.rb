class Pgpdump < Formula
  desc "PGP packet visualizer"
  homepage "https://www.mew.org/~kazu/proj/pgpdump/en/"
  url "https://github.com/kazu-yamamoto/pgpdump/archive/refs/tags/v0.37.tar.gz"
  sha256 "bc3b6b85f3c95c68010883675283c1c905e6c4070ac5609ced1a87c53b3ee814"
  license "BSD-3-Clause"
  head "https://github.com/kazu-yamamoto/pgpdump.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5f1c8d1df98ffb9366dfbea1d872b66dbfc325568695293c93295830d6a4e4d6"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  uses_from_macos "bzip2"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"sig.pgp").write <<~EOS
      -----BEGIN PGP MESSAGE-----
      Version: GnuPG v1.2.6 (NetBSD)
      Comment: For info see https://www.gnupg.org

      owGbwMvMwCSYq3dE6sEMJU7GNYZJLGmZOanWn4xaQzIyixWAKFEhN7W4ODE9VaEk
      XyEpVaE4Mz0vNUUhqVIhwD1Aj6vDnpmVAaQeZogg060chvkFjPMr2CZNmPnwyebF
      fJP+td+b6biAYb779N1eL3gcHUyNsjliW1ekbZk6wRwA
      =+jUx
      -----END PGP MESSAGE-----
    EOS

    output = shell_output("#{bin}/pgpdump sig.pgp")
    assert_match("Key ID - 0x6D2EC41AE0982209", output)
  end
end
