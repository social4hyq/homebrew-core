class Dfc < Formula
  desc "Display graphs and colors of file system space/usage"
  homepage "https://github.com/Rolinh/dfc"
  url "https://github.com/Rolinh/dfc/releases/download/v3.1.1/dfc-3.1.1.tar.gz"
  sha256 "962466e77407dd5be715a41ffc50a54fce758a78831546f03a6bb282e8692e54"
  license "BSD-3-Clause"
  revision 1
  head "https://github.com/Rolinh/dfc.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "46f4e99d4ae2af91dc2db51ff2c8a2b9b8d8ca4d3acfcbe556c212d1fee311b1"
  end

  depends_on "cmake" => :build
  depends_on "gettext" => :build

  on_macos do
    depends_on "gettext"
  end

  def install
    # Workaround for CMake 4 compatibility
    args = %w[-DCMAKE_POLICY_VERSION_MINIMUM=3.5]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    system bin/"dfc", "-T"
    assert_match ",%USED,", shell_output("#{bin}/dfc -e csv")
  end
end
