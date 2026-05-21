class Gitslave < Formula
  desc "Create group of related repos with one as superproject"
  homepage "https://gitslave.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/gitslave/gitslave-2.0.2.tar.gz"
  sha256 "8aa3dcb1b50418cc9cee9bee86bb4b279c1c5a34b7adc846697205057d4826f0"
  license "LGPL-2.1-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "745e1b23682f4fece850093561431c04340332b3225f7ee4fd0503965d771ab4"
  end

  uses_from_macos "perl"

  def install
    system "make", "install", "prefix=#{prefix}"
  end

  test do
    output = shell_output("#{bin}/gits --version")
    assert_match "gits version #{version}", output
  end
end
