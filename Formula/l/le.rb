class Le < Formula
  desc "Text editor with block and binary operations"
  homepage "https://github.com/lavv17/le"
  url "https://github.com/lavv17/le/releases/download/v1.16.7/le-1.16.7.tar.gz"
  sha256 "1cbe081eba31e693363c9b8a8464af107e4babfd2354a09a17dc315b3605af41"
  license all_of: ["GPL-3.0-or-later", "GPL-2.0-or-later"]

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2741e0297d71eaf5a142ec3a90a2653291b84c88aaa69ac58534bd27ae3b2afa"
  end

  uses_from_macos "ncurses"

  # Backport fix for hex conflict with std::hex
  patch :DATA # part of https://github.com/lavv17/le/commit/f5582ae199e4c4b80d32e4764715d630203b44f6
  patch do
    url "https://github.com/lavv17/le/commit/f5582ae199e4c4b80d32e4764715d630203b44f6.patch?full_index=1"
    sha256 "aa7ce012a03b86a5e3e7724fcd1c4d3cd304a92193510905eb71e614473c66ef"
  end

  def install
    # Configure script makes bad assumptions about curses locations.
    # Future versions allow this to be manually specified:
    # https://github.com/lavv17/le/commit/d921a3cdb3e1a0b50624d17e5efeb5a76d64f29d
    ncurses = OS.mac? ? MacOS.sdk_path/"usr/include" : Formula["ncurses"].include
    inreplace "configure", "/usr/local/include/ncurses", ncurses

    ENV.deparallelize
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    assert_match "Usage", shell_output("#{bin}/le --help", 1)
  end
end

__END__
diff --git a/src/screen.cc b/src/screen.cc
index fcac4e1..0d429f2 100644
--- a/src/screen.cc
+++ b/src/screen.cc
@@ -408,9 +408,9 @@ void  StatusLine()


    if(hex)
-      sprintf(status,"OctOffs:0%-11lo",(unsigned long)(Offset()));
+      snprintf(status,sizeof(status),"OctOffs:0%-11lo",(unsigned long)(Offset()));
    else
-      sprintf(status,"Line=%-5lu Col=%-4lu",
+      snprintf(status,sizeof(status),"Line=%-5lu Col=%-4lu",
 	 (unsigned long)(GetLine()+1),
 	 (unsigned long)(((Text&&Eol())?GetStdCol():GetCol())+1));
