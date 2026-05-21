class Hfsutils < Formula
  desc "Tools for reading and writing Macintosh volumes"
  homepage "https://www.mars.org/home/rob/proj/hfs/"
  url "https://ftp.osuosl.org/pub/clfs/conglomeration/hfsutils/hfsutils-3.2.6.tar.gz"
  mirror "https://fossies.org/linux/misc/old/hfsutils-3.2.6.tar.gz"
  sha256 "bc9d22d6d252b920ec9cdf18e00b7655a6189b3f34f42e58d5bb152957289840"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://ftp.mars.org/hfs/"
    regex(/href=.*?hfsutils[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ffaa900e8e01fb6affc87af9d2142824c17813f660c1f2703a8f9dcd61734f99"
  end

  def install
    # Workaround for newer Clang
    ENV.append_to_cflags "-Wno-implicit-int" if DevelopmentTools.clang_build_version >= 1403

    # hpwd.c:55:7: error: call to undeclared library function 'strcmp' with type 'int (const char *, const char *)';
    # ISO C99 and later do not support implicit function declarations
    # Notified the author via email on 2023-01-05
    inreplace "hpwd.c", "# include <stdio.h>\n", "# include <stdio.h>\n# include <string.h>\n"

    system "./configure", "--mandir=#{man}", *std_configure_args
    bin.mkpath
    man1.mkpath
    system "make", "install"
  end

  test do
    system "dd", "if=/dev/zero", "of=disk.hfs", "bs=1k", "count=800"
    system bin/"hformat", "-l", "Test Disk", "disk.hfs"
    output = shell_output("#{bin}/hmount disk.hfs")
    assert_match(/^Volume name is "Test Disk"$/, output)
    assert_match(/^Volume has 803840 bytes free$/, output)
  end
end
