class Podofo < Formula
  desc "Library to work with the PDF file format"
  homepage "https://github.com/podofo/podofo"
  url "https://github.com/podofo/podofo/archive/refs/tags/1.1.1.tar.gz"
  sha256 "16943528b37798d8663ffedc97190803e525d0a1dcb021fdbf9d35242831890a"
  license all_of: [
    { any_of: ["LGPL-2.0-or-later", "MPL-2.0"] },
    "GPL-2.0-or-later", # tools/

    # Additional licenses used in specific files
    "Apache-2.0", # src/podofo/private/FontUtils*
    "MIT",        # src/podofo/private/SASLprep*
    any_of: [     # src/podofo/private/OpenSSLInternal*
      { "LGPL-2.0-or-later" => { with: "cryptsetup-OpenSSL-exception" } },
      "MPL-2.0",
    ],
  ]
  head "https://github.com/podofo/podofo.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d81344343278367171c1ba533794a1fa2b16e5a692270f73b82ced87814953ef"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build

  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "jpeg-turbo"
  depends_on "libpng"
  depends_on "libtiff"
  depends_on "openssl@3"

  uses_from_macos "libxml2"

  on_ventura :or_older do
    depends_on "llvm"

    fails_with :clang do
      cause "error: 'to_chars' is unavailable: introduced in macOS 13.3"
    end
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    if OS.mac? && MacOS.version <= :ventura
      # When using Homebrew's superenv shims, we need to use HOMEBREW_LIBRARY_PATHS
      # rather than LDFLAGS for libc++ in order to correctly link to LLVM's libc++.
      ENV.prepend_path "HOMEBREW_LIBRARY_PATHS", Formula["llvm"].opt_lib/"c++"
      # Workaround for error: call to 'from_chars' is ambiguous
      inreplace "src/podofo/private/charconv_compat.h", "#define WANT_FROM_CHARS", ""
    end

    args = %W[
      -DCMAKE_INSTALL_NAME_DIR=#{opt_lib}
      -DCMAKE_BUILD_WITH_INSTALL_NAME_DIR=ON
      -DPODOFO_BUILD_UNSUPPORTED_TOOLS=TRUE
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    cp test_fixtures("test.pdf"), testpath
    assert_match "500 x 800 pts", shell_output("#{bin}/podofopdfinfo test.pdf")
  end
end
