class Xtitle < Formula
  desc "Set window title and icon for your X terminal"
  homepage "https://kinzler.com/me/xtitle/"
  url "https://kinzler.com/me/xtitle/xtitle-1.0.4.tgz"
  sha256 "cadddef1389ba1c5e1dc7dd861545a5fe11cb397a3f692cd63881671340fcc15"
  license "GPL-2.0-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?xtitle[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "86d09221fb428c990f642f5931b090b9cf15f6396f7c992a36e837238e10eedc"
  end

  def install
    bin.install "xtitle.sh" => "xtitle"
    bin.install "xtctl.sh" => "xtctl"
    man1.install "xtitle.man" => "xtitle.1"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/xtitle --version")
  end
end
