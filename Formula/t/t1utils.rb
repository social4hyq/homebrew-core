class T1utils < Formula
  desc "Command-line tools for dealing with Type 1 fonts"
  homepage "https://www.lcdf.org/type/"
  url "https://www.lcdf.org/type/t1utils-1.42.tar.gz"
  sha256 "61877935b1987044ddff4bb90a05200ca7164678a355e170bf5f1a5556cc9f29"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "882555ae68df1d3fe2c6e9652221da932ade6c848f3b57ad77dd385852e6c13e"
  end

  head do
    url "https://github.com/kohler/t1utils.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  def install
    system "./bootstrap.sh" if build.head?
    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system bin/"t1mac", "--version"
  end
end
