class Devcockpit < Formula
  desc "TUI system monitor for Apple Silicon"
  homepage "https://devcockpit.app/"
  url "https://github.com/caioricciuti/dev-cockpit/archive/refs/tags/v3.0.0.tar.gz"
  sha256 "5f0c72cd82ce06b166ad92810d096507c9575350af058734c3c010408cf0e87c"
  license "GPL-3.0-only"
  head "https://github.com/caioricciuti/dev-cockpit.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b077e2d099148db14c88a883dec3647eb1e24a7c17a36bbfddcbb8cd5894f977"
  end

  depends_on "go" => :build
  on_macos do
    depends_on arch: :arm64
  end

  def install
    ENV["CGO_ENABLED"] = "1"

    # Workaround to avoid patchelf corruption when cgo is required (for go-zetasql)
    if OS.linux? && Hardware::CPU.arch == :arm64
      ENV["GO_EXTLINK_ENABLED"] = "1"
      ENV.append "GOFLAGS", "-buildmode=pie"
    end

    cd "app" do
      system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}"), "./cmd/devcockpit"
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/devcockpit --version")
    assert_match "Log file location:", shell_output("#{bin}/devcockpit --logs")
  end
end
