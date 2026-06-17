class Lhasa < Formula
  desc "LHA implementation to decompress .lzh and .lzs archives"
  homepage "https://fragglet.github.io/lhasa/"
  url "https://github.com/fragglet/lhasa/archive/refs/tags/v0.6.0.tar.gz"
  sha256 "427c47527f11d157380d90e33c86535a3a0e8eb5c7e2cf0278bd6dbfe733fcee"
  license "ISC"
  head "https://github.com/fragglet/lhasa.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "940b19064b86f4e93afe94c3a5b4998b752be635b8f76e7e76424287fb56d10b"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build

  def install
    system "./autogen.sh", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    data = [
      %w[
        31002d6c68302d0400000004000000f59413532002836255050000865a060001666f6f0
        50050a4810700511400f5010000666f6f0a00
      ].join,
    ].pack("H*")

    pipe_output("#{bin}/lha x -", data)
    assert_equal "foo\n", (testpath/"foo").read
  end
end
