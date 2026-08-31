class Gitlogue < Formula
  desc "Cinematic Git commit replay tool"
  homepage "https://github.com/unhappychoice/gitlogue"
  url "https://github.com/unhappychoice/gitlogue/archive/refs/tags/v0.11.0.tar.gz"
  sha256 "cf0814005bd39c02b7c48d385a258e2e4e1fd57980bb57db72ecb490494de06c"
  license "ISC"
  head "https://github.com/unhappychoice/gitlogue.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1221caf09c9c3084962345968d665ccd46d2c67a8d9e70aa9b5c69a1157d1fae"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "openssl@3"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/gitlogue --version")

    assert_match "Error: Not a Git repository", shell_output("#{bin}/gitlogue 2>&1", 1)
  end
end
