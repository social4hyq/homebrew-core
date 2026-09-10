class Shellcheck < Formula
  desc "Static analysis and lint tool, for (ba)sh scripts"
  homepage "https://www.shellcheck.net/"
  url "https://github.com/koalaman/shellcheck/archive/refs/tags/v0.11.0.tar.gz"
  sha256 "8b07554f92e4fbfc33f1539a1f475f21c6503ceae8f806efcc518b1f529f7102"
  license "GPL-3.0-or-later"
  revision 1
  compatibility_version 1
  head "https://github.com/koalaman/shellcheck.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0582888b613263f7b24c02c378646b569ad12ae409280e96fa6497e109da3267"
  end

  depends_on "cabal-install" => :build
  depends_on "ghc" => :build
  depends_on "pandoc" => :build
  depends_on "gmp"

  uses_from_macos "libffi"

  def install
    system "cabal", "v2-update"
    system "cabal", "v2-install", *std_cabal_v2_args
    system "./manpage"
    man1.install "shellcheck.1"
  end

  test do
    sh = testpath/"test.sh"
    sh.write <<~SH
      for f in $(ls *.wav)
      do
        echo "$f"
      done
    SH
    assert_match "[SC2045]", shell_output("#{bin}/shellcheck -f gcc #{sh}", 1)
  end
end
