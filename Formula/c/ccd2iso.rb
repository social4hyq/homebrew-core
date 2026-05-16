class Ccd2iso < Formula
  desc "Convert CloneCD images to ISO images"
  homepage "https://ccd2iso.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/ccd2iso/ccd2iso/ccd2iso-0.3/ccd2iso-0.3.tar.gz"
  sha256 "f874b8fe26112db2cdb016d54a9f69cf286387fbd0c8a55882225f78e20700fc"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "25c3207dec2e453b76efbb0f3bbb7c62aed23d03b8f271a80205f766530ba14c"
  end

  def install
    # Missing <string.h> header file, see https://sourceforge.net/p/ccd2iso/bugs/11/
    inreplace "src/ccd2iso.c", "#include <stdlib.h>\n", "#include <stdlib.h>\n#include <string.h>\n"

    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    assert_match(
      /^#{Regexp.escape(version)}$/, shell_output("#{bin}/ccd2iso --version")
    )
  end
end
