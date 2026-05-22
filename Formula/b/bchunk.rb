class Bchunk < Formula
  desc "Convert CD images from .bin/.cue to .iso/.cdr"
  homepage "http://he.fi/bchunk/"
  url "https://github.com/hessu/bchunk/archive/refs/tags/release/1.2.2.tar.gz"
  sha256 "48dd464d8547f368e6e3434e3e2d53e7b1a7748b4ecc2c8a423d614b0b1f7fc4"
  license "GPL-2.0-or-later"
  head "https://github.com/hessu/bchunk.git", branch: "master"

  livecheck do
    url :homepage
    regex(/href=.*?bchunk[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a02047e07e9d211aeba899301bcf9e240c719b324fa1f23bd24861a38c88eea0"
  end

  def install
    system "make"
    bin.install "bchunk"
    man1.install "bchunk.1"
  end

  test do
    (testpath/"foo.cue").write <<~EOS
      foo.bin BINARY
      TRACK 01 MODE1/2352
      INDEX 01 00:00:00
    EOS

    touch testpath/"foo.bin"

    system bin/"bchunk", "foo.bin", "foo.cue", "foo"
    assert_path_exists testpath/"foo01.iso"
  end
end
