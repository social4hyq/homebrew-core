class LeetcodeCli < Formula
  desc "May the code be with you"
  homepage "https://github.com/clearloop/leetcode-cli"
  url "https://github.com/clearloop/leetcode-cli/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "3ee61769f40fd374461dfe9a7cccd113b38564e828bcccabf1875d9482b9ced9"
  license "MIT"
  head "https://github.com/clearloop/leetcode-cli.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9d8103af720cf5e158d9b4a252630061bc9a0b93311f34a5bed7dfe26eee3c17"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "openssl@3"

  uses_from_macos "sqlite"

  def install
    # Ensure that the `openssl` crate picks up the intended library.
    ENV["OPENSSL_DIR"] = Formula["openssl@3"].opt_prefix

    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"leetcode", "completions")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/leetcode --version")
    assert_match "[INFO  leetcode_cli::config] Generate root dir", shell_output("#{bin}/leetcode list 2>&1", 101)
  end
end
