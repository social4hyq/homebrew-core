class SsllabsScan < Formula
  desc "This tool is a command-line client for the SSL Labs APIs"
  homepage "https://www.ssllabs.com/projects/ssllabs-apis/"
  url "https://github.com/ssllabs/ssllabs-scan/archive/refs/tags/v1.5.0.tar.gz"
  sha256 "51c52e958d5da739910e9271a3abf4902892b91acb840ea74f5c052a71e3a008"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dced4f95b12c3df425970fbbe57b1eb5eb29900528607e8ab62185822b3ea7b0"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "ssllabs-scan-v3.go"
  end

  def caveats
    <<~EOS
      By installing this package you agree to the Terms and Conditions defined by Qualys.
      You can find the terms and conditions at this link:
         https://www.ssllabs.com/about/terms.html

      If you do not agree with those you should uninstall the formula.
    EOS
  end

  test do
    system bin/"ssllabs-scan", "-grade", "-quiet", "-usecache", "ssllabs.com"
  end
end
