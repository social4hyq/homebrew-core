class Tmex < Formula
  desc "Minimalist tmux layout manager"
  homepage "https://github.com/evnp/tmex"
  url "https://github.com/evnp/tmex/archive/refs/tags/v2.0.6.tar.gz"
  sha256 "83f16a8231c1c14105134c5e30d1294b41011de2e624e2a91f37d335b5a01712"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "22fd1763319e24a1d679ff74894348a00790d893d3689a967a263a8a64810fd0"
  end

  depends_on "tmux"

  def install
    bin.install "tmex"
    man1.install "man/tmex.1"

    # Build an `:all` bottle
    inreplace man1/"tmex.1" do |s|
      s.gsub! "/opt/homebrew", HOMEBREW_PREFIX
      s.gsub! prefix, opt_prefix, audit_result: false
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tmex -v 2>&1")

    assert_match "new-session -s test", shell_output("#{bin}/tmex test -tp 1224")
  end
end
