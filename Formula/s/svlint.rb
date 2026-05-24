class Svlint < Formula
  desc "SystemVerilog linter"
  homepage "https://github.com/dalance/svlint"
  url "https://github.com/dalance/svlint/archive/refs/tags/v0.9.5.tar.gz"
  sha256 "1ffa212d571eabf57fb2b32c648760a0aff301dff8282a5a2b8e653d4657d3fe"
  license "MIT"
  head "https://github.com/dalance/svlint.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f925a8a1033cb149ad33f72962f54bbf17916bbee4b1de1a278fe27ebfa58204"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args

    # installation produces two binaries, `mdgen` and `svlint`, however, `mdgen` is for dev pipeline
    # see https://github.com/dalance/svlint/blob/729159751f330c4c3f7adaa25b826f809f0e5f44/README.md?plain=1#L26
    rm bin/"mdgen"

    generate_completions_from_executable(bin/"svlint", "--shell-completion")
  end

  test do
    (testpath/"test.sv").write <<~EOS
      module M;
      endmodule
    EOS

    assert_match(/hint\s+:\s+Begin `module` name with lowerCamelCase./, shell_output("#{bin}/svlint test.sv", 1))
  end
end
