class SqlxCli < Formula
  desc "Command-line utility for SQLx, the Rust SQL toolkit"
  homepage "https://github.com/launchbadge/sqlx"
  url "https://github.com/launchbadge/sqlx/archive/refs/tags/v0.9.0.tar.gz"
  sha256 "48eaacc9a800af48c35713d300bc0de0c1e04b84c810b25de1007806fa1d718c"
  license any_of: ["Apache-2.0", "MIT"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ab1b116910846e5ef5b1110b43c3cfb060777314962d7cc5041f7ac530456fc8"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3"
  end

  def install
    system "cargo", "install", *std_cargo_args(path: "sqlx-cli")

    generate_completions_from_executable(bin/"sqlx", "completions")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/sqlx --version")

    ENV["DATABASE_URL"] = "postgres://postgres@localhost/my_database"
    output = shell_output("#{bin}/sqlx migrate info 2>&1", 1)
    assert_match "error: while resolving migrations: error canonicalizing path migrations", output
  end
end
