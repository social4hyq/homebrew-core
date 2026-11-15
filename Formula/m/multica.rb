class Multica < Formula
  desc "CLI and local daemon for the Multica AI agent workspace"
  homepage "https://multica.ai"
  url "https://github.com/multica-ai/multica/archive/refs/tags/v0.9.0.tar.gz"
  sha256 "c52ffa09412bfc0f6cd6bed0900a66252b1c30f355f257f991a62a88e121eac8"
  license :cannot_represent # Multica License (Apache-2.0 plus additional conditions)
  revision 14

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/multica-v0.9.0-r19"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "47fa9dc408451bae575d56f4aad425a178de1206a1de7233d4981dc9d7565320"
  end

  depends_on "go" => :build

  def install
    cd "server" do
      ENV["CGO_ENABLED"] = "0"
      system "go", "build", *std_go_args(output: libexec/"multica-cli", ldflags: "-s -w -X main.version=#{version}"),
             "./cmd/multica"
    end

    # The daemon locks its per-task temp dir with flock, which /tmp refuses on
    # OHOS. A value the user set explicitly still wins. multica-desktop runs
    # libexec/multica-cli by its stable opt path, so keep it where it is.
    (bin/"multica").write_env_script libexec/"multica-cli",
      MULTICA_AGENT_TEMP_BASE: "${MULTICA_AGENT_TEMP_BASE:-/data/storage/el2/base/cache}"
  end

  def caveats
    <<~EOS
      The CLI and daemon are available as `multica`.

      The desktop app is a separate formula. Install it with
      `brew install multica-desktop`, then run `multica-desktop install` to sign
      and install it on a connected device. The `multica install-desktop` and
      `multica desktop` commands of earlier revisions now live there as
      `multica-desktop install` and `multica-desktop start|stop|status`.
    EOS
  end

  test do
    ENV["HOME"] = testpath/"home"
    assert_match "multica #{version}", shell_output("#{bin}/multica --version")
    assert_match "CORE COMMANDS", shell_output("#{bin}/multica --help")
    # multica-desktop runs the CLI by this path, and it must stay an executable.
    assert_path_exists libexec/"multica-cli"
    assert_predicate libexec/"multica-cli", :executable?
    # The wrapper only carries what the daemon needs. A value the user set
    # explicitly still wins.
    wrapper = (bin/"multica").read
    temp_base = "/data/storage/el2/base/cache"
    assert_match "MULTICA_AGENT_TEMP_BASE=\"${MULTICA_AGENT_TEMP_BASE:-#{temp_base}}\"", wrapper
    assert_equal ["MULTICA_AGENT_TEMP_BASE"], wrapper.scan(/\bMULTICA_\w+(?==)/).uniq
    env_probe = testpath/"env-probe"
    env_probe.write wrapper.sub(/exec "[^"]*multica-cli"/, "exec env")
    assert_match "MULTICA_AGENT_TEMP_BASE=#{temp_base}\n",
                 shell_output("env -u MULTICA_AGENT_TEMP_BASE sh #{env_probe}")
    assert_match "MULTICA_AGENT_TEMP_BASE=#{testpath}/custom\n",
                 shell_output("MULTICA_AGENT_TEMP_BASE=#{testpath}/custom sh #{env_probe}")
    # The desktop lives in its own formula now: nothing of it, and none of what
    # it needed, is left here.
    assert_empty %w[hap-installer ohos-sdk-toolchains zip] & deps.map(&:name)
    assert_empty stable.patches
    assert_empty resources
    refute_path_exists libexec/"multica-desktop-unsigned.hap"
    refute_path_exists libexec/"multica-desktop-bridge"
    refute_path_exists libexec/"multica-dispatch.sh"
    refute_path_exists pkgshare
    # The caveats send readers to multica-desktop and no longer teach the old commands as current.
    assert_match "brew install multica-desktop", caveats
    assert_match "multica-desktop install", caveats
    assert_match "multica-desktop start|stop|status", caveats
    refute_match "hap-installer", caveats
    refute_match "github.com/social4hyq", caveats
  end
end
