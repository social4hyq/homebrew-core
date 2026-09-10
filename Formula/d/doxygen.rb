class Doxygen < Formula
  desc "Generate documentation for several programming languages"
  homepage "https://www.doxygen.nl/"
  url "https://doxygen.nl/files/doxygen-1.18.0.src.tar.gz"
  mirror "https://downloads.sourceforge.net/project/doxygen/rel-1.18.0/doxygen-1.18.0.src.tar.gz"
  sha256 "a1deed70a6785bbec95a2b2a9e419dc7f7b223a9d74a8644ae611c8e2dcdd354"
  license "GPL-2.0-only"
  revision 1
  compatibility_version 1
  head "https://github.com/doxygen/doxygen.git", branch: "master"

  livecheck do
    url "https://www.doxygen.nl/download.html"
    regex(/href=.*?doxygen[._-]v?(\d+(?:\.\d+)+)[._-]src\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ce04199b68a2edef2c63a091523f30fb15f23e4820d3978c9847995a6a705204"
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
