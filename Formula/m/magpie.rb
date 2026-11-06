class Magpie < Formula
  desc "Pick the model each AI coding agent on your machine uses"
  homepage "https://github.com/yetone/magpie"
  url "https://github.com/yetone/magpie/archive/refs/tags/v0.1.3141.tar.gz"
  sha256 "59ea9f727912da2c2813deff99998535c7676b782700f2dc92bc08fd1422d5ba"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/magpie-v0.1.3127-r2"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "72a6d23de24d39dc23597727a578cf76f41943f152973f8d790a5776f1982195"
  end

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "0"
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}"), "-tags=nogui", "."
  end

  test do
    assert_match "magpie #{version}", shell_output("#{bin}/magpie --version")
    system bin/"magpie", "settings", "set", "lang", "ja"
    assert_equal "ja", shell_output("#{bin}/magpie settings get lang").strip
  end
end
