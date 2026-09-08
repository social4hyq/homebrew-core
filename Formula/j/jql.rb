class Jql < Formula
  desc "JSON query language CLI tool"
  homepage "https://github.com/yamafaktory/jql"
  url "https://github.com/yamafaktory/jql/archive/refs/tags/jql-v8.3.0.tar.gz"
  sha256 "f336ff28fde0bf587fb6fdbdc5e2a5531bcc5b6618c80e5de12008452b9fab8b"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/yamafaktory/jql.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0dc69ac8cf943357d1cf4200a42c54e4428cb5c8fed1524fc20925755922688d"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/jql")
  end

  test do
    (testpath/"example.json").write <<~JSON
      {
        "cats": [{ "first": "Pixie" }, { "second": "Kitkat" }, { "third": "Misty" }]
      }
    JSON
    output = shell_output("#{bin}/jql --inline --raw-string '\"cats\" [2:1] [0]' example.json")
    assert_equal '{"third":"Misty"}', output.chomp
  end
end
