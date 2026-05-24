class Cf < Formula
  desc "Filter to replace numeric timestamps with a formatted date time"
  homepage "https://ee.lbl.gov/"
  url "https://ee.lbl.gov/downloads/cf/cf-1.2.8.tar.gz"
  sha256 "52ce4302f7f9dd67227e5a3d09fc289127bf0ad256d24d8e1698733ea2e1fd48"
  license "BSD-3-Clause"

  livecheck do
    url "https://ee.lbl.gov/downloads/cf/"
    regex(/href=.*?cf[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0d604dbad7517896b975e7f8142433f42aa3c64a1e05092bc544994ea6a6fd39"
  end

  conflicts_with "cloudfoundry-cli", because: "both install `cf` binaries"

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make"
    bin.mkpath
    man1.mkpath
    system "make", "install"
    system "make", "install-man"
  end

  test do
    assert_match "Jan 20 00:35:44", pipe_output("#{bin}/cf -u", "1074558944")
  end
end
