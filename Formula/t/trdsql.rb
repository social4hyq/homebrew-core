class Trdsql < Formula
  desc "CLI tool that can execute SQL queries on CSV, LTSV, JSON, YAML and TBLN"
  homepage "https://github.com/noborus/trdsql"
  url "https://github.com/noborus/trdsql/archive/refs/tags/v1.2.3.tar.gz"
  sha256 "23a80d1c7cf44f458440ad9b6ffc5dc9305e98f191fbce102f47bf6be2c4fb17"
  license "MIT"
  head "https://github.com/noborus/trdsql.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "33b9b1360d43d8fe382daa0ff20c3f832026744e3ac20c0ba679aa172d0366ee"
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
