class Srtp < Formula
  desc "Implementation of the Secure Real-time Transport Protocol"
  homepage "https://github.com/cisco/libsrtp"
  url "https://github.com/cisco/libsrtp/archive/refs/tags/v2.8.0.tar.gz"
  sha256 "d123dcff5c56d4f1a9006f2b311ea99a85016cbf3bb24b1007885d422237db85"
  license "BSD-3-Clause"
  compatibility_version 1
  head "https://github.com/cisco/libsrtp.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ab551d07a8a770974276ad5abcc9f42c7a47748bf5034126cdd550b3759dfd81"
  end

  depends_on "pkgconf" => :build
  depends_on "openssl@3"

  def install
    system "./configure", "--enable-openssl", *std_configure_args
    system "make", "test"
    system "make", "shared_library"
    system "make", "install" # Can't go in parallel of building the dylib
    libexec.install "test/rtpw"
  end

  test do
    system libexec/"rtpw", "-l"
  end
end
