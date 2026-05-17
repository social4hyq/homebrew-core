class Chordii < Formula
  desc "Text file to music sheet converter"
  homepage "https://www.vromans.org/johan/projects/Chordii/"
  url "https://downloads.sourceforge.net/project/chordii/chordii/4.5/chordii-4.5.3b.tar.gz"
  sha256 "edb19be9de456366e592a75a5ce1c0a75352a55d5b4e5f282c953c7e7f2d87b5"
  license "GPL-3.0-or-later"

  livecheck do
    url "https://sourceforge.net/projects/chordii/rss?path=/chordii"
    regex(%r{url=.*?/chordii[._-]v?(\d+(?:\.\d+)+[a-z]?)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1aec82284bbe4ea5945d34f37843a4e5fc8c6dd86549e006537d9c6f874654f5"
  end

  def install
    # Work around failure from GCC 10+ using default of `-fno-common`
    ENV.append_to_cflags "-fcommon" if OS.linux?

    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"homebrew.cho").write <<~EOS
      {title:Homebrew}
      {subtitle:I can't write lyrics. Send help}

      [C]Thank [G]You [F]Everyone,
      [C]We couldn't maintain [F]Homebrew without you,
      [G]Here's an appreciative song from us to [C]you.
    EOS

    system bin/"chordii", "--output=#{testpath}/homebrew.ps", "homebrew.cho"
    assert_path_exists testpath/"homebrew.ps"
  end
end
