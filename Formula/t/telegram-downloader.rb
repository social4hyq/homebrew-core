class TelegramDownloader < Formula
  desc "Telegram Messenger downloader/tools written in Golang"
  homepage "https://docs.iyear.me/tdl/"
  url "https://github.com/iyear/tdl/archive/refs/tags/v0.20.2.tar.gz"
  sha256 "61b518929c05f5eb36386bb5d01fc85ff1c1956223592a52feda47f15faaa5fc"
  license "AGPL-3.0-only"
  head "https://github.com/iyear/tdl.git", branch: "master"

  no_autobump! because: :bumped_by_upstream

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d194a9d75b1a56737143fb38cdb18436a6dbfce09e4382b356c0556022245cf9"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/iyear/tdl/pkg/consts.Version=#{version}
      -X github.com/iyear/tdl/pkg/consts.Commit=#{tap.user}
      -X github.com/iyear/tdl/pkg/consts.CommitDate=#{time.iso8601}
    ]
    system "go", "build", *std_go_args(ldflags:, output: bin/"tdl")

    generate_completions_from_executable(bin/"tdl", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tdl version")

    assert_match "not authorized. please login first", shell_output("#{bin}/tdl chat ls -n _test", 1)
  end
end
