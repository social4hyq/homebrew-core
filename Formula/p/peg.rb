class Peg < Formula
  desc "Program to perform pattern matching on text"
  homepage "https://www.piumarta.com/software/peg/"
  url "https://www.piumarta.com/software/peg/peg-0.1.19.tar.gz"
  mirror "https://deb.debian.org/debian/pool/main/p/peg/peg_0.1.19.orig.tar.gz"
  sha256 "0013dd83a6739778445a64bced3d74b9f50c07553f86ea43333ae5fab5c2bbb4"
  license "MIT"

  # The homepage links to development tarballs using the stable version format
  # (with nothing in the file name to distinguish stable/development), so we
  # check the "current stable version is 1.2.3" text.
  livecheck do
    url :homepage
    regex(/current\s+stable\s+version\s+is\s+v?(\d+(?:\.\d+)+)/im)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c122ad366969f7da635c8dc8b37cfc3d54ae1a5c1d1cddd7baffe9b68c1ab0f2"
  end

  def install
    system "make", "all"
    bin.install %w[peg leg]
    man1.install Utils::Gzip.compress("src/peg.1")
  end

  test do
    (testpath/"username.peg").write <<~EOS
      start <- "username"
    EOS

    system bin/"peg", "-o", "username.c", "username.peg"

    assert_match 'yymatchString(yy, "username")', File.read("username.c")
  end
end
