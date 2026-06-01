class Pbzip2 < Formula
  desc "Parallel bzip2"
  homepage "http://compression.great-site.net/pbzip2/"
  url "https://launchpad.net/pbzip2/1.1/1.1.13/+download/pbzip2-1.1.13.tar.gz"
  sha256 "8fd13eaaa266f7ee91f85c1ea97c86d9c9cc985969db9059cdebcb1e1b7bdbe6"
  license "bzip2-1.0.6"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2163a632c919c239245a853244be1dfe5463bc9d29081723bbc4e0600c6fdcbf"
  end

  uses_from_macos "bzip2"

  # Fixes: error: implicit instantiation of undefined template 'std::char_traits<unsigned char>'
  # https://developer.apple.com/documentation/xcode-release-notes/xcode-16_3-release-notes#C++-Standard-Library
  on_macos do
    patch :DATA
  end

  def install
    # Workaround for Xcode 16 (Clang 16) and non-macOS Clang
    ENV.append "CXXFLAGS", "-Wno-reserved-user-defined-literal"

    # C++20 is required for char8_t in the patch.
    ENV.append "CXXFLAGS", "-std=c++20" if OS.mac?

    system "make", "PREFIX=#{prefix}",
                   "CXX=#{ENV.cxx}",
                   "CXXFLAGS=#{ENV.cxxflags}",
                   "install"
  end

  test do
    system bin/"pbzip2", "--version"
  end
end

__END__
--- a/BZ2StreamScanner.cpp
+++ b/BZ2StreamScanner.cpp
@@ -42,7 +42,7 @@ int BZ2StreamScanner::init( int hInFile, size_t inBuffCapacity )
 {
 	dispose();
 
-	CharType bz2header[] = "BZh91AY&SY";
+	CharType bz2header[] = u8"BZh91AY&SY";
 	// zero-terminated string
 	CharType bz2ZeroHeader[] =
 		{ 'B', 'Z', 'h', '9', 0x17, 0x72, 0x45, 0x38, 0x50, 0x90, 0 };
--- a/BZ2StreamScanner.h
+++ b/BZ2StreamScanner.h
@@ -20,7 +20,7 @@ namespace pbzip2
 class BZ2StreamScanner
 {
 public:
-	typedef unsigned char CharType;
+	typedef char8_t CharType;
 
 	static const size_t DEFAULT_IN_BUFF_CAPACITY = 1024 * 1024; // 1M
 	static const size_t DEFAULT_OUT_BUFF_LIMIT = 1024 * 1024;
