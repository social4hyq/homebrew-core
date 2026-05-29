class Blahtexml < Formula
  desc "Converts equations into Math ML"
  homepage "https://github.com/gvanas/blahtexml"
  url "https://github.com/gvanas/blahtexml/archive/refs/tags/v1.0.tar.gz"
  sha256 "ef746642b1371f591b222ce3461c08656734c32ad3637fd0574d91e83995849e"
  license "BSD-3-Clause"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "aea19ae7851f34ed9ec3bdc20495de045d6a7b1be797c1f2faf2f4f847168e5d"
  end

  depends_on "xerces-c"

  def install
    ENV.cxx11
    if OS.mac?
      system "make", "blahtex-mac"
      system "make", "blahtexml-mac"
    else
      system "make", "blahtex-linux"
      system "make", "blahtexml-linux"
    end
    bin.install "blahtex"
    bin.install "blahtexml"
  end

  test do
    input = '\sqrt{x^2+\alpha}'
    output = pipe_output("#{bin}/blahtex --mathml", input, 0)
    assert_match "<msqrt><msup><mi>x</mi><mn>2</mn></msup><mo ", output
  end
end
