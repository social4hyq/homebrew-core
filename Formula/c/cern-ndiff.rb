class CernNdiff < Formula
  desc "Numerical diff tool"
  # NOTE: ndiff is a sub-project of Mad-X at the moment.
  homepage "https://mad.web.cern.ch/mad/"
  url "https://github.com/MethodicalAcceleratorDesign/MAD-X/archive/refs/tags/5.09.03.tar.gz"
  sha256 "cd57f9451e3541a820814ad9ef72b6e01d09c6f3be56802fa2e95b1742db7797"
  license "GPL-3.0-only"
  head "https://github.com/MethodicalAcceleratorDesign/MAD-X.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dfe6090f8527696ea3f2aa61f06327c1075626b205b654503ceff87da18b07a7"
  end

  depends_on "cmake" => :build

  conflicts_with "ndiff", "nmap", because: "both install `ndiff` binaries"

  def install
    # Workaround for CMake 4 compatibility
    args = %w[-DCMAKE_POLICY_VERSION_MINIMUM=3.5]
    system "cmake", "-S", "tools/numdiff", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    # Avoid installing MAD-X license as numdiff is under a different license
    rm "License.txt"
    prefix.install "tools/numdiff/LICENSE"
  end

  test do
    (testpath/"lhs.txt").write("0.0 2e-3 0.003")
    (testpath/"rhs.txt").write("1e-7 0.002 0.003")
    (testpath/"test.cfg").write("*   * abs=1e-6")

    system bin/"ndiff", "lhs.txt", "rhs.txt", "test.cfg"
  end
end
