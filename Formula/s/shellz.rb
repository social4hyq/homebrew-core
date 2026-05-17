class Shellz < Formula
  desc "Small utility to track and control custom shellz"
  homepage "https://github.com/evilsocket/shellz"
  url "https://github.com/evilsocket/shellz/archive/refs/tags/v1.6.0.tar.gz"
  sha256 "3a89e3d573563a0c2ccb1831ff41fc0204c8b4efb011c10108ab98451a309b1c"
  license "GPL-3.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "724f49d628f0ff6ed2bcc90e450f8527fd9d4b5b25d2dd478a80bd9281bbfe37"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/shellz"
  end

  test do
    output = shell_output("#{bin}/shellz -no-banner -no-effects -path #{testpath}", 1)
    assert_match "creating", output
    assert_path_exists testpath/"shells"
  end
end
