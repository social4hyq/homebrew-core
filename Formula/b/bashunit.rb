class Bashunit < Formula
  desc "Simple testing library for bash scripts"
  homepage "https://bashunit.typeddevs.com"
  url "https://github.com/TypedDevs/bashunit/releases/download/0.38.0/bashunit"
  sha256 "b1364d4874e61bc8cee4d9dea15844badebdbcc855d4d5b5439c9f4ae8b2204c"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "95de057510cd20a6f70a4f054c5081e4e552e885d4bd0cb690cec8101cca2e49"
  end

  def install
    bin.install "bashunit"
  end

  test do
    (testpath/"test.sh").write <<~SHELL
      function test_addition() {
        local result
        result="$((2 + 2))"

        assert_equals "4" "$result"
      }
    SHELL
    assert "addition", shell_output("#{bin}/bashunit test.sh")

    assert_match version.to_s, shell_output("#{bin}/bashunit --version")
  end
end
