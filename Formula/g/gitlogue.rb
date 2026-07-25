class Gitlogue < Formula
  desc "Cinematic Git commit replay tool"
  homepage "https://github.com/unhappychoice/gitlogue"
  url "https://github.com/unhappychoice/gitlogue/archive/refs/tags/v0.10.0.tar.gz"
  sha256 "65c5043b81aed86aa6429c846d944c375b8d763e77071bb5444b72f5531e3845"
  license "ISC"
  head "https://github.com/unhappychoice/gitlogue.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "eff4964a1a0b19f6f61661167136924453b3ef5f29bba99cf3d0756b61bba743"
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
