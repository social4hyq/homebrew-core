class Cgdb < Formula
  desc "Curses-based interface to the GNU Debugger"
  homepage "https://cgdb.github.io/"
  url "https://cgdb.me/files/cgdb-0.8.0.tar.gz"
  sha256 "0d38b524d377257b106bad6d856d8ae3304140e1ee24085343e6ddf1b65811f1"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://cgdb.me/files/"
    regex(/href=.*?cgdb[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a9bbbcdbee4cb6aa5b8e3542ef37e9cd1db474c0c52f0e35ba02dd131b139964"
  end

  head do
    url "https://github.com/cgdb/cgdb.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  depends_on "help2man" => :build
  depends_on "readline"

  uses_from_macos "flex" => :build
  uses_from_macos "ncurses"

  on_system :linux, macos: :ventura_or_newer do
    depends_on "texinfo" => :build
  end

  # patch for readline check code, upstream pr ref, https://github.com/cgdb/cgdb/pull/359
  patch :DATA

  def install
    system "sh", "autogen.sh" if build.head?
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--with-readline=#{Formula["readline"].opt_prefix}"
    system "make", "install"
  end

  test do
    system bin/"cgdb", "--version"
  end
end

__END__
diff --git a/configure b/configure
index c564dc1..e13c67c 100755
--- a/configure
+++ b/configure
@@ -6512,7 +6512,7 @@ else
 #include <stdlib.h>
 #include <readline/readline.h>

-main()
+int main()
 {
 	FILE *fp;
 	fp = fopen("conftest.rlv", "w");
