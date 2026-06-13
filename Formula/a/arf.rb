class Arf < Formula
  desc "Modern R console with syntax highlighting and fuzzy search"
  homepage "https://github.com/eitsupi/arf"
  url "https://github.com/eitsupi/arf/archive/refs/tags/v0.4.1.tar.gz"
  sha256 "5a0e911eac32dd2660e1ef0d40afdbccbccd7ce257bb6be893d6b3dc1f6cb4f1"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "54aa1156409626c49e0c16ede165e93e5a7c23cbe29b1d87923665308cb08f5d"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/arf-console")

    generate_completions_from_executable(bin/"arf", "completions")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/arf --version")

    system bin/"arf", "config", "init"
    if OS.mac?
      assert_path_exists testpath/"Library/Application Support/arf/arf.toml"
    else
      assert_path_exists testpath/".config/arf/arf.toml"
    end
    system bin/"arf", "config", "check"

    assert_match "history", shell_output("#{bin}/arf history schema")
    assert_match "sessions", shell_output("#{bin}/arf ipc list")
  end
end
