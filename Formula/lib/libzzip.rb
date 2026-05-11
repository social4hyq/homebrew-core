class Libzzip < Formula
  desc "Library providing read access on ZIP-archives"
  homepage "https://github.com/gdraheim/zziplib"
  url "https://github.com/gdraheim/zziplib/archive/refs/tags/v0.13.80.tar.gz"
  sha256 "21f40d111c0f7a398cfee3b0a30b20c5d92124b08ea4290055fbfe7bdd53a22c"
  license any_of: ["LGPL-2.0-or-later", "MPL-1.1"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e0b14e7ec5879af21207aa405845515987adb2449c3117c474928d98f02eb17d"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build

  uses_from_macos "python" => :build
  uses_from_macos "zip" => :test

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    args = %W[
      -DZZIPTEST=OFF
      -DZZIPSDL=OFF
      -DCMAKE_INSTALL_RPATH=#{rpath}
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"README.txt").write("Hello World!")
    system "zip", "test.zip", "README.txt"
    assert_equal "Hello World!", shell_output("#{bin}/zzcat test/README.txt")
  end
end
