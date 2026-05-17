class Libiptcdata < Formula
  desc "Virtual package provided by libiptcdata0"
  homepage "https://libiptcdata.sourceforge.net/"
  url "https://github.com/ianw/libiptcdata/releases/download/release_1_0_5/libiptcdata-1.0.5.tar.gz"
  sha256 "c094d0df4595520f194f6f47b13c7652b7ecd67284ac27ab5f219bc3985ea29e"
  license "LGPL-2.0-only"

  livecheck do
    url :stable
    regex(/^release[._-]v?(\d+(?:[._]\d+)+)$/i)
    strategy :git do |tags, regex|
      tags.filter_map { |tag| tag[regex, 1]&.tr("_", ".") }
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "820f1d0e1d4ee1f9cf1c14d512982f1453bdb0ec498acbdcbed6877a54af6c50"
  end

  on_macos do
    depends_on "gettext"
  end

  # Fix -flat_namespace being used on Big Sur and later.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-big_sur.diff"
    sha256 "35acd6aebc19843f1a2b3a63e880baceb0f5278ab1ace661e57a502d9d78c93c"
  end

  def install
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/iptc --version")
    assert_match "ModelVersion", shell_output("#{bin}/iptc --list")
  end
end
