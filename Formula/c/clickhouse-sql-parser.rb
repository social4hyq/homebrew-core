class ClickhouseSqlParser < Formula
  desc "Writing clickhouse sql parser in pure Go"
  homepage "https://github.com/AfterShip/clickhouse-sql-parser"
  url "https://github.com/AfterShip/clickhouse-sql-parser/archive/refs/tags/v0.5.6.tar.gz"
  sha256 "eb839fe9dc22158e87e19bb24ee1d8719664742ebec087700cbab5785757eb4a"
  license "MIT"
  head "https://github.com/AfterShip/clickhouse-sql-parser.git", branch: "master"

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    output = shell_output("#{bin}/clickhouse-sql-parser -format \"SELECT 1\"")
    assert_match "SELECT 1", output
  end
end
