class Makedepend < Formula
  desc "Creates dependencies in makefiles"
  homepage "https://x.org/"
  url "https://xorg.freedesktop.org/releases/individual/util/makedepend-1.0.10.tar.xz"
  sha256 "f278c4686285d70292c03f7339cc3c0a811fc6c4bf9c053906d0a5732eac9138"
  license "MIT"

  livecheck do
    url "https://xorg.freedesktop.org/releases/individual/util/"
    regex(/href=.*?makedepend[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5ffe33e664a9e6bab7f03bad86775ffe9beaa5604e1f6edc50bc917630c2598b"
  end

  depends_on "pkgconf" => :build
  depends_on "util-macros"
  depends_on "xorgproto"

  def install
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    touch "Makefile"
    system bin/"makedepend"
  end
end
