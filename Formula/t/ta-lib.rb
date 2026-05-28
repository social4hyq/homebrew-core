class TaLib < Formula
  desc "Tools for market analysis"
  homepage "https://ta-lib.org/"
  url "https://github.com/ta-lib/ta-lib/releases/download/v0.6.4/ta-lib-0.6.4-src.tar.gz"
  sha256 "aa04066d17d69c73b1baaef0883414d3d56ab3775872d82916d1cdb376a3ae86"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "16dc9a521a4a779c36ce7803a9f895721ee1390f9b7548c9caf0bc14fd70c354"
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
