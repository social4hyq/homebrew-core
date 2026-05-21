class Reflex < Formula
  desc "Run a command when files change"
  homepage "https://github.com/cespare/reflex"
  url "https://github.com/cespare/reflex/archive/refs/tags/v0.3.2.tar.gz"
  sha256 "62603db35a51fddf8a3ae9b1f4d9a8372ebec2a4523be16e3261bc8f9cfba3e5"
  license "MIT"
  head "https://github.com/cespare/reflex.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f2fc868aad938e3782a67b57ae260fc06d0b792b7eb32868431644dc9c6410f3"
  end

  depends_on "go" => :build

  conflicts_with "re-flex", because: "both install `reflex` binaries"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    output = shell_output("#{bin}/reflex 2>&1", 1)
    assert_match "Could not make reflex for config: must give command to execute", output
  end
end
