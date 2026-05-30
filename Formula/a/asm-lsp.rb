class AsmLsp < Formula
  desc "Language server for NASM/GAS/GO Assembly"
  homepage "https://github.com/bergercookie/asm-lsp"
  url "https://github.com/bergercookie/asm-lsp/archive/refs/tags/v0.10.1.tar.gz"
  sha256 "9500dd7234966ae9fa57d8759edf1d165acd06c4924d7dbeddb7d52eb0ce59d6"
  license "BSD-2-Clause"
  head "https://github.com/bergercookie/asm-lsp.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9bb5587185af74d54fcd6c24693fb6fe2cf042ae742197789aac04401df6b5e2"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3"
  end

  def install
    system "cargo", "install", *std_cargo_args(path: "asm-lsp")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/asm-lsp version")

    expected = if OS.mac?
      "Global config directories"
    else
      "Global config directory"
    end
    assert_match expected, shell_output("#{bin}/asm-lsp info")

    output = shell_output("#{bin}/asm-lsp gen-config 2>&1", 101)
    assert_match "not a terminal", output
  end
end
