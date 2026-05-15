class GitHound < Formula
  desc "Git plugin that prevents sensitive data from being committed"
  homepage "https://github.com/ezekg/git-hound"
  url "https://github.com/ezekg/git-hound/archive/refs/tags/1.0.0.tar.gz"
  sha256 "32f79f470c790db068a23fd68e9763b3bedc84309a281b4c99b941d4f33f5763"
  license "MIT"
  head "https://github.com/ezekg/git-hound.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f3017486d53c5801d642892fc14d86bf048ad7ce0cafbb60a23c462b304cc113"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-X main.version=#{version}")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/git-hound -v")

    (testpath/".githound.yml").write <<~YAML
      warn:
        - '(?i)user(name)?\W*[:=,]\W*.+$'
      fail:
        - '(?i)pass(word)?\W*[:=,]\W*.+$'
      skip:
        - 'skip-test.txt'
    YAML

    (testpath/"failure-test.txt").write <<~EOS
      password="hunter2"
    EOS

    (testpath/"warn-test.txt").write <<~EOS
      username="AzureDiamond"
    EOS

    (testpath/"skip-test.txt").write <<~EOS
      password="password123"
    EOS

    (testpath/"pass-test.txt").write <<~EOS
      foo="bar"
    EOS

    diff_cmd = "git diff /dev/null"

    assert_match "failure", shell_output("#{diff_cmd} #{testpath}/failure-test.txt | #{bin}/git-hound sniff", 1)
    assert_match "warning", shell_output("#{diff_cmd} #{testpath}/warn-test.txt | #{bin}/git-hound sniff")
    assert_match "", shell_output("#{diff_cmd} #{testpath}/skip-test.txt | #{bin}/git-hound sniff")
    assert_match "", shell_output("#{diff_cmd} #{testpath}/pass-test.txt | #{bin}/git-hound sniff")
  end
end
