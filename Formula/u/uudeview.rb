class Uudeview < Formula
  desc "Smart multi-file multi-part decoder"
  homepage "http://www.fpx.de/fp/Software/UUDeview/"
  url "https://cdn.netbsd.org/pub/pkgsrc/distfiles/uudeview-0.5.20.tar.gz"
  mirror "http://www.fpx.de/fp/Software/UUDeview/download/uudeview-0.5.20.tar.gz"
  sha256 "e49a510ddf272022af204e96605bd454bb53da0b3fe0be437115768710dae435"
  license "GPL-2.0-or-later"
  revision 1

  livecheck do
    url :homepage
    regex(/href=.*?uudeview[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "58098f24b3d79e09500584ae36ee51fdf1db0c21d3ecde7a120ae1677302b513"
  end

  # fix implicit declaration, remove in release > 0.5.20
  patch do
    url "https://github.com/hannob/uudeview/commit/a8f98cf10e2c1ab883c31ed1292f16bfdd43ef33.patch?full_index=1"
    sha256 "1154a62902355105fc61cc38033b9284d488ca29b971ad18744915990ffb31ec"
  end

  patch do
    url "https://github.com/hannob/uudeview/commit/c54cb38ab71363647577fa98bedf4e0a3759c17b.patch?full_index=1"
    sha256 "44347fdb875d5a86909f6c2e6bd25f4325a34c7be83927b6fd5ba4cfe0bea46c"
  end

  patch do
    url "https://github.com/hannob/uudeview/commit/72a52709ea1c79c8747d2c0face50f03873d2f81.patch?full_index=1"
    sha256 "452788a9e81a0839b8bab924406db26542b529dedb8e8073df50eb299aae9dfc"
  end

  def install
    # Fix for newer clang
    ENV.append_to_cflags "-Wno-implicit-int" if DevelopmentTools.clang_build_version >= 1403
    ENV.append_to_cflags "-DSTDC_HEADERS"
    system "./configure", "--prefix=#{prefix}",
                          "--mandir=#{man}",
                          "--disable-tcl"
    system "make", "install"
    # uudeview provides the public library libuu, but no way to install it.
    # Since the package is unsupported, upstream changes are unlikely to occur.
    # Install the library and headers manually for now.
    lib.install "uulib/libuu.a"
    include.install "uulib/uudeview.h"
  end

  test do
    system bin/"uudeview", "-V"
  end
end
