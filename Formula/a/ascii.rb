class Ascii < Formula
  desc "List ASCII idiomatic names and octal/decimal code-point forms"
  homepage "http://www.catb.org/~esr/ascii/"
  url "https://gitlab.com/esr/ascii/-/archive/3.32/ascii-3.32.tar.bz2"
  sha256 "cde70847d7e91b14cd855addceb1c7a07470a192cb7d178168fa421c1c21c826"
  license "BSD-2-Clause"
  head "https://gitlab.com/esr/ascii.git", branch: "master"

  # The homepage links to the `stable` tarball but it can take longer than the
  # ten second livecheck timeout, so we check the Git tags as a workaround.
  livecheck do
    url :head
    regex(/^v?(\d+(?:[.-]\d+)+)$/i)
    strategy :git do |tags, regex|
      tags.filter_map { |tag| tag[regex, 1]&.tr("-", ".") }
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "af72c9265757aa7d85e3b5b8349e6b27fcb5261bc4a9d0013d2852efb79d3a78"
  end

  depends_on "asciidoctor" => :build

  def install
    bin.mkpath
    man1.mkpath
    system "make"
    system "make", "PREFIX=#{prefix}", "install"
  end

  test do
    assert_match "Official name: Line Feed", shell_output("#{bin}/ascii 0x0a")
  end
end
