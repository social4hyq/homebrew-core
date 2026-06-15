class Hayagriva < Formula
  desc "Bibliography management tool"
  homepage "https://github.com/typst/hayagriva"
  url "https://github.com/typst/hayagriva/archive/refs/tags/v0.10.1.tar.gz"
  sha256 "bce8393f5200a3672b0d5baade84cfd96646dc7f0e045faedb0bf9a754c1a48d"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/typst/hayagriva.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "40c165df0b8610338cb8b4e24418fd8d4ab5a6abb03888aa2a93233298b4144c"
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
