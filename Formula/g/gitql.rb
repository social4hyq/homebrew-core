class Gitql < Formula
  desc "Git query language"
  homepage "https://github.com/filhodanuvem/gitql"
  url "https://github.com/filhodanuvem/gitql/archive/refs/tags/v2.3.1.tar.gz"
  sha256 "e3d34649f3dc714cb3189638103918314cf63b1ddbfd99a067d802730d1119b2"
  license "MIT"
  head "https://github.com/filhodanuvem/gitql.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "557c6861b70f1117ae595706fe89c608aca64bcec5f7be847f39a105e800d793"
  end

  depends_on "go" => :build

  conflicts_with "gql", because: "both install `gitql` binaries"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    system "git", "init"
    system "git", "config", "user.name", "A U Thor"
    system "git", "config", "user.email", "author@example.com"
    (testpath/"README").write "test"
    system "git", "add", "README"
    system "git", "commit", "-m", "Initial commit"
    assert_match "Initial commit", shell_output("#{bin}/gitql 'SELECT * FROM commits'")
  end
end
