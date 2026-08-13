class BoostBuild < Formula
  desc "C++ build system"
  homepage "https://www.boost.org/build/"
  url "https://github.com/boostorg/build/archive/refs/tags/boost-1.92.0.tar.gz"
  sha256 "bf2d9efb60cded0eca0c0be37e5c8a9fda7a3977a5c675b353aefced66ff3444"
  license "BSL-1.0"
  version_scheme 1
  head "https://github.com/boostorg/build.git", branch: "develop"

  livecheck do
    url :stable
    regex(/^boost[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4359340fae126ff0d4eacf2455ed2b6f7835ce8764e49b0f9793bbf5db2a6071"
  end

  conflicts_with "b2-tools", because: "both install `b2` binaries"

  def install
    system "./bootstrap.sh"
    system "./b2", "--prefix=#{prefix}", "install"
  end

  test do
    (testpath/"hello.cpp").write <<~CPP
      #include <iostream>
      int main (void) { std::cout << "Hello world"; }
    CPP
    (testpath/"Jamroot.jam").write <<~JAM
      exe hello : hello.cpp ;
      install install-bin : hello : <location>"#{testpath}" ;
    JAM

    system bin/"b2", "release"
    assert_path_exists testpath/"hello"
    assert_equal "Hello world", shell_output("./hello")
  end
end
