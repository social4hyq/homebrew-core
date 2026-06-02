class FonFlashCli < Formula
  desc "Flash La Fonera and Atheros chipset compatible devices"
  homepage "https://www.gargoyle-router.com/wiki/doku.php?id=fon_flash"
  url "https://github.com/ericpaulbishop/gargoyle/archive/refs/tags/1.14.0.tar.gz"
  sha256 "bd3ba67ab9cd8c7474ce8f02a3a320b91aec72c6710e43c18dbe719b13f3820a"
  license "GPL-2.0-or-later"
  head "https://github.com/ericpaulbishop/gargoyle.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6b2f7657ed07c0728dac5bc54b0014c99c3e4729c143db641e876442effb3057"
  end

  uses_from_macos "libpcap"

  # Apply open PR commit to fix aarch64 linux, https://github.com/ericpaulbishop/gargoyle/pull/1017
  patch do
    url "https://github.com/ericpaulbishop/gargoyle/commit/e69325f56366074d771379528d3c8cbf75cbb9e7.patch?full_index=1"
    sha256 "79a053f5796be94bbb6fe2d3d1a1f113236033cc5b8d579edcc4d9f0c63aef26"
  end

  def install
    cd "fon-flash" do
      system "make", "fon-flash"
      bin.install "fon-flash"
    end
  end

  test do
    system bin/"fon-flash"
  end
end
