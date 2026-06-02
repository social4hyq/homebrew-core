class Winetricks < Formula
  desc "Automatic workarounds for problems in Wine"
  homepage "https://github.com/Winetricks/winetricks"
  url "https://github.com/Winetricks/winetricks/archive/refs/tags/20260125.tar.gz"
  sha256 "2890bd9fbbade4638e58b4999a237273192df03b58516ae7b8771e09c22d2f56"
  license "LGPL-2.1-or-later"
  head "https://github.com/Winetricks/winetricks.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d{6,8})$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "acedb18376bf9a661f00d4275e5d101a6742d421db305035d5162680602de284"
  end

  depends_on "cabextract"
  depends_on "p7zip"
  depends_on "unzip"

  def install
    bin.install "src/winetricks"
    man1.install "src/winetricks.1"
  end

  test do
    system bin/"winetricks", "--version"
  end
end
