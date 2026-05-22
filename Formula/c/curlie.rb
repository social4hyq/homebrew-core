class Curlie < Formula
  desc "Power of curl, ease of use of httpie"
  homepage "https://rs.github.io/curlie/"
  url "https://github.com/rs/curlie/archive/refs/tags/v1.8.2.tar.gz"
  sha256 "846ca3c5f2cca60c15eaef24949cf49607f09bdd68cbe9d81a2a026e434fa715"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8560d083a489db0d3806e66f16758cea9b679d4b83f2e2f89720fe5ac5b20e11"
  end

  depends_on "go" => :build

  uses_from_macos "curl"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match "httpbin.org",
      shell_output("#{bin}/curlie -X GET httpbin.org/headers 2>&1")
  end
end
