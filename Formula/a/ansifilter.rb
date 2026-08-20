class Ansifilter < Formula
  desc "Strip or convert ANSI codes into HTML, (La)Tex, RTF, or BBCode"
  homepage "http://andre-simon.de/doku/ansifilter/en/ansifilter.php"
  url "https://gitlab.com/saalen/ansifilter/-/archive/2.23/ansifilter-2.23.tar.bz2"
  sha256 "ff9efcfe8623593a54cd7bec2499711ec2a49a425ab50c61f2148c6d7450d525"
  license "GPL-3.0-or-later"

  livecheck do
    url "http://andre-simon.de/zip/download.php"
    regex(/href=.*?ansifilter[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ea95047e036d4642316cc692ea2412c3ef3703e256c4e27df290fa7979363a61"
  end

  def install
    system "make", "PREFIX=#{prefix}"
    system "make", "PREFIX=#{prefix}", "install"
  end

  test do
    path = testpath/"ansi.txt"
    path.write "f\x1b[31moo"

    assert_equal "foo", shell_output("#{bin}/ansifilter #{path}").strip
  end
end
