class BitGit < Formula
  desc "Bit is a modern Git CLI"
  homepage "https://github.com/chriswalz/bit"
  url "https://github.com/chriswalz/bit/archive/refs/tags/v1.1.2.tar.gz"
  sha256 "563ae6b0fa279cb8ea8f66b4b455c7cb74a9e65a0edbe694505b2c8fc719b2ff"
  license "Apache-2.0"
  head "https://github.com/chriswalz/bit.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a413d00f0c1fb28528f8c311905225928da46bf9e390717eacab1289c71c895b"
  end

  depends_on "go" => :build

  conflicts_with "bit", because: "both install `bit` binaries"

  def install
    system "go", "build", *std_go_args(ldflags: "-X main.version=v#{version}")
    bin.install_symlink "bit-git" => "bit"
  end

  test do
    system "git", "init", testpath/"test-repository"

    cd testpath/"test-repository" do
      (testpath/"test-repository/test.txt").write <<~EOS
        Hello Homebrew!
      EOS
      system bin/"bit", "add", "test.txt"

      output = shell_output("#{bin}/bit status").chomp
      assert_equal "new file:   test.txt", output.lines.last.strip
    end
  end
end
