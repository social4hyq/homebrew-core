class Atomicparsley < Formula
  desc "MPEG-4 command-line tool"
  homepage "https://github.com/wez/atomicparsley"
  url "https://github.com/wez/atomicparsley/archive/refs/tags/20240608.083822.1ed9031.tar.gz"
  version "20240608.083822.1ed9031"
  sha256 "5bc9ac931a637ced65543094fa02f50dde74daae6c8800a63805719d65e5145e"
  license "GPL-2.0-or-later"
  version_scheme 1
  head "https://github.com/wez/atomicparsley.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3f1b295918cbd2cc6a1aa350e9c3aedbcf17c11c342d4c345ecd25667add53a7"
  end

  depends_on "cmake" => :build

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    bin.install "build/AtomicParsley"
  end

  test do
    cp test_fixtures("test.m4a"), testpath/"file.m4a"

    system bin/"AtomicParsley", testpath/"file.m4a", "--artist", "Homebrew", "--overWrite"
    output = shell_output("#{bin}/AtomicParsley file.m4a --textdata")
    assert_match "Homebrew", output
  end
end
