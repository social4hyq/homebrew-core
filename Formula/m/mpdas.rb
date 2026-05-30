class Mpdas < Formula
  desc "C++ client to submit tracks to audioscrobbler"
  homepage "https://www.50hz.ws/mpdas/"
  url "https://www.50hz.ws/mpdas/mpdas-0.4.5.tar.gz"
  sha256 "c9103d7b897e76cd11a669e1c062d74cb73574efc7ba87de3b04304464e8a9ca"
  license "BSD-3-Clause"
  head "https://github.com/hrkfdn/mpdas.git", branch: "master"

  livecheck do
    url :homepage
    regex(/href=.*?mpdas[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a86b886b8da82bd10d170afa2f714a9783c7dec9ea1c1e1c76344cf14f0d0bea"
  end

  depends_on "pkgconf" => :build
  depends_on "libmpdclient"

  uses_from_macos "curl"

  def install
    system "make", "PREFIX=#{prefix}", "MANPREFIX=#{man1}", "CONFIG=#{etc}", "install"
    etc.install "mpdasrc.example"
  end

  service do
    run opt_bin/"mpdas"
    keep_alive true
    working_dir HOMEBREW_PREFIX
  end

  test do
    system bin/"mpdas", "-v"
  end
end
