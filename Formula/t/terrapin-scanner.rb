class TerrapinScanner < Formula
  desc "Vulnerability scanner for the Terrapin attack"
  homepage "https://terrapin-attack.com/"
  url "https://github.com/RUB-NDS/Terrapin-Scanner/archive/refs/tags/v1.1.3.tar.gz"
  sha256 "3dde1f19e9228a2a284d73c63b193fdf775cb993945fb328cd01e3a6cc834bf1"
  license "Apache-2.0"
  head "https://github.com/RUB-NDS/Terrapin-Scanner.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e9be550922b9c0eb6c50b21c4c4a2479e8852c0bc051a83fa97fe243096da57e"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/"Terrapin-Scanner")
  end

  test do
    output = shell_output("#{bin}/Terrapin-Scanner --connect localhost:2222 2>&1", 2)
    assert_match "connect: connection refused", output

    assert_match version.to_s, shell_output("#{bin}/Terrapin-Scanner --version")
  end
end
