class Awsweeper < Formula
  desc "CLI tool for cleaning your AWS account"
  homepage "https://github.com/jckuester/awsweeper/"
  url "https://github.com/jckuester/awsweeper/archive/refs/tags/v0.12.0.tar.gz"
  sha256 "43468e1af20dab757da449b07330f7b16cbb9f77e130782f88f30a7744385c5e"
  license "MPL-2.0"
  head "https://github.com/jckuester/awsweeper.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dadaf35a42be1b08c60650554ba215ec3b72a704aa120a2dd98a9ca0cd27b115"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/jckuester/awsweeper/internal.version=#{version}
      -X github.com/jckuester/awsweeper/internal.date=#{time.strftime("%F")}
    ]

    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    (testpath/"filter.yml").write <<~YAML
      aws_autoscaling_group:
      aws_instance:
        - tags:
            Name: foo
    YAML

    assert_match "Error: failed to configure provider (name=aws",
      shell_output("#{bin}/awsweeper --dry-run #{testpath}/filter.yml 2>&1", 1)
  end
end
