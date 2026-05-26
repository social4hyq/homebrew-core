class RedTldr < Formula
  desc "Used to help red team staff quickly find the commands and key points"
  homepage "https://payloads.online/red-tldr/"
  url "https://github.com/Rvn0xsy/red-tldr/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "823a2faa8f0259c093284a5609c980e2e836cbb31b515454cb5192701418441a"
  license "MIT"
  head "https://github.com/Rvn0xsy/red-tldr.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ca0679e652d79ee52286276792803cf0dba9fe5201fb7a49804de05e55a2fff5"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")

    generate_completions_from_executable(bin/"red-tldr", shell_parameter_format: :cobra)
  end

  test do
    assert_match "privilege", shell_output("#{bin}/red-tldr mimikatz")
  end
end
