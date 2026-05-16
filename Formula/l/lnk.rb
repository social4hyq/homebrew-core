class Lnk < Formula
  desc "Git-native dotfiles management that doesn't suck"
  homepage "https://github.com/yarlson/lnk"
  url "https://github.com/yarlson/lnk/archive/refs/tags/v0.9.1.tar.gz"
  sha256 "2cbc8f994b7888d2d384a1ed34e1fd73477e1c73b9a05f638d2ad940c6c458ae"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "92c1a48da40fa114cfc187d9c5ebd0461d0d851c9aeca7e56bfc4b954906fb5f"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.version=#{version}
      -X main.buildTime=#{time.iso8601}
    ]
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"lnk", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/lnk --version")
    assert_match "Lnk repository not initialized", shell_output("#{bin}/lnk list 2>&1", 1)
  end
end
