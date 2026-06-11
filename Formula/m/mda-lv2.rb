class MdaLv2 < Formula
  desc "LV2 port of the MDA plugins"
  homepage "https://drobilla.net/software/mda-lv2.html"
  url "https://download.drobilla.net/mda-lv2-1.2.12.tar.xz"
  sha256 "8f2090433e60e90d9c4d0326970c845a3cb471951657cd9355d3dbca4040b873"
  license "GPL-3.0-or-later"

  livecheck do
    url "https://download.drobilla.net"
    regex(/href=.*?mda-lv2[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "59918fe488b8fa41349350b7066919107d0987ded78dc2d4033e2fdcfa889ace"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "sord" => :test
  depends_on "lv2"

  uses_from_macos "python" => :build

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build"
    system "meson", "install", "-C", "build"
  end

  test do
    # Validate mda.lv2 plugin metadata (needs definitions included from lv2)
    system Formula["sord"].opt_bin/"sord_validate",
           *Dir[Formula["lv2"].opt_lib/"**/*.ttl"],
           *Dir[lib/"lv2/mda.lv2/*.ttl"]
  end
end
