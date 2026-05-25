class ClockRs < Formula
  desc "Modern, digital clock that effortlessly runs in your terminal"
  homepage "https://github.com/Oughie/clock-rs"
  url "https://github.com/Oughie/clock-rs/archive/refs/tags/v0.2.1.tar.gz"
  sha256 "cb344326f7ed45eb252d74d27d35cddf61b8df9566e60f25e129da696e083344"
  license "Apache-2.0"
  head "https://github.com/Oughie/clock-rs.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "eec7bfb79bdc2d492c49aefd5e955e09461efa50e918240d01f90b3a18aa4125"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args

    bash_completion.install "target/completions/clock-rs.bash" => "clock-rs"
    fish_completion.install "target/completions/clock-rs.fish"
    zsh_completion.install  "target/completions/_clock-rs"
  end

  test do
    # clock-rs is a TUI application
    assert_match version.to_s, shell_output("#{bin}/clock-rs --version")
    assert_match "error: unexpected argument '--invalid' found", shell_output("#{bin}/clock-rs --invalid 2>&1", 2)
  end
end
