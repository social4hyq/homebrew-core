class SchemaEvolutionManager < Formula
  desc "Manage postgresql database schema migrations"
  homepage "https://github.com/mbryzek/schema-evolution-manager"
  url "https://github.com/mbryzek/schema-evolution-manager/archive/refs/tags/0.9.58.tar.gz"
  sha256 "879d2957413c0fa8c989c141e12a5d45bde0f34d2e4290fb197e05bac7baf774"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "78d99aabeb0fd3e456565ed08c76cb9c7bcb928d39abb3b6b4e375355b736455"
  end

  uses_from_macos "ruby"

  def install
    system "./install.sh", prefix
  end

  test do
    (testpath/"new.sql").write <<~SQL
      CREATE TABLE IF NOT EXISTS test (id text);
    SQL
    system "git", "init", "."
    assert_match "File staged in git", shell_output("#{bin}/sem-add ./new.sql")
  end
end
