class Aamath < Formula
  desc "Renders mathematical expressions as ASCII art"
  homepage "http://fuse.superglue.se/aamath/"
  url "https://cdn.netbsd.org/pub/pkgsrc/distfiles/aamath-0.3.tar.gz"
  mirror "http://fuse.superglue.se/aamath/aamath-0.3.tar.gz"
  sha256 "9843f4588695e2cd55ce5d8f58921d4f255e0e65ed9569e1dcddf3f68f77b631"
  license "GPL-2.0-only"

  livecheck do
    url :homepage
    regex(/href=.*?aamath[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "55a733762ad52ba508de7479adfb0244e476efe97578a5220dbfbdf95151761d"
  end

  uses_from_macos "bison" => :build # for yacc
  uses_from_macos "flex" => :build
  uses_from_macos "libedit" # readline's license is incompatible with GPL-2.0-only

  # Fix build on clang; patch by Homebrew team
  # https://github.com/Homebrew/homebrew/issues/23872
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/aamath/0.3.patch"
    sha256 "9443881d7950ac8d2da217a23ae3f2c936fbd6880f34dceba717f1246d8608f1"
  end

  def install
    unless OS.mac?
      inreplace "Makefile" do |s|
        s.change_make_var! "CFLAGS", "#{s.get_make_var("CFLAGS")} -I#{Formula["libedit"].opt_libexec}/include"
        s.change_make_var! "LFLAGS", "#{s.get_make_var("LFLAGS")} -L#{Formula["libedit"].opt_libexec}/lib"
      end
    end

    ENV.deparallelize
    system "make"

    bin.install "aamath"
    man1.install "aamath.1"
    prefix.install "testcases"
  end

  test do
    s = pipe_output(bin/"aamath", (prefix/"testcases").read, 0)
    assert_match "f(x + h) = f(x) + h f'(x)", s
  end
end
