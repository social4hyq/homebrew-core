class Rune < Formula
  desc "Embeddable dynamic programming language for Rust"
  homepage "https://rune-rs.github.io"
  url "https://github.com/rune-rs/rune/archive/refs/tags/0.14.2.tar.gz"
  sha256 "a858800d066f47e101c9b613d04dbc3f3d6d2bdb932da92f37c1ccdc79077337"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/rune-rs/rune.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dda0f998ba4f60a5f690c5168d00d4f95afcb5f1e32d34a1ccc6331706250b9e"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/rune-cli")
    system "cargo", "install", *std_cargo_args(path: "crates/rune-languageserver")
  end

  test do
    (testpath/"main.rn").write <<~EOS
      pub fn main() {
        println!("Hello, world!");
      }
    EOS

    assert_equal "Hello, world!", shell_output("#{bin/"rune"} run").strip
  end
end
