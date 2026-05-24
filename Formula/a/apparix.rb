class Apparix < Formula
  desc "File system navigation via bookmarking directories"
  homepage "https://micans.org/apparix/"
  url "https://micans.org/apparix/src/apparix-11-062.tar.gz"
  sha256 "211bb5f67b32ba7c3e044a13e4e79eb998ca017538e9f4b06bc92d5953615235"
  license "GPL-3.0-or-later"

  livecheck do
    skip "No version information available"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c97e7865be6569e0aa58d362c1f5cd51db176a56af1407825468afef27dd0515"
  end

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    mkdir "test"
    system bin/"apparix", "--add-mark", "homebrew", "test"
    assert_equal "j,homebrew,test",
      shell_output("#{bin}/apparix -lm homebrew").chomp
  end
end
