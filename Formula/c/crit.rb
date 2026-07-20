class Crit < Formula
  desc "Your feedback loop with the agent: review plans and code locally"
  homepage "https://crit.md/"
  url "https://github.com/tomasz-tomczyk/crit/archive/refs/tags/v0.18.1.tar.gz"
  sha256 "243a17b5493532baa110ed78ac705a3746044b0fd90fab2943d7be5affdcbd16"
  license "MIT"
  head "https://github.com/tomasz-tomczyk/crit.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fb0d8011c725ad7b815a900ec25207bb854fbbd9581f35417a4cf31a25cd49fa"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.version=#{version}
      -X main.commit=brew
      -X main.date=#{time.iso8601[0, 10]}
    ]
    system "go", "build", *std_go_args(ldflags:), "./cmd/crit"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/crit --version")

    (testpath/"hello.md").write("# Hello\n")
    ENV["HOME"] = testpath
    system bin/"crit", "comment", "-o", testpath, "hello.md:1", "looks good"

    review = (testpath/".crit/review.json").read
    assert_match "looks good", review
    assert_match "hello.md", review
  end
end
