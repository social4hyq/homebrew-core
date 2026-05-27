class Tea < Formula
  desc "Command-line tool to interact with Gitea servers"
  homepage "https://gitea.com/gitea/tea"
  url "https://gitea.com/gitea/tea/archive/v0.14.1.tar.gz"
  sha256 "848b6b2fafa270fa77b4e278d521bfcc16d2f721c45ac90f08f5b16dc630c3f9"
  license "MIT"
  head "https://gitea.com/gitea/tea.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "62b390e76a32507418431619541446ca9e80b9b1c0279743a22f3033ecd1a154"
  end

  depends_on "go" => :build

  def install
    # get gittea sdk version
    sdk = Utils.safe_popen_read("go", "list", "-f", "{{.Version}}", "-m", "code.gitea.io/sdk/gitea").to_s

    ldflags = %W[
      -s -w
      -X code.gitea.io/tea/modules/version.Version=#{version}
      -X code.gitea.io/tea/modules/version.Tags=#{tap.user}
      -X code.gitea.io/tea/modules/version.SDK=#{sdk}
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
