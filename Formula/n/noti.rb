class Noti < Formula
  desc "Trigger notifications when a process completes"
  homepage "https://codeberg.org/roble/noti"
  url "https://codeberg.org/roble/noti/archive/3.8.0.tar.gz"
  sha256 "40939b83ee80f84ea2516ff205a961ddc0c4ec66af4f29319cdc41fce87eb332"
  license "MIT"
  head "https://codeberg.org/roble/noti.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0018796d07bf4fb84cc69b00601a10870f9e7f608b901c75b4674b985fb6f9b0"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/variadico/noti/internal/command.Version=#{version}
    ]
    system "go", "build", *std_go_args(ldflags:), "cmd/noti/main.go"
    man1.install "docs/man/dist/noti.1"
    man5.install "docs/man/dist/noti.yaml.5"

    generate_completions_from_executable(bin/"noti", shell_parameter_format: :cobra)
  end

  test do
    assert_match "noti version #{version}", shell_output("#{bin}/noti --version").chomp
    system bin/"noti", "-t", "Noti", "-m", "'Noti recipe installation test has finished.'"
  end
end
