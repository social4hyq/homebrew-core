class Darkstat < Formula
  desc "Network traffic analyzer"
  homepage "https://unix4lyfe.org/darkstat/"
  url "https://github.com/emikulic/darkstat/archive/refs/tags/3.0.722.tar.gz"
  sha256 "5c8e66d4c478b6d7e58f4c842823a09125509bf6851017ff70e32b32ce95b01b"
  license all_of: [
    "GPL-2.0-only",
    "ISC",
    "BSD-2-Clause", # tree.h
    "BSD-3-Clause", # queue.h
  ]
  head "https://github.com/emikulic/darkstat.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "80db3bb42448ff0d0561b8a60426c4a30faf5df40e78cd22453ad7dee63a32c2"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  uses_from_macos "libpcap"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  # Patch reported to upstream on 2017-10-08
  # Work around `redefinition of clockid_t` issue on 10.12 SDK or newer
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/darkstat/clock_gettime.patch"
    sha256 "001b81d417a802f16c5bc4577c3b840799511a79ceedec27fc7ff1273df1018b"
  end

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    system sbin/"darkstat", "--verbose", "-r", test_fixtures("test.pcap")
  end
end
