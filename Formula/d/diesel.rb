class Diesel < Formula
  desc "Command-line tool for Rust ORM Diesel"
  homepage "https://diesel.rs"
  url "https://github.com/diesel-rs/diesel/archive/refs/tags/v2.3.13.tar.gz"
  sha256 "3d1795761b4b48dc8b2c0e203c942ddfc97f767b5b59aca309f016e28cf0f6a4"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/diesel-rs/diesel.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a307a0c205b19132aea2b66607ca1c60442e69fc56323fea2d9905ae6ba510d9"
  end

  depends_on "rust" => [:build, :test]
  depends_on "libpq"
  depends_on "mariadb-connector-c"

  uses_from_macos "sqlite"

  def install
    system "cargo", "install", *std_cargo_args(path: "diesel_cli")
    generate_completions_from_executable(bin/"diesel", "completions")
  end

  test do
    ENV["DATABASE_URL"] = "db.sqlite"
    system "cargo", "init", "homebrew"
    cd "homebrew" do
      system bin/"diesel", "setup"
      assert_path_exists "db.sqlite", "SQLite database should be created"
    end
  end
end
