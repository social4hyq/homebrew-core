class Csshx < Formula
  desc "Cluster ssh tool for Terminal.app"
  homepage "https://github.com/brockgr/csshx"
  url "https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/csshx/csshX-0.74.tgz"
  mirror "https://distfiles.macports.org/csshX/csshX-0.74.tgz"
  sha256 "eaa9e52727c8b28dedc87398ed33ffa2340d6d0f3ea9d261749c715cb7a0e9c8"
  # same terms as Perl
  license any_of: ["Artistic-1.0-Perl", "GPL-1.0-or-later"]
  head "https://github.com/brockgr/csshx.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "54e3534c5e9c630e932d8a50d4d49dd0aa238f15719df00d6866f08eebfd94bf"
  end

  def install
    bin.install "csshX"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/csshX --version 2>&1", 2)
  end
end
