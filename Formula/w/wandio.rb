class Wandio < Formula
  desc "Transparently read from and write to zip, bzip2, lzma or zstd archives"
  homepage "https://github.com/LibtraceTeam/wandio"
  url "https://github.com/LibtraceTeam/wandio/archive/refs/tags/4.2.6-1.tar.gz"
  version "4.2.6"
  sha256 "f035d4d6beadf7a7e5619fb73db5a84d338008b5f4d6b1b8843619547248ec73"
  license "LGPL-3.0-or-later"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:[.-]\d+)+)$/i)
    strategy :git do |tags, regex|
      tags.filter_map { |tag| tag[regex, 1]&.gsub(/-1$/, "") }
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f307da1c0309b1b405b3eb63a8ebc851d26d7b832b84f0b8bbfdea0ab35d4948"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "lz4"
  depends_on "lzo"
  depends_on "xz" # For LZMA
  depends_on "zstd"

  uses_from_macos "bzip2"
  uses_from_macos "curl"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "./bootstrap.sh"
    system "./configure", "--disable-silent-rules",
                          "--with-http",
                          *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"wandiocat", "-z", "9", "-Z", "gzip", "-o", "test.gz",
      test_fixtures("test.png"), test_fixtures("test.pdf")
    assert_path_exists testpath/"test.gz"
  end
end
