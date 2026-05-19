class Precomp < Formula
  desc "Command-line precompressor to achieve better compression"
  homepage "http://schnaader.info/precomp.php"
  url "https://github.com/schnaader/precomp-cpp/archive/refs/tags/v0.4.7.tar.gz"
  sha256 "b4064f9a18b9885e574c274f93d73d8a4e7f2bbd9e959beaa773f2e61292fb2b"
  license "Apache-2.0"
  head "https://github.com/schnaader/precomp-cpp.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e750e8b97a81e701bc25d436f50fdb31ad53873f39547d3009e9fdf7cbd4e936"
  end

  depends_on "cmake" => :build

  def install
    # https://github.com/schnaader/precomp-cpp/pull/146
    inreplace "contrib/liblzma/rangecoder/range_encoder.h", "#include \"price.h\"",
              "#include \"price.h\"\n#include <assert.h>"

    # Workaround for CMake 4 compatibility
    args = %w[-DCMAKE_POLICY_VERSION_MINIMUM=3.5]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    bin.install "build/precomp"
  end

  test do
    cp bin/"precomp", testpath/"precomp"
    system "gzip", "-1", testpath/"precomp"

    system bin/"precomp", testpath/"precomp.gz"
    rm testpath/"precomp.gz", force: true
    system bin/"precomp", "-r", testpath/"precomp.pcf"
    system "gzip", "-d", testpath/"precomp.gz"
  end
end
