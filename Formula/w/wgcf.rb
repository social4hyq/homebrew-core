class Wgcf < Formula
  desc "Generate WireGuard profile from Cloudflare Warp account"
  homepage "https://github.com/ViRb3/wgcf"
  url "https://github.com/ViRb3/wgcf/archive/refs/tags/v2.2.32.tar.gz"
  sha256 "1cbd077422b108c1cca1a7083ef759177512b6180e33cdfaf7d8c9422783194c"
  license "MIT"
  head "https://github.com/ViRb3/wgcf.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0c3f2a417b8f64059692b76ee7a1d366f64be4f75416be3da81b8b0b5b29b5df"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")

    generate_completions_from_executable(bin/"wgcf", shell_parameter_format: :cobra)
  end

  test do
    system bin/"wgcf", "trace"
  end
end
