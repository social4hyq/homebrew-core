class Mtbl < Formula
  desc "Immutable sorted string table library"
  homepage "https://github.com/farsightsec/mtbl"
  url "https://dl.farsightsecurity.com/dist/mtbl/mtbl-1.7.1.tar.gz"
  sha256 "da2693ea8f9d915a09cdb55815ebd92e84211443b0d5525789d92d57a5381d7b"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b0f973b10e99ee5d20c4f27b65175d0a74eee3fae9cde1f2e04df564e1ac0f33"
  end

  head do
    url "https://github.com/farsightsec/mtbl.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkgconf" => :build
  depends_on "lz4"
  depends_on "snappy"
  depends_on "zstd"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "autoreconf", "--force", "--install", "--verbose" if build.head?
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"

    pkgshare.install "t/fileset-filter-data/animals-1.mtbl"
  end

  test do
    output = shell_output("#{bin}/mtbl_verify #{pkgshare}/animals-1.mtbl")
    assert_equal "#{pkgshare}/animals-1.mtbl: OK", output.chomp
  end
end
