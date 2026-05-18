class Mergelog < Formula
  desc "Merges httpd logs from web servers behind round-robin DNS"
  homepage "https://mergelog.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/mergelog/mergelog/4.5/mergelog-4.5.tar.gz"
  sha256 "fd97c5b9ae88fbbf57d3be8d81c479e0df081ed9c4a0ada48b1ab8248a82676d"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e16bdd6d79462af6399d2123630df14827ce9c3c50f68b6988fb1be1d7b1836e"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    # Workaround for newer Clang
    ENV.append_to_cflags "-Wno-implicit-int" if DevelopmentTools.clang_build_version >= 1403

    # Temporary Homebrew-specific work around for linker flag ordering problem in Ubuntu 16.04.
    # Remove after migration to 18.04.
    inreplace "src/Makefile.in", "mergelog.c -o", "mergelog.c $(LIBS) -o" unless OS.mac?
    system "./configure", "--mandir=#{man}", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"mergelog", File::NULL
  end
end
