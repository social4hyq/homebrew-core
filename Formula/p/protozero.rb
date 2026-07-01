class Protozero < Formula
  desc "Minimalist protocol buffer decoder and encoder in C++"
  homepage "https://github.com/mapbox/protozero"
  url "https://github.com/mapbox/protozero/archive/refs/tags/v1.8.2.tar.gz"
  sha256 "68d1df951b4d8397355c8fc9ffed40d9c06282a877fe847403feac6edcee3ef1"
  license "BSD-2-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f124155555613ae919eae576dcf9a8ce00349a3946732227ee19ce0144d1478c"
  end

  depends_on "cmake" => :build

  def install
    # We only install headers, so we can skip `cmake --build`.
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--install", "build"
    pkgshare.install "tools"
  end

  test do
    system ENV.cxx, "-std=c++14", "-I#{include}", pkgshare/"tools/pbf-decoder.cpp", "-o", "pbf-decoder"
    assert_empty pipe_output("./pbf-decoder -", "")
  end
end
