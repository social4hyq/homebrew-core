class Tfsort < Formula
  desc "CLI to sort Terraform variables and outputs"
  homepage "https://github.com/AlexNabokikh/tfsort"
  url "https://github.com/AlexNabokikh/tfsort/archive/refs/tags/v0.7.1.tar.gz"
  sha256 "6f72bb06b57573ee63fec715cd4493ed90d0af0dfeea7478abfde04745d39157"
  license "Apache-2.0"
  head "https://github.com/AlexNabokikh/tfsort.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dd16f8c051c651db73f1585bc174f00d2dc59cb7c79e91591acaaa731c88a2f6"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version} -X main.commit=#{tap.user} -X main.date=#{time.iso8601}"
    system "go", "build", *std_go_args(ldflags:)

    # install testdata
    pkgshare.install "internal/hclsort/testdata"
  end

  test do
    cp_r pkgshare/"testdata/.", testpath

    assert_empty shell_output("#{bin}/tfsort invalid.tf 2>&1")

    system bin/"tfsort", "valid.tofu"
    assert_equal (testpath/"expected.tofu").read, (testpath/"valid.tofu").read
  end
end
