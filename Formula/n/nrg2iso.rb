class Nrg2iso < Formula
  desc "Extract ISO9660 data from Nero nrg files"
  homepage "http://gregory.kokanosky.free.fr/v4/linux/nrg2iso.en.html"
  url "https://distfiles.macports.org/nrg2iso/nrg2iso-0.4.1.tar.gz"
  mirror "http://gregory.kokanosky.free.fr/v4/linux/nrg2iso-0.4.1.tar.gz"
  sha256 "3be36a416758fc1910473b49a8dadf2a2aa3d51f1976197336bc174bc1e306e5"
  license "GPL-3.0-or-later"

  # The latest version reported on the English page (nrg2iso.en.html) and the
  # main French page (nrg2iso.html) can differ, so we may want to keep an eye
  # on this to make sure we don't miss any versions.
  livecheck do
    url :homepage
    regex(/href=.*?nrg2iso[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7e61a1865d08ee7f880e43bf205acbd249ebf1e7952c1c41d6b60f53a9a5b35a"
  end

  def install
    # fix version output issue
    inreplace "nrg2iso.c", "VERSION \"0.4\"", "VERSION \"#{version}\""

    system "make"
    bin.install "nrg2iso"
  end

  test do
    assert_equal "nrg2iso v#{version}",
      shell_output("#{bin}/nrg2iso --version").chomp
  end
end
