class Nq < Formula
  desc "Unix command-line queue utility"
  homepage "https://github.com/leahneukirchen/nq"
  url "https://github.com/leahneukirchen/nq/archive/refs/tags/v1.0.tar.gz"
  sha256 "d5b79a488a88f4e4d04184efa0bc116929baf9b34617af70d8debfb37f7431f4"
  license "CC0-1.0"
  head "https://github.com/leahneukirchen/nq.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2426143b80c2e505534cf39d1b3204f37f7e47b974b539779a54d135d60a6358"
  end

  def install
    system "make", "all", "PREFIX=#{prefix}"
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    system bin/"nq", "touch", "TEST"
    assert_match "exited with status 0", shell_output("#{bin}/nqtail -a 2>&1")
    assert_path_exists testpath/"TEST"
  end
end
