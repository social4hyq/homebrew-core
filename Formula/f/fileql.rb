class Fileql < Formula
  desc "Run SQL-like query on local files instead of database files using the GitQL SDK"
  homepage "https://github.com/AmrDeveloper/FileQL"
  url "https://github.com/AmrDeveloper/FileQL/archive/refs/tags/0.10.0.tar.gz"
  sha256 "c85976ffd14454be0f3f973d6d97621f10d8dc0d4814448bd66d2a376f6dfdc2"
  license "MIT"
  head "https://github.com/AmrDeveloper/FileQL.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6aa26f897c977b31f5b41dd46cf3495c55e7e49fe49d44b2381fbb15f129bcf8"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    output = JSON.parse(shell_output("#{bin}/fileql -o json -q 'SELECT (1 * 2) AS result'"))
    assert_equal "2", output.first["result"]
  end
end
