class Packcc < Formula
  desc "Parser generator for C"
  homepage "https://github.com/arithy/packcc"
  url "https://github.com/arithy/packcc/archive/refs/tags/v3.1.0.tar.gz"
  sha256 "26fa5c99ea36c4632fcb231479d01f354d016d2d8d97d74c44c08bc1924ae0a6"
  license "MIT"
  head "https://github.com/arithy/packcc.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b1041b5c7f84fab06833c934e5609d09f650e239dcec7650b4ea08742f60bf80"
  end

  depends_on "cmake" => :build

  def install
    inreplace "src/packcc.c", "/usr/share/packcc/import", "#{opt_pkgshare}/import"

    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    pkgshare.install "examples"
  end

  test do
    cp pkgshare/"examples/ast-calc.v3.peg", testpath
    system bin/"packcc", "ast-calc.v3.peg"
    system ENV.cc, "ast-calc.v3.c", "-o", "ast-calc"
    output = pipe_output(testpath/"ast-calc", "1+2*3\n")
    assert_equal <<~EOS, output
      binary: "+"
        nullary: "1"
        binary: "*"
          nullary: "2"
          nullary: "3"
    EOS
  end
end
