class Favirecon < Formula
  desc "Uses favicon.ico to improve the target recon phase"
  homepage "https://github.com/edoardottt/favirecon"
  url "https://github.com/edoardottt/favirecon/archive/refs/tags/v1.0.4.tar.gz"
  sha256 "61ce4ceea1a11e1e39ec67dadafb4cf9b9749d18385a76774298e5441eca4391"
  license "MIT"
  head "https://github.com/edoardottt/favirecon.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "43cacfcf5c9b4c708a1668ff98eb037b67d47cde6b2a45068fc705dbb143f845"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/favirecon"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/favirecon --help")

    output = shell_output("#{bin}/favirecon -u https://www.github.com -verbose 2>&1")
    assert_match "Checking favicon for https://www.github.com/favicon.ico", output
  end
end
