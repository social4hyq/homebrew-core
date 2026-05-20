class Ccat < Formula
  desc "Like cat but displays content with syntax highlighting"
  homepage "https://github.com/owenthereal/ccat"
  url "https://github.com/owenthereal/ccat/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "b02d2c8d573f5d73595657c7854c9019d3bd2d9e6361b66ce811937ffd2bfbe1"
  license "MIT"
  head "https://github.com/owenthereal/ccat.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "112aa78df30b720cb58cc33b15952daac90ec42afc6981f754fa3bfabb01b820"
  end

  depends_on "go" => :build

  conflicts_with "ccrypt", because: "both install `ccat` binaries"

  def install
    ENV["GOPATH"] = buildpath
    ENV["GO111MODULE"] = "auto"
    system "./script/build"
    bin.install "ccat"
  end

  test do
    (testpath/"test.txt").write <<~EOS
      I am a colourful cat
    EOS

    assert_match(/I am a colourful cat/, shell_output("#{bin}/ccat test.txt"))
  end
end
