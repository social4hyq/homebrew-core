class Run < Formula
  desc "Easily manage and invoke small scripts and wrappers"
  homepage "https://github.com/TekWizely/run"
  url "https://github.com/TekWizely/run/archive/refs/tags/v0.11.2.tar.gz"
  sha256 "942427701caa99a9a3a6458a121b5c80b424752ea8701b26083841de5ae43ff6"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "48c359bc81a9f84ab8b336e31245683bd48dc42dbfd983a21b19706013868ba3"
  end

  depends_on "go" => :build

  conflicts_with "run-kit", because: "both install a `run` binary"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    text = "Hello Homebrew!"
    task = "hello"
    (testpath/"Runfile").write <<~EOS
      #{task}:
        echo #{text}
    EOS
    assert_equal text, shell_output("#{bin}/#{name} #{task}").chomp
  end
end
