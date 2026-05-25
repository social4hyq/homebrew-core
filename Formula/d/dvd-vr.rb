class DvdVr < Formula
  desc "Utility to identify and extract recordings from DVD-VR files"
  homepage "https://www.pixelbeat.org/programs/dvd-vr/"
  url "https://www.pixelbeat.org/programs/dvd-vr/dvd-vr-0.9.7.tar.gz"
  sha256 "19d085669aa59409e8862571c29e5635b6b6d3badf8a05886a3e0336546c938f"
  license "GPL-2.0-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?dvd-vr[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4c17d03aec9942cb34cf980ba872dcc35477e5d5ff9f2d15b2acddc4e17f5f74"
  end

  def install
    system "make", "PREFIX=#{prefix}", "install"
  end

  test do
    system bin/"dvd-vr", "--version"
  end
end
