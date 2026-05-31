class Blisp < Formula
  desc "ISP tool & library for Bouffalo Labs RISC-V Microcontrollers and SoCs"
  homepage "https://github.com/pine64/blisp"
  url "https://github.com/pine64/blisp/archive/refs/tags/v0.0.5.tar.gz"
  sha256 "79f87fbbb66f1d9ddf250cdc15dc16638d95e0905665003b08920a4b1fda9f96"
  license "MIT"
  revision 1
  head "https://github.com/pine64/blisp.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5530ca6109ccbe4dc737664189437c2b0e57adeede7249021fc4767c0ce0dad8"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "argtable3"
  depends_on "libserialport"

  def install
    args = %w[
      -DBLISP_USE_SYSTEM_LIBRARIES=ON
      -DBLISP_BUILD_CLI=ON
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    # workaround for fixing the header installations,
    # should be fixed with a new release, https://github.com/pine64/blisp/issues/67
    include.install Dir[lib/"blisp*.h"]
  end

  test do
    output = shell_output("#{bin}/blisp write -c bl70x --reset Pinecilv2_EN.bin 2>&1", 11)
    assert_match "Input firmware not found: Pinecilv2_EN.bin", output

    assert_match version.to_s, shell_output("#{bin}/blisp --version")
  end
end
