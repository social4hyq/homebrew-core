class Sift < Formula
  desc "Fast and powerful open source alternative to grep"
  homepage "https://sift-tool.org/"
  url "https://github.com/svent/sift/archive/refs/tags/v0.9.1.tar.gz"
  sha256 "8830db8aa7d34445eee66a5817127919040531c5ade186b909655ef274c3e4ce"
  license "GPL-3.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "82433373ecb87155aa81bca848ff36ca4c36240a1b12e48ee527b058c67b5f46"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.buildVersion=#{version}"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    (testpath/"test.txt").write("where is foo\n")
    assert_match "where is foo", shell_output("#{bin}/sift foo #{testpath}")
  end
end
