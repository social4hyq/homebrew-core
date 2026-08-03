class Arf < Formula
  desc "Modern R console with syntax highlighting and fuzzy search"
  homepage "https://github.com/eitsupi/arf"
  url "https://github.com/eitsupi/arf/archive/refs/tags/v0.4.5.tar.gz"
  sha256 "42f06bb7eae572bac427438e9c8bdd181f1666073e14014c61062ec6c92e3802"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1a2a59a66d95f3113d896b158bcdf073b415d6f9a46d0cba6c119c010454850c"
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
