class Flawz < Formula
  desc "Terminal UI for browsing security vulnerabilities (CVEs)"
  homepage "https://github.com/orhun/flawz"
  url "https://github.com/orhun/flawz/archive/refs/tags/v0.4.1.tar.gz"
  sha256 "641264999d2a5d662bc3d9c3994fcc580b92a2e9051c79fbcb8fdb2220924f30"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/orhun/flawz.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "36f4c067e6f656d44ce0bae5f237e74d549a095ad0bed81fb43e93f3f76021ee"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  uses_from_macos "sqlite"

  on_linux do
    depends_on "openssl@3"
  end

  def install
    system "cargo", "install", *std_cargo_args

    # Setup buildpath for completions and manpage generation
    ENV["OUT_DIR"] = buildpath

    system bin/"flawz-completions"
    bash_completion.install "flawz.bash" => "flawz"
    fish_completion.install "flawz.fish"
    zsh_completion.install "_flawz"

    system bin/"flawz-mangen"
    man1.install "flawz.1"

    # no need to ship `flawz-completions` and `flawz-mangen` binaries
    rm [bin/"flawz-completions", bin/"flawz-mangen"]
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/flawz --version")

    require "pty"
    PTY.spawn(bin/"flawz", "--url", "https://nvd.nist.gov/feeds/json/cve/1.1") do |r, _w, _pid|
      assert_match "Syncing CVE Data", r.read
    rescue Errno::EIO
      # GNU/Linux raises EIO when read is done on closed pty
    end
  end
end
