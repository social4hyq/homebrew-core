class Kalign < Formula
  desc "Fast multiple sequence alignment program for biological sequences"
  homepage "https://github.com/TimoLassmann/kalign"
  url "https://github.com/TimoLassmann/kalign/archive/refs/tags/v3.6.0.tar.gz"
  sha256 "4af0af2764509c3e83d501c6d8260b8c69bd8fd02456ed41c18583a23f4781d7"
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
