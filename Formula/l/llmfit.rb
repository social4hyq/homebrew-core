class Llmfit < Formula
  desc "Find what models run on your hardware"
  homepage "https://github.com/AlexsJones/llmfit"
  url "https://static.crates.io/crates/llmfit/llmfit-0.9.34.crate"
  sha256 "d5bf498338016b12b9e52cdb6c82e93a5daa1c27a786e78a608505214ad154e2"
  license "MIT"
  head "https://github.com/AlexsJones/llmfit.git", branch: "main"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bbcbf645ddf48778cd029024ff4a2d24b2962d413fd8d2dbdcf9b93aa340f08e"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/llmfit --version")
    assert_match "Multiple models match", shell_output("#{bin}/llmfit info llama")
  end
end
