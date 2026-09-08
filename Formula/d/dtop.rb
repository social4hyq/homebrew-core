class Dtop < Formula
  desc "Terminal dashboard for Docker monitoring across multiple hosts"
  homepage "https://dtop.dev/"
  url "https://github.com/amir20/dtop/archive/refs/tags/v0.9.2.tar.gz"
  sha256 "3d6ba93043a6f126a1e56d9dd611da8f151989e2c455b1bd83102112c88b4390"
  license "MIT"
  head "https://github.com/amir20/dtop.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "51ebf784d11a74a5c771d4942c9b40babf7754ac6cb108e57aff62fbd5daf3ea"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dtop --version")

    output = shell_output("#{bin}/dtop 2>&1", 1)
    assert_match "Failed to connect to Docker host", output
  end
end
