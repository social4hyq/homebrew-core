class Libudfread < Formula
  desc "Universal Disk Format reader"
  homepage "https://code.videolan.org/videolan/libudfread"
  url "https://download.videolan.org/videolan/libudfread/libudfread-1.2.0.tar.xz"
  sha256 "bb477cbd4cfbfc7787d9d05b71ee5e70430f5cfebf1297497f7e83547958050f"
  license "LGPL-2.1-or-later"
  compatibility_version 1

  livecheck do
    url "https://download.videolan.org/pub/videolan/libudfread/"
    regex(/href=.*?libudfread[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8edf522bb339cf32306bb78337bcb8e40af4c10527a672d6bb4bc4f63bf43bfb"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"

    (pkgshare/"examples").install "examples/udfcat.c"
  end

  test do
    cp (pkgshare/"examples/udfcat.c"), testpath

    system ENV.cc, "udfcat.c", "-I#{include}/udfread", "-L#{lib}", "-ludfread", "-o", "udfcat"
    assert_match "usage: udfcat <image> <file>", shell_output("./udfcat 2>&1", 255)
  end
end
