class Trdsql < Formula
  desc "CLI tool that can execute SQL queries on CSV, LTSV, JSON, YAML and TBLN"
  homepage "https://github.com/noborus/trdsql"
  url "https://github.com/noborus/trdsql/archive/refs/tags/v1.2.1.tar.gz"
  sha256 "58a4b5987e80ed313bf878b070b4d94768fae658f2cf56f353284d762937a84a"
  license "MIT"
  head "https://github.com/noborus/trdsql.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5b7917b0ce7d69071cc52ff5538a46999c3c60285bbf3cad3d4b0194f05d3413"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/noborus/trdsql.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/trdsql"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/trdsql --version")

    (testpath/"test.csv").write <<~CSV
      name,age
      Alice,30
      Bob,25
    CSV

    output = shell_output("#{bin}/trdsql -ih 'SELECT name FROM test.csv where age > 25'")
    assert_equal "Alice", output.chomp
  end
end
