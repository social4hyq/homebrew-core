class Swig < Formula
  desc "Generate scripting interfaces to C/C++ code"
  homepage "https://www.swig.org/"
  url "https://downloads.sourceforge.net/project/swig/swig/swig-4.5.1/swig-4.5.1.tar.gz"
  sha256 "7fec50b27deddab5455a9633780b6341eddfb96215a7619e93a76eb27178f653"
  license "GPL-3.0-or-later"
  revision 1
  compatibility_version 1

  livecheck do
    url "https://sourceforge.net/projects/swig/rss?path=/swig"
    regex(%r{url=.*?/swig[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "34e085234c13d169d306c5e1307657914548913e71a1c3c44fa154738ecc55f0"
  end

  head do
    url "https://github.com/swig/swig.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  depends_on "pcre2"

  uses_from_macos "python" => :test

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    ENV.append "CXXFLAGS", "-std=c++11" # Fix `nullptr` support detection.
    system "./autogen.sh" if build.head?
    system "./configure", *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      int add(int x, int y) {
        return x + y;
      }
    C
    (testpath/"test.i").write <<~EOS
      %module test
      %inline %{
      extern int add(int x, int y);
      %}
    EOS
    (testpath/"pyproject.toml").write <<~TOML
      [project]
      name = "test"
      version = "0.1"

      [tool.setuptools]
      ext-modules = [
        {name = "_test", sources = ["test_wrap.c", "test.c"]}
      ]
    TOML
    (testpath/"run.py").write <<~PYTHON
      import test
      print(test.add(1, 1))
    PYTHON

    ENV.remove_from_cflags(/-march=\S*/)
    system bin/"swig", "-python", "test.i"
    system "python3", "-m", "venv", ".venv"
    system testpath/".venv/bin/pip", "install", *std_pip_args(prefix: false, build_isolation: true), "."
    assert_equal "2", shell_output("#{testpath}/.venv/bin/python3 ./run.py").strip
  end
end
