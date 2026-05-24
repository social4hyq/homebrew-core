class Jqp < Formula
  desc "TUI playground to experiment and play with jq"
  homepage "https://github.com/noahgorstein/jqp"
  url "https://github.com/noahgorstein/jqp/archive/refs/tags/v0.8.0.tar.gz"
  sha256 "c70e83975edb1c1dacb0fb067a0685e9632e21360805ade3dda03e54751e4855"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "22a996c3652e3b6b2a9ce8bbfb34de81b2cfe0c4a738afa0ae1b793529b35a0c"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
    generate_completions_from_executable(bin/"jqp", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/jqp --version")
    assert_match "Error: please provide an input file", if OS.mac?
      shell_output("#{bin}/jqp 2>&1", 1)
    else
      require "pty"
      r, _w, pid = PTY.spawn("#{bin}/jqp 2>&1")
      Process.wait(pid)
      r.read_nonblock(1024)
    end
  end
end
