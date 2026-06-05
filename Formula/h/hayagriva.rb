class Hayagriva < Formula
  desc "Bibliography management tool"
  homepage "https://github.com/typst/hayagriva"
  url "https://github.com/typst/hayagriva/archive/refs/tags/v0.10.0.tar.gz"
  sha256 "41c82a16510cdceb922250e2f133227759c6ee1ff05bef5328598b97f7168edf"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/typst/hayagriva.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a9f9920c5aca265c34ccb25fa6cf4a88fd0df5b753adb0592d61deeabaa71e3a"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(features: "cli")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/hayagriva --version")

    (testpath/"test.yaml").write <<~YAML
      dependence:
          type: Article
          title: The program dependence graph and its use in optimization
          author: ["Ferrante, Jeanne", "Ottenstein, Karl J.", "Warren, Joe D."]
          date: 1987-07
          serial-number:
              doi: "10.1145/24039.24041"
          parent:
              type: Periodical
              title: ACM Transactions on Programming Languages and Systems
              volume: 9
              issue: 3
    YAML

    output = "Ferrante, J., Ottenstein, K. J., & Warren, J. D. (1987)."
    assert_match output, shell_output("#{bin}/hayagriva test.yaml reference --no-fmt --style apa")
  end
end
