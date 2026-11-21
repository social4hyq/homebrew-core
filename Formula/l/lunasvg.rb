class Lunasvg < Formula
  desc "SVG rendering and manipulation library in C++"
  homepage "https://github.com/sammycage/lunasvg"
  url "https://github.com/sammycage/lunasvg/archive/refs/tags/v3.5.0.tar.gz"
  sha256 "1abf1472ee6c4d19797916e8cc3c2e4b628e0d81178ffac60bdb0d457e32c690"
  license "MIT"
  revision 1

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/lunasvg-v3.5.0-r2"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f872581e62e435ba26239ba8336bea21c35d65176e5251f4ca5b4c7c3e047090"
  end

  depends_on "cmake" => :build
  depends_on "plutovg"

  deny_network_access!

  def install
    args = %w[
      -DBUILD_SHARED_LIBS=ON
      -DUSE_SYSTEM_PLUTOVG=ON
      -DLUNASVG_BUILD_EXAMPLES=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
    (pkgshare/"examples").install "examples/svg2png.cpp"
  end

  test do
    args = %W[
      -std=c++11
      -I#{include}/lunasvg
      -I#{formula_opt_include("plutovg")}/plutovg
      -L#{lib}
      -L#{formula_opt_lib("plutovg")}
      -llunasvg
      -lplutovg
    ]

    system ENV.cxx, pkgshare/"examples/svg2png.cpp", "-o", "svg2png", *args
    system testpath/"svg2png", test_fixtures("test.svg")
    assert File.size("test.svg.png").positive?
  end
end
