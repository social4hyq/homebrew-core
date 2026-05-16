class Threemux < Formula
  desc "Terminal multiplexer inspired by i3"
  homepage "https://github.com/aaronjanse/3mux"
  url "https://github.com/aaronjanse/3mux/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "0f4dae181914c73eaa91bdb21ee0875f21b5da64c7c9d478f6d52a2d0aa2c0ea"
  license "MIT"
  head "https://github.com/aaronjanse/3mux.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c10dc10fad2f3f1c1ba614bbb03166da6586f08c9a576670c6741944572429a0"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/"3mux")
  end

  test do
    require "open3"

    Open3.popen2e(bin/"3mux") do |stdin, _, _|
      stdin.write "brew\n"
      stdin.write "3mux detach\n"
    end

    assert_match "Sessions:", pipe_output("#{bin}/3mux ls")
  end
end
