class Historian < Formula
  desc "Command-line utility for managing shell history in a SQLite database"
  homepage "https://github.com/jcsalterego/historian"
  url "https://github.com/jcsalterego/historian/archive/refs/tags/0.0.2.tar.gz"
  sha256 "691b131290ddf06142a747755412115fec996cb9cc2ad8e8f728118788b3fe05"
  license "BSD-2-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "68111839ee7ae9c29d623bf6c76c36c68ba6a801f5edb42a9c89559e5eb68a6f"
  end

  uses_from_macos "sqlite"

  def install
    bin.install "hist"
  end

  test do
    ENV["HISTORIAN_SRC"] = "test_history"
    (testpath/"test_history").write <<~EOS
      brew update
      brew upgrade
    EOS
    system bin/"hist", "import"
  end
end
