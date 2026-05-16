class Md5deep < Formula
  desc "Recursively compute digests on files/directories"
  homepage "https://github.com/jessek/hashdeep"
  url "https://github.com/jessek/hashdeep/archive/refs/tags/release-4.4.tar.gz"
  sha256 "dbda8ab42a9c788d4566adcae980d022d8c3d52ee732f1cbfa126c551c8fcc46"
  license "GPL-2.0-or-later"
  revision 1
  head "https://github.com/jessek/hashdeep.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7f7af09b07683417cae87afdf2b9c341970d32544509d0397284171dfa32949a"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  # Fix compilation error due to very old GNU config scripts in source repo
  # reported upstream at https://github.com/jessek/hashdeep/issues/400
  patch :DATA

  # Fix compilation error due to pointer comparison
  patch do
    url "https://github.com/jessek/hashdeep/commit/8776134.patch?full_index=1"
    sha256 "3d4e3114aee5505d1336158b76652587fd6f76e1d3af784912277a1f93518c64"
  end

  # Fix literal and identifier spacing as dictated by C++11
  # upstream pr ref, https://github.com/jessek/hashdeep/pull/385
  patch do
    url "https://github.com/jessek/hashdeep/commit/18a6b5d57f7a648d2b7dcc6e50ff00a1e4b05fcc.patch?full_index=1"
    sha256 "a48a214b06372042e4e9fc06caae9d0e31da378892d28c4a30b4800cedf85e86"
  end

  def install
    system "sh", "bootstrap.sh"
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"testfile.txt").write("This is a test file")
    # Do not reduce the spacing of the below text.
    assert_equal "91b7b0b1e27bfbf7bc646946f35fa972c47c2d32  testfile.txt",
                 shell_output("#{bin}/sha1deep -b testfile.txt").strip
  end
end

__END__
--- a/config.guess
+++ b/config.guess
@@ -797,6 +797,9 @@
     arm*:Linux:*:*)
	echo ${UNAME_MACHINE}-unknown-linux-gnu
	exit 0 ;;
+    aarch64:Linux:*:*)
+	echo ${UNAME_MACHINE}-unknown-linux-gnu
+	exit 0 ;;
     ia64:Linux:*:*)
	echo ${UNAME_MACHINE}-unknown-linux-gnu
	exit 0 ;;
@@ -1130,6 +1133,9 @@
     *:Rhapsody:*:*)
	echo ${UNAME_MACHINE}-apple-rhapsody${UNAME_RELEASE}
	exit 0 ;;
+    arm64:Darwin:*:*)
+	echo arm-apple-darwin"$UNAME_RELEASE"
+	exit ;;
     *:Darwin:*:*)
	case `uname -p` in
	    *86) UNAME_PROCESSOR=i686 ;;
