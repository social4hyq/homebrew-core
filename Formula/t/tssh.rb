class Tssh < Formula
  desc "SSH Lightweight management tools"
  homepage "https://github.com/luanruisong/tssh"
  url "https://github.com/luanruisong/tssh/archive/refs/tags/2.1.5.tar.gz"
  sha256 "8878d73af523281441e6ec708998bf8aea1a5b22bf0a8822abd72067bd6566a9"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "de48bc94a74b6919751f07db6ebbf5acdee771835dd523fb0987d440749b8973"
  end

  depends_on "go" => :build

  conflicts_with "trzsz-ssh", because: "both install `tssh` binaries"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}")
  end

  test do
    output_v = shell_output("#{bin}/tssh -v")
    assert_match "version #{version}", output_v
    output_e = shell_output("#{bin}/tssh -e")
    assert_match "TSSH_HOME", output_e
  end
end
