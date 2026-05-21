class Mdp < Formula
  desc "Command-line based markdown presentation tool"
  homepage "https://github.com/visit1985/mdp"
  url "https://github.com/visit1985/mdp/archive/refs/tags/1.0.18.tar.gz"
  sha256 "36861161513c508c0589014510cdafd940a6e661e517022a3bea48ecf8d5fac4"
  license "GPL-3.0-or-later"
  head "https://github.com/visit1985/mdp.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a2ba34c43e0f334ad771d1640749312aa56dac3bb6170ccacb5a822656752f59"
  end

  uses_from_macos "ncurses"

  def install
    system "make"
    system "make", "install", "PREFIX=#{prefix}"
    pkgshare.install "sample.md"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mdp -v")
  end
end
