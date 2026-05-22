class Metashell < Formula
  desc "Metaprogramming shell for C++ templates"
  homepage "http://metashell.org"
  url "https://github.com/metashell/metashell/archive/refs/tags/v5.0.0.tar.gz"
  sha256 "028e37be072ec4e85d18ead234a208d07225cf335c0bb1c98d4d4c3e30c71f0e"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f75c50a6efb4bfde539bbb96989ac203624016e88cc87a5006f78a7ac987eac3"
  end

  depends_on "cmake" => :build
  depends_on "zstd"

  uses_from_macos "python" => :build
  uses_from_macos "libedit"
  uses_from_macos "libxml2"

  on_linux do
    depends_on "readline"
    depends_on "zlib-ng-compat"
  end

  # include missing cstddef, upstream PR ref, https://github.com/metashell/metashell/pull/303
  patch do
    url "https://github.com/metashell/metashell/commit/0d81415616d33e39ff6d1add91e71f9789ea8657.patch?full_index=1"
    sha256 "31472db5ae8e67483319dcbe104d5c7a533031f9845af2ddf5147f3caabf3ac2"
  end

  # fix build with cmake 4, upstream PR ref, https://github.com/metashell/metashell/pull/306
  patch do
    url "https://github.com/metashell/metashell/commit/38b524ae291799a7ea9077745d3fc10ef2d40d54.patch?full_index=1"
    sha256 "e97590ca1d2b5510dcfcca86aa608e828040bb91519f6b161f7b4311676f4fd4"
  end

  def install
    # remove -msse4.1 if unsupported, issue ref: https://github.com/metashell/metashell/issues/305
    inreplace "3rd/boost/atomic/CMakeLists.txt", /\btarget_compile_options.*-msse4/, "#\\0" if Hardware::CPU.arm?

    # Build internal Clang
    system "cmake", "-S", "3rd/templight/llvm",
                    "-B", "build/templight",
                    "-DLIBCLANG_BUILD_STATIC=ON",
                    "-DLLVM_ENABLE_TERMINFO=OFF",
                    "-DLLVM_ENABLE_PROJECTS=clang",
                    *std_cmake_args
    system "cmake", "--build", "build/templight", "--target", "templight"

    system "cmake", "-S", ".", "-B", "build/metashell", *std_cmake_args
    system "cmake", "--build", "build/metashell"
    system "cmake", "--install", "build/metashell"
  end

  test do
    (testpath/"test.hpp").write <<~CPP
      template <class T> struct add_const { using type = const T; };
      add_const<int>::type
    CPP
    output = pipe_output("#{bin}/metashell -H", (testpath/"test.hpp").read)
    assert_match "const int", output
  end
end
