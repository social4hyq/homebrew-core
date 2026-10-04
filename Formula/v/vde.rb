class Vde < Formula
  desc "Ethernet compliant virtual network"
  homepage "https://github.com/virtualsquare/vde-2"
  url "https://github.com/virtualsquare/vde-2/archive/refs/tags/v2.3.3.tar.gz"
  sha256 "a7d2cc4c3d0c0ffe6aff7eb0029212f2b098313029126dcd12dc542723972379"
  license all_of: ["GPL-2.0-or-later", "LGPL-2.1-or-later"]
  head "https://github.com/virtualsquare/vde-2.git", branch: "master"

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/vde-v2.3.3-r2"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "57989ef2d8b66ed4524ed7baf9a34b9286a2a1067b129f8713af81391525e42d"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  patch do
    file "Patches/vde/0001-adapt-ohos-libc.patch"
  end

  def install
    ENV.append "CFLAGS", "-std=gnu17" if DevelopmentTools.clang_build_version >= 1700
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"vde_switch", "-v"
  end
end
