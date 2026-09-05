class Dnsx < Formula
  desc "DNS query and resolution tool"
  homepage "https://github.com/projectdiscovery/dnsx"
  url "https://github.com/projectdiscovery/dnsx/archive/refs/tags/v1.3.1.tar.gz"
  sha256 "2c14a27b00e3215e1c0dc07afe9e5e5c3f0a3502852f1d5f497a92b5e6cb63db"
  license "MIT"
  head "https://github.com/projectdiscovery/dnsx.git", branch: "dev"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a1b48f0e8366d670156d5152e4e8f2c365a1836f95737132e7ce6e72e126ac6f"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/dnsx"
  end

  test do
    (testpath/"domains.txt").write "docs.brew.sh"
    expected_output = "docs.brew.sh [CNAME] [homebrew.github.io]"
    assert_equal expected_output,
      shell_output("#{bin}/dnsx -no-color -silent -l #{testpath}/domains.txt -cname -resp").strip
  end
end
