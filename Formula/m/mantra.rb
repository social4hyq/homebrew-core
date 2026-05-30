class Mantra < Formula
  desc "Tool to hunt down API key leaks in JS files and pages"
  homepage "https://github.com/brosck/mantra"
  url "https://github.com/brosck/mantra/archive/refs/tags/v3.1.tar.gz"
  sha256 "379894f36ef04a6b4e57e77112070e23dcc75569d1df98a8f128fe24a8b5e0b1"
  license "GPL-3.0-only"
  head "https://github.com/brosck/mantra.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3322118e7275ace0cc6c817e143c7f67a9772c423a81848bd1fb0cd862a8f6d0"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    output = pipe_output(bin/"mantra", "https://brew.sh")
    assert_match "\"indexName\":\"brew_all\"", output
  end
end
