class AutoconfArchive < Formula
  desc "Collection of over 500 reusable autoconf macros"
  homepage "https://savannah.gnu.org/projects/autoconf-archive/"
  url "https://ftpmirror.gnu.org/gnu/autoconf-archive/autoconf-archive-2024.10.16.tar.xz"
  mirror "https://ftp.gnu.org/gnu/autoconf-archive/autoconf-archive-2024.10.16.tar.xz"
  sha256 "7bcd5d001916f3a50ed7436f4f700e3d2b1bade3ed803219c592d62502a57363"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fcc405e4598a8c5dc64a4394dcd01000b4ce6b25643ac526ff1af64470096ea4"
  end

  # autoconf-archive is useless without autoconf
  depends_on "autoconf"

  # Fix quoting of `m4_fatal`
  # https://github.com/autoconf-archive/autoconf-archive/pull/312
  # https://github.com/Homebrew/homebrew-core/issues/202234
  patch do
    url "https://github.com/autoconf-archive/autoconf-archive/commit/fadde164479a926d6b56dd693ded2a4c36ed89f0.patch?full_index=1"
    sha256 "4d9a4ca1fc9dc9e28a765ebbd1fa0e1080b6c8401e048b28bb16b9735ff7bf77"
  end

  def install
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"configure.ac").write <<~EOS
      AC_INIT([test], [0.1])
      AX_CHECK_ENABLE_DEBUG
      AC_OUTPUT
    EOS

    system Formula["autoconf"].bin/"autoconf", "configure.ac"
    assert_path_exists testpath/"autom4te.cache"
  end
end
