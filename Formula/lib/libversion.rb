class Libversion < Formula
  desc "Advanced version string comparison library"
  homepage "https://github.com/repology/libversion"
  url "https://github.com/repology/libversion/archive/refs/tags/3.0.4.tar.gz"
  sha256 "48c2a4a98b6f220dedd535979f1e9ab83f9bf869e06c0f5e7bb1be6d2e662fee"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "167ff767b4dad3017d0419487f6ad2cdc35428565fd3c64faf1caf1206eeb2d0"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", "-DCMAKE_INSTALL_RPATH=#{rpath}", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    assert_equal "=", shell_output("#{bin}/version_compare 1.0 1.0.0").chomp
    assert_equal "<", shell_output("#{bin}/version_compare 1.1p1 1.1").chomp
    assert_equal ">", shell_output("#{bin}/version_compare -p 1.1p1 1.1").chomp
  end
end
