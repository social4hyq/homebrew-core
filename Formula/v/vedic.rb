class Vedic < Formula
  desc "Simple Sanskrit programming language"
  homepage "https://vedic-lang.github.io/"
  url "https://github.com/vedic-lang/vedic/archive/refs/tags/v2.0.6.tar.gz"
  sha256 "9bfb68dfa8a79c02d52905eb1403267209dae80ad05287b7f3706f14071c4800"
  license "MIT"
  head "https://github.com/vedic-lang/vedic.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "05d16c1850e86267ce61e057d91ebe2ee292e46be864a41af9888d88b0012d77"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "cli")
  end

  test do
    # hello world in vedic
    (testpath/"hello.ved").write <<~EOS
      वद("नमस्ते विश्व!");
    EOS
    assert_match "नमस्ते विश्व!", shell_output("#{bin}/vedic hello.ved")

    assert_match version.to_s, shell_output("#{bin}/vedic --version")
  end
end
