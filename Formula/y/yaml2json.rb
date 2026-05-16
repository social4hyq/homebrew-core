class Yaml2json < Formula
  desc "Command-line tool convert from YAML to JSON"
  homepage "https://github.com/bronze1man/yaml2json"
  url "https://github.com/bronze1man/yaml2json/archive/refs/tags/v1.3.5.tar.gz"
  sha256 "efde12ca8b3ab7df3d3eaef35ecfb6e0d54baed33c8d553e7fd611a79c4cee04"
  license "MIT"
  head "https://github.com/bronze1man/yaml2json.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c43d84596df652d56b69831710b5c632c6efb709eb39ee7f586cbe58579323b7"
  end

  depends_on "go" => :build

  conflicts_with "remarshal", because: "both install `yaml2json` binaries"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/yaml2json --version 2>&1", 1)

    (testpath/"test.yaml").write <<~YAML
      firstname: John
      lastname: Doe
      age: 25

      items:
        - item: Desk
          color: black

        - item: Chair
          color: brown
    YAML

    (testpath/"expected.json").write <<~JSON
      {
        "age": 25,
        "firstname": "John",
        "lastname": "Doe",
        "items": [
          {
            "item": "Desk",
            "color": "black"
          },
          {
            "item": "Chair",
            "color": "brown"
          }
        ]
      }
    JSON

    assert_equal JSON.parse((testpath/"expected.json").read),
      JSON.parse(shell_output("#{bin}/yaml2json < #{testpath}/test.yaml"))
  end
end
