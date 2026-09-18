class Uni < Formula
  desc "Unicode database query tool for the command-line"
  homepage "https://github.com/arp242/uni"
  url "https://github.com/arp242/uni/archive/refs/tags/v2.10.0.tar.gz"
  sha256 "e9208bc0028d239f9cfbb701d98b14e93eddd138ac6433c6f2f5718244ffa5bf"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cb74812c1e268acb12ca997f53aa4035da57212bb49510d78dc9081008710ab6"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match "CLINKING BEER MUGS", shell_output("#{bin}/uni identify 🍻")
  end
end
