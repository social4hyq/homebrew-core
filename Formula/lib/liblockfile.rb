class Liblockfile < Formula
  desc "Library providing functions to lock standard mailboxes"
  homepage "https://tracker.debian.org/pkg/liblockfile"
  url "https://deb.debian.org/debian/pool/main/libl/liblockfile/liblockfile_1.17.orig.tar.gz"
  sha256 "6e937f3650afab4aac198f348b89b1ca42edceb17fb6bb0918f642143ccfd15e"
  license "LGPL-2.0-or-later"
  revision 1

  # Use open(O_CREAT|O_EXCL) instead of link() for lockfile creation.
  # HarmonyOS HMDFS doesn't support hard links (link() returns EPERM).
  patch do
    file "Patches/liblockfile/0001-use-open-excl-instead-of-link.patch"
  end

  livecheck do
    url "https://deb.debian.org/debian/pool/main/libl/liblockfile/"
    regex(/href=.*?liblockfile[._-]v?(\d+(?:\.\d+)+)\.orig\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "114beebd25b3389c1984bd067130dc6539112648d2395f0f9702f1efa59f09a2"
  end

  def install
    # brew runs without root privileges (and the group is named "wheel" anyway)
    inreplace "Makefile.in", " -g root ", " "

    args = %W[
      --sysconfdir=#{etc}
      --mandir=#{man}
    ]
    args << "--with-mailgroup=staff" if OS.mac?

    system "./configure", *std_configure_args, *args
    bin.mkpath
    lib.mkpath
    include.mkpath
    man1.mkpath
    man3.mkpath
    system "make"
    system "make", "install"
  end

  test do
    system bin/"dotlockfile", "-l", "locked"
    assert_path_exists testpath/"locked"
    system bin/"dotlockfile", "-u", "locked"
    refute_path_exists testpath/"locked"
  end
end
