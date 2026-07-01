class Sift < Formula
  desc "Fast and powerful open source alternative to grep"
  homepage "https://sift-tool.org/"
  url "https://github.com/svent/sift/archive/refs/tags/v0.9.2.tar.gz"
  sha256 "d6d8274e475f3f1235eb0118a89f981e0f7741b9f27243d679d3ecd76f68fe03"
  license "GPL-3.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6afe0dbb6d4c128b044e0d1cd08facc68b12a7c75f6055fb645a9d32bfb31679"
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
