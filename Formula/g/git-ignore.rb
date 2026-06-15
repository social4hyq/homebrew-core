class GitIgnore < Formula
  desc "List, fetch and generate .gitignore templates"
  homepage "https://github.com/sondr3/git-ignore"
  url "https://github.com/sondr3/git-ignore/archive/refs/tags/v1.4.0.tar.gz"
  sha256 "58b2ae7c5fdc057d6935ee411c4a8225151b7ea2368c863d9b21bf4ccafb11a5"
  license "GPL-3.0-or-later"
  head "https://github.com/sondr3/git-ignore.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b1ab38c53f6ec1345c9adb2699321075a6a8dec2933d73585d1c221558cd51b2"
  end

  depends_on "rust" => :build

  conflicts_with "git-extras", because: "both install a `git-ignore` binary"

  def install
    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"git-ignore", "completion")
    man1.install "target/assets/git-ignore.1"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/git-ignore --version")

    assert_match "Usage:", shell_output("#{bin}/git-ignore --help")

    system bin/"git-ignore", "init"
    assert_path_exists testpath/".config/git-ignore/config.toml"
  end
end
