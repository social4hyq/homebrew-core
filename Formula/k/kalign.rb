class Kalign < Formula
  desc "Fast multiple sequence alignment program for biological sequences"
  homepage "https://github.com/TimoLassmann/kalign"
  url "https://github.com/TimoLassmann/kalign/archive/refs/tags/v3.5.1.tar.gz"
  sha256 "983bfd7da76010d59c3de3bae3d977cac78642c5eb061009dd12b11b9db5190d"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "114f4402b9769d319d12951949ebe8f6e3c298fb3d8bc933fc2afd23aa51196c"
  end

  depends_on "cmake" => :build
  depends_on "libomp"

  def install
    args = %w[
      -DENABLE_AVX=OFF
      -DENABLE_AVX2=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    input = ">1\nA\n>2\nA"
    (testpath/"test.fa").write(input)
    output = shell_output("#{bin}/kalign test.fa")
    assert_match input, output
  end
end
