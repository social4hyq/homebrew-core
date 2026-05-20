class Uni < Formula
  desc "Unicode database query tool for the command-line"
  homepage "https://github.com/arp242/uni"
  url "https://github.com/arp242/uni/archive/refs/tags/v2.9.0.tar.gz"
  sha256 "dc595807a0ab875111dafd55be9f3de116cbea652216f9d0082d03dddb3d83be"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cfc29899c59deaf19ff439fb4f1f8187e84ea7ce3e0a955cd928bf30315865e8"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match "CLINKING BEER MUGS", shell_output("#{bin}/uni identify 🍻")
  end
end
