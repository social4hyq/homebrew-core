class Cattle < Formula
  desc "Brainfuck language toolkit"
  homepage "https://kiyuko.org/software/cattle"
  license "GPL-2.0-or-later"

  stable do
    url "https://kiyuko.org/software/cattle/releases/cattle-1.4.0.tar.xz"
    sha256 "9ba2d746f940978b5bfc6c39570dde7dc55d5b4d09d0d25f29252d6a25fb562f"

    # Fix -flat_namespace being used on Big Sur and later.
    patch do
      url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-big_sur.diff"
      sha256 "35acd6aebc19843f1a2b3a63e880baceb0f5278ab1ace661e57a502d9d78c93c"
    end
  end

  livecheck do
    url "https://kiyuko.org/software/cattle/releases"
    regex(/href=.*?cattle[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "966e3cc1b911c160f6d07fb3c9f0d5a19da6bc55c467d771780ffe33f77930fc"
  end

  head do
    url "https://github.com/andreabolognani/cattle.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "gtk-doc" => :build
    depends_on "libtool" => :build
  end

  depends_on "gobject-introspection" => :build
  depends_on "pkgconf" => :build

  depends_on "glib"

  on_macos do
    depends_on "gettext"
  end

  def install
    pkgshare.mkpath
    cp_r ["examples", "tests"], pkgshare
    rm Dir["#{pkgshare}/{examples,tests}/{Makefile.am,.gitignore}"]

    if build.head?
      inreplace "autogen.sh", "libtoolize", "glibtoolize"
      system "sh", "autogen.sh"
    end

    mkdir "build" do
      system "../configure", "--disable-silent-rules", *std_configure_args
      system "make", "install"
    end
  end

  test do
    cp_r (pkgshare/"examples").children, testpath
    cp_r (pkgshare/"tests").children, testpath
    system ENV.cc, "common.c", "run.c", "-o", "test",
           "-I#{include}/cattle-1.0",
           "-I#{Formula["glib"].include}/glib-2.0",
           "-I#{Formula["glib"].lib}/glib-2.0/include",
           "-L#{lib}",
           "-L#{Formula["glib"].lib}",
           "-lcattle-1.0", "-lglib-2.0", "-lgio-2.0", "-lgobject-2.0"
    assert_match "Unbalanced brackets", shell_output("./test program.c 2>&1", 1)
  end
end
