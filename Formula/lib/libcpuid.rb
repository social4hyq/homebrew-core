class Libcpuid < Formula
  desc "Small C library for x86 CPU detection and feature extraction"
  homepage "https://github.com/anrieff/libcpuid"
  url "https://github.com/anrieff/libcpuid/archive/refs/tags/v0.8.1.tar.gz"
  sha256 "81f2f40da5d66b8220476e116cb40bca4e6a62c0d22bdeeb8e3856cf14607007"
  license "BSD-2-Clause"
  head "https://github.com/anrieff/libcpuid.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7d8fcb49d8178b08888ed4285d48816db36f21f3d5fffa7112817b97b7762b74"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  on_macos do
    depends_on arch: :x86_64

    # Can be undeprecated if upstream decides to support arm64 macOS
    # https://docs.brew.sh/Support-Tiers#future-macos-support
    # TODO: Make linux-only when removing macOS support
    deprecate! date: "2025-09-25", because: :unsupported
    disable! date: "2026-09-25", because: :unsupported
  end

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"cpuid_tool"
    assert_path_exists testpath/"raw.txt"
    assert_path_exists testpath/"report.txt"
    assert_match "CPUID is present", File.read(testpath/"report.txt")
  end
end
