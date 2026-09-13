class TaLib < Formula
  desc "Tools for market analysis"
  homepage "https://ta-lib.org/"
  url "https://github.com/ta-lib/ta-lib/releases/download/v0.8.1/ta-lib-0.8.1-src.tar.gz"
  sha256 "ec59ccd88c0c77f618587d858787c8f9d06c40460a09d66751926f6fd670f985"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f5840b250caae2f70042e7db090c7dd202b93e10b19771d357b391c795b30c88"
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
