class Matterbridge < Formula
  desc "Protocol bridge for multiple chat platforms"
  homepage "https://github.com/42wim/matterbridge"
  url "https://github.com/42wim/matterbridge/archive/refs/tags/v1.26.0.tar.gz"
  sha256 "00e1bbfe3b32f2feccf9a7f13a6f12b1ce28a5eb04cc7b922b344e3493497425"
  license "Apache-2.0"
  head "https://github.com/42wim/matterbridge.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "594f323bf39ab6ab8424456dd8fa0c04d73b27783ef94d5ee19674461c4688db"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args
  end

  test do
    touch testpath/"test.toml"
    assert_match "no [[gateway]] configured", shell_output("#{bin}/matterbridge -conf test.toml 2>&1", 1)
  end
end
