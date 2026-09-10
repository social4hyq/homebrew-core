class Libplist < Formula
  desc "Library for Apple Binary- and XML-Property Lists"
  homepage "https://libimobiledevice.org/"
  url "https://github.com/libimobiledevice/libplist/releases/download/2.7.0/libplist-2.7.0.tar.bz2"
  sha256 "7ac42301e896b1ebe3c654634780c82baa7cb70df8554e683ff89f7c2643eb8b"
  license "LGPL-2.1-or-later"
  revision 1
  compatibility_version 1
  head "https://github.com/libimobiledevice/libplist.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6b539f41dd86d7099557fa9cb177e0abeff03f37244a4ac320bf1c6e714de68b"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build

  def install
    ENV.deparallelize

    args = %w[
      --disable-silent-rules
      --without-cython
    ]

    system "./autogen.sh", *args, *std_configure_args if build.head?
    system "./configure", *args, *std_configure_args if build.stable?
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.plist").write <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>test</string>
        <key>ProgramArguments</key>
        <array>
          <string>/bin/echo</string>
        </array>
      </dict>
      </plist>
    EOS
    system bin/"plistutil", "-i", "test.plist", "-o", "test_binary.plist"
    assert_path_exists testpath/"test_binary.plist", "Failed to create converted plist!"
  end
end
