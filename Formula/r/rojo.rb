class Rojo < Formula
  desc "Professional grade Roblox development tools"
  homepage "https://rojo.space/"
  # pull from git tag to get submodules
  url "https://github.com/rojo-rbx/rojo.git",
      tag:      "v7.7.0",
      revision: "bcadc97de27ab3800e915abcb72c6c7a3c30f363"
  license "MPL-2.0"
  head "https://github.com/rojo-rbx/rojo.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9f12d10abf388557d5fac8aeeb90ee50f9880b0cabeb32e1856d401e73c4a368"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    system bin/"rojo", "init"
    assert_path_exists testpath/"default.project.json"

    assert_match version.to_s, shell_output("#{bin}/rojo --version")
  end
end
