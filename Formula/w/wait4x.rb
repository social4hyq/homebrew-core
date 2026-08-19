class Wait4x < Formula
  desc "Wait for a port or a service to enter the requested state"
  homepage "https://wait4x.dev"
  url "https://github.com/wait4x/wait4x/archive/refs/tags/v3.7.0.tar.gz"
  sha256 "7cff5a488804dbaad2475902e8cb88b8827c7a73022aee764a6f8ddd036dde41"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b20bbfcfefad3254f19cc40e77f8fdd1dd5fe04ff05acd6f7dde4d88aaa0b2ff"
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
