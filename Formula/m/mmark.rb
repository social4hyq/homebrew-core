class Mmark < Formula
  desc "Powerful markdown processor in Go geared towards the IETF"
  homepage "https://mmark.miek.nl/"
  url "https://github.com/mmarkdown/mmark/archive/refs/tags/v2.2.48.tar.gz"
  sha256 "8ab1295db3a9c1cdd353d4fc0f29daf1e6085b6e1989e30cd0348d0e17760bc1"
  license "BSD-2-Clause"
  head "https://github.com/mmarkdown/mmark.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5630dfaa5a79aff7c04cc2fae1fe73803f5cb98adcace571dea747f7edd41b0b"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
    man1.install "mmark.1"
  end

  test do
    resource "homebrew-test" do
      url "https://raw.githubusercontent.com/mmarkdown/mmark/v2.2.19/rfc/2100.md"
      sha256 "0e12576b4506addc5aa9589b459bcc02ed92b936ff58f87129385d661b400c41"
    end

    resource("homebrew-test").stage do
      assert_match "The Naming of Hosts", shell_output("#{bin}/mmark -ast 2100.md")
    end
  end
end
