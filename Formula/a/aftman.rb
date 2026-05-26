class Aftman < Formula
  desc "Toolchain manager for Roblox, the prodigal sequel to Foreman"
  homepage "https://github.com/LPGhatguy/aftman"
  url "https://github.com/LPGhatguy/aftman/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "f75aab63cb887c63e3888a225061a1ab4e0fd0d9c3e0a1c86b8ac7ad035fdf6c"
  license "MIT"
  head "https://github.com/LPGhatguy/aftman.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9c13a7147a71b35cd70ac5b96d0df4174eac950dbccaf6983f3aadb1cf8777d9"
  end

  # https://github.com/LPGhatguy/aftman?tab=readme-ov-file#%EF%B8%8F-aftman-is-no-longer-maintained-%EF%B8%8F
  deprecate! date: "2025-07-19", because: :repo_archived, replacement_formula: "mise"
  disable! date: "2026-07-19", because: :repo_archived, replacement_formula: "mise"

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  uses_from_macos "bzip2"

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    (testpath/"aftman.toml").write <<~TOML
      [tools]
      rojo = "rojo-rbx/rojo@7.2.1"
    TOML

    system bin/"aftman", "install", "--no-trust-check"

    assert_path_exists testpath/".aftman"
  end
end
