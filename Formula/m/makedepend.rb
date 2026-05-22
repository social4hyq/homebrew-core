class Makedepend < Formula
  desc "Creates dependencies in makefiles"
  homepage "https://x.org/"
  url "https://xorg.freedesktop.org/releases/individual/util/makedepend-1.0.9.tar.xz"
  sha256 "92d0deb659fff6d8ddbc1d27fc4ca8ceb2b6dbe15d73f0a04edc09f1c5782dd4"
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
