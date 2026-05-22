class Pwgen < Formula
  desc "Password generator"
  homepage "https://pwgen.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/pwgen/pwgen/2.08/pwgen-2.08.tar.gz"
  sha256 "dab03dd30ad5a58e578c5581241a6e87e184a18eb2c3b2e0fffa8a9cf105c97b"
  license "GPL-2.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "aa4ba983e15fc1e9e313a416f0dc77229603ad6f7244e6f78a98b7eb31bf2633"
  end

  def install
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--mandir=#{man}"
    system "make", "install"
  end

  test do
    system bin/"pwgen", "--secure", "20", "10"
  end
end
