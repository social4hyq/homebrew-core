class Klog < Formula
  desc "Command-line tool for time tracking in a human-readable, plain-text file format"
  homepage "https://klog.jotaen.net"
  url "https://github.com/jotaen/klog/archive/refs/tags/v7.1.tar.gz"
  sha256 "3cd6eee1adc16c2105713718e23b67d9607ac9872a0dbc31689c6051d0176ea6"
  license "MIT"
  head "https://github.com/jotaen/klog.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "143e619ef6186e5d9c321b07f593ee795260621b3b7c72fbdd3b672d0a072b5c"
  end

  depends_on "go" => :build

  def install
    # The commit variable only displays 7 characters, so we can't use #{tap.user} or "Homebrew".
    ldflags = %W[
      -s -w
      -X main.BinaryVersion=v#{version}
      -X main.BinaryBuildHash=brew
    ]
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/klog version --no-check --quiet")

    (testpath/"test.klg").write <<~EOS
      2018-03-24
      First day at my new job
          8:30 - 17:00
          -45m Lunch break
    EOS

    assert_match "Total: 7h45m", shell_output("#{bin}/klog total --no-style #{testpath}/test.klg")
  end
end
