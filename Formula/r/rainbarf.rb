class Rainbarf < Formula
  desc "CPU/RAM/battery stats chart bar for tmux (and GNU screen)"
  homepage "https://github.com/creaktive/rainbarf"
  url "https://github.com/creaktive/rainbarf/archive/refs/tags/v1.5.tar.gz"
  sha256 "5fc96ffc16929e2158e82baf2a39f5573e6013a280ad66067e1eaee594be98df"
  license any_of: ["Artistic-1.0-Perl", "GPL-1.0-or-later"]
  head "https://github.com/creaktive/rainbarf.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "57fefe2896fff6d17b5f91dd297c952e1f2522d8343c68ee3e77379e3cc610e5"
  end

  depends_on "pod2man" => :build

  uses_from_macos "perl"

  def install
    system "#{Formula["pod2man"].opt_bin}/pod2man", "rainbarf", "rainbarf.1"
    man1.install "rainbarf.1"
    bin.install "rainbarf"
  end

  test do
    # Avoid "Use of uninitialized value $battery" and sandbox violation
    # Reported 5 Sep 2016 https://github.com/creaktive/rainbarf/issues/30
    assert_match version.to_s, shell_output("#{bin}/rainbarf --help", 1)
  end
end
