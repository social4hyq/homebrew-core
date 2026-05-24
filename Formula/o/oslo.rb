class Oslo < Formula
  desc "CLI tool for the OpenSLO spec"
  homepage "https://openslo.com/"
  url "https://github.com/OpenSLO/oslo/archive/refs/tags/v0.13.0.tar.gz"
  sha256 "8e3c501103cbfb0d9980a6ea023def0bdef2fe111a8aec3b106302669d452ec2"
  license "Apache-2.0"
  head "https://github.com/openslo/oslo.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "de9fb9127cb849e9dd4314a86569664ff27be7c91d22dec6513309df7a33feff"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/oslo"

    generate_completions_from_executable(bin/"oslo", shell_parameter_format: :cobra)

    pkgshare.install "test"
  end

  test do
    test_file = pkgshare/"test/inputs/validate/unknown-field.yaml"
    assert_match "json: unknown field", shell_output("#{bin}/oslo validate -f #{test_file} 2>&1", 1)

    output = shell_output("#{bin}/oslo fmt -f #{pkgshare}/test/inputs/fmt/service.yaml")
    assert_equal File.read(pkgshare/"test/outputs/fmt/service.yaml"), output
  end
end
