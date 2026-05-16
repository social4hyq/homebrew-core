class Recutils < Formula
  desc "Tools to work with human-editable, plain text data files"
  homepage "https://www.gnu.org/software/recutils/"
  url "https://ftpmirror.gnu.org/gnu/recutils/recutils-1.9.tar.gz"
  mirror "https://ftp.gnu.org/gnu/recutils/recutils-1.9.tar.gz"
  sha256 "6301592b0020c14b456757ef5d434d49f6027b8e5f3a499d13362f205c486e0e"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0b47e69b9c87238fe01251e54ba278d75e051df5982d44cc761fbce5b20fc563"
  end

  on_linux do
    depends_on "libgcrypt"
  end

  # Fix -flat_namespace being used on Big Sur and later.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-big_sur.diff"
    sha256 "35acd6aebc19843f1a2b3a63e880baceb0f5278ab1ace661e57a502d9d78c93c"
  end

  def install
    # Fix compile with newer Clang. Remove in the next release.
    # Ref: http://git.savannah.gnu.org/cgit/recutils.git/commit/?id=e154822aeec19cb790f8618ee740875c048859e4
    ENV.append_to_cflags "-Wno-implicit-function-declaration" if DevelopmentTools.clang_build_version >= 1403

    system "./configure", "--datarootdir=#{elisp}",
                          "--disable-silent-rules",
                          *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.csv").write <<~CSV
      a,b,c
      1,2,3
    CSV
    system bin/"csv2rec", "test.csv"

    (testpath/"test.rec").write <<~EOS
      %rec: Book
      %mandatory: Title

      Title: GNU Emacs Manual
    EOS
    system bin/"recsel", "test.rec"
  end
end
