class Plotutils < Formula
  desc "C/C++ function library for exporting 2-D vector graphics"
  homepage "https://www.gnu.org/software/plotutils/"
  url "https://ftpmirror.gnu.org/gnu/plotutils/plotutils-2.6.tar.gz"
  mirror "https://ftp.gnu.org/gnu/plotutils/plotutils-2.6.tar.gz"
  sha256 "4f4222820f97ca08c7ea707e4c53e5a3556af4d8f1ab51e0da6ff1627ff433ab"
  license "GPL-3.0-or-later"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f98699c6df535ae7ecd90277f44555f0839b3cfb3ecc9ba94588424d2b9a188c"
  end

  depends_on "libpng"

  on_linux do
    depends_on "libx11"
    depends_on "libxaw"
    depends_on "libxext"
    depends_on "libxt"
  end

  def install
    # Fix usage of libpng to be 1.5 compatible
    inreplace "libplot/z_write.c", "png_ptr->jmpbuf", "png_jmpbuf (png_ptr)"

    # Avoid `-flat_namespace` flag.
    ENV["MACOSX_DEPLOYMENT_TARGET"] = MacOS.version.to_s if OS.mac?

    args = %w[
      --disable-silent-rules
      --enable-libplotter
    ]
    # Prevent opportunistic linkage to X11
    args << "--without-x" if OS.mac?
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    assert pipe_output("#{bin}/graph -T ps", "0.0 0.0\n1.0 0.2\n").start_with?("")
  end
end
