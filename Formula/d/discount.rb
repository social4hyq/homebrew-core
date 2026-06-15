class Discount < Formula
  desc "C implementation of Markdown"
  homepage "https://www.pell.portland.or.us/~orc/Code/discount/"
  url "https://www.pell.portland.or.us/~orc/Code/discount/discount-3.0.1.3.tar.bz2"
  sha256 "a4e3d4ead2412905b9d07954331cfde30c30743c5e0e4c57f40b3c2659efa30e"
  license "BSD-3-Clause"
  head "https://github.com/Orc/discount.git", branch: "main"

  livecheck do
    url :homepage
    regex(/href=.*?discount[._-]v?(\d+(?:\.\d+)+[a-z]?)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3c783bfeb5df1e5806220b56de6a9dba2e83c3b70ee27a67ccb2b3c27f9c11aa"
  end

  conflicts_with "markdown", because: "both install `markdown` binaries"
  conflicts_with "multimarkdown", because: "both install `markdown` binaries"

  def install
    # Workaround for newer Clang
    ENV.append_to_cflags "-Wno-incompatible-function-pointer-types" if DevelopmentTools.clang_build_version >= 1500

    # Shared libraries are currently not built because they require
    # root access to build without patching.
    # Issue reported upstream here: https://github.com/Orc/discount/issues/266.
    # Add --shared to args when this is resolved.
    args = %W[
      --prefix=#{prefix}
      --mandir=#{man}
      --with-dl=Both
      --enable-dl-tag
      --enable-pandoc-header
      --enable-superscript
      --pkg-config
    ]
    system "./configure.sh", *args
    bin.mkpath
    lib.mkpath
    include.mkpath
    system "make", "install.everything"
  end

  test do
    markdown = "[Homebrew](https://brew.sh/)"
    html = "<p><a href=\"https://brew.sh/\">Homebrew</a></p>"
    assert_equal html, pipe_output(bin/"markdown", markdown, 0).chomp
  end
end
