class Lief < Formula
  desc "Library to Instrument Executable Formats"
  homepage "https://lief.re/"
  url "https://github.com/lief-project/LIEF/archive/refs/tags/0.17.6.tar.gz"
  sha256 "5fbbd19c85912d417eabbaef2b98e70144496356964685b82e0792d708b9be87"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4f8e96e424c1564e7ea864c9b2ff46d364e61ccc31a4d5e5b7bd32c23a113474"
  end

  depends_on "cmake" => :build
  depends_on "frozen" => :build
  depends_on "nlohmann-json" => :build
  depends_on "utf8cpp" => :build
  depends_on "fmt"
  depends_on "mbedtls@3" # https://github.com/lief-project/LIEF/commit/71e69423090e1bfaee7d2512a843605a373b1026
  depends_on "spdlog"
  depends_on "tl-expected" => :no_linkage

  def install
    rm_r(Dir["third-party/*"] - Dir["third-party/tcb-span*"])

    args = %w[
      -DBUILD_SHARED_LIBS=ON
      -DLIEF_EXAMPLES=OFF
      -DLIEF_EXTERNAL_SPDLOG=ON
      -DLIEF_OPT_EXTERNAL_EXPECTED=ON
      -DLIEF_OPT_FROZEN_EXTERNAL=ON
      -DLIEF_OPT_MBEDTLS_EXTERNAL=ON
      -DLIEF_OPT_NLOHMANN_JSON_EXTERNAL=ON
      -DLIEF_OPT_UTFCPP_EXTERNAL=ON
      -DLIEF_SO_VERSION=ON
      -DLIEF_USE_CCACHE=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <LIEF/LIEF.hpp>

      int main(void) {
        std::unique_ptr<LIEF::ELF::Binary> elf = LIEF::ELF::Parser::parse("hello");
        LIEF::ELF::DynamicEntryRunPath runpath("/usr/local/lib");
        elf->add(runpath);
        elf->write("hello-rpath");
        return 0;
      }
    CPP

    cp test_fixtures("elf/hello"), testpath
    system ENV.cxx, "-std=c++17", "test.cpp", "-o", "test", "-L#{lib}", "-lLIEF"
    system "./test"
    assert_match %r{RUNPATH\s+/usr/local/lib$}, shell_output("objdump -p hello-rpath")
  end
end
