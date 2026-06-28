class Manifold < Formula
  desc "Geometry library for topological robustness"
  homepage "https://github.com/elalish/manifold"
  url "https://github.com/elalish/manifold/releases/download/v3.5.2/manifold-3.5.2.tar.gz"
  sha256 "ce5f4d87877daca99a910d0af73c028f2a36b9288dd2bf3cd1cecf8faff9f7c8"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c99438c72729a2f3a3e656a51573f0cd00f4544664b33f59fe093977b664ee82"
  end

  depends_on "cmake" => :build
  depends_on "clipper2"
  depends_on "tbb"

  def install
    args = %w[
      -DMANIFOLD_DOWNLOADS=OFF
      -DMANIFOLD_PAR=ON
      -DMANIFOLD_TEST=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    pkgshare.install "extras/large_scene_test.cpp"
  end

  test do
    system ENV.cxx, pkgshare/"large_scene_test.cpp",
                    "-std=c++17", "-I#{include}", "-L#{lib}", "-lmanifold",
                    "-o", "test"
    assert_match "nTri = 91814", shell_output("./test")
  end
end
