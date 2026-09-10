class GoogleworkspaceCli < Formula
  desc "CLI for Drive, Gmail, Calendar, Sheets, Docs, Chat, Admin, and more"
  homepage "https://developers.google.com/workspace"
  # We cannot install from the npm registry because it installs precompiled binaries
  url "https://github.com/googleworkspace/cli/archive/refs/tags/v0.22.5.tar.gz"
  sha256 "1e55ec8c6ee87fac7d422975604a2d546c35f6d687a1cfaba7c7cc0d3c05663f"
  license "Apache-2.0"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "256bb4347287ce26e712cfa3a2b5c9a9c24fc037d482d366fdd4ebdfc637cb47"
  end

  depends_on "rust" => :build

  conflicts_with "gws", because: "both install a `gws` binary"

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/google-workspace-cli")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/gws --version")
    output = shell_output("#{bin}/gws drive files list --params '{\"pageSize\": 10}'", 2)
    assert_match "Access denied. No credentials provided.", output
  end
end
