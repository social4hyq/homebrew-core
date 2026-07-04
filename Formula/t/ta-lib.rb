class TaLib < Formula
  desc "Tools for market analysis"
  homepage "https://ta-lib.org/"
  url "https://github.com/ta-lib/ta-lib/releases/download/v0.7.1/ta-lib-0.7.1-src.tar.gz"
  sha256 "508981a5b85edab42ecee0b2d9c7dcd2c4ae9831e859e1aa4e549232734c27e1"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "88ea7089f2b33748f74a0c7a9a5b3781f9d2f2839e49862db43431e1a82e6791"
  end

  on_macos do
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  def install
    ENV.deparallelize
    # Call autoreconf on macOS to fix -flat_namespace usage
    system "autoreconf", "--force", "--install", "--verbose" if OS.mac?
    system "./configure", *std_configure_args
    system "make", "install"
    bin.install "src/tools/ta_regtest/.libs/ta_regtest"
  end

  test do
    system bin/"ta_regtest"
  end
end
