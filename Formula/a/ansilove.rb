class Ansilove < Formula
  desc "ANSI/ASCII art to PNG converter"
  homepage "https://www.ansilove.org"
  url "https://github.com/ansilove/ansilove/releases/download/4.2.1/ansilove-4.2.1.tar.gz"
  sha256 "60b1f1b6e4a5be287bb19310ea526c631a0bea5f4cb550f33c301a4b1ec30abf"
  license "BSD-2-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "10e4a3870a980b18ef814705e400ef465f863e41a276ab96de1175a8c6f2854e"
  end

  depends_on "cmake" => :build
  depends_on "libansilove"

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args, "-DCMAKE_INSTALL_RPATH=#{rpath}"
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    pkgshare.install "examples/burps/bs-ansilove.ans" => "test.ans"
  end

  test do
    output = shell_output("#{bin}/ansilove -o #{testpath}/output.png #{pkgshare}/test.ans")
    assert_match "Font: 80x25", output
    assert_match "Id: SAUCE v00", output
    assert_match "Tinfos: IBM VGA", output
    assert_path_exists testpath/"output.png"
  end
end
