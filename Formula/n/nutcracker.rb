class Nutcracker < Formula
  desc "Proxy for memcached and redis"
  homepage "https://github.com/twitter/twemproxy"
  url "https://github.com/twitter/twemproxy/archive/refs/tags/0.5.0.tar.gz"
  sha256 "73f305d8525abbaaa6a5f203c1fba438f99319711bfcb2bb8b2f06f0d63d1633"
  license "Apache-2.0"
  revision 1
  head "https://github.com/twitter/twemproxy.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3c2bc6b5f4ed9218fba5583b7cb44a06e1b3f4612edfb12d7ef90f194a929d6c"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "libyaml"

  # Use Homebrew libyaml instead of the vendored one.
  # Adapted from Debian's equivalent patch.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/nutcracker/use-system-libyaml.patch"
    sha256 "9105f2bd784f291da5c3f3fb4f6876e62ab7a6f78256f81f5574d593924e424c"
  end

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", *std_configure_args
    system "make", "install"

    pkgshare.install "conf", "notes", "scripts"
  end

  test do
    assert_match version.to_s, shell_output("#{sbin}/nutcracker -V 2>&1")
  end
end
