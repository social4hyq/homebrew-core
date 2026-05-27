class Mp3gain < Formula
  desc "Lossless mp3 normalizer with statistical analysis"
  homepage "https://mp3gain.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/mp3gain/mp3gain/1.6.2/mp3gain-1_6_2-src.zip"
  version "1.6.2"
  sha256 "5cc04732ef32850d5878b28fbd8b85798d979a025990654aceeaa379bcc9596d"
  license "LGPL-2.1-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4a84079a4955efd44cc39368541a7e7ad90baf1b86f312356ef94c6a6fac06f7"
  end

  depends_on "mpg123"

  def install
    system "make"
    bin.install "mp3gain"
  end

  test do
    system bin/"mp3gain", "-v"
  end
end
