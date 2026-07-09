class Libextractor < Formula
  desc "Library to extract meta data from files"
  homepage "https://www.gnu.org/software/libextractor/"
  url "https://ftpmirror.gnu.org/gnu/libextractor/libextractor-1.17.tar.gz"
  mirror "https://ftp.gnu.org/gnu/libextractor/libextractor-1.17.tar.gz"
  sha256 "215c7d8dc10e0d7644509da2b47a6fa1ba5ebad8ce02904864e54abfb4c3059a"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f0ebf80b732ce2fc51353f4b3a226b7e3f6b80638d5f6ba47e3e703929323540"
  end

  depends_on "pkgconf" => :build
  depends_on "libtool"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  conflicts_with "csound", because: "both install `extract` binaries"

  def install
    ENV.deparallelize

    # macOS defines ntohll as a macro, clashing with the local definition
    inreplace "src/plugins/qt_extractor.c",
              "static uint64_t\nntohll (uint64_t n)",
              "#undef ntohll\n\\0"

    # 1.17 uses glibc-only `secure_getenv` guarded by `#if _GNU_SOURCE`, which
    # autoconf also defines on macOS and OHOS; use `getenv` there instead.
    inreplace "src/main/extractor_plugpath.c",
              "#if _GNU_SOURCE", "#if _GNU_SOURCE && !defined(__APPLE__) && !defined(__OHOS__)"

    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    fixture = test_fixtures("test.png")
    assert_match "Keywords for file", shell_output("#{bin}/extract #{fixture}")
  end
end
