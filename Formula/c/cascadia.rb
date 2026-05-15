class Cascadia < Formula
  desc "Go cascadia package command-line CSS selector"
  homepage "https://github.com/suntong/cascadia"
  url "https://github.com/suntong/cascadia/archive/refs/tags/v1.5.0.tar.gz"
  sha256 "674d32db061fdab3329cda23263f0ff2a8551b64d49b4829cff54912bd8befd1"
  license "MIT"
  head "https://github.com/suntong/cascadia.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "11055c42afa140222a9ae7c5a4f0ab562fb365102e00efd9fabee6cc39154e05"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match "Version #{version}", shell_output("#{bin}/cascadia --help")

    test_html = "<foo><bar>aaa</bar><baz>bbb</baz></foo>"
    test_css_selector = "foo > bar"
    expected_html_output = "<bar>aaa</bar>"
    assert_equal expected_html_output,
      pipe_output("#{bin}/cascadia --in --out --css '#{test_css_selector}'", test_html).strip
  end
end
