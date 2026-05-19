class Hotbuild < Formula
  desc "Cross platform hot compilation tool for go"
  homepage "https://hotbuild.rustpub.com/"
  url "https://github.com/wandercn/hotbuild/archive/refs/tags/v1.0.9.tar.gz"
  sha256 "7e8c5c52269344d12d4dc83ae4f472f8aec05faad76379c844dc21c2da44704c"
  license "MulanPSL-2.0"
  head "https://github.com/wandercn/hotbuild.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8e0684718e2770f644d5d55f1572d40621e1a9ff284e05ff98732f558805315a"
  end

  depends_on "go" => :build

  # Bump version
  # https://github.com/wandercn/hotbuild/pull/15
  patch do
    url "https://github.com/wandercn/hotbuild/commit/1b04ea4e9e1327ef4d462256072d72f4f37040cb.patch?full_index=1"
    sha256 "b0bbcdf106914307265b4ac81d73667a8b2d4c2fd688cc76dd1e303f690b4021"
  end

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    output = "buildcmd = \"go build -o tmp/tmp_bin\""
    system bin/"hotbuild", "initconf"
    assert_match output, (testpath/".hotbuild.toml").read

    assert_match version.to_s, shell_output("#{bin}/hotbuild version")
  end
end
