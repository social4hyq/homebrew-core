class Flex < Formula
  desc "Fast Lexical Analyzer, generates Scanners (tokenizers)"
  homepage "https://github.com/westes/flex"
  license "BSD-2-Clause"
  revision 3

  stable do
    url "https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz"
    sha256 "e87aae032bf07c26f85ac0ed3250998c37621d95f8bd748b31f15b33c45ee995"

    # Fix -flat_namespace being used on Big Sur and later.
    patch do
      url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-big_sur.diff"
      sha256 "35acd6aebc19843f1a2b3a63e880baceb0f5278ab1ace661e57a502d9d78c93c"
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "764604e200abceb433be38a8c29df3a7399364e1a61018cb6814680ea3086598"
  end

  head do
    url "https://github.com/westes/flex.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build

    # https://github.com/westes/flex/issues/294
    depends_on "gnu-sed" => :build

    depends_on "libtool" => :build
    depends_on :macos # Needs a pre-existing `flex` to bootstrap.
  end

  keg_only :provided_by_macos

  depends_on "help2man" => :build

  uses_from_macos "bison" => :build
  uses_from_macos "m4"

  depends_on "gettext"

  def install
    if build.head?
      ENV.prepend_path "PATH", Formula["gnu-sed"].opt_libexec/"gnubin"

      system "./autogen.sh"
    end

    # Fix segmentation fault during install on Ubuntu 18.04 (caused by glibc 2.26+),
    # remove with the next release
    ENV.append "CPPFLAGS", "-D_GNU_SOURCE" if OS.linux?

    system "./configure", *std_configure_args,
                          "--disable-silent-rules",
                          "--enable-shared"
    system "make", "install"
    bin.install_symlink "flex" => "lex"
  end

  test do
    (testpath/"test.flex").write <<~FLEX
      CHAR   [a-z][A-Z]
      %%
      {CHAR}+      printf("%s", yytext);
      [ \\t\\n]+   printf("\\n");
      %%
      int main()
      {
        yyin = stdin;
        yylex();
      }
    FLEX
    system bin/"flex", "test.flex"
    system ENV.cc, "lex.yy.c", "-L#{lib}", "-lfl", "-o", "test"
    assert_equal <<~EOS, pipe_output("./test", "Hello World\n")
      Hello
      World
    EOS
  end
end
