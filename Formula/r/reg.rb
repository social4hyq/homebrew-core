class Reg < Formula
  desc "Docker registry v2 command-line client"
  # original homepage is down `https://r.j3ss.co`
  homepage "https://github.com/genuinetools/reg"
  url "https://github.com/genuinetools/reg/archive/refs/tags/v0.16.1.tar.gz"
  sha256 "b65787bff71bff21f21adc933799e70aa9b868d19b1e64f8fd24ebdc19058430"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fd451e73dd50a6e027344788e4fab1d96f7815e9db3331ff87133d124c87c500"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args
  end

  test do
    assert_match "buster", shell_output("#{bin}/reg tags debian")
  end
end
