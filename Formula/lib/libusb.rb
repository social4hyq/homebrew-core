class Libusb < Formula
  desc "Library for USB device access"
  homepage "https://libusb.info/"
  url "https://github.com/libusb/libusb/releases/download/v1.0.30/libusb-1.0.30.tar.bz2"
  sha256 "fea36f34f9156400209595e300840767ab1a385ede1dc7ee893015aea9c6dbaf"
  license "LGPL-2.1-or-later"
  compatibility_version 1

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ac25aa4a1b057ece24aa04a61a1d8200a9bb8b85dfb9d5553ec68d6376c24632"
  end

  head do
    url "https://github.com/libusb/libusb.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  def install
    args = %W[--disable-dependency-tracking --prefix=#{prefix} --disable-udev]

    system "./autogen.sh" if build.head?
    system "./configure", *args
    system "make", "install"
    (pkgshare/"examples").install Dir["examples/*"] - Dir["examples/Makefile*"]
  end

  test do
    cp_r (pkgshare/"examples"), testpath
    cd "examples" do
      system ENV.cc, "listdevs.c", "-L#{lib}", "-I#{include}/libusb-1.0",
             "-lusb-1.0", "-o", "test"
      system "./test"
    end
  end
end
