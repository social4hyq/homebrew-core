class Doxygen < Formula
  desc "Generate documentation for several programming languages"
  homepage "https://www.doxygen.nl/"
  url "https://doxygen.nl/files/doxygen-1.17.0.src.tar.gz"
  mirror "https://downloads.sourceforge.net/project/doxygen/rel-1.17.0/doxygen-1.17.0.src.tar.gz"
  sha256 "fa4c3dd78785abc11ccc992bc9c01e7a8c3120fe14b8a8dfd7cefa7014530814"
  license "GPL-2.0-only"
  compatibility_version 1
  head "https://github.com/doxygen/doxygen.git", branch: "master"

  livecheck do
    url "https://www.doxygen.nl/download.html"
    regex(/href=.*?doxygen[._-]v?(\d+(?:\.\d+)+)[._-]src\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0efb22b675e8a0941d612dcda0f921702e19128e805f741d64ca2a23a76a9275"
  end

  depends_on "bison" => :build
  depends_on "cmake" => :build

  uses_from_macos "flex" => :build, since: :big_sur
  uses_from_macos "python" => :build

  patch do
    file "Patches/doxygen/structured_binding.patch"
  end

  patch do
    file "Patches/doxygen/disable_lto.patch"
  end

  def install
    system "cmake", "-S", ".", "-B", "build",
                    "-DPython_EXECUTABLE=#{which("python3")}",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    system "cmake", "-S", ".", "-B", "build", "-Dbuild_doc=1", *std_cmake_args
    man1.install buildpath.glob("build/man/*.1")
  end

  test do
    system bin/"doxygen", "-g"
    system bin/"doxygen", "Doxyfile"
  end
end
