class Nap < Formula
  desc "Code snippets in your terminal"
  homepage "https://github.com/maaslalani/nap"
  url "https://github.com/maaslalani/nap/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "2954577d2bd99c1114989d31e994d7bef0f1c934795fc559b7c90f6370d9f98b"
  license "MIT"
  head "https://github.com/maaslalani/nap.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "590a081006c77c56c4e6267758f856421bc1a277cde4005b805e7011197bf5f6"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args
  end

  test do
    assert_match "misc/Untitled Snippet.go", shell_output("#{bin}/nap list")
  end
end
