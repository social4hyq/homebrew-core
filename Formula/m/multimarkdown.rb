class Multimarkdown < Formula
  desc "Turn marked-up plain text into well-formatted documents"
  homepage "https://fletcher.github.io/MultiMarkdown-6/"
  url "https://github.com/fletcher/MultiMarkdown-6/archive/refs/tags/6.7.0.tar.gz"
  sha256 "aa386f54631dbc4e0beeb6b9cf9eb769db95a3f505a69b663140a80008cf0595"
  license "MIT"
  head "https://github.com/fletcher/MultiMarkdown-6.git", branch: "develop"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6ae4710c23f3128eb754e4d7a7d426ceb2a5c6ca60f624b89947edf46b6964de"
  end

  depends_on "cmake" => :build

  conflicts_with "mtools", because: "both install `mmd` binaries"
  conflicts_with "markdown", because: "both install `markdown` binaries"
  conflicts_with "discount", because: "both install `markdown` binaries"

  # Workaround for CMake 4 compatibility
  patch do
    url "https://github.com/fletcher/MultiMarkdown-6/commit/655c0908155758e7c94858af2fb99dc992709075.patch?full_index=1"
    sha256 "1ca4b7ea07c19981685786f8f469aad9c9d0d6af8394bc9d3b92608de929495c"
  end

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    bin.install "build/multimarkdown"

    bin.install Dir["scripts/*"].reject { |f| f.end_with?(".bat") }
  end

  test do
    assert_equal "<p>foo <em>bar</em></p>\n", pipe_output(bin/"multimarkdown", "foo *bar*\n")
    assert_equal "<p>foo <em>bar</em></p>\n", pipe_output(bin/"mmd", "foo *bar*\n")
  end
end
