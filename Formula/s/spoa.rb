class Spoa < Formula
  desc "SIMD partial order alignment tool/library"
  homepage "https://github.com/rvaser/spoa"
  url "https://github.com/rvaser/spoa/archive/refs/tags/4.1.5.tar.gz"
  sha256 "b5d323740b01255c55725e88db2548c666a05bc83b825c19cfac10586e21e7b3"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3b9be803ad9e9020fe9480585d9cac836ec421e85cee4f1d8dcf2d9585c9780a"
  end

  depends_on "cmake" => :build

  uses_from_macos "zlib"

  def install
    args = %w[
      -DBUILD_SHARED_LIBS=ON
      -Dspoa_build_tests=OFF
    ]
    args << "-DCMAKE_INSTALL_RPATH=#{rpath}" if OS.mac?
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
    pkgshare.install "test/data"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/spoa --version")

    output = shell_output("#{bin}/spoa #{pkgshare}/data/sample.fastq.gz")
    assert_match ">Consensus", output
  end
end
