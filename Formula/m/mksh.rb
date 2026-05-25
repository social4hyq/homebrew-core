class Mksh < Formula
  desc "MirBSD Korn Shell"
  homepage "https://mbsd.evolvis.org/mksh.htm"
  url "http://ftp.debian.org/debian/pool/main/m/mksh/mksh_59c.orig.tar.gz"
  version "59c"
  sha256 "77ae1665a337f1c48c61d6b961db3e52119b38e58884d1c89684af31f87bc506"
  license "MirOS"

  livecheck do
    url "https://mbsd.evolvis.org/MirOS/dist/mir/mksh/"
    regex(/href=.*?mksh-R?(\d+[a-z]?)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "37ff0914f14e7d785cfa311e5b204f887eeeed4e98a4149334106cfa5983a990"
  end

  def install
    system "sh", "./Build.sh", "-r"
    bin.install "mksh"
    man1.install "mksh.1"
  end

  test do
    assert_equal "honk",
      shell_output("#{bin}/mksh -c 'echo honk'").chomp
  end
end
