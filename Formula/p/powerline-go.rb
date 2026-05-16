class PowerlineGo < Formula
  desc "Beautiful and useful low-latency prompt for your shell"
  homepage "https://github.com/justjanne/powerline-go"
  url "https://github.com/justjanne/powerline-go/archive/refs/tags/v1.26.tar.gz"
  sha256 "65aa911d50f3695b37da92a53ed417b6cf263a9e4091552b77921a6057dbb320"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "08b1fc26cc1de61ef982f983962bed0e5fa8f29127366ec0967de9f1dd2c6cee"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    system bin/"powerline-go"
  end
end
