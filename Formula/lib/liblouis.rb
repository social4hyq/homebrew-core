class Liblouis < Formula
  desc "Open-source braille translator and back-translator"
  homepage "https://liblouis.io"
  url "https://github.com/liblouis/liblouis/releases/download/v3.38.0/liblouis-3.38.0.tar.gz"
  sha256 "afb26096b18b17f43e6055e6a79ce0058eb9dbdcdcc4597522dcd7f11915ec16"
  license all_of: ["GPL-3.0-or-later", "LGPL-2.1-or-later"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9cb10f2e10156b8df98eb406ea13acf4f5f14dcd29719b72df15cbc4c25fd095"
  end

  head do
    url "https://github.com/liblouis/liblouis.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "help2man" => :build
  depends_on "pkgconf" => :build
  depends_on "python@3.14"

  uses_from_macos "m4"

  def python3
    "python3.14"
  end

  def install
    system "./autogen.sh" if build.head?
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make"
    system "make", "check"
    system "make", "install"
    system python3, "-m", "pip", "install", *std_pip_args(build_isolation: true), "./python"
    (prefix/"tools").install bin/"lou_maketable", bin/"lou_maketable.d"
  end

  test do
    assert_equal "⠼⠙⠃", pipe_output("#{bin}/lou_translate unicode.dis,en-us-g2.ctb", "42")

    (testpath/"test.py").write <<~PYTHON
      import louis
      print(louis.translateString(["unicode.dis", "en-us-g2.ctb"], "42"))
    PYTHON
    assert_equal "⠼⠙⠃", shell_output("#{python3} test.py").chomp
  end
end
