class Gobuster < Formula
  desc "Directory/file & DNS busting tool written in Go"
  homepage "https://github.com/OJ/gobuster"
  url "https://github.com/OJ/gobuster/archive/refs/tags/v3.8.2.tar.gz"
  sha256 "6919232eafbd0c4bbc9664d7f434b6a8d82133aa09f1400341ef6985ceff208a"
  license "Apache-2.0"
  head "https://github.com/OJ/gobuster.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "de59e931794e888d2d8febe65e6dcbd50ad0908e7ce7f0e1b6515faaf2177b2f"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    (testpath/"words.txt").write <<~EOS
      dog
      cat
      horse
      snake
      ape
    EOS

    output = shell_output("#{bin}/gobuster dir -u https://buffered.io -w words.txt 2>&1")
    assert_match "Finished", output

    assert_match version.major_minor.to_s, shell_output("#{bin}/gobuster --version")
  end
end
