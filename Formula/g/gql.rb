class Gql < Formula
  desc "Git Query language is a SQL like language to perform queries on .git files"
  homepage "https://amrdeveloper.github.io/GQL/"
  url "https://github.com/AmrDeveloper/GQL/archive/refs/tags/0.43.0.tar.gz"
  sha256 "29744a565ff8a46d0713a077202d3b72a2b32f29ff253c98ec0aa226559fd7fd"
  license "MIT"
  head "https://github.com/AmrDeveloper/GQL.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1a1432f0e60581588eea4dc1de28b245575f27f9ebbf3b7b57dca81e96798a50"
  end

  depends_on "cmake" => :build
  depends_on "rust" => :build

  conflicts_with "gitql", because: "both install `gitql` binaries"

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    system "git", "init"
    output = JSON.parse(shell_output("#{bin}/gitql -o json -q 'SELECT 1 + 1 LIMIT 1'"))
    assert_equal "2", output.first["column_0"]
  end
end
