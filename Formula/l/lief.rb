class Lief < Formula
  desc "Library to Instrument Executable Formats"
  homepage "https://lief.re/"
  url "https://github.com/lief-project/LIEF/archive/refs/tags/1.0.0.tar.gz"
  sha256 "2cf412695ff739d82e129db441e5c2025f3bb4873a3d3a1d3dd4cf300b682abd"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "781b27ad66a684a017076855db0495014ab0f9fc75998e8ee412879c49728973"
  end

  depends_on "cmake" => :build
  depends_on "frozen" => :build
  depends_on "nlohmann-json" => :build
  depends_on "utf8cpp" => :build
  depends_on "fmt"
  depends_on "spdlog"
  depends_on "tl-expected" => :no_linkage

  resource "mbedtls" do
    url "https://raw.githubusercontent.com/lief-project/LIEF/1.0.0/third-party/mbedtls-4.0.0.r0.gec4044008d.zip"
    sha256 "01aec4471547dec5308853ff0d797611a68a521a10496898b626035dfdc07183"
  end

  resource "tcb-span" do
    url "https://raw.githubusercontent.com/lief-project/LIEF/1.0.0/third-party/tcb-span-b70b0ff.zip"
    sha256 "f3d47ed83507fce94245a9f3cf97bc433cd1116f94d11ac0dca1a6f53bbeb239"
  end

  def install
    rm_r Dir["third-party/*"]
    resource("mbedtls").stage do
      (buildpath/"third-party/mbedtls").install Dir["*"]
    end
    resource("tcb-span").stage do
      (buildpath/"third-party/tcb").install "span.hpp"
    end

    args = %W[
      -DBUILD_SHARED_LIBS=ON
      -DFETCHCONTENT_SOURCE_DIR_LIEF_MBEDTLS=#{buildpath}/third-party/mbedtls
      -DFETCHCONTENT_SOURCE_DIR_LIEF_SPAN=#{buildpath}/third-party/tcb
      -DLIEF_EXAMPLES=OFF
      -DLIEF_EXTERNAL_SPDLOG=ON
      -DLIEF_OPT_EXTERNAL_EXPECTED=ON
      -DLIEF_OPT_FROZEN_EXTERNAL=ON
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
