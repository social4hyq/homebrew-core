class Scheme48 < Formula
  desc "Scheme byte-code interpreter"
  homepage "https://www.s48.org/"
  url "https://s48.org/1.9.3/scheme48-1.9.3.tgz"
  sha256 "6ef5a9f3fca14110b0f831b45801d11f9bdfb6799d976aa12e4f8809daf3904c"
  license "BSD-3-Clause"

  livecheck do
    url :homepage
    regex(%r{href=.*?v?(\d+(?:\.\d+)+)/download\.html}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "229b43f2e357d20a39618c8acefb0811bb4adce54849769b49429ba8fb00a912"
  end

  conflicts_with "gambit-scheme", because: "both install `scheme-r5rs` binaries"

  # remove doc installation step
  patch :DATA

  def install
    # Workaround for newer Clang
    ENV.append_to_cflags "-Wno-implicit-int" if DevelopmentTools.clang_build_version >= 1403

    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", "--enable-gc=bibop", *args, *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"hello.scm").write <<~SCHEME
      (display "Hello, World!") (newline)
    SCHEME

    expected = <<~EOS
      Hello, World!\#{Unspecific}

      \#{Unspecific}

    EOS

    assert_equal expected, shell_output("#{bin}/scheme48 -a batch < hello.scm")
  end
end

__END__
diff --git a/Makefile.in b/Makefile.in
index 5fce20d..1647047 100644
--- a/Makefile.in
+++ b/Makefile.in
@@ -468,7 +468,7 @@ doc/manual.ps: $(MANUAL_SRC)
 doc/html/manual.html: doc/manual.pdf
 	cd $(srcdir)/doc/src && tex2page manual && tex2page manual && tex2page manual

-doc: doc/manual.pdf doc/manual.ps doc/html/manual.html
+doc: # doc/manual.pdf doc/manual.ps doc/html/manual.html

 install: install-no-doc install-doc
