class Cloudquery < Formula
  desc "Data movement tool to sync data from any source to any destination"
  homepage "https://www.cloudquery.io"
  url "https://github.com/cloudquery/cloudquery/archive/refs/tags/cli-v6.42.2.tar.gz"
  sha256 "26fa091509597cb51b1feed91540962f17df9cc13aa2d41e2f2f4a9042e7c8ea"
  license "MPL-2.0"
  head "https://github.com/cloudquery/cloudquery.git", branch: "main"

  livecheck do
    url :stable
    regex(/^cli-v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bbf9f647a3af950aceb3afbd8124fa414ea0ed3f7b52e2ab61fa8d3795b51e8c"
  end

  depends_on "go" => :build

  def install
    cd "cli" do
      ldflags = "-s -w -X github.com/cloudquery/cloudquery/cli/v6/cmd.Version=#{version}"
      system "go", "build", *std_go_args(ldflags:)
    end
    generate_completions_from_executable(bin/"cloudquery", shell_parameter_format: :cobra)
  end

  test do
    system bin/"cloudquery", "init", "--source", "aws", "--destination", "bigquery"

    assert_path_exists testpath/"cloudquery.log"
    assert_match <<~YAML, (testpath/"aws_to_bigquery.yaml").read
      kind: source
      spec:
        # Source spec section
        name: aws
        path: cloudquery/aws
    YAML

    assert_match version.to_s, shell_output("#{bin}/cloudquery --version")
  end
end
