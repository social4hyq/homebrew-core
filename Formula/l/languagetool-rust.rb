class LanguagetoolRust < Formula
  desc "LanguageTool API in Rust"
  homepage "https://docs.rs/languagetool-rust"
  url "https://github.com/jeertmans/languagetool-rust/archive/refs/tags/v3.0.1.tar.gz"
  sha256 "fc3dfcb73f21c58bb143b5f31495892755bc1e945aa64f522f3640e1cf77de31"
  license "MIT"
  head "https://github.com/jeertmans/languagetool-rust.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cabd1ee86f29c064ee1dcaa5de745f617f72597f6b9d981da8e81c51ee489cab"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3"
  end

  def install
    system "cargo", "install", *std_cargo_args(features: "full")

    generate_completions_from_executable(bin/"ltrs", "completions")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/ltrs --version")

    system bin/"ltrs", "ping"
    assert_match "\"name\": \"Arabic\"", shell_output("#{bin}/ltrs languages")

    output = shell_output("#{bin}/ltrs check --text \"Some phrase with a smal mistake\"")
    assert_match "error[MORFOLOGIK_RULE_EN_US]: Possible spelling mistake found", output
  end
end
