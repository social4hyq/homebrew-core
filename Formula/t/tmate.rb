class Tmate < Formula
  desc "Instant terminal sharing"
  homepage "https://tmate.io/"
  license "ISC"
  head "https://github.com/tmate-io/tmate.git", branch: "master"

  stable do
    url "https://github.com/tmate-io/tmate/archive/refs/tags/2.4.0.tar.gz"
    sha256 "62b61eb12ab394012c861f6b48ba0bc04ac8765abca13bdde5a4d9105cb16138"

    # Fix finding `msgpack`
    # https://github.com/tmate-io/tmate/pull/281
    patch do
      url "https://github.com/tmate-io/tmate/commit/a5c6e80d3c54cd7faed52de5283b4f96bea86c13.patch?full_index=1"
      sha256 "d48006bf00d6addd5db7c6b875b7a890d6f9bc1a8984a9e12e1087af5ff58f35"
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a484a295e18e0c84ee9e60074abbff9e608f0f3fa6c6cd42071a467c8339604a"
  end

  deprecate! date: "2025-12-11", because: :unmaintained
  disable! date: "2026-12-11", because: :unmaintained

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build
  depends_on "libevent"
  depends_on "libssh"
  depends_on "msgpack"

  uses_from_macos "ncurses"

  def install
    system "sh", "autogen.sh"

    ENV.append "LDFLAGS", "-lresolv"
    system "./configure", "--sysconfdir=#{etc}", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"tmate", "-V"
  end
end
