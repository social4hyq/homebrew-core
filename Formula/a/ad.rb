class Ad < Formula
  desc "Adaptable text editor inspired by vi, kakoune, and acme"
  homepage "https://github.com/sminez/ad"
  url "https://github.com/sminez/ad/archive/refs/tags/0.4.0.tar.gz"
  sha256 "e35cf1030bc24bf336066fcd367e8a022d097357b896cb316183993951d4ffb8"
  license "MIT"
  head "https://github.com/sminez/ad.git", branch: "develop"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "52a710a3645988ddfecc8d4746f9a85367e50a3e683da7e9e33c64873a79a3eb"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man.install buildpath/"docs/man/ad.1"
  end

  test do
    # ad is a gui application
    assert_match "ad v#{version}", shell_output("#{bin}/ad --version").strip

    # test scripts
    (testpath/"test.txt").write <<~TXT
      Hello, World!
      Goodbye, World!
      hello, John!
      Hi, Alex!
    TXT

    (testpath/"hello.ad").write <<~AD
      ,
      x/[Hh]ello, (.*)!/
      p/{1}\\n/
    AD

    assert_match "World\nJohn\n", shell_output("#{bin}/ad -f #{testpath}/hello.ad #{testpath}/test.txt")
  end
end
