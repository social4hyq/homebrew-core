class TerraformGraphBeautifier < Formula
  desc "CLI to beautify `terraform graph` output"
  homepage "https://github.com/pcasteran/terraform-graph-beautifier"
  url "https://github.com/pcasteran/terraform-graph-beautifier/archive/refs/tags/v0.3.4.tar.gz"
  sha256 "36762a21cfdf34b2082b8921d4352c3160d759a7a3743225f1a084f9b3dffe4a"
  license "Apache-2.0"
  head "https://github.com/pcasteran/terraform-graph-beautifier.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "65aaeafb9ab4283145282eab0ddd56584adbf38cdb928caa64054f818e41d0f8"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}")
    pkgshare.install "test"
  end

  test do
    test_file = (pkgshare/"test/config1_expected.gv").read
    output = pipe_output("#{bin}/terraform-graph-beautifier --graph-name=test --output-type=graphviz", test_file)
    assert_equal test_file, output

    assert_match version.to_s, shell_output("#{bin}/terraform-graph-beautifier -v")
  end
end
