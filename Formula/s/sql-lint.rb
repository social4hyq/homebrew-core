class SqlLint < Formula
  desc "SQL linter to do sanity checks on your queries and bring errors back from the DB"
  homepage "https://github.com/joereynolds/sql-lint"
  url "https://registry.npmjs.org/sql-lint/-/sql-lint-1.0.2.tgz"
  sha256 "17575266273fe3f762595fe404f49ff5fbd4c360f605cda0718cb62d65ad82b8"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2e6a293e30071c139345acfe2a1751426e465e417fdd59b572e7ee1fa354f468"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    (testpath/"pg-enum.sql").write <<~SQL
      CREATE TYPE status AS ENUM ('to-do', 'in-progress', 'done');
    SQL
    assert_empty shell_output("#{bin}/sql-lint -d postgres pg-enum.sql")

    (testpath/"invalid-delete.sql").write <<~SQL
      DELETE FROM table-epbdlrsrkx;
    SQL
    assert_match "missing-where", shell_output("#{bin}/sql-lint invalid-delete.sql", 1)
  end
end
