class Dz6 < Formula
  desc "Fast Vim-inspired TUI hex editor"
  homepage "https://dz6.dev.br"
  url "https://github.com/mentebinaria/dz6/archive/refs/tags/v0.7.1.tar.gz"
  sha256 "be984784453a0964ff87d3987e488e1aa5a95bf7938ecec28fd5a3a670293f00"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fa21d1a0881d552c44d7835d9f23d92561f741695b07e809d0774042415a0e9f"
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
