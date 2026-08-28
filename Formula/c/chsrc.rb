class Chsrc < Formula
  desc "Change Source for every software on every platform from the command-line"
  homepage "https://github.com/RubyMetric/chsrc"
  url "https://github.com/RubyMetric/chsrc/archive/refs/tags/v0.2.7.tar.gz"
  sha256 "0c1ff6ec9e8860d6c0455bc2f0e228647e578fbbe1874141850ec253a9693f10"
  license "GPL-3.0-or-later"
  revision 1

  # Add HarmonyOS/OpenHarmony OS detection to XY library.
  # XY library's _xy_detect_os doesn't recognize HarmonyOS, causing SIGABRT.
  patch do
    file "Patches/chsrc/0001-add-ohos-os-detection.patch"
  end

  head "https://github.com/RubyMetric/chsrc.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2d9ab4a0bd09578536cfc4c46730730433571216e7534e99e6d8e502957b9904"
  end

  def install
    system "make"
    bin.install "chsrc"
  end

  test do
    assert_match(/mirrorz\s*MirrorZ.*MirrorZ/, shell_output("#{bin}/chsrc list"))
    assert_match version.to_s, shell_output("#{bin}/chsrc --version")
  end
end
