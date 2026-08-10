class SoftServe < Formula
  desc "Mighty, self-hostable Git server for the command-line"
  homepage "https://github.com/charmbracelet/soft-serve"
  url "https://github.com/charmbracelet/soft-serve/releases/download/v0.12.2/soft-serve-0.12.2.tar.gz"
  sha256 "b520cafe241855f3c9db34ede235ab8191c7f638e1bc7d34f5fb1b29a17e1345"
  license "MIT"
  head "https://github.com/charmbracelet/soft-serve.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d8ea922b5cc5b9e9015c14990f3df1d26c0f76aaed95bada313c2016f24024df"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.Version=#{version} -X main.CommitSHA=#{tap.user} -X main.CommitDate=#{time.iso8601}"
    system "go", "build", *std_go_args(ldflags:, output: bin/"soft"), "./cmd/soft"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/soft --version")

    pid = spawn bin/"soft", "serve"
    sleep 1
    Process.kill("TERM", pid)
    assert_path_exists testpath/"data/soft-serve.db"
    assert_path_exists testpath/"data/hooks/update.sample"
  end
end
