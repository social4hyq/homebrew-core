class Wait4x < Formula
  desc "Wait for a port or a service to enter the requested state"
  homepage "https://wait4x.dev"
  url "https://github.com/wait4x/wait4x/archive/refs/tags/v3.7.1.tar.gz"
  sha256 "36b1e0d3e7894ab20d29dfed19ec306c19e94608c2cb1a61ef5084d5127dfca8"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "eeaabea8ac535e7fb42741e7181928cd993cea6d874e3ea565fcd635b34c9738"
  end

  depends_on "go" => :build

  def install
    system "make", "build"
    bin.install "dist/wait4x"
    generate_completions_from_executable(bin/"wait4x", shell_parameter_format: :cobra)
  end

  test do
    system bin/"wait4x", "exec", "true"
  end
end
