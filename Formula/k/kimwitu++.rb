class Kimwituxx < Formula
  desc "Tool for processing trees (i.e. terms)"
  homepage "https://savannah.nongnu.org/projects/kimwitu-pp"
  url "https://download.savannah.gnu.org/releases/kimwitu-pp/kimwitu++-2.3.13.tar.gz"
  sha256 "3f6d9fbb35cc4760849b18553d06bc790466ca8b07884ed1a1bdccc3a9792a73"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://download.savannah.gnu.org/releases/kimwitu-pp/"
    regex(/href=.*?kimwitu\+\+[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cc0fe6d0f568eab9ac7def1be5c5ee7a97cd5a6cef73a264ba9875a33401f03d"
  end

  def install
    system "./configure", "--disable-silent-rules", *std_configure_args
    bin.mkpath
    man1.mkpath
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/kc++ --version")

    # from: https://www.nongnu.org/kimwitu-pp/example/main.k.html
    (testpath/"main.k").write <<~EOS
      // Reverse Polish Notation, main.k
      // © 2001, Michael Piefel <piefel@informatik.hu-berlin.de>

      %{
      #include <iostream>
      #include "k.h"
      #include "rk.h"
      #include "unpk.h"
      #include "csgiok.h"

      int yyparse();
      line TheLine;
      %}
      %{ KC_TYPES_HEADER
      extern line TheLine;
      %}

      // Yes, create YYSTYPE union for the bison parser.
      %option yystype

      // Trivial printer function (ignores view)
      void
      printer(const char *s, uview v)
      {
              std::cout << s;
      }

      int
      main(int argc, char **argv)
      {
              FILE* f;

              std::cout << " RPN Parser and reformatter " << std::endl;
              // If a saved tree is given on command line, read it
              if (argc==2) {
                  f=fopen(argv[1], "r");
                  kc::CSGIOread(f, TheLine);
                  fclose(f);
              } else yyparse();

              line TheCanonLine=TheLine->rewrite(canon);
              line TheShortLine=TheCanonLine->rewrite(calculate);

              std::cout << "\nInfix notation:\n";
              TheCanonLine->unparse(printer, infix);

              std::cout << "\n\nCanonical postfix notation:\n";
              TheCanonLine->unparse(printer, postfix);

              std::cout << "\n\nCalculated infix notation:\n";
              TheShortLine->unparse(printer, infix);

              std::cout << "\n\nCalculated canonical postfix notation:\n";
              TheShortLine->unparse(printer, postfix);

              std::cout << std::endl;
      }
    EOS
    system bin/"kc++", testpath/"main.k"
  end
end
