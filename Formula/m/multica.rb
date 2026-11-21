class Multica < Formula
  desc "CLI and local daemon for the Multica AI agent workspace"
  homepage "https://multica.ai"
  url "https://github.com/multica-ai/multica/archive/refs/tags/v0.11.1.tar.gz"
  sha256 "8a8f2149447dfd0c178fca332f88b539560fa57a5075d67c6e440958de8d49fc"
  license :cannot_represent # Multica License (Apache-2.0 plus additional conditions)

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/multica-v0.11.1-r2"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c106694bad084ed9bcd3b5a48913f7dd76a4e45e174cc9364b7e5bfb20b55ed9"
  end

  depends_on "go" => :build

  def install
    cd "server" do
      ENV["CGO_ENABLED"] = "0"
      system "go", "build", *std_go_args(output: libexec/"multica-cli", ldflags: "-s -w -X main.version=#{version}"),
             "./cmd/multica"
    end

    # The daemon locks its per-task temp dir with flock, which /tmp refuses on
    # OHOS. A value the user set explicitly still wins. multica-app runs
    # libexec/multica-cli by its stable opt path, so keep it where it is.
    (bin/"multica").write_env_script libexec/"multica-cli",
      MULTICA_AGENT_TEMP_BASE: "${MULTICA_AGENT_TEMP_BASE:-/data/storage/el2/base/cache}"
  end

  def caveats
    <<~EOS
      The CLI and daemon are available as `multica`.

      The desktop app is a separate formula. Install it with
      `brew install multica-app`, then run `multica-app install` to sign
      and install it on a connected device.
    EOS
  end

  test do
    ENV["HOME"] = testpath/"home"
    assert_match "multica #{version}", shell_output("#{bin}/multica --version")
    assert_match "CORE COMMANDS", shell_output("#{bin}/multica --help")
    # multica-app runs the CLI by this path, and it must stay an executable.
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
  end
end
