class Jimtcl < Formula
  desc "Small footprint implementation of Tcl"
  homepage "https://jim.tcl.tk/index.html"
  url "https://github.com/msteveb/jimtcl/archive/refs/tags/0.84.tar.gz"
  sha256 "435095b436b38b96dd85e8cda13878144813bf52066057f76368db178dd8fea2"
  license "BSD-2-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c63800ffadff75842fdcd9ec428931dad46af6d0c09b3a5b5d5004cdd5383e4c"
  end

  depends_on "openssl@3"
  depends_on "readline"

  uses_from_macos "sqlite"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  # patch to include `stdio.h``
  patch do
    url "https://github.com/msteveb/jimtcl/commit/35e0e1f9b1f018666e5170a35366c5fc3b97309c.patch?full_index=1"
    sha256 "50f66a70d130c578f57d9569b62cf7071f7a3a285ca15efefd3485fa385469ba"
  end

  def install
    system "./configure", "--disable-silent-rules",
                          "--with-ext=readline,rlprompt,sqlite3",
                          "--shared",
                          "--docdir=#{doc}",
                          "--ssl",
                          *std_configure_args
    system "make"
    system "make", "install"
    pkgshare.install Dir["examples*"]
  end

  test do
    (testpath/"test.tcl").write "puts {Hello world}"
    assert_match "Hello world", shell_output("#{bin}/jimsh test.tcl")
  end
end
