class Authz0 < Formula
  desc "Automated authorization test tool"
  homepage "https://authz0.hahwul.com/"
  url "https://github.com/hahwul/authz0/archive/refs/tags/v1.1.2.tar.gz"
  sha256 "b62d61846f3c1559dbffb6707f943ad6c4a5d4d519119b3c21954b8cd2a11a16"
  license "MIT"
  head "https://github.com/hahwul/authz0.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "451ab4ba4a97527edc408be72cd6e9cad8ab5cde431613f47e9045d2b27101b0"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")

    generate_completions_from_executable(bin/"authz0", shell_parameter_format: :cobra)
  end

  test do
    output = shell_output("#{bin}/authz0 new --name brewtest 2>&1")
    assert_match "[INFO] [authz0.yaml]", output
    assert_match "name: brewtest", (testpath/"authz0.yaml").read

    assert_match version.to_s, shell_output("#{bin}/authz0 version")
  end
end
