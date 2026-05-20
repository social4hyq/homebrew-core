class Dupseek < Formula
  desc "Interactive program to find and remove duplicate files"
  homepage "http://www.beautylabs.net/software/dupseek.html"
  url "http://www.beautylabs.net/software/dupseek-1.3.tgz"
  sha256 "c046118160e4757c2f8377af17df2202d6b9f2001416bfaeb9cd29a19f075d93"
  license "GPL-2.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1fe5577bb2552ddad6d14ea00e8584e6e332b047db02fe027dd630536ac36a0b"
  end

  deprecate! date: "2026-01-05", because: "is not available via HTTPS"

  def install
    bin.install "dupseek"
    doc.install %w[changelog.txt doc.txt copyright credits.txt]
  end

  test do
    mkdir "folder"
    touch "folder/file1"
    assert_empty shell_output("#{bin}/dupseek -b report -f de folder").chomp
    touch "folder/file2"
    assert_match %r{^folder\\/file[12]$}, shell_output("#{bin}/dupseek -b report -f de folder").chomp
    assert_equal "folder\\/file1\nfolder\\/file2", shell_output("#{bin}/dupseek -b report -f e folder | sort").chomp
  end
end
