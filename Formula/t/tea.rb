class Tea < Formula
  desc "Command-line tool to interact with Gitea servers"
  homepage "https://gitea.com/gitea/tea"
  url "https://gitea.com/gitea/tea.git",
      tag:      "v0.16.0",
      revision: "9c12138d6273ba8feb6e7578833cc330c0cd6461"
  license "MIT"
  head "https://gitea.com/gitea/tea.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "da7838f92af0051d763cf53a3e07255f75d623a710b89254d95a67c4cb190a7f"
  end

  depends_on "go" => :build

  def install
    # get gittea sdk version
    sdk = Utils.safe_popen_read("go", "list", "-f", "{{.Version}}", "-m", "gitea.dev/sdk").to_s

    ldflags = %W[
      -s -w
      -X gitea.dev/tea/modules/version.Version=#{version}
      -X gitea.dev/tea/modules/version.SDK=#{sdk}
    ]

    system "go", "build", *std_go_args(ldflags:)
    generate_completions_from_executable(bin/"tea", "completion")

    man8.mkpath
    system bin/"tea", "man", "--out", man8/"tea.8"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tea --version")
    assert_match "Error: no available login\n", shell_output("#{bin}/tea pulls 2>&1", 1)
  end
end
