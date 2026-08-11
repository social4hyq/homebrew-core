class LeetcodeCli < Formula
  desc "May the code be with you"
  homepage "https://github.com/clearloop/leetcode-cli"
  url "https://github.com/clearloop/leetcode-cli/archive/refs/tags/v0.5.5.tar.gz"
  sha256 "52bc5bac21dc52a0d498c8b817f9e04c7267ba9febb08d4ed0a158e91893d6cf"
  license "MIT"
  head "https://github.com/clearloop/leetcode-cli.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e98853967a7356b2ebec127f1a5faa3bc4597d08bb1c457ed5c9d825429f2028"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "openssl@3"

  uses_from_macos "sqlite"

  def install
    # Ensure that the `openssl` crate picks up the intended library.
    ENV["OPENSSL_DIR"] = formula_opt_prefix("openssl@3")

    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"leetcode", "completions")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/leetcode --version")
    assert_match "[INFO  leetcode_cli::config] Generate root dir", shell_output("#{bin}/leetcode list 2>&1")
  end
end
