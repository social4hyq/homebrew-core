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
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e0bb08fdb4359ddfd5c82be815f23c4dc90ced08f08453081046f82c36fa3dfe"
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
