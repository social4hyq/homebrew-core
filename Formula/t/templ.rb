class Templ < Formula
  desc "Language for writing HTML user interfaces in Go"
  homepage "https://templ.guide"
  url "https://github.com/a-h/templ/archive/refs/tags/v0.3.1020.tar.gz"
  sha256 "4f21ea4f1b60d65e506fa146a33a9d83d055c6f1e2e7687421f08ada6614d83c"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9751b3f35d6073ed5ab6d39acb01264f24ae52dde39afcea214b03c9bf171e7c"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/templ"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/templ version")

    (testpath/"test.templ").write <<~TEMPL
      package main

      templ Test() {
        <p class="testing">Hello, World</p>
      }
    TEMPL

    output = shell_output("#{bin}/templ generate -stdout -f #{testpath}/test.templ")
    assert_match "func Test() templ.Component {", output
  end
end
