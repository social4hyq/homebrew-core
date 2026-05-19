class Gpsim < Formula
  desc "Simulator for Microchip's PIC microcontrollers"
  homepage "https://gpsim.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/gpsim/gpsim/0.32.0/gpsim-0.32.1.tar.gz"
  sha256 "c704d923ae771fabb7f63775a564dfefd7018a79c914671c4477854420b32e69"
  license "GPL-2.0-or-later"
  head "https://svn.code.sf.net/p/gpsim/code/trunk"

  livecheck do
    url :stable
    regex(%r{url=.*?/gpsim[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d41ea291b06b76433625ee8ecc3aa9fbf0c90468b79799be3fe5a3a211682ca6"
  end

  depends_on "gputils" => :build
  depends_on "pkgconf" => :build
  depends_on "glib"
  depends_on "popt"
  depends_on "readline"

  on_macos do
    depends_on "gettext"
  end

  # https://sourceforge.net/p/gpsim/bugs/289/
  patch :DATA

  def install
    system "./configure", "--disable-gui",
                          "--disable-shared",
                          *std_configure_args
    system "make", "all"
    system "make", "install"
  end

  test do
    system bin/"gpsim", "--version"
  end
end

__END__
Index: program_files.cc
===================================================================
--- a/src/program_files.cc  (revision 2623)
+++ b/src/program_files.cc  (working copy)
@@ -85,8 +85,7 @@
   * ProgramFileTypeList
   * Singleton class to manage the many (as of now three) file types.
   */
-ProgramFileTypeList * ProgramFileTypeList::s_ProgramFileTypeList =
-  new ProgramFileTypeList();
+ProgramFileTypeList * ProgramFileTypeList::s_ProgramFileTypeList = nullptr;
 // We will instantiate g_HexFileType and g_CodFileType here to be sure
 // they are instantiated after s_ProgramFileTypeList. The objects will
 // move should the PIC code moved to its own external module.
@@ -97,6 +96,8 @@
 
 ProgramFileTypeList &ProgramFileTypeList::GetList()
 {
+  if (!s_ProgramFileTypeList)
+      s_ProgramFileTypeList = new ProgramFileTypeList();
   return *s_ProgramFileTypeList;
 }
