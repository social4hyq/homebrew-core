class Delve < Formula
  desc "Debugger for the Go programming language"
  homepage "https://github.com/go-delve/delve"
  url "https://github.com/go-delve/delve/archive/refs/tags/v1.27.0.tar.gz"
  sha256 "84979ac689ba26dc0a086b245cb0a3f3e6a7a246a435b2c757867e76823187a5"
  license "MIT"
  head "https://github.com/go-delve/delve.git", branch: "master"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dac6dfda5a603075890425f82df98c5f75680513140066816f251c43d26244dd"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/"dlv"), "./cmd/dlv"

    generate_completions_from_executable(bin/"dlv", shell_parameter_format: :cobra)
  end

  test do
    assert_match(/^Version: #{version}$/, shell_output("#{bin}/dlv version"))
  end
end
