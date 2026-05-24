class Netmask < Formula
  desc "IP address netmask generation utility"
  homepage "https://github.com/tlby/netmask"
  url "https://github.com/tlby/netmask/archive/refs/tags/v2.5.0.tar.gz"
  sha256 "f352d8117a4f9377a15919d9ad4989cfba8816958718a914abf1414242a9f636"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "44087c22c068fd6be9437c5e06f79fe050f79913f3d5ba71b07dcb05ba5f4e6f"
  end

  depends_on "autoconf" => :build
  depends_on "autoconf-archive" => :build
  depends_on "automake" => :build
  depends_on "pkgconf" => :build

  depends_on "check"

  on_system :linux, macos: :ventura_or_newer do
    depends_on "texinfo" => :build
  end

  def install
    system "./bootstrap"
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    assert_equal "100.64.0.0/10", shell_output("#{bin}/netmask -c 100.64.0.0:100.127.255.255").strip
  end
end
