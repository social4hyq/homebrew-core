class Odbc2parquet < Formula
  desc "CLI to query an ODBC data source and write the result into a Parquet file"
  homepage "https://github.com/pacman82/odbc2parquet"
  url "https://github.com/pacman82/odbc2parquet/archive/refs/tags/v11.0.1.tar.gz"
  sha256 "1e0ba2b7c841a8e4c52a13a604aec44fa8f910ffb0b0375e21753e71dbcd21fc"
  license "MIT"
  head "https://github.com/pacman82/odbc2parquet.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a21f7bac3e6b59c4915a2a8222857b62cfcd6fc4d180f9a4a406953f7aef0787"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "unixodbc"

  def install
    system "cargo", "install", *std_cargo_args
    generate_completions_from_executable(bin/"odbc2parquet", "completions", shells: [:bash, :zsh, :fish, :pwsh])
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/odbc2parquet --version")

    system bin/"odbc2parquet", "list-data-sources"
    system bin/"odbc2parquet", "list-drivers"
  end
end
