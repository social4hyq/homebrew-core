class Micasa < Formula
  desc "TUI for tracking home projects, maintenance schedules, appliances and quotes"
  homepage "https://micasa.dev"
  url "https://github.com/micasa-dev/micasa/archive/refs/tags/v2.8.0.tar.gz"
  sha256 "d864680af382d4a11e3d2ca789b0b62bafe16a6f8bee39761375c2e185c9412e"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e58441c38c4c9ed449c2b166a805540dc9ffce2cc2ec262ead28b8c50f498615"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}"), "./cmd/micasa"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/micasa --version")

    system bin/"micasa", "demo", "--seed-only", testpath/"demo.db"
    assert_path_exists testpath/"demo.db"
  end
end
