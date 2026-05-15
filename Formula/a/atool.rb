class Atool < Formula
  desc "Archival front-end"
  homepage "https://savannah.nongnu.org/projects/atool/"
  url "https://download.savannah.gnu.org/releases/atool/atool-0.39.0.tar.gz"
  sha256 "aaf60095884abb872e25f8e919a8a63d0dabaeca46faeba87d12812d6efc703b"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://download.savannah.gnu.org/releases/atool/"
    regex(/href=.*?atool[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "93d06032e49aefcdfffc16fab27160aaf69b194940b0debb09e7d57b87586ec8"
  end

  def install
    # Build an `:all` bottle.
    files = %w[ChangeLog README]
    files.each { |file| rm buildpath/file }

    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    touch "example.txt"
    touch "example2.txt"
    system bin/"apack", "test.tar.gz", "example.txt", "example2.txt"

    output = shell_output("#{bin}/als test.tar.gz")
    assert_match "example.txt", output
    assert_match "example2.txt", output
  end
end
