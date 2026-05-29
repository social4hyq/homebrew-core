class Bomber < Formula
  desc "Scans Software Bill of Materials for security vulnerabilities"
  homepage "https://github.com/devops-kung-fu/bomber"
  url "https://github.com/devops-kung-fu/bomber/archive/refs/tags/v0.5.1.tar.gz"
  sha256 "f4d8165ea9d3be0e88fdb33d35870588df308f31a4c40f14f09f0b68570f6ae1"
  license "MPL-2.0"
  head "https://github.com/devops-kung-fu/bomber.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "90f6053d64fc423e9d799d0dcbf012a7d0cbea2abe880a05d5ce1879e5a35139"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")

    generate_completions_from_executable(bin/"bomber", shell_parameter_format: :cobra)

    pkgshare.install "_TESTDATA_"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/bomber --version")

    cp pkgshare/"_TESTDATA_/sbom/bomber.spdx.json", testpath
    output = shell_output("#{bin}/bomber scan bomber.spdx.json")
    assert_match "Total vulnerabilities found:", output
  end
end
