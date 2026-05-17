class TfProfile < Formula
  desc "CLI tool to profile Terraform runs"
  homepage "https://github.com/datarootsio/tf-profile"
  url "https://github.com/datarootsio/tf-profile/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "cfc5b9c68188f3cac1318b24d0b53ba4cae8af325ae5332865e1f0c92905b20b"
  license "MIT"
  head "https://github.com/datarootsio/tf-profile.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "016d1091a276167ad17cfef9922aa14b68dd11e9593380247816b13b6ac19e89"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w", tags: "netgo")
    pkgshare.install "test"

    generate_completions_from_executable(bin/"tf-profile", shell_parameter_format: :cobra)
  end

  test do
    test_file = pkgshare/"test/argo.log"
    output = shell_output("#{bin}/tf-profile stats #{test_file}")
    assert_match "Number of resources in configuration   100", output
    assert_match "Resources not in desired state         2 out of 76 (2.6%)", output

    output = shell_output("#{bin}/tf-profile table #{test_file}")
    assert_match "tot_time  modify_started  modify_ended", output

    assert_match version.to_s, shell_output("#{bin}/tf-profile version")
  end
end
