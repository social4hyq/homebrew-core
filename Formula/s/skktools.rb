class Skktools < Formula
  desc "SKK dictionary maintenance tools"
  homepage "https://github.com/skk-dev/skktools"
  url "https://github.com/skk-dev/skktools/archive/refs/tags/skktools-1_3_4.tar.gz"
  sha256 "84cc5d3344362372e0dfe93a84790a193d93730178401a96248961ef161f2168"
  license "GPL-2.0-or-later"
  revision 2

  livecheck do
    url :stable
    regex(/^skktools[._-]v?(\d+(?:[._]\d+)+)$/i)
    strategy :git do |tags, regex|
      tags.filter_map { |tag| tag[regex, 1]&.tr("_", ".") }
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2bbb7809625ef7d9b2711e7f18c922d0d39e988596eb9cb41a5a7d57790b3830"
  end

  depends_on "pkgconf" => :build
  depends_on "glib"

  on_macos do
    depends_on "gettext"
  end

  on_linux do
    depends_on "gdbm"
  end

  def install
    args = ["--with-skkdic-expr2"]
    if OS.linux?
      args << "--with-gdbm"
      # Help find Homebrew's gdbm compatibility layer header
      inreplace %w[configure skkdic-expr.c], "gdbm/ndbm.h", "gdbm-ndbm.h"
    end
    system "./configure", *args, *std_configure_args
    system "make", "CC=#{ENV.cc}"
    ENV.deparallelize
    system "make", "install"
  end

  test do
    test_dic = <<~EOS.strip.tap { |s| s.encode("euc-jis-2004") }
      わるs /悪/
      わるk /悪/
      わるi /悪/
    EOS
    (testpath/"SKK-JISYO.TEST").write test_dic

    test_shuffle = <<~EOS.tap { |s| s.encode("euc-jis-2004") }
      わるs /悪/
      わるi /悪/
      わるk /悪/
    EOS

    expect_shuffle = <<~EOS.tap { |s| s.encode("euc-jis-2004") }
      ;; okuri-ari entries.
      わるs /悪/
      わるk /悪/
      わるi /悪/
    EOS

    test_sp1 = <<~EOS.strip.tap { |s| s.encode("euc-jis-2004") }
      わるs /悪/
      わるk /悪/
    EOS
    (testpath/"test.sp1").write test_sp1

    test_sp2 = <<~EOS.strip.tap { |s| s.encode("euc-jis-2004") }
      わるk /悪/
      わるi /悪/
    EOS
    (testpath/"test.sp2").write test_sp2

    test_sp3 = <<~EOS.strip.tap { |s| s.encode("euc-jis-2004") }
      わるi /悪/
    EOS
    (testpath/"test.sp3").write test_sp3

    expect_expr = <<~EOS.tap { |s| s.encode("euc-jis-2004") }
      ;; okuri-ari entries.
      わるs /悪/
      わるk /悪/
    EOS

    expect_count = "SKK-JISYO.TEST: 3 candidates\n"
    actual_count = shell_output("#{bin}/skkdic-count SKK-JISYO.TEST")
    assert_equal expect_count, actual_count

    actual_shuffle = pipe_output("#{bin}/skkdic-sort", test_shuffle, 0)
    assert_equal expect_shuffle, actual_shuffle

    ["skkdic-expr", "skkdic-expr2"].each do |cmd|
      expr_cmd = "#{bin}/#{cmd} test.sp1 + test.sp2 - test.sp3"
      actual_expr = shell_output(expr_cmd)
      assert_equal expect_expr, pipe_output("#{bin}/skkdic-sort", actual_expr)
    end
  end
end
