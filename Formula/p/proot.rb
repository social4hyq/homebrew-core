class Proot < Formula
  desc "User-space implementation of chroot, mount --bind, and binfmt_misc"
  homepage "https://proot-me.github.io"
  url "https://github.com/proot-me/proot/archive/refs/tags/v5.4.0.tar.gz"
  sha256 "29248aac2a7ce10c3bd5ee5602742ec33b2532310ff9cf73b79f3c133e5a5f68"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f3afc35c4f4ba53beb871c87d42eb52a29e7fc20a7cf5045f124dbb3ea8ed6f8"
  end

  depends_on "pkgconf" => :build
  depends_on "talloc"

  patch do
    file "Patches/proot/0001-support-ohos.patch"
  end

  def install
    ENV.prepend_path "PKG_CONFIG_LIBDIR", "/opt/homebrew/lib/pkgconfig"
    system "make", "-C", "src", "loader.elf", "build.h"
    system "make", "-C", "src", "install", "PREFIX=#{prefix}"
  end

  test do
    system bin/"proot", "--help"
  end
end
