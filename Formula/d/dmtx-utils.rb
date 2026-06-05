class DmtxUtils < Formula
  desc "Read and write data matrix barcodes"
  homepage "https://github.com/dmtx/dmtx-utils"
  url "https://github.com/dmtx/dmtx-utils/archive/refs/tags/v0.7.6.tar.gz"
  sha256 "0d396ec14f32a8cf9e08369a4122a16aa2e5fa1675e02218f16f1ab777ea2a28"
  license all_of: ["GPL-2.0-or-later", "LGPL-2.1-or-later"]
  revision 8

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "290ff80fb9f3c24fdd46cad81de5511fea3de52ffb1ddb5b8a9defcd9a561186"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "pkgconf" => :build

  depends_on "imagemagick"
  depends_on "libdmtx"
  depends_on "libtool"

  on_macos do
    depends_on "fontconfig"
    depends_on "freetype"
    depends_on "gettext"
    depends_on "glib"
    depends_on "liblqr"
    depends_on "libomp"
    depends_on "little-cms2"
  end

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    resource "homebrew-test_image12" do
      url "https://raw.githubusercontent.com/dmtx/libdmtx/ca9313f/test/rotate_test/images/test_image12.png"
      sha256 "683777f43ce2747c8a6c7a3d294f64bdbfee600d719aac60a18fcb36f7fc7242"
    end

    testpath.install resource("homebrew-test_image12")
    image = File.read("test_image12.png")
    assert_equal "9411300724000003", pipe_output("#{bin}/dmtxread", image, 0)
    system "/bin/dd", "if=/dev/random", "of=in.bin", "bs=512", "count=3"
    dmtxwrite_output = pipe_output("#{bin}/dmtxwrite", File.read("in.bin"), 0)
    dmtxread_output = pipe_output("#{bin}/dmtxread", dmtxwrite_output, 0)
    (testpath/"out.bin").atomic_write dmtxread_output
    assert_equal (testpath/"in.bin").sha256, (testpath/"out.bin").sha256
  end
end
