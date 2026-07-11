class Diesel < Formula
  desc "Command-line tool for Rust ORM Diesel"
  homepage "https://diesel.rs"
  url "https://github.com/diesel-rs/diesel/archive/refs/tags/v2.3.11.tar.gz"
  sha256 "409298c05178ae0520dcbb3878292599e0c7dbb7a088f6f77b649a8fa5dc91c6"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/diesel-rs/diesel.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "595e71bd686355f0de477a552cd8f7ae452b98e313c7c838f925fcd9dac14850"
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
