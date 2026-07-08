class Fjira < Formula
  desc "Fuzzy-find cli jira interface"
  homepage "https://github.com/mk-5/fjira"
  url "https://github.com/mk-5/fjira/archive/refs/tags/1.5.6.tar.gz"
  sha256 "f708f29646a69d371f93bdb09bb5811fc00baa13ab1374bee0719f5b81a6e82b"
  license "AGPL-3.0-only"
  head "https://github.com/mk-5/fjira.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "831dc7cf8d24f1d7352080ebcfae8f6ff828845259be9e25f75eae6feccac079"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}"), "./cmd/fjira-cli"

    generate_completions_from_executable(bin/"fjira", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/fjira version")

    ENV["XDG_CONFIG_HOME"] = testpath

    output_log = testpath/"output.log"
    pid = spawn bin/"fjira", testpath, [:out, :err] => output_log.to_s
    sleep 1
    assert_match "Create new workspace default", output_log.read
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
