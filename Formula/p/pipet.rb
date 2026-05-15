class Pipet < Formula
  desc "Swiss-army tool for web scraping, made for hackers"
  homepage "https://github.com/bjesus/pipet"
  url "https://github.com/bjesus/pipet/archive/refs/tags/0.3.0.tar.gz"
  sha256 "9fb35bcc4be8b7655a4075c3b2bf7b0368ae7bb97e9e6dbbcf00422c8e18cc6b"
  license "MIT"
  head "https://github.com/bjesus/pipet.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1729e30236deacc82c9d3af1fbc37b35ce7f469c4dab4101080f20a3251423e7"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/pipet"
  end

  test do
    (testpath/"example.pipet").write <<~EOS
      curl https://example.com
      head > title
    EOS

    assert_match "Example Domain", shell_output("#{bin}/pipet example.pipet")
  end
end
