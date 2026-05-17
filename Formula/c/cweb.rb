class Cweb < Formula
  desc "Literate documentation system for C, C++, and Java"
  homepage "https://cs.stanford.edu/~knuth/cweb.html"
  url "https://github.com/ascherer/cweb/archive/refs/tags/cweb-4.12.2.tar.gz"
  sha256 "519ac1c03610eea18956ed62d2996dc5a629f0c3af91f38cf4621d5deab749fd"
  license "Knuth-CTAN" # https://ctan.org/pkg/cweb

  livecheck do
    url :stable
    regex(/^cweb[._-]v?(\d+(?:\.\d+)+[a-z]?)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9863b5b3719c15ddc5de62082d05b485255ff0c0f7c11f1e9b5d7d4332ad39be"
  end

  conflicts_with "texlive", because: "both install `cweb` binaries"

  def install
    ENV.deparallelize

    macrosdir = share/"texmf/tex/generic"
    cwebinputs = lib/"cweb"

    # make install doesn't use `mkdir -p` so this is needed
    [bin, man1, macrosdir, elisp, cwebinputs].each(&:mkpath)

    system "make", "install",
      "DESTDIR=#{bin}/",
      "MANDIR=#{man1}",
      "MANEXT=1",
      "MACROSDIR=#{macrosdir}",
      "EMACSDIR=#{elisp}",
      "CWEBINPUTS=#{cwebinputs}"
  end

  test do
    (testpath/"test.w").write <<~EOS
      @* Hello World
      This is a minimal program written in CWEB.

      @c
      #include <stdio.h>
      void main() {
          printf("Hello world!");
      }
    EOS
    system bin/"ctangle", "test.w"
    system ENV.cc, "test.c", "-o", "hello"
    assert_equal "Hello world!", pipe_output("./hello")
  end
end
