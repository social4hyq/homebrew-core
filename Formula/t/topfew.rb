class Topfew < Formula
  desc "Finds the field values which appear most often in a stream of records"
  homepage "https://github.com/timbray/topfew"
  url "https://github.com/timbray/topfew/archive/refs/tags/v2.0.0.tar.gz"
  sha256 "89b9abe7304eb6bb50cc5b3152783e50600439955f73b6175c6db8aec75c0ac9"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "432303bfce136d97af2d8cd0c044061ed5e12bdca5357d145c522cc1b77bf5e8"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match "1 bar", pipe_output("#{bin}/topfew -f 2", "foo bar\n")
  end
end
