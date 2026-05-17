class Clitest < Formula
  desc "Command-Line Tester"
  homepage "https://github.com/aureliojargas/clitest"
  url "https://github.com/aureliojargas/clitest/archive/refs/tags/0.5.0.tar.gz"
  sha256 "4005de0bc27e4676e418ab1e1e64861272aa74af1212c73a1173760fc449b049"
  license "MIT"
  head "https://github.com/aureliojargas/clitest.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "21d49315035a5a59f5bf15149c6b6b835fad4ea3cdc1116b6abda7b804a80fad"
  end

  def install
    bin.install "clitest"
  end

  test do
    (testpath/"test.txt").write <<~EOS
      $ echo "Hello World"   #=> Hello World
      $ cd /tmp
      $ pwd                  #=> /tmp
      $ cd "$OLDPWD"
      $
    EOS
    assert_match "OK: 4 of 4 tests passed",
      shell_output("#{bin}/clitest #{testpath}/test.txt")
  end
end
