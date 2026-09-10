class Httperf < Formula
  desc "Tool for measuring webserver performance"
  homepage "https://github.com/httperf/httperf"
  license "GPL-2.0-or-later"
  revision 4

  stable do
    url "https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/httperf/httperf-0.9.0.tar.gz"
    sha256 "e1a0bf56bcb746c04674c47b6cfa531fad24e45e9c6de02aea0d1c5f85a2bf1c"

    # Upstream patch for OpenSSL 1.1 compatibility
    # https://github.com/httperf/httperf/pull/48
    patch do
      url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/httperf/openssl-1.1.diff"
      sha256 "69d5003f60f5e46d25813775bbf861366fb751da4e0e4d2fe7530d7bb3f3660a"
    end
  end

  # Until the upstream GitHub repository creates a new release (something after
  # 0.9.0), we're unable to create a check that can identify new versions.
  livecheck do
    skip "No version information available to check"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b4ea0adbd672bebd30880a5279684b1c1ded1a75d6dc6494e870b24665dcce3d"
  end

  head do
    url "https://github.com/httperf/httperf.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "openssl@4"

  def install
    system "autoreconf", "--force", "--install", "--verbose" if build.head?

    # idleconn.c:164:28: error: passing argument 2 of ‘connect’ from incompatible pointer type
    ENV.append_to_cflags "-Wno-error=incompatible-pointer-types"

    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"httperf", "--version"
  end
end
