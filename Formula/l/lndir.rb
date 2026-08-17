class Lndir < Formula
  desc "Create a shadow directory of symbolic links to another directory tree"
  homepage "https://gitlab.freedesktop.org/xorg/util/lndir"
  url "https://www.x.org/releases/individual/util/lndir-1.0.6.tar.xz"
  sha256 "18f6d664e52894b7dee0d2fc9b171e0e58566e5091e44f9535f10e6d941912a4"
  license "MIT-open-group"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5262c81e1211fa2e2d452dd4687c3004d2b72d354dd4810ac751b71241f67601"
  end

  depends_on "pkgconf" => :build
  depends_on "xorgproto"  => :build

  def install
    system "./configure", *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    mkdir "test"
    system bin/"lndir", bin, "test"
    assert_path_exists testpath/"test/lndir"
  end
end
