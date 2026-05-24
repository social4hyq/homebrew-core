class Rospo < Formula
  desc "Simple, reliable, persistent ssh tunnels with embedded ssh server"
  homepage "https://github.com/ferama/rospo"
  url "https://github.com/ferama/rospo/archive/refs/tags/v0.15.3.tar.gz"
  sha256 "4c36291969c84159baff261841e6ccd9520e17f8bc9142bf815b9097322a8857"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fa376ae753f18fdbaa1bef35b36b09b7e709a5761db76972e1a2779ac3df7a2a"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/ferama/rospo/cmd.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"rospo", shell_parameter_format: :cobra)
  end

  test do
    system bin/"rospo", "-v"
    system bin/"rospo", "keygen", "-s"
    assert_path_exists testpath/"identity"
    assert_path_exists testpath/"identity.pub"
  end
end
