class Flawz < Formula
  desc "Terminal UI for browsing security vulnerabilities (CVEs)"
  homepage "https://github.com/orhun/flawz"
  url "https://github.com/orhun/flawz/archive/refs/tags/v0.4.0.tar.gz"
  sha256 "1716e8a4786f8c810ea820355d7b17d28582bc5d81b0506a6c6d40804f53ac42"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/orhun/flawz.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "67ce73dcd6a4ccbf3e50bd0c3533f0982ade155d2f102cf0f2537d1164543817"
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
