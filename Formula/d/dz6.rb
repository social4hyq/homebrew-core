class Dz6 < Formula
  desc "Fast Vim-inspired TUI hex editor"
  homepage "https://dz6.dev.br"
  url "https://github.com/mentebinaria/dz6/archive/refs/tags/v0.7.0.tar.gz"
  sha256 "2ee4f2cdd065d751387cdc023fac988406320c52a6d0efaf1b017b93d6d9b76e"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8a1f4505e9b43560a70ee7f51e5aa0a93fddfdc88a74dfcc430bf0101c90ead4"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dz6 --version")
    output = shell_output("#{bin}/dz6 #{testpath/"missing.bin"} 2>&1", 1)
    assert_match "No such file or directory", output
  end
end
