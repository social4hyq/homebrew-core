class Zk < Formula
  desc "Plain text note-taking assistant"
  homepage "https://zk-org.github.io/zk/"
  url "https://github.com/zk-org/zk/archive/refs/tags/v0.15.4.tar.gz"
  sha256 "024b5a1615c8ac1924ec3338b36031c36131bad5de77dcce05adce35659b7489"
  license "GPL-3.0-only"
  head "https://github.com/zk-org/zk.git", branch: "dev"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "30928d9b9399d79cb7b8890a5f801b4350a4b97c820940ca3a983b1037753109"
  end

  depends_on "go" => :build

  depends_on "icu4c@78"
  uses_from_macos "sqlite"

  def install
    ENV["CGO_ENABLED"] = "1" if OS.linux? && Hardware::CPU.arm?

    ldflags = "-s -w -X main.Version=#{version} -X main.Build=#{tap.user}"
    tags = %w[fts5 icu]
    system "go", "build", *std_go_args(ldflags:, tags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/zk --version")

    system bin/"zk", "init", "--no-input"
    system bin/"zk", "index", "--no-input"
    (testpath/"testnote.md").write "note content"
    (testpath/"anothernote.md").write "todolist"

    output = pipe_output("#{bin}/zk list --quiet").chomp
    assert_match "note content", output
    assert_match "todolist", output
  end
end
