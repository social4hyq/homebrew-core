class Gpcslots2 < Formula
  desc "Casino text-console game"
  homepage "https://sourceforge.net/projects/gpcslots2/"
  url "https://downloads.sourceforge.net/project/gpcslots2/gpcslots2_0-4-5b"
  version "0.4.5b"
  sha256 "4daf5b6e5a23fe6cd121fe1250f10ad9f3b936bd536d475ec585f57998736f55"
  license "GPL-2.0-or-later"

  livecheck do
    url :stable
    regex(%r{url=.*?/gpcslots2[._-]v?(\d+(?:[._-]\d+)+[a-z]?)}i)
  end

  no_autobump! because: :incompatible_version_format

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6bbbbb66b3927b43506d11bbbb223aed2020f47395871335b3d029e1837a8d3a"
  end

  def install
    bin.install "gpcslots2_0-4-5b" => "gpcslots2"
  end

  test do
    system bin/"gpcslots2", "-h"
  end
end
