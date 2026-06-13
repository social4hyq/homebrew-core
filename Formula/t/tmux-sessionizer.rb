class TmuxSessionizer < Formula
  desc "Tool for opening git repositories as tmux sessions"
  homepage "https://github.com/jrmoulton/tmux-sessionizer/"
  url "https://github.com/jrmoulton/tmux-sessionizer/archive/refs/tags/v0.6.1a.tar.gz"
  version "0.6.1a"
  sha256 "ce0a7756d2eb94d753cea5d4696e3683907d8d3237c2ac4e29cb91b0aa91b707"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3e0ead556bc7e2009a45aea720a86fa0e0246bde2af470127dc56d73e350c5c3"
  end

  depends_on "rust" => :build

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"tms", shell_parameter_format: :clap)
  end

  test do
    # TODO: recover version test in next release
    # assert_match version.to_s, shell_output("#{bin}/tms --version")

    assert_match "Configuration has been stored", shell_output("#{bin}/tms config -p /dev/null")
  end
end
